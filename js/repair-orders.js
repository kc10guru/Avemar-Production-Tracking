// Repair Orders list page logic
let allOrders = [];
let stages = [];
let parts = [];

async function loadPage() {
  [stages, parts] = await Promise.all([
    db.getProductionStages(),
    db.getProductionParts()
  ]);

  populateFilters();
  applyUrlFilters();
  await loadOrders();
}

function populateFilters() {
  const stageSelect = document.getElementById('stageFilter');
  stages.forEach(s => {
    const opt = document.createElement('option');
    opt.value = s.stageNumber;
    opt.textContent = `${s.stageNumber}. ${s.stageName}`;
    stageSelect.appendChild(opt);
  });

  const partSelect = document.getElementById('partFilter');
  parts.forEach(p => {
    const opt = document.createElement('option');
    opt.value = p.partNumber;
    opt.textContent = p.partNumber;
    partSelect.appendChild(opt);
  });
}

function applyUrlFilters() {
  const params = new URLSearchParams(window.location.search);
  if (params.get('status')) document.getElementById('statusFilter').value = params.get('status');
  if (params.get('stage')) document.getElementById('stageFilter').value = params.get('stage');
  if (params.get('part')) document.getElementById('partFilter').value = params.get('part');
}

async function loadOrders() {
  const filters = {
    status: document.getElementById('statusFilter').value || undefined,
    currentStage: document.getElementById('stageFilter').value ? Number(document.getElementById('stageFilter').value) : undefined,
    partNumber: document.getElementById('partFilter').value || undefined,
    search: document.getElementById('searchInput').value || undefined
  };

  allOrders = await db.getRepairOrders(filters);
  renderOrders();
}

function renderOrders() {
  const tbody = document.getElementById('ordersTable');
  const countEl = document.getElementById('resultCount');

  countEl.textContent = `${allOrders.length} repair order${allOrders.length !== 1 ? 's' : ''} found`;

  if (allOrders.length === 0) {
    tbody.innerHTML = `<tr><td colspan="7" class="py-12 text-center text-gray-400">
      No repair orders found. <a href="new-repair-order.html" class="text-avemar-gold hover:underline">Create one</a>
    </td></tr>`;
    return;
  }

  const stageNames = {};
  stages.forEach(s => stageNames[s.stageNumber] = s.stageName);

  const statusColors = {
    'In Progress': 'bg-sky-500/20 text-sky-400',
    'Completed': 'bg-emerald-500/20 text-emerald-400',
    'On Hold': 'bg-amber-500/20 text-amber-400',
    'Cancelled': 'bg-red-500/20 text-red-400'
  };

  tbody.innerHTML = allOrders.map(order => {
    const statusClass = statusColors[order.status] || 'bg-gray-500/20 text-gray-400';
    const received = order.dateReceived ? new Date(order.dateReceived).toLocaleDateString() : '--';

    return `
      <tr class="border-b border-white/5 hover:bg-white/5 cursor-pointer transition" onclick="window.location.href='repair-order-detail.html?id=${order.id}'">
        <td class="py-4 px-6 font-medium text-white">${order.roNumber}</td>
        <td class="py-4 px-6 text-gray-300">${order.customerName}</td>
        <td class="py-4 px-6 text-gray-300 font-mono text-sm">${order.partNumber}</td>
        <td class="py-4 px-6 text-gray-300">${order.serialNumber}</td>
        <td class="py-4 px-6">
          <span class="text-xs text-gray-400">${order.currentStage}.</span>
          <span class="text-gray-300 text-sm">${stageNames[order.currentStage] || ''}</span>
        </td>
        <td class="py-4 px-6"><span class="px-2 py-1 rounded-full text-xs ${statusClass}">${order.status}</span></td>
        <td class="py-4 px-6 text-gray-400 text-sm">${received}</td>
      </tr>
    `;
  }).join('');
}

function clearFilters() {
  document.getElementById('searchInput').value = '';
  document.getElementById('statusFilter').value = '';
  document.getElementById('stageFilter').value = '';
  document.getElementById('partFilter').value = '';
  window.history.replaceState({}, '', 'repair-orders.html');
  loadOrders();
}

// Debounced search
let searchTimeout;
function setupListeners() {
  document.getElementById('searchInput').addEventListener('input', () => {
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(loadOrders, 300);
  });
  document.getElementById('statusFilter').addEventListener('change', loadOrders);
  document.getElementById('stageFilter').addEventListener('change', loadOrders);
  document.getElementById('partFilter').addEventListener('change', loadOrders);
}

document.addEventListener('DOMContentLoaded', async () => {
  await initializeAuth();
  setupListeners();
  await loadPage();
});
