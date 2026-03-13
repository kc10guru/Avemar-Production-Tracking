-- Add 601R33033 CRJ side window part numbers
-- Odd dash = LH (Left Hand), Even dash = RH (Right Hand)

INSERT INTO production_parts (part_number, description) VALUES
  ('601R33033-3',  'CRJ LH SIDE WINDOW (-3)'),
  ('601R33033-4',  'CRJ RH SIDE WINDOW (-4)'),
  ('601R33033-11', 'CRJ LH SIDE WINDOW (-11)'),
  ('601R33033-12', 'CRJ RH SIDE WINDOW (-12)'),
  ('601R33033-19', 'CRJ LH SIDE WINDOW (-19)'),
  ('601R33033-20', 'CRJ RH SIDE WINDOW (-20)'),
  ('601R33033-23', 'CRJ LH SIDE WINDOW (-23)'),
  ('601R33033-24', 'CRJ RH SIDE WINDOW (-24)'),
  ('601R33033-29', 'CRJ LH SIDE WINDOW (-29)'),
  ('601R33033-30', 'CRJ RH SIDE WINDOW (-30)')
ON CONFLICT (part_number) DO NOTHING;
