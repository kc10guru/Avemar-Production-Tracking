// Repair Order Detail page logic
let order = null;
let stages = [];
let history = [];
let issuedParts = [];
let currentUser = null;
let productionParts = [];

async function loadPage() {
  const params = new URLSearchParams(window.location.search);
  const id = params.get('id');
  if (!id) { window.location.href = 'repair-orders.html'; return; }

  currentUser = await getCurrentUser();

  [order, stages, history, issuedParts, productionParts] = await Promise.all([
    db.getRepairOrder(id),
    db.getProductionStages(),
    db.getStageHistory(id),
    db.getPartsIssuance(id),
    db.getProductionParts()
  ]);

  if (!order) {
    document.getElementById('roTitle').textContent = 'Order Not Found';
    return;
  }

  renderHeader();
  renderStageProgress();
  renderOrderDetails();
  renderStageTimeline();
  renderPartsIssued();
}

function renderHeader() {
  document.getElementById('roTitle').textContent = order.roNumber;
  const stageName = stages.find(s => s.stageNumber === order.currentStage)?.stageName || '';
  document.getElementById('roSubtitle').textContent = `${order.customerName} — Stage ${order.currentStage}: ${stageName}`;

  if (order.status === 'In Progress' && order.currentStage <= 15) {
    document.getElementById('advanceBtn').classList.remove('hidden');
  }
}

function renderStageProgress() {
  const container = document.getElementById('stageProgress');
  const html = [];

  stages.forEach((stage, idx) => {
    let dotClass = 'pending';
    if (stage.stageNumber < order.currentStage) dotClass = 'completed';
    else if (stage.stageNumber === order.currentStage) dotClass = 'current';

    html.push(`
      <div class="flex flex-col items-center flex-shrink-0" title="${stage.stageName}">
        <div class="stage-dot ${dotClass}">${stage.stageNumber}</div>
        <span class="text-xs mt-1 ${dotClass === 'current' ? 'text-avemar-sky' : dotClass === 'completed' ? 'text-emerald-400' : 'text-gray-600'} max-w-[70px] text-center leading-tight">
          ${stage.stageName}
        </span>
      </div>
    `);

    if (idx < stages.length - 1) {
      const connClass = stage.stageNumber < order.currentStage ? 'completed' : 'pending';
      html.push(`<div class="stage-connector ${connClass} flex-shrink-0"></div>`);
    }
  });

  container.innerHTML = html.join('');
}

function renderOrderDetails() {
  const container = document.getElementById('orderDetails');

  const statusColors = {
    'In Progress': 'bg-sky-500/20 text-sky-400',
    'Completed': 'bg-emerald-500/20 text-emerald-400',
    'On Hold': 'bg-amber-500/20 text-amber-400',
    'Cancelled': 'bg-red-500/20 text-red-400'
  };
  const statusClass = statusColors[order.status] || 'bg-gray-500/20 text-gray-400';

  const fields = [
    { label: 'Status', value: `<span class="px-3 py-1 rounded-full text-xs ${statusClass}">${order.status}</span>` },
    { label: 'Part Number', value: order.partNumber },
    { label: 'Serial Number', value: order.serialNumber },
    { label: 'Customer', value: order.customerName },
    { label: 'Contract Type', value: order.contractType },
    { label: 'Purchase Order', value: order.purchaseOrder || '--' },
    { label: 'Aircraft', value: [order.aircraftTailNumber, order.aircraftType].filter(Boolean).join(' / ') || '--' },
    { label: 'Shipping Address', value: order.shippingAddress || '--' },
    { label: 'Contact', value: [order.contactName, order.contactEmail, order.contactPhone].filter(Boolean).join(' | ') || '--' },
    { label: 'Date Received', value: order.dateReceived ? new Date(order.dateReceived).toLocaleDateString() : '--' },
    { label: 'Expected Completion', value: order.expectedCompletion ? new Date(order.expectedCompletion).toLocaleDateString() : '--' },
    { label: 'Date Completed', value: order.dateCompleted ? new Date(order.dateCompleted).toLocaleDateString() : '--' },
  ];

  container.innerHTML = fields.map(f => `
    <div>
      <span class="text-gray-500 text-xs uppercase">${f.label}</span>
      <p class="text-white mt-1">${f.value}</p>
    </div>
  `).join('');

  if (order.notes) {
    container.innerHTML += `
      <div class="col-span-2 border-t border-white/10 pt-4 mt-2">
        <span class="text-gray-500 text-xs uppercase">Notes</span>
        <p class="text-gray-300 mt-1">${order.notes}</p>
      </div>`;
  }
}

function renderStageTimeline() {
  const container = document.getElementById('stageTimeline');

  if (history.length === 0) {
    container.innerHTML = '<div class="text-gray-400 text-center py-4">No stage history yet</div>';
    return;
  }

  container.innerHTML = history.map(entry => {
    const entered = new Date(entry.enteredAt);
    const exited = entry.exitedAt ? new Date(entry.exitedAt) : null;
    const isActive = !entry.exitedAt && entry.stageNumber === order.currentStage;

    let duration = '';
    if (exited) {
      const hrs = Math.round((exited - entered) / (1000 * 60 * 60) * 10) / 10;
      duration = `${hrs}h`;
    } else if (isActive) {
      const hrs = Math.round((new Date() - entered) / (1000 * 60 * 60) * 10) / 10;
      duration = `${hrs}h (in progress)`;
    }

    return `
      <div class="flex gap-3">
        <div class="flex flex-col items-center">
          <div class="w-3 h-3 rounded-full ${isActive ? 'bg-avemar-sky animate-pulse' : exited ? 'bg-emerald-500' : 'bg-gray-600'}"></div>
          <div class="w-0.5 flex-1 ${exited ? 'bg-emerald-500/30' : 'bg-gray-700'}"></div>
        </div>
        <div class="pb-4 flex-1">
          <p class="font-medium text-sm text-white">${entry.stageNumber}. ${entry.stageName}</p>
          <p class="text-xs text-gray-400 mt-1">
            ${entered.toLocaleDateString()} ${entered.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
            ${duration ? ` — ${duration}` : ''}
          </p>
          ${entry.notes ? `<p class="text-xs text-gray-500 mt-1 italic">${entry.notes}</p>` : ''}
          ${entry.isLate ? '<span class="text-xs text-red-400"><i class="fas fa-clock mr-1"></i>Late</span>' : ''}
        </div>
      </div>
    `;
  }).join('');
}

function renderPartsIssued() {
  const container = document.getElementById('partsIssued');

  if (issuedParts.length === 0) {
    container.innerHTML = '<div class="text-gray-400 text-center py-4 text-sm">No parts issued yet</div>';
    return;
  }

  container.innerHTML = `
    <table class="w-full text-sm">
      <thead>
        <tr class="border-b border-white/10">
          <th class="text-left py-2 text-xs text-gray-400 font-medium">Part</th>
          <th class="text-left py-2 text-xs text-gray-400 font-medium">Stage</th>
          <th class="text-right py-2 text-xs text-gray-400 font-medium">Qty</th>
          <th class="text-right py-2 text-xs text-gray-400 font-medium">Date</th>
        </tr>
      </thead>
      <tbody>
        ${issuedParts.map(p => `
          <tr class="border-b border-white/5">
            <td class="py-2 text-white">${p.subcomponents?.partNumber || '--'}</td>
            <td class="py-2 text-gray-400">${p.stageNumber}</td>
            <td class="py-2 text-right text-gray-300">${p.quantityIssued}</td>
            <td class="py-2 text-right text-gray-500">${new Date(p.issuedAt).toLocaleDateString()}</td>
          </tr>
        `).join('')}
      </tbody>
    </table>
  `;
}

// ─── Stage Advancement ──────────────────────────────────
function showAdvanceModal() {
  const nextStageNum = order.currentStage + 1;
  const nextStage = stages.find(s => s.stageNumber === nextStageNum);
  const currentStage = stages.find(s => s.stageNumber === order.currentStage);

  document.getElementById('advanceDescription').textContent =
    `Moving from "${currentStage?.stageName}" to "${nextStage?.stageName || 'Completed'}"`;

  // Load BOM parts for the next stage
  loadBomPartsForStage(nextStageNum);

  document.getElementById('advanceModal').classList.remove('hidden');
}

function hideAdvanceModal() {
  document.getElementById('advanceModal').classList.add('hidden');
  document.getElementById('advanceNotes').value = '';
}

async function loadBomPartsForStage(stageNumber) {
  const section = document.getElementById('bomPartsSection');
  const list = document.getElementById('bomPartsList');

  // Find the production part ID
  const prodPart = productionParts.find(p => p.partNumber === order.partNumber);
  if (!prodPart) { section.classList.add('hidden'); return; }

  const bomItems = await db.getBomForStage(prodPart.id, stageNumber);
  if (bomItems.length === 0) {
    section.classList.add('hidden');
    return;
  }

  section.classList.remove('hidden');
  list.innerHTML = bomItems.map(item => {
    const sub = item.subcomponents;
    const hasStock = sub && Number(sub.quantityOnHand) >= Number(item.quantityRequired);
    return `
      <div class="flex items-center justify-between p-3 bg-white/5 rounded-lg">
        <div>
          <span class="text-white text-sm">${sub?.partNumber || '--'}</span>
          <span class="text-gray-400 text-xs ml-2">${sub?.description || ''}</span>
        </div>
        <div class="flex items-center gap-3">
          <span class="text-xs ${hasStock ? 'text-emerald-400' : 'text-red-400'}">
            ${sub?.quantityOnHand || 0} avail
          </span>
          <span class="text-white text-sm font-medium">x${item.quantityRequired}</span>
          <input type="checkbox" checked data-bom-id="${item.id}" data-sub-id="${sub?.id}" data-qty="${item.quantityRequired}"
            class="bom-checkbox w-4 h-4 rounded border-gray-600 bg-white/10 text-avemar-gold focus:ring-avemar-gold">
        </div>
      </div>
    `;
  }).join('');
}

async function advanceStage() {
  const btn = document.getElementById('confirmAdvanceBtn');
  btn.disabled = true;
  btn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>Processing...';

  try {
    const notes = document.getElementById('advanceNotes').value.trim();
    const now = new Date().toISOString();
    const userId = currentUser?.id || null;

    // Close current stage history entry
    const currentEntry = history.find(h => h.stageNumber === order.currentStage && !h.exitedAt);
    if (currentEntry) {
      // Check if late
      const currentStageDef = stages.find(s => s.stageNumber === order.currentStage);
      const enteredAt = new Date(currentEntry.enteredAt);
      const hoursInStage = (new Date() - enteredAt) / (1000 * 60 * 60);
      const isLate = currentStageDef && hoursInStage > currentStageDef.timeLimitHours;

      await db.updateStageEntry(currentEntry.id, {
        exitedAt: now,
        completedBy: userId,
        notes: notes || null,
        isLate: isLate
      });
    }

    // Issue checked BOM parts
    const checkboxes = document.querySelectorAll('.bom-checkbox:checked');
    for (const cb of checkboxes) {
      await db.issuePart({
        repairOrderId: order.id,
        subcomponentId: cb.dataset.subId,
        bomItemId: cb.dataset.bomId,
        stageNumber: order.currentStage + 1,
        quantityIssued: Number(cb.dataset.qty),
        issuedBy: userId
      });
    }

    const newStage = order.currentStage + 1;
    const isComplete = newStage > 15;

    // Update repair order
    const updateData = {
      currentStage: isComplete ? 15 : newStage,
      status: isComplete ? 'Completed' : 'In Progress'
    };
    if (isComplete) updateData.dateCompleted = now;
    await db.updateRepairOrder(order.id, updateData);

    // Create next stage history entry (if not complete)
    if (!isComplete) {
      const nextStage = stages.find(s => s.stageNumber === newStage);
      await db.addStageEntry({
        repairOrderId: order.id,
        stageNumber: newStage,
        stageName: nextStage?.stageName || `Stage ${newStage}`,
        enteredAt: now
      });
    }

    hideAdvanceModal();
    await loadPage();
  } catch (error) {
    console.error('Error advancing stage:', error);
    alert('Failed to advance stage. Please try again.');
  }

  btn.disabled = false;
  btn.innerHTML = '<i class="fas fa-check mr-2"></i>Confirm';
}

document.addEventListener('DOMContentLoaded', async () => {
  await initializeAuth();
  await loadPage();
});
