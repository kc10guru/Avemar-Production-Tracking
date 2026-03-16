-- Update Production Stages: 18-stage → 19-stage workflow
-- Adds "Glass Installation" as new Stage 7
-- Run this in Supabase SQL Editor AFTER update-stages-v2.sql

-- Step 1: Shift existing stages 7-18 up by 1 (descending order to avoid unique conflicts)
DO $$
BEGIN
  FOR i IN REVERSE 18..7 LOOP
    UPDATE production_stages SET stage_number = i + 1 WHERE stage_number = i;
  END LOOP;
END $$;

-- Step 2: Insert new Stage 7 - Glass Installation
INSERT INTO production_stages (stage_number, stage_name, required_role, time_limit_hours)
VALUES (7, 'Glass Installation', 'shop_floor', 24)
ON CONFLICT (stage_number) DO UPDATE SET
  stage_name = EXCLUDED.stage_name,
  required_role = EXCLUDED.required_role,
  time_limit_hours = EXCLUDED.time_limit_hours;

-- Step 3: Shift BOM items at stage >= 7 (old numbering) up by 1
UPDATE bom_items SET stage_number = stage_number + 1
  WHERE stage_number >= 7;

-- Step 4: Shift repair order current_stage >= 7 up by 1
UPDATE repair_orders SET current_stage = current_stage + 1
  WHERE current_stage >= 7;

-- Step 5: Shift stage_history stage_number >= 7 up by 1
UPDATE stage_history SET stage_number = stage_number + 1
  WHERE stage_number >= 7;

-- Step 6: Increment skipped_stages JSONB values >= 7 by 1
UPDATE repair_orders
SET skipped_stages = (
  SELECT COALESCE(jsonb_agg(
    CASE WHEN (value::text)::int >= 7
         THEN to_jsonb((value::text)::int + 1)
         ELSE value
    END
  ), '[]'::jsonb)
  FROM jsonb_array_elements(skipped_stages) AS value
)
WHERE skipped_stages IS NOT NULL
  AND skipped_stages != '[]'::jsonb;

-- Step 7: Auto-skip Glass Installation (stage 7) for all existing CRJ repair orders
UPDATE repair_orders
SET skipped_stages = COALESCE(skipped_stages, '[]'::jsonb) || '[7]'::jsonb
WHERE part_number LIKE 'NP139321%'
   OR part_number LIKE '601R33033%';
