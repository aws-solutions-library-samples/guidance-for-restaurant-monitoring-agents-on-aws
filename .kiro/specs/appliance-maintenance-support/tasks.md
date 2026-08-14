# Tasks: Appliance Maintenance Support

## Task 1: Infrastructure — New DynamoDB Tables and GSIs

- [ ] 1.1 Add Maintenance History DynamoDB table to CloudFormation template
  - Table: `restaurant-kitchen-assistant-maintenance-history-prod`
  - PK: `equipment_id` (S), SK: `maintenance_date` (S)
  - GSI `restaurant-index`: PK `restaurant_id`, SK `maintenance_date`
  - KMS encryption, PITR enabled, PAY_PER_REQUEST billing
  - Add to `deployment/restaurant-monitoring-base-template.yaml`
- [ ] 1.2 Add Maintenance Schedule DynamoDB table to CloudFormation template
  - Table: `restaurant-kitchen-assistant-maintenance-schedule-prod`
  - PK: `equipment_id` (S), SK: `maintenance_type` (S)
  - GSI `restaurant-schedule-index`: PK `restaurant_id`, SK `next_due_date`
  - GSI `due-date-index`: PK `status`, SK `next_due_date`
  - KMS encryption, PITR enabled, PAY_PER_REQUEST billing
- [ ] 1.3 Add GSI `equipment-index` to existing Tickets table
  - PK: `equipment_id`, SK: `created_at`
  - Add `equipment_id` and `created_at` to AttributeDefinitions
- [ ] 1.4 Update API Lambda IAM role to include read/write access to new tables
  - Add maintenance-history and maintenance-schedule table ARNs + GSI ARNs to DynamoDB policy
- [ ] 1.5 Add new API Gateway endpoints for maintenance-history and maintenance-schedule
  - GET `/maintenance-history` with Cognito authorizer
  - GET `/maintenance-schedule` with Cognito authorizer
  - OPTIONS methods for CORS
- [ ] 1.6 Update API Lambda handler to serve new endpoints
  - `/maintenance-history`: query by `equipment_id` or `restaurant_id` (via GSI)
  - `/maintenance-schedule`: query by `restaurant_id` (via GSI)

## Task 2: Agent Tools — Maintenance History

- [ ] 2.1 Add `get_maintenance_history` tool to `agent.py`
  - Parameters: `equipment_id` (required), `restaurant_id` (optional)
  - Query maintenance-history table by equipment_id, or GSI by restaurant_id
  - Return formatted history with date, type, technician, description, resolution, cost
  - Handle empty history with suggestion to establish baseline
- [ ] 2.2 Add `record_maintenance` tool to `agent.py`
  - Parameters: `equipment_id`, `restaurant_id`, `maintenance_type`, `description`, `technician`, `resolution`, `parts_cost`, `labor_cost`, `ticket_id` (optional)
  - Calculate `total_cost` = `parts_cost` + `labor_cost`
  - Write to maintenance-history table with ISO 8601 timestamp
  - Return confirmation with recorded details

## Task 3: Agent Tools — Maintenance Scheduling

- [ ] 3.1 Add `get_maintenance_schedule` tool to `agent.py`
  - Parameters: `restaurant_id` (optional), `equipment_id` (optional)
  - Query schedule table; compute status (scheduled/due_soon/overdue) based on next_due_date
  - Flag items due within 7 days as "due_soon", past due as "overdue"
  - Return formatted schedule sorted by next_due_date
- [ ] 3.2 Add `update_maintenance_schedule` tool to `agent.py`
  - Parameters: `equipment_id`, `maintenance_type`, `completed_date` (optional, defaults to now)
  - Update `last_completed`, calculate `next_due_date` = completed_date + frequency_days
  - Set status to "scheduled"
  - Return confirmation with next due date

## Task 4: Agent Tools — Equipment Lifecycle

- [ ] 4.1 Add `get_equipment_lifecycle` tool to `agent.py`
  - Parameters: `equipment_id`, `restaurant_id` (optional)
  - Read equipment record from equipment-readings table
  - Calculate years_in_service from installation_date
  - Calculate remaining_lifespan from expected_lifespan_years
  - Check warranty_expiration against current date (flag if within 30 days)
  - Recommend replacement if years_in_service > expected_lifespan_years
  - Return formatted lifecycle summary

## Task 5: Agent Tools — Correlation and Cost Analysis

- [ ] 5.1 Add `analyze_equipment_correlation` tool to `agent.py`
  - Parameters: `restaurant_id`, `time_window_hours` (optional, default 24)
  - Query recent tickets for the restaurant within time window
  - If 2+ equipment failures found, flag as potentially correlated
  - Include equipment locations and types in analysis
  - Return correlation analysis or "no correlation found"
- [ ] 5.2 Add `get_maintenance_costs` tool to `agent.py`
  - Parameters: `equipment_id` (optional), `restaurant_id` (optional), `start_date` (optional), `end_date` (optional)
  - Query maintenance-history table for matching records
  - Aggregate total_cost, break down by maintenance_type
  - Compare against replacement cost threshold if equipment_id provided
  - Return formatted cost summary with trends

## Task 6: Agent Tools — Enhanced Ticket Management

- [ ] 6.1 Enhance `create_ticket` tool with maintenance fields
  - Add optional parameters: `maintenance_type`, `estimated_cost`, `technician`
  - Add duplicate detection: query equipment-index GSI for open tickets on same equipment
  - Add auto-escalation: set `escalated=true` for critical priority tickets
  - Maintain backward compatibility with existing callers
- [ ] 6.2 Add `update_ticket` tool to `agent.py`
  - Parameters: `ticket_id`, `status` (optional), `notes` (optional), `technician` (optional), `resolution_notes` (optional)
  - Update ticket in DynamoDB with provided fields
  - Set `resolved_at` timestamp when status changes to "resolved" or "closed"
  - Return updated ticket details

## Task 7: System Prompt Update

- [ ] 7.1 Update SYSTEM_PROMPT in `agent.py` with new capabilities
  - Add MAINTENANCE section describing maintenance history, scheduling, lifecycle tools
  - Add TROUBLESHOOTING section describing KB-based troubleshooting flow
  - Add COST TRACKING section describing cost analysis capabilities
  - Update TOOLS list with all new tool names
  - Add guidance for when to use each new tool
- [ ] 7.2 Update ALL_TOOLS list to include all new tools
  - Add get_maintenance_history, record_maintenance, get_maintenance_schedule
  - Add update_maintenance_schedule, get_equipment_lifecycle
  - Add analyze_equipment_correlation, get_maintenance_costs, update_ticket

## Task 8: Frontend — Enhanced Tickets Page

- [ ] 8.1 Add maintenance history panel to `frontend/tickets.html`
  - Add "Maintenance History" section in the right sidebar
  - Show recent maintenance activities with date, type, and cost
  - Add click-to-expand for full maintenance details
- [ ] 8.2 Add upcoming maintenance schedule widget to `frontend/tickets.html`
  - Add "Upcoming Maintenance" section showing due-soon and overdue items
  - Color-code: red for overdue, orange for due within 7 days, green for scheduled
  - Include equipment name, maintenance type, and due date
- [ ] 8.3 Add maintenance-type filter to ticket filter bar
  - Add filter buttons for maintenance types: preventive, corrective, emergency, inspection
  - Integrate with existing filterTickets() function
- [ ] 8.4 Extend `frontend/api.js` with new API methods
  - Add `getMaintenanceHistory(equipmentId)` method
  - Add `getMaintenanceSchedule(restaurantId)` method
  - Follow existing `makeRequest` pattern with auth headers

## Task 9: Data Seeding

- [ ] 9.1 Create seed data script for maintenance history
  - Generate realistic maintenance history for all equipment types across restaurants
  - Include mix of preventive, corrective, and emergency maintenance
  - Include realistic cost data (parts + labor)
  - Save as `deployment/load-maintenance-data.sh`
- [ ] 9.2 Create seed data for maintenance schedules
  - Generate preventive maintenance schedules for all equipment
  - Include some overdue items and some due-soon items for demo purposes
  - Set realistic frequencies (e.g., monthly filter changes, quarterly deep cleans)
- [ ] 9.3 Add lifecycle fields to existing equipment seed data
  - Add installation_date, warranty_expiration, expected_lifespan_years, model_number
  - Update `deployment/load-data.sh` or create supplemental script

## Task 10: Property-Based Tests

- [ ] 10.1 Set up Hypothesis test infrastructure
  - Add `hypothesis` to test dependencies
  - Create test file `tests/test_maintenance_properties.py`
  - Create generators for equipment, tickets, maintenance records, schedules
- [ ] 10.2 Implement property tests for ticket management (Properties 3, 4, 5, 6)
  - Property 3: Ticket creation persists all required fields
  - Property 4: Duplicate ticket detection for same equipment
  - Property 5: Ticket update round-trip
  - Property 6: Critical issue auto-escalation
- [ ] 10.3 Implement property tests for maintenance history (Properties 7, 13, 14)
  - Property 7: Maintenance history retrieval correctness and completeness
  - Property 13: Maintenance cost recording round-trip
  - Property 14: Cost aggregation correctness
- [ ] 10.4 Implement property tests for scheduling (Properties 8, 9)
  - Property 8: Schedule status reflects due date correctly
  - Property 9: Schedule completion advances next due date
- [ ] 10.5 Implement property tests for lifecycle and correlation (Properties 11, 12, 15, 16)
  - Property 11: Warranty and lifespan threshold detection
  - Property 12: Multi-equipment failure correlation detection
  - Property 15: Cost-based replacement recommendation
  - Property 16: Temperature anomaly auto-ticket creation
- [ ] 10.6 Implement property tests for data retrieval and formatting (Properties 1, 2, 10)
  - Property 1: Equipment retrieval returns correct restaurant-scoped results
  - Property 2: Equipment lifecycle data completeness
  - Property 10: Troubleshooting steps are sequentially formatted
