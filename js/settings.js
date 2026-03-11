// Settings page logic
let parts = [];
let stages = [];

async function loadSettings() {
  [parts, stages] = await Promise.all([
    db.getProductionParts(),
    db.getProductionStages()
  ]);

  renderParts();
  renderStages();
  await loadBusinessHours();

  document.getElementById('dbStatus').innerHTML =
    '<i class="fas fa-check-circle mr-1"></i>Connected';
}

function renderParts() {
  const container = document.getElementById('partsList');

  if (parts.length === 0) {
    container.innerHTML = '<div class="text-gray-400 text-center py-4">No part numbers configured.</div>';
    return;
  }

  container.innerHTML = parts.map(p => `
    <div class="flex items-center justify-between p-3 bg-white/5 rounded-lg">
      <div>
        <span class="text-white font-mono text-sm">${p.partNumber}</span>
        <span class="text-gray-400 text-sm ml-3">${p.description || ''}</span>
      </div>
      <div class="flex items-center gap-3">
        <button onclick="showEditPartModal('${p.id}', '${p.partNumber.replace(/'/g, "\\'")}', '${(p.description || '').replace(/'/g, "\\'")}')"
          class="text-gray-400 hover:text-glassAero-sky transition text-sm" title="Edit">
          <i class="fas fa-pen"></i>
        </button>
        <span class="text-xs text-emerald-400"><i class="fas fa-check-circle mr-1"></i>Active</span>
      </div>
    </div>
  `).join('');
}

function renderStages() {
  const container = document.getElementById('stagesList');

  container.innerHTML = stages.map(s => {
    const roleColors = {
      'receiving': 'text-cyan-400',
      'quality': 'text-purple-400',
      'shop_floor': 'text-orange-400',
      'admin': 'text-gray-400'
    };
    const roleColor = roleColors[s.requiredRole] || 'text-gray-400';
    const roleLabel = s.requiredRole.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase());

    return `
      <div class="flex items-center gap-4 p-3 bg-white/5 rounded-lg">
        <span class="text-gray-500 text-sm font-medium w-8 text-right">${s.stageNumber}.</span>
        <span class="text-white text-sm flex-1">${s.stageName}</span>
        <span class="text-xs ${roleColor} w-24">${roleLabel}</span>
        <div class="flex items-center gap-2">
          <input type="number" value="${s.timeLimitHours}" min="1" data-stage-id="${s.id}"
            class="stage-time-input w-20 bg-white/5 border border-white/10 rounded-lg px-3 py-1 text-white text-sm text-center focus:outline-none focus:border-glassAero-gold">
          <span class="text-xs text-gray-500">hours</span>
        </div>
      </div>
    `;
  }).join('');
}

async function saveTimeLimits() {
  const btn = document.getElementById('saveTimeLimitsBtn');
  btn.disabled = true;
  btn.innerHTML = '<i class="fas fa-spinner fa-spin mr-1"></i>Saving...';

  const inputs = document.querySelectorAll('.stage-time-input');
  const updates = [];

  for (const input of inputs) {
    const stageId = input.dataset.stageId;
    const hours = Number(input.value);
    if (hours > 0) {
      updates.push(db.updateProductionStage(stageId, { timeLimitHours: hours }));
    }
  }

  await Promise.all(updates);

  btn.disabled = false;
  btn.innerHTML = '<i class="fas fa-check mr-1"></i>Saved!';
  setTimeout(() => {
    btn.innerHTML = '<i class="fas fa-save mr-1"></i>Save Changes';
  }, 2000);
}

// ─── Add Part Modal ─────────────────────────────────────
function showAddPartModal() {
  document.getElementById('newPartNumber').value = '';
  document.getElementById('newPartDescription').value = '';
  document.getElementById('addPartModal').classList.remove('hidden');
}

function hideAddPartModal() {
  document.getElementById('addPartModal').classList.add('hidden');
}

async function handleAddPart(event) {
  event.preventDefault();

  const part = {
    partNumber: document.getElementById('newPartNumber').value.trim(),
    description: document.getElementById('newPartDescription').value.trim() || null
  };

  const result = await db.saveProductionPart(part);
  if (result) {
    hideAddPartModal();
    await loadSettings();
  } else {
    alert('Failed to add part number. It may already exist.');
  }
}

// ─── Business Hours ─────────────────────────────────────
async function loadBusinessHours() {
  const config = await window.loadBusinessHoursConfig();
  if (!config) return;

  const openStr = String(config.openHour).padStart(2, '0') + ':' + String(config.openMinute ?? 0).padStart(2, '0');
  const closeStr = String(config.closeHour).padStart(2, '0') + ':' + String(config.closeMinute ?? 0).padStart(2, '0');

  document.getElementById('bizOpenTime').value = openStr;
  document.getElementById('bizCloseTime').value = closeStr;
  document.getElementById('bizTimezone').value = config.timezone || 'America/New_York';

  const workDays = config.workDays || [1, 2, 3, 4, 5];
  document.querySelectorAll('.workday-cb').forEach(cb => {
    cb.checked = workDays.includes(Number(cb.value));
  });
}

async function saveBusinessHours() {
  const btn = document.getElementById('saveBizHoursBtn');
  btn.disabled = true;
  btn.innerHTML = '<i class="fas fa-spinner fa-spin mr-1"></i>Saving...';

  const openParts = document.getElementById('bizOpenTime').value.split(':');
  const closeParts = document.getElementById('bizCloseTime').value.split(':');

  const workDays = [];
  document.querySelectorAll('.workday-cb:checked').forEach(cb => {
    workDays.push(Number(cb.value));
  });

  const config = {
    openHour: parseInt(openParts[0]),
    openMinute: parseInt(openParts[1]),
    closeHour: parseInt(closeParts[0]),
    closeMinute: parseInt(closeParts[1]),
    timezone: document.getElementById('bizTimezone').value,
    workDays: workDays.sort()
  };

  const success = await db.saveAppSetting('business_hours', config);

  if (success) {
    window.businessHoursConfig = config;
    btn.innerHTML = '<i class="fas fa-check mr-1"></i>Saved!';
  } else {
    btn.innerHTML = '<i class="fas fa-times mr-1"></i>Error';
    alert('Failed to save business hours. Please try again.');
  }

  btn.disabled = false;
  setTimeout(() => {
    btn.innerHTML = '<i class="fas fa-save mr-1"></i>Save Changes';
  }, 2000);
}

// ─── Edit Part Modal ────────────────────────────────────
function showEditPartModal(id, partNumber, description) {
  document.getElementById('editPartId').value = id;
  document.getElementById('editPartNumber').value = partNumber;
  document.getElementById('editPartDescription').value = description;
  document.getElementById('editPartModal').classList.remove('hidden');
}

function hideEditPartModal() {
  document.getElementById('editPartModal').classList.add('hidden');
}

async function handleEditPart(event) {
  event.preventDefault();

  const id = document.getElementById('editPartId').value;
  const partNumber = document.getElementById('editPartNumber').value.trim();
  const description = document.getElementById('editPartDescription').value.trim() || null;

  if (!partNumber) { alert('Part number is required.'); return; }

  const btn = document.getElementById('editPartSaveBtn');
  btn.disabled = true;
  btn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>Saving...';

  const result = await db.updateProductionPart(id, { partNumber, description });
  if (result) {
    hideEditPartModal();
    await loadSettings();
  } else {
    alert('Failed to update part number. Please try again.');
  }

  btn.disabled = false;
  btn.innerHTML = '<i class="fas fa-save mr-2"></i>Save';
}

document.addEventListener('DOMContentLoaded', async () => {
  const user = await initializeAuth();
  if (!user || !isAdmin(user)) {
    window.location.href = 'index.html';
    return;
  }
  await loadSettings();
});
