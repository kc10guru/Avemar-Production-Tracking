// Bill of Materials page logic
let productionParts = [];
let subcomponents = [];
let stages = [];
let currentPartId = null;
let bomItems = [];

async function loadPage() {
  [productionParts, subcomponents, stages] = await Promise.all([
    db.getProductionParts(),
    db.getSubcomponents(),
    db.getProductionStages()
  ]);

  populatePartSelect();
  populateModalDropdowns();
}

function populatePartSelect() {
  const select = document.getElementById('partSelect');
  productionParts.forEach(p => {
    const opt = document.createElement('option');
    opt.value = p.id;
    opt.textContent = `${p.partNumber} — ${p.description}`;
    select.appendChild(opt);
  });
}

function populateModalDropdowns() {
  const subSelect = document.getElementById('bomSubcomponent');
  subSelect.innerHTML = '<option value="">Select subcomponent...</option>';
  subcomponents.forEach(s => {
    const opt = document.createElement('option');
    opt.value = s.id;
    opt.textContent = `${s.partNumber} — ${s.description}`;
    subSelect.appendChild(opt);
  });

  const stageSelect = document.getElementById('bomStageNumber');
  stageSelect.innerHTML = '';
  stages.forEach(s => {
    const opt = document.createElement('option');
    opt.value = s.stageNumber;
    opt.textContent = `${s.stageNumber}. ${s.stageName}`;
    stageSelect.appendChild(opt);
  });
}

async function loadBom(partId) {
  currentPartId = partId;
  bomItems = await db.getBomItems(partId);

  const part = productionParts.find(p => p.id === partId);
  document.getElementById('bomTitle').textContent = `BOM for ${part?.partNumber || ''}`;
  document.getElementById('bomContent').classList.remove('hidden');
  document.getElementById('bomEmpty').classList.add('hidden');

  renderBom();
}

function renderBom() {
  const container = document.getElementById('bomStages');

  if (bomItems.length === 0) {
    container.innerHTML = `
      <div class="stat-card rounded-xl p-8 text-center">
        <p class="text-gray-400 mb-2">No BOM items defined for this part number.</p>
        <button onclick="showAddBomModal()" class="text-avemar-gold hover:underline text-sm">Add your first item</button>
      </div>`;
    return;
  }

  // Group by stage
  const grouped = {};
  bomItems.forEach(item => {
    if (!grouped[item.stageNumber]) grouped[item.stageNumber] = [];
    grouped[item.stageNumber].push(item);
  });

  const stageNames = {};
  stages.forEach(s => stageNames[s.stageNumber] = s.stageName);

  container.innerHTML = Object.entries(grouped)
    .sort((a, b) => Number(a[0]) - Number(b[0]))
    .map(([stageNum, items]) => `
      <div class="stat-card rounded-xl p-4">
        <h4 class="text-sm font-semibold text-gray-400 mb-3">
          <span class="text-avemar-gold">Stage ${stageNum}</span> — ${stageNames[stageNum] || ''}
        </h4>
        <div class="space-y-2">
          ${items.map(item => {
            const sub = item.subcomponents;
            return `
              <div class="flex items-center justify-between p-3 bg-white/5 rounded-lg">
                <div>
                  <span class="text-white text-sm font-mono">${sub?.partNumber || '--'}</span>
                  <span class="text-gray-400 text-sm ml-2">${sub?.description || ''}</span>
                  ${item.notes ? `<span class="text-gray-500 text-xs ml-2 italic">(${item.notes})</span>` : ''}
                </div>
                <div class="flex items-center gap-4">
                  <span class="text-white text-sm">x${item.quantityRequired}</span>
                  <span class="text-xs text-gray-500">${sub?.unitOfMeasure || 'each'}</span>
                  <button onclick="removeBomItem('${item.id}')" class="text-red-400 hover:text-red-300 transition text-sm" title="Remove">
                    <i class="fas fa-trash"></i>
                  </button>
                </div>
              </div>
            `;
          }).join('')}
        </div>
      </div>
    `).join('');
}

// ─── Add BOM Item Modal ─────────────────────────────────
function showAddBomModal() {
  document.getElementById('addBomModal').classList.remove('hidden');
}

function hideAddBomModal() {
  document.getElementById('addBomModal').classList.add('hidden');
}

async function handleSaveBomItem(event) {
  event.preventDefault();

  const item = {
    productionPartId: currentPartId,
    subcomponentId: document.getElementById('bomSubcomponent').value,
    stageNumber: Number(document.getElementById('bomStageNumber').value),
    quantityRequired: Number(document.getElementById('bomQtyRequired').value),
    notes: document.getElementById('bomNotes').value.trim() || null
  };

  const result = await db.saveBomItem(item);
  if (result) {
    hideAddBomModal();
    await loadBom(currentPartId);
  } else {
    alert('Failed to save BOM item.');
  }
}

async function removeBomItem(id) {
  if (!confirm('Remove this BOM item?')) return;
  const result = await db.deleteBomItem(id);
  if (result) {
    await loadBom(currentPartId);
  }
}

// ─── Init ───────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', async () => {
  await initializeAuth();
  await loadPage();

  document.getElementById('partSelect').addEventListener('change', (e) => {
    if (e.target.value) {
      loadBom(e.target.value);
    } else {
      document.getElementById('bomContent').classList.add('hidden');
      document.getElementById('bomEmpty').classList.remove('hidden');
    }
  });
});
