#!/bin/sh
set -e

# This script first processes all existing files in a directory and then
# watches for new files to process, moving them into a sorted structure.

# --- Configuration ---
# Use environment variables passed from docker-compose, with sensible defaults.
OUTPUT_DIR="${OUTPUT_DIR:-/output}"        # Base directory for the sorted photo library
INPUT_DIR="${INPUT_DIR:-/input}"            # Directory to watch for new files
FAILED_DIR="${FAILED_DIR:-$OUTPUT_DIR/failed_sort}" # Directory for files that could not be sorted
DUPLICATE_DIR="${DUPLICATE_DIR:-$OUTPUT_DIR/duplicates}" # Directory for duplicate files

# --- Logging ---
# A simple logging function that prefixes messages with a timestamp.
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# --- File Processing ---
process_file() {
    # Forcefully unset Perl environment variables at runtime. This is a critical
    # safeguard for environments like Unraid/Synology where host variables can
    # leak into the container and break exiftool's Perl dependencies.
    unset PERL5LIB
    unset PERL_MB_LIB

    local FILE="$1"
    if [ ! -f "$FILE" ]; then
        log "SKIP: File no longer exists: $FILE"
        return
    fi

    log "INFO: Processing file: $FILE"

    local FORMATTED_DATE=""
    local ALL_FORMATTED_DATES=$(exiftool -s3 -d "%Y-%m-%d_%H-%M-%S" -DateTimeOriginal -CreateDate -MediaCreateDate -TrackCreateDate -FileModifyDate "$FILE")

    FORMATTED_DATE=$(echo "$ALL_FORMATTED_DATES" | grep -v '^$' | head -n 1)

    if [ -z "$FORMATTED_DATE" ]; then
        log "ERROR: Could not determine a valid date for: $FILE."
        mkdir -p "$FAILED_DIR"
        mv "$FILE" "$FAILED_DIR/"
        log "INFO: Moved to $FAILED_DIR"
        return
    fi

    # Now get the year and month from the FORMATTED_DATE string
    local YEAR=$(echo "$FORMATTED_DATE" | cut -c 1-4)
    local MONTH=$(echo "$FORMATTED_DATE" | cut -c 6-7)
    local EXTENSION=$(exiftool -s3 -p '${FileTypeExtension}' "$FILE")

    DEST_PATH="$OUTPUT_DIR/$YEAR/$MONTH/${FORMATTED_DATE}.${EXTENSION}"

    # 3. Handle duplicates by checking if the destination file already exists.
    if [ -e "$DEST_PATH" ]; then
        log "WARN: Duplicate found. Destination '$DEST_PATH' already exists."
        mkdir -p "$DUPLICATE_DIR"
        # Append a timestamp to the duplicate filename to avoid overwrites
        mv "$FILE" "$DUPLICATE_DIR/$(basename "$FILE")_$(date +%s)"
        log "INFO: Moved to $DUPLICATE_DIR"
    else
        # 4. Move the file to its sorted destination.
        mkdir -p "$(dirname "$DEST_PATH")"
        
        # Temporarily disable exit-on-error to capture exiftool's exit code
        set +e
        ERROR_MSG=$(exiftool -P "-filename=$DEST_PATH" "$FILE" 2>&1)
        EXIT_CODE=$?
        set -e # Re-enable exit-on-error
        
        if [ $EXIT_CODE -eq 0 ]; then
            # exiftool prints '1 image files updated' on success, which we can ignore or log if needed.
            log "SUCCESS: Moved: $FILE to $DEST_PATH"
        else
            # Check if the error was because the file already exists.
            if echo "$ERROR_MSG" | grep -q "already exists"; then
                log "WARN: Duplicate found (detected by exiftool). Destination '$DEST_PATH' already exists."
                mkdir -p "$DUPLICATE_DIR"
                mv "$FILE" "$DUPLICATE_DIR/$(basename "$FILE")_$(date +%s)"
                log "INFO: Moved to $DUPLICATE_DIR"
            else
                # Handle other unexpected exiftool errors.
                log "ERROR: An unexpected exiftool error occurred while trying to move: $FILE"
                log "ERROR DETAILS: $ERROR_MSG"
                mkdir -p "$FAILED_DIR"
                mv "$FILE" "$FAILED_DIR/"
                log "INFO: Moved to $FAILED_DIR"
            fi
        fi
    fi
}

# --- Main Execution ---
log "Starting photo sorter..."

# Check for the Unraid/Perl environment variable issue and log a warning if found.
if [ -n "$PERL5LIB" ] || [ -n "$PERL_MB_LIB" ]; then
    log "WARN: Detected PERL5LIB or PERL_MB_LIB environment variables. The script will unset them before each operation, but this indicates a potential host environment leak."
fi

log "Output directory:      $OUTPUT_DIR"
log "Input (watch) directory: $INPUT_DIR"
log "Failed sort directory:   $FAILED_DIR"
log "Duplicates directory:    $DUPLICATE_DIR"

# Create necessary directories on startup
mkdir -p "$INPUT_DIR" "$OUTPUT_DIR" "$FAILED_DIR" "$DUPLICATE_DIR"

# --- 1. Process all existing files on startup ---
log "--- Processing existing files in $INPUT_DIR ---"
# Use find with -print0 and read with -d '' to safely handle all filenames.
find "$INPUT_DIR" -type f -not -path '*/.syncthing.*.tmp' -print0 | while IFS= read -r -d '' FILE; do
    process_file "$FILE"
done
log "--- Finished processing existing files ---"

# --- 2. Watch for new files ---
log "--- Watching for new file events in $INPUT_DIR ---"
inotifywait -m -r -e close_write -e moved_to --format '%w%f' --exclude '^\.syncthing\..*\.tmp$' "$INPUT_DIR" | while read -r FILE; do
    log "---------------------------------"
    log "INFO: File event detected: $FILE"
    sleep 1 # Brief pause to ensure file is fully written and stable
    process_file "$FILE"
done
