-- App Settings table for configurable parameters (business hours, etc.)
CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all access to app_settings"
  ON app_settings FOR ALL USING (true) WITH CHECK (true);

-- Default business hours: 9 AM - 6 PM ET, Monday-Friday
INSERT INTO app_settings (key, value) VALUES
  ('business_hours', '{
    "openHour": 9,
    "openMinute": 0,
    "closeHour": 18,
    "closeMinute": 0,
    "timezone": "America/New_York",
    "workDays": [1, 2, 3, 4, 5]
  }')
ON CONFLICT (key) DO NOTHING;
