-- ============================================================
-- FUNCTION: cascade_dispatch
-- Cascades dispatch request to the next nearest available responder
-- when a responder rejects or expires.
-- ============================================================

CREATE OR REPLACE FUNCTION cascade_dispatch(
  emergency_id_param UUID,
  last_responder_id UUID
)
RETURNS JSONB AS $$
DECLARE
  req_lat DOUBLE PRECISION;
  req_lon DOUBLE PRECISION;
  req_service service_type;
  next_responder_id UUID;
  next_dist DOUBLE PRECISION;
  next_eta INTEGER;
BEGIN
  -- 1. Fetch details of emergency request
  SELECT latitude, longitude, service_type
  INTO req_lat, req_lon, req_service
  FROM emergency_requests
  WHERE id = emergency_id_param;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'message', 'Emergency request not found');
  END IF;

  -- 2. Find the next nearest available responder who has NOT been dispatched to yet
  SELECT r.id, 
         (ST_Distance(r.current_location, ST_SetSRID(ST_MakePoint(req_lon, req_lat), 4326)::geography) / 1000.0) AS dist_km,
         GREATEST(1, ROUND((ST_Distance(r.current_location, ST_SetSRID(ST_MakePoint(req_lon, req_lat), 4326)::geography) / 1000.0) * 2.0 + 3.0)::INTEGER) AS eta_min
  INTO next_responder_id, next_dist, next_eta
  FROM responders r
  WHERE r.verification_status = 'APPROVED'
    AND r.availability_status = 'AVAILABLE'
    AND r.service_type = req_service
    AND r.id != last_responder_id
    AND NOT EXISTS (
      SELECT 1 
      FROM dispatch_requests dr 
      WHERE dr.emergency_id = emergency_id_param 
        AND dr.responder_id = r.id
    )
  ORDER BY r.current_location <-> ST_SetSRID(ST_MakePoint(req_lon, req_lat), 4326)::geography
  LIMIT 1;

  -- 3. If another responder is found, dispatch to them
  IF next_responder_id IS NOT NULL THEN
    INSERT INTO dispatch_requests (
      emergency_id,
      responder_id,
      distance_km,
      estimated_arrival_minutes,
      status
    ) VALUES (
      emergency_id_param,
      next_responder_id,
      next_dist,
      next_eta,
      'PENDING'
    );

    -- Log timeline event
    INSERT INTO emergency_events (
      event_type,
      status,
      latitude,
      longitude,
      description
    ) VALUES (
      'DISPATCH_CASCADED',
      'DISPATCHING',
      req_lat,
      req_lon,
      'Dispatch cascaded to next nearest responder ' || next_responder_id || ' (' || ROUND(next_dist::numeric, 2) || ' km away)'
    );

    RETURN jsonb_build_object(
      'success', true, 
      'message', 'Cascade successful, new responder dispatched',
      'responder_id', next_responder_id
    );
  ELSE
    -- 4. No remaining available responders: mark emergency status as 'NO_RESPONDER'
    UPDATE emergency_requests
    SET status = 'NO_RESPONDER'
    WHERE id = emergency_id_param;

    -- Log final failure event
    INSERT INTO emergency_events (
      event_type,
      status,
      latitude,
      longitude,
      description
    ) VALUES (
      'NO_RESPONDER_AVAILABLE',
      'NO_RESPONDER',
      req_lat,
      req_lon,
      'All matching responders rejected or expired. Dispatcher intervention required.'
    );

    RETURN jsonb_build_object(
      'success', false, 
      'message', 'No remaining available responders. State set to NO_RESPONDER'
    );
  END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- TRIGGER: fn_dispatch_on_update_cascade
-- Trigger that detects reject/expire status updates and runs cascade_dispatch
-- ============================================================

CREATE OR REPLACE FUNCTION fn_dispatch_on_update_cascade()
RETURNS TRIGGER AS $$
BEGIN
  IF (NEW.status = 'REJECTED' OR NEW.status = 'EXPIRED') AND OLD.status = 'PENDING' THEN
    PERFORM cascade_dispatch(NEW.emergency_id, NEW.responder_id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_dispatch_on_update_cascade
  AFTER UPDATE ON dispatch_requests
  FOR EACH ROW EXECUTE FUNCTION fn_dispatch_on_update_cascade();

-- ============================================================
-- FUNCTION: sweep_expired_dispatches
-- Utility routine to sweep dispatches unanswered for more than 35s
-- ============================================================

CREATE OR REPLACE FUNCTION sweep_expired_dispatches()
RETURNS INTEGER AS $$
DECLARE
  expired_count INTEGER := 0;
  r RECORD;
BEGIN
  FOR r IN 
    SELECT id, emergency_id, responder_id 
    FROM dispatch_requests 
    WHERE status = 'PENDING' 
      AND sent_at < NOW() - INTERVAL '35 seconds'
  LOOP
    UPDATE dispatch_requests 
    SET status = 'EXPIRED', expired_at = NOW() 
    WHERE id = r.id;
    
    expired_count := expired_count + 1;
  END LOOP;
  
  RETURN expired_count;
END;
$$ LANGUAGE plpgsql;
