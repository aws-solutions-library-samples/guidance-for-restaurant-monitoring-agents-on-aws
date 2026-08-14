class ApiGatewayClient {
    constructor() {
        this.apiUrl = (window.APP_CONFIG && window.APP_CONFIG.apiUrl) || '';
    }

    async getAuthToken() {
        try {
            if (typeof authReady !== 'undefined') await authReady;
            if (typeof auth !== 'undefined' && auth && auth.currentUser) {
                const info = await auth.getUserInfo();
                return info.token;
            }
        } catch (e) {
            console.warn('Could not get auth token:', e);
        }
        return null;
    }
    
    async makeRequest(endpoint) {
        try {
            const token = await this.getAuthToken();
            const headers = {
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            };
            if (token) {
                headers['Authorization'] = token;
            }
            
            const response = await fetch(`${this.apiUrl}${endpoint}`, {
                method: 'GET',
                headers: headers
            });
            
            if (!response.ok) {
                throw new Error(`API error: ${response.status}`);
            }
            
            return await response.json();
        } catch (error) {
            console.error('API Error for %s:', endpoint, error);
            throw error;
        }
    }
    
    async getRestaurants() {
        const data = await this.makeRequest('/restaurants');
        const restaurants = data.restaurants || data.Items || data;
        return Array.isArray(restaurants) ? restaurants : [];
    }
    
    async getTickets() {
        const data = await this.makeRequest('/tickets');
        const tickets = data.tickets || data.Items || data;
        return Array.isArray(tickets) ? tickets : [];
    }

    async getEquipment() {
        const data = await this.makeRequest('/equipment');
        const equipment = data.equipment || data.Items || data;
        if (!Array.isArray(equipment)) return [];
        return equipment.map(e => ({
            equipment_id: e.equipment_id,
            restaurant_id: e.restaurant_id,
            appliance_name: e.appliance_name,
            appliance_type: e.appliance_type,
            status: e.status || 'normal',
            temperature: e.temperature,
            target_temperature: e.target_temperature
        }));
    }

    async getInventory() {
        const data = await this.makeRequest('/inventory');
        const inventory = data.inventory || data.Items || data;
        return Array.isArray(inventory) ? inventory : [];
    }

    async getStaffing() {
        const data = await this.makeRequest('/staffing');
        const staffing = data.staffing || data.Items || data;
        return Array.isArray(staffing) ? staffing : [];
    }
}

const apiClient = new ApiGatewayClient();
