/**
 * AgentCore Voice Client — connects to BidiAgent via SigV4-signed WebSocket.
 * Handles mic capture (PCM 16kHz), audio playback, and the BidiAgent protocol.
 * 
 * Dependencies (loaded via CDN in the HTML):
 *   - @aws-crypto/sha256-browser
 *   - @smithy/signature-v4
 *   - @smithy/protocol-http
 */

class VoiceClient {
    constructor(config) {
        this.tokenUrl = config.tokenUrl;
        this.socket = null;
        this.audioContext = null;
        this.mediaStream = null;
        this.scriptProcessor = null;
        this.playbackQueue = [];
        this.isPlaying = false;
        this.isConnected = false;
        this.onTranscript = config.onTranscript || (() => {});
        this.onStatus = config.onStatus || (() => {});
        this.onError = config.onError || (() => {});
    }

    // ========================================
    // CONNECTION
    // ========================================

    async connect() {
        this.onStatus('Getting voice token...');

        try {
            // Get presigned WebSocket URL from server
            const resp = await authFetch(this.tokenUrl);
            if (!resp.ok) throw new Error('Failed to get voice token: ' + resp.status);
            const data = await resp.json();
            const wsUrl = data.wsUrl;
            if (!wsUrl) throw new Error('No wsUrl in response');

            console.log('[Voice] Got presigned WebSocket URL');
            this.socket = new WebSocket(wsUrl);

            this.socket.onopen = async () => {
                console.log('[Voice] WebSocket connected');
                this.isConnected = true;
                this.onStatus('Connected — starting audio...');
                await this._startAudioCapture();
                this.onStatus('🎤 Listening — speak now');
            };

            this.socket.onmessage = (event) => {
                try {
                    const data = JSON.parse(event.data);
                    this._handleMessage(data);
                } catch (e) {
                    console.error('[Voice] Parse error:', e);
                }
            };

            this.socket.onerror = (err) => {
                console.error('[Voice] WebSocket error:', err);
                console.error('[Voice] WebSocket readyState:', this.socket.readyState);
                this.onError('Connection error — check console for details');
            };

            this.socket.onclose = (event) => {
                console.log('[Voice] WebSocket closed:', event.code, event.reason);
                console.log('[Voice] Close wasClean:', event.wasClean);
                this.isConnected = false;
                this._stopAudioCapture();
                this.onStatus('Disconnected');
            };
        } catch (e) {
            console.error('[Voice] Connect failed:', e);
            this.onError('Failed to connect: ' + e.message);
        }
    }

    disconnect() {
        this.isConnected = false;
        this._stopAudioCapture();
        this._clearPlayback();
        if (this.socket) {
            try { this.socket.close(1000, 'User ended'); } catch(e) {}
            this.socket = null;
        }
        this.onStatus('Disconnected');
    }


    // ========================================
    // BIDI PROTOCOL MESSAGE HANDLING
    // ========================================

    _handleMessage(data) {
        const type = data.type;
        if (!type) return;

        switch (type) {
            case 'bidi_audio_output':
            case 'bidi_audio_stream':
                if (data.audio) {
                    this._enqueueAudio(data.audio);
                }
                break;

            case 'bidi_text_output':
            case 'bidi_transcript_stream':
                if (data.text) {
                    const role = (data.role || '').toUpperCase() === 'USER' ? 'user' : 'assistant';
                    // For streaming transcripts, only show final
                    if (type === 'bidi_transcript_stream' && !data.is_final) break;
                    this.onTranscript(role, data.text);
                    // Barge-in: user speaking clears audio buffer
                    if (role === 'user') this._clearPlayback();
                }
                break;

            case 'bidi_response_start':
                this.onStatus('🔊 Agent speaking...');
                break;

            case 'bidi_response_end':
            case 'bidi_turn_end':
                this.onStatus('🎤 Listening — speak now');
                break;

            case 'bidi_tool_call':
                this.onStatus(`🔧 Using tool: ${data.tool_name}`);
                break;

            case 'error':
                console.error('[Voice] Agent error:', data.message);
                this.onError(data.message || 'Agent error');
                break;
        }
    }

    _sendEvent(event) {
        if (this.socket && this.socket.readyState === WebSocket.OPEN) {
            this.socket.send(JSON.stringify(event));
        }
    }


    // ========================================
    // AUDIO CAPTURE (Mic → PCM 16kHz → WebSocket)
    // ========================================

    async _startAudioCapture() {
        try {
            this.audioContext = new (window.AudioContext || window.webkitAudioContext)({ sampleRate: 16000 });
            this.mediaStream = await navigator.mediaDevices.getUserMedia({ audio: { sampleRate: 16000, channelCount: 1, echoCancellation: true, noiseSuppression: true } });

            const source = this.audioContext.createMediaStreamSource(this.mediaStream);
            // ScriptProcessorNode for PCM capture (deprecated but widely supported)
            this.scriptProcessor = this.audioContext.createScriptProcessor(4096, 1, 1);

            this.scriptProcessor.onaudioprocess = (e) => {
                if (!this.isConnected) return;
                const float32 = e.inputBuffer.getChannelData(0);
                // Convert Float32 → Int16 PCM
                const int16 = new Int16Array(float32.length);
                for (let i = 0; i < float32.length; i++) {
                    int16[i] = Math.max(-32768, Math.min(32767, Math.round(float32[i] * 32768)));
                }
                // Convert to base64
                const bytes = new Uint8Array(int16.buffer);
                let binary = '';
                for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]);
                const base64 = btoa(binary);

                this._sendEvent({
                    type: 'bidi_audio_input',
                    audio: base64,
                    format: 'pcm',
                    sample_rate: 16000,
                    channels: 1
                });
            };

            source.connect(this.scriptProcessor);
            this.scriptProcessor.connect(this.audioContext.destination);
            console.log('[Voice] Audio capture started');
        } catch (e) {
            console.error('[Voice] Mic access failed:', e);
            this.onError('Microphone access denied. Please allow mic access and try again.');
        }
    }

    _stopAudioCapture() {
        if (this.scriptProcessor) {
            this.scriptProcessor.disconnect();
            this.scriptProcessor = null;
        }
        if (this.mediaStream) {
            this.mediaStream.getTracks().forEach(t => t.stop());
            this.mediaStream = null;
        }
        if (this.audioContext) {
            this.audioContext.close().catch(() => {});
            this.audioContext = null;
        }
    }

    // ========================================
    // AUDIO PLAYBACK (WebSocket → PCM → Speaker)
    // ========================================

    _enqueueAudio(base64Data) {
        // Decode base64 → Int16 PCM → Float32
        const binary = atob(base64Data);
        const bytes = new Uint8Array(binary.length);
        for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
        const int16 = new Int16Array(bytes.buffer);
        const float32 = new Float32Array(int16.length);
        for (let i = 0; i < int16.length; i++) float32[i] = int16[i] / 32768.0;

        this.playbackQueue.push(float32);
        if (!this.isPlaying) this._playNext();
    }

    _playNext() {
        if (this.playbackQueue.length === 0) {
            this.isPlaying = false;
            return;
        }
        this.isPlaying = true;
        const samples = this.playbackQueue.shift();

        // Use a separate AudioContext for playback at 16kHz
        const ctx = new (window.AudioContext || window.webkitAudioContext)({ sampleRate: 16000 });
        const buffer = ctx.createBuffer(1, samples.length, 16000);
        buffer.getChannelData(0).set(samples);
        const source = ctx.createBufferSource();
        source.buffer = buffer;
        source.connect(ctx.destination);
        source.onended = () => {
            ctx.close().catch(() => {});
            this._playNext();
        };
        source.start();
    }

    _clearPlayback() {
        this.playbackQueue = [];
        this.isPlaying = false;
    }
}

// Export globally
window.VoiceClient = VoiceClient;
