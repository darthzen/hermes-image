#!/usr/bin/env bash
# Verify every toolbelt binary runs and every baked Python library imports.
# Usage: toolcheck [python-interpreter]   (default: first python3 on PATH)
# Exits non-zero and names what is missing.
set -uo pipefail

PY=${1:-$(command -v python3)}
fail=0

bins=(rg fd jq yq tree file less bc shellcheck unzip zstd xz dig ping nc rsync
      ssh curl wget ps free timeout git pdftotext pdfinfo sqlite3 ffmpeg ffprobe
      kubectl helm gh crane stern yt-dlp uv)
for b in "${bins[@]}"; do
  if ! command -v "$b" >/dev/null 2>&1; then
    printf 'MISSING  %s\n' "$b"; fail=1
  fi
done

# A binary that exists but cannot execute (wrong arch, missing lib) is also a failure.
for v in "kubectl version --client" "helm version --short" "gh --version" "yq --version" \
         "crane version" "stern --version" "yt-dlp --version" "rg --version" "fd --version" "jq --version"; do
  if ! out=$($v 2>&1 | head -1); then
    printf 'BROKEN   %s: %s\n' "$v" "$out"; fail=1
  else
    printf 'ok       %-24s %s\n' "${v%% *}" "$out"
  fi
done

"$PY" - <<'EOF' || fail=1
import importlib, sys
mods = ["docx", "pptx", "yaml", "pypdf", "numpy", "PIL", "requests",
        "mido", "miditoolkit", "soundfile", "librosa", "av"]
bad = []
for m in mods:
    try:
        importlib.import_module(m)
    except Exception as e:
        bad.append(f"{m}: {e}")
print(f"python   {sys.executable} {sys.version.split()[0]}")
for b in bad:
    print(f"IMPORT   {b}")
sys.exit(1 if bad else 0)
EOF

[ "$fail" -eq 0 ] && echo "TOOLCHECK PASS" || echo "TOOLCHECK FAIL"
exit "$fail"
