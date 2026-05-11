#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# Prevent errors in a pipeline from being masked.
set -o pipefail

# --- Configuration ---
DATABASE_URL="https://database.lichess.org/standard/list.txt"
RESULTS_DIR="partialResults"

# --- Sanity Checks ---
if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed or not in PATH."
    exit 1
fi
if ! command -v zstdcat &> /dev/null; then
    echo "Error: zstdcat is not installed or not in PATH."
    exit 1
fi

if ! command -v zig &> /dev/null; then
    echo "Error: zig is not installed or not in PATH."
    exit 1
fi

# --- Main Logic ---

# Create the results directory if it doesn't exist
mkdir -p "$RESULTS_DIR"

echo "Fetching updates..."
# Fetch the list of URLs. Use process substitution to feed it to the loop.
# `IFS= read -r url` is robust for reading lines.
# [[-n "$url"]] handles last line if no newline
curl -s "$DATABASE_URL" | while IFS= read -r url || [[ -n "$url" ]]; do 
    # 1. Derive filenames

    # Get the filename part from the URL (e.g., lichess_db_standard_rated_2025-04.pgn.zst)
    filename_pgn_zst="${url##*/}"

    # Get the base filename by removing .pgn.zst (e.g., lichess_db_standard_rated_2025-04)
    base_filename="${filename_pgn_zst%%.pgn.zst}"

    # Construct the expected result JSON filename
    result_json_file="$RESULTS_DIR/${base_filename}.result.json"

    # 2. Check if the file has been processed
    # -f: file exists and is a regular file
    # -s: file exists and has a size greater than zero
    if [ -f "$result_json_file" ] && [ -s "$result_json_file" ]; then
        # We hit a file that has already been process, so we can assume that the update has been complete
        exit
    fi

    # 3. If not processed (or empty), execute the command
    echo "Processing $filename_pgn_zst"
    curl -s "$url" | zstdcat | zig build run -Doptimize=ReleaseFast -- collect > "$result_json_file"

done

# Rebuild the results, doesn't work on github
# zig build run -Doptimize=ReleaseFast -- analyze $RESULTS_DIR

# Cleanup
rm .zig-cache -r
