#!/bin/bash
# ============================================================
# fix_shebangs.sh - Safely repair Python script shebangs
# Run this from your advanced-linux-toolkit directory
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

VENV_PYTHON="$HOME/.linux-toolkit-venv/bin/python3"
INSTALL_DIR="$HOME/.local/bin"
SRC_DIR="src/python"

echo -e "${YELLOW}Repairing Python script shebangs...${NC}"
echo "Using Python: $VENV_PYTHON"
echo ""

# Verify the venv Python exists
if [ ! -f "$VENV_PYTHON" ]; then
    echo -e "${RED}ERROR: Virtual environment Python not found at $VENV_PYTHON${NC}"
    echo "Run ./scripts/auto_setup.sh first."
    exit 1
fi

fix_shebang() {
    local file="$1"
    local filename
    filename=$(basename "$file")

    if [ ! -f "$file" ]; then
        echo -e "  ${RED}✗ Not found: $filename${NC}"
        return 1
    fi

    # Check if the first line is already correct
    local first_line
    first_line=$(head -1 "$file")
    local correct_shebang="#!$VENV_PYTHON"

    if [ "$first_line" = "$correct_shebang" ]; then
        echo -e "  ${YELLOW}○ Already correct: $filename${NC}"
        return 0
    fi

    # Check if the file starts with a shebang (any shebang)
    if [[ "$first_line" == \#!* ]]; then
        # Replace only the first line safely using Python itself
        python3 - "$file" "$correct_shebang" << 'PYEOF'
import sys
filepath = sys.argv[1]
new_shebang = sys.argv[2]
with open(filepath, 'r') as f:
    lines = f.readlines()
lines[0] = new_shebang + '\n'
with open(filepath, 'w') as f:
    f.writelines(lines)
PYEOF
    else
        # No shebang exists — prepend one
        python3 - "$file" "$correct_shebang" << 'PYEOF'
import sys
filepath = sys.argv[1]
new_shebang = sys.argv[2]
with open(filepath, 'r') as f:
    content = f.read()
with open(filepath, 'w') as f:
    f.write(new_shebang + '\n' + content)
PYEOF
    fi

    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✓ Fixed: $filename${NC}"
        chmod +x "$file"
        return 0
    else
        echo -e "  ${RED}✗ Failed to fix: $filename${NC}"
        return 1
    fi
}

PYTHON_SCRIPTS=(
    system_info.py
    file_organizer.py
    network_monitor.py
    disk_usage_analyzer.py
    log_visualizer.py
)

echo "=== Fixing source files in $SRC_DIR ==="
for script in "${PYTHON_SCRIPTS[@]}"; do
    fix_shebang "$SRC_DIR/$script"
done

echo ""
echo "=== Reinstalling to $INSTALL_DIR ==="
for script in "${PYTHON_SCRIPTS[@]}"; do
    if [ -f "$SRC_DIR/$script" ]; then
        cp "$SRC_DIR/$script" "$INSTALL_DIR/$script"
        chmod +x "$INSTALL_DIR/$script"
        echo -e "  ${GREEN}✓ Installed: $script${NC}"
    fi
done

echo ""
echo "=== Verifying ==="
for script in "${PYTHON_SCRIPTS[@]}"; do
    installed="$INSTALL_DIR/$script"
    if [ -f "$installed" ]; then
        shebang=$(head -1 "$installed")
        if [ "$shebang" = "#!$VENV_PYTHON" ]; then
            echo -e "  ${GREEN}✓ $script — shebang OK${NC}"
        else
            echo -e "  ${RED}✗ $script — bad shebang: $shebang${NC}"
        fi
    fi
done

echo ""
echo "=== Quick test ==="
echo -n "  system_info.py -c ... "
if "$INSTALL_DIR/system_info.py" -c > /dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL — check venv activation${NC}"
fi

echo ""
echo -e "${GREEN}Done. If tests pass, your scripts are working correctly.${NC}"
echo -e "${YELLOW}Tip: Never use sed to rewrite shebangs. Use this script instead.${NC}"

