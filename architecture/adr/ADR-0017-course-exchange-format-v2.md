# ADR-0017 — Course Exchange Format v2.0 is the authoritative EKG projection source

Status: Accepted (2026-08-09, implemented — EKG-W0-01…W6-08, see TRACEABILITY.md)
Related: ADR-0015 (gate-numbering reconciliation), BOOK-05, BOOK-13, BOOK-15, BOOK-17, BOOK-18
Source: `dlu_builder_tk/docs/DLU_Course_Exchange_Format_v2.0.md`, `dlu_course_exchange_v2.0.schema.json`, `DLU_Course_Builder_v2.0.html`, STU Digital Course-Creation Process v2.1

## Context

The DLU course artefact (Exchange Format v1.3: Course → Section → Page → Component) is structurally sound but semantically thin: it lacks a concept/prerequisite layer, stable outcome/skill identity, framework mappings and a structured assessment→evidence model. With the EKG, the authored course becomes the **projection source** for the Academic/Knowledge/Assessment layers, so the format must carry exactly the semantics the graph needs — otherwise adaptive tutoring, mastery, learning paths and accreditation traceability cannot be grounded.

## Options considered

1. **Keep v1.3**; enrich the graph separately after import. Duplicates truth; course and graph drift; no authoring-time validation.
2. **Replace v1.3 with a brand-new format.** Breaks the running Builder and STU process; loses backward compatibility.
3. **Evolve to v2.0 (EKG-aligned), backward-compatible with v1.3 via an adapter; validate graph invariants at export.** (Chosen.)

## Decision

- Adopt **DLU Course Exchange Format v2.0** as the authoritative EKG projection source. Container tree aligns to the ontology: Course → **Module** (= v1.3 Section) → **Lesson** (= Page) → **LearningResource** (= Component).
- Outcomes (CLO/MLO) become **first-class** with stable `id`/`uri`, `targetMastery`, `version`, `status`; add a **Concept** layer (`prerequisiteOf` DAG; `lesson.teaches`/`addresses`); **Skills** with governed **MappingAssertion** to CASE/ESCO/SFIA/DigComp/EQF/Bloom (pinned versions); a structured **assessment→item→rubric(criteria→levels)→evidence** model. Identity follows the EKG URI/versioning policy (no titles in ids).
- **Backward compatibility:** a v1.3→v2.0 **adapter** converts Section→Module, Page→Lesson, Component→Resource, carries CLO/MLO, and renames checkpoints (`design_approval/academic_acceptance/technical_publication`) keeping a v1.3 `legacy_type` alias.
- **Validation at export:** the Course Builder v2.0 runs schema + **graph-invariant** checks (every MLO→CLO; every published outcome assessed-or-waived; prerequisite DAG acyclic; approved mapping pinned; rubric criterion ≥2 levels). A release failing a blocking rule cannot reach a gate.
- The file is the input to the EKG academic/knowledge/assessment **projection** (sprints EKG-W1-02/03/04).

## Consequences

**Positive:** one source of truth for course *and* graph; authoring-time guarantee that every course projects cleanly; unlocks tutoring/mastery/paths/accreditation grounding; no big-bang migration (v1.3 keeps working).
**Costs/risks:** the Builder gains concept/skill/assessment authoring surfaces; concepts/skills/mappings start empty and are enriched incrementally (AI-assisted, human-approved) — enforce "warn-then-require" across releases; stewardship of framework mappings (ADR governance) becomes a prerequisite for the skill fields to be canonical.
**Enforcement:** export blocked on blocking invariants; STU process v2.1 §9/§10 updated to validate/emit v2.0; content-standard numbers (12–15 h, feedback/2 h, 3–8 CLOs, ≥1 MLO/module) retained on Module/Lesson.

## Related artifacts

`DLU_Course_Exchange_Format_v2.0.md`, `dlu_course_exchange_v2.0.schema.json`, `DLU_Course_Builder_v2.0.html`, `DLU_COURSE_FORMAT_EKG_ALIGNMENT.md`; sprint `EKG-W1-07`.
