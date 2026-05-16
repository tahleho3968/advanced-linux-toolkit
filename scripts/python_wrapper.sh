#!/bin/bash
# ============================================================
# Python Wrapper - Run Python scripts with virtual environment
# ============================================================

# Activate virtual environment
if [ -f "$HOME/.linux-toolkit-activate" ]; then
    source "$HOME/.linux-toolkit-activate"
fi

# Get the Python script name
SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find the actual Python script
PYTHON_SCRIPT="$SCRIPT_DIR/../src/python/${SCRIPT_NAME%.sh}.py"

if [ -f "$PYTHON_SCRIPT" ]; then
    # Run with virtual environment Python
    exec python3 "$PYTHON_SCRIPT" "$@"
else
    echo "Error: Python script not found: $PYTHON_SCRIPT"
    exit 1
fi
