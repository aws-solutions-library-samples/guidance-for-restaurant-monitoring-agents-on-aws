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
        UserPoolId: 'us-east-1_irtVFCmZ4',
        ClientId: '76oq6mah56p6t4tchkfej1vmg8'
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
                // Update nav user display
                var nameEl = document.getElementById('sh-user-name');
                var userEl = document.getElementById('sh-user');
                if (nameEl && userEl) {
                    user.getUserAttributes(function(e, attrs) {
                        if (!e && attrs) {
                            var name = attrs.find(function(a) { return a.getName() === 'name'; });
                            if (name && nameEl) nameEl.textContent = name.getValue();
                        }
                    });
                    userEl.style.display = 'flex';
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

const API_URL = 'https://kipgsctrp4.execute-api.us-east-1.amazonaws.com/prod';
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
// NAVIGATION
// ============================================
function renderNav(activePage) {
    const pages = [
        { id: 'dashboard', href: 'index.html', icon: '📊', label: 'Dashboard' },
        { id: 'equipment', href: '3d-twin.html', icon: '🏭', label: 'Equipment 3D Twin' },
        { id: 'inventory', href: 'inventory.html', icon: '📦', label: 'Inventory' },
        { id: 'staffing', href: 'staffing.html', icon: '👥', label: 'Staffing' },
        { id: 'tickets', href: 'tickets.html', icon: '🎫', label: 'Tickets' }
    ];

    const header = document.createElement('div');
    header.className = 'shared-header';
    header.innerHTML = `
        <div class="sh-bar">
            <h1>🍔 AnyCompany Restaurant Monitoring System</h1>
            <p>AI-Powered Kitchen Management — Georgia Locations</p>
            <div class="sh-user" id="sh-user" style="display:none;">
                <span id="sh-user-name"></span>
                <button class="sh-signout" onclick="sharedSignOut()">Sign Out</button>
            </div>
        </div>
        <nav class="sh-nav">
            ${pages.map(p => `<a href="${p.href}" class="${p.id === activePage ? 'active' : ''}">${p.icon} ${p.label}</a>`).join('')}
        </nav>
    `;
    document.body.prepend(header);

    // Check auth
    checkAuth();
}

// ============================================
// AUTH CHECK (lightweight — no Cognito SDK needed on sub-pages)
// ============================================
function checkAuth() {
    // Look for Cognito tokens in localStorage
    const keys = Object.keys(localStorage);
    const idTokenKey = keys.find(k => k.includes('idToken'));
    if (idTokenKey) {
        const userEl = document.getElementById('sh-user');
        if (userEl) userEl.style.display = 'block';
        // Try to get user name from token
        try {
            const token = localStorage.getItem(idTokenKey);
            const payload = JSON.parse(atob(token.split('.')[1]));
            const nameEl = document.getElementById('sh-user-name');
            if (nameEl) nameEl.textContent = 'Welcome, ' + (payload.name || payload.email || 'User');
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
                <h4>🤖 Kitchen Assistant AI</h4>
                <small>Ask about equipment, tickets, or locations</small>
            </div>
            <div class="chat-messages" id="chat-messages">
                <div class="message bot"><div class="message-content">Hi! Ask me about equipment status, tickets, inventory, or staffing. 🎤 Use the mic for voice input.</div></div>
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
        .shared-header { position: relative; z-index: 1000; }
        .sh-bar { background: #2c3e50; color: white; padding: 1rem; text-align: center; position: relative; }
        .sh-bar h1 { font-size: 1.8rem; margin-bottom: 0.3rem; font-weight: bold; }
        .sh-bar p { font-size: 1rem; opacity: 0.9; }
        .sh-nav { background: #34495e; padding: 0.5rem; text-align: center; }
        .sh-nav a { color: white; text-decoration: none; margin: 0 0.8rem; padding: 0.5rem 1rem; border-radius: 4px; display: inline-block; }
        .sh-nav a:hover, .sh-nav a.active { background: #3498db; }
        .sh-user { position: absolute; top: 50%; right: 1rem; transform: translateY(-50%); display: flex; align-items: center; gap: 0.5rem; font-size: 0.9rem; }
        .sh-signout { background: #e74c3c; color: white; border: none; padding: 0.3rem 0.8rem; border-radius: 4px; cursor: pointer; font-size: 0.85rem; }
        .sh-signout:hover { background: #c0392b; }
        .chat-widget { position: fixed; bottom: 20px; right: 20px; z-index: 9999; }
        .chat-toggle { background: #e74c3c; color: white; border: none; border-radius: 50%; width: 72px; height: 72px; font-size: 36px; cursor: pointer; box-shadow: 0 4px 16px rgba(0,0,0,0.35); transition: transform 0.2s; }
        .chat-toggle:hover { background: #c0392b; transform: scale(1.1); }
        .chat-panel { display: none; flex-direction: column; position: absolute; bottom: 82px; right: 0; width: 380px; height: 450px; background: white; border-radius: 12px; box-shadow: 0 8px 24px rgba(0,0,0,0.3); overflow: hidden; }
        .chat-header { background: #3498db; color: white; padding: 1rem; text-align: center; }
        .chat-header h4 { margin: 0 0 0.2rem 0; }
        .chat-header small { opacity: 0.9; }
        .chat-messages { flex: 1; overflow-y: auto; padding: 1rem; background: #fafafa; }
        .chat-input input { flex: 1; padding: 0.5rem; border: 1px solid #ddd; border-radius: 4px; font-size: 0.9rem; min-width: 0; }
        .chat-input button { background: #3498db; color: white; border: none; padding: 0.5rem 1rem; margin-left: 0.5rem; border-radius: 4px; cursor: pointer; }
        .chat-input button:hover { background: #2980b9; }
        .message { margin-bottom: 0.8rem; }
        .message.user { text-align: right; }
        .message.bot { text-align: left; }
        .message-content { display: inline-block; padding: 0.5rem 1rem; border-radius: 12px; max-width: 85%; word-wrap: break-word; line-height: 1.4; }
        .message.user .message-content { background: #3498db; color: white; }
        .message.bot .message-content { background: #e8e8e8; color: #333; }
        .voice-btn { background: #e74c3c; color: white; border: none; width: 36px; height: 36px; border-radius: 50%; font-size: 16px; cursor: pointer; flex-shrink: 0; display: flex; align-items: center; justify-content: center; transition: background 0.2s; }
        .voice-btn:hover { opacity: 0.85; }
        .voice-btn.recording { background: #c0392b; animation: pulse-rec 1s infinite; }
        .voice-btn.voice-output-on { background: #27ae60; }
        .voice-btn.voice-output-off { background: #95a5a6; }
        @keyframes pulse-rec { 0%,100% { box-shadow: 0 0 0 0 rgba(192,57,43,0.5); } 50% { box-shadow: 0 0 0 8px rgba(192,57,43,0); } }
        .chat-input { display: flex; padding: 0.8rem; border-top: 1px solid #eee; background: white; gap: 0.4rem; align-items: center; }
    `;
    document.head.appendChild(style);
}

injectSharedStyles();
