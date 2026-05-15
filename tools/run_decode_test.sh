#!/bin/bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS_DIR="$ROOT_DIR/tools"
SAMPLE="$TOOLS_DIR/sample_computer.json"
SCRIPT="$TOOLS_DIR/decode_computer_test.swift"
MODEL_SRC="$ROOT_DIR/Man1fest0/Model/ModelDecodingStructs/ComputerDetailedFull.swift"

if [ ! -f "$SAMPLE" ]; then
  echo "Sample JSON not found at $SAMPLE"
  exit 2
fi

if ! command -v swift >/dev/null 2>&1; then
  echo "swift command not found. Please install Swift or run the test from Xcode." >&2
  exit 3
fi

# Compile the test together with the project's model source so the Decodable types are available.
EXEC="$TOOLS_DIR/decode_computer_test_exec"
if [ -f "$MODEL_SRC" ]; then
  swiftc -o "$EXEC" "$SCRIPT" "$MODEL_SRC"
else
  echo "Model source not found at $MODEL_SRC, attempting to run script without compilation"
  EXEC="$(command -v swift) $SCRIPT"
fi

OUT="$TOOLS_DIR/decoded_test_output.txt"
"$EXEC" "$SAMPLE" | tee "$OUT"

echo "Output written to $OUT"
