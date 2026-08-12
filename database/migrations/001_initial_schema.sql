-- ============================================================
-- SURAKSHYA NEPAL — Database Migration 001
-- Initial Schema: All tables, enums, triggers, indexes, RLS
-- Run this in: Supabase Dashboard → SQL Editor
-- ============================================================

-- ============================================================
-- EXTENSIONS
-- ============================================================

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pg_trgm; -- for text search

-- ============================================================
-- CUSTOM ENUM TYPES
-- ============================================================

DO $$ BEGIN
  CREATE TYPE user_role AS ENUM (
    'CITIZEN', 'RESPONDER', 'DISPATCHER', 'HOSPITAL', 'ADMIN'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE service_type AS ENUM (
    'AMBULANCE', 'POLICE', 'FIRE_BRIGADE'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE availability_status AS ENUM (
    'AVAILABLE', 'BUSY', 'EN_ROUTE', 'OFFLINE'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE verification_status AS ENUM (
    'PENDING', 'APPROVED', 'REJECTED', 'SUSPENDED'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE emergency_status AS ENUM (
    'REQUESTED', 'SEARCHING', 'ASSIGNED', 'ACCEPTED', 'EN_ROUTE',
    'ARRIVED', 'IN_SERVICE', 'COMPLETED', 'CANCELLED', 'REJECTED',
    'NO_RESPONDER', 'ESCALATED'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE dispatch_status AS ENUM (
    'PENDING', 'ACCEPTED', 'REJECTED', 'EXPIRED', 'CANCELLED'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE emergency_severity AS ENUM (
    'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE vehicle_status AS ENUM (
    'ACTIVE', 'INACTIVE', 'MAINTENANCE'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE blood_availability AS ENUM (
    'AVAILABLE', 'LOW', 'UNAVAILABLE'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================
-- SHARED TRIGGER: updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION fn_update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- TABLE: profiles
-- Maps Firebase UIDs to user profiles and roles.
-- NOTE: firebase_uid is the TEXT Firebase UID; we do NOT rely
--       on Supabase auth.uid() for identity in Phase 1.
--       Phase 2 will introduce the Firebase→Supabase JWT bridge.
-- ============================================================

CREATE TABLE IF NOT EXISTS profiles (
  id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  firebase_uid    TEXT        NOT NULL UNIQUE,
  full_name       TEXT        NOT NULL DEFAULT '',
  phone           TEXT        NOT NULL DEFAULT '',
  email           TEXT        NOT NULL DEFAULT '',
  profile_image   TEXT        NOT NULL DEFAULT '',
  role            user_role   NOT NULL DEFAULT 'CITIZEN',
  blood_group     TEXT        NOT NULL DEFAULT '',
  emergency_contact_1 TEXT    NOT NULL DEFAULT '',
  emergency_contact_2 TEXT    NOT NULL DEFAULT '',
  fcm_token       TEXT        NOT NULL DEFAULT '',
  is_demo         BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profiles_firebase_uid  ON profiles(firebase_uid);
CREATE INDEX IF NOT EXISTS idx_profiles_role          ON profiles(role);

CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION fn_update_updated_at();

-- ============================================================
-- TABLE: responders
-- Responder accounts (Ambulance / Police / Fire Brigade).
-- Created first without vehicle_id to break circular FK.
-- ============================================================

CREATE TABLE IF NOT EXISTS responders (
  id                   UUID                PRIMARY KEY DEFAULT uuid_generate_v4(),
  firebase_uid         TEXT                NOT NULL UNIQUE,
  profile_id           UUID                REFERENCES profiles(id) ON DELETE SET NULL,
  service_type         service_type        NOT NULL,
  employee_id          TEXT                NOT NULL DEFAULT '',
  verification_status  verification_status NOT NULL DEFAULT 'PENDING',
  availability_status  availability_status NOT NULL DEFAULT 'OFFLINE',
  -- Current GPS (also stored in PostGIS point for spatial queries)
  current_location     GEOGRAPHY(POINT, 4326),
  current_latitude     DOUBLE PRECISION    NOT NULL DEFAULT 0,
  current_longitude    DOUBLE PRECISION    NOT NULL DEFAULT 0,
  current_heading      DOUBLE PRECISION    NOT NULL DEFAULT 0,
  current_speed        DOUBLE PRECISION    NOT NULL DEFAULT 0,
  last_location_update TIMESTAMPTZ,
  -- Stats
  total_emergencies    INTEGER             NOT NULL DEFAULT 0,
  completed_today      INTEGER             NOT NULL DEFAULT 0,
  is_demo              BOOLEAN             NOT NULL DEFAULT FALSE,
  created_at           TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
  updated_at           TIMESTAMPTZ         NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_responders_firebase_uid      ON responders(firebase_uid);
CREATE INDEX IF NOT EXISTS idx_responders_service_type      ON responders(service_type);
CREATE INDEX IF NOT EXISTS idx_responders_availability      ON responders(availability_status);
CREATE INDEX IF NOT EXISTS idx_responders_verification      ON responders(verification_status);
CREATE INDEX IF NOT EXISTS idx_responders_location          ON responders USING GIST(current_location);

CREATE TRIGGER trg_responders_updated_at
  BEFORE UPDATE ON responders
  FOR EACH ROW EXECUTE FUNCTION fn_update_updated_at();

-- Auto-sync PostGIS point when lat/lng updated
CREATE OR REPLACE FUNCTION fn_sync_responder_location()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.current_latitude IS NOT NULL AND NEW.current_longitude IS NOT NULL THEN
    NEW.current_location = ST_SetSRID(
      ST_MakePoint(NEW.current_longitude, NEW.current_latitude), 4326
    )::GEOGRAPHY;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_responder_sync_location
  BEFORE INSERT OR UPDATE ON responders
  FOR EACH ROW EXECUTE FUNCTION fn_sync_responder_location();

-- ============================================================
-- TABLE: vehicles
-- Emergency vehicles linked to responders.
-- ============================================================

CREATE TABLE IF NOT EXISTS vehicles (
  id             UUID           PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_number TEXT           NOT NULL UNIQUE,
  vehicle_type   TEXT           NOT NULL DEFAULT '',
  service_type   service_type   NOT NULL,
  responder_id   UUID           REFERENCES responders(id) ON DELETE SET NULL,
  status         vehicle_status NOT NULL DEFAULT 'ACTIVE',
  location       GEOGRAPHY(POINT, 4326),
  latitude       DOUBLE PRECISION NOT NULL DEFAULT 0,
  longitude      DOUBLE PRECISION NOT NULL DEFAULT 0,
  created_at     TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vehicles_responder_id  ON vehicles(responder_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_service_type  ON vehicles(service_type);
CREATE INDEX IF NOT EXISTS idx_vehicles_status        ON vehicles(status);
CREATE INDEX IF NOT EXISTS idx_vehicles_location      ON vehicles USING GIST(location);

CREATE TRIGGER trg_vehicles_updated_at
  BEFORE UPDATE ON vehicles
  FOR EACH ROW EXECUTE FUNCTION fn_update_updated_at();

-- Now add vehicle_id back to responders (circular FK resolved)
ALTER TABLE responders
  ADD COLUMN IF NOT EXISTS vehicle_id UUID REFERENCES vehicles(id) ON DELETE SET NULL;

-- ============================================================
-- TABLE: emergency_requests
-- Core table for all citizen emergency submissions.
-- ============================================================

CREATE TABLE IF NOT EXISTS emergency_requests (
  id                    UUID               PRIMARY KEY DEFAULT uuid_generate_v4(),
  request_number        TEXT               NOT NULL DEFAULT '',
  citizen_firebase_uid  TEXT               NOT NULL,
  service_type          service_type       NOT NULL,
  emergency_type        TEXT               NOT NULL DEFAULT '',
  severity              emergency_severity NOT NULL DEFAULT 'MEDIUM',
  description           TEXT               NOT NULL DEFAULT '',
  -- Location
  location              GEOGRAPHY(POINT, 4326),
  latitude              DOUBLE PRECISION   NOT NULL,
  longitude             DOUBLE PRECISION   NOT NULL,
  address               TEXT               NOT NULL DEFAULT '',
  -- Media
  photo_url             TEXT               NOT NULL DEFAULT '',
  video_url             TEXT               NOT NULL DEFAULT '',
  -- Extra info
  people_affected       INTEGER            NOT NULL DEFAULT 1,
  fire_type             TEXT               NOT NULL DEFAULT '',
  building_type         TEXT               NOT NULL DEFAULT '',
  explosion_risk        BOOLEAN            NOT NULL DEFAULT FALSE,
  gas_electrical_risk   BOOLEAN            NOT NULL DEFAULT FALSE,
  -- Status tracking
  status                emergency_status   NOT NULL DEFAULT 'REQUESTED',
  assigned_responder_id UUID               REFERENCES responders(id) ON DELETE SET NULL,
  -- Timestamps
  created_at            TIMESTAMPTZ        NOT NULL DEFAULT NOW(),
  accepted_at           TIMESTAMPTZ,
  arrived_at            TIMESTAMPTZ,
  completed_at          TIMESTAMPTZ,
  cancelled_at          TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_emergency_citizen_uid   ON emergency_requests(citizen_firebase_uid);
CREATE INDEX IF NOT EXISTS idx_emergency_status        ON emergency_requests(status);
CREATE INDEX IF NOT EXISTS idx_emergency_service_type  ON emergency_requests(service_type);
CREATE INDEX IF NOT EXISTS idx_emergency_severity      ON emergency_requests(severity);
CREATE INDEX IF NOT EXISTS idx_emergency_location      ON emergency_requests USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_emergency_created_at    ON emergency_requests(created_at DESC);

-- Auto-generate readable request_number and sync PostGIS point
CREATE OR REPLACE FUNCTION fn_before_emergency_insert()
RETURNS TRIGGER AS $$
BEGIN
  -- Generate unique request number: SN-YYYYMMDD-XXXXX
  IF NEW.request_number = '' THEN
    NEW.request_number = 'SN-' ||
      TO_CHAR(NOW(), 'YYYYMMDD') || '-' ||
      LPAD(FLOOR(RANDOM() * 99999)::TEXT, 5, '0');
  END IF;
  -- Sync PostGIS point
  IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
    NEW.location = ST_SetSRID(
      ST_MakePoint(NEW.longitude, NEW.latitude), 4326
    )::GEOGRAPHY;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_emergency_before_insert
  BEFORE INSERT ON emergency_requests
  FOR EACH ROW EXECUTE FUNCTION fn_before_emergency_insert();

-- Sync PostGIS point on update too
CREATE OR REPLACE FUNCTION fn_before_emergency_update()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
    NEW.location = ST_SetSRID(
      ST_MakePoint(NEW.longitude, NEW.latitude), 4326
    )::GEOGRAPHY;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_emergency_before_update
  BEFORE UPDATE ON emergency_requests
  FOR EACH ROW EXECUTE FUNCTION fn_before_emergency_update();

-- ============================================================
-- TABLE: dispatch_requests
-- Tracks which responder was sent which emergency request.
-- ============================================================

CREATE TABLE IF NOT EXISTS dispatch_requests (
  id                        UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
  emergency_id              UUID            NOT NULL REFERENCES emergency_requests(id) ON DELETE CASCADE,
  responder_id              UUID            NOT NULL REFERENCES responders(id) ON DELETE CASCADE,
  distance_km               DOUBLE PRECISION NOT NULL DEFAULT 0,
  estimated_arrival_minutes INTEGER         NOT NULL DEFAULT 0,
  status                    dispatch_status NOT NULL DEFAULT 'PENDING',
  sent_at                   TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
  accepted_at               TIMESTAMPTZ,
  rejected_at               TIMESTAMPTZ,
  expired_at                TIMESTAMPTZ,
  -- Prevent duplicate dispatch for same emergency+responder pair
  UNIQUE(emergency_id, responder_id)
);

CREATE INDEX IF NOT EXISTS idx_dispatch_emergency_id  ON dispatch_requests(emergency_id);
CREATE INDEX IF NOT EXISTS idx_dispatch_responder_id  ON dispatch_requests(responder_id);
CREATE INDEX IF NOT EXISTS idx_dispatch_status        ON dispatch_requests(status);
CREATE INDEX IF NOT EXISTS idx_dispatch_sent_at       ON dispatch_requests(sent_at DESC);

-- ============================================================
-- TABLE: responder_locations
-- Time-series GPS history during active response.
-- ============================================================

CREATE TABLE IF NOT EXISTS responder_locations (
  id           UUID             PRIMARY KEY DEFAULT uuid_generate_v4(),
  responder_id UUID             NOT NULL REFERENCES responders(id) ON DELETE CASCADE,
  location     GEOGRAPHY(POINT, 4326),
  latitude     DOUBLE PRECISION NOT NULL,
  longitude    DOUBLE PRECISION NOT NULL,
  speed        DOUBLE PRECISION NOT NULL DEFAULT 0,
  heading      DOUBLE PRECISION NOT NULL DEFAULT 0,
  accuracy     DOUBLE PRECISION NOT NULL DEFAULT 0,
  recorded_at  TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_resp_locations_responder_id ON responder_locations(responder_id);
CREATE INDEX IF NOT EXISTS idx_resp_locations_recorded_at  ON responder_locations(recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_resp_locations_location     ON responder_locations USING GIST(location);

-- Auto-sync PostGIS point
CREATE OR REPLACE FUNCTION fn_sync_responder_loc_geo()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
    NEW.location = ST_SetSRID(
      ST_MakePoint(NEW.longitude, NEW.latitude), 4326
    )::GEOGRAPHY;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_resp_location_geo
  BEFORE INSERT ON responder_locations
  FOR EACH ROW EXECUTE FUNCTION fn_sync_responder_loc_geo();

-- ============================================================
-- TABLE: hospitals
-- Hospital capacity and contact info.
-- ============================================================

CREATE TABLE IF NOT EXISTS hospitals (
  id                  UUID              PRIMARY KEY DEFAULT uuid_generate_v4(),
  firebase_uid        TEXT              UNIQUE,        -- hospital admin Firebase UID
  name                TEXT              NOT NULL,
  phone               TEXT              NOT NULL DEFAULT '',
  address             TEXT              NOT NULL DEFAULT '',
  location            GEOGRAPHY(POINT, 4326),
  latitude            DOUBLE PRECISION  NOT NULL DEFAULT 0,
  longitude           DOUBLE PRECISION  NOT NULL DEFAULT 0,
  emergency_available BOOLEAN           NOT NULL DEFAULT TRUE,
  ambulance_available BOOLEAN           NOT NULL DEFAULT TRUE,
  icu_available       BOOLEAN           NOT NULL DEFAULT TRUE,
  available_beds      INTEGER           NOT NULL DEFAULT 0,
  icu_beds            INTEGER           NOT NULL DEFAULT 0,
  blood_available     blood_availability NOT NULL DEFAULT 'AVAILABLE',
  created_at          TIMESTAMPTZ       NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ       NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_hospitals_location ON hospitals USING GIST(location);

CREATE TRIGGER trg_hospitals_updated_at
  BEFORE UPDATE ON hospitals
  FOR EACH ROW EXECUTE FUNCTION fn_update_updated_at();

CREATE OR REPLACE FUNCTION fn_sync_hospital_location()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
    NEW.location = ST_SetSRID(
      ST_MakePoint(NEW.longitude, NEW.latitude), 4326
    )::GEOGRAPHY;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_hospital_location
  BEFORE INSERT OR UPDATE ON hospitals
  FOR EACH ROW EXECUTE FUNCTION fn_sync_hospital_location();

-- ============================================================
-- TABLE: emergency_events  (audit / timeline)
-- Every state change appended here for full emergency timeline.
-- ============================================================

CREATE TABLE IF NOT EXISTS emergency_events (
  id           UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  emergency_id UUID        NOT NULL REFERENCES emergency_requests(id) ON DELETE CASCADE,
  event_type   TEXT        NOT NULL,  -- e.g. CREATED, SEARCHING, DISPATCH_SENT, ACCEPTED...
  description  TEXT        NOT NULL DEFAULT '',
  created_by   TEXT        NOT NULL DEFAULT '',  -- Firebase UID
  metadata     JSONB       NOT NULL DEFAULT '{}',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_events_emergency_id ON emergency_events(emergency_id);
CREATE INDEX IF NOT EXISTS idx_events_created_at   ON emergency_events(created_at DESC);

-- ============================================================
-- SPATIAL QUERY HELPER FUNCTION
-- Returns nearby approved, available responders for a given
-- service type within a radius (metres).
-- Used by the dispatch Edge Function.
-- ============================================================

CREATE OR REPLACE FUNCTION fn_find_nearby_responders(
  p_latitude     DOUBLE PRECISION,
  p_longitude    DOUBLE PRECISION,
  p_service_type service_type,
  p_radius_m     DOUBLE PRECISION DEFAULT 20000  -- 20 km default
)
RETURNS TABLE (
  responder_id      UUID,
  firebase_uid      TEXT,
  distance_m        DOUBLE PRECISION,
  distance_km       DOUBLE PRECISION,
  estimated_eta_min INTEGER,
  availability_status availability_status,
  vehicle_id        UUID
) AS $$
DECLARE
  origin GEOGRAPHY;
BEGIN
  origin := ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::GEOGRAPHY;

  RETURN QUERY
  SELECT
    r.id                          AS responder_id,
    r.firebase_uid,
    ST_Distance(r.current_location, origin)        AS distance_m,
    ST_Distance(r.current_location, origin) / 1000 AS distance_km,
    -- Simple ETA: distance_km / 40 km/h average speed × 60 minutes
    GREATEST(1, ROUND(ST_Distance(r.current_location, origin) / 1000 / 40 * 60)::INTEGER) AS estimated_eta_min,
    r.availability_status,
    r.vehicle_id
  FROM responders r
  WHERE
    r.service_type         = p_service_type
    AND r.verification_status = 'APPROVED'
    AND r.availability_status = 'AVAILABLE'
    AND r.current_location IS NOT NULL
    AND ST_DWithin(r.current_location, origin, p_radius_m)
  ORDER BY distance_m ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================
-- REALTIME: Enable realtime for critical tables
-- ============================================================

-- If realtime publication does not exist yet, create it
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_publication WHERE pubname = 'supabase_realtime'
  ) THEN
    CREATE PUBLICATION supabase_realtime;
  END IF;
END $$;

ALTER PUBLICATION supabase_realtime ADD TABLE emergency_requests;
ALTER PUBLICATION supabase_realtime ADD TABLE dispatch_requests;
ALTER PUBLICATION supabase_realtime ADD TABLE responder_locations;
ALTER PUBLICATION supabase_realtime ADD TABLE responders;
ALTER PUBLICATION supabase_realtime ADD TABLE hospitals;
ALTER PUBLICATION supabase_realtime ADD TABLE emergency_events;

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE profiles              ENABLE ROW LEVEL SECURITY;
ALTER TABLE responders            ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles              ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_requests    ENABLE ROW LEVEL SECURITY;
ALTER TABLE dispatch_requests     ENABLE ROW LEVEL SECURITY;
ALTER TABLE responder_locations   ENABLE ROW LEVEL SECURITY;
ALTER TABLE hospitals             ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_events      ENABLE ROW LEVEL SECURITY;

-- ────────────────────────────────────────────────────────────
-- RLS HELPER: Extract Firebase UID from the JWT.
-- Phase 1 uses anon key; Phase 2 will bridge Firebase JWT →
-- Supabase custom JWT which embeds 'firebase_uid' claim.
-- For now the function also checks the 'sub' claim (fallback).
-- ────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_current_firebase_uid()
RETURNS TEXT
LANGUAGE sql STABLE
AS $$
  SELECT COALESCE(
    NULLIF(current_setting('request.jwt.claims', true)::jsonb ->> 'firebase_uid', ''),
    NULLIF(current_setting('request.jwt.claims', true)::jsonb ->> 'sub', ''),
    ''
  );
$$;

CREATE OR REPLACE FUNCTION fn_get_user_role(p_firebase_uid TEXT)
RETURNS user_role
LANGUAGE sql STABLE SECURITY DEFINER
AS $$
  SELECT role FROM profiles WHERE firebase_uid = p_firebase_uid LIMIT 1;
$$;

-- ────────────────────────────────────────────────────────────
-- PROFILES RLS
-- ────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "profiles_select_own"              ON profiles;
DROP POLICY IF EXISTS "profiles_select_admin_dispatcher" ON profiles;
DROP POLICY IF EXISTS "profiles_insert_own"              ON profiles;
DROP POLICY IF EXISTS "profiles_update_own"              ON profiles;
DROP POLICY IF EXISTS "profiles_update_admin"            ON profiles;

CREATE POLICY "profiles_select_own" ON profiles
  FOR SELECT USING (firebase_uid = fn_current_firebase_uid());

CREATE POLICY "profiles_select_admin_dispatcher" ON profiles
  FOR SELECT USING (
    fn_get_user_role(fn_current_firebase_uid()) IN ('ADMIN', 'DISPATCHER')
  );

CREATE POLICY "profiles_insert_own" ON profiles
  FOR INSERT WITH CHECK (firebase_uid = fn_current_firebase_uid());

CREATE POLICY "profiles_update_own" ON profiles
  FOR UPDATE USING (firebase_uid = fn_current_firebase_uid());

CREATE POLICY "profiles_update_admin" ON profiles
  FOR UPDATE USING (
    fn_get_user_role(fn_current_firebase_uid()) = 'ADMIN'
  );

-- ────────────────────────────────────────────────────────────
-- RESPONDERS RLS
-- ────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "responders_select_own"             ON responders;
DROP POLICY IF EXISTS "responders_select_dispatcher"      ON responders;
DROP POLICY IF EXISTS "responders_select_citizen_active"  ON responders;
DROP POLICY IF EXISTS "responders_insert_own"             ON responders;
DROP POLICY IF EXISTS "responders_update_own"             ON responders;
DROP POLICY IF EXISTS "responders_update_admin"           ON responders;

CREATE POLICY "responders_select_own" ON responders
  FOR SELECT USING (firebase_uid = fn_current_firebase_uid());

CREATE POLICY "responders_select_dispatcher" ON responders
  FOR SELECT USING (
    fn_get_user_role(fn_current_firebase_uid()) IN ('ADMIN', 'DISPATCHER')
  );

-- Citizen can see responder assigned to their active emergency
CREATE POLICY "responders_select_citizen_active" ON responders
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM emergency_requests er
      WHERE er.citizen_firebase_uid = fn_current_firebase_uid()
        AND er.assigned_responder_id = responders.id
        AND er.status IN ('ACCEPTED','EN_ROUTE','ARRIVED','IN_SERVICE')
    )
  );

CREATE POLICY "responders_insert_own" ON responders
  FOR INSERT WITH CHECK (firebase_uid = fn_current_firebase_uid());

CREATE POLICY "responders_update_own" ON responders
  FOR UPDATE USING (firebase_uid = fn_current_firebase_uid());

CREATE POLICY "responders_update_admin" ON responders
  FOR UPDATE USING (
    fn_get_user_role(fn_current_firebase_uid()) = 'ADMIN'
  );

-- ────────────────────────────────────────────────────────────
-- VEHICLES RLS
-- ────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "vehicles_select_all"     ON vehicles;
DROP POLICY IF EXISTS "vehicles_insert_admin"   ON vehicles;
DROP POLICY IF EXISTS "vehicles_update_admin"   ON vehicles;

-- Any logged-in user can see vehicles (for dispatch UI)
CREATE POLICY "vehicles_select_all" ON vehicles
  FOR SELECT USING (fn_current_firebase_uid() != '');

CREATE POLICY "vehicles_insert_admin" ON vehicles
  FOR INSERT WITH CHECK (
    fn_get_user_role(fn_current_firebase_uid()) = 'ADMIN'
  );

CREATE POLICY "vehicles_update_admin" ON vehicles
  FOR UPDATE USING (
    fn_get_user_role(fn_current_firebase_uid()) = 'ADMIN'
  );

-- ────────────────────────────────────────────────────────────
-- EMERGENCY REQUESTS RLS
-- ────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "er_select_citizen"      ON emergency_requests;
DROP POLICY IF EXISTS "er_select_dispatcher"   ON emergency_requests;
DROP POLICY IF EXISTS "er_select_responder"    ON emergency_requests;
DROP POLICY IF EXISTS "er_select_dispatched"   ON emergency_requests;
DROP POLICY IF EXISTS "er_insert_citizen"      ON emergency_requests;
DROP POLICY IF EXISTS "er_update_citizen"      ON emergency_requests;
DROP POLICY IF EXISTS "er_update_dispatcher"   ON emergency_requests;
DROP POLICY IF EXISTS "er_update_responder"    ON emergency_requests;

CREATE POLICY "er_select_citizen" ON emergency_requests
  FOR SELECT USING (citizen_firebase_uid = fn_current_firebase_uid());

CREATE POLICY "er_select_dispatcher" ON emergency_requests
  FOR SELECT USING (
    fn_get_user_role(fn_current_firebase_uid()) IN ('ADMIN', 'DISPATCHER')
  );

-- Responder can see emergencies they are assigned to
CREATE POLICY "er_select_responder" ON emergency_requests
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM responders r
      WHERE r.firebase_uid = fn_current_firebase_uid()
        AND r.id = emergency_requests.assigned_responder_id
    )
  );

-- Responder can see emergencies dispatched to them
CREATE POLICY "er_select_dispatched" ON emergency_requests
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM dispatch_requests dr
      JOIN   responders r ON r.id = dr.responder_id
      WHERE  r.firebase_uid = fn_current_firebase_uid()
        AND  dr.emergency_id = emergency_requests.id
        AND  dr.status = 'PENDING'
    )
  );

CREATE POLICY "er_insert_citizen" ON emergency_requests
  FOR INSERT WITH CHECK (citizen_firebase_uid = fn_current_firebase_uid());

CREATE POLICY "er_update_citizen" ON emergency_requests
  FOR UPDATE USING (
    citizen_firebase_uid = fn_current_firebase_uid()
    AND status IN ('REQUESTED', 'SEARCHING')
  );

CREATE POLICY "er_update_dispatcher" ON emergency_requests
  FOR UPDATE USING (
    fn_get_user_role(fn_current_firebase_uid()) IN ('ADMIN', 'DISPATCHER')
  );

CREATE POLICY "er_update_responder" ON emergency_requests
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM responders r
      WHERE r.firebase_uid = fn_current_firebase_uid()
        AND r.id = emergency_requests.assigned_responder_id
    )
  );

-- ────────────────────────────────────────────────────────────
-- DISPATCH REQUESTS RLS
-- ────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "dr_select_responder"   ON dispatch_requests;
DROP POLICY IF EXISTS "dr_select_dispatcher"  ON dispatch_requests;
DROP POLICY IF EXISTS "dr_select_citizen"     ON dispatch_requests;
DROP POLICY IF EXISTS "dr_insert_dispatcher"  ON dispatch_requests;
DROP POLICY IF EXISTS "dr_update_responder"   ON dispatch_requests;
DROP POLICY IF EXISTS "dr_update_dispatcher"  ON dispatch_requests;

CREATE POLICY "dr_select_responder" ON dispatch_requests
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM responders r
      WHERE r.firebase_uid = fn_current_firebase_uid()
        AND r.id = dispatch_requests.responder_id
    )
  );

CREATE POLICY "dr_select_dispatcher" ON dispatch_requests
  FOR SELECT USING (
    fn_get_user_role(fn_current_firebase_uid()) IN ('ADMIN', 'DISPATCHER')
  );

CREATE POLICY "dr_select_citizen" ON dispatch_requests
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM emergency_requests er
      WHERE er.citizen_firebase_uid = fn_current_firebase_uid()
        AND er.id = dispatch_requests.emergency_id
    )
  );

CREATE POLICY "dr_insert_dispatcher" ON dispatch_requests
  FOR INSERT WITH CHECK (
    fn_get_user_role(fn_current_firebase_uid()) IN ('ADMIN', 'DISPATCHER')
  );

CREATE POLICY "dr_update_responder" ON dispatch_requests
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM responders r
      WHERE r.firebase_uid = fn_current_firebase_uid()
        AND r.id = dispatch_requests.responder_id
    )
  );

CREATE POLICY "dr_update_dispatcher" ON dispatch_requests
  FOR UPDATE USING (
    fn_get_user_role(fn_current_firebase_uid()) IN ('ADMIN', 'DISPATCHER')
  );

-- ────────────────────────────────────────────────────────────
-- RESPONDER LOCATIONS RLS
-- ────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "rl_insert_own"         ON responder_locations;
DROP POLICY IF EXISTS "rl_select_citizen"     ON responder_locations;
DROP POLICY IF EXISTS "rl_select_own"         ON responder_locations;
DROP POLICY IF EXISTS "rl_select_dispatcher"  ON responder_locations;

CREATE POLICY "rl_insert_own" ON responder_locations
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM responders r
      WHERE r.firebase_uid = fn_current_firebase_uid()
        AND r.id = responder_locations.responder_id
    )
  );

-- Citizen sees their assigned responder's location during active emergency only
CREATE POLICY "rl_select_citizen" ON responder_locations
  FOR SELECT USING (
    EXISTS (
      SELECT 1
      FROM   emergency_requests er
      JOIN   responders r ON r.id = er.assigned_responder_id
      WHERE  er.citizen_firebase_uid = fn_current_firebase_uid()
        AND  r.id = responder_locations.responder_id
        AND  er.status IN ('ACCEPTED','EN_ROUTE','ARRIVED','IN_SERVICE')
    )
  );

CREATE POLICY "rl_select_own" ON responder_locations
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM responders r
      WHERE r.firebase_uid = fn_current_firebase_uid()
        AND r.id = responder_locations.responder_id
    )
  );

CREATE POLICY "rl_select_dispatcher" ON responder_locations
  FOR SELECT USING (
    fn_get_user_role(fn_current_firebase_uid()) IN ('ADMIN', 'DISPATCHER')
  );

-- ────────────────────────────────────────────────────────────
-- HOSPITALS RLS
-- ────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "hospitals_select_all"   ON hospitals;
DROP POLICY IF EXISTS "hospitals_update_own"   ON hospitals;
DROP POLICY IF EXISTS "hospitals_insert_admin" ON hospitals;
DROP POLICY IF EXISTS "hospitals_update_admin" ON hospitals;

-- All logged-in users can read hospitals
CREATE POLICY "hospitals_select_all" ON hospitals
  FOR SELECT USING (fn_current_firebase_uid() != '');

CREATE POLICY "hospitals_update_own" ON hospitals
  FOR UPDATE USING (
    firebase_uid = fn_current_firebase_uid()
    AND fn_get_user_role(fn_current_firebase_uid()) = 'HOSPITAL'
  );

CREATE POLICY "hospitals_insert_admin" ON hospitals
  FOR INSERT WITH CHECK (
    fn_get_user_role(fn_current_firebase_uid()) = 'ADMIN'
  );

CREATE POLICY "hospitals_update_admin" ON hospitals
  FOR UPDATE USING (
    fn_get_user_role(fn_current_firebase_uid()) = 'ADMIN'
  );

-- ────────────────────────────────────────────────────────────
-- EMERGENCY EVENTS RLS
-- ────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "ev_select_citizen"    ON emergency_events;
DROP POLICY IF EXISTS "ev_select_responder"  ON emergency_events;
DROP POLICY IF EXISTS "ev_select_dispatcher" ON emergency_events;
DROP POLICY IF EXISTS "ev_insert_any"        ON emergency_events;

CREATE POLICY "ev_select_citizen" ON emergency_events
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM emergency_requests er
      WHERE er.citizen_firebase_uid = fn_current_firebase_uid()
        AND er.id = emergency_events.emergency_id
    )
  );

CREATE POLICY "ev_select_responder" ON emergency_events
  FOR SELECT USING (
    EXISTS (
      SELECT 1
      FROM   emergency_requests er
      JOIN   responders r ON r.id = er.assigned_responder_id
      WHERE  r.firebase_uid = fn_current_firebase_uid()
        AND  er.id = emergency_events.emergency_id
    )
  );

CREATE POLICY "ev_select_dispatcher" ON emergency_events
  FOR SELECT USING (
    fn_get_user_role(fn_current_firebase_uid()) IN ('ADMIN', 'DISPATCHER')
  );

-- Any authenticated actor can append timeline events
CREATE POLICY "ev_insert_any" ON emergency_events
  FOR INSERT WITH CHECK (fn_current_firebase_uid() != '');

-- ============================================================
-- SEED DATA: Demo Hospitals in Nepal
-- ============================================================

INSERT INTO hospitals (
  name, phone, address, latitude, longitude,
  emergency_available, ambulance_available, icu_available,
  available_beds, icu_beds, blood_available
) VALUES
  ('Tribhuvan University Teaching Hospital', '01-4412303', 'Maharajgunj, Kathmandu',
   27.7354, 85.3274, TRUE, TRUE, TRUE, 120, 20, 'AVAILABLE'),
  ('Bir Hospital', '01-4221119', 'Mahaboudha, Kathmandu',
   27.7023, 85.3127, TRUE, TRUE, TRUE, 200, 30, 'AVAILABLE'),
  ('Patan Hospital', '01-5522266', 'Lagankhel, Lalitpur',
   27.6681, 85.3200, TRUE, TRUE, TRUE, 100, 15, 'LOW'),
  ('Gandaki Medical College Hospital', '061-526416', 'Prithvi Chowk, Pokhara',
   28.2096, 83.9856, TRUE, TRUE, TRUE, 80, 10, 'AVAILABLE'),
  ('BP Koirala Institute of Health Sciences', '021-525555', 'Ghopa, Dharan',
   26.8065, 87.2846, TRUE, TRUE, TRUE, 150, 25, 'AVAILABLE'),
  ('Chitwan Medical College', '056-524111', 'Bharatpur, Chitwan',
   27.6795, 84.4322, TRUE, TRUE, TRUE, 90, 12, 'AVAILABLE'),
  ('Koshi Hospital', '021-525777', 'Biratnagar',
   26.4525, 87.2718, TRUE, TRUE, FALSE, 60, 0, 'LOW')
ON CONFLICT DO NOTHING;

-- ============================================================
-- SEED DATA: Demo Responders (for testing without real vehicles)
-- ============================================================

-- NOTE: Run this AFTER user accounts are created in profiles table.
-- These are demo/test entries for development mode.

-- Demo responders will be inserted via the Flutter app's demo mode setup.
-- The fn_find_nearby_responders function is ready to query them.

-- ============================================================
-- VERIFY SCHEMA
-- ============================================================

-- Quick sanity check query (run to confirm tables exist):
-- SELECT table_name FROM information_schema.tables
--   WHERE table_schema = 'public'
--   ORDER BY table_name;
