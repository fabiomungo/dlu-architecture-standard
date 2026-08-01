# BOOK-10A — AI Workforce, Skills & MCP Catalog
## DLU Architecture Standard (DAS) · Normative Annex to BOOK-10
### Version 1.0 — DRAFT for review

> The exhaustive, phased catalog of the intelligent components: **agents**
> (the full roster beyond the student-facing nine), **skills** (typed
> capabilities in the ACP registry), **MCP servers** (the tool bus, internal
> and external) and their **usage modes** in the AI-Native University. This is
> the refinement that precedes the K1 prompt pack: every intelligent component
> that will ever be configured has a name, a contract sketch, an owner and a
> phase — before a single sprint prompt is generated.
>
> **Conforms to:** BOOK-10 (composition, lifecycle, scorecards), BOOK-09
> (moves), BOOK-11 (patterns, harness), BOOK-06 (entitlements).
> **Baseline (running today, `ai_university_defaults.py`):** 3 MCP servers
> (`dlu-knowledge-graph` [query_concepts, get_prerequisites, get_plo_clo_map],
> `dlu-web-search` [brave_web_search], `dlu-code-executor` [execute_python]),
> 10 skills (`uni-*`), 4 agents (`uni-study-assistant`, `uni-curriculum-
> designer`, `uni-assessment-creator`, `uni-content-enricher`).
>
> **Status legend:** ✅ seeded/running · 🔵 phased (sprint noted) · ⚪ later.

---

# Chapter 1 — Method, Naming, Categories

1. **Naming:** existing `uni-*` slugs are grandfathered; new components use
   `dlu-<domain>-<key>` (agents), `<verb>-<object>` (skills, e.g.
   `draft-viva-dossier`), `dlu-<capability>` (MCP servers). Slugs are
   ontology-linted (BOOK-05 Ch. 8).
2. **Every agent is an ACP composition** (BOOK-10 Ch. 2): nothing below exists
   outside `ai_agent_configs` + bindings. Every skill has I/O schemas; every
   tool reaches agents only through an MCP manifest.
3. **Scoping:** `org` default; `dept`/`program`/`course` variants via
   `scope_type/scope_id` (running) — specialization without forking.
4. **Skill categories** (extends the running set): `dialogue` ·
   `content_gen` · `assessment` · `feedback` · `summarization` ·
   `extraction` · `translation` · `planning_narration` · `evidence` ·
   `document_gen` · `analysis` · `compliance`.
5. **Preset classes** map to the escalation ladder (BOOK-09 Ch. 4):
   `P-fast` (L2 small/local — hints, classification, extraction),
   `P-standard` (L3 — tutoring, generation), `P-deliberate` (L3/L4 —
   dossiers, briefings, recognition), `P-embed` (embeddings), `P-media`
   (image/audio/video via categorized providers).

---

# Chapter 2 — Agent Roster (exhaustive)

## 2.1 Student-facing (the Nine — contract cards in BOOK-10 Ch. 3)

| Agent slug | Mission (one line) | Autonomy | Preset | Phase |
|-----------|--------------------|----------|--------|-------|
| `dlu-student-discovery` | intake, goals, persona, twin seeding | propose | P-standard | 🔵 STX-06 |
| `dlu-student-recognition` | prior-learning claims → dossiers | propose (registrar HITL) | P-deliberate | 🔵 STX-12 |
| `dlu-student-navigator` | GPS scenario narration & replanning dialogue | propose | P-standard | 🔵 STX-07 |
| `dlu-student-coach` | pacing, review missions, habits, nudges | act (low-stakes) | P-fast/standard | 🔵 STX-09/10 |
| `dlu-student-tutor` | Socratic course tutoring (GraphRAG-grounded) | act (in envelope) | P-standard | 🔵 STX-10 |
| `dlu-student-assessor` | formative generation, feedback, viva prep | act formative / propose summative | P-standard | 🔵 STX-11 |
| `dlu-student-credentialer` | eligibility narration, wallet guidance | act badges / reserved high-stakes | P-fast | 🔵 STX-13 |
| `dlu-student-success` | risk detection, belonging, re-engagement | propose | P-standard | 🔵 STX-14 |
| `dlu-student-career` | ESCO gap analysis, goal coaching | propose | P-deliberate | 🔵 STX-15 |

*Absorption note:* seeded `uni-study-assistant` ✅ is the embryo of
tutor+coach; its skills transfer, the slug retires at STX-10 (alias window).

## 2.2 Faculty & authoring

| Agent slug | Mission | Autonomy | Key skills / tools | Phase |
|-----------|---------|----------|--------------------|-------|
| `uni-curriculum-designer` ✅ | program/course structure proposals, CLO drafting | propose (Gate 1) | clo-writer, curriculum-gap-analyzer / kg | running |
| `uni-assessment-creator` ✅ | quiz/lab item generation, Bloom-targeted | propose (faculty approve) | quiz-generator, lab-exercise-generator | running |
| `uni-content-enricher` ✅ | 9-type media enrichment orchestration | act (draft) / Gate 2 | lesson-enricher, summarizer / kg, media | running |
| `dlu-faculty-architect` | course blueprint proposals (`/architect/propose` formalized) | propose | draft-blueprint / catalog, kg | 🔵 K2 |
| `dlu-faculty-coach` | pedagogical QA: Bloom/coverage/CAT-trajectory analysis + recommendations | act (reports) | analyze-bloom-distribution, audit-coverage | 🟡 running service → agent K2 |
| `dlu-faculty-viva-preparer` | viva dossiers from evidence graph (weakest-link probes) | propose | draft-viva-dossier / evidence | 🔵 STX-11 |
| `dlu-faculty-register-drafter` | G4 teaching register generation from delivery events | propose (faculty certify) | draft-teaching-register / xapi | 🔵 NEW-09 |
| `dlu-faculty-envelope-advisor` | learned-default tuning proposals for envelopes (M4→propose) | propose | analyze-envelope-outcomes | ⚪ K4 |
| `dlu-media-producer` | video professor, TTS, image pipeline coordination | act (draft assets) | media job skills / P-media providers | ✅ services → agent K3 |
| `dlu-localizer` | course/content translation & cultural adaptation (IT/EN+) | propose | academic-translator ✅ | 🟡 |

## 2.3 Institutional & staff

| Agent slug | Mission | Autonomy | Consumes | Phase |
|-----------|---------|----------|----------|-------|
| `dlu-inst-dean-briefer` | governance dossiers from Institution Twin (three-economy impact statements) | propose | I2/I3/I6 | 🔵 NEW-10 |
| `dlu-inst-qa-writer` | living self-study sections, CEV/accreditor dossier drafts | propose | I5, coverage, Bloom | 🔵 NEW-10/13 |
| `dlu-inst-compliance-monitor` | G8 completeness, G12 RSI, G14 DE/DI ledger watching + alerts | act (alerts) / propose (filings prep) | ledgers, mirrors | 🔵 NEW-13 |
| `dlu-inst-registrar-assistant` | clearance checks (G11), recognition queue triage, committee scheduling (G6) | propose | GPS health, dossiers | 🔵 NEW-08 |
| `dlu-inst-capacity-planner` | HITL queue forecasts, session calendar feasibility (G2 minimums), faculty load balance | act (analytics) | F5, calendars | ⚪ K5 |
| `dlu-inst-funnel-assistant` | prospect nurturing content, application triage support (P01, CRM-side) | propose — **misrepresentation guard: claims checked against outcomes data (BOOK-19)** | CRM events, scorecard | ⚪ K5 |

## 2.4 Platform & knowledge operations

| Agent slug | Mission | Autonomy | Phase |
|-----------|---------|----------|-------|
| `dlu-ops-import-analyst` | legacy import semantic analysis (3-phase pipeline, human gates) | propose | ✅ services → agent K3 |
| `dlu-ops-kg-curator` | SAME_AS/duplicate review preparation, promotion QA, orphan triage | propose (faculty/ontologist confirm) | 🔵 K3 |
| `dlu-ops-integrity-sentinel` | integrity signal triage (similarity, anomalies) → human review prep; **never verdicts** (detector humility) | propose | ⚪ K4 |
| `dlu-ops-analyst` | anomaly summaries from observability (consumer lag, driver health) for ops | act (reports) | ⚪ K5 |

**Roster total: 24 agents** (9 student · 10 faculty/authoring · 6 institutional
· 4 ops, with absorptions). Every one requires: envelope owner, move bindings,
entitlements, harness pass (NEW-02) before GA.

---

# Chapter 3 — Skills Catalog

Seeded ✅ = present in `ai_university_defaults`. Format: *slug — function
[pattern] → used by*.

## dialogue
- `elicit-goals` — structured goal/persona elicitation [R4] → discovery 🔵
- `socratic-turn` — hint-ladder tutoring turn with state [R4] → tutor 🔵
- `explain-with-sources` — grounded explanation with citations [R1/R2] → tutor, navigator 🔵
- `handle-crisis-handover` — warm handover script (protocol-bound, non-generative core) [—] → all (ingress) 🔵 NEW-02

## content_gen
- `uni-clo-writer` ✅ — Bloom-levelled outcome drafting [R1] → curriculum-designer
- `uni-concept-extractor` ✅ — concept candidates from content [R3→staging] → enricher, kg-curator
- `uni-lesson-enricher` ✅ — lesson expansion with KG grounding [R2] → content-enricher
- `draft-blueprint` — module blueprint (FEX-shaped, DE/DI-classified per G14) [R1] → architect 🔵
- `generate-worked-example` — load-managed worked example [R1] → tutor 🔵
- `draft-remediation` — gap-targeted micro-content [R2] → coach/tutor 🔵

## assessment
- `uni-quiz-generator` ✅ — Bloom-targeted items (QTI-valid) [R1] → assessment-creator, assessor
- `uni-lab-exercise-generator` ✅ — lab/code exercises [R1] → assessment-creator
- `generate-formative-set` — outcome-aligned formative set [R1] → assessor 🔵
- `draft-viva-dossier` — weakest-link probe brief from evidence graph [R5] → viva-preparer 🔵
- `calibrate-item-analytics` — IRT-lite difficulty/discrimination summaries [R3] → assessor, QA ⚪

## feedback
- `uni-feedback-analyzer` ✅ — feedback quality analysis [R3] → coach (faculty-side)
- `uni-syllabus-analyzer` ✅ — syllabus alignment critique [R3] → curriculum-designer
- `uni-curriculum-gap-analyzer` ✅ — program gap analysis [R2/R3] → curriculum-designer, dean-briefer
- `give-feedforward` — feeds-forward learner feedback referencing model state [R3] → assessor, tutor 🔵
- `analyze-bloom-distribution` — assessment/course Bloom audit [R3] → faculty-coach 🟡 (service exists)

## summarization
- `uni-content-summarizer` ✅ — content summaries [R1] → study-assistant→tutor
- `summarize-session` — episodic session summary (M2) [R8] → ACE 🔵 NEW-03
- `distill-memory` — M2→M3 consolidation (cited, atomic) [R8] → ACE 🔵 NEW-03
- `digest-agent-activity` — envelope digest for faculty [R3] → envelope console 🔵 NEW-09

## extraction
- `parse-transcript` — external transcript → structured claims [R3, adversarial-aware] → recognition 🔵
- `parse-certification` — cert/badge → framework-mapped claim [R3] → recognition 🔵
- `map-experience-to-esco` — CV/work history → ESCO skill claims [R3] → recognition, career 🔵
- `detect-document-anomalies` — authenticity signals for review (M2 finding; never verdicts) [R3] → recognition 🔵

## planning_narration
- `narrate-scenario` — GPS scenario explanation from trace only [R7] → navigator 🔵
- `narrate-path-health` — ETA/health honest rendering [R7] → navigator, coach 🔵
- `compose-weekly-plan` — mission slate composition [R5] → coach 🔵
- `explain-recommendation` — ranking-trace narration (may not reorder) [R7] → all recommenders 🔵

## evidence
- `assemble-evidence-summary` — competency evidence timeline brief [R3] → credentialer, viva-preparer 🔵
- `draft-recognition-dossier` — claim dossier for registrar [R5] → recognition 🔵
- `annotate-integrity-case` — due-process case file prep [R5] → integrity-sentinel ⚪

## document_gen
- `generate-diploma-supplement` — DS (IT/EN, ELM) from evidence graph [R7-like: template over computed data] → registrar-assistant 🔵 NEW-08
- `generate-self-certification` — autocertificazione documents [template] → WS07 🔵 NEW-08
- `draft-teaching-register` — G4 register from delivery events [R7] → register-drafter 🔵 NEW-09
- `draft-qa-dossier-section` — self-study sections, evidence-linked [R5] → qa-writer 🔵

## analysis
- `assess-learner-state` — LearnerStateAssessment composition (typed) [R3] → ACE Diagnose 🔵 STX-06
- `score-readiness` — session/exam readiness from L4 [R3] → assessor, WS06 🔵 NEW-05
- `analyze-cohort-health` — belonging/engagement aggregates (n≥10) [R3] → success, dean-briefer 🔵
- `forecast-capacity` — queue/calendar forecasting [R3] → capacity-planner ⚪

## translation
- `uni-academic-translator` ✅ — academic register IT↔EN [R1] → localizer

## compliance
- `classify-de-di` — activity DE/DI classification (G14) [R3, rule-first] → compliance-monitor 🔵 NEW-13
- `check-rsi-coverage` — RSI plan vs ledger analysis (G12) [R3] → compliance-monitor 🔵 NEW-13
- `draft-disclosure` — G13/licensure disclosure text from policy objects [template] → compliance-monitor ⚪

**Catalog total: 44 skills** (10 seeded ✅, ~24 🔵 phased, rest ⚪). Every
skill: I/O schemas mandatory, ontology-linted prompts, testable via the
running `/skills/{id}/test`, bilingual template variants where learner-facing
(Review M5).

---

# Chapter 4 — MCP Server Catalog (the tool bus)

## 4.1 Internal kernel servers (wrap kernel APIs; agent-facing, entitlement-enforced)

| Server | Tools (manifest sketch) | Consumers | Phase |
|--------|------------------------|-----------|-------|
| `dlu-knowledge-graph` ✅ | query_concepts, get_prerequisites, get_plo_clo_map · **v2 adds:** get_frontier, get_gap, find_same_as_candidates | tutor, navigator, curriculum-designer, kg-curator | running → 🔵 STX-05 |
| `dlu-twin-context` | get_context(layers, purpose) — **entitlement matrix enforced server-side** | all student-facing (per BOOK-06 Ch. 6) | 🔵 STX-02 |
| `dlu-gps` | compute_scenarios, get_path_health, estimate_recognition | navigator, coach, registrar-assistant | 🔵 STX-07/12 |
| `dlu-evidence` | get_evidence_timeline, get_competency_state, submit_evidence_proposal | assessor, credentialer, viva-preparer, recognition | 🔵 STX-08 |
| `dlu-assessment-runtime` | list_sessions, get_readiness, create_formative, get_attempt_stats | assessor, coach, WS06 | 🔵 STX-11/NEW-05 |
| `dlu-credential-wallet` | evaluate_criteria, get_wallet, prepare_issuance, verify_external | credentialer, registrar-assistant | 🔵 STX-13 |
| `dlu-catalog` | search_programs, get_offerings(term), get_regulation_year_rules, **get_edition, simulate_path** (2 new tools, G15) | discovery, navigator, funnel-assistant | ✅ **delivered (NEW-16, 2026-07-27)** — `services/dlu_catalog_mcp/`, copying `dlu_badge_mcp`'s FastMCP structure (HTTP-only to the public REST surface, no direct DB access); all 5 tools genuinely new, including the 3 "base" ones this row had marked 🔵 since K3 despite never being built |
| `dlu-scheduler-notify` | book_office_hours, schedule_mission, send_notification (etiquette-enforced) | coach, success, registrar-assistant | 🔵 NEW-09 |
| `dlu-memory` | recall(query), propose_memory — **twin-keyed, ACE-mediated writes** | all (via ACE Perceive/Learn) | 🔵 NEW-03 |
| `dlu-document-gen` | render_ds, render_certificate, render_register | registrar-assistant, register-drafter | 🔵 NEW-08/09 |
| `dlu-ledgers` | get_rsi_status, get_dedi_status, get_ans_completeness | compliance-monitor, qa-writer | 🔵 NEW-13 |
| `dlu-institution-twin` | get_scorecard, get_program_health, get_posture | dean-briefer, qa-writer | 🔵 NEW-10 |

## 4.2 Generic capability servers

| Server | Tools | Notes | Phase |
|--------|-------|-------|-------|
| `dlu-web-search` ✅ | brave_web_search | scoped: authoring/career research only; **never a grounding source for course answers** (R1 uses course corpus) | running |
| `dlu-code-executor` ✅ | execute_python | sandboxed; tutor lab support, analytics skills | running |
| `dlu-rag-retrieval` | search_chunks(scope) — knowledge_scope enforced at index | tutor, enricher (formalizes existing RAG as MCP) | 🔵 K2 |

## 4.3 External / reference-data servers

| Server | Tools | Notes | Phase |
|--------|-------|-------|-------|
| `dlu-esco` | search_occupations, get_skills_for_occupation, crosswalk_skill | local snapshot, quarterly refresh (constitution) | 🔵 STX-12 |
| `dlu-case-frameworks` | list_frameworks, get_cfitem, import_preview | CASE registry access (model exists) | 🔵 STX-04 |
| `dlu-emrex` | request_transcript, verify_elmo | EU verified transcript exchange (Review M2) — recognition trust upgrade | ⚪ K5 |
| `dlu-plagiarism` | check_similarity | wraps running service; signals-only (detector humility) | 🟡 K3 |

**Rules (restated as binding):** driver systems (ESSE3, ERPNext, Moodle,
Stripe, PagoPA, QES) are **NOT MCP servers** — agents reach their data only
through kernel mirrors/APIs wrapped above (BOOK-10 Ch. 9 trust boundary).
Per-agent grants are tool-level, least-privilege; every server has health
tests (`/mcp-servers/{id}/test`, running) and a credential binding
(`llm_credentials`).

---

# Chapter 5 — Usage Modes & Management Model

1. **Composition flow (per agent):** pick preset class → bind skills → grant
   MCP tools (least privilege) → declare move bindings + entitlements +
   envelope defaults → `draft → testing (harness) → deployed` (BOOK-10 Ch. 6).
2. **Scope specialization:** e.g. a Medicine department deploys
   `dlu-student-tutor` (scope=dept) with clinical-case skills added and
   stricter integrity envelope — same platform agent, scoped row.
3. **Escalation economics:** skills declare their preset class; ACE may
   downgrade within quality bars (BOOK-09 Ch. 4); costs attribute per agent
   badge → engine → process area (NEW-14).
4. **Quota classes:** conversational (tutor/coach: per-learner daily),
   mission (nightly scans: cognitive budget), batch (media, imports:
   throughput), compliance (monitors: guaranteed floor — a quota-starved
   compliance monitor is itself an incident).
5. **Seeding v2:** `ai_university_defaults.py` evolves into the **catalog
   seeder**: this document is its source of truth; per-phase seed migrations
   add rows as sprints land (grandfathered `uni-*` slugs alias-windowed).
6. **Bilinguality (M5):** learner-facing skill templates ship IT+EN; harness
   runs both locales; ontology registry carries IT labels.

---

# Chapter 6 — Phasing & Traceability

| Phase | Agents landing | Skills landing | MCP landing |
|-------|----------------|----------------|-------------|
| K2 | discovery; faculty-coach/architect formalized | dialogue set, assess-learner-state, memory skills | twin-context, rag-retrieval, memory |
| K3 | navigator, coach, tutor, assessor, recognition; import-analyst/kg-curator/media-producer as agents | tutoring/assessment/planning/extraction sets | gps, evidence, assessment-runtime, catalog, esco, case, plagiarism |
| K4 | credentialer, success, career; register-drafter, viva-preparer; envelope-advisor; integrity-sentinel | evidence/document_gen sets, cohort analysis | credential-wallet, document-gen, scheduler-notify, institution-twin |
| K5 | compliance-monitor, dean-briefer, qa-writer, registrar-assistant, capacity-planner, funnel-assistant, ops-analyst | compliance set, forecasting | ledgers, emrex |

Each landing rides its BOOK-20 sprint; the harness (NEW-02) gates every GA;
this catalog's tables are the checklist the K-phase prompt packs enumerate.

---

# Annex — Seeded-to-Target Mapping

| Seeded today | Disposition |
|--------------|-------------|
| `uni-study-assistant` | absorbed by `dlu-student-tutor` + `dlu-student-coach` (STX-10); skills transfer; alias window one release |
| `uni-curriculum-designer` | continues; gains `draft-blueprint`, DE/DI classification (G14) |
| `uni-assessment-creator` | continues; converges with `dlu-student-assessor` faculty-side duties |
| `uni-content-enricher` | continues; becomes Gate-2-aware move executor |
| 10 `uni-*` skills | all retained; schemas hardened + bilingual variants |
| 3 MCP servers | retained; `dlu-knowledge-graph` extended v2 (frontier/gap tools) |

---

*BOOK-10A v1.0 — awaiting review. With this catalog approved, the K1 prompt
pack can be generated knowing exactly which intelligent components K2–K5 will
demand of the kernel foundations.*

---

## Annex T (target additions, v0.3 — sprints NEW-31, NEW-33)

Five persona-support agents extend the roster (24 → 29). All are ACP-composed
(a row in `ai_agent_configs` + linked skills/MCP/presets — no separate
"composition" machinery), **propose-only** (no autonomous acts on careers,
money, or grades), carry contract cards, and pass a dedicated eval-harness
dataset (≥20 golden cases each, BOOK-11 Ch. 6's T11 golden-set gate — see
below for the one correction to this annex's own original text). Envelopes
apply only where the agent actually has pedagogical moves to scope (Student
Companion) — `envelope_defaults`/`FacultyEnvelope` are both structurally a
move-catalog construct (BOOK-09 Ch. 3), not a generic per-agent policy knob;
the other 3 have no pedagogical moves at all, so "run under envelopes" does
not apply to them (an honest non-applicability, not a gap).

**NEW-31 (SPRINT-19) implements the first 4 rows below** — all registered
`lifecycle_state="testing"` (same posture as the 9 ACE agents, never
auto-promoted this sprint), each with a populated `contract_card`
(`{purpose, powers, limits, escalation}`, `platform.ai_agent_configs.
contract_card`) and a passing T11 golden-set dataset
(`backend/evals/domain_agent_fns.py` + `scripts/eval_datasets/*.jsonl` —
the SAME SPRINT-17 mechanism used for `generation`/`admission_evaluation`/
`nudging`, not the twin-bound `harness.py::run_gate` PDDAEL scenario-bank
gate, which structurally does not fit 3 of these 4 non-twin agents).
Persistence is via a new, generic `ai_agent_proposals` table
(`ai_agent_proposal_service.py`) — never a direct domain write; a CFO
Analyst proposal is a drafted rationale for a human to file via the
existing `governance_actions` "File governance action" flow (BOOK-24 §3),
never filed by the agent itself. **Row 5 (Research Assistant) belongs to a
separate, later sprint (NEW-33)** — untouched by NEW-31.

**NEW-33 (SPRINT-21) implements row 5** — same `lifecycle_state="testing"`
posture, same `contract_card` shape, same T11 golden-set mechanism
(`research_assistant.jsonl`, 22 real golden cases) — resolved as the
correct eval mechanism for this row too (not `harness.py::run_gate`,
which structurally doesn't apply here either — no `scenario_bank/
research_assistant.yaml` exists; SPRINT-21.md "Correzioni al piano" #10).
Its "citation" decision core (`_match_claims_to_citations`) is pure/no-I/O,
same discipline the other 4 rows' cores already established. Roster is now
**29/29** — Annex T fully delivered.

| Agent | Persona | Scope | Surfaces |
|---|---|---|---|
| Student Companion (consolidated) ✅ NEW-31 | Student | missions, nudging, objectives, admission/pre-eval status; twin context `purpose=self` | Companion Workspace |
| Faculty Assistant ✅ NEW-31 | Teacher | teaching-ops drafts (register G4, milestone-deliverable review reminders); authoring-suggestion (FEX/CLO-MLO) scope from the original plan narrowed to teaching-ops this sprint (disclosed) | Faculty Teaching Register |
| Admin Copilot ✅ NEW-31 | Back-office | explains pre-eval sheets and applied rules (deterministic summary of already-decided `PrevalSheet` facts, never re-decides a tier/verdict); dossier/checklist assistance and certificate drafts (G9) remain target | Preval Desk |
| CFO Analyst ✅ NEW-31 | CFO | ranks variance breaches / cash alerts and drafts a rationale; every actual filing still routes via `governance_actions`, always a human `record_action` call, never this agent | CFO Command (BOOK-24) |
| Research Assistant ✅ NEW-33 | Researcher | literature review with verifiable citations (every claim resolves to a source chunk), structured extraction from corpora, drafting support; no writes to project state | Research Workspace (BOOK-25) |

Also part of NEW-31: the uniform "AI proposal" affordance (accept / modify /
reject with reason, `ds/AIProposalCard` + new shared `AgentProposalQueue`),
wired onto all 4 surfaces above — "modify" resubmits the same payload this
sprint (no payload-editing UI yet, disclosed); rejections are durably
recorded with their reason on the `ai_agent_proposals` row itself (feeding
the eval datasets is aspirational per this annex's original text — not
literally wired this sprint, an honest correction).
