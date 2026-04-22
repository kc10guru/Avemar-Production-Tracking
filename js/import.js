// Import Work Orders page logic
const GLASS_STAGE = 7;
const MAX_STAGE = 19;

const STAGE_NAMES = {
  1: 'Receiving Inspection',
  2: 'Disassembly',
  3: 'Removal of Conductive Coating',
  4: 'P1 Autoclave',
  5: 'Cleaning PRE-CAT3/4',
  6: 'Interlayer, Heater, Sensor Install',
  7: 'Glass Installation',
  8: 'Autoclave',
  9: 'Testing',
  10: 'Cleaning PRE-Fiber Glass',
  11: 'Fiber Glass Installation',
  12: 'Retainer Installation',
  13: 'Polishing',
  14: 'Peripheral Edge Sealant PRC',
  15: 'Weather Sealant PRC',
  16: 'Cleaning',
  17: 'Final Pics',
  18: 'Final Inspection',
  19: 'Shipping'
};

function stageColKey(n) { return `stage_${n}_applies`; }
function stageColHeader(n) { return `Stage ${n}: ${STAGE_NAMES[n]}`; }

function isCRJPart(partNumber) {
  return partNumber?.startsWith('NP139321') || partNumber?.startsWith('601R33033');
}

let productionParts = [];
let stages = [];
let parsedRows = [];

async function loadImportPage() {
  [productionParts, stages] = await Promise.all([
    db.getProductionParts(),
    db.getProductionStages()
  ]);
}

// ─── Template Download ──────────────────────────────────
function downloadTemplate() {
  const orderHeaders = [
    'ro_number', 'customer_name', 'part_number', 'serial_number', 'contract_type',
    'current_stage', 'status', 'date_received', 'expected_completion',
    'purchase_order', 'invoice_number', 'aircraft_tail_number', 'aircraft_type',
    'shipping_address', 'contact_name', 'contact_email', 'contact_phone', 'notes'
  ];

  const stageHeaders = [];
  for (let s = 2; s <= 18; s++) stageHeaders.push(stageColHeader(s));
  const allHeaders = orderHeaders.concat(stageHeaders);

  const validParts = productionParts.map(p => p.partNumber).join(', ');

  const instructions = { ro_number: 'INSTRUCTIONS (delete this row)' };
  instructions.customer_name = 'Required';
  instructions.part_number = `Valid: ${validParts}`;
  instructions.serial_number = 'Required';
  instructions.contract_type = 'Commercial Sales or C12';
  instructions.current_stage = '1-19 (stage the unit is at NOW)';
  instructions.status = 'In Progress, On Hold, or Completed';
  instructions.date_received = 'YYYY-MM-DD format';
  instructions.expected_completion = 'YYYY-MM-DD format';
  instructions.purchase_order = 'Optional';
  instructions.invoice_number = 'Optional';
  instructions.aircraft_tail_number = 'Optional';
  instructions.aircraft_type = 'Optional';
  instructions.shipping_address = 'Optional';
  instructions.contact_name = 'Optional';
  instructions.contact_email = 'Optional';
  instructions.contact_phone = 'Optional';
  instructions.notes = 'Optional';
  for (let s = 2; s <= 18; s++) {
    instructions[stageColHeader(s)] = 'Y = applies, N = skip (default Y)';
  }

  const sampleRow = {
    ro_number: 'WO-2026-001',
    customer_name: 'ACME Aviation',
    part_number: productionParts.length > 0 ? productionParts[0].partNumber : '101-384025-21',
    serial_number: 'SN-12345',
    contract_type: 'Commercial Sales',
    current_stage: 8,
    status: 'In Progress',
    date_received: '2026-01-15',
    expected_completion: '2026-03-15',
    purchase_order: 'PO-9876',
    invoice_number: '',
    aircraft_tail_number: 'N12345',
    aircraft_type: 'CRJ-200',
    shipping_address: '123 Airport Rd, Dallas TX',
    contact_name: 'John Smith',
    contact_email: 'jsmith@acme.com',
    contact_phone: '(555) 123-4567',
    notes: 'Legacy import - priority repair'
  };
  for (let s = 2; s <= 18; s++) {
    sampleRow[stageColHeader(s)] = (s === GLASS_STAGE) ? 'N' : 'Y';
  }

  const ws = XLSX.utils.json_to_sheet([instructions, sampleRow], { header: allHeaders });

  ws['!cols'] = allHeaders.map(h => ({
    wch: h.startsWith('Stage ') ? 14 : Math.max(h.length + 2, 18)
  }));

  // ─── Reference sheet ────────────────────────────────────
  const refData = [];
  refData.push({ A: 'STAGE REFERENCE', B: '', C: '', D: '' });
  refData.push({ A: 'Stage #', B: 'Stage Name', C: 'Skippable?', D: 'Notes' });
  for (let s = 1; s <= MAX_STAGE; s++) {
    refData.push({
      A: s,
      B: STAGE_NAMES[s],
      C: (s === 1 || s === MAX_STAGE) ? 'No (always required)' : 'Yes',
      D: s === 1 ? 'Inspection - always first'
        : s === GLASS_STAGE ? 'Auto-skipped for CRJ parts'
        : s === MAX_STAGE ? 'Always required'
        : ''
    });
  }
  refData.push({ A: '', B: '', C: '', D: '' });
  refData.push({ A: 'VALID STATUSES', B: '', C: '', D: '' });
  refData.push({ A: 'In Progress', B: 'Unit is actively being worked on', C: '', D: '' });
  refData.push({ A: 'On Hold', B: 'Unit is paused / waiting', C: '', D: '' });
  refData.push({ A: 'Completed', B: 'Unit is finished and shipped', C: '', D: '' });
  refData.push({ A: '', B: '', C: '', D: '' });
  refData.push({ A: 'CONTRACT TYPES', B: '', C: '', D: '' });
  refData.push({ A: 'Commercial Sales', B: 'Default contract type', C: '', D: '' });
  refData.push({ A: 'C12', B: 'Government / C12 contract', C: '', D: '' });
  refData.push({ A: '', B: '', C: '', D: '' });
  refData.push({ A: 'VALID PART NUMBERS', B: '', C: '', D: '' });
  productionParts.forEach(p => {
    refData.push({ A: p.partNumber, B: p.description || '', C: '', D: '' });
  });
  refData.push({ A: '', B: '', C: '', D: '' });
  refData.push({ A: 'HOW TO USE', B: '', C: '', D: '' });
  refData.push({ A: '1.', B: 'Fill in one row per work order on the "Work Orders" sheet', C: '', D: '' });
  refData.push({ A: '2.', B: 'ro_number is the work order number (required, must be unique)', C: '', D: '' });
  refData.push({ A: '3.', B: 'Set current_stage to the stage the unit is at RIGHT NOW', C: '', D: '' });
  refData.push({ A: '4.', B: 'For each stage column (2-18): Y = stage applies, N = skip it', C: '', D: '' });
  refData.push({ A: '5.', B: 'Leave stage columns blank to default to Y (applies)', C: '', D: '' });
  refData.push({ A: '6.', B: 'CRJ parts auto-skip Stage 7 (Glass Installation) regardless', C: '', D: '' });
  refData.push({ A: '7.', B: 'Delete the INSTRUCTIONS row before uploading', C: '', D: '' });

  const wsRef = XLSX.utils.json_to_sheet(refData, { header: ['A', 'B', 'C', 'D'], skipHeader: true });
  wsRef['!cols'] = [{ wch: 24 }, { wch: 50 }, { wch: 22 }, { wch: 30 }];

  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, 'Work Orders');
  XLSX.utils.book_append_sheet(wb, wsRef, 'Reference');
  XLSX.writeFile(wb, 'Glass_Aero_Legacy_Import_Template.xlsx');
}

// ─── Helpers ────────────────────────────────────────────

function parseSkippedStages(row) {
  const skipped = [];
  for (let s = 2; s <= 18; s++) {
    const colKey = stageColHeader(s);
    const val = String(row[colKey] || '').trim().toUpperCase();
    if (val === 'N' || val === 'NO') {
      skipped.push(s);
    }
  }
  const partNumber = String(row.part_number || '').trim();
  if (isCRJPart(partNumber) && !skipped.includes(GLASS_STAGE)) {
    skipped.push(GLASS_STAGE);
  }
  return skipped.sort((a, b) => a - b);
}

function describeSkippedStages(skipped) {
  if (!skipped || skipped.length === 0) return 'None';
  return skipped.map(s => `${s}`).join(', ');
}

// ─── File Upload & Parse ────────────────────────────────
function handleFile(file) {
  document.getElementById('fileName').textContent = file.name;

  const reader = new FileReader();
  reader.onload = function(e) {
    const data = new Uint8Array(e.target.result);
    const workbook = XLSX.read(data, { type: 'array', cellDates: true });
    const sheet = workbook.Sheets[workbook.SheetNames[0]];
    const rows = XLSX.utils.sheet_to_json(sheet, { defval: '' });

    parsedRows = rows.filter(r => {
      const roVal = String(r.ro_number || r.customer_name || '').toUpperCase();
      return (r.customer_name || r.ro_number) && !roVal.includes('INSTRUCTION');
    });

    validateAndPreview();
  };
  reader.readAsArrayBuffer(file);
}

function validateAndPreview() {
  const validPartNumbers = productionParts.map(p => p.partNumber);
  const table = document.getElementById('previewTable');
  let validCount = 0;
  let errorCount = 0;

  table.innerHTML = parsedRows.map((row, idx) => {
    const issues = [];

    if (!row.ro_number) issues.push('Missing WO number (ro_number)');
    if (!row.customer_name) issues.push('Missing customer name');
    if (!row.part_number) issues.push('Missing part number');
    else if (!validPartNumbers.includes(String(row.part_number).trim())) {
      issues.push(`Unknown part: "${row.part_number}"`);
    }
    if (!row.serial_number) issues.push('Missing serial number');

    const stage = Number(row.current_stage) || 1;
    if (stage < 1 || stage > MAX_STAGE) issues.push(`Invalid stage: ${stage}`);

    const skipped = parseSkippedStages(row);
    if (stage > 1 && skipped.includes(stage)) {
      issues.push(`Current stage ${stage} is marked as skipped`);
    }

    row._skippedStages = skipped;
    row._issues = issues;
    row._valid = issues.length === 0;
    row._index = idx;

    if (row._valid) validCount++;
    else errorCount++;

    const statusIcon = row._valid
      ? '<i class="fas fa-check-circle text-emerald-400"></i>'
      : '<i class="fas fa-exclamation-circle text-red-400"></i>';

    const skippedLabel = skipped.length > 0
      ? `<span class="text-yellow-400" title="Skipped: ${skipped.map(s => STAGE_NAMES[s]).join(', ')}">` +
        `${skipped.length} skipped</span>`
      : '<span class="text-gray-500">None</span>';

    return `
      <tr class="border-b border-white/5 ${row._valid ? '' : 'bg-red-500/5'}">
        <td class="py-2 px-3">${statusIcon}</td>
        <td class="py-2 px-3 text-white font-mono text-xs">${row.ro_number || '--'}</td>
        <td class="py-2 px-3 text-white">${row.customer_name || '--'}</td>
        <td class="py-2 px-3 text-gray-300 font-mono text-xs">${row.part_number || '--'}</td>
        <td class="py-2 px-3 text-gray-300">${row.serial_number || '--'}</td>
        <td class="py-2 px-3 text-gray-400">${stage}</td>
        <td class="py-2 px-3 text-xs">${skippedLabel}</td>
        <td class="py-2 px-3 text-xs ${issues.length > 0 ? 'text-red-400' : 'text-emerald-400'}">
          ${issues.length > 0 ? issues.join('; ') : 'Ready'}
        </td>
      </tr>
    `;
  }).join('');

  document.getElementById('previewSection').classList.remove('hidden');
  document.getElementById('previewSummary').textContent =
    `${parsedRows.length} rows found — ${validCount} valid, ${errorCount} with errors`;

  if (validCount > 0) {
    document.getElementById('importBtn').classList.remove('hidden');
    document.getElementById('importBtn').innerHTML =
      `<i class="fas fa-file-import mr-2"></i>Import ${validCount} Valid Orders`;
  } else {
    document.getElementById('importBtn').classList.add('hidden');
  }
}

// ─── Import Logic ───────────────────────────────────────
async function importAll() {
  const validRows = parsedRows.filter(r => r._valid);
  if (validRows.length === 0) return;

  if (!confirm(`Import ${validRows.length} work orders? Rows with errors will be skipped.`)) return;

  const btn = document.getElementById('importBtn');
  btn.disabled = true;
  btn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>Importing...';

  const progress = document.getElementById('importProgress');
  const progressBar = document.getElementById('importProgressBar');
  const progressText = document.getElementById('importProgressText');
  const progressCount = document.getElementById('importProgressCount');
  progress.classList.remove('hidden');

  let imported = 0;
  let failed = 0;

  for (let i = 0; i < validRows.length; i++) {
    const row = validRows[i];
    progressText.textContent = `Importing ${row.serial_number || row.customer_name}...`;
    progressCount.textContent = `${i + 1} of ${validRows.length}`;
    progressBar.style.width = `${((i + 1) / validRows.length) * 100}%`;

    try {
      await importSingleOrder(row);
      imported++;
    } catch (err) {
      console.error('Error importing row:', row, err);
      failed++;
    }
  }

  progress.classList.add('hidden');

  alert(`Import complete!\n\n${imported} orders imported successfully${failed > 0 ? `\n${failed} orders failed` : ''}`);
  window.location.href = 'repair-orders.html';
}

async function importSingleOrder(row) {
  const partNumber = String(row.part_number).trim();
  const currentStage = Number(row.current_stage) || 1;
  const skippedStages = row._skippedStages || parseSkippedStages(row);
  const now = new Date().toISOString();

  let dateReceived = null;
  if (row.date_received) {
    const d = row.date_received instanceof Date ? row.date_received : new Date(row.date_received);
    if (!isNaN(d)) dateReceived = d.toISOString();
  }

  let expectedCompletion = null;
  if (row.expected_completion) {
    const d = row.expected_completion instanceof Date ? row.expected_completion : new Date(row.expected_completion);
    if (!isNaN(d)) expectedCompletion = d.toISOString();
  }

  const status = row.status && ['In Progress', 'On Hold', 'Completed'].includes(row.status)
    ? row.status : 'In Progress';

  const orderData = {
    roNumber: String(row.ro_number).trim(),
    customerName: String(row.customer_name).trim(),
    partNumber: partNumber,
    serialNumber: String(row.serial_number).trim(),
    contractType: row.contract_type || 'Commercial Sales',
    currentStage: currentStage,
    status: status,
    skippedStages: skippedStages,
    dateReceived: dateReceived || now,
    expectedCompletion: expectedCompletion,
    purchaseOrder: row.purchase_order ? String(row.purchase_order).trim() : null,
    invoiceNumber: row.invoice_number ? String(row.invoice_number).trim() : null,
    aircraftTailNumber: row.aircraft_tail_number ? String(row.aircraft_tail_number).trim() : null,
    aircraftType: row.aircraft_type ? String(row.aircraft_type).trim() : null,
    shippingAddress: row.shipping_address ? String(row.shipping_address).trim() : null,
    contactName: row.contact_name ? String(row.contact_name).trim() : null,
    contactEmail: row.contact_email ? String(row.contact_email).trim() : null,
    contactPhone: row.contact_phone ? String(row.contact_phone).trim() : null,
    notes: row.notes ? String(row.notes).trim() : null,
    dateCompleted: status === 'Completed' ? (dateReceived || now) : null
  };

  const saved = await db.saveRepairOrder(orderData);
  if (!saved) throw new Error('Failed to save work order');

  // Build stage history, skipping stages the inspection marked as N/A
  const baseTime = dateReceived ? new Date(dateReceived) : new Date();
  let historyIndex = 0;
  for (let s = 1; s <= currentStage; s++) {
    if (skippedStages.includes(s)) continue;

    const stageDef = stages.find(st => st.stageNumber === s);
    const enteredAt = new Date(baseTime.getTime() + historyIndex * 60000);
    const isCurrentStage = s === currentStage;

    await db.addStageEntry({
      repairOrderId: saved.id,
      stageNumber: s,
      stageName: stageDef?.stageName || STAGE_NAMES[s] || `Stage ${s}`,
      enteredAt: enteredAt.toISOString(),
      exitedAt: isCurrentStage ? null : new Date(enteredAt.getTime() + 60000).toISOString(),
      notes: isCurrentStage ? null : 'Imported — prior stage'
    });
    historyIndex++;
  }
}

// ─── Init ───────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', async () => {
  const user = await initializeAuth();
  if (!user || !isAdmin(user)) {
    window.location.href = 'repair-orders.html';
    return;
  }
  await loadImportPage();

  document.getElementById('importFileInput').addEventListener('change', (e) => {
    if (e.target.files.length > 0) {
      handleFile(e.target.files[0]);
    }
  });
});
