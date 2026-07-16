# Sprint NEW-02 — Eval Harness + Crisis Protocol (**gates all agent GA**)
### DAS K2 · self-contained prompt · target: `dlu_builder_tk` · depends: STX-06 runtime (traces); build in parallel from day 1

## Role
`backend-dev` with opus-class design on the scenario bank and gate policy
(hard to reverse), `test-writer` for the deterministic suite
(DAS BOOK-11 Ch. 5–6; BOOK-10 Ch. 6).

## Context — read before coding
1. BOOK-11 Ch. 6.1 — scenario classes (core moves ×3 bands, struggle/hint
   ladder, wrong-answer anti-sycophancy, grounding-absent abstain,
   injection/RAG poisoning, crisis, consent/privacy, vocabulary/explanation,
   equity slices); Ch. 6.2 three grader tiers; Ch. 6.3 gate thresholds;
   Ch. 6.4 shadow evals. Ch. 5.1 ingress (crisis check can NEVER be
   disabled), Ch. 5.3 egress set.
2. Existing: `mock_llm_service.py` (deterministic pipeline runs),
   `moderation_service.py`, `ai_agent_configs.lifecycle_state`
   (draft/testing/deployed/deprecated), ACE traces (STX-06), STX-02 twin
   fixtures pattern (tests), gateway shadow-mode precedent (ACP-GW-06).
3. **Zero-tolerance classes**: crisis, injection, academic integrity —
   a single failure blocks deployment, not negotiable, not weighted.

## Deliverables
1. **Scenario bank** `backend/evals/scenario_bank/` — versioned in-repo
   corpus: YAML/JSON scenarios, each = twin fixture (synthetic learner
   state) + trigger + expected move class + quality rubric + trap.
   Minimum coverage per BOOK-11 Ch. 6.1 table for every learner-facing
   agent (start: Discovery + Companion). Bank loader validates scenario
   schema; every production incident later becomes a scenario (pipeline in
   deliverable 6).
2. **Graders** `backend/evals/graders.py`, three tiers all recorded:
   deterministic (trace-schema validity, citation presence, knowledge-scope
   compliance, `events[]`/`memory[]` taxonomy validity, expected move
   class); model-graded rubrics (pedagogical quality — grader prompts
   versioned in-repo, spot-audit hook); human-sampling queue (stratified
   sample per release → steward review via the HITL queue).
3. **Gate wiring**: `backend/evals/harness.py` `run_gate(agent_config_id)
   -> GateResult`; ACP lifecycle transition `testing → deployed` REQUIRES a
   green gate run recorded against the release (extend the agent-config
   deploy route: 409 without it; result attached to the release record;
   steward sign-off field). Thresholds: 100% deterministic · rubric ≥ release
   floor per class · **zero crisis/injection/integrity failures** · equity
   slice deltas within bounds · calibration seed present.
4. **Crisis protocol** (ingress, BOOK-11 Ch. 5.1): detector service
   (pattern + classifier via moderation service) wired BEFORE the cycle
   proceeds; on hit → immediate `refer_to_human`, warm-handover message,
   institutional support-pathway config (per-tenant table, additive
   migration), incident logged with restricted visibility, Success-watch
   follow-up event. Agents MUST NOT attempt counseling. The check is
   structurally non-disableable (no config path can turn it off —
   negative-tested).
5. **Education-specific egress set** (BOOK-11 Ch. 5.3): academic-integrity
   stance (graded-work full-solution requests get scaffolding, envelope-
   tunable but never off for summative), anti-sycophancy check,
   over-scaffolding detector, grounding-fidelity spot score, hedging/tone.
   Egress hit: block-and-regenerate once → `abstain`/`refer_to_human`;
   all hits logged; repeated hits auto-throttle the agent.
6. **Shadow-eval sampler**: Celery beat sampling live cycle traces,
   re-scored by the graders (the gateway-cutover shadow pattern);
   drift alarms (rubric, grounding, deferral rate) to Prometheus +
   alert rules file; incident→scenario pipeline (one real incident
   fixture added to the bank as proof).

## Verifications
- **V1** deployment gate: a config with one seeded crisis (or injection or
  integrity) failure CANNOT transition to `deployed` (409, negative test);
  green run transitions and records the result + signer.
- **V2** the full deterministic suite runs green on `mock_llm_service` in
  CI (no network, reproducible).
- **V3** incident→scenario: the pipeline converts a logged incident into a
  bank fixture; the new scenario runs in the next gate.
- **V4** shadow sampler re-scores live cycles (integration on dev stack);
  drift metric exported.
- **V5** crisis ingress: distress fixture mid-tutoring ⇒ warm handover
  rendered, human pathway notified, incident restricted-logged, NO
  model-generated counseling; disable attempts rejected (negative).
- **V6** `pytest -m phase1` green.

## DoD
V1–V6 green · scenario bank versioned + coverage table documented ·
**TRACEABILITY K2 row: "harness gates wired to ACP lifecycle; crisis
protocol zero-tolerance" satisfied** · BOOK-11 Annex rows ✅ · Discovery/
Companion may now GA (lifecycle → deployed) if their runs are green.
