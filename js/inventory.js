// Inventory page logic
let allParts = [];

async function loadInventory() {
  const category = document.getElementById('categoryFilter').value || undefined;
  allParts = await db.getSubcomponents(category ? { category } : {});

  const lowOnly = document.getElementById('lowStockOnly').checked;
  if (lowOnly) {
    allParts = allParts.filter(p => Number(p.quantityOnHand) <= Number(p.reorderPoint));
  }

  renderTable();
  populateReceiveDropdown();
}

function renderTable() {
  const tbody = document.getElementById('inventoryTable');
  document.getElementById('inventoryCount').textContent = `${allParts.length} part${allParts.length !== 1 ? 's' : ''}`;

  if (allParts.length === 0) {
    tbody.innerHTML = `<tr><td colspan="8" class="py-12 text-center text-gray-400">
      No parts found. <button onclick="showAddModal()" class="text-avemar-gold hover:underline">Add your first part</button>
    </td></tr>`;
    return;
  }

  tbody.innerHTML = allParts.map(part => {
    const onHand = Number(part.quantityOnHand);
    const reorder = Number(part.reorderPoint);
    let statusClass = 'bg-emerald-500/20 text-emerald-400';
    let statusText = 'OK';

    if (reorder > 0 && onHand <= 0) {
      statusClass = 'bg-red-500/20 text-red-400';
      statusText = 'Out of Stock';
    } else if (reorder > 0 && onHand <= reorder * 0.5) {
      statusClass = 'bg-red-500/20 text-red-400';
      statusText = 'Critical';
    } else if (reorder > 0 && onHand <= reorder) {
      statusClass = 'bg-amber-500/20 text-amber-400';
      statusText = 'Low';
    }

    const categoryColors = {
      'Glass': 'text-cyan-400', 'Electrical': 'text-yellow-400', 'Seals': 'text-purple-400',
      'Hardware': 'text-gray-400', 'Consumable': 'text-pink-400', 'General': 'text-gray-400'
    };

    return `
      <tr class="border-b border-white/5 hover:bg-white/5 transition">
        <td class="py-3 px-6 font-mono text-sm text-white">${part.partNumber}</td>
        <td class="py-3 px-6 text-gray-300 text-sm">${part.description}</td>
        <td class="py-3 px-6 text-sm ${categoryColors[part.category] || 'text-gray-400'}">${part.category}</td>
        <td class="py-3 px-6 text-right font-semibold ${onHand <= reorder && reorder > 0 ? 'text-red-400' : 'text-white'}">${onHand}</td>
        <td class="py-3 px-6 text-right text-gray-400">${reorder}</td>
        <td class="py-3 px-6 text-right text-gray-400">${part.leadTimeDays}d</td>
        <td class="py-3 px-6 text-center"><span class="px-2 py-1 rounded-full text-xs ${statusClass}">${statusText}</span></td>
        <td class="py-3 px-6 text-center">
          <button onclick="editPart('${part.id}')" class="text-gray-400 hover:text-white transition text-sm mr-2" title="Edit">
            <i class="fas fa-edit"></i>
          </button>
        </td>
      </tr>
    `;
  }).join('');
}

function populateReceiveDropdown() {
  const select = document.getElementById('receivePart');
  select.innerHTML = '<option value="">Select a part...</option>';
  allParts.forEach(p => {
    const opt = document.createElement('option');
    opt.value = p.id;
    opt.textContent = `${p.partNumber} — ${p.description} (${p.quantityOnHand} on hand)`;
    select.appendChild(opt);
  });
}

// ─── Add / Edit Modal ──────────────────────────────────
function showAddModal() {
  document.getElementById('addModalTitle').textContent = 'Add Subcomponent';
  document.getElementById('editPartId').value = '';
  document.getElementById('subPartNumber').value = '';
  document.getElementById('subDescription').value = '';
  document.getElementById('subCategory').value = 'General';
  document.getElementById('subUom').value = 'each';
  document.getElementById('subQty').value = '0';
  document.getElementById('subCost').value = '';
  document.getElementById('subReorder').value = '0';
  document.getElementById('subReorderQty').value = '0';
  document.getElementById('subLeadTime').value = '14';
  document.getElementById('subSupplier').value = '';
  document.getElementById('addModal').classList.remove('hidden');
}

function hideAddModal() {
  document.getElementById('addModal').classList.add('hidden');
}

async function editPart(id) {
  const part = allParts.find(p => p.id === id);
  if (!part) return;

  document.getElementById('addModalTitle').textContent = 'Edit Subcomponent';
  document.getElementById('editPartId').value = id;
  document.getElementById('subPartNumber').value = part.partNumber;
  document.getElementById('subDescription').value = part.description;
  document.getElementById('subCategory').value = part.category;
  document.getElementById('subUom').value = part.unitOfMeasure;
  document.getElementById('subQty').value = part.quantityOnHand;
  document.getElementById('subCost').value = part.unitCost || '';
  document.getElementById('subReorder').value = part.reorderPoint;
  document.getElementById('subReorderQty').value = part.reorderQuantity;
  document.getElementById('subLeadTime').value = part.leadTimeDays;
  document.getElementById('subSupplier').value = part.supplier || '';
  document.getElementById('addModal').classList.remove('hidden');
}

async function handleSavePart(event) {
  event.preventDefault();

  const data = {
    partNumber: document.getElementById('subPartNumber').value.trim(),
    description: document.getElementById('subDescription').value.trim(),
    category: document.getElementById('subCategory').value,
    unitOfMeasure: document.getElementById('subUom').value.trim(),
    quantityOnHand: Number(document.getElementById('subQty').value),
    unitCost: document.getElementById('subCost').value ? Number(document.getElementById('subCost').value) : null,
    reorderPoint: Number(document.getElementById('subReorder').value),
    reorderQuantity: Number(document.getElementById('subReorderQty').value),
    leadTimeDays: Number(document.getElementById('subLeadTime').value),
    supplier: document.getElementById('subSupplier').value.trim() || null
  };

  const editId = document.getElementById('editPartId').value;
  let result;
  if (editId) {
    result = await db.updateSubcomponent(editId, data);
  } else {
    result = await db.saveSubcomponent(data);
  }

  if (result) {
    hideAddModal();
    await loadInventory();
  } else {
    alert('Failed to save. Check for duplicate part numbers.');
  }
}

// ─── Receive Stock Modal ────────────────────────────────
function showReceiveModal() {
  document.getElementById('receiveModal').classList.remove('hidden');
}

function hideReceiveModal() {
  document.getElementById('receiveModal').classList.add('hidden');
}

async function handleReceiveStock() {
  const partId = document.getElementById('receivePart').value;
  const qty = Number(document.getElementById('receiveQty').value);

  if (!partId || qty <= 0) {
    alert('Please select a part and enter a valid quantity.');
    return;
  }

  const result = await db.receiveSubcomponentStock(partId, qty);
  if (result) {
    hideReceiveModal();
    await loadInventory();
  } else {
    alert('Failed to receive stock.');
  }
}

// ─── Init ───────────────────────────────────────────────
function setupListeners() {
  document.getElementById('categoryFilter').addEventListener('change', loadInventory);
  document.getElementById('lowStockOnly').addEventListener('change', loadInventory);

  // Check URL params for auto-filter
  const params = new URLSearchParams(window.location.search);
  if (params.get('filter') === 'low') {
    document.getElementById('lowStockOnly').checked = true;
  }
}

document.addEventListener('DOMContentLoaded', async () => {
  await initializeAuth();
  setupListeners();
  await loadInventory();
});
