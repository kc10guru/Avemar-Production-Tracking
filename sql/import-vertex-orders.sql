-- Import Vertex Windows repair orders from spreadsheet
-- Generated: 2026-02-27 18:49:49

-- Step 1: Add invoice_number column if not present
ALTER TABLE repair_orders ADD COLUMN IF NOT EXISTS invoice_number TEXT;

-- Step 2: Insert repair orders

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20250128-1001', 'V2X', '101-384025-23', '98295H1249',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502046766-Q3', NULL,
  'Edgar Jones', 'edgar.jones@gov2x.com',
  1, '2025-01-28', NULL, NULL,
  'Scrapped', 'BER / SCRAP'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20250130-1002', 'V2X', '101-384025-23', '04119H3454',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502046756-Q3', NULL,
  'Edgar Jones', 'edgar.jones@gov2x.com',
  1, '2025-01-30', NULL, '2025-10-06',
  'Scrapped', 'DECLARED BER'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20241204-1003', 'V2X', '101-384025-23', '16021H8918',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502035542-Q3', 'I250148',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2024-12-04', NULL, '2025-06-27',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20241216-1004', 'V2X', '101-384025-23', '00336H5148',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502038254-Q3', 'I250194',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2024-12-16', NULL, '2025-08-25',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20241204-1005', 'V2X', '101-384025-23', '05224R8609',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502037825-Q3', 'I250145',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2024-12-04', NULL, '2025-06-24',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20241216-1006', 'V2X', '101-384025-23', '06270R3972',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502041019-Q3', 'I250139',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2024-12-16', NULL, '2025-06-16',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20241216-1007', 'V2X', '101-384025-24', '01197R3170',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502041016-Q3', 'i250259',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2024-12-16', '2025-10-10', '2025-10-20',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20250127-1008', 'V2X', '101-384025-24', '16146R2934',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502046765-Q3', 'I250246',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2025-01-27', NULL, '2025-10-06',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20250205-1009', 'V2X', '101-384025-23', '10201R3592',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502047172-Q3', 'I250146',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2025-02-05', NULL, '2025-06-24',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20250210-1010', 'V2X', '101-384025-24', '03276R5721',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502046764-Q3', 'I250160',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2025-02-10', NULL, '2025-07-16',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20250210-1011', 'V2X', '101-384025-24', '21320H1427',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502046760-Q1', 'I250206',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2025-02-10', NULL, '2025-09-02',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20250424-1012', 'V2X', '101-384025-23', '15132R2543',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502054462-Q3', 'I250182',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2025-04-24', NULL, '2025-08-11',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20250128-1013', 'V2X', '101-384025-24', '07180H1933',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502046762-Q3', 'I250229',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2025-01-28', NULL, '2025-09-22',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20250128-1014', 'V2X', '101-384025-23', '03059R7483',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502046758-Q3', 'I250113',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2025-01-28', NULL, '2025-05-16',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20250128-1015', 'V2X', '101-384025-23', '03190H8257',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502046757-Q3', 'I250247',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2025-01-28', NULL, '2025-10-06',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20250128-1016', 'V2X', '101-384025-24', '07220H5691',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502046763-Q3', 'I250218',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2025-01-28', NULL, '2025-09-16',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20250915-1017', 'V2X', '101-384025-24', '18094H3298',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502069021-Q3', 'I250245',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2025-09-15', NULL, '2025-10-06',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20250128-1018', 'V2X', '101-384025-23', '06156H1253',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502046752-Q3', 'I250303',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2025-01-28', NULL, '2025-12-15',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20240916-1019', 'V2X', '101-384025-23', '12025R5439',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502033551-Q3', 'I250305',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2024-09-16', NULL, '2025-12-16',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20250129-1020', 'V2X', '101-384025-23', '07334H8219',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502046745-Q3', 'I250306',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2025-01-29', NULL, '2025-12-22',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20241204-1021', 'V2X', '101-384025-23', '01174H1570',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502035543-Q3', 'I250307',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2024-12-04', NULL, '2025-12-22',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20250128-1022', 'V2X', '101-384025-24', '06174H3586',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502046761-Q3', 'I250308',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2025-01-28', NULL, '2025-12-22',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20241204-1023', 'V2X', '101-384025-23', '16154R3659',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502037823-Q3', 'i250314',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2024-12-04', NULL, '2025-12-31',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20250128-1024', 'V2X', '101-384025-24', '06097H4171',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502046760-Q3', 'I260103',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2025-01-28', NULL, '2026-01-14',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20250903-1025', 'V2X', '101-384025-23', '14132R5251',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502069034-Q3', 'I260104',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2025-09-03', NULL, '2026-01-14',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20250902-1026', 'V2X', '101-384025-23', '07333H8076',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502069028-Q3', 'I260106',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2025-09-02', NULL, '2026-01-15',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20250221-1027', 'V2X', '101-384025-24', '07089H1648',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502051199-Q3', 'I260107',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2025-02-21', NULL, '2026-01-19',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20250221-1028', 'V2X', '101-384025-23', '17135R6151',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502050655-Q3', 'I260119',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2025-02-21', NULL, '2026-01-30',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20250128-1029', 'V2X', '101-384025-23', '05140R9502',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502046748-Q3', 'I260127',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2025-01-28', NULL, '2026-02-09',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20250128-1030', 'V2X', '101-384025-23', '06026R5096',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502046746-Q3', 'I260129',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2025-01-28', '2026-03-27', '2026-02-09',
  'Completed', 'SHIPPED'
);

INSERT INTO repair_orders (
  ro_number, customer_name, part_number, serial_number,
  aircraft_type, contract_type, shipping_address,
  purchase_order, invoice_number,
  contact_name, contact_email,
  current_stage, date_received, expected_completion, date_completed,
  status, notes
) VALUES (
  'RO-20250128-1031', 'V2X', '101-384025-24', '02224H3427',
  'King Air', 'Commercial Sales', '555 Industrial Blvd S Madison MS 39110',
  '4502046759-Q3', 'I260133',
  'Edgar Jones', 'edgar.jones@gov2x.com',
  15, '2025-01-28', '2026-02-27', '2026-02-12',
  'Completed', 'SHIPPED'
);

-- Total records imported: 31