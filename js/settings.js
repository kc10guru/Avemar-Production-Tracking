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
  await loadUsers();

  document.getElementById('dbStatus').innerHTML =
    '<i class="fas fa-check-circle mr-1"></i>Connected';
}

// ─── User Management ────────────────────────────────────
async function loadUsers() {
  const container = document.getElementById('usersList');
  container.innerHTML = '<div class="text-gray-400 text-center py-4"><i class="fas fa-spinner fa-spin mr-2"></i>Loading...</div>';

  const { data, error } = await window.supabaseClient.rpc('admin_list_users');

  if (error) {
    container.innerHTML = `<div class="text-gray-400 text-center py-4 text-sm">
      <i class="fas fa-exclamation-triangle text-amber-400 mr-2"></i>
      Could not load users. Run the <strong>admin-user-management.sql</strong> migration first.
    </div>`;
    console.error('Error loading users:', error);
    return;
  }

  if (!data || data.length === 0) {
    container.innerHTML = '<div class="text-gray-400 text-center py-4 text-sm">No users found.</div>';
    return;
  }

  container.innerHTML = data.map(u => {
    const isAdminUser = u.role === 'admin';
    const roleClass = isAdminUser ? 'text-glassAero-gold' : 'text-gray-400';
    const roleLabel = isAdminUser ? 'Admin' : 'User';
    const lastLogin = u.last_sign_in ? new Date(u.last_sign_in).toLocaleDateString() : 'Never';

    return `
      <div class="flex items-center gap-4 p-3 bg-white/5 rounded-lg">
        <div class="w-8 h-8 bg-glassAero-sky/20 rounded-full flex items-center justify-center flex-shrink-0">
          <i class="fas fa-user text-glassAero-sky text-xs"></i>
        </div>
        <div class="flex-1 min-w-0">
          <p class="text-white text-sm font-medium truncate">${u.email}</p>
          <p class="text-xs text-gray-500">Last login: ${lastLogin}</p>
        </div>
        <span class="text-xs ${roleClass} font-medium w-14 text-center">${roleLabel}</span>
        <button onclick="showResetPwModal('${u.id}', '${u.email.replace(/'/g, "\\'")}')"
          class="text-glassAero-sky hover:text-sky-300 transition text-sm px-3 py-1 rounded-lg bg-glassAero-sky/10 hover:bg-glassAero-sky/20"
          title="Reset Password">
          <i class="fas fa-key mr-1"></i>Reset
        </button>
      </div>
    `;
  }).join('');
}

function showResetPwModal(userId, email) {
  document.getElementById('resetPwUserId').value = userId;
  document.getElementById('resetPwUserLabel').textContent = 'Reset password for: ' + email;
  document.getElementById('resetPwNew').value = '';
  document.getElementById('resetPwConfirm').value = '';
  document.getElementById('resetPwError').classList.add('hidden');
  document.getElementById('resetPwSuccess').classList.add('hidden');
  document.getElementById('resetPwBtn').disabled = false;
  document.getElementById('resetPwBtn').textContent = 'Reset Password';
  document.getElementById('resetPwModal').classList.remove('hidden');
}

function hideResetPwModal() {
  document.getElementById('resetPwModal').classList.add('hidden');
}

async function handleResetPassword() {
  const userId = document.getElementById('resetPwUserId').value;
  const newPw = document.getElementById('resetPwNew').value;
  const confirmPw = document.getElementById('resetPwConfirm').value;
  const errorEl = document.getElementById('resetPwError');
  const successEl = document.getElementById('resetPwSuccess');
  const btn = document.getElementById('resetPwBtn');

  errorEl.classList.add('hidden');
  successEl.classList.add('hidden');

  if (newPw.length < 6) {
    errorEl.textContent = 'Password must be at least 6 characters.';
    errorEl.classList.remove('hidden');
    return;
  }
  if (newPw !== confirmPw) {
    errorEl.textContent = 'Passwords do not match.';
    errorEl.classList.remove('hidden');
    return;
  }

  btn.disabled = true;
  btn.textContent = 'Resetting...';

  const { error } = await window.supabaseClient.rpc('admin_reset_password', {
    target_user_id: userId,
    new_password: newPw
  });

  if (error) {
    errorEl.textContent = error.message || 'Failed to reset password.';
    errorEl.classList.remove('hidden');
    btn.disabled = false;
    btn.textContent = 'Reset Password';
  } else {
    successEl.textContent = 'Password reset successfully!';
    successEl.classList.remove('hidden');
    btn.textContent = 'Done';
    setTimeout(() => hideResetPwModal(), 1500);
  }
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

const HOURS_PER_DAY = 6.8;

function hoursToDays(hours) {
  return (hours / HOURS_PER_DAY).toFixed(1);
}

function updateStageTotals() {
  const inputs = document.querySelectorAll('.stage-time-input');
  let totalHours = 0;
  inputs.forEach(input => {
    const hours = Number(input.value) || 0;
    const daysEl = input.closest('.stage-row').querySelector('.stage-days');
    if (daysEl) daysEl.textContent = hoursToDays(hours) + ' days';
    totalHours += hours;
  });
  const totalEl = document.getElementById('stageTotalHours');
  const totalDaysEl = document.getElementById('stageTotalDays');
  if (totalEl) totalEl.textContent = totalHours + ' hours';
  if (totalDaysEl) totalDaysEl.textContent = hoursToDays(totalHours) + ' days';
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
    const days = hoursToDays(s.timeLimitHours);

    return `
      <div class="stage-row flex items-center gap-4 p-3 bg-white/5 rounded-lg">
        <span class="text-gray-500 text-sm font-medium w-8 text-right">${s.stageNumber}.</span>
        <span class="text-white text-sm flex-1">${s.stageName}</span>
        <span class="text-xs ${roleColor} w-24">${roleLabel}</span>
        <div class="flex items-center gap-2">
          <input type="number" value="${s.timeLimitHours}" min="1" data-stage-id="${s.id}"
            class="stage-time-input w-20 bg-white/5 border border-white/10 rounded-lg px-3 py-1 text-white text-sm text-center focus:outline-none focus:border-glassAero-gold"
            oninput="updateStageTotals()">
          <span class="text-xs text-gray-500">hours</span>
          <span class="stage-days text-xs text-glassAero-gold w-16 text-right">${days} days</span>
        </div>
      </div>
    `;
  }).join('');

  const totalHours = stages.reduce((sum, s) => sum + (Number(s.timeLimitHours) || 0), 0);
  container.innerHTML += `
    <div class="flex items-center gap-4 p-3 mt-3 bg-glassAero-gold/10 border border-glassAero-gold/30 rounded-lg">
      <span class="text-gray-500 text-sm font-medium w-8"></span>
      <span class="text-white text-sm font-semibold flex-1">Total (all 15 stages)</span>
      <span class="text-xs text-gray-400 w-24"></span>
      <div class="flex items-center gap-2">
        <span id="stageTotalHours" class="w-20 text-white text-sm font-semibold text-center">${totalHours} hours</span>
        <span class="text-xs text-gray-500">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>
        <span id="stageTotalDays" class="text-xs text-glassAero-gold font-semibold w-16 text-right">${hoursToDays(totalHours)} days</span>
      </div>
    </div>
    <p class="text-gray-500 text-xs mt-2 italic">Based on ${HOURS_PER_DAY} hours per man-day. Individual windshields may require fewer days if stages are skipped during inspection.</p>
  `;
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

// ─── Email Notification Config ──────────────────────────
async function loadEmailConfig() {
  const config = await db.getAppSetting('email_config');
  if (config) {
    document.getElementById('emailNotifyTo').value = config.notifyEmail || '';
    document.getElementById('emailPublicKey').value = config.publicKey || '';
    document.getElementById('emailServiceId').value = config.serviceId || '';
    document.getElementById('emailTemplateId').value = config.templateId || '';
  }
}

async function saveEmailConfig() {
  const btn = document.getElementById('saveEmailBtn');
  btn.disabled = true;
  btn.innerHTML = '<i class="fas fa-spinner fa-spin mr-1"></i>Saving...';

  const config = {
    notifyEmail: document.getElementById('emailNotifyTo').value.trim(),
    publicKey: document.getElementById('emailPublicKey').value.trim(),
    serviceId: document.getElementById('emailServiceId').value.trim(),
    templateId: document.getElementById('emailTemplateId').value.trim()
  };

  const success = await db.saveAppSetting('email_config', config);

  if (success) {
    btn.innerHTML = '<i class="fas fa-check mr-1"></i>Saved!';
  } else {
    btn.innerHTML = '<i class="fas fa-times mr-1"></i>Error';
    alert('Failed to save email config.');
  }

  btn.disabled = false;
  setTimeout(() => {
    btn.innerHTML = '<i class="fas fa-save mr-1"></i>Save Changes';
  }, 2000);
}

document.addEventListener('DOMContentLoaded', async () => {
  const user = await initializeAuth();
  if (!user || !isAdmin(user)) {
    window.location.href = 'index.html';
    return;
  }
  await loadSettings();
  await loadEmailConfig();
});
