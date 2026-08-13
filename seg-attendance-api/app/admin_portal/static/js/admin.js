// Admin API helper
async function api(url, method = 'GET', body = null) {
    const token = localStorage.getItem('admin_token');
    const options = {
        method,
        headers: {
            'Content-Type': 'application/json',
        }
    };
    if (token) {
        options.headers['Authorization'] = `Bearer ${token}`;
    }
    if (body) {
        options.body = JSON.stringify(body);
    }

    const res = await fetch(url, options);

    if (res.status === 401 || res.status === 403) {
        window.location.href = '/admin/logout';
        return;
    }

    if (!res.ok) {
        const err = await res.json().catch(() => ({ error: 'Request failed' }));
        throw new Error(err.error || 'Request failed');
    }

    return await res.json();
}

// Format helpers
function formatDate(iso) {
    if (!iso) return '—';
    const d = new Date(iso);
    return d.toLocaleDateString('en-GB', {
        day: '2-digit', month: 'short', year: 'numeric'
    });
}

function formatTime(iso) {
    if (!iso) return '—';
    const d = new Date(iso);
    const now = new Date();
    const diff = (now - d) / 1000;

    if (diff < 60) return 'Just now';
    if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
    if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
    if (diff < 604800) return `${Math.floor(diff / 86400)}d ago`;
    return formatDate(iso);
}

function formatAction(action) {
    return action.replace(/_/g, ' ').replace(/\./g, ' → ');
}

function escapeHtml(text) {
    if (text === null || text === undefined) return '';
    const div = document.createElement('div');
    div.textContent = String(text);
    return div.innerHTML;
}

// Notifications
function showError(msg) {
    showFlash(msg, 'danger');
}

function showSuccess(msg) {
    showFlash(msg, 'success');
}

function showFlash(msg, type) {
    const div = document.createElement('div');
    div.className = `flash flash-${type}`;
    div.textContent = msg;
    div.style.position = 'fixed';
    div.style.top = '20px';
    div.style.right = '20px';
    div.style.zIndex = '1000';
    div.style.maxWidth = '400px';
    document.body.appendChild(div);
    setTimeout(() => div.remove(), 4000);
}