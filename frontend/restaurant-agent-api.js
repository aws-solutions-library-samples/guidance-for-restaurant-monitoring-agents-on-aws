/**
 * Restaurant Agent API Client
 * Uses /chat-stream endpoint for streaming responses via AI agent
 */

class RestaurantAgentAPI {
    constructor() {
        this.chatUrl = 'https://kipgsctrp4.execute-api.us-east-1.amazonaws.com/prod/chat';
        this.streamUrl = 'https://kipgsctrp4.execute-api.us-east-1.amazonaws.com/prod/chat-stream';
        this.sessionId = `session-${Date.now()}`;
    }

    async _getAuthHeaders() {
        const headers = { 'Content-Type': 'application/json' };
        try {
            if (typeof auth !== 'undefined' && auth.currentUser) {
                const info = await auth.getUserInfo();
                if (info.token) headers['Authorization'] = info.token;
            }
        } catch (e) { /* proceed without token */ }
        return headers;
    }

    // Streaming query with callback for real-time updates
    async queryStream(prompt, onChunk, onComplete) {
        try {
            const headers = await this._getAuthHeaders();
            const response = await fetch(this.streamUrl, {
                method: 'POST',
                headers: headers,
                body: JSON.stringify({
                    prompt: prompt,
                    sessionId: this.sessionId
                })
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}`);
            }

            const reader = response.body.getReader();
            const decoder = new TextDecoder();
            let fullText = '';

            while (true) {
                const { done, value } = await reader.read();
                if (done) break;

                const chunk = decoder.decode(value, { stream: true });
                const lines = chunk.split('\n');

                for (const line of lines) {
                    if (line.startsWith('data: ')) {
                        try {
                            const data = JSON.parse(line.slice(6));
                            if (data.text) {
                                fullText += data.text;
                                if (onChunk) onChunk(data.text, fullText);
                            }
                            if (data.done && onComplete) {
                                onComplete(fullText, data.sessionId);
                            }
                            if (data.error) {
                                throw new Error(data.error);
                            }
                        } catch (e) {
                            // Skip invalid JSON
                        }
                    }
                }
            }

            return fullText;
        } catch (error) {
            console.error('Stream Error:', error);
            throw error;
        }
    }

    // Non-streaming query (fallback)
    async query(prompt) {
        try {
            const headers = await this._getAuthHeaders();
            const response = await fetch(this.chatUrl, {
                method: 'POST',
                headers: headers,
                body: JSON.stringify({
                    prompt: prompt,
                    sessionId: this.sessionId
                })
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}`);
            }

            const data = await response.json();
            return data.result || data.response || '';
        } catch (error) {
            console.error('API Error:', error);
            throw error;
        }
    }

    // Convenience methods
    async getRestaurants() {
        const result = await this.query('List all restaurants with their details');
        return this.parseRestaurants(result);
    }

    async getEquipment(restaurantId = null) {
        const prompt = restaurantId 
            ? `Show equipment readings for restaurant ${restaurantId}`
            : 'Show all equipment readings';
        const result = await this.query(prompt);
        return this.parseEquipment(result);
    }

    async getTickets(status = null) {
        const prompt = status 
            ? `Show ${status} maintenance tickets`
            : 'Show all maintenance tickets';
        const result = await this.query(prompt);
        return this.parseTickets(result);
    }

    async getInventory(restaurantId = null) {
        const prompt = restaurantId
            ? `Show inventory for restaurant ${restaurantId}`
            : 'Show inventory status for all restaurants';
        const result = await this.query(prompt);
        return this.parseInventory(result);
    }

    async getStaffing(restaurantId = null) {
        const prompt = restaurantId
            ? `Show staffing for restaurant ${restaurantId}`
            : 'Show staffing status for all restaurants';
        const result = await this.query(prompt);
        return this.parseStaffing(result);
    }

    // Parse AI responses into structured data
    parseRestaurants(text) {
        // Extract restaurant data from AI response
        return [];
    }

    parseEquipment(text) {
        return [];
    }

    parseTickets(text) {
        return [];
    }

    parseInventory(text) {
        return [];
    }

    parseStaffing(text) {
        return [];
    }
}

// Global instance
window.restaurantAgentAPI = new RestaurantAgentAPI();
