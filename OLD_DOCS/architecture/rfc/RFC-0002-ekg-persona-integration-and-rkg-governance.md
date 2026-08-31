# RFC-0002 — EKG Persona Integration & RKG Governance

Status: **Proposed** · Author: architecture review, 2026-08-08
Owner Books: **17** (Experiences) · **19** (Governance, Security & Compliance) · **05** (Ontology) · **08** (Institution Digital Twin) · **24** (Executive Command)
Affected registers: **G23** (new, sub-gaps G23.1–G23.5); ontology registry (`architecture/ontology/dlu-core.yaml`, EKG v1.1 + ATA 1.0 classes/relationships)
Supersedes: nothing · Superseded by: nothing · Companion: ADR-0021 (EKG usage / RKG governance plane)

> **Verdict up front.** The EKG v1.1 absorption (`DAS_EKG_INTEGRATION_PLAN.md`,
> `MASTERBOOK-UPDATE-EKG-ATA-COURSEv2.md`, ADR-0016…0020, the 36-sprint
> `EKG-W0…W5` + `W3-ATA` engineering catalog) is real and correctly scoped. It
> is **not** re-opened here. What it left thin is two concrete, checkable
> things: **(1)** the Ontology Registry it calls for was never actually
> written into `architecture/ontology/dlu-core.yaml` — done in this change
> set (see §10); **(2)** persona-facing integration covers only Student and
> Faculty in any depth, and the DXA screen catalog (30 screens) has **zero**
> screens for the maintenance/governance half of the graph, for any persona.
> Stakeholders already call that missing half **"RKG"** — this RFC and its
> companion ADR-0021 give that shorthand a definition that does not
> contradict ADR-0019 ("one platform, not a database"), and closes the
> screen/RACI gap for Dean, Provost, Registrar, Advisor, QA Officer and the
> Platform Operator.

---

## 1. Context

`DAS_EKG_INTEGRATION_PLAN.md` (§4.2, per-Book impact matrix) rates BOOK-17 "High — rewrite" and
BOOK-05/13 "High — rewrite" as well, but as of this RFC every one of those Books carries only a
short, dated pointer addendum ("See `MASTERBOOK-UPDATE-EKG-ATA-COURSEv2.md` for detail") — none
has been rewritten. That wholesale rewrite is out of scope here (it is the pre-existing `EKG-W0…W5`
engineering absorption's job, executed against the running Turnkey codebase, not a documentation
pass). What this RFC targets is narrower and already fully specified elsewhere, just never wired
into the Standard's own persona/RACI apparatus:

- The DXA screen catalog (`DLU_EKG_Suite/DXA/300-screens/SCREEN-INDEX.md`) specs `DEA-01…06`
  (Dean) and `PRO-01…05` (Provost), but **BOOK-17 Ch. 5's IW1–IW6 table has no Dean row at all**,
  and Provost is folded undifferentiated into IW1 ("rector/provost/board") despite BOOK-24 §3
  giving Provost, President, Chairman, CFO and HR six *separate* command surfaces.
- BOOK-19 §1.1's RACI table and BOOK-24 §3's role×surface table do not mention the EKG, mapping
  stewardship, or `PolicyVersion` approval anywhere.
- The DXA catalog's 30 screens are **all read surfaces**. There is no screen — for any persona,
  including the Platform Operator (BOOK-17 IW6) — for ontology-registry administration, mapping
  review, `PolicyVersion` approval, or tenant-guardrail configuration.
- `architecture/ontology/dlu-core.yaml` still had, until this change set, zero EKG or ATA classes
  registered, despite BOOK-05's own addendum instructing exactly that and the file's own header
  rule ("New classes/relationships require an RFC amending BOOK-05 FIRST, then this file").

## 2. Duplication audit (normative — nothing below may be re-built)

| Artefact | Already exists as | Location |
|---|---|---|
| EKG node/edge taxonomy (35 nodes/40+ edges) | `EKG-Ontology-1.0.md` §4–5 | `DLU_EKG_Suite/DKA/100-ontology/` |
| ATA graph extension (11 nodes/12 edges) | `ATA-EKG-Extension.md` | `DLU_EKG_Suite/DKA/600-adaptive-tutor/` |
| Student/Faculty/Dean/Provost/cross-role screen specs | `SCREEN-INDEX.md` (30 screens) | `DLU_EKG_Suite/DXA/300-screens/` |
| Lens abstraction (Role×Intent×Scope×Projection×Depth×Actions×ACL) | ADR-0020 | `architecture/adr/` |
| EKG-as-platform-subsystem decision | ADR-0019 | `architecture/adr/` |
| Pedagogical Policy Engine governed rollout pipeline | ADR-0016 | `architecture/adr/` |
| Tenant guardrails (T12: egress/rate_limit/data_residency/pii/model_allowlist) | `tenant_guardrail_policies`/`guardrail_audit_events` | BOOK-19 Ch. 2.7 (already built, NEW-29) |
| `certify_catalog` governance action (Provost) | BOOK-24 §5, `governance_actions` type | BOOK-24 (already built, SPRINT-23) |
| Engineering sprint catalog for the graph/tutor/mapping backend | `EKG-W0…W5`, `W3-ATA`, `W1-07` | `../dlu_builder_tk/docs/ROOCODE_EKG_PROMPTS.md` |
| Target relational + graph schema | `ER_MAP_TARGET.md` | `../dlu_builder_tk/docs/` |

**Rule RFC2.1** — No sprint under this RFC re-derives the node/edge taxonomy, re-specs a screen
already in the DXA catalog, or re-opens ADR-0019/0020's decisions. A sprint that does so fails
review.

## 3. The real deltas

| # | Delta | Kind | Evidence |
|---|---|---|---|
| D1 | Ontology Registry never populated despite BOOK-05's own instruction and the file's "RFC first" rule. | gap | `architecture/ontology/dlu-core.yaml` v2.0, zero EKG/ATA classes before this change set |
| D2 | No Dean workspace row in BOOK-17 Ch. 5, despite `DEA-01…06` being fully specced. | gap | BOOK-17 Ch. 5 IW table (6 rows: rector/provost/board, registrar, QA, advisor, steward, operator — no Dean) |
| D3 | Provost's five screens (`PRO-01…05`) and BOOK-24's six executive command surfaces are never cross-referenced against BOOK-17's undifferentiated IW1. | conflict | BOOK-17 IW1 "rector/provost/board" vs. BOOK-24 §3's six distinct surfaces |
| D4 | Zero screens, in any persona's catalog, for the graph's governance/maintenance plane — no ontology-registry admin, mapping-review queue, policy-version approval, or guardrail config UI anywhere. | gap | `DLU_EKG_Suite/DXA/300-screens/SCREEN-INDEX.md` — 30/30 rows are read surfaces |
| D5 | No persona×EKG RACI exists; BOOK-19 §1.1 and BOOK-24 §3 don't mention the EKG. | gap | BOOK-19 §1.1, BOOK-24 §3 (both read in full, no EKG/graph row) |
| D6 | "RKG" is in stakeholder use with no citable definition, risking drift into "a second graph" — an anti-pattern ADR-0019 already rejected twice over (database / analytics-mirror options). | conflict (terminology) | zero occurrences of "RKG" anywhere in the Standard, the Suite, or Turnkey before this RFC |
| D7 | ADR-0016–0020 are all still Status: Proposed; nothing in the Standard tracks what would move them to Accepted. | hygiene | `architecture/adr/ADR-0016…0020*.md` headers |

## 4. Decision

### 4.1 RKG is named and scoped (resolves D6)

Per ADR-0021: RKG is the governance/maintenance plane of the one EKG platform subsystem (ADR-0019),
not a second graph. Full decision text lives in ADR-0021; this RFC only wires it into personas.

### 4.2 Persona × EKG-usage / RKG-maintenance RACI (resolves D5)

Appended to BOOK-19 §1.1 as a new table (this RFC's own §4.2 is the source of truth the Book
addendum transcribes verbatim):

| Persona | EKG usage (Lens) | RKG maintenance duty |
|---|---|---|
| Student | `STU-01…12`, tutor `STU-13…15` | Open Learner Model dispute/contest only (BOOK-06 Ch. 8) |
| Faculty | `FAC-01…08` | Course-authoring writes (Course Format v2.0 binds fields to ontology ids); `PolicyVersion` academic-review sign-off (ADR-0016); course-scoped evidence review |
| Dean | `DEA-01…06` | Program-level `MappingAssertion` escalation review; curriculum-graph design-gate sign-off |
| Provost | `PRO-01…05` + BOOK-24 Provost Command | Institution-wide `PolicyVersion` approval; Catalog/Ontology Certification (extends `certify_catalog`, BOOK-24 §5); RFC/ontology-change sign-off (Architecture Board) |
| Registrar / Evidence Registrar | `XRO` tools + IW2 | Evidence supersession review (append-only); credential graph-object issuance |
| Advisor | Career/gap views (`GapObservation`, IW4) | none beyond existing intervention RACI |
| QA Officer | Coverage/traceability queries (feeds BOOK-26/AVA) | Conformance-check verification against graph invariants |
| AI Pedagogy Steward | Agent/`PolicyVersion` scorecards (IW5) | `PolicyVersion` canary/rollback authority (ADR-0016) |
| Platform Operator ("Admin") | Cross-tenant anonymized aggregates (IW6) | **Primary RKG maintainer**: Ontology Registry version approval, tenant guardrails (already built), Neo4j tenancy hardening, mapping-pipeline operations |
| Researcher | Federated zero-trust query path (T13) | none new |
| Auditor / CEV expert | Read-only evidence/coverage audit | none (read-only by design, BOOK-26) |
| President / Chairman / CFO / HR | BOOK-24 command surfaces (thin) | none new |

### 4.3 BOOK-17 gains a Dean row and reconciles Provost (resolves D2, D3)

Ch. 5's IW table gains an explicit Dean entry referencing `DEA-01…06`; the existing IW1 row is
annotated to point at BOOK-24 §3's Provost Command (and, thinly, President/Chairman/CFO/HR) rather
than treating "rector/provost/board" as one undifferentiated surface.

### 4.4 The RKG Governance Console (resolves D4)

A new named console under BOOK-17 IW6 (Platform Operator), with four screens that do not exist in
the DXA catalog today: **ontology-registry admin**, **mapping-review queue**, **`PolicyVersion`
approval workflow**, **tenant-guardrail configuration**. Per Rule RFC2.1 and the brownfield
discipline, it is UI over tables ADR-0019/ADR-0016/BOOK-19 Ch. 2.7 already established
(`ekg_ontology_versions`, `mapping_assertions`/`mapping_reviews`, `policy_versions`,
`tenant_guardrail_policies`) — **no new relational table is proposed by this RFC** (§10 confirms).

### 4.5 ADR lifecycle (resolves D7)

ADR-0016–0020 stay Proposed until their owning `EKG-Wn` sprint lands and its verification passes
(the existing convention — ADR-0009/0010/0013 moved to Accepted the same way once the Suite
"provided the evidence," per `DAS_EKG_INTEGRATION_PLAN.md` §4.1). This RFC does not promote them;
it only adds ADR-0021 in the same Proposed state, for the same reason.

## 5. New events

None. `mastery`, `recommendation`, `path`, `policy` event-noun prefixes already cover most of the
EKG event surface; the newly-registered `tutor`/`goal`/`intervention`/`mapping`/`career`/`gap`/
`ontology` prefixes (§10) are sufficient for RKG-maintenance events (e.g. `ontology.version.
published`, `mapping.assertion.reviewed`) — no additional taxonomy entries are required.

## 6. Conformance checks

- **C19.1** Property: every persona named in BOOK-17 Ch. 5 and BOOK-24 §3 has a corresponding row
  in the §4.2 RACI table — no persona with a workspace and no RACI entry.
- **C19.2** Fixture: `dlu-core.yaml` contains no class or graph label matching `RKG*` (RKG is a
  plane, per ADR-0021, never a node type) — a static grep-based check, not a runtime test.
- **C17.1** Fixture: BOOK-17 Ch. 5's IW table has a Dean row referencing `DEA-01…06`.
- **C05.1** Fixture: `architecture/ontology/dlu-core.yaml` parses as valid YAML and contains every
  EKG (§10) and ATA class/relationship name at least once (this change set's own registration,
  verified in §"Verification" below).

These are documentation/registry-level checks (gre­ppable against this repo), not runtime tests —
the RKG Governance Console's own backend/UI conformance tests are Turnkey-side work, deferred to
`EKG-W6-07/08` (§7) where the running codebase actually exists.

## 7. Sprint catalog

| Sprint | Scope | Books/Registers | Repo |
|---|---|---|---|
| **EKG-W6-01** | Ontology registry catch-up: register EKG (35 nodes/40+ edges) + ATA (11/12) into `dlu-core.yaml`, with brownfield overlap notes instead of duplicate rows. | 05 | Standard |
| **EKG-W6-02** | RFC-0002 (this document) + ADR-0021 (formal RKG definition). | 00 (ADR registry), 05 | Standard |
| **EKG-W6-03** | BOOK-19 §1.1 persona×EKG-usage/RKG-maintenance RACI + G23 in Ch. 8. | 19 | Standard |
| **EKG-W6-04** | BOOK-17 Dean workspace row + RKG Governance Console spec (IW6) + Provost/BOOK-24 cross-reference. | 17 | Standard |
| **EKG-W6-05** | BOOK-08 Ch. 8 consumer table + BOOK-24 §3 role×surface table gain EKG/RKG columns. | 08, 24 | Standard |
| **EKG-W6-06** | Sync duty: `TRACEABILITY.md` (G23), `GLOSSARY.md`, `CHANGELOG.md`, `MASTERBOOK-INDEX.md`. | 00, 20 | Standard |
| **EKG-W6-07** | Dean/Provost/Registrar/Advisor/QA Lens frontend sprint specs (not built code — specs in `ROOCODE_EKG_PROMPTS.md`, same pattern as W0–W5). | 17 | Turnkey |
| **EKG-W6-08** | RKG Governance Console sprint specs (ontology admin, mapping review, policy approval, guardrail config UI) — UI only, reusing existing tables. | 17, 19 | Turnkey |

Each sprint's verification is the corresponding conformance check in §6, or (for W6-07/08) the
verification checklist embedded in the `ROOCODE_EKG_PROMPTS.md` entry itself.

## 8. Sequencing

```
EKG-W6-01 (ontology registry) ──┐
                                  ├─► EKG-W6-02 (RFC+ADR, needs registry to cite) ──┐
                                  │                                                   │
                                  └───────────────────────────────────────────────────┤
                                                                                       ▼
                                                            EKG-W6-03 (BOOK-19 RACI) ──┐
                                                            EKG-W6-04 (BOOK-17)  ──────┼─► EKG-W6-06 (sync)
                                                            EKG-W6-05 (BOOK-08/24) ────┘
                                                                                       │
                                                                                       ▼
                                                    EKG-W6-07 / EKG-W6-08 (Turnkey specs, Standard-side done first)
```

W6-01 and W6-02 are foundational (registry + vocabulary) and gate everything that cites them.
W6-03/04/05 can run in any order relative to each other but all depend on W6-02's vocabulary.
W6-06 is the sync gate — nothing in this RFC is "done" until the apparatus files agree with the
Books. W6-07/08 (Turnkey) are sequenced last because their sprint specs cite the Standard-side
RACI and screen decisions (W6-03/04) as their Definition of Ready.

## 9. Register disposition

New gap **G23** in `TRACEABILITY.md`, with five sub-gaps mirroring the D-numbering above:

| Gap | Description | Owner sprint |
|---|---|---|
| G23.1 | Ontology Registry never populated | EKG-W6-01 |
| G23.2 | No persona×EKG-usage/RKG-maintenance RACI | EKG-W6-03 |
| G23.3 | BOOK-17 missing Dean/executive Lens wiring | EKG-W6-04 |
| G23.4 | No RKG-maintenance UI/console for any persona | EKG-W6-04, EKG-W6-08 |
| G23.5 | "RKG" undefined, risk of drift into "second graph" | EKG-W6-02 (ADR-0021) |

## 10. Ontology duty (BOOK-05)

Executed in the same change set as this RFC (BOOK-05 Ch. 8's rule: RFC first, then the registry
file) — `architecture/ontology/dlu-core.yaml` now carries: the EKG v1.1 node types with no
pre-existing equivalent (`LearningResource`, `KnowledgeUnit`, `ToolTechnology`, `Dataset`,
`FrameworkConcept`, `QualificationLevel`, `AssessmentItem`, `Rubric`, `RubricCriterion`,
`PerformanceLevel`, `MasteryObservation`, `LearningState`, `JobRole`, `CareerPath`,
`SkillRequirement`, `GapObservation`, `LearningPath`, `LearningPathStep`, `PolicyRule`,
`MappingAssertion`); the ATA 1.0 extension (`LearningGoal`, `LearningIntervention`,
`LearningStrategy`, `TutorSession`, `TutorTurn`, `LearningEpisode`, `Misconception`,
`LearningPlan`, `TutorEvidence`, `PolicyVersion` — `Recommendation` reused, not re-added); the
corresponding new relationships (43 EKG + 12 ATA — the EKG figure corrected from an earlier
"42" miscount once EKG-W0-01's Postgres seed (`dlu_builder_tk`) transcribed the same 49-row
source table and caught the off-by-one), with explicit brownfield notes wherever an EKG
name is a second domain/range pair under an already-used relationship name (`DEVELOPS`,
`ASSESSES`, `EVIDENCES`, `SUPPORTS`) rather than a silent duplicate; and one alias
(`HAS_CLO → DEFINES_CLO`, `removed_in: "2.1"`, the same window as the three pre-existing aliases).
No class or relationship already covered by an exact pre-existing pair (`HAS_COURSE`,
`HAS_MODULE`, `HAS_LESSON`, `TEACHES`, `PREREQUISITE_OF`, `ASSESSED_BY`) was re-added.

## 11. Alternatives considered

1. **Leave "RKG" undefined and let usage settle organically.** Rejected — ADR-0019 already shows
   what happens when "just a graph" is left ambiguous (it drifts into "a database"); the same risk
   applies here, and the term is already circulating.
2. **Give RKG its own Neo4j instance / ontology, mirroring EKG's.** Rejected outright by ADR-0019's
   own decision (Neo4j is a component, not the product; one canonical ontology) — would duplicate
   the Ontology Registry this RFC just populated.
3. **Fold Dean into IW1 permanently (no new row), since Provost/Board are already there.** Rejected
   — Dean has a distinct, fully-specced screen set (`DEA-01…06`, program-level, not
   institution-level) and a distinct RKG duty (program-scoped mapping escalation, not
   institution-wide policy approval); collapsing them loses a real RACI distinction.
4. **Build the RKG Governance Console's backend/UI now, in this pass.** Rejected — this is a
   documentation/registry change set in `dlu-architecture-standard`; the console is real frontend
   and API work against the running Turnkey codebase, correctly scoped as sprint specs
   (`EKG-W6-07/08`) for execution there, not fabricated here.

---

*Per BOOK-00 Ch. 16's sync rule: this RFC, ADR-0021, the BOOK-17/19/08/24 addenda, the ontology
registry update, and the `TRACEABILITY.md`/`GLOSSARY.md`/`CHANGELOG.md`/`MASTERBOOK-INDEX.md`
sync move together in one change set — see the companion `ROOCODE_EKG_PROMPTS.md` Wave 6 entry in
`dlu_builder_tk` for the Turnkey-side continuation.*
