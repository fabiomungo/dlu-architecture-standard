#!/usr/bin/env python3
"""
Ontology registry lint — DAS STX-05 (BOOK-05 Ch. 8 enforcement).

Validates against the DLU-Core registry
(`dlu-architecture-standard/architecture/ontology/dlu-core.yaml`):

1. Cypher files (default: scripts/kg/*.cypher, or paths given as args):
   every node label `(:Label)` and relationship type `[:REL_TYPE]` must be
   a registered graph label / relationship / alias.
2. Event Mesh taxonomy (`backend/services/event_taxonomy.py`): the noun
   prefix of every registered event type must be in `event_nouns`.

Exit 0 = clean; exit 1 = violations (listed). New vocabulary requires an
RFC amending BOOK-05 first, then the registry, then code.

Usage:
    python scripts/ci/lint_ontology.py [cypher files...]
    ONTOLOGY_REGISTRY=/path/to/dlu-core.yaml python scripts/ci/lint_ontology.py
"""
import glob
import os
import re
import sys

try:
    import yaml
except ImportError:
    print("lint_ontology: PyYAML required (pip install pyyaml)")
    sys.exit(2)

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DEFAULT_REGISTRY_CANDIDATES = [
    os.environ.get("ONTOLOGY_REGISTRY"),
    os.path.join(REPO_ROOT, "..", "dlu-architecture-standard",
                 "architecture", "ontology", "dlu-core.yaml"),
    os.path.join(REPO_ROOT, "architecture", "ontology", "dlu-core.yaml"),
]

LABEL_RE = re.compile(r"\(\s*[A-Za-z_][A-Za-z0-9_]*?\s*:\s*([A-Za-z][A-Za-z0-9_]*)|\(\s*:\s*([A-Za-z][A-Za-z0-9_]*)")
REL_RE = re.compile(r"\[\s*[A-Za-z_][A-Za-z0-9_]*?\s*:\s*([A-Z][A-Z0-9_]*)|\[\s*:\s*([A-Z][A-Z0-9_]*)")
# CREATE CONSTRAINT ... FOR (x:Label) — covered by LABEL_RE


def load_registry():
    for candidate in DEFAULT_REGISTRY_CANDIDATES:
        if candidate and os.path.exists(candidate):
            with open(candidate) as fh:
                return yaml.safe_load(fh), candidate
    print("lint_ontology: registry dlu-core.yaml not found "
          "(set ONTOLOGY_REGISTRY)")
    sys.exit(2)


def allowed_vocab(registry):
    labels = {c["graph_label"] for c in registry["classes"]
              if c.get("graph_label")}
    rels = {r["name"] for r in registry["relationships"]}
    aliases = {a["name"] for a in registry.get("aliases", [])}
    return labels, rels | aliases


def lint_cypher(paths, labels, rels):
    violations = []
    for path in paths:
        with open(path) as fh:
            text = "\n".join(line.split("//")[0] for line in fh)
        found_labels = {m.group(1) or m.group(2) for m in LABEL_RE.finditer(text)}
        found_rels = {m.group(1) or m.group(2) for m in REL_RE.finditer(text)}
        for label in sorted(found_labels - labels - {None}):
            violations.append(f"{path}: unregistered node label :{label}")
        for rel in sorted(found_rels - rels - {None}):
            violations.append(f"{path}: unregistered relationship :{rel}")
    return violations


def lint_taxonomy(registry):
    taxonomy_path = os.path.join(REPO_ROOT, "backend", "services",
                                 "event_taxonomy.py")
    if not os.path.exists(taxonomy_path):
        return []  # standard repo run: no taxonomy to check
    nouns = set(registry.get("event_nouns", []))
    with open(taxonomy_path) as fh:
        text = fh.read()
    event_types = set(re.findall(r'=\s*"([a-z_]+(?:\.[a-z_]+)+)"', text))
    violations = []
    for event_type in sorted(event_types):
        noun = event_type.split(".")[0]
        if noun not in nouns:
            violations.append(
                f"event_taxonomy.py: event noun '{noun}' ({event_type}) "
                "not in dlu-core.yaml event_nouns")
    return violations


def main():
    registry, registry_path = load_registry()
    labels, rels = allowed_vocab(registry)

    cypher_paths = sys.argv[1:] or sorted(
        glob.glob(os.path.join(REPO_ROOT, "scripts", "kg", "*.cypher")))

    violations = lint_cypher(cypher_paths, labels, rels)
    violations += lint_taxonomy(registry)

    checked = f"{len(cypher_paths)} cypher file(s) + taxonomy"
    if violations:
        print(f"lint_ontology: FAIL ({checked}, registry {registry_path})")
        for v in violations:
            print(f"  ✗ {v}")
        sys.exit(1)
    print(f"lint_ontology: OK ({checked}, registry {registry_path})")


if __name__ == "__main__":
    main()
