/**
 * Shared navigation and chat widget for all pages
 * Include this on every page for consistent nav + chat
 */

// Load Cognito SDK dynamically
(function() {
    if (!window.AmazonCognitoIdentity) {
        var s = document.createElement('script');
        s.src = 'https://unpkg.com/amazon-cognito-identity-js@6.3.12/dist/amazon-cognito-identity.min.js';
        s.onload = function() { initAuth(); };
        document.head.appendChild(s);
    }
})();

// Auth globals
var auth = null;
var _cognitoPool = null;
var _authReadyResolve = null;
var authReady = new Promise(function(resolve) { _authReadyResolve = resolve; });

function initAuth() {
    if (!window.AmazonCognitoIdentity) return;
    _cognitoPool = new AmazonCognitoIdentity.CognitoUserPool({
        UserPoolId: window.APP_CONFIG && window.APP_CONFIG.userPoolId,
        ClientId: window.APP_CONFIG && window.APP_CONFIG.userPoolWebClientId
    });
    var user = _cognitoPool.getCurrentUser();
    if (user) {
        user.getSession(function(err, session) {
            if (!err && session && session.isValid()) {
                auth = { currentUser: user, getUserInfo: function() {
                    return new Promise(function(resolve, reject) {
                        user.getSession(function(e, s) {
                            if (e) return reject(e);
                            resolve({ token: s.getIdToken().getJwtToken() });
                        });
                    });
                }};
                _authReadyResolve(auth);
                // Update sidebar user display
                var nameEl = document.getElementById('sidebar-user-name');
                if (nameEl) {
                    user.getUserAttributes(function(e, attrs) {
                        if (!e && attrs) {
                            var name = attrs.find(function(a) { return a.getName() === 'name'; });
                            if (name && nameEl) nameEl.textContent = name.getValue();
                        }
                    });
                }
            } else {
                window.location.href = 'login.html';
            }
        });
    } else {
        // Not on login page? Redirect
        if (window.location.pathname.indexOf('login.html') === -1) {
            window.location.href = 'login.html';
        }
    }
}

function sharedSignOut() {
    if (_cognitoPool) {
        var user = _cognitoPool.getCurrentUser();
        if (user) user.signOut();
    }
    window.location.href = 'login.html';
}

const API_URL = (window.APP_CONFIG && window.APP_CONFIG.apiUrl) || '';
const CHAT_URL = API_URL + '/chat';

// Authenticated fetch helper - use this instead of raw fetch() for API calls
async function authFetch(url, options) {
    options = options || {};
    options.headers = options.headers || {};
    try {
        await authReady;
        if (auth && auth.currentUser) {
            var info = await auth.getUserInfo();
            if (info.token) options.headers['Authorization'] = info.token;
        }
    } catch (e) { /* proceed without token */ }
    return fetch(url, options);
}

// Sanitize user input to prevent XSS via innerHTML
function escapeHtml(str) {
    const div = document.createElement('div');
    div.appendChild(document.createTextNode(str));
    return div.innerHTML;
}

// ============================================
// NAVIGATION (sidebar is now per-page; this is a no-op for backward compat)
// ============================================
function renderNav(activePage) {
    // Top nav removed — each page now has its own sidebar.
    // Keep this function so existing calls don't throw errors.
    checkAuth();
}

// ============================================
// SIDEBAR NAV POPULATION — auto-fills #sidebar-nav on any page
// ============================================
function populateSidebar() {
    var navEl = document.getElementById('sidebar-nav');
    if (!navEl) return;
    var path = window.location.pathname;
    var pages = [
        { id: 'dashboard', href: 'index.html', icon: 'ti-dashboard', label: 'Dashboard' },
        { id: 'equipment', href: '3d-twin.html', icon: 'ti-cpu', label: 'Equipment 3D Twin' },
        { id: 'inventory', href: 'inventory.html', icon: 'ti-packages', label: 'Inventory' },
        { id: 'staffing', href: 'staffing.html', icon: 'ti-users', label: 'Staffing' },
        { id: 'tickets', href: 'tickets.html', icon: 'ti-ticket', label: 'Tickets' }
    ];
    navEl.innerHTML = pages.map(function(p) {
        var isActive = path.indexOf(p.href) !== -1 || (p.id === 'dashboard' && (path.endsWith('/') || path.endsWith('/index.html')));
        return '<a href="' + p.href + '" style="display:flex;align-items:center;gap:0.75rem;padding:0.75rem 1rem;border-radius:0.5rem;color:' +
            (isActive ? '#fff;background:#f97316;' : '#d1d5db;background:transparent;') +
            'text-decoration:none;font-size:14px;font-weight:500;transition:background 0.15s;" ' +
            'onmouseover="if(!this.style.background.includes(\'#f97316\'))this.style.background=\'rgba(255,255,255,0.1)\'" ' +
            'onmouseout="if(!this.style.background.includes(\'#f97316\'))this.style.background=\'transparent\'">' +
            '<i class="ti ' + p.icon + '" style="font-size:1.25rem;"></i><span>' + p.label + '</span></a>';
    }).join('');
    checkAuth();
}
// Run when DOM is ready (handles scripts in <head> or <body>)
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', populateSidebar);
} else {
    populateSidebar();
}

// ============================================
// AUTH CHECK (lightweight — no Cognito SDK needed on sub-pages)
// ============================================
function checkAuth() {
    const keys = Object.keys(localStorage);
    const idTokenKey = keys.find(k => k.includes('idToken'));
    if (idTokenKey) {
        try {
            const token = localStorage.getItem(idTokenKey);
            const payload = JSON.parse(atob(token.split('.')[1]));
            const displayName = payload.name || payload.email || 'User';
            // Update sidebar user name if present
            const sidebarName = document.getElementById('sidebar-user-name');
            if (sidebarName) sidebarName.textContent = displayName;
        } catch(e) { /* ignore */ }
    }
}

function sharedSignOut() {
    // Clear all Cognito tokens
    const keys = Object.keys(localStorage);
    keys.forEach(k => {
        if (k.includes('Cognito') || k.includes('amplify')) {
            localStorage.removeItem(k);
        }
    });
    window.location.href = 'login.html';
}

// ============================================
// CHAT WIDGET
// ============================================
let chatSessionId = null;

function renderChatWidget() {
    console.log('🔧 renderChatWidget called');
    const widget = document.createElement('div');
    widget.className = 'chat-widget';
    widget.innerHTML = `
        <button class="chat-toggle" onclick="toggleChat()" aria-label="Open chat">🧑‍💼</button>
        <div class="chat-panel" id="chat-panel">
            <div class="chat-header">
                <h4>🤖 Restaurant Assistant AI</h4>
                <small>Ask about equipment, tickets, or locations</small>
            </div>
            <div class="chat-messages" id="chat-messages">
                <div class="message bot"><div class="message-content">Hi! I can help with equipment issues, inventory reorders, staffing requests, and maintenance tickets. Try asking:<br>• "What equipment needs attention?"<br>• "Which items need reordering?"<br>• "Show staffing gaps for today"<br>• "Create a ticket for the walk-in cooler"</div></div>
            </div>
            <div class="chat-input">
                <button class="voice-btn" id="voice-input-btn" onclick="toggleVoiceInput()" title="Voice input">🎤</button>
                <input type="text" id="chat-input" placeholder="Ask a question..." onkeypress="if(event.key==='Enter')sendChat()">
                <button onclick="sendChat()">Send</button>
                <button class="voice-btn voice-output-on" id="voice-output-toggle" onclick="toggleVoiceOutput()" title="Toggle voice responses">🔊</button>
            </div>
        </div>
    `;
    document.body.appendChild(widget);
    // Load voice client
    if (!document.querySelector('script[src="voice-client.js"]')) {
        const s = document.createElement('script');
        s.src = 'voice-client.js';
        document.head.appendChild(s);
    }
}

function toggleChat() {
    const panel = document.getElementById('chat-panel');
    panel.style.display = panel.style.display === 'flex' ? 'none' : 'flex';
}

async function sendChat() {
    const input = document.getElementById('chat-input');
    const msg = input.value.trim();
    if (!msg) return;
    input.value = '';

    addMsg(msg, 'user');

    if (!chatSessionId) chatSessionId = 'chat_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);

    // Show typing
    addMsg('...', 'bot', true);

    try {
        const chatHeaders = { 'Content-Type': 'application/json' };
        try {
            if (typeof auth !== 'undefined' && auth.currentUser) {
                const info = await auth.getUserInfo();
                if (info.token) chatHeaders['Authorization'] = info.token;
            }
        } catch (e) { /* proceed without token */ }

        const res = await fetch(CHAT_URL, {
            method: 'POST',
            headers: chatHeaders,
            body: JSON.stringify({ prompt: msg, sessionId: chatSessionId })
        });
        removeTyping();
        if (!res.ok) throw new Error('API error ' + res.status);
        const data = await res.json();
        if (data.sessionId) chatSessionId = data.sessionId;
        const botText = data.result || data.response || 'No response';
        addMsg(botText, 'bot');
    } catch (e) {
        removeTyping();
        addMsg('Sorry, something went wrong. Please try again.', 'bot');
    }
}

function addMsg(text, sender, isTyping) {
    const container = document.getElementById('chat-messages');
    const div = document.createElement('div');
    div.className = 'message ' + sender;
    if (isTyping) div.id = 'typing-indicator';
    div.innerHTML = '<div class="message-content">' + escapeHtml(text).replace(/\n/g, '<br>') + '</div>';
    container.appendChild(div);
    container.scrollTop = container.scrollHeight;
}

function removeTyping() {
    const el = document.getElementById('typing-indicator');
    if (el) el.remove();
}

// ============================================
// VOICE CHAT — Nova Sonic via AgentCore WebSocket
// ============================================
let voiceClient = null;
let isVoiceActive = false;


async function toggleVoiceInput() {
    if (isVoiceActive) {
        stopVoiceInput();
        return;
    }

    const btn = document.getElementById('voice-input-btn');
    btn.classList.add('recording');
    btn.textContent = '⏹️';
    isVoiceActive = true;
    addMsg('🎤 Connecting to voice agent...', 'bot');

    try {
        voiceClient = new VoiceClient({
            tokenUrl: API_URL + '/voice-token',
            onTranscript: (role, text) => {
                addMsg(text, role === 'user' ? 'user' : 'bot');
            },
            onStatus: (status) => {
                const badge = document.getElementById('voice-listening-badge');
                if (badge) badge.querySelector('.message-content').textContent = status;
            },
            onError: (err) => {
                addMsg('⚠️ Voice error: ' + err, 'bot');
                stopVoiceInput();
            }
        });

        await voiceClient.connect();

        if (!document.getElementById('voice-listening-badge')) {
            const badge = document.createElement('div');
            badge.id = 'voice-listening-badge';
            badge.className = 'message bot';
            badge.innerHTML = '<div class="message-content" style="font-style:italic;opacity:0.7">🎤 Voice mode — speak naturally</div>';
            document.getElementById('chat-messages').appendChild(badge);
        }
    } catch (e) {
        console.error('Voice connect failed:', e);
        addMsg('⚠️ Could not start voice: ' + e.message, 'bot');
        stopVoiceInput();
    }
}

function stopVoiceInput() {
    const btn = document.getElementById('voice-input-btn');
    if (btn) { btn.classList.remove('recording'); btn.textContent = '🎤'; }
    isVoiceActive = false;
    if (voiceClient) {
        voiceClient.disconnect();
        voiceClient = null;
    }
    const badge = document.getElementById('voice-listening-badge');
    if (badge) badge.remove();
}

// Voice output toggle (for text chat TTS fallback)
let isVoiceOutputEnabled = false;
function toggleVoiceOutput() {
    isVoiceOutputEnabled = !isVoiceOutputEnabled;
    const btn = document.getElementById('voice-output-toggle');
    if (isVoiceOutputEnabled) {
        btn.classList.add('voice-output-on');
        btn.classList.remove('voice-output-off');
        btn.innerHTML = '🔊';
    } else {
        btn.classList.remove('voice-output-on');
        btn.classList.add('voice-output-off');
        btn.innerHTML = '🔊<span style="position:absolute;font-size:22px;color:#e74c3c;top:50%;left:50%;transform:translate(-50%,-50%);font-weight:bold;pointer-events:none;">✕</span>';
        btn.style.position = 'relative';
        if ('speechSynthesis' in window) window.speechSynthesis.cancel();
    }
}

// ============================================
// SHARED STYLES (injected once)
// ============================================
function injectSharedStyles() {
    if (document.getElementById('shared-nav-styles')) return;
    const style = document.createElement('style');
    style.id = 'shared-nav-styles';
    style.textContent = `
        .chat-widget { position: fixed; bottom: 20px; right: 20px; z-index: 9999; font-family: 'Inter', system-ui, -apple-system, sans-serif; font-size: 14px; }
        .chat-toggle { background: #f97316; color: white; border: none; border-radius: 50%; width: 64px; height: 64px; font-size: 32px; cursor: pointer; box-shadow: 0 4px 16px rgba(0,0,0,0.35); transition: transform 0.2s; }
        .chat-toggle:hover { background: #ea580c; transform: scale(1.1); }
        .chat-panel { display: none; flex-direction: column; position: absolute; bottom: 76px; right: 0; width: 380px; height: 480px; background: white; border-radius: 12px; box-shadow: 0 8px 24px rgba(0,0,0,0.3); overflow: hidden; font-size: 14px; }
        .chat-header { background: #111827; color: white; padding: 1rem 1.25rem; }
        .chat-header h4 { margin: 0 0 0.2rem 0; font-size: 15px; font-weight: 600; }
        .chat-header small { opacity: 0.7; font-size: 12px; }
        .chat-messages { flex: 1; overflow-y: auto; padding: 1rem; background: #f9fafb; }
        .chat-input input { flex: 1; padding: 0.6rem 0.75rem; border: 1px solid #d1d5db; border-radius: 6px; font-size: 14px; min-width: 0; font-family: inherit; outline: none; }
        .chat-input input:focus { border-color: #f97316; box-shadow: 0 0 0 2px rgba(249,115,22,0.2); }
        .chat-input button { background: #f97316; color: white; border: none; padding: 0.6rem 1rem; margin-left: 0.4rem; border-radius: 6px; cursor: pointer; font-size: 14px; font-weight: 500; }
        .chat-input button:hover { background: #ea580c; }
        .message { margin-bottom: 0.8rem; }
        .message.user { text-align: right; }
        .message.bot { text-align: left; }
        .message-content { display: inline-block; padding: 0.6rem 1rem; border-radius: 12px; max-width: 85%; word-wrap: break-word; line-height: 1.5; font-size: 14px; }
        .message.user .message-content { background: #f97316; color: white; }
        .message.bot .message-content { background: #e5e7eb; color: #1f2937; }
        .voice-btn { background: #f97316; color: white; border: none; width: 36px; height: 36px; border-radius: 50%; font-size: 16px; cursor: pointer; flex-shrink: 0; display: flex; align-items: center; justify-content: center; transition: background 0.2s; }
        .voice-btn:hover { opacity: 0.85; }
        .voice-btn.recording { background: #dc2626; animation: pulse-rec 1s infinite; }
        .voice-btn.voice-output-on { background: #16a34a; }
        .voice-btn.voice-output-off { background: #9ca3af; }
        @keyframes pulse-rec { 0%,100% { box-shadow: 0 0 0 0 rgba(220,38,38,0.5); } 50% { box-shadow: 0 0 0 8px rgba(220,38,38,0); } }
        .chat-input { display: flex; padding: 0.75rem; border-top: 1px solid #e5e7eb; background: white; gap: 0.4rem; align-items: center; }
    `;
    document.head.appendChild(style);
}

injectSharedStyles();

// ============================================
// SIDEBAR TOGGLE & DARK MODE (global helpers)
// ============================================
function toggleSidebar() {
    var sb = document.getElementById('sidebar');
    var ov = document.getElementById('sidebar-overlay');
    if (sb) sb.classList.toggle('open');
    if (ov) ov.classList.toggle('hidden');
    // Also handle 3d-twin sidebar-nav class
    var sbNav = document.querySelector('.sidebar-nav');
    if (sbNav && sbNav !== sb) sbNav.classList.toggle('open');
}
function toggleDarkMode() {
    document.documentElement.classList.toggle('dark');
    localStorage.theme = document.documentElement.classList.contains('dark') ? 'dark' : 'light';
}
