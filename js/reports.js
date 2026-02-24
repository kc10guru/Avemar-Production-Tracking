// Reports page logic
let allOrders = [];
let allStages = [];
let allSubcomponents = [];
let allProductionParts = [];

function showReport(reportId) {
  document.getElementById('report-weekly').classList.add('hidden');
  document.getElementById('report-inventory').classList.add('hidden');
  document.getElementById('report-' + reportId).classList.remove('hidden');

  document.getElementById('tab-weekly').className =
    'px-6 py-3 rounded-xl font-semibold transition text-sm ' +
    (reportId === 'weekly' ? 'bg-avemar-gold text-black' : 'bg-white/5 border border-white/10 text-gray-300 hover:text-white');
  document.getElementById('tab-inventory').className =
    'px-6 py-3 rounded-xl font-semibold transition text-sm ' +
    (reportId === 'inventory' ? 'bg-avemar-gold text-black' : 'bg-white/5 border border-white/10 text-gray-300 hover:text-white');

  if (reportId === 'inventory') loadProjectedInventory();
}

function getWeekDates(weekStr) {
  if (!weekStr) {
    const now = new Date();
    const dayOfWeek = now.getDay();
    const monday = new Date(now);
    monday.setDate(now.getDate() - (dayOfWeek === 0 ? 6 : dayOfWeek - 1));
    monday.setHours(0, 0, 0, 0);
    const sunday = new Date(monday);
    sunday.setDate(monday.getDate() + 6);
    sunday.setHours(23, 59, 59, 999);
    return { start: monday, end: sunday };
  }
  const [year, week] = weekStr.split('-W').map(Number);
  // ISO 8601: Jan 4 is always in week 1
  const jan4 = new Date(year, 0, 4);
  const jan4Day = jan4.getDay() || 7;
  const mondayOfWeek1 = new Date(jan4);
  mondayOfWeek1.setDate(jan4.getDate() - jan4Day + 1);
  const monday = new Date(mondayOfWeek1);
  monday.setDate(mondayOfWeek1.getDate() + (week - 1) * 7);
  monday.setHours(0, 0, 0, 0);
  const sunday = new Date(monday);
  sunday.setDate(monday.getDate() + 6);
  sunday.setHours(23, 59, 59, 999);
  return { start: monday, end: sunday };
}

// ─── Weekly Production Report ────────────────────────────
async function loadWeeklyReport() {
  const weekInput = document.getElementById('weekSelector').value;
  const { start, end } = getWeekDates(weekInput);

  const dateOpts = { month: 'short', day: 'numeric', year: 'numeric' };
  document.getElementById('weeklyReportTitle').textContent = 'Weekly Production Report';
  document.getElementById('weeklyReportDates').textContent =
    `${start.toLocaleDateString('en-US', dateOpts)} — ${end.toLocaleDateString('en-US', dateOpts)}`;

  const activeOrders = allOrders.filter(o => o.status === 'In Progress');

  // Units received this week
  const received = allOrders.filter(o => {
    const d = new Date(o.dateReceived);
    return d >= start && d <= end;
  });

  // Units delivered/completed this week
  const delivered = allOrders.filter(o => {
    if (!o.dateCompleted) return false;
    const d = new Date(o.dateCompleted);
    return d >= start && d <= end;
  });

  // Behind schedule: active orders where time in current stage exceeds the stage limit
  const behindSchedule = [];
  const stageHistory = {};
  for (const order of activeOrders) {
    const history = await db.getStageHistory(order.id);
    const currentEntry = history.find(h => h.stageNumber === order.currentStage && !h.exitedAt);
    if (currentEntry) {
      const stageDef = allStages.find(s => s.stageNumber === order.currentStage);
      const hoursInStage = (new Date() - new Date(currentEntry.enteredAt)) / (1000 * 60 * 60);
      if (stageDef && hoursInStage > stageDef.timeLimitHours) {
        behindSchedule.push({
          ...order,
          stageName: stageDef.stageName,
          hoursInStage: Math.round(hoursInStage),
          limitHours: stageDef.timeLimitHours,
          hoursOver: Math.round(hoursInStage - stageDef.timeLimitHours)
        });
      }
    }
  }

  // Summary counts
  document.getElementById('weeklyReceived').textContent = received.length;
  document.getElementById('weeklyDelivered').textContent = delivered.length;
  document.getElementById('weeklyInWork').textContent = activeOrders.length;
  document.getElementById('weeklyBehind').textContent = behindSchedule.length;

  // Stage breakdown
  renderStageBreakdown(activeOrders);
  renderBehindSchedule(behindSchedule);
}

function renderStageBreakdown(activeOrders) {
  const container = document.getElementById('stageBreakdown');

  const rows = allStages.map(stage => {
    const units = activeOrders.filter(o => o.currentStage === stage.stageNumber);
    const pct = activeOrders.length > 0 ? (units.length / activeOrders.length) * 100 : 0;

    return `
      <div class="flex items-center gap-4 py-3 ${stage.stageNumber < allStages.length ? 'border-b border-white/5' : ''}">
        <span class="text-xs text-gray-500 w-8 text-right">${stage.stageNumber}</span>
        <span class="text-sm text-white flex-1">${stage.stageName}</span>
        <div class="w-48 bg-white/5 rounded-full h-3 overflow-hidden">
          <div class="h-full rounded-full ${units.length > 0 ? 'bg-avemar-sky' : ''}" style="width: ${pct}%"></div>
        </div>
        <span class="text-sm font-bold w-8 text-right ${units.length > 0 ? 'text-avemar-sky' : 'text-gray-600'}">${units.length}</span>
      </div>
    `;
  });

  container.innerHTML = rows.join('');
}

function renderBehindSchedule(behindSchedule) {
  const container = document.getElementById('behindScheduleList');

  if (behindSchedule.length === 0) {
    container.innerHTML = '<div class="text-emerald-400 text-center py-6"><i class="fas fa-check-circle mr-2"></i>All units are on schedule</div>';
    return;
  }

  container.innerHTML = `
    <table class="w-full text-sm">
      <thead>
        <tr class="border-b border-white/10">
          <th class="text-left py-2 text-xs text-gray-400 font-medium">RO Number</th>
          <th class="text-left py-2 text-xs text-gray-400 font-medium">Customer</th>
          <th class="text-left py-2 text-xs text-gray-400 font-medium">Current Stage</th>
          <th class="text-right py-2 text-xs text-gray-400 font-medium">Time in Stage</th>
          <th class="text-right py-2 text-xs text-gray-400 font-medium">Limit</th>
          <th class="text-right py-2 text-xs text-gray-400 font-medium">Over By</th>
        </tr>
      </thead>
      <tbody>
        ${behindSchedule.map(o => `
          <tr class="border-b border-white/5 cursor-pointer hover:bg-white/5" onclick="window.location.href='repair-order-detail.html?id=${o.id}'">
            <td class="py-3 text-white font-medium">${o.roNumber}</td>
            <td class="py-3 text-gray-300">${o.customerName}</td>
            <td class="py-3 text-gray-300">${o.currentStage}. ${o.stageName}</td>
            <td class="py-3 text-right text-gray-300">${o.hoursInStage}h</td>
            <td class="py-3 text-right text-gray-500">${o.limitHours}h</td>
            <td class="py-3 text-right text-red-400 font-medium">${o.hoursOver}h</td>
          </tr>
        `).join('')}
      </tbody>
    </table>
  `;
}

// ─── Projected Inventory Report ──────────────────────────
async function loadProjectedInventory() {
  const activeOrders = allOrders.filter(o => o.status === 'In Progress');

  // For each active order, find which BOM stages are AHEAD of it (not yet reached)
  // and accumulate the projected part needs
  const projectedNeeds = {};

  for (const order of activeOrders) {
    const prodPart = allProductionParts.find(p => p.partNumber === order.partNumber);
    if (!prodPart) continue;

    const bomItems = await db.getBomItems(prodPart.id);

    for (const item of bomItems) {
      // Only count BOM items for stages the unit hasn't reached yet
      if (item.stageNumber > order.currentStage) {
        const subId = item.subcomponentId || item.subcomponents?.id;
        if (!subId) continue;

        if (!projectedNeeds[subId]) {
          projectedNeeds[subId] = {
            subcomponent: item.subcomponents,
            totalNeeded: 0,
            orders: []
          };
        }
        projectedNeeds[subId].totalNeeded += Number(item.quantityRequired);
        const existing = projectedNeeds[subId].orders.find(o => o.id === order.id);
        if (!existing) {
          projectedNeeds[subId].orders.push({ id: order.id, roNumber: order.roNumber });
        }
      }
    }
  }

  // Build the full inventory picture
  const inventoryRows = allSubcomponents.map(sub => {
    const need = projectedNeeds[sub.id];
    const onHand = Number(sub.quantityOnHand);
    const projected = need ? need.totalNeeded : 0;
    const available = onHand - projected;

    return {
      partNumber: sub.partNumber,
      description: sub.description,
      onHand: onHand,
      projected: projected,
      available: available,
      unitOfMeasure: sub.unitOfMeasure,
      reorderPoint: Number(sub.reorderPoint),
      orderCount: need ? need.orders.length : 0
    };
  });

  // Sort: shortages first, then by available ascending
  inventoryRows.sort((a, b) => a.available - b.available);

  const shortages = inventoryRows.filter(r => r.available < 0);

  document.getElementById('invTotalParts').textContent = allSubcomponents.length;
  document.getElementById('invShortages').textContent = shortages.length;
  document.getElementById('invUnitsInWork').textContent = activeOrders.length;

  renderProjectedInventory(inventoryRows);
}

function renderProjectedInventory(rows) {
  const container = document.getElementById('projectedInventoryTable');

  if (rows.length === 0) {
    container.innerHTML = '<div class="text-gray-400 text-center py-8">No subcomponents in inventory</div>';
    return;
  }

  container.innerHTML = `
    <div class="overflow-x-auto">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-white/10">
            <th class="text-left py-2 text-xs text-gray-400 font-medium">Part Number</th>
            <th class="text-left py-2 text-xs text-gray-400 font-medium">Description</th>
            <th class="text-right py-2 text-xs text-gray-400 font-medium">On Hand</th>
            <th class="text-right py-2 text-xs text-gray-400 font-medium">Projected Need</th>
            <th class="text-right py-2 text-xs text-gray-400 font-medium">Projected Available</th>
            <th class="text-right py-2 text-xs text-gray-400 font-medium">Units Needing</th>
            <th class="text-center py-2 text-xs text-gray-400 font-medium">Status</th>
          </tr>
        </thead>
        <tbody>
          ${rows.map(r => {
            let statusClass, statusText;
            if (r.available < 0) {
              statusClass = 'bg-red-500/20 text-red-400';
              statusText = 'SHORTAGE';
            } else if (r.available <= r.reorderPoint) {
              statusClass = 'bg-amber-500/20 text-amber-400';
              statusText = 'LOW';
            } else {
              statusClass = 'bg-emerald-500/20 text-emerald-400';
              statusText = 'OK';
            }

            return `
              <tr class="border-b border-white/5 ${r.available < 0 ? 'bg-red-500/5' : ''}">
                <td class="py-3 text-white font-medium">${r.partNumber}</td>
                <td class="py-3 text-gray-300">${r.description}</td>
                <td class="py-3 text-right text-gray-300">${r.onHand} ${r.unitOfMeasure}</td>
                <td class="py-3 text-right text-avemar-gold">${r.projected}</td>
                <td class="py-3 text-right font-bold ${r.available < 0 ? 'text-red-400' : r.available <= r.reorderPoint ? 'text-amber-400' : 'text-emerald-400'}">${r.available}</td>
                <td class="py-3 text-right text-gray-400">${r.orderCount}</td>
                <td class="py-3 text-center"><span class="px-2 py-1 rounded-full text-xs ${statusClass}">${statusText}</span></td>
              </tr>
            `;
          }).join('')}
        </tbody>
      </table>
    </div>
  `;
}

// ─── Initialization ──────────────────────────────────────
async function initReports() {
  [allOrders, allStages, allSubcomponents, allProductionParts] = await Promise.all([
    db.getRepairOrders(),
    db.getProductionStages(),
    db.getSubcomponents(),
    db.getProductionParts()
  ]);

  // Also load completed/archived orders for the delivered count
  const { data: completedData } = await window.supabaseClient
    .from('repair_orders').select('*')
    .eq('status', 'Completed')
    .order('date_completed', { ascending: false });
  if (completedData) {
    const completedOrders = completedData.map(o => {
      const result = {};
      Object.keys(o).forEach(key => {
        const camelKey = key.replace(/_([a-z])/g, (g) => g[1].toUpperCase());
        result[camelKey] = o[key];
      });
      return result;
    });
    // Merge completed orders that aren't already in allOrders
    const existingIds = new Set(allOrders.map(o => o.id));
    completedOrders.forEach(o => {
      if (!existingIds.has(o.id)) allOrders.push(o);
    });
  }

  // Default week selector to current week
  const now = new Date();
  const year = now.getFullYear();
  const startOfYear = new Date(year, 0, 1);
  const dayOfYear = Math.floor((now - startOfYear) / 86400000) + 1;
  const weekNum = Math.ceil((dayOfYear + startOfYear.getDay()) / 7);
  document.getElementById('weekSelector').value = `${year}-W${String(weekNum).padStart(2, '0')}`;

  await loadWeeklyReport();
}

document.addEventListener('DOMContentLoaded', async () => {
  await initializeAuth();
  await initReports();
});
