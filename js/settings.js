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
      <span class="text-xs text-emerald-400"><i class="fas fa-check-circle mr-1"></i>Active</span>
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
            class="stage-time-input w-20 bg-white/5 border border-white/10 rounded-lg px-3 py-1 text-white text-sm text-center focus:outline-none focus:border-avemar-gold">
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

document.addEventListener('DOMContentLoaded', async () => {
  await initializeAuth();
  await loadSettings();
});
