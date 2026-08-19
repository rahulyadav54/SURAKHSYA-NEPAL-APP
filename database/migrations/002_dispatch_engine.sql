-- ============================================================
-- FUNCTION: find_nearest_responders
-- Returns a list of active available responders ordered by proximity.
-- ============================================================

CREATE OR REPLACE FUNCTION find_nearest_responders(
  emergency_lat DOUBLE PRECISION,
  emergency_lon DOUBLE PRECISION,
  service_type_val service_type,
  limit_val INTEGER
)
RETURNS TABLE (
  id UUID,
  employee_id TEXT,
  service_type service_type,
  full_name TEXT,
  phone TEXT,
  vehicle_type TEXT,
  vehicle_number TEXT,
  distance_km DOUBLE PRECISION,
  estimated_arrival_minutes INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.id,
    r.employee_id,
    r.service_type,
    p.full_name,
    p.phone,
    v.vehicle_type,
    v.vehicle_number,
    (ST_Distance(r.current_location, ST_SetSRID(ST_MakePoint(emergency_lon, emergency_lat), 4326)::geography) / 1000.0) AS distance_km,
    -- Simple ETA calculation: 2 minutes per kilometer + 3 minutes base prep time
    GREATEST(1, ROUND((ST_Distance(r.current_location, ST_SetSRID(ST_MakePoint(emergency_lon, emergency_lat), 4326)::geography) / 1000.0) * 2.0 + 3.0)::INTEGER) AS estimated_arrival_minutes
  FROM responders r
  LEFT JOIN profiles p ON r.profile_id = p.id
  LEFT JOIN vehicles v ON r.vehicle_id = v.id
  WHERE r.verification_status = 'APPROVED'
    AND r.availability_status = 'AVAILABLE'
    AND r.service_type = service_type_val
  ORDER BY r.current_location <-> ST_SetSRID(ST_MakePoint(emergency_lon, emergency_lat), 4326)::geography
  LIMIT limit_val;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- FUNCTION: dispatch_emergency
-- Matches the single nearest available responder and creates a dispatch request.
-- ============================================================

CREATE OR REPLACE FUNCTION dispatch_emergency(emergency_id_param UUID)
RETURNS JSONB AS $$
DECLARE
  req_lat DOUBLE PRECISION;
  req_lon DOUBLE PRECISION;
  req_service service_type;
  nearest_responder_id UUID;
  nearest_dist DOUBLE PRECISION;
  nearest_eta INTEGER;
  result JSONB;
BEGIN
  -- 1. Fetch the details of the emergency request
  SELECT latitude, longitude, service_type
  INTO req_lat, req_lon, req_service
  FROM emergency_requests
  WHERE id = emergency_id_param;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'message', 'Emergency request not found');
  END IF;

  -- 2. Find the single nearest available responder
  SELECT r.id, 
         (ST_Distance(r.current_location, ST_SetSRID(ST_MakePoint(req_lon, req_lat), 4326)::geography) / 1000.0) AS dist_km,
         GREATEST(1, ROUND((ST_Distance(r.current_location, ST_SetSRID(ST_MakePoint(req_lon, req_lat), 4326)::geography) / 1000.0) * 2.0 + 3.0)::INTEGER) AS eta_min
  INTO nearest_responder_id, nearest_dist, nearest_eta
  FROM responders r
  WHERE r.verification_status = 'APPROVED'
    AND r.availability_status = 'AVAILABLE'
    AND r.service_type = req_service
  ORDER BY r.current_location <-> ST_SetSRID(ST_MakePoint(req_lon, req_lat), 4326)::geography
  LIMIT 1;

  -- 3. If a responder is found, dispatch to them
  IF nearest_responder_id IS NOT NULL THEN
    -- Insert dispatch request
    INSERT INTO dispatch_requests (
      emergency_id,
      responder_id,
      distance_km,
      estimated_arrival_minutes,
      status
    ) VALUES (
      emergency_id_param,
      nearest_responder_id,
      nearest_dist,
      nearest_eta,
      'PENDING'
    )
    ON CONFLICT (emergency_id, responder_id) DO NOTHING;

    -- Update emergency request status to DISPATCHING
    UPDATE emergency_requests
    SET status = 'DISPATCHING'
    WHERE id = emergency_id_param;

    -- Log event
    INSERT INTO emergency_events (
      event_type,
      status,
      latitude,
      longitude,
      description
    ) VALUES (
      'DISPATCH_SENT',
      'DISPATCHING',
      req_lat,
      req_lon,
      'Auto-dispatch sent to responder ' || nearest_responder_id || ' (' || ROUND(nearest_dist::numeric, 2) || ' km away)'
    );

    RETURN jsonb_build_object(
      'success', true, 
      'message', 'Responder found and dispatch request created',
      'responder_id', nearest_responder_id,
      'distance_km', nearest_dist,
      'eta_minutes', nearest_eta
    );
  ELSE
    -- No responder available
    -- Log event
    INSERT INTO emergency_events (
      event_type,
      status,
      latitude,
      longitude,
      description
    ) VALUES (
      'NO_RESPONDER_AVAILABLE',
      'REQUESTED',
      req_lat,
      req_lon,
      'No active available responder found for service type: ' || req_service
    );

    RETURN jsonb_build_object('success', false, 'message', 'No available responders online');
  END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- TRIGGER: fn_auto_dispatch_on_insert
-- Automatically runs the dispatch engine on new emergency requests.
-- ============================================================

CREATE OR REPLACE FUNCTION fn_auto_dispatch_on_insert()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM dispatch_emergency(NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_auto_dispatch_on_insert
  AFTER INSERT ON emergency_requests
  FOR EACH ROW EXECUTE FUNCTION fn_auto_dispatch_on_insert();
