#!/usr/bin/env bash
# Sync the Masterbook (source of truth: repo root) into docs/masterbook/
# for MkDocs rendering. Run after any Book/apparatus change (BOOK-20 Ch. 12
# sync duty). Idempotent.
set -euo pipefail
cd "$(dirname "$0")/.."
DEST="docs/masterbook"
mkdir -p "$DEST"
cp -f BOOK-00-Executive-Vision-and-Manifesto-v2.0.md "$DEST/"
for f in BOOK-0[1-9]-*-v1.0.md BOOK-1[0-9]-*-v1.0.md BOOK-20-*-v1.0.md; do
  cp -f "$f" "$DEST/"
done
cp -f BOOK-10A-AI-Workforce-Skills-and-MCP-Catalog-v1.0.md "$DEST/"
cp -f BOOK-10B-AI-Execution-Framework-v1.0.md "$DEST/"
cp -f MASTERBOOK-INDEX.md TRACEABILITY.md GLOSSARY.md MASTERBOOK-REVIEW-v1.0.md "$DEST/"
cat > "$DEST/README.md" <<'EOF'
# Generated copies — do not edit here
Source of truth: repository root (`BOOK-*.md`, apparatus files).
Regenerate with `scripts/sync-masterbook.sh`.
EOF
echo "Masterbook synced to $DEST ($(ls "$DEST" | wc -l | tr -d ' ') files)."
