// Support Tickets admin page logic

let allTickets = [];
let currentTicketId = null;

const STATUS_COLORS = {
  'Open':        'bg-red-500/20 text-red-400',
  'In Progress': 'bg-yellow-500/20 text-yellow-400',
  'Resolved':    'bg-emerald-500/20 text-emerald-400',
  'Closed':      'bg-gray-500/20 text-gray-400'
};

const PRIORITY_COLORS = {
  'Low':    'bg-gray-500/20 text-gray-400',
  'Medium': 'bg-blue-500/20 text-blue-400',
  'High':   'bg-red-500/20 text-red-400'
};

const TYPE_ICONS = {
  'Bug Report':       '<i class="fas fa-bug text-red-400"></i>',
  'Feature Request':  '<i class="fas fa-lightbulb text-yellow-400"></i>'
};

function setFilter(status) {
  document.getElementById('filterStatus').value = status;
  loadTickets();
}

async function loadTickets() {
  const status = document.getElementById('filterStatus').value;
  const type = document.getElementById('filterType').value;

  const filters = {};
  if (status) filters.status = status;
  if (type) filters.type = type;

  allTickets = await db.getSupportTickets(filters);

  // Load all tickets for stats (unfiltered)
  const all = await db.getSupportTickets({});
  document.getElementById('statOpen').textContent = all.filter(t => t.status === 'Open').length;
  document.getElementById('statInProgress').textContent = all.filter(t => t.status === 'In Progress').length;
  document.getElementById('statResolved').textContent = all.filter(t => t.status === 'Resolved').length;
  document.getElementById('statClosed').textContent = all.filter(t => t.status === 'Closed').length;

  renderTickets();
}

function renderTickets() {
  const table = document.getElementById('ticketsTable');

  if (allTickets.length === 0) {
    table.innerHTML = '<tr><td colspan="8" class="text-center py-12 text-gray-400"><i class="fas fa-check-circle mr-2 text-emerald-400"></i>No tickets found</td></tr>';
    return;
  }

  table.innerHTML = allTickets.map(t => {
    const statusClass = STATUS_COLORS[t.status] || 'bg-gray-500/20 text-gray-400';
    const priorityClass = PRIORITY_COLORS[t.priority] || 'bg-gray-500/20 text-gray-400';
    const typeIcon = TYPE_ICONS[t.type] || '';
    const date = new Date(t.createdAt).toLocaleDateString();

    return `
      <tr class="border-b border-white/5 hover:bg-white/5 transition cursor-pointer" onclick="openDetail('${t.id}')">
        <td class="py-3 px-4 font-mono text-xs text-glassAero-sky">${t.ticketNumber}</td>
        <td class="py-3 px-4">${typeIcon} <span class="text-xs text-gray-300 ml-1">${t.type}</span></td>
        <td class="py-3 px-4"><span class="px-2 py-0.5 rounded-full text-xs ${priorityClass}">${t.priority}</span></td>
        <td class="py-3 px-4 text-white max-w-xs truncate">${t.subject}</td>
        <td class="py-3 px-4 text-gray-400 text-xs">${t.reporterEmail || '--'}</td>
        <td class="py-3 px-4"><span class="px-2 py-0.5 rounded-full text-xs ${statusClass}">${t.status}</span></td>
        <td class="py-3 px-4 text-gray-500 text-xs">${date}</td>
        <td class="py-3 px-4 text-gray-400"><i class="fas fa-chevron-right text-xs"></i></td>
      </tr>
    `;
  }).join('');
}

async function openDetail(id) {
  currentTicketId = id;
  const t = allTickets.find(x => x.id === id) || await db.getSupportTicket(id);
  if (!t) return;

  document.getElementById('detailTitle').innerHTML =
    `<span class="text-glassAero-sky font-mono">${t.ticketNumber}</span> <span class="text-gray-400 font-normal text-base ml-2">${t.type}</span>`;

  const statusClass = STATUS_COLORS[t.status] || '';
  const priorityClass = PRIORITY_COLORS[t.priority] || '';
  const created = new Date(t.createdAt).toLocaleString();
  const resolved = t.resolvedAt ? new Date(t.resolvedAt).toLocaleString() : '';

  document.getElementById('detailBody').innerHTML = `
    <div class="grid grid-cols-2 gap-4">
      <div>
        <p class="text-xs text-gray-500 mb-1">Reporter</p>
        <p class="text-white text-sm">${t.reporterEmail || 'Unknown'}</p>
      </div>
      <div>
        <p class="text-xs text-gray-500 mb-1">Submitted</p>
        <p class="text-white text-sm">${created}</p>
      </div>
      <div>
        <p class="text-xs text-gray-500 mb-1">Priority</p>
        <span class="px-2 py-0.5 rounded-full text-xs ${priorityClass}">${t.priority}</span>
      </div>
      <div>
        <p class="text-xs text-gray-500 mb-1">Page</p>
        <p class="text-white text-sm">${t.pageUrl || 'Not specified'}</p>
      </div>
    </div>

    <div>
      <p class="text-xs text-gray-500 mb-1">Subject</p>
      <p class="text-white font-semibold">${t.subject}</p>
    </div>

    <div>
      <p class="text-xs text-gray-500 mb-1">Description</p>
      <div class="bg-glassAero-navy/50 rounded-lg p-4 text-sm text-gray-300 whitespace-pre-wrap">${t.description}</div>
    </div>

    <hr class="border-white/10">

    <div>
      <label class="block text-xs text-gray-500 mb-1">Status</label>
      <select id="detailStatus" class="w-full bg-glassAero-navy border border-white/10 rounded-lg px-4 py-2.5 text-white text-sm focus:border-glassAero-sky focus:outline-none">
        <option value="Open" ${t.status === 'Open' ? 'selected' : ''}>Open</option>
        <option value="In Progress" ${t.status === 'In Progress' ? 'selected' : ''}>In Progress</option>
        <option value="Resolved" ${t.status === 'Resolved' ? 'selected' : ''}>Resolved</option>
        <option value="Closed" ${t.status === 'Closed' ? 'selected' : ''}>Closed</option>
      </select>
    </div>

    <div>
      <label class="block text-xs text-gray-500 mb-1">Resolution Notes</label>
      <textarea id="detailResolution" rows="3" placeholder="Describe what was done to resolve this..."
        class="w-full bg-glassAero-navy border border-white/10 rounded-lg px-4 py-2.5 text-white text-sm focus:border-glassAero-sky focus:outline-none placeholder-gray-600 resize-none">${t.resolutionNotes || ''}</textarea>
    </div>

    ${resolved ? `<p class="text-xs text-gray-500">Resolved on: ${resolved}</p>` : ''}

    <div class="flex gap-3 pt-2">
      <button onclick="closeDetail()" class="flex-1 bg-white/10 hover:bg-white/20 text-white py-2.5 rounded-lg font-semibold transition text-sm">Cancel</button>
      <button onclick="saveTicketUpdate()" id="detailSaveBtn" class="flex-1 bg-glassAero-sky hover:bg-sky-600 text-white py-2.5 rounded-lg font-semibold transition text-sm">
        <i class="fas fa-save mr-2"></i>Save Changes
      </button>
    </div>
  `;

  document.getElementById('detailModal').classList.remove('hidden');
}

function closeDetail() {
  document.getElementById('detailModal').classList.add('hidden');
  currentTicketId = null;
}

async function saveTicketUpdate() {
  if (!currentTicketId) return;

  const btn = document.getElementById('detailSaveBtn');
  btn.disabled = true;
  btn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>Saving...';

  try {
    const newStatus = document.getElementById('detailStatus').value;
    const resolutionNotes = document.getElementById('detailResolution').value.trim();

    const updates = {
      status: newStatus,
      resolutionNotes: resolutionNotes || null
    };

    if (newStatus === 'Resolved' || newStatus === 'Closed') {
      const user = await getCurrentUser();
      updates.resolvedBy = user?.id || null;
      updates.resolvedAt = new Date().toISOString();
    }

    const saved = await db.updateSupportTicket(currentTicketId, updates);
    if (saved) {
      closeDetail();
      await loadTickets();
    } else {
      alert('Failed to update ticket.');
    }
  } catch (err) {
    console.error('Error updating ticket:', err);
    alert('Error updating ticket.');
  } finally {
    btn.disabled = false;
    btn.innerHTML = '<i class="fas fa-save mr-2"></i>Save Changes';
  }
}

document.addEventListener('DOMContentLoaded', async () => {
  const user = await initializeAuth();
  if (!user || !isAdmin(user)) {
    window.location.href = 'index.html';
    return;
  }
  await loadTickets();
});
