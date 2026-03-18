// Scan & Advance page - shop floor tablet
const INSPECTION_STAGE = 1;
let order = null;
let stages = [];
let history = [];
let productionParts = [];
let currentUser = null;

function getSkippedStages() {
  return order?.skippedStages || [];
}

function isStageSkipped(stageNum) {
  return getSkippedStages().includes(stageNum);
}

function getNextActiveStage(fromStage) {
  let next = fromStage + 1;
  while (next <= 19 && isStageSkipped(next)) next++;
  return next;
}

async function lookupOrder(roNumber) {
  const trimmed = String(roNumber).trim();
  if (!trimmed) return;

  document.getElementById('readyState').classList.add('hidden');
  document.getElementById('errorState').classList.add('hidden');
  document.getElementById('resultArea').classList.add('hidden');
  document.getElementById('orderContent').innerHTML = '<div class="text-center py-8"><i class="fas fa-spinner fa-spin text-3xl text-glassAero-gold"></i><p class="mt-2 text-gray-400">Looking up...</p></div>';

  const found = await db.getRepairOrderByRoNumber(trimmed);
  if (!found) {
    document.getElementById('errorMessage').textContent = `No repair order found for "${trimmed}"`;
    document.getElementById('errorState').classList.remove('hidden');
    document.getElementById('scanInput').value = '';
    document.getElementById('scanInput').focus();
    return;
  }

  [order, stages, history, productionParts] = await Promise.all([
    Promise.resolve(found),
    db.getProductionStages(),
    db.getStageHistory(found.id),
    db.getProductionParts()
  ]);

  renderOrder();
  document.getElementById('resultArea').classList.remove('hidden');
  document.getElementById('scanInput').value = '';
  document.getElementById('scanInput').focus();
}

function renderOrder() {
  const container = document.getElementById('orderContent');
  const stageDef = stages.find(s => s.stageNumber === order.currentStage);
  const stageName = stageDef?.stageName || `Stage ${order.currentStage}`;
  const isOnHold = order.isOnHold || order.status === 'On Hold';
  const isComplete = order.status === 'Completed';
  const atInspection = order.currentStage === INSPECTION_STAGE;

  let advanceHtml = '';
  if (isComplete) {
    advanceHtml = '<p class="text-emerald-400 text-lg font-semibold"><i class="fas fa-check-circle mr-2"></i>Order Complete</p>';
  } else if (isOnHold) {
    advanceHtml = `
      <div class="bg-red-500/20 border border-red-500/30 rounded-xl p-4 mb-4">
        <p class="text-red-400 font-semibold"><i class="fas fa-hand-paper mr-2"></i>On Hold</p>
        <p class="text-gray-300 text-sm mt-1">${order.holdReason || 'No reason provided'}</p>
      </div>
      <p class="text-gray-400">Resume this order from a computer terminal.</p>
    `;
  } else if (atInspection) {
    advanceHtml = `
      <div class="bg-amber-500/20 border border-amber-500/30 rounded-xl p-4 mb-4">
        <p class="text-amber-400 font-semibold"><i class="fas fa-clipboard-check mr-2"></i>Inspection Required</p>
        <p class="text-gray-300 text-sm mt-1">Complete the inspection checklist on a computer terminal, then use this page to advance through later stages.</p>
      </div>
      <a href="repair-order-detail.html?id=${order.id}" class="block w-full bg-glassAero-sky/20 hover:bg-glassAero-sky/30 border border-glassAero-sky/50 text-glassAero-sky py-4 rounded-xl font-semibold text-center transition">
        <i class="fas fa-external-link-alt mr-2"></i>Open on Computer
      </a>
    `;
  } else {
    const nextStage = getNextActiveStage(order.currentStage);
    const nextDef = stages.find(s => s.stageNumber === nextStage);
    const nextName = nextDef?.stageName || (nextStage > 19 ? 'Complete' : `Stage ${nextStage}`);
    advanceHtml = `
      <button onclick="advanceOrder()" id="advanceBtn" class="w-full btn-advance bg-glassAero-emerald hover:bg-emerald-600 text-white rounded-xl font-bold transition flex items-center justify-center gap-3">
        <i class="fas fa-arrow-right text-2xl"></i>
        Advance to ${nextStage > 19 ? 'Complete' : nextName}
      </button>
    `;
  }

  container.innerHTML = `
    <div class="mb-4">
      <h2 class="text-2xl font-bold text-glassAero-gold font-mono">${order.roNumber}</h2>
      <p class="text-gray-400 text-sm mt-1">${order.customerName || '--'}</p>
      <p class="text-gray-400 text-sm">${order.partNumber || '--'} · ${order.serialNumber || '--'}</p>
    </div>
    <div class="mb-4 flex items-center gap-2">
      <span class="px-3 py-1 rounded-full text-sm font-medium ${isOnHold ? 'bg-red-500/20 text-red-400' : isComplete ? 'bg-emerald-500/20 text-emerald-400' : 'bg-glassAero-sky/20 text-glassAero-sky'}">
        ${isComplete ? 'Complete' : isOnHold ? 'On Hold' : `Stage ${order.currentStage}: ${stageName}`}
      </span>
    </div>
    ${advanceHtml}
  `;
}

async function advanceOrder() {
  if (!order || order.status === 'Completed' || order.isOnHold || order.currentStage === INSPECTION_STAGE) return;

  const btn = document.getElementById('advanceBtn');
  if (btn) {
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin text-2xl mr-2"></i>Processing...';
  }

  try {
    const now = new Date().toISOString();
    const userId = currentUser?.id || null;

    const currentEntry = history.find(h => h.stageNumber === order.currentStage && !h.exitedAt);
    if (currentEntry) {
      const currentStageDef = stages.find(s => s.stageNumber === order.currentStage);
      const enteredAt = new Date(currentEntry.enteredAt);
      const hoursInStage = window.calculateBusinessHours ? window.calculateBusinessHours(enteredAt, new Date()) : 0;
      const isLate = currentStageDef && hoursInStage > currentStageDef.timeLimitHours;

      await db.updateStageEntry(currentEntry.id, {
        exitedAt: now,
        completedBy: userId,
        notes: 'Advanced via scan',
        isLate: isLate
      });
    }

    const newStage = getNextActiveStage(order.currentStage);
    const isComplete = newStage > 19;

    const prodPart = productionParts.find(p => p.partNumber === order.partNumber);
    if (prodPart && !isComplete) {
      const bomItems = await db.getBomForStage(prodPart.id, newStage);
      for (const item of bomItems) {
        const subId = item.subcomponentId || item.subcomponents?.id;
        if (subId) {
          await db.issuePart({
            repairOrderId: order.id,
            subcomponentId: subId,
            bomItemId: item.id,
            stageNumber: newStage,
            quantityIssued: Number(item.quantityRequired),
            issuedBy: userId
          });
        }
      }
    }

    const updateData = {
      currentStage: isComplete ? 19 : newStage,
      status: isComplete ? 'Completed' : 'In Progress'
    };
    if (isComplete) updateData.dateCompleted = now;
    await db.updateRepairOrder(order.id, updateData);

    if (!isComplete) {
      const nextStageDef = stages.find(s => s.stageNumber === newStage);
      await db.addStageEntry({
        repairOrderId: order.id,
        stageNumber: newStage,
        stageName: nextStageDef?.stageName || `Stage ${newStage}`,
        enteredAt: now
      });
    }

    if (isComplete) {
      document.getElementById('orderContent').innerHTML = `
        <div class="text-center py-6">
          <i class="fas fa-check-circle text-6xl text-emerald-400 mb-4"></i>
          <p class="text-xl font-bold text-emerald-400">${order.roNumber} Complete!</p>
          <p class="text-gray-400 mt-2">Ready for next scan</p>
        </div>
      `;
      setTimeout(() => {
        document.getElementById('resultArea').classList.add('hidden');
        document.getElementById('readyState').classList.remove('hidden');
        document.getElementById('scanInput').focus();
      }, 2000);
    } else {
      order.currentStage = newStage;
      history = await db.getStageHistory(order.id);
      renderOrder();
    }
  } catch (error) {
    console.error('Error advancing:', error);
    alert('Failed to advance. Please try again.');
  }

  const advanceBtn = document.getElementById('advanceBtn');
  if (advanceBtn) {
    advanceBtn.disabled = false;
    const nextStage = getNextActiveStage(order.currentStage);
    const nextDef = stages.find(s => s.stageNumber === nextStage);
    advanceBtn.innerHTML = `<i class="fas fa-arrow-right text-2xl"></i> Advance to ${nextStage > 19 ? 'Complete' : nextDef?.stageName || `Stage ${nextStage}`}`;
  }
}

document.addEventListener('DOMContentLoaded', async () => {
  const user = await requireAuth();
  if (!user) {
    window.location.href = 'login.html?redirect=' + encodeURIComponent('scan.html');
    return;
  }
  currentUser = user;
  await window.loadBusinessHoursConfig();

  const scanInput = document.getElementById('scanInput');
  scanInput.focus();

  scanInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      lookupOrder(scanInput.value);
    }
  });

  document.body.addEventListener('click', () => scanInput.focus());
});
