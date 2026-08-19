-- ============================================================
-- SURAKSHYA NEPAL — Database Migration 004
-- Add assigned_hospital_id to emergency_requests
-- ============================================================

ALTER TABLE emergency_requests
  ADD COLUMN IF NOT EXISTS assigned_hospital_id UUID REFERENCES hospitals(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_emergency_assigned_hospital ON emergency_requests(assigned_hospital_id);
