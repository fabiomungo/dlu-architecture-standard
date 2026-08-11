# Masterbook Update — EKG v1.1 · ATA 1.0 · Course Exchange Format v2.0

> Authoritative change-set that folds three inputs into the DLU Architecture Standard (Masterbook BOOK-00 … BOOK-26):
> **(1)** the DLU Architecture Suite **EKG v1.1** (already mapped in `DAS_EKG_INTEGRATION_PLAN.md`); **(2)** the Suite's new
> **ATA 1.0 — Adaptive Tutor Architecture** (`DLU_EKG_Suite/ATA/`); **(3)** the **DLU Course Exchange Format v2.0** and the
> updated **DLU Course Builder v2.0** (`dlu_builder_tk/docs/DLU_Course_Exchange_Format_v2.0.md`).
> This document says *what changes in every Book and connected artefact*; per-Book addenda are appended to the Book files.
> Date: 8 August 2026. Precedence on conflict: BOOK-00 (constitution) > Suite blueprints (detailed spec) > Turnkey `CLAUDE.md`.

---

## 1. What ATA 1.0 adds (summary)

**Core principle.** The Tutor does **not** retrain the LLM per learner. It continuously updates the **Student Learning Digital Twin** and improves a **versioned Pedagogical Policy** from measured outcomes:

`Student State + Goal + EKG + Evidence + Pedagogical Policy → Next Best Learning Action (NBLA) → Tutor Intervention → Outcome → State update`

**Eight non-negotiables:** (1) stateless Tutor runtime, state external; (2) mastery ≠ confidence; (3) a conversational turn creates only an *informal signal* — only *qualified evidence* updates high-stakes mastery; (4) pedagogy is explicit and **versioned** (the LLM does not own pedagogy); (5) optimise **learning gain & retention**, not engagement; (6) production policy changes require **offline evaluation + controlled rollout**; (7) every recommendation is **explainable** from goal, knowledge state and graph dependencies; (8) all retrieval/memory is **tenant- and learner-authorised**.

**Tutor platform (DSA/250):** Tutor Orchestrator · Student Model Service · Goal Service · **Pedagogical Policy Engine** · GraphRAG Service · Memory Service (working/episodic/preference) · Mastery Engine · Tutor Evaluation Service · LLM Gateway · Event Bus. Degraded-mode fallback to course-grounded, non-adaptive assistance.

**Policy Engine:** selects NBLA from 14 actions (EXPLAIN, SIMPLIFY, ELABORATE, SCAFFOLD, SOCRATIC_QUESTION, WORKED_EXAMPLE, HINT, PRACTICE, REVIEW_PREREQUISITE, REMEDIATE, CHALLENGE, REFLECT, ASSESS, REASSESS). Versioned score `Score(a)=Σ wᵢ·featureᵢ − penalties`; evolution V1 rules → V1.5 offline counterfactual → V2 contextual bandit → RL (governed, constrained). Reward composite (illustrative): learning gain 40% · retention 20% · goal 15% · assessment 10% · engagement 10% · satisfaction 5%. Deployment: Draft→simulation→shadow→A/B→academic review→approved→canary→production→monitor→rollback.

**EKG extension (11 nodes / 12 edges):** nodes `LearningGoal, LearningIntervention, LearningStrategy, TutorSession, TutorTurn, LearningEpisode, Misconception, Recommendation, LearningPlan, TutorEvidence, PolicyVersion`; edges `HAS_GOAL, TARGETS, HAS_SESSION, CONTAINS_TURN, USES_STRATEGY, TARGETS_KNOWLEDGE, PRODUCES_SIGNAL, SUPPORTS(→MasteryObservation), SUGGESTS(→Misconception), REMEDIATES, RECOMMENDS, GENERATED_BY_POLICY(→PolicyVersion)`.

---

## 2. New / promoted ADRs (BOOK-00 Ch.9)

| ADR | Decision | Status |
|-----|----------|--------|
| **ADR-0019** | EKG is a platform subsystem, not a DB feature *(renumbered — 0014 was taken)* | **Proposed** |
| **ADR-0020** | Experience **Lens** is a governed projection contract *(renumbered — 0015 was taken)* | **Proposed** |
| **ADR-0016** | **Pedagogy is explicit and versioned**: the Pedagogical Policy Engine chooses the NBLA; the LLM renders it. Policy changes require offline evaluation + controlled rollout; RL only under governance with a constrained action space. | **Proposed** |
| **ADR-0017** | **Course Exchange Format v2.0** is the authoritative projection source for the EKG Academic/Knowledge/Assessment layers; v1.3 supported via adapter. | **Proposed** |
| **ADR-0018** | **Tutor state is external & stateless-runtime**: learner state lives in EKG/mastery/memory/goals; a conversational turn is an informal signal, not qualified evidence. | **Proposed** |

Promote ADR-0009/0010/0013 to Accepted per `DAS_EKG_INTEGRATION_PLAN.md` §4.1.

---

## 3. Per-Book impact & delta (addenda appended to each Book)

| Book | Impact | ATA / EKG / Course v2.0 delta |
|------|--------|-------------------------------|
| **00** Executive Vision | Med | Add ATA to the AOS picture; ADR-0016/0017/0018; glossary (NBLA, Pedagogical Policy, Student Learning Twin, Course Format v2.0); Ch.14 KPIs gain tutor learning-gain/retention SLOs. |
| **01** Philosophy | Low-Med | CAT stages ↔ tutor strategies (scaffolding→worked-example→practice→reflect); desirable-difficulty realised by adaptive difficulty (AIP-14). |
| **03** Academic OS | **High** | Add Tutor platform services (Orchestrator/Policy/Student-Model/Memory/Evaluation) as AOS processes; event topics `dlu.tutor.*`. |
| **04** Domain Model | High | New aggregates: LearningGoal, TutorSession/Turn, LearningIntervention, Misconception, LearningPlan, PolicyVersion, TutorEvidence. |
| **05** Ontology | **High** | Register ATA EKG extension (11 nodes/12 edges) + pedagogical ontology (strategies) in `dlu-core.yaml`; Course v2.0 outcome/concept/skill identity. |
| **06** Student Digital Twin | **High** | The **Student Learning Digital Twin** is the tutor-facing twin projection (goals+mastery+misconceptions+memory); mastery≠confidence. |
| **09** ACE | **High** | ACE hosts the Tutor Orchestrator; NBLA selection is Policy-Engine-owned; ACE renders, never owns pedagogy. |
| **10/10A/10B** AI Workforce | Med-High | Tutor personas: Adaptive/Diagnostic/Socratic/Practice Tutor + Learning Advisor; delegated capability tokens; AIP-11…16. |
| **11** AI Cognitive Arch. | **High** | GraphRAG tutor pipeline + retrieval policies; Tutor Evaluation framework (offline counterfactual, propensity logging, bandit gating). |
| **12** Memory | **High** | Tutor Memory Semantics: working/episodic/preference memory; salience/expiry; tenant/learner-authorised. |
| **13** Knowledge Network | **High** | Add ATA nodes/edges over the graph; `TutorEvidence SUPPORTS MasteryObservation`, `SUGGESTS Misconception`. |
| **14/14A** GPS / Credit | **High** | LearningPlan ↔ LearningPath; NBLA vs deterministic path (GPS plans, Policy sequences interventions); credit unaffected. |
| **15** Assessment & Evidence | **High** | Informal signal vs qualified evidence rule; TutorEvidence is a distinct evidence source that cannot override authoritative grades; Course v2.0 assessment→evidence model. |
| **16** Credential & Trust | Med | unchanged core; Course v2.0 credential/OB export path. |
| **17** Experiences | **High** | Tutor screens (stu_13 session, stu_14 diagnosis, stu_15 plan); AIP-11…16; Lens rules apply; Paper Design 3.0 + component library (200-components), accessibility (900). |
| **18** Technical/Turnkey | **High** | Tutor microservices, `tutor-openapi.yaml`/`tutor-schema.graphql`/`tutor-asyncapi.yaml`; Course Builder v2.0 + Exchange Format v2.0 export/import; Frappe DocTypes. |
| **19** Governance/Sec/Compliance | **High** | Policy governance (offline eval, controlled rollout, academic review, rollback); tenant/learner authorisation for memory/retrieval; AI-Act high-risk mapping for adaptive steering. |
| **20** Blueprint | **High** | Add ATA waves/sprints to the roadmap (see `ROOCODE_EKG_PROMPTS.md` W3-ATA); Course Format v2.0 sprint. |
| **21–26** (drafts) | Low | 26 (Accreditation/DM1154) consumes tutor learning-gain signals as quality evidence; others unaffected. |

Lightly-impacted Books get a pointer addendum; High-impact Books get the concrete delta above appended.

---

## 4. Course Format v2.0 into the Masterbook

- **BOOK-15/17/18**: the authoring artefact is now `DLU Course Exchange Format v2.0` (Course→Module→Lesson→Resource; first-class outcomes/concepts/skills; assessment→evidence). It is the **projection source** for BOOK-05/13/15. The Course Builder v2.0 imports v1.3 (adapter) and validates graph invariants at export. See `dlu_builder_tk/docs/DLU_Course_Exchange_Format_v2.0.md` + `dlu_course_exchange_v2.0.schema.json`.
- **Content standard** (STU process v2.1 §9) retained; checkpoints renamed `design_approval/academic_acceptance/technical_publication` with v1.3 alias.

---

## 5. Connected artefacts updated in this change set

| Artefact | Update |
|----------|--------|
| `CHANGELOG.md` (standard) | add "EKG v1.1 + ATA 1.0 + Course v2.0" entry |
| `MASTERBOOK-INDEX.md` | note ATA cross-cut + Course v2.0; link this change-set |
| `GLOSSARY.md` | NBLA, Pedagogical Policy, Student Learning Digital Twin, Misconception, LearningIntervention, PolicyVersion, Course Format v2.0 |
| `TRACEABILITY.md` | ADR-0016/0017/0018 → Books → sprints → checks |
| `DAS_EKG_INTEGRATION_PLAN.md` | ATA + Course v2.0 sections + updated impact matrix |
| `dlu_builder_tk/docs/ROOCODE_EKG_PROMPTS.md` | **W3-ATA sprints** (Tutor platform, Policy Engine, evaluation) + **EKG-W1-07 Course Format v2.0** |
| `dlu_builder_tk/docs/BACKLOG_TARGET.md` | ATA epics under Wave 3 + Course v2.0 story under Wave 1 |
| `dlu_builder_tk/docs/ER_MAP_TARGET.md` | ATA graph extension diagram + tables |
| `dlu_builder_tk/docs/ALBERO_DI_FUNZIONALITA_TARGET.md` | new area **M. Adaptive Tutor (ATA)** |
| `dlu_builder_tk/docs/skills/ekg-tutor/` | new skill for tutor/policy work |

---

## 6. Sync duty (BOOK-00 governance)

Every Book addendum, the glossary, `TRACEABILITY.md` and this change-set move **together**. Silent divergence between standard and Suite/Turnkey is a conformance failure. The ATA reference lifecycle (`Expert policy → pilot → evidence → offline eval → controlled experiment → approved version → rollout → monitoring`) is the governed path for any pedagogical-policy change and is bound by BOOK-19.

---

### Correction (ADR numbering) — 2026-08-08
`architecture/adr/` already uses **ADR-0014** (identity-reconciliation) and **ADR-0015** (gate-numbering-reconciliation). The EKG-subsystem and Lens decisions referenced earlier as "ADR-0014/0015" therefore take **fresh numbers: ADR-0019 (EKG is a platform subsystem)** and **ADR-0020 (Experience Lens is a governed projection contract)** — to be authored as files. The three ADRs authored in this change set are the free numbers **ADR-0016 / ADR-0017 / ADR-0018**.
