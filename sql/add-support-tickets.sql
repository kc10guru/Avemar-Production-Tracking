-- Support Tickets table for issue reporting and feature requests
-- Run on the VM: cat sql/add-support-tickets.sql | docker exec -i glass-aero-db psql -U postgres -d postgres

CREATE TABLE IF NOT EXISTS support_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_number TEXT UNIQUE NOT NULL,
  reported_by UUID,
  reporter_email TEXT NOT NULL,
  reporter_name TEXT,
  type TEXT NOT NULL DEFAULT 'Bug Report',
  priority TEXT NOT NULL DEFAULT 'Medium',
  subject TEXT NOT NULL,
  description TEXT NOT NULL,
  page_url TEXT,
  status TEXT NOT NULL DEFAULT 'Open',
  resolution_notes TEXT,
  resolved_by UUID,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON support_tickets(status);
CREATE INDEX IF NOT EXISTS idx_support_tickets_created ON support_tickets(created_at DESC);

-- RLS policies
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can insert tickets" ON support_tickets;
CREATE POLICY "Authenticated users can insert tickets" ON support_tickets
  FOR INSERT TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can view tickets" ON support_tickets;
CREATE POLICY "Authenticated users can view tickets" ON support_tickets
  FOR SELECT TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Authenticated users can update tickets" ON support_tickets;
CREATE POLICY "Authenticated users can update tickets" ON support_tickets
  FOR UPDATE TO authenticated
  USING (true);

-- Grant permissions
GRANT ALL ON support_tickets TO anon, authenticated, service_role;

-- Sequence helper for ticket numbers (TKT-0001, TKT-0002, etc.)
CREATE SEQUENCE IF NOT EXISTS support_ticket_seq START 1;
