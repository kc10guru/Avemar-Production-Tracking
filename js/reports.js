// Reports page logic
let allOrders = [];
let allStages = [];
let allSubcomponents = [];
let allProductionParts = [];

const REPORT_TABS = ['weekly', 'inventory', 'quarterly', 'annual'];

function showReport(reportId) {
  REPORT_TABS.forEach(id => {
    document.getElementById('report-' + id).classList.toggle('hidden', id !== reportId);
    const active = id === reportId;
    document.getElementById('tab-' + id).className =
      'px-6 py-3 rounded-xl font-semibold transition text-sm ' +
      (active ? 'bg-avemar-gold text-black' : 'bg-white/5 border border-white/10 text-gray-300 hover:text-white');
  });

  if (reportId === 'inventory') loadProjectedInventory();
  if (reportId === 'quarterly') loadQuarterlyReport();
  if (reportId === 'annual') loadAnnualReport();
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

// ─── Chart theme defaults ────────────────────────────────
const CHART_COLORS = {
  received: 'rgba(14,165,233,0.85)',
  receivedBg: 'rgba(14,165,233,0.25)',
  delivered: 'rgba(16,185,129,0.85)',
  deliveredBg: 'rgba(16,185,129,0.25)',
  scrapped: 'rgba(239,68,68,0.7)',
  cumulative: 'rgba(245,158,11,0.85)',
  grid: 'rgba(255,255,255,0.06)',
  tick: 'rgba(156,163,175,0.7)',
};
const MONTH_NAMES = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

let quarterlyChartInstance = null;
let annualChartInstance = null;

// ─── Helpers ─────────────────────────────────────────────
function getOrdersForPeriod(startMonth, endMonth, year) {
  const start = new Date(year, startMonth, 1);
  const end = new Date(year, endMonth + 1, 0, 23, 59, 59, 999);

  const received = allOrders.filter(o => {
    if (!o.dateReceived) return false;
    const d = new Date(o.dateReceived);
    return d >= start && d <= end;
  });
  const delivered = allOrders.filter(o => {
    if (!o.dateCompleted) return false;
    const d = new Date(o.dateCompleted);
    return d >= start && d <= end && o.status === 'Completed';
  });
  const scrapped = allOrders.filter(o => {
    if (!o.dateCompleted) return false;
    const d = new Date(o.dateCompleted);
    return d >= start && d <= end && (o.status === 'Scrapped' || o.status === 'Cancelled');
  });
  return { received, delivered, scrapped, start, end };
}

function calcAvgDays(orders) {
  const valid = orders.filter(o => o.dateReceived && o.dateCompleted);
  if (valid.length === 0) return 0;
  const total = valid.reduce((sum, o) => {
    return sum + (new Date(o.dateCompleted) - new Date(o.dateReceived)) / 86400000;
  }, 0);
  return Math.round(total / valid.length);
}

function groupByMonth(orders, dateField, startMonth, monthCount) {
  const counts = new Array(monthCount).fill(0);
  orders.forEach(o => {
    const d = new Date(o[dateField]);
    const idx = d.getMonth() - startMonth;
    if (idx >= 0 && idx < monthCount) counts[idx]++;
  });
  return counts;
}

function yoyText(current, previous) {
  if (previous === 0 && current === 0) return '';
  if (previous === 0) return '<span class="text-emerald-400">New</span>';
  const delta = current - previous;
  const pct = Math.round((delta / previous) * 100);
  const arrow = delta >= 0 ? 'fa-arrow-up' : 'fa-arrow-down';
  const color = delta >= 0 ? 'text-emerald-400' : 'text-red-400';
  return `<span class="${color}"><i class="fas ${arrow} mr-1"></i>${Math.abs(pct)}% vs prior year</span>`;
}

// ─── Quarterly Report ────────────────────────────────────
function loadQuarterlyReport() {
  const quarter = Number(document.getElementById('quarterSelector').value);
  const year = Number(document.getElementById('quarterYearSelector').value);
  const startMonth = (quarter - 1) * 3;
  const months = [MONTH_NAMES[startMonth], MONTH_NAMES[startMonth+1], MONTH_NAMES[startMonth+2]];

  const { received, delivered, scrapped, start, end } = getOrdersForPeriod(startMonth, startMonth + 2, year);

  document.getElementById('quarterlyReportTitle').textContent = `Q${quarter} ${year} Production Report`;
  const dateOpts = { month: 'short', day: 'numeric', year: 'numeric' };
  document.getElementById('quarterlyReportDates').textContent =
    `${start.toLocaleDateString('en-US', dateOpts)} \u2014 ${end.toLocaleDateString('en-US', dateOpts)}`;

  document.getElementById('qtrReceived').textContent = received.length;
  document.getElementById('qtrDelivered').textContent = delivered.length;
  document.getElementById('qtrScrapped').textContent = scrapped.length;
  document.getElementById('qtrAvgDays').textContent = calcAvgDays(delivered);

  const recByMonth = groupByMonth(received, 'dateReceived', startMonth, 3);
  const delByMonth = groupByMonth(delivered, 'dateCompleted', startMonth, 3);
  const scrByMonth = groupByMonth(scrapped, 'dateCompleted', startMonth, 3);

  // Chart
  if (quarterlyChartInstance) quarterlyChartInstance.destroy();
  const ctx = document.getElementById('quarterlyChart').getContext('2d');
  quarterlyChartInstance = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: months.map(m => `${m} ${year}`),
      datasets: [
        {
          label: 'Received',
          data: recByMonth,
          backgroundColor: CHART_COLORS.receivedBg,
          borderColor: CHART_COLORS.received,
          borderWidth: 2, borderRadius: 6
        },
        {
          label: 'Delivered',
          data: delByMonth,
          backgroundColor: CHART_COLORS.deliveredBg,
          borderColor: CHART_COLORS.delivered,
          borderWidth: 2, borderRadius: 6
        },
        {
          label: 'Scrapped',
          data: scrByMonth,
          backgroundColor: 'rgba(239,68,68,0.2)',
          borderColor: CHART_COLORS.scrapped,
          borderWidth: 2, borderRadius: 6
        }
      ]
    },
    options: {
      responsive: true, maintainAspectRatio: false,
      plugins: {
        legend: { labels: { color: CHART_COLORS.tick, font: { family: 'Outfit' } } }
      },
      scales: {
        x: { ticks: { color: CHART_COLORS.tick }, grid: { color: CHART_COLORS.grid } },
        y: { beginAtZero: true, ticks: { color: CHART_COLORS.tick, stepSize: 1 }, grid: { color: CHART_COLORS.grid } }
      }
    }
  });

  // Table
  const container = document.getElementById('quarterlyTable');
  container.innerHTML = `
    <div class="overflow-x-auto">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-white/10">
            <th class="text-left py-2 text-xs text-gray-400 font-medium">Month</th>
            <th class="text-right py-2 text-xs text-gray-400 font-medium">Received</th>
            <th class="text-right py-2 text-xs text-gray-400 font-medium">Delivered</th>
            <th class="text-right py-2 text-xs text-gray-400 font-medium">Scrapped</th>
            <th class="text-right py-2 text-xs text-gray-400 font-medium">Net Throughput</th>
          </tr>
        </thead>
        <tbody>
          ${months.map((m, i) => `
            <tr class="border-b border-white/5">
              <td class="py-3 text-white font-medium">${m} ${year}</td>
              <td class="py-3 text-right text-avemar-sky">${recByMonth[i]}</td>
              <td class="py-3 text-right text-emerald-400">${delByMonth[i]}</td>
              <td class="py-3 text-right text-red-400">${scrByMonth[i]}</td>
              <td class="py-3 text-right font-semibold text-white">${delByMonth[i] - recByMonth[i] >= 0 ? '+' : ''}${delByMonth[i] - recByMonth[i]}</td>
            </tr>
          `).join('')}
          <tr class="border-t border-white/20">
            <td class="py-3 text-white font-bold">Total</td>
            <td class="py-3 text-right font-bold text-avemar-sky">${received.length}</td>
            <td class="py-3 text-right font-bold text-emerald-400">${delivered.length}</td>
            <td class="py-3 text-right font-bold text-red-400">${scrapped.length}</td>
            <td class="py-3 text-right font-bold text-white">${delivered.length - received.length >= 0 ? '+' : ''}${delivered.length - received.length}</td>
          </tr>
        </tbody>
      </table>
    </div>
  `;
}

// ─── Annual Report ───────────────────────────────────────
function loadAnnualReport() {
  const year = Number(document.getElementById('annualYearSelector').value);

  const { received, delivered, scrapped } = getOrdersForPeriod(0, 11, year);
  const prevData = getOrdersForPeriod(0, 11, year - 1);

  document.getElementById('annualReportTitle').textContent = `${year} Annual Production Report`;
  document.getElementById('annualReportDates').textContent = `January 1 \u2014 December 31, ${year}`;

  document.getElementById('annReceived').textContent = received.length;
  document.getElementById('annDelivered').textContent = delivered.length;
  document.getElementById('annScrapped').textContent = scrapped.length;
  document.getElementById('annAvgDays').textContent = calcAvgDays(delivered);

  document.getElementById('annReceivedYoY').innerHTML = yoyText(received.length, prevData.received.length);
  document.getElementById('annDeliveredYoY').innerHTML = yoyText(delivered.length, prevData.delivered.length);
  document.getElementById('annScrappedYoY').innerHTML = yoyText(scrapped.length, prevData.scrapped.length);
  const prevAvg = calcAvgDays(prevData.delivered);
  const currAvg = calcAvgDays(delivered);
  if (prevAvg > 0 && currAvg > 0) {
    const delta = currAvg - prevAvg;
    const color = delta <= 0 ? 'text-emerald-400' : 'text-red-400';
    const arrow = delta <= 0 ? 'fa-arrow-down' : 'fa-arrow-up';
    document.getElementById('annAvgDaysYoY').innerHTML =
      `<span class="${color}"><i class="fas ${arrow} mr-1"></i>${Math.abs(delta)} days vs prior year</span>`;
  } else {
    document.getElementById('annAvgDaysYoY').innerHTML = '';
  }

  const recByMonth = groupByMonth(received, 'dateReceived', 0, 12);
  const delByMonth = groupByMonth(delivered, 'dateCompleted', 0, 12);
  const scrByMonth = groupByMonth(scrapped, 'dateCompleted', 0, 12);

  // Cumulative delivered
  const cumDelivered = [];
  let cumSum = 0;
  delByMonth.forEach(v => { cumSum += v; cumDelivered.push(cumSum); });

  // Chart
  if (annualChartInstance) annualChartInstance.destroy();
  const ctx = document.getElementById('annualChart').getContext('2d');
  annualChartInstance = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: MONTH_NAMES.map(m => `${m}`),
      datasets: [
        {
          type: 'bar', label: 'Received', data: recByMonth,
          backgroundColor: CHART_COLORS.receivedBg, borderColor: CHART_COLORS.received,
          borderWidth: 2, borderRadius: 6, yAxisID: 'y'
        },
        {
          type: 'bar', label: 'Delivered', data: delByMonth,
          backgroundColor: CHART_COLORS.deliveredBg, borderColor: CHART_COLORS.delivered,
          borderWidth: 2, borderRadius: 6, yAxisID: 'y'
        },
        {
          type: 'line', label: 'Cumulative Delivered', data: cumDelivered,
          borderColor: CHART_COLORS.cumulative, backgroundColor: 'transparent',
          borderWidth: 3, pointRadius: 4, pointBackgroundColor: CHART_COLORS.cumulative,
          tension: 0.3, yAxisID: 'y1'
        }
      ]
    },
    options: {
      responsive: true, maintainAspectRatio: false,
      plugins: {
        legend: { labels: { color: CHART_COLORS.tick, font: { family: 'Outfit' } } }
      },
      scales: {
        x: { ticks: { color: CHART_COLORS.tick }, grid: { color: CHART_COLORS.grid } },
        y: {
          beginAtZero: true, position: 'left',
          title: { display: true, text: 'Monthly', color: CHART_COLORS.tick },
          ticks: { color: CHART_COLORS.tick, stepSize: 1 }, grid: { color: CHART_COLORS.grid }
        },
        y1: {
          beginAtZero: true, position: 'right',
          title: { display: true, text: 'Cumulative', color: CHART_COLORS.cumulative },
          ticks: { color: CHART_COLORS.cumulative }, grid: { drawOnChartArea: false }
        }
      }
    }
  });

  // Table
  const container = document.getElementById('annualTable');
  container.innerHTML = `
    <div class="overflow-x-auto">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-white/10">
            <th class="text-left py-2 text-xs text-gray-400 font-medium">Month</th>
            <th class="text-right py-2 text-xs text-gray-400 font-medium">Received</th>
            <th class="text-right py-2 text-xs text-gray-400 font-medium">Delivered</th>
            <th class="text-right py-2 text-xs text-gray-400 font-medium">Scrapped</th>
            <th class="text-right py-2 text-xs text-gray-400 font-medium">Cumulative Delivered</th>
          </tr>
        </thead>
        <tbody>
          ${MONTH_NAMES.map((m, i) => `
            <tr class="border-b border-white/5">
              <td class="py-3 text-white font-medium">${m}</td>
              <td class="py-3 text-right text-avemar-sky">${recByMonth[i]}</td>
              <td class="py-3 text-right text-emerald-400">${delByMonth[i]}</td>
              <td class="py-3 text-right text-red-400">${scrByMonth[i]}</td>
              <td class="py-3 text-right font-semibold text-avemar-gold">${cumDelivered[i]}</td>
            </tr>
          `).join('')}
          <tr class="border-t border-white/20">
            <td class="py-3 text-white font-bold">Total</td>
            <td class="py-3 text-right font-bold text-avemar-sky">${received.length}</td>
            <td class="py-3 text-right font-bold text-emerald-400">${delivered.length}</td>
            <td class="py-3 text-right font-bold text-red-400">${scrapped.length}</td>
            <td class="py-3 text-right font-bold text-avemar-gold">${cumSum}</td>
          </tr>
        </tbody>
      </table>
    </div>
  `;
}

// ─── Populate year/quarter selectors ─────────────────────
function populateSelectors() {
  const years = new Set();
  allOrders.forEach(o => {
    if (o.dateReceived) years.add(new Date(o.dateReceived).getFullYear());
    if (o.dateCompleted) years.add(new Date(o.dateCompleted).getFullYear());
  });
  if (years.size === 0) years.add(new Date().getFullYear());

  const sortedYears = [...years].sort((a, b) => b - a);
  const now = new Date();
  const currentYear = now.getFullYear();
  const currentQuarter = Math.ceil((now.getMonth() + 1) / 3);

  ['quarterYearSelector', 'annualYearSelector'].forEach(id => {
    const sel = document.getElementById(id);
    sel.innerHTML = sortedYears.map(y =>
      `<option value="${y}" ${y === currentYear ? 'selected' : ''}>${y}</option>`
    ).join('');
  });

  document.getElementById('quarterSelector').value = String(currentQuarter);
}

// ─── Initialization ──────────────────────────────────────
async function initReports() {
  [allOrders, allStages, allSubcomponents, allProductionParts] = await Promise.all([
    db.getRepairOrders(),
    db.getProductionStages(),
    db.getSubcomponents(),
    db.getProductionParts()
  ]);

  // Also load completed/scrapped/archived orders
  const { data: historicData } = await window.supabaseClient
    .from('repair_orders').select('*')
    .in('status', ['Completed', 'Scrapped', 'Cancelled'])
    .order('date_completed', { ascending: false });
  if (historicData) {
    const historicOrders = historicData.map(o => {
      const result = {};
      Object.keys(o).forEach(key => {
        const camelKey = key.replace(/_([a-z])/g, (g) => g[1].toUpperCase());
        result[camelKey] = o[key];
      });
      return result;
    });
    const existingIds = new Set(allOrders.map(o => o.id));
    historicOrders.forEach(o => {
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

  populateSelectors();
  await loadWeeklyReport();
}

document.addEventListener('DOMContentLoaded', async () => {
  await initializeAuth();
  await initReports();
});
