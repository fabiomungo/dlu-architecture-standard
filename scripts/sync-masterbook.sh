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
cp -f BOOK-14A-Credit-Recognition-and-Pre-Evaluation-v1.0.md "$DEST/"
cp -f BOOK-09A-Adaptive-Tutor-v1.0.md "$DEST/"
cp -f MASTERBOOK-UPDATE-EKG-ATA-COURSEv2.md "$DEST/" 2>/dev/null || true
# Sync ADRs for MkDocs nav
ADRDEST="docs/architecture/adr"; mkdir -p "$ADRDEST"
cp -f architecture/adr/ADR-*.md "$ADRDEST/"
# Draft books + changelog referenced by the index
for f in BOOK-2[0-9]*-draft.md; do cp -f "$f" "$DEST/" 2>/dev/null || true; done
cp -f CHANGELOG.md "$DEST/" 2>/dev/null || true
# Sync RFCs for cross-links
RFCDEST="docs/architecture/rfc"; mkdir -p "$RFCDEST"
cp -f architecture/rfc/RFC-*.md "$RFCDEST/" 2>/dev/null || true
# Fix relative depth of adr/rfc links inside copied draft books (docs/masterbook/ is one level below docs/)
python3 - "$DEST" <<'PYFIX'
import glob,re,sys
for f in glob.glob(sys.argv[1]+"/BOOK-2*-draft.md"):
    s=open(f,encoding="utf-8").read()
    open(f,"w",encoding="utf-8").write(re.sub(r"\]\(architecture/","](../architecture/",s))
PYFIX
cp -f MASTERBOOK-INDEX.md TRACEABILITY.md GLOSSARY.md MASTERBOOK-REVIEW-v1.0.md "$DEST/"
cat > "$DEST/README.md" <<'EOF'
# Generated copies — do not edit here
Source of truth: repository root (`BOOK-*.md`, apparatus files).
Regenerate with `scripts/sync-masterbook.sh`.
EOF
echo "Masterbook synced to $DEST ($(ls "$DEST" | wc -l | tr -d ' ') files)."
