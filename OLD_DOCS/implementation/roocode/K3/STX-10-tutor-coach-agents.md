# Sprint STX-10 — Subject Tutor + Learning Coach + WS04/WS05
### DAS K3 · self-contained prompt · target: `dlu_builder_tk` · depends: STX-09 (slates), K2 (both agents ship through the NEW-02 gate)

## Role
`backend-dev` + `frontend-dev` (DAS BOOK-10 Ch. 3 contract cards;
BOOK-11 R4; BOOK-01 P2/P4; BOOK-17 WS04/WS05).

## Context — read before coding
1. BOOK-10 Ch. 3 cards, binding:
   - **Subject Tutor** — moves `elicit`, `hint`, `worked_example`,
     `explain_concept`, `check_retrieval`, `give_feedback`, `challenge`;
     reads **L4/L7 + course context, never L5/L6** (BOOK-06 entitlement);
     GraphRAG-grounded (R2), misconception diagnosis, struggle-zone
     dialogue; knowledge scope: **enrolled courses only**; autonomy:
     act, inside the faculty envelope (giveup thresholds, tone, source
     restrictions — NEW-01 `envelope_defaults`).
   - **Learning Coach** — moves `check_retrieval` (scheduling),
     `encourage`, `recommend_next`, `celebrate`; reads L4/L6/L7 (+L2
     pacing); weekly plan composition, review-mission assembly (SM-2 due
     queue), habit reflection; autonomy: act (low-stakes nudges); quiet
     hours + wellbeing guardrails (BOOK-01 Ch. 10) + proactivity
     etiquette (BOOK-17 Ch. 7.2: ≤ 3 proactive contacts/day reference,
     digests preferred).
2. BOOK-11 R4 (Socratic dialogue policy), the sprint's core discipline:
   **dialogue state tracked symbolically** — hint-ladder position +
   giveup counter live in typed state (M1 blackboard within a cycle,
   M2/M4 across turns), never inferred from chat history; each turn is
   a fresh move decision through the NEW-01 preconditions engine — no
   drifting free chat.
3. Existing (repo-verified): `learner_tutor_service.py` (🟡 per BOOK-11
   Annex — the R4 upgrade target: add symbolic ladder state, don't fork);
   GraphRAG retrieval + `kg_query_service`; `spaced_repetition_service`
   (SM-2 — `get_due_reviews` is the Coach's mission source); STX-09
   slates (review missions compete there); ACE runtime — new-agent
   lock-step rule: seed row (pattern `seed_discovery_agent`),
   `AGENT_ENTITLEMENTS` (`subject_tutor → {L4,L7}` already reserved —
   reuse the exact key; add the Coach's), `move_bindings` from the closed
   catalog; `WORKSPACE_AGENT_BIAS` currently maps only `ws00` — extend
   for WS04/WS05; existing tutor UI + `StudentCoursePlayer`,
   `StudentProgress` components for WS04 reuse.
4. **K2 debt intake (README): `MOVE_CONSULTS` is empty** — the L4
   blackboard escalation is fixture-tested only. This sprint populates
   it with the first real consult pair (e.g. Tutor's `recommend_next` /
   struggle escalation consults the Coach's pacing view;
   `synthesize_blackboard` already exists). Unresolved propose-tier
   objections go to the HITL queue with both positions (BOOK-09 §5.3).
5. BOOK-01 P4 (desirable difficulty / productive struggle): the Tutor
   MUST let the learner work before helping — the struggle-zone policy is
   *withhold within bounds, then escalate the ladder*; giveup threshold
   is an envelope knob faculty control per course.

## Deliverables
1. **R4 symbolic dialogue engine** (upgrade `learner_tutor_service` in
   place): typed `TutorDialogueState` — ladder position
   (elicit → hint₁…hintₙ → worked_example), giveup counter, misconception
   tags; persisted across turns (M4/L1-cache discipline from NEW-03);
   every turn re-enters the Decide phase (preconditions read
   `LearnerStateAssessment` only); ladder never skips levels downward
   into answer-giving while the struggle-zone window is open.
2. **Subject Tutor agent**: seed row (`subject_tutor`, `testing`),
   bindings per card, envelope defaults (giveup threshold, tone, source
   restrictions); R2 grounding — content claims carry `_grounding_refs`
   from enrolled-course scope only; entitlement enforcement L4/L7 (+
   course context), L5/L6 structurally denied.
3. **Learning Coach agent**: seed row (`learning_coach`, `testing`),
   bindings per card; review-mission assembly from the SM-2 due queue as
   first-class recommendations (STX-09 slates — **compete equally**, no
   privileged lane, no separate queue); weekly plan composition
   (mission-shaped, kernel-object-bound); quiet hours + daily contact
   cap enforced in the proactive path (`ace.run_mission`).
4. **First real L4 consult**: populate `MOVE_CONSULTS` for the chosen
   Tutor↔Coach pair; typed contributions through
   `synthesize_blackboard`; objection path → HITL with both positions.
5. **WS04 Learning (Learn)**: triad — Canvas: course player + progress +
   pacing (reuse `StudentCoursePlayer`/`StudentProgress`); Companion:
   Coach bias; Missions: today's plan, resume, review debt.
   **WS05 Personal Tutor (Practice)**: triad — Canvas: tutoring session
   with the **hint ladder visible** (the learner sees where they are on
   it — P4 made experiential); Companion: Tutor bias; Missions: practice
   sets, struggle sessions.
6. **NEW-02 coverage + gates**: scenario-bank classes for both agents
   (incl. struggle-zone: the "just give me the answer" pressure scenario
   must hold the ladder; Coach: quiet-hours + wellbeing guardrail
   scenarios); both agents green + steward-signed before any `deployed`
   transition.

## Verifications
- **V1** hint-ladder state machine: property tests — position only
  advances per policy, giveup threshold triggers worked_example/
  refer_to_human (never silent answer-giving), state survives turn
  boundaries symbolically (no chat-history inference).
- **V2** Tutor entitlements: L5/L6 read attempts denied + audited
  (negative test through the single door); content grounding refs ⊆
  enrolled-course scope (out-of-scope question ⇒ abstain/refer, not
  invention).
- **V3** review missions compete equally in slates: an SM-2 due item
  ranks by the same stage-2 weights as other candidates (no privileged
  lane, no bypass of idempotency).
- **V4** struggle-zone: fixture dialogue — help withheld within the
  policy window (elicit/hint₁ before hint₂), envelope giveup knob
  respected; "answer now" pressure scenario holds the ladder (harness).
- **V5** L4 consult: the populated `MOVE_CONSULTS` path produces typed
  contributions in the trace; a propose-tier objection lands in HITL
  with both positions (real path, not the K2 fixture).
- **V6** Coach etiquette: proactive missions respect quiet hours + the
  daily cap (fixture clock); wellbeing guardrail scenario green.
- **V7** both agents' harness runs green (NEW-02 gate) ·
  `pytest -m phase1` + existing tutor routes green (strangler) ·
  migration (if any) up/down/up clean.

## DoD
V1–V7 green · BOOK-10 nine-agents rows (Tutor, Coach) + BOOK-11 R4 Annex
row updated · constitution §8.2/§15 (WS04/WS05) marked implemented ·
TRACEABILITY K3 row updated · decisions note (consult-pair choice, giveup
defaults) · K2 debt items `MOVE_CONSULTS` + agent-seeding marked
retired in the K3 exit report.
