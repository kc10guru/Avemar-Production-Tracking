-- Add NP139321 CRJ side window part numbers (-1 through -14)
-- Odd dash = LH (Left Hand), Even dash = RH (Right Hand)
-- Note: If these part numbers already exist (e.g. from add-np139321-parts.sql as main windshield),
-- this will update their descriptions to SIDE WINDOW.

INSERT INTO production_parts (part_number, description) VALUES
  ('NP139321-1',  'CRJ LH SIDE WINDOW (-1)'),
  ('NP139321-2',  'CRJ RH SIDE WINDOW (-2)'),
  ('NP139321-5',  'CRJ LH SIDE WINDOW (-5)'),
  ('NP139321-6',  'CRJ RH SIDE WINDOW (-6)'),
  ('NP139321-9',  'CRJ LH SIDE WINDOW (-9)'),
  ('NP139321-10', 'CRJ RH SIDE WINDOW (-10)'),
  ('NP139321-11', 'CRJ LH SIDE WINDOW (-11)'),
  ('NP139321-12', 'CRJ RH SIDE WINDOW (-12)'),
  ('NP139321-13', 'CRJ LH SIDE WINDOW (-13)'),
  ('NP139321-14', 'CRJ RH SIDE WINDOW (-14)')
ON CONFLICT (part_number) DO UPDATE SET description = EXCLUDED.description;
