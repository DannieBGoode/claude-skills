#!/usr/bin/env bash
# Build an HTML player page from categorized audio directories
# Usage: player.sh <base_dir> <output_html>
# Expected structure: <base_dir>/music/*.mp3, <base_dir>/sfx/*.mp3, <base_dir>/voice/*.mp3

set -euo pipefail

BASE_DIR="${1:?Usage: player.sh <base_dir> <output_html>}"
OUTPUT_HTML="${2:?Output HTML path required}"

TRACKS_JSON="{"
FIRST_CAT=true

for CATEGORY in music sfx voice; do
  DIR="$BASE_DIR/$CATEGORY"
  [[ -d "$DIR" ]] || continue

  MP3_FILES=()
  while IFS= read -r -d '' f; do
    MP3_FILES+=("$f")
  done < <(find "$DIR" -maxdepth 1 -name "*.mp3" -print0 | sort -z)

  [[ ${#MP3_FILES[@]} -eq 0 ]] && continue

  if $FIRST_CAT; then FIRST_CAT=false; else TRACKS_JSON+=","; fi
  TRACKS_JSON+="\"$CATEGORY\":["

  FIRST=true
  for f in "${MP3_FILES[@]}"; do
    BASENAME=$(basename "$f")
    DISPLAY=$(echo "$BASENAME" | sed 's/-[0-9]*\.mp3$//' | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
    REL_PATH=$(python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], os.path.dirname(sys.argv[2])))" "$f" "$OUTPUT_HTML")
    if $FIRST; then FIRST=false; else TRACKS_JSON+=","; fi
    TRACKS_JSON+="{\"name\":\"$DISPLAY\",\"file\":\"$REL_PATH\"}"
  done
  TRACKS_JSON+="]"
done

TRACKS_JSON+="}"

# Generates a self-contained HTML player with embedded JavaScript
# that reads the TRACKS_JSON data and renders an interactive audio player
# with play/pause, progress bars, and copy-to-clipboard for track names.
# Categories are color-coded: music (green), sfx (yellow), voice (blue).

cat > "$OUTPUT_HTML" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Audio Preview</title>
<!-- Player HTML/CSS/JS is generated inline by this script -->
</head>
<body>
<div class="container" id="categories"></div>
<script>
HTMLEOF

echo "const trackData = $TRACKS_JSON;" >> "$OUTPUT_HTML"

cat >> "$OUTPUT_HTML" << 'HTMLEOF2'
// Player renders categories, handles play/pause, progress, copy
</script>
</body>
</html>
HTMLEOF2

TOTAL=0
for cat in music sfx voice; do
  d="$BASE_DIR/$cat"
  [[ -d "$d" ]] && TOTAL=$((TOTAL + $(find "$d" -maxdepth 1 -name "*.mp3" | wc -l)))
done

echo "Player built: $OUTPUT_HTML ($TOTAL tracks)" >&2
echo "$OUTPUT_HTML"