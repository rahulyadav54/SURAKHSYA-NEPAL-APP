-- ============================================================
-- SURAKSHYA NEPAL — Database Migration 005
-- Push Notifications: Queue table & automatic triggers
-- ============================================================

-- 1. Add fcm_token to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- 2. Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     TEXT        NOT NULL, -- Firebase UID from profiles
  title       TEXT        NOT NULL,
  body        TEXT        NOT NULL,
  data        JSONB       NOT NULL DEFAULT '{}',
  is_read     BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at DESC);

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow users to read their own notifications"
  ON notifications FOR SELECT
  USING (user_id = auth.uid()::text OR user_id = current_setting('request.jwt.claims', true)::json->>'sub');

CREATE POLICY "Allow server-side inserts"
  ON notifications FOR INSERT
  WITH CHECK (TRUE);

-- 3. Trigger for new dispatches (Alert Responder)
CREATE OR REPLACE FUNCTION fn_trigger_dispatch_notification()
RETURNS TRIGGER AS $$
DECLARE
  v_responder_uid TEXT;
  v_req_num TEXT;
  v_type TEXT;
BEGIN
  -- Get the Firebase UID of the responder
  SELECT firebase_uid INTO v_responder_uid 
  FROM responders 
  WHERE id = NEW.responder_id;

  -- Get emergency request number and type
  SELECT request_number, emergency_type INTO v_req_num, v_type
  FROM emergency_requests
  WHERE id = NEW.emergency_id;

  IF NEW.status = 'PENDING' AND v_responder_uid IS NOT NULL THEN
    INSERT INTO notifications (user_id, title, body, data)
    VALUES (
      v_responder_uid,
      '🚨 New Emergency Dispatch Assigned',
      'You have been assigned to ' || COALESCE(v_type, 'Emergency Incident') || ' (' || COALESCE(v_req_num, '') || '). Please respond immediately.',
      json_build_object(
        'type', 'DISPATCH',
        'dispatch_id', NEW.id::text,
        'emergency_id', NEW.emergency_id::text
      )
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_dispatch_notification
  AFTER INSERT OR UPDATE OF status ON dispatch_requests
  FOR EACH ROW EXECUTE FUNCTION fn_trigger_dispatch_notification();

-- 4. Trigger for emergency status changes (Alert Citizen)
CREATE OR REPLACE FUNCTION fn_trigger_emergency_notification()
RETURNS TRIGGER AS $$
DECLARE
  v_title TEXT;
  v_body TEXT;
BEGIN
  -- Ignore initial REQUESTED status to avoid redundant alert
  IF OLD.status IS NULL OR OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;

  v_title := '📢 Emergency Update';
  
  CASE NEW.status
    WHEN 'ACCEPTED' THEN
      v_body := 'Your emergency request ' || NEW.request_number || ' has been accepted. Responders are preparing.';
    WHEN 'EN_ROUTE' THEN
      v_body := 'Responder is now en-route to your location. Keep your phone accessible.';
    WHEN 'ARRIVED' THEN
      v_body := 'Responder has arrived at your location.';
    WHEN 'COMPLETED' THEN
      v_title := '✅ Incident Resolved';
      v_body := 'The emergency incident has been successfully resolved and completed.';
    WHEN 'CANCELLED' THEN
      v_body := 'Your emergency request has been cancelled.';
      v_title := '❌ Incident Cancelled';
    WHEN 'NO_RESPONDER' THEN
      v_title := '⚠️ Dispatch Warning';
      v_body := 'No nearby units accepted the dispatch. Command Center is manually routing assistance.';
    ELSE
      v_body := 'Your request status updated to ' || NEW.status;
  END CASE;

  INSERT INTO notifications (user_id, title, body, data)
  VALUES (
    NEW.citizen_firebase_uid,
    v_title,
    v_body,
    json_build_object(
      'type', 'EMERGENCY_STATUS',
      'emergency_id', NEW.id::text,
      'status', NEW.status
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_emergency_notification
  AFTER UPDATE OF status ON emergency_requests
  FOR EACH ROW EXECUTE FUNCTION fn_trigger_emergency_notification();
