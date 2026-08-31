# Sprint NEW-06 — Thesis + Committee Aggregates (G5/G6)
### DAS K3 · self-contained prompt · target: `dlu_builder_tk` · depends: STX-08 (verdict ingress); feeds NEW-04 MILESTONE edges

## Role
`backend-dev` resolving G-register items **G5** (thesis lifecycle) and
**G6** (committees) — the largest ESSE3 gaps (DAS BOOK-15 Ch. 6/7/8/9;
BOOK-07 duties; G3 boundary).

## Context — read before coding
1. BOOK-15 Ch. 7 — the Thesis aggregate, verbatim contract:
   `Thesis (C6/C8, GUID): learner · advisors (first, second —
   FacultyAssignment roles) · title/proposal · milestones[]
   (proposal→literature→draft→final) each with process evidence ·
   plagiarism_check (existing service — report attached as evidence) ·
   deposit (PDF/A, versioned, advisor-approved) · defense: viva before
   Committee · verdict + grade · status:
   proposed→approved→in_progress→submitted→deposited→defended→archived`.
   Normative: **process evidence throughout** (versioned drafts,
   checkpoint reviews — the integrity strategy IS the workflow, Ch. 9.1);
   advisor approvals are HITL acts; the deposit is immutable and
   retention-classed; the defense verdict is committee-signed evidence at
   trust 1.0 feeding credential criteria (BOOK-16, K4).
2. BOOK-15 Ch. 8 — the Committee aggregate:
   `Committee (C3, GUID): kind (exam|graduation|doctoral|recognition) ·
   members[] (president|member|secretary — FacultyProfile refs) · quorum
   rules · term/session scope · formation_approved_by (dean/rector)`.
   Acts: convocation → session minutes → verdicts (per candidate) →
   verbalization. Formation is governed (approval + conflict-of-interest
   declaration: an advisor SHOULD NOT preside over their own advisee's
   defense without policy exception). Verdicts are collective,
   president-signed, secretary-recorded — highest-trust evidence.
   Recognition committees reuse the same aggregate (STX-12 loop).
3. **G3 boundary (constitutional):** where the legal act is external
   (ESSE3 verbale with qualified signature), the Committee act
   *prepares* it and the driver *executes* it; `grade.synced` confirms
   (pending-verbalization semantics from NEW-04). **DLU never fabricates
   the legal act** — the full driver is NEW-11/12 (K5); this sprint
   ships the prepare-side contract + a driver stub that visibly defers.
4. Existing (repo-verified): **fully greenfield** — no thesis/committee
   tables exist (grep clean); the event taxonomy **already reserves**
   `thesis.milestone.completed` / `thesis.deposited` / `thesis.defended`
   (constitution §7.3); `plagiarism_service` + `plagiarism_reports`
   exist (attach, don't rebuild); `FacultyAssignment` roles substrate
   exists (BOOK-15 Annex — member refs); STX-08 pipeline is the verdict
   ingress (committee-verified trust class 1.0 in the Ch. 4.1 table);
   NEW-04's `MILESTONE` edge seam awaits this feed; `agent_proposals`
   HITL queue for advisor approvals. Migration chains off the current
   head.
5. Surfaces are minimal here: thesis thread renders in WS06 for the
   learner; advisor/committee queues get APIs — the full FW3/FW4
   faculty surfaces are NEW-09 (K4). Don't build faculty UI beyond what
   verification needs.
6. BOOK-15 Ch. 9 integrity order of preference applies to the thesis
   flow: design-out first (process evidence, checkpoints), detect humbly
   (plagiarism report = signal for human review; AI-text detectors never
   sole evidence).

## Deliverables
1. **Thesis aggregate + migration**: tables per the Ch. 7 contract
   (thesis, milestones with process-evidence refs, deposit versions) —
   status machine with guarded transitions; advisor approvals as HITL
   acts (queue-routed, 409-guarded); plagiarism report attached as
   evidence at the submission milestone; deposit = PDF/A ref, versioned,
   immutable once deposited (mutation raises), retention-classed.
2. **Committee aggregate + migration**: committee, members (roles,
   `FacultyAssignment`/FacultyProfile refs), quorum rules, scope;
   **formation flow**: proposed → conflict-of-interest check (declared
   conflicts block unless a policy exception is recorded) →
   dean/rector approval (HITL) → active.
3. **Acts pipeline**: convocation → session minutes → per-candidate
   verdicts (president-signed, secretary-recorded, collective) →
   verbalization **preparation** (the G3 boundary: prepared act +
   driver stub that marks `pending_verbalization`; `grade.synced`
   fixture closes it).
4. **Evidence integration (STX-08)**: defense/committee verdicts enter
   the pipeline at trust 1.0 (`source_kind="committee_verdict"`) —
   the highest class in the Ch. 4.1 table; viva verdicts at 0.95–1.0;
   process evidence accumulates on milestones (lower classes);
   competency `verified` transitions ride the human act, never the
   pipeline.
5. **Mesh events + GPS feed**: emit the reserved
   `thesis.milestone.completed/deposited/defended` events; thesis
   chains materialize as `MILESTONE` edges through NEW-04's seam,
   schedulable against committee availability.
6. **Learner surface**: thesis thread in WS06 (milestones, deposit
   status, defense schedule); advisor approval + committee
   convocation/verdict APIs (FW3/FW4 surfaces consume in K4).

## Verifications
- **V1** evidence chain resolvable end-to-end: fixture defense verdict →
  trust-1.0 `EvidenceRecord` → competency criteria resolution (the
  chain a K4 credential will walk) — every hop cites its source.
- **V2** committee verdict = trust-1.0 evidence: enters only via STX-08,
  president-signed + secretary-recorded fields mandatory (schema), and
  no non-committee path can write that trust class (negative test).
- **V3** conflict-of-interest: formation with an advisor presiding over
  their own advisee's defense is blocked; recorded policy exception
  unblocks with an audit trail (both directions tested).
- **V4** deposit immutability: any mutation of a deposited version
  fails loudly; a new version supersedes with lineage (mirrors the
  evidence append-only discipline).
- **V5** G3 boundary: the verbalization act is prepared, never executed
  locally (no legal-act write path exists — structural test);
  `pending_verbalization` set on verdict, closed by a `grade.synced`
  fixture.
- **V6** migration up/down/up clean · `pytest -m phase1` green · thesis
  events taxonomy-valid on the mesh · `MILESTONE` edges appear for a
  fixture thesis.

## DoD
V1–V6 green · **G5 and G6 dispositions updated in TRACEABILITY**
(aggregates delivered; verbalization execution remains NEW-11/12) ·
BOOK-15 Annex (Thesis, Committee, viva rows) updated · constitution
§7.3/§14 sync · decisions note (quorum/conflict policy knobs are
institution-configurable) · next: K4 credential engine consumes the
evidence chain; NEW-09 builds FW3/FW4 surfaces; K5 executes
verbalization at the driver.
