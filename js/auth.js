// Authentication helper functions for Avemar Production Tracking

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

async function signOut() {
  if (!window.supabaseClient) return;
  await window.supabaseClient.auth.signOut();
  window.location.href = 'login.html';
}

async function initializeAuth() {
  const user = await requireAuth();

  if (user) {
    const nav = document.querySelector('nav .flex.items-center.gap-6');
    if (nav) {
      const userInfo = document.createElement('div');
      userInfo.className = 'flex items-center gap-3 ml-4 pl-4 border-l border-white/20';
      userInfo.innerHTML = `
        <span class="text-gray-400 text-sm">${user.email}</span>
        <button onclick="signOut()" class="text-red-400 hover:text-red-300 transition" title="Sign Out">
          <i class="fas fa-sign-out-alt"></i>
        </button>
      `;
      nav.appendChild(userInfo);
    }
  }

  return user;
}
