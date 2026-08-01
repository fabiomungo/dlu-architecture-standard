# BOOK-25 — Research Workspace & Open Science
### DAS v0.1-draft · Layer: Intelligence / Institution · Status: IMPLEMENTED (SPRINT-21/NEW-33 — G21 FULLY CLOSED; corrected from stale "DRAFT" SPRINT-22 doc-sync, 2026-08-01 — the intro below already said ✅ IMPLEMENTED, only this status line was stale)

> ✅ **IMPLEMENTED (NEW-33, SPRINT-21, 2026-08-01):** the full domain
> model below (§2, 13 tables — 11 + `research_compute_jobs` +
> `research_kb_chunks`, disclosed additions), the Research Assistant
> (§4), grants/outputs/compute-broker fabric (§5), all 6 events (§6),
> and all 5 conformance checks (§7) plus an added **C25.5** (this
> book's own §7 already named it; the plan's own DoD had only listed
> 4) are real and verified against a migrated Postgres. Closes **G21**
> in full. See `SPRINT-21.md`'s own "Correzioni al piano" for every
> plan-vs-reality correction found in pre-flight/verification —
> summarized inline below where it changes what a reader of this book
> should expect to find in the code.

> Adds the **tenth persona — the Researcher** — and closes **G21** (no research capability
> in the platform). Grounded in the comparative analysis *"Architetture IA per Ricerca
> Universitaria"*: Renku 2.0 (SDSC/EPFL-ETH) for reproducibility and data provenance,
> Swiss Data Custodian for zero-trust inter-institutional collaboration, EuroHPC AI
> Factories for sovereign compute, Federated RAG over private scholarly corpora, and
> GDPR/AI-Act compliance for research. ER target domain: **T13**. Functionality area: **25**.
> Sprint: **NEW-33**.

---

## 1. Purpose and scope

The AI-Native University teaches *and researches*. The Researcher MUST be able to run
projects whose results are reproducible by construction, query the institution's (and the
consortium's) private knowledge without moving raw data, manage grants and outputs inside
the same financial and workload backbone as everything else, and use AI assistance that
cites what it claims.

Out of scope: HPC scheduling internals (external driver), publisher/journal workflows,
laboratory instrument integration.

## 2. Domain model (aggregates, T13)

| Aggregate | Root | Key invariants |
|---|---|---|
| ResearchProject | `research_projects` | members incl. external partners; every project carries a compliance assessment before processing personal/clinical data |
| DatasetRegistry | `research_datasets` + `dataset_versions` | versions are immutable; license and consent metadata mandatory; DOI optional but tracked |
| ReproducibleEnvironment | `research_environments` | container digest + execution context recorded per run (Renku model) |
| Provenance | `provenance_records` | **R25.1** every registered output resolves to the exact (code sha, dataset version, container digest) that produced it — the FAIR DAG |
| ResearchOutput | `research_outputs` | typed (publication/dataset/software); authors link to `faculty_profiles` and post to the workload ledger (BOOK-22) |
| Grant | `grants` + `grant_budget_links` | award links to budget lines (BOOK-23); no shadow accounting |
| FederatedScope | `federated_kb_scopes` | **R25.2** zero-trust rule: raw data never leaves the owning instance; only scope-authorized retrieval passes travel, every served query is audited |
| ComplianceAssessment | `research_compliance_assessments` | reuses `fria_assessments`; responsible-GenAI policy binding via T6 |

## 3. Knowledge: internal RAG and Federated RAG

Internal: theses, publications, patents indexed in the existing RAG pipeline with
per-project scopes. Federated: queries fan out to consortium instances via
`instance_registry`; each instance answers only within its declared
`federated_kb_scopes` (retrieve-only policy), enforcement is audited and — once
SPRINT-22 lands — governed by tenant guardrail policies (T12). The pattern follows the
Data Custodian principle: computation moves to the data, ownership never transfers.

> ✅ **IMPLEMENTED, with 2 corrections found in pre-flight (SPRINT-21.md
> "Correzioni al piano" #6/#7):** neither existing RAG path fit "reused
> with project scopes" as originally written — `RAGAgent` is course-
> scoped only, `ReferenceDocument`'s own retrieval is a declared
> placeholder that always returns `[]`. Built a real, minimal,
> project-scoped chunk+embedding store instead (`research_kb_chunks`,
> `research_kb_service.py` — same `text-embedding-3-small` mechanism
> `rag_agent.py` already uses in production). Federation fan-out
> (`federated_research_service.py`) is likewise built from scratch —
> `FederationService` was pure CRUD + heartbeat, zero query fan-out
> existed to extend — scoped to the DoD's own "2 istanze mock": both
> instances are rows in the SAME database, not a real cross-process
> network call (same "mock" posture this program already uses for
> other undelivered external transports).

## 4. The Research Assistant (propose-only)

Extends BOOK-10A Annex T (roster +1). Capabilities: literature review over the KB with
**verifiable citations** (R25.3: every claim resolves to an existing source chunk —
anti-hallucination test in CI), structured extraction from document corpora, drafting
support. Contract card: propose-only, no writes to project state; surfaced exclusively
through `AIProposalCard`; dedicated eval dataset `research_assistant` with GA gate
(BOOK-11). Rejections with reason feed the eval loop.

> ✅ **IMPLEMENTED (NEW-33):** "GA gate" here means the T11 golden-set
> harness (`domain_agent_fns.py` + `research_assistant.jsonl`, 22 real
> golden cases) — the SAME mechanism BOOK-10A Annex T's other 4
> persona-support agents use — NOT the twin-shaped PDDAEL scenario-bank
> gate (`harness.py::run_gate`), which structurally does not apply
> here (no `scenario_bank/research_assistant.yaml` exists, same reason
> it doesn't for the other 4; SPRINT-21.md "Correzioni al piano" #10).
> `CITATION_SCORE_THRESHOLD = 0.75` is the real anti-hallucination
> floor — below it a claim is honestly `supported=False`, never a
> fabricated citation.

## 5. Grants, outputs, and the institutional fabric

Grant lifecycle (call → submission → awarded/rejected → closed) with project budget
imputed on `budget_lines` (BOOK-23) — the CFO sees research money in the same
planning & control cycle as everything else. Outputs post to
`faculty_workload_entries` (type `research`, BOOK-22) making research effort visible in
the workload ledger; research KPIs (active projects, outputs, grant success rate)
publish into the T10 layer (BOOK-24). Compute requests toward external HPC/AI
Factories are brokered as jobs with quotas and cost attribution (driver executes).

> ✅ **IMPLEMENTED (NEW-33):** `entry_type='research'` required a real
> migration (a Postgres CHECK constraint, not just a Python tuple) —
> extended alongside `models_hr.py`'s existing `teaching`/`authoring`/
> `thesis_committee`/`tutoring` values. `grant_budget_links` is a real
> junction table (a grant can fund several budget lines), a deliberate
> deviation from the simpler 1:1-FK pattern this program uses elsewhere
> (`AuthoringEngagement.budget_line_id`) — no generic "link" service
> existed to reuse either. The compute broker
> (`research_compute_broker_service.py`) needed its own table
> (`research_compute_jobs`, beyond this section's own "11 tables"
> count) — `driver_reference` is a `MOCK-DRIVER-{job_id}` opaque
> reference, same posture `ap_service`'s payment-run driver already
> established for undelivered external integrations.

## 6. Events (A6-closed)

`ResearchProjectCreated`, `DatasetVersioned`, `ProvenanceRecorded`,
`OutputRegistered`, `GrantAwarded`, `FederatedQueryServed`.

> ✅ **IMPLEMENTED (NEW-33)** as `research_project.created`, `research_
> dataset.versioned`, `provenance.recorded`, `research_output.
> registered`, `grant.awarded`, `federated_query.served`
> (`event_taxonomy.py`) — 2 nouns refined from this section's literal
> names (`Dataset`→`research_dataset`, `Output`→`research_output`) to
> avoid future ambiguity with the unrelated T11 `EvalDataset` concept
> and a too-generic "output" noun. Unlike most other T-domain events,
> T13 was never pre-reserved by SPRINT-01/NEW-17f — a genuinely new
> registration (`event_nouns:` in both `dlu-core.yaml` copies,
> `lint_ontology.py`-clean).

## 7. Conformance checks

- C25.1 Reproducibility fixture: a registered output re-resolves to its exact inputs
  (code sha + dataset version + container digest).
- C25.2 Zero-trust property: federated query with out-of-scope content → nothing served;
  every served query audited (two-instance mock test).
- C25.3 Citation integrity: every Research Assistant claim cites an existing chunk;
  GA gate green on `research_assistant` dataset.
- C25.4 Fabric test: output → workload entry posted; awarded grant → budget line linked.
- C25.5 Compliance gate: project processing personal data without a completed
  assessment → blocked.

> ✅ **ALL FIVE VERIFIED (NEW-33)** — `tests/conformance/
> test_research_workspace.py` (6 tests, real Postgres, real OpenAI
> embeddings for C25.3) + `tests/e2e/demo/test_researcher.py` (the
> Researcher persona's own end-to-end walkthrough). C25.5 was absent
> from `SPRINT-21.md`'s own literal DoD (which listed only 4 checks) —
> added there from this section, since it's a real, cheap-to-verify
> invariant this book itself already named.

## Annex A — Turnkey mapping

| Element | Exists today | Target | ✅ Delivered (NEW-33) |
|---|---|---|---|
| RAG pipeline | `rag.py`, `reference_documents`, resource/transcript chunks | reused with project scopes | NOT reused as-is (both paths unfit, §3) — new `research_kb_chunks`/`research_kb_service.py`, same embedding mechanism |
| Federation | `federation.py`, `instance_registry` | federated retrieval transport | new `federated_research_service.py` (fan-out built from scratch, §3) |
| Compliance | `fria_assessments`, `ai_act_obligations` (BOOK-19) | project-level assessments | `research_compliance_assessments` (soft ref to `platform.fria_assessments.id` — cross-schema) |
| Finance/workload/KPI | T7 `budgets`, T9 `faculty_workload_entries`, T10 KPI layer | grant/output/effort integration | `grant_budget_links`, `entry_type='research'` (new CHECK value), 3 new KPIs in `kpi_compute_service.py` |
| Guardrails | T12 (SPRINT-22) | federated enforcement hook | still SPRINT-22 — unchanged, disclosed |
| New tables | — | T13: 11 tables (`ER_MAP_TARGET.md` §T13) | 13 tables (+`research_compute_jobs`/`research_kb_chunks`, disclosed) |
| Sprint | — | **NEW-33** (SPRINT-21 of the executable plan) | DONE, 2026-08-01 |
| Register | — | add **G21** (research workspace absent) to TRACEABILITY | done — G21 closed |
