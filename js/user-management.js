// User Management page logic for IT Admins
let allUsers = [];
let currentUserRole = null;

async function loadUsers() {
  const container = document.getElementById('usersList');
  container.innerHTML = '<div class="text-gray-400 text-center py-8"><i class="fas fa-spinner fa-spin mr-2"></i>Loading users...</div>';

  const { data, error } = await window.supabaseClient.rpc('admin_list_users');

  if (error) {
    container.innerHTML = `<div class="text-gray-400 text-center py-8 text-sm">
      <i class="fas fa-exclamation-triangle text-amber-400 mr-2"></i>
      Could not load users. Make sure the <strong>it-admin-user-management.sql</strong> migration has been run.
    </div>`;
    console.error('Error loading users:', error);
    return;
  }

  allUsers = data || [];
  updateStats();
  renderUserList();
}

function updateStats() {
  const total = allUsers.length;
  const admins = allUsers.filter(u => u.role === 'admin' || u.role === 'it_admin' || u.role === 'super_admin').length;
  const standard = allUsers.filter(u => u.role === 'user' || !u.role).length;

  document.getElementById('totalUsers').textContent = total;
  document.getElementById('totalAdmins').textContent = admins;
  document.getElementById('totalStandard').textContent = standard;
}

function renderUserList() {
  const container = document.getElementById('usersList');

  if (allUsers.length === 0) {
    container.innerHTML = '<div class="text-gray-400 text-center py-8 text-sm">No users found.</div>';
    return;
  }

  container.innerHTML = allUsers.map(u => {
    const roleDisplay = getRoleDisplay(u.role);
    const lastLogin = u.last_sign_in ? new Date(u.last_sign_in).toLocaleDateString() : 'Never';
    const created = u.created_at ? new Date(u.created_at).toLocaleDateString() : '-';
    
    const canModify = canModifyUser(u.role);
    const isProtected = u.role === 'it_admin';

    return `
      <div class="flex items-center gap-4 p-4 bg-white/5 rounded-lg hover:bg-white/10 transition">
        <div class="w-10 h-10 ${roleDisplay.bgClass} rounded-full flex items-center justify-center flex-shrink-0">
          <i class="fas ${roleDisplay.icon} ${roleDisplay.textClass} text-sm"></i>
        </div>
        <div class="flex-1 min-w-0">
          <p class="text-white font-medium truncate">${u.email}</p>
          <p class="text-xs text-gray-500">Created: ${created} • Last login: ${lastLogin}</p>
        </div>
        <span class="text-xs ${roleDisplay.textClass} font-medium px-3 py-1 rounded-full ${roleDisplay.pillClass}">${roleDisplay.label}</span>
        <div class="flex items-center gap-2">
          ${canModify ? `
            <button onclick="showEditRoleModal('${u.id}', '${u.email.replace(/'/g, "\\'")}', '${u.role || 'user'}')"
              class="text-glassAero-sky hover:text-sky-300 transition text-sm px-3 py-1.5 rounded-lg bg-glassAero-sky/10 hover:bg-glassAero-sky/20"
              title="Change Role">
              <i class="fas fa-user-edit"></i>
            </button>
            <button onclick="showResetPwModal('${u.id}', '${u.email.replace(/'/g, "\\'")}')"
              class="text-glassAero-gold hover:text-amber-300 transition text-sm px-3 py-1.5 rounded-lg bg-glassAero-gold/10 hover:bg-glassAero-gold/20"
              title="Reset Password">
              <i class="fas fa-key"></i>
            </button>
            <button onclick="showDeleteUserModal('${u.id}', '${u.email.replace(/'/g, "\\'")}')"
              class="text-red-400 hover:text-red-300 transition text-sm px-3 py-1.5 rounded-lg bg-red-500/10 hover:bg-red-500/20"
              title="Delete User">
              <i class="fas fa-trash"></i>
            </button>
          ` : `
            <span class="text-xs text-gray-500 italic">Protected</span>
          `}
        </div>
      </div>
    `;
  }).join('');
}

function getRoleDisplay(role) {
  switch (role) {
    case 'super_admin':
      return {
        label: 'Super Admin',
        icon: 'fa-crown',
        textClass: 'text-red-400',
        bgClass: 'bg-red-500/20',
        pillClass: 'bg-red-500/20'
      };
    case 'admin':
      return {
        label: 'Admin',
        icon: 'fa-user-shield',
        textClass: 'text-glassAero-gold',
        bgClass: 'bg-glassAero-gold/20',
        pillClass: 'bg-glassAero-gold/20'
      };
    case 'it_admin':
      return {
        label: 'IT Admin',
        icon: 'fa-user-cog',
        textClass: 'text-purple-400',
        bgClass: 'bg-purple-500/20',
        pillClass: 'bg-purple-500/20'
      };
    default:
      return {
        label: 'User',
        icon: 'fa-user',
        textClass: 'text-glassAero-emerald',
        bgClass: 'bg-glassAero-emerald/20',
        pillClass: 'bg-glassAero-emerald/20'
      };
  }
}

function canModifyUser(targetRole) {
  // super_admin can modify anyone except other super_admins
  if (currentUserRole === 'super_admin') {
    return targetRole !== 'super_admin';
  }
  // it_admin can modify users and regular admins, but not super_admin or other it_admins
  if (currentUserRole === 'it_admin') {
    return targetRole !== 'super_admin' && targetRole !== 'it_admin';
  }
  // regular admin has VIEW ONLY access - no CRUD
  return false;
}

// ─── Add User Modal ─────────────────────────────────────
function showAddUserModal() {
  document.getElementById('newUserEmail').value = '';
  document.getElementById('newUserPassword').value = '';
  document.getElementById('newUserPasswordConfirm').value = '';
  document.getElementById('newUserRole').value = 'user';
  document.getElementById('addUserError').classList.add('hidden');
  document.getElementById('addUserSuccess').classList.add('hidden');
  document.getElementById('addUserBtn').disabled = false;
  document.getElementById('addUserBtn').innerHTML = '<i class="fas fa-plus mr-2"></i>Create User';
  
  // Super admin can create IT admin users
  const roleSelect = document.getElementById('newUserRole');
  const hasItAdminOption = Array.from(roleSelect.options).some(o => o.value === 'it_admin');
  if (currentUserRole === 'super_admin' && !hasItAdminOption) {
    const opt = document.createElement('option');
    opt.value = 'it_admin';
    opt.textContent = 'IT Admin (User Management)';
    roleSelect.appendChild(opt);
  }
  
  document.getElementById('addUserModal').classList.remove('hidden');
}

function hideAddUserModal() {
  document.getElementById('addUserModal').classList.add('hidden');
}

async function handleAddUser(event) {
  event.preventDefault();
  
  const email = document.getElementById('newUserEmail').value.trim();
  const password = document.getElementById('newUserPassword').value;
  const passwordConfirm = document.getElementById('newUserPasswordConfirm').value;
  const role = document.getElementById('newUserRole').value;
  const errorEl = document.getElementById('addUserError');
  const successEl = document.getElementById('addUserSuccess');
  const btn = document.getElementById('addUserBtn');

  errorEl.classList.add('hidden');
  successEl.classList.add('hidden');

  if (password !== passwordConfirm) {
    errorEl.textContent = 'Passwords do not match.';
    errorEl.classList.remove('hidden');
    return;
  }

  if (password.length < 6) {
    errorEl.textContent = 'Password must be at least 6 characters.';
    errorEl.classList.remove('hidden');
    return;
  }

  btn.disabled = true;
  btn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>Creating...';

  const { data, error } = await window.supabaseClient.rpc('it_admin_create_user', {
    user_email: email,
    user_password: password,
    user_role: role
  });

  if (error) {
    errorEl.textContent = error.message || 'Failed to create user.';
    errorEl.classList.remove('hidden');
    btn.disabled = false;
    btn.innerHTML = '<i class="fas fa-plus mr-2"></i>Create User';
  } else {
    successEl.textContent = `User ${email} created successfully!`;
    successEl.classList.remove('hidden');
    btn.innerHTML = '<i class="fas fa-check mr-2"></i>Created!';
    setTimeout(() => {
      hideAddUserModal();
      loadUsers();
    }, 1500);
  }
}

// ─── Edit Role Modal ────────────────────────────────────
function showEditRoleModal(userId, email, currentRole) {
  document.getElementById('editRoleUserId').value = userId;
  document.getElementById('editRoleUserLabel').textContent = 'Change role for: ' + email;
  document.getElementById('editRoleError').classList.add('hidden');
  document.getElementById('editRoleSuccess').classList.add('hidden');
  document.getElementById('editRoleBtn').disabled = false;
  document.getElementById('editRoleBtn').innerHTML = '<i class="fas fa-save mr-2"></i>Save';
  
  // Super admin can assign IT admin role
  const roleSelect = document.getElementById('editRoleSelect');
  const hasItAdminOption = Array.from(roleSelect.options).some(o => o.value === 'it_admin');
  if (currentUserRole === 'super_admin' && !hasItAdminOption) {
    const opt = document.createElement('option');
    opt.value = 'it_admin';
    opt.textContent = 'IT Admin (User Management)';
    roleSelect.appendChild(opt);
  }
  
  document.getElementById('editRoleSelect').value = currentRole || 'user';
  document.getElementById('editRoleModal').classList.remove('hidden');
}

function hideEditRoleModal() {
  document.getElementById('editRoleModal').classList.add('hidden');
}

async function handleChangeRole() {
  const userId = document.getElementById('editRoleUserId').value;
  const newRole = document.getElementById('editRoleSelect').value;
  const errorEl = document.getElementById('editRoleError');
  const successEl = document.getElementById('editRoleSuccess');
  const btn = document.getElementById('editRoleBtn');

  errorEl.classList.add('hidden');
  successEl.classList.add('hidden');

  btn.disabled = true;
  btn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>Saving...';

  const { data, error } = await window.supabaseClient.rpc('it_admin_set_role', {
    target_user_id: userId,
    new_role: newRole
  });

  if (error) {
    errorEl.textContent = error.message || 'Failed to change role.';
    errorEl.classList.remove('hidden');
    btn.disabled = false;
    btn.innerHTML = '<i class="fas fa-save mr-2"></i>Save';
  } else {
    successEl.textContent = 'Role updated successfully!';
    successEl.classList.remove('hidden');
    btn.innerHTML = '<i class="fas fa-check mr-2"></i>Saved!';
    setTimeout(() => {
      hideEditRoleModal();
      loadUsers();
    }, 1500);
  }
}

// ─── Delete User Modal ──────────────────────────────────
function showDeleteUserModal(userId, email) {
  document.getElementById('deleteUserId').value = userId;
  document.getElementById('deleteUserLabel').innerHTML = `Are you sure you want to delete <strong>${email}</strong>?`;
  document.getElementById('deleteUserError').classList.add('hidden');
  document.getElementById('deleteUserBtn').disabled = false;
  document.getElementById('deleteUserBtn').innerHTML = '<i class="fas fa-trash mr-2"></i>Delete User';
  document.getElementById('deleteUserModal').classList.remove('hidden');
}

function hideDeleteUserModal() {
  document.getElementById('deleteUserModal').classList.add('hidden');
}

async function handleDeleteUser() {
  const userId = document.getElementById('deleteUserId').value;
  const errorEl = document.getElementById('deleteUserError');
  const btn = document.getElementById('deleteUserBtn');

  errorEl.classList.add('hidden');

  btn.disabled = true;
  btn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>Deleting...';

  const { data, error } = await window.supabaseClient.rpc('it_admin_delete_user', {
    target_user_id: userId
  });

  if (error) {
    errorEl.textContent = error.message || 'Failed to delete user.';
    errorEl.classList.remove('hidden');
    btn.disabled = false;
    btn.innerHTML = '<i class="fas fa-trash mr-2"></i>Delete User';
  } else {
    hideDeleteUserModal();
    loadUsers();
  }
}

// ─── Reset Password Modal ───────────────────────────────
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

// ─── Initialize ─────────────────────────────────────────
document.addEventListener('DOMContentLoaded', async () => {
  try {
    console.log('User Management: Initializing...');
    
    const user = await requireAuth();
    console.log('User Management: Auth result:', user);
    
    if (!user) {
      console.log('User Management: No user, returning');
      return;
    }

    currentUserRole = user.app_metadata?.role || 'user';
    console.log('User Management: Role =', currentUserRole, 'Email =', user.email);

    // Only it_admin, super_admin can access this page (admin is view-only but allowed)
    const allowedRoles = ['it_admin', 'super_admin', 'admin'];
    if (!allowedRoles.includes(currentUserRole)) {
      console.log('User Management: Not authorized, redirecting');
      window.location.href = 'index.html';
      return;
    }

    const nav = document.getElementById('navLinks');
    console.log('User Management: Nav element found:', !!nav);
    
    if (nav) {
      // super_admin and admin get full nav with Dashboard link
      if (currentUserRole === 'super_admin' || currentUserRole === 'admin') {
        nav.innerHTML = `
          <a href="index.html" class="text-gray-300 hover:text-white transition"><i class="fas fa-chart-line mr-2"></i>Dashboard</a>
          <a href="user-management.html" class="text-glassAero-gold font-medium"><i class="fas fa-users-cog mr-2"></i>User Management</a>
          <a href="settings.html" class="text-gray-300 hover:text-white transition"><i class="fas fa-cog mr-2"></i>Settings</a>
        `;
      }
      // it_admin only sees User Management (default HTML)

      const userInfo = document.createElement('div');
      userInfo.className = 'flex items-center gap-3 ml-4 pl-4 border-l border-white/20';
      userInfo.innerHTML = `
        <span class="text-gray-400 text-sm">${user.email || 'Unknown'}</span>
        <button onclick="signOut()" class="text-red-400 hover:text-red-300 transition" title="Sign Out">
          <i class="fas fa-sign-out-alt"></i>
        </button>
      `;
      nav.appendChild(userInfo);
      console.log('User Management: User info appended');
    }

    await loadUsers();
  } catch (err) {
    console.error('User Management: Initialization error:', err);
  }
});
