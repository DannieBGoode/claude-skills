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

cat > "$OUTPUT_HTML" << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Audio Preview</title>
<style>
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: #0f0f13; color: #e0e0e0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; padding: 2rem; min-height: 100vh; }
  h1 { font-size: 1.5rem; font-weight: 600; color: #fff; margin-bottom: 2rem; letter-spacing: -0.02em; }
  .section { margin-bottom: 2.5rem; }
  .section-title { font-size: 0.75rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 1rem; opacity: 0.5; }
  .section-title.music { color: #4ade80; }
  .section-title.sfx   { color: #facc15; }
  .section-title.voice { color: #60a5fa; }
  .track { display: flex; align-items: center; gap: 0.75rem; padding: 0.75rem 1rem; background: #1a1a22; border-radius: 8px; margin-bottom: 0.5rem; cursor: pointer; transition: background 0.15s; border: 1px solid transparent; }
  .track:hover { background: #22222e; }
  .track.playing { border-color: currentColor; }
  .track.playing.music { color: #4ade80; }
  .track.playing.sfx   { color: #facc15; }
  .track.playing.voice { color: #60a5fa; }
  .play-btn { width: 32px; height: 32px; border-radius: 50%; border: none; cursor: pointer; flex-shrink: 0; display: flex; align-items: center; justify-content: center; background: #2a2a38; color: #e0e0e0; transition: background 0.15s; }
  .track.playing .play-btn { background: currentColor; }
  .track.playing .play-btn svg { color: #0f0f13; }
  .play-btn svg { width: 14px; height: 14px; fill: currentColor; }
  .track-info { flex: 1; min-width: 0; }
  .track-name { font-size: 0.875rem; font-weight: 500; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; color: inherit; }
  .track-time { font-size: 0.7rem; color: #666; margin-top: 2px; font-variant-numeric: tabular-nums; }
  .progress-wrap { flex: 1; height: 4px; background: #2a2a38; border-radius: 2px; cursor: pointer; position: relative; }
  .progress-bar { height: 100%; border-radius: 2px; background: #555; transition: background 0.15s; width: 0%; }
  .track.playing .progress-bar { background: currentColor; }
  .copy-btn { background: none; border: none; cursor: pointer; padding: 4px; color: #555; transition: color 0.15s; flex-shrink: 0; }
  .copy-btn:hover { color: #aaa; }
  .copy-btn svg { width: 14px; height: 14px; fill: currentColor; display: block; }
  .copy-btn.copied { color: #4ade80; }
</style>
</head>
<body>
<h1>Audio Preview</h1>
<div id="app"></div>
<script>
const TRACKS = $TRACKS_JSON;
const CATEGORY_LABELS = { music: 'Music', sfx: 'Sound Effects', voice: 'Voice' };
const app = document.getElementById('app');
let currentAudio = null;
let currentTrackEl = null;

function formatTime(s) {
  if (!isFinite(s)) return '0:00';
  const m = Math.floor(s / 60);
  const sec = Math.floor(s % 60);
  return m + ':' + String(sec).padStart(2, '0');
}

function stopCurrent() {
  if (currentAudio) { currentAudio.pause(); currentAudio.currentTime = 0; }
  if (currentTrackEl) {
    currentTrackEl.classList.remove('playing');
    currentTrackEl.querySelector('.progress-bar').style.width = '0%';
    currentTrackEl.querySelector('.play-btn').innerHTML = playIcon();
    currentTrackEl.querySelector('.track-time').textContent = '';
  }
  currentAudio = null;
  currentTrackEl = null;
}

function playIcon() { return '<svg viewBox="0 0 16 16"><path d="M3 2.5l10 5.5-10 5.5z"/></svg>'; }
function pauseIcon() { return '<svg viewBox="0 0 16 16"><rect x="3" y="2" width="4" height="12" rx="1"/><rect x="9" y="2" width="4" height="12" rx="1"/></svg>'; }
function copyIcon() { return '<svg viewBox="0 0 16 16"><rect x="5" y="5" width="9" height="9" rx="1.5" fill="none" stroke="currentColor" stroke-width="1.5"/><path d="M3 11H2a1 1 0 01-1-1V2a1 1 0 011-1h8a1 1 0 011 1v1" fill="none" stroke="currentColor" stroke-width="1.5"/></svg>'; }

Object.entries(TRACKS).forEach(([cat, tracks]) => {
  if (!tracks || tracks.length === 0) return;
  const section = document.createElement('div');
  section.className = 'section';
  const title = document.createElement('div');
  title.className = 'section-title ' + cat;
  title.textContent = CATEGORY_LABELS[cat] || cat;
  section.appendChild(title);

  tracks.forEach(track => {
    const el = document.createElement('div');
    el.className = 'track ' + cat;

    const btn = document.createElement('button');
    btn.className = 'play-btn';
    btn.innerHTML = playIcon();

    const info = document.createElement('div');
    info.className = 'track-info';
    const name = document.createElement('div');
    name.className = 'track-name';
    name.textContent = track.name;
    const time = document.createElement('div');
    time.className = 'track-time';
    info.appendChild(name);
    info.appendChild(time);

    const prog = document.createElement('div');
    prog.className = 'progress-wrap';
    const bar = document.createElement('div');
    bar.className = 'progress-bar';
    prog.appendChild(bar);

    const copyBtn = document.createElement('button');
    copyBtn.className = 'copy-btn';
    copyBtn.title = 'Copy name';
    copyBtn.innerHTML = copyIcon();
    copyBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      navigator.clipboard.writeText(track.name).then(() => {
        copyBtn.classList.add('copied');
        setTimeout(() => copyBtn.classList.remove('copied'), 1500);
      });
    });

    el.appendChild(btn);
    el.appendChild(info);
    el.appendChild(prog);
    el.appendChild(copyBtn);

    function play() {
      if (currentTrackEl === el) { stopCurrent(); return; }
      stopCurrent();
      const audio = new Audio(track.file);
      currentAudio = audio;
      currentTrackEl = el;
      el.classList.add('playing');
      btn.innerHTML = pauseIcon();

      audio.addEventListener('timeupdate', () => {
        if (audio.duration) {
          bar.style.width = (audio.currentTime / audio.duration * 100) + '%';
          time.textContent = formatTime(audio.currentTime) + ' / ' + formatTime(audio.duration);
        }
      });
      audio.addEventListener('ended', stopCurrent);
      audio.play().catch(() => stopCurrent());
    }

    btn.addEventListener('click', (e) => { e.stopPropagation(); play(); });
    el.addEventListener('click', play);

    prog.addEventListener('click', (e) => {
      e.stopPropagation();
      if (!currentAudio || currentTrackEl !== el) { play(); return; }
      const rect = prog.getBoundingClientRect();
      const ratio = (e.clientX - rect.left) / rect.width;
      currentAudio.currentTime = ratio * currentAudio.duration;
    });

    section.appendChild(el);
  });
  app.appendChild(section);
});
</script>
</body>
</html>
HTMLEOF

echo "Player built: $OUTPUT_HTML"
