-- Adds the optional descriptive columns needed by the Location model.
-- Execute with `psql -d <database> -f backend/migrations/20251123_add_location_optional_fields.sql`

ALTER TABLE locations
    ADD COLUMN IF NOT EXISTS region VARCHAR(100);

ALTER TABLE locations
    ADD COLUMN IF NOT EXISTS summary TEXT;

ALTER TABLE locations
    ADD COLUMN IF NOT EXISTS duration VARCHAR(100);

ALTER TABLE locations
    ADD COLUMN IF NOT EXISTS opening_hours VARCHAR(255);
