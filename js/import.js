// Import Repair Orders page logic
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
  const headers = [
    'customer_name', 'part_number', 'serial_number', 'contract_type',
    'current_stage', 'status', 'date_received', 'expected_completion',
    'purchase_order', 'invoice_number', 'aircraft_tail_number', 'aircraft_type',
    'shipping_address', 'contact_name', 'contact_email', 'contact_phone', 'notes'
  ];

  const validParts = productionParts.map(p => p.partNumber).join(', ');

  const sampleRow = {
    customer_name: 'ACME Aviation',
    part_number: productionParts.length > 0 ? productionParts[0].partNumber : '101-384025-21',
    serial_number: 'SN-12345',
    contract_type: 'Commercial Sales',
    current_stage: 3,
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
    notes: 'Priority repair'
  };

  const instructions = {
    customer_name: 'INSTRUCTIONS (delete this row)',
    part_number: `Valid: ${validParts}`,
    serial_number: 'Required',
    contract_type: 'Commercial Sales or C12',
    current_stage: '1-15 (default 1)',
    status: 'In Progress, On Hold, Completed',
    date_received: 'YYYY-MM-DD format',
    expected_completion: 'YYYY-MM-DD format',
    purchase_order: 'Optional',
    invoice_number: 'Optional',
    aircraft_tail_number: 'Optional',
    aircraft_type: 'Optional',
    shipping_address: 'Optional',
    contact_name: 'Optional',
    contact_email: 'Optional',
    contact_phone: 'Optional',
    notes: 'Optional'
  };

  const ws = XLSX.utils.json_to_sheet([instructions, sampleRow], { header: headers });

  // Set column widths
  ws['!cols'] = headers.map(h => ({ wch: Math.max(h.length + 2, 18) }));

  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, 'Repair Orders');
  XLSX.writeFile(wb, 'Glass_Aero_Import_Template.xlsx');
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

    // Filter out instruction rows
    parsedRows = rows.filter(r =>
      r.customer_name &&
      !String(r.customer_name).toUpperCase().includes('INSTRUCTION')
    );

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

    if (!row.customer_name) issues.push('Missing customer name');
    if (!row.part_number) issues.push('Missing part number');
    else if (!validPartNumbers.includes(String(row.part_number).trim())) {
      issues.push(`Unknown part: "${row.part_number}"`);
    }
    if (!row.serial_number) issues.push('Missing serial number');

    const stage = Number(row.current_stage) || 1;
    if (stage < 1 || stage > 15) issues.push(`Invalid stage: ${stage}`);

    row._issues = issues;
    row._valid = issues.length === 0;
    row._index = idx;

    if (row._valid) validCount++;
    else errorCount++;

    const statusIcon = row._valid
      ? '<i class="fas fa-check-circle text-emerald-400"></i>'
      : '<i class="fas fa-exclamation-circle text-red-400"></i>';

    return `
      <tr class="border-b border-white/5 ${row._valid ? '' : 'bg-red-500/5'}">
        <td class="py-2 px-3">${statusIcon}</td>
        <td class="py-2 px-3 text-white">${row.customer_name || '--'}</td>
        <td class="py-2 px-3 text-gray-300 font-mono text-xs">${row.part_number || '--'}</td>
        <td class="py-2 px-3 text-gray-300">${row.serial_number || '--'}</td>
        <td class="py-2 px-3 text-gray-400">${stage}</td>
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
    document.getElementById('importBtn').textContent = `Import ${validCount} Valid Orders`;
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

  if (!confirm(`Import ${validRows.length} repair orders? Rows with errors will be skipped.`)) return;

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
    customerName: String(row.customer_name).trim(),
    partNumber: partNumber,
    serialNumber: String(row.serial_number).trim(),
    contractType: row.contract_type || 'Commercial Sales',
    currentStage: currentStage,
    status: status,
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
    dateCompleted: status === 'Completed' ? now : null
  };

  const saved = await db.saveRepairOrder(orderData);
  if (!saved) throw new Error('Failed to save repair order');

  // Create stage history entries for all stages up to and including currentStage
  const baseTime = dateReceived ? new Date(dateReceived) : new Date();
  for (let s = 1; s <= currentStage; s++) {
    const stageDef = stages.find(st => st.stageNumber === s);
    const enteredAt = new Date(baseTime.getTime() + (s - 1) * 60000);
    const isCurrentStage = s === currentStage;

    await db.addStageEntry({
      repairOrderId: saved.id,
      stageNumber: s,
      stageName: stageDef?.stageName || `Stage ${s}`,
      enteredAt: enteredAt.toISOString(),
      exitedAt: isCurrentStage ? null : new Date(enteredAt.getTime() + 60000).toISOString(),
      notes: isCurrentStage ? null : 'Imported — prior stage'
    });
  }
}

// ─── Init ───────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', async () => {
  await initializeAuth();
  await loadImportPage();

  document.getElementById('importFileInput').addEventListener('change', (e) => {
    if (e.target.files.length > 0) {
      handleFile(e.target.files[0]);
    }
  });
});
