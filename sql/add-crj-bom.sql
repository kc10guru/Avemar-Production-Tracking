-- Add CRJ Windshield BOM: Subcomponents and BOM Items
-- Run this in Supabase SQL Editor AFTER update-stages-v3.sql
-- All BOM items are at Stage 6 (Interlayer, Heater, Sensor Install), quantity 1

-- Step 1: Insert subcomponents (materials) if they don't already exist
INSERT INTO subcomponents (part_number, description, category, unit_of_measure, quantity_on_hand, reorder_point) VALUES
  ('GA-676',              'CRJ Interlayer',                  'Material', 'EA', 0, 5),
  ('GA-NP139321-LH WWH', 'CRJ Main Windshield LH Heater',  'Material', 'EA', 0, 5),
  ('GA-NP139321-RH WWH', 'CRJ Main Windshield RH Heater',  'Material', 'EA', 0, 5),
  ('GA-NP139322-LH WWH', 'CRJ Side Window LH Heater',      'Material', 'EA', 0, 5),
  ('GA-NP139322-RH WWH', 'CRJ Side Window RH Heater',      'Material', 'EA', 0, 5),
  ('GA-S-7070',           'CRJ Sensor',                     'Material', 'EA', 0, 5)
ON CONFLICT (part_number) DO NOTHING;

-- Step 2: BOM for CRJ Main Windshield LH parts (NP139321-15, -17)
-- Each gets: GA-676 (interlayer), GA-NP139321-LH WWH (heater), GA-S-7070 (sensor)
INSERT INTO bom_items (production_part_id, subcomponent_id, stage_number, quantity_required)
SELECT pp.id, sc.id, 6, 1
FROM production_parts pp
CROSS JOIN subcomponents sc
WHERE pp.part_number IN ('NP139321-15', 'NP139321-17')
  AND sc.part_number IN ('GA-676', 'GA-NP139321-LH WWH', 'GA-S-7070')
  AND pp.is_active = true AND sc.is_active = true;

-- Step 3: BOM for CRJ Main Windshield RH parts (NP139321-16, -18)
INSERT INTO bom_items (production_part_id, subcomponent_id, stage_number, quantity_required)
SELECT pp.id, sc.id, 6, 1
FROM production_parts pp
CROSS JOIN subcomponents sc
WHERE pp.part_number IN ('NP139321-16', 'NP139321-18')
  AND sc.part_number IN ('GA-676', 'GA-NP139321-RH WWH', 'GA-S-7070')
  AND pp.is_active = true AND sc.is_active = true;

-- Step 4: BOM for CRJ Side Window LH parts (NP139321 odd -1 thru -13, 601R33033 odd)
INSERT INTO bom_items (production_part_id, subcomponent_id, stage_number, quantity_required)
SELECT pp.id, sc.id, 6, 1
FROM production_parts pp
CROSS JOIN subcomponents sc
WHERE pp.part_number IN (
  'NP139321-1', 'NP139321-3', 'NP139321-5', 'NP139321-7', 'NP139321-9', 'NP139321-11', 'NP139321-13',
  '601R33033-3', '601R33033-11', '601R33033-19', '601R33033-23', '601R33033-29'
)
  AND sc.part_number IN ('GA-676', 'GA-NP139322-LH WWH', 'GA-S-7070')
  AND pp.is_active = true AND sc.is_active = true;

-- Step 5: BOM for CRJ Side Window RH parts (NP139321 even -2 thru -14, 601R33033 even)
INSERT INTO bom_items (production_part_id, subcomponent_id, stage_number, quantity_required)
SELECT pp.id, sc.id, 6, 1
FROM production_parts pp
CROSS JOIN subcomponents sc
WHERE pp.part_number IN (
  'NP139321-2', 'NP139321-4', 'NP139321-6', 'NP139321-8', 'NP139321-10', 'NP139321-12', 'NP139321-14',
  '601R33033-4', '601R33033-12', '601R33033-20', '601R33033-24', '601R33033-30'
)
  AND sc.part_number IN ('GA-676', 'GA-NP139322-RH WWH', 'GA-S-7070')
  AND pp.is_active = true AND sc.is_active = true;

-- Step 6: BOM for 601R33033 Main Windshield LH parts (if they exist in the system)
INSERT INTO bom_items (production_part_id, subcomponent_id, stage_number, quantity_required)
SELECT pp.id, sc.id, 6, 1
FROM production_parts pp
CROSS JOIN subcomponents sc
WHERE pp.part_number IN (
  '601R33033-1', '601R33033-5', '601R33033-9', '601R33033-13',
  '601R33033-17', '601R33033-21', '601R33033-25', '601R33033-27'
)
  AND sc.part_number IN ('GA-676', 'GA-NP139321-LH WWH', 'GA-S-7070')
  AND pp.is_active = true AND sc.is_active = true;

-- Step 7: BOM for 601R33033 Main Windshield RH parts (if they exist in the system)
INSERT INTO bom_items (production_part_id, subcomponent_id, stage_number, quantity_required)
SELECT pp.id, sc.id, 6, 1
FROM production_parts pp
CROSS JOIN subcomponents sc
WHERE pp.part_number IN (
  '601R33033-2', '601R33033-6', '601R33033-10', '601R33033-14',
  '601R33033-18', '601R33033-22', '601R33033-26', '601R33033-28'
)
  AND sc.part_number IN ('GA-676', 'GA-NP139321-RH WWH', 'GA-S-7070')
  AND pp.is_active = true AND sc.is_active = true;
