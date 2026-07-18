# Sprint STX-12 — Recognition Agent + Full Scenario Set + WS02
### DAS K3 · self-contained prompt · target: `dlu_builder_tk` · depends: NEW-04 (Pareto engine, RECOGNIZE edges), STX-08 (dossier ingress), K2 (gate)

## Role
`backend-dev` + `frontend-dev`, with an opus-class design review on the
yield estimator and hedged-plan semantics before implementation (DAS
BOOK-14 Ch. 2/4/8; BOOK-10 Ch. 3 card; BOOK-17 WS02).

## Context — read before coding
1. BOOK-14 Ch. 4 — the differentiator, binding: recognition as
   **portfolio optimization**, not paperwork. Claim inventory →
   `RECOGNIZE` edges with `⟨effort, probability, yield⟩`; yield
   estimation from syllabus similarity (embeddings + AKN mapping of
   `ExternalCourse` data), framework crosswalks (CASE/ESCO), policy caps
   (max recognized credits, G7 applicability), and **historical
   adjudication data** calibrated per BOOK-09 Ch. 7. Strategy output =
   contingent routing: main line + hedges (*"if claim #3 is rejected,
   the fallback adds one term"*).
2. **HITL boundary (constitutional, Ch. 4.2):** the GPS plans with
   probabilities; **humans decide the facts**. Claims are prepared by
   the agent (propose), adjudicated by the registrar (reserved —
   committee flows where policy requires, via NEW-06's aggregate).
   Expected yield MUST NOT render as granted credit — probability
   honesty (Ch. 8.4: calibrated hedging, refreshed from the registrar's
   actual decision history).
3. Ch. 4.3 claim taxonomy (open by design): other universities
   (transcripts), certifications (framework-mapped), MOOCs/
   micro-credentials (OB 3.0/CLR import matures in K4/BOOK-16), work
   experience (ESCO occupation history → `evidenced` ceiling until
   humanly verified), portfolio artifacts — each with its trust weight
   and adjudication path.
4. **Scenarios 2–4 go learner-real here** (pack decision, README):
   NEW-04 built the Pareto machinery; this sprint wires the live
   inputs — `best_career_path` (L5 ESCO goals → competency map,
   `DEVELOPS` strengths), `lowest_cost` (per-course cost from the
   ERPNext mirror + recognized credits), `highest_competency_growth`
   (StudentCompetency state + `DEVELOPS` gains) — and adds **hedged
   plans** (scenarios carry contingency branches for uncertain claims;
   a rejection activates the hedge, framed per compassionate
   recalculating).
5. Existing (repo-verified): `ExternalCourse` data + document processing
   + plagiarism service (BOOK-14 Annex ✅); embedding infrastructure
   (pgvector convention — `academic_embedding_service`, NEW-03's
   episodic vector service as the pattern); CASE import (STX-04) + ESCO
   references on L5; NEW-04's `RECOGNIZE`/`CHALLENGE` edge seam +
   Pareto engine; STX-08 pipeline (dossiers enter as `prior_learning`,
   trust 0.4, ceiling `evidenced`); NEW-02/NEW-03 calibration machinery
   (M4 state — reuse for adjudication-history calibration);
   `agent_proposals`/HITL queue; new-agent lock-step rule (seed row
   `recognition`, `AGENT_ENTITLEMENTS` addition — card reads L1/L3 +
   submitted documents, `move_bindings`: `recognize_prior`,
   `explain_concept`). Migration chains off the current head.
6. **Recognition-first onboarding** (BOOK-17 Ch. 3): the Transfer/
   professional persona lands on WS02 *first* — recognition-first
   routing made experiential; a Discovery hand-off
   (`recognize_prior` trigger) opens the flow.

## Deliverables
1. **Recognition Agent** (propose only): seed row (`recognition`,
   `testing`); transcript/document parsing → candidate claims; syllabus
   comparison (embedding similarity + AKN mapping); dossier drafting
   (R5 deliberation, traced) into the registrar HITL queue; committee
   routing where institutional policy requires (NEW-06 aggregate —
   integrate if landed, typed seam if not).
2. **Claim inventory**: persistent claim records (additive migration —
   `recognition_claims` per BOOK-14 Ch. 9/C7-C8) with per-claim
   `⟨effort, probability, yield⟩`; **position potential** quantified on
   the twin fix (*"up to N ECTS may be recognizable"*) — uncertainty as
   a first-class, honestly-bounded number.
3. **Yield estimator**: similarity + crosswalk + policy caps +
   **adjudication-history calibration** (per-claim-class predicted vs
   granted, M4-style state; refreshed on every registrar decision —
   outcome tracking for adjudication, the second real BOOK-09 Ch. 7
   loop after STX-11's readiness).
4. **Scenarios 2–4 + hedged plans**: live inputs wired into NEW-04's
   engine; every scenario can carry hedge branches (claim rejected ⇒
   fallback line pre-computed); rejection events activate the hedge and
   reroute per compassionate-recalculating framing; recognition plan
   rendered inside every scenario card (file order, expected yield ±
   band, timeline).
5. **Evidence integration**: filed claims enter STX-08 as
   `prior_learning` (trust 0.4, ceiling `evidenced`); registrar grants
   convert to official evidence + position jump + reroute; denials
   activate hedges — **no path auto-verifies**.
6. **WS02 Credit Recognition (Plan)**: triad — Canvas: claim inventory,
   yield estimates (hedged bands, never "granted"), dossier status,
   hedge structure; Companion: Recognition bias; Missions: upload
   documents, file claims, track adjudication. Transfer persona lands
   here first (onboarding order per persona). Advisors see the hedge
   structure (`purpose=staff_view`, audited).
7. **NEW-02 coverage + gate**: scenario classes incl. the
   over-promising pressure case ("so I'll get 24 credits, right?" ⇒
   calibrated hedging holds, no yield-as-fact) — green + steward-signed
   before any `deployed` transition.

## Verifications
- **V1** claims never auto-verify: no execution path moves a
  recognition claim to granted/`verified` without a human act (negative
  tests: API, mission, pipeline; the registrar HITL act is the only
  door).
- **V2** hedge activation on a rejection fixture: the pre-computed
  fallback becomes the main line, `path.replanned` only on adoption,
  learner copy passes the compassionate-recalculating rule (no loss
  language).
- **V3** probability honesty: expected yield renders with calibrated
  bands everywhere (API contract test — no unhedged yield figure in any
  payload); adjudication calibration updates on a fixture registrar
  decision.
- **V4** scenarios 2–4 deterministic + fingerprinted: each named
  scenario reproducible from its fingerprint; Pareto frontier ≤ 8,
  non-dominance holds with real inputs.
- **V5** dossier ingress: a filed claim appears in STX-08 as
  `prior_learning` trust 0.4 with ceiling `evidenced` (negative test on
  `mastered` via dossier alone).
- **V6** harness green (gate) incl. over-promising scenario ·
  `pytest -m phase1` green · migration up/down/up clean · STX-07/NEW-04
  V-suites still green (the GPS contract held through three sprints).

## DoD
V1–V6 green · BOOK-14 Annex (recognition inputs, scenarios engine full
set) + BOOK-10 nine-agents row updated · constitution §9.2 marked fully
implemented · TRACEABILITY K3 row updated · design-review note (yield
estimator + hedge semantics) in `docs/sprint_decisions_*.md` · next:
NEW-06 committee flows adjudicate where policy requires; K4 wallet
import extends the claim taxonomy.
