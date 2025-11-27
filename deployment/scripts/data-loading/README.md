# Data Loading Scripts

## Quick Start

```bash
# Load all normal baseline data
./load-all-normal-data.sh

# Create abnormal status for testing
python3 simple_simulator.py
```

## Script Overview

### Normal Data Loading (5 scripts)
Creates 100% operational baseline with no issues:

1. **`load-restaurant-data.sh`**
   - 10 restaurants, all operational
   - Status: 'operational', equipment_count: 7

2. **`load-equipment-data.sh`**
   - 70 equipment sensors (7 per restaurant)
   - All status: 'normal', temperature within ±2° of target

3. **`load-inventory-data.sh`**
   - 102 inventory items, normal stock levels (100-200% of reorder point)
   - 3000+ historical records (30 days default)
   - Includes inline Python for inventory generation

4. **`load-staffing-data.sh`**
   - 140 staffing requirements (14 days)
   - 1600+ scheduled shifts, normal coverage

5. **`load-all-normal-data.sh`**
   - Master script that runs all 4 in sequence

### Abnormal Status Creation (1 script)
Creates issues for monitoring and testing:

**`simple_simulator.py`**
- Hardcodes equipment failures (AFC-001/002/003)
- Creates inventory gaps inline (30% critical, 40% low)
- Creates staffing gaps inline (60% shift removal)
- Creates maintenance tickets
- All gap creation logic included in single file

**Targets**: AFC-001, AFC-002, AFC-003

## File Structure

```
data-loading/
├── README.md                      # This file
├── load-all-normal-data.sh        # Master script - loads all normal data
├── load-restaurant-data.sh        # 10 restaurants
├── load-equipment-data.sh         # 70 equipment sensors
├── load-inventory-data.sh         # 102 inventory items (inline Python)
├── load-staffing-data.sh          # 14 days staffing
└── simple_simulator.py            # Equipment failures + inventory gaps + staffing gaps
```

**Total: 7 files** (5 normal data + 1 abnormal + 1 doc)

## Usage Examples

### Fresh Deployment
```bash
# Step 1: Load normal baseline
./load-all-normal-data.sh

# Step 2: Create test issues
python3 simple_simulator.py
```

### Reset to Normal State
```bash
# Reload all normal data (overwrites existing)
./load-all-normal-data.sh
```

### Create Issues Only
```bash
# Run simulator (assumes normal data already loaded)
python3 simple_simulator.py
```

### Individual Data Loading
```bash
# Load specific data type
./load-restaurant-data.sh
./load-equipment-data.sh
./load-inventory-data.sh --days 60  # Custom historical days
./load-staffing-data.sh
```

## Data Summary

**After load-all-normal-data.sh**:
- 10 restaurants: ALL operational
- 70 equipment sensors: ALL normal
- 102 inventory items: NORMAL stock levels (100-200% of reorder point)
- 14 days staffing: NORMAL coverage

**After simple_simulator.py**:
- AFC-001/002/003: Equipment failures + inventory gaps + staffing gaps
- AFC-004 through AFC-010: Remain operational

## Design Principles

1. **Merged**: Helper scripts merged into parent scripts (inventory generation inline)
2. **Single File**: All gap creation logic in simple_simulator.py (no separate gap scripts)
3. **Minimal**: Only 7 files total (down from 13)
4. **Automated**: Simulator creates all gaps automatically
5. **Clean**: Normal data scripts never create issues

## Recent Changes

- Merged `generate-inventory-data.py` into `load-inventory-data.sh` as inline Python
- Merged `create-inventory-gaps.sh` into `simple_simulator.py`
- Merged `create-staffing-gaps.sh` into `simple_simulator.py`
- Removed `run-simulator-once.sh` wrapper
- Consolidated 3 documentation files into single README.md

**Result**: 13 files → 7 files (46% reduction)
