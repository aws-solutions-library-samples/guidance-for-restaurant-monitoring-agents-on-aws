/**
 * Restaurant Agent API Client
 * Agent-first architecture - all queries go through /chat endpoint
 */

class AgentAPI {
    constructor() {
        const base = (window.APP_CONFIG && window.APP_CONFIG.apiUrl) || '';
        this.chatUrl = base + '/chat';
        this.sessionId = `session-${Date.now()}`;
    }

    async query(prompt) {
        try {
            console.log(`🤖 Agent Query: ${prompt}`);
            
            const headers = {'Content-Type': 'application/json'};
            try {
                if (typeof auth !== 'undefined' && auth.currentUser) {
                    const info = await auth.getUserInfo();
                    if (info.token) headers['Authorization'] = info.token;
                }
            } catch (e) { /* proceed without token */ }

            const response = await fetch(this.chatUrl, {
                method: 'POST',
                headers: headers,
                body: JSON.stringify({prompt, sessionId: this.sessionId})
            });

            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            
            const data = await response.json();
            const result = data.result || data.response || '';
            
            console.log(`✅ Agent Response: ${result.substring(0, 100)}...`);
            return result;
        } catch (error) {
            console.error('❌ Agent Error:', error);
            throw error;
        }
    }

    async getRestaurants() {
        const result = await this.query('Get all restaurants. Return as JSON array with id, name, location, manager, status, equipment_count fields.');
        return this.parseJSON(result) || [];
    }

    async getEquipment(restaurantId = null) {
        const prompt = restaurantId 
            ? `Get equipment for restaurant ${restaurantId}. Return as JSON array.`
            : 'Get all equipment readings. Return as JSON array with restaurant_id, equipment_id, appliance_name, temperature, target_temperature, status fields.';
        const result = await this.query(prompt);
        return this.parseJSON(result) || [];
    }

    async getTickets(status = null) {
        const prompt = status 
            ? `Get ${status} tickets. Return as JSON array.`
            : 'Get all maintenance tickets. Return as JSON array with ticket_id, restaurant_id, equipment_id, issue, priority, status, created_at fields.';
        const result = await this.query(prompt);
        return this.parseJSON(result) || [];
    }

    async getInventory(restaurantId = null) {
        const prompt = restaurantId
            ? `Get inventory for restaurant ${restaurantId}. Return as JSON array.`
            : 'Get inventory status. Return as JSON array with restaurant_id, item_id, item_name, category, quantity, unit_of_measure, status fields.';
        const result = await this.query(prompt);
        return this.parseJSON(result) || [];
    }

    async getStaffing(restaurantId = null) {
        const prompt = restaurantId
            ? `Get staffing for restaurant ${restaurantId}. Return as JSON array.`
            : 'Get staffing status. Return as JSON array with restaurant_id, role, shift, required_count, scheduled_count fields.';
        const result = await this.query(prompt);
        return this.parseJSON(result) || [];
    }

    parseJSON(text) {
        try {
            // Try to extract JSON from markdown code blocks
            const jsonMatch = text.match(/```json\n([\s\S]*?)\n```/) || text.match(/```\n([\s\S]*?)\n```/);
            if (jsonMatch) {
                return JSON.parse(jsonMatch[1]);
            }
            
            // Try to parse directly
            return JSON.parse(text);
        } catch (e) {
            console.warn('Could not parse JSON from agent response:', e);
            return null;
        }
    }
}

// Create global instance
window.agentAPI = new AgentAPI();
console.log('✅ Agent API initialized');
