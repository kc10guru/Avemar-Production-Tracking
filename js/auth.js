// Authentication helper functions for Glass Aero Production Tracking

async function requireAuth() {
  if (!window.supabaseClient) {
    console.error('Supabase not initialized');
    return null;
  }

  const { data: { session } } = await window.supabaseClient.auth.getSession();

  if (!session) {
    window.location.href = 'login.html';
    return null;
  }

  return session.user;
}

async function getCurrentUser() {
  if (!window.supabaseClient) return null;
  const { data: { user } } = await window.supabaseClient.auth.getUser();
  return user;
}

/** Returns true if user has admin role (app_metadata.role === 'admin') */
function isAdmin(user) {
  return user?.app_metadata?.role === 'admin';
}

async function signOut() {
  if (!window.supabaseClient) return;
  await window.supabaseClient.auth.signOut();
  window.location.href = 'login.html';
}

function injectChangePasswordModal() {
  const style = document.createElement('style');
  style.textContent = `
    #changePwOverlay { position:fixed; inset:0; background:rgba(0,0,0,0.6); backdrop-filter:blur(4px);
      display:flex; align-items:center; justify-content:center; z-index:9999; padding:1rem; }
    #changePwOverlay.pw-hidden { display:none; }
    #changePwCard { background:linear-gradient(145deg,#1e293b 0%,#0f172a 100%); border:1px solid rgba(255,255,255,0.1);
      border-radius:1rem; padding:2rem; max-width:420px; width:100%; color:#fff; }
    #changePwCard input { width:100%; background:rgba(255,255,255,0.05); border:1px solid rgba(255,255,255,0.1);
      border-radius:0.75rem; padding:0.65rem 1rem; color:#fff; font-size:0.875rem; outline:none; margin-top:0.25rem; }
    #changePwCard input:focus { border-color:#f59e0b; }
    #changePwCard label { display:block; font-size:0.8rem; color:#9ca3af; margin-top:1rem; }
    #changePwCard label:first-of-type { margin-top:0; }
  `;
  document.head.appendChild(style);

  const overlay = document.createElement('div');
  overlay.id = 'changePwOverlay';
  overlay.className = 'pw-hidden';
  overlay.innerHTML = `
    <div id="changePwCard">
      <h3 style="font-size:1.25rem;font-weight:700;margin-bottom:1.25rem"><i class="fas fa-key" style="color:#f59e0b;margin-right:0.5rem"></i>Change Password</h3>
      <label>New Password</label>
      <input type="password" id="newPassword" placeholder="Enter new password" minlength="6">
      <label>Confirm New Password</label>
      <input type="password" id="confirmPassword" placeholder="Confirm new password" minlength="6">
      <div id="changePwError" style="display:none;margin-top:0.75rem;padding:0.5rem 0.75rem;background:rgba(239,68,68,0.15);border:1px solid rgba(239,68,68,0.3);border-radius:0.5rem;color:#f87171;font-size:0.8rem"></div>
      <div id="changePwSuccess" style="display:none;margin-top:0.75rem;padding:0.5rem 0.75rem;background:rgba(16,185,129,0.15);border:1px solid rgba(16,185,129,0.3);border-radius:0.5rem;color:#34d399;font-size:0.8rem"></div>
      <div style="display:flex;gap:0.75rem;margin-top:1.25rem">
        <button onclick="cancelChangePassword()" style="flex:1;padding:0.6rem;border-radius:0.75rem;border:1px solid rgba(255,255,255,0.1);background:transparent;color:#9ca3af;cursor:pointer;font-size:0.875rem">Cancel</button>
        <button onclick="submitChangePassword()" id="changePwBtn" style="flex:1;padding:0.6rem;border-radius:0.75rem;border:none;background:#f59e0b;color:#000;cursor:pointer;font-weight:600;font-size:0.875rem">Update Password</button>
      </div>
    </div>
  `;
  document.body.appendChild(overlay);

  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) cancelChangePassword();
  });
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !overlay.classList.contains('pw-hidden')) cancelChangePassword();
  });
}

function showChangePassword() {
  document.getElementById('newPassword').value = '';
  document.getElementById('confirmPassword').value = '';
  document.getElementById('changePwError').style.display = 'none';
  document.getElementById('changePwSuccess').style.display = 'none';
  document.getElementById('changePwBtn').disabled = false;
  document.getElementById('changePwBtn').textContent = 'Update Password';
  document.getElementById('changePwOverlay').classList.remove('pw-hidden');
}

function cancelChangePassword() {
  document.getElementById('changePwOverlay').classList.add('pw-hidden');
}

async function submitChangePassword() {
  const newPw = document.getElementById('newPassword').value;
  const confirmPw = document.getElementById('confirmPassword').value;
  const errorEl = document.getElementById('changePwError');
  const successEl = document.getElementById('changePwSuccess');
  const btn = document.getElementById('changePwBtn');

  errorEl.style.display = 'none';
  successEl.style.display = 'none';

  if (newPw.length < 6) {
    errorEl.textContent = 'Password must be at least 6 characters.';
    errorEl.style.display = 'block';
    return;
  }
  if (newPw !== confirmPw) {
    errorEl.textContent = 'Passwords do not match.';
    errorEl.style.display = 'block';
    return;
  }

  btn.disabled = true;
  btn.textContent = 'Updating...';

  const { error } = await window.supabaseClient.auth.updateUser({ password: newPw });

  if (error) {
    errorEl.textContent = error.message;
    errorEl.style.display = 'block';
    btn.disabled = false;
    btn.textContent = 'Update Password';
  } else {
    successEl.textContent = 'Password updated successfully!';
    successEl.style.display = 'block';
    btn.textContent = 'Done';
    setTimeout(() => cancelChangePassword(), 1500);
  }
}

async function initializeAuth() {
  const user = await requireAuth();

  if (user) {
    injectChangePasswordModal();

    const nav = document.querySelector('nav .flex.items-center.gap-6');
    if (nav) {
      const userInfo = document.createElement('div');
      userInfo.className = 'flex items-center gap-3 ml-4 pl-4 border-l border-white/20';
      userInfo.innerHTML = `
        <span class="text-gray-400 text-sm">${user.email}</span>
        <button onclick="showChangePassword()" class="text-glassAero-sky hover:text-sky-300 transition" title="Change Password">
          <i class="fas fa-key"></i>
        </button>
        <button onclick="signOut()" class="text-red-400 hover:text-red-300 transition" title="Sign Out">
          <i class="fas fa-sign-out-alt"></i>
        </button>
      `;
      nav.appendChild(userInfo);

      if (!isAdmin(user)) {
        document.querySelectorAll('[data-admin-only]').forEach(el => el.style.display = 'none');
      }
    }
  }

  return user;
}
