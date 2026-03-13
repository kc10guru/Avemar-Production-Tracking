-- Update Production Stages: 15-stage workflow → 18-stage workflow
-- Run this in Supabase SQL Editor

-- Step 1: Delete old stages
DELETE FROM production_stages;

-- Step 2: Insert new 18-stage workflow
INSERT INTO production_stages (stage_number, stage_name, required_role, time_limit_hours) VALUES
  (1,  'Receiving Inspection',                'receiving',   2),
  (2,  'Disassembly',                       'shop_floor',  24),
  (3,  'Removal of Conductive Coating',     'shop_floor',  24),
  (4,  'P1 Autoclave',                      'shop_floor',  48),
  (5,  'Cleaning PRE-CAT3/4',              'shop_floor',  16),
  (6,  'Interlayer, Heater, Sensor Install','shop_floor',  24),
  (7,  'Autoclave',                         'shop_floor',  48),
  (8,  'Testing',                           'quality',     24),
  (9,  'Cleaning PRE-Fiber Glass',          'shop_floor',  16),
  (10, 'Fiber Glass Installation',          'shop_floor',  24),
  (11, 'Retainer Installation',             'shop_floor',  24),
  (12, 'Polishing',                         'shop_floor',  24),
  (13, 'Peripheral Edge Sealant PRC',       'shop_floor',  24),
  (14, 'Weather Sealant PRC',               'shop_floor',  24),
  (15, 'Cleaning',                          'shop_floor',  16),
  (16, 'Final Pics',                        'quality',     8),
  (17, 'Final Inspection',                  'quality',     16),
  (18, 'Shipping',                          'receiving',   8)
ON CONFLICT (stage_number) DO UPDATE SET
  stage_name = EXCLUDED.stage_name,
  required_role = EXCLUDED.required_role,
  time_limit_hours = EXCLUDED.time_limit_hours;

-- Step 3: Remap existing King Air (101-384025) BOM items
-- Old stage 8 (Heater Installation) and stage 9 (Outer Glass Installation)
-- both move to new stage 6 (Interlayer, Heater, Sensor Install)
UPDATE bom_items SET stage_number = 6 WHERE stage_number IN (8, 9);

-- Step 4: Clear any skipped_stages on existing orders (stage numbers no longer valid)
UPDATE repair_orders SET skipped_stages = '[]'::jsonb WHERE skipped_stages != '[]'::jsonb;
