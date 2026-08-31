# ADR-0021 — EKG usage and RKG (governance/maintenance) are the two planes of one subsystem

Status: Accepted (2026-08-09, implemented — EKG-W0-01…W6-08, see TRACEABILITY.md)
Related: ADR-0019 (EKG platform subsystem), ADR-0020 (Lens projection contract), ADR-0016 (pedagogy explicit/versioned), BOOK-05, BOOK-13, BOOK-17, BOOK-19, BOOK-24
Source: RFC-0002 (EKG Persona Integration & RKG Governance); no prior art — "RKG" does not appear anywhere in the Standard, the DLU Architecture Suite, or Turnkey before this ADR.

## Context

ADR-0019 already names most of the components a persona-facing governance model needs
(Ontology Registry, `MappingAssertion` stewardship, tenant guardrails, the mastery engine) but
never separates them from the read/query side of the same graph, and never assigns either side
to a persona. BOOK-19 §1.1's RACI table and BOOK-24 §3's role×surface table don't mention the
EKG at all. The DXA screen catalog (`DLU_EKG_Suite/DXA/300-screens/SCREEN-INDEX.md`) specs 30
screens — `STU/FAC/DEA/PRO/XRO` — and every one of them is a **read** surface; there is no screen
anywhere for ontology-registry administration, mapping-review, `PolicyVersion` approval, or
tenant-guardrail configuration, for any persona, including the Platform Operator (BOOK-17 IW6).
Stakeholders have started using the shorthand **"RKG"** for this missing maintenance half; the
term needs a durable, non-ambiguous definition before it appears in more Books, or it will drift
into meaning "a second graph" — which ADR-0019 already explicitly rejected as an anti-pattern
("EKG = an analytics mirror" / "EKG = a database" were both rejected there).

## Options considered

1. **Treat "RKG" as an unofficial synonym for "EKG" and drop it.** Simplest; loses the real
   distinction stakeholders are already pointing at (who *reads* the graph vs. who's accountable
   for its *correctness and evolution* are genuinely different personas with different RACI).
   Rejected.
2. **Define RKG as a second, physically separate graph** (e.g. a "reference" ontology graph
   feeding the EKG). Would contradict ADR-0019's core decision ("Neo4j is a component, not the
   product," one canonical ontology) and duplicate the Ontology Registry that ADR-0019 already
   established. Rejected.
3. **Name RKG as the governance/maintenance plane of the one EKG platform subsystem**, formalizing
   an operational split that already exists in ADR-0019's own component list, and assign it a
   persona RACI the same way BOOK-19 §1.1 already does for every other governed decision.
   (Chosen — matches the confirmed usage: RKG is not a separate system.)

## Decision

- The EKG platform subsystem (ADR-0019) has exactly **two operational planes**, not two graphs:
  - **EKG usage** — the read/query plane, surfaced only through governed **Lenses** (ADR-0020):
    progressive disclosure L0→L3, bounded local graph, mastery ≠ confidence, table-before-graph.
    Every `STU/FAC/DEA/PRO/XRO` screen in the DXA catalog is an EKG-usage surface.
  - **RKG (governance/maintenance)** — the write/curate plane: **Ontology Registry** versioning
    (`ekg_ontology_versions`/`ekg_node_types`/`ekg_edge_types`/`ekg_shacl_shapes`), **`MappingAssertion`**
    stewardship (candidate review, confidence bands, approve/reject/deprecate), **`PolicyVersion`**
    approval and rollback (the Pedagogical Policy Engine's governed rollout pipeline, ADR-0016),
    **tenant guardrails** (T12, BOOK-19 Ch.2.7 — already built), and **evidence audit**
    (`evidence_records` supersession review). RKG is never queried by learners or by the Lens
    layer directly — it is accessed only by the personas this ADR assigns below.
- **Every persona gets an explicit RACI cell on both planes**, in BOOK-19 §1.1 (RFC-0002 §4):
  most personas (Student, Advisor, Researcher, Auditor) have EKG-usage only; Faculty/Dean/Provost
  hold narrow, scoped RKG duties (course-authoring writes, `MappingAssertion` escalation,
  institution-wide `PolicyVersion`/ontology sign-off, respectively); the **Platform Operator**
  (BOOK-17 IW6, the closest existing analogue to "Admin") is the **primary RKG maintainer**,
  absorbing the Suite's own `GOVERNANCE.md` "Knowledge/Graph Architect" and "Solution/Platform
  Architect" roles into that seat rather than inventing a new one.
- **RKG maintenance gets UI**, not just a backend API: the DXA screen catalog's gap (zero
  governance screens) is closed by a named **RKG Governance Console** (BOOK-17 IW6, RFC-0002 §4)
  — ontology-registry admin, mapping-review queue, policy-version approval, tenant-guardrail
  config — reusing tables ADR-0019/ADR-0016 already established, per the brownfield "no new
  table for something that already exists" discipline (RFC-0001's own duplication-audit rule).
- **This does not reopen ADR-0019.** RKG is a named half of the same subsystem; nothing here
  authorizes a second ontology, a second Neo4j instance, or a bypass of the policy-aware API
  facade — RKG-maintenance writes still go through the same governed facade and outbox path as
  every other EKG write.

## Consequences

**Positive:** "RKG" gets a definition that survives contact with ADR-0019 instead of contradicting
it; every persona's relationship to the graph (not just Student/Faculty) is now traceable in one
RACI table; the previously-invisible gap (no governance UI for any persona) becomes a named,
plannable deliverable instead of an undocumented absence.
**Costs/risks:** a new console to design and build (RFC-0002 §5–6, sprints `EKG-W6-07/08`); risk
of the term still drifting toward "second graph" in casual usage — mitigated by this ADR being
the single citable definition and by CI/lint treating any new "RKG" node/edge type as a build
failure (there is no such type — RKG is a plane, not a label).
**Enforcement:** BOOK-19 §1.1's persona×EKG-usage/RKG-maintenance table is the normative RACI;
`GLOSSARY.md` carries this ADR's definition verbatim; a lint rule (extending the existing
ontology-registry lint) rejects any `dlu-core.yaml` class or graph label named `RKG*` — RKG is
never a node type.

## Related artifacts

`RFC-0002-ekg-persona-integration-and-rkg-governance.md`; `DAS_EKG_INTEGRATION_PLAN.md`;
`architecture/ontology/dlu-core.yaml` (Ontology Registry entries this ADR governs); BOOK-19 §1.1;
BOOK-17 IW6; skills `ekg-graph`, `ekg-lens`; sprints `EKG-W6-01…08`.
