# BOOK-27 — Financial Services & Student Economy Platform (DLU-FSEP)

### DAS v0.1-draft · Layer: Student Economy / Cross-Cutting · Status: SKELETON — Phase 0 governance only, no engineering yet

> **This is a skeleton, not an implementation record.** Unlike most Books in this series, BOOK-27
> registers a program that has been designed but whose engineering is deliberately suspended.
> FSEP-00-01 (the one live defect — five runtime paths querying migration-less
> `backend/domains/payments/` tables) is done, per HRD-A-10. Nothing else in Phase 1 onward has
> started: `docs/ops/TRACK_C_POST_PILOT_PLAN.md` explains why — four of the plan's own open
> decisions (first jurisdiction, merchant-of-record posture, platform-fee tolerance, ledger-vs-
> institutional-GL boundary) can only be answered from a live pilot, and the plan's own staffing
> assumption (3-4 backend engineers) exceeds the current team of two. This Book exists now anyway
> because DAS registration (FSEP-00-04) is documentation, not engineering, and costs no capacity to
> do in parallel with the pilot.
>
> Closes **G24** (`TRACEABILITY.md` §1) — no student-economy layer (obligations, ledger, provider
> abstraction, agreements, wallet, loyalty, marketplace, financial intelligence) existed anywhere
> in the platform; AR/AP/budgets/planning exist (G19, BOOK-23) but stop at the collection
> instrument. Functionality area: **27**. Sprints: **FSEP-00…FSEP-12**
> (`dlu_builder_tk/docs/fsep/FSEP_IMPLEMENTATION_PLAN.md` v2.0 + v2.1 addendum — the actual,
> detailed execution plan; not restated here, only registered and cross-referenced).

---

## 1. Purpose and scope

DLU-FSEP extends the platform from academic/cognitive orchestration into the economic relationship
connecting students, universities, service providers and regulated financial partners
(`DLU-FSEP_Architecture_Masterbook_v1.0.docx` §1, Executive Vision). It covers obligation/allocation
semantics, an append-only ledger, provider abstraction (Stripe, PagoPA, banks, lenders), agreements
(payer/sponsor/guarantor roles), student wallet and card issuance, loyalty and University Credits,
a university marketplace, and AI-native financial intelligence (Financial GPS, Student/Finance
Copilots).

**BOOK-23 (Financial Operations and Administrative Backbone) remains the owner of AR/AP, budgets,
and planning & control — this Book does not re-model, replace, or compete with it.** FSEP's
obligation/allocation core binds *downstream* to BOOK-23's existing instruments
(`student_invoices`, `administrative_holds`, `fee_schedules`, `period_closes` — see the de-
duplication register, §4 below), extending them rather than forking a second source of truth for
anything BOOK-23 already does well. Where the two Books' scopes touch, BOOK-23 keeps the operative
detail and this Book cross-references it rather than restating it.

Out of scope for this skeleton: everything Phase 1 onward actually builds. This document registers
*that a plan exists and where it lives*, not the plan's own content — see
`dlu_builder_tk/docs/fsep/FSEP_IMPLEMENTATION_PLAN.md` for the real execution detail (verified
baseline, verification findings V1–V13, the de-duplication register, phase-by-phase task tables,
and the governance apparatus §2–§18 draw from).

## 2. Relationship to BOOK-23 and the rest of the standard

| This Book says | BOOK-23 (or other Book) already says | Resolution |
|---|---|---|
| FSEP obligations settle via cash, aid, sponsor, or University Credit | BOOK-23 owns `student_invoices`/`invoice_lines`/`payment_reconciliations`, the AR collection instrument | FSEP's `Obligation`/`Allocation` model wraps and extends the existing AR tables — `student_invoices` is retained, re-parented, never replaced (ADR-FSEP-R003) |
| Pricing must resolve through a single catalogue | BOOK-23 R23.6: no AR invoice may issue without an effective fee schedule | FSEP introduces no second pricing model; every obligation binds to `fee_schedule_service` (ADR-FSEP-R007) |
| Closed accounting periods are immutable | BOOK-23's `period_close_service` already enforces this at the ORM-event level | FSEP write paths take the same period-close interlock, corrections become new open-period entries, never edits |
| Administrative holds gate enrolment/credentials | BOOK-23 (NEW-19) already unified three prior hold concepts into `administrative_holds` | FSEP wires existing, disclosed-but-unwired hold gates (credential issuance, GPS route constraints) rather than building a new hold model |
| New event types need registering | `event_taxonomy.py`'s registry is closed — a new event requires a constitution amendment first | FSEP-03-01 (RFC-0003, `architecture/rfc/RFC-0003-*.md`) is that amendment; no FSEP event constant lands in code before the RFC merges |

## 3. Rules — R27.x

**Not yet written.** Deriving the canonical rule set is real design work, scoped to FSEP-04-03
("BOOK-27 R27.x/C27.x filled in from Phase 0 reality") — a task that itself waits on the pilot
answering the open decisions §1 names, since several candidate rules (merchant-of-record
responsibility, jurisdiction-specific credit expiry) can't be written correctly before those facts
exist. The implementation plan's own invariants (§6.2: provider identifiers are never primary DLU
identity keys; price flows down never sideways; closed periods are write-once) are the working
draft of what R27.x will formalize — cross-reference them there until this section is filled in.

## 4. Conformance checks — C27.x

Already fully specified in the implementation plan (§16); reproduced here for DAS cross-reference,
not restated with different content:

| Check | What it proves | Owning sprint |
|---|---|---|
| **C27.1** | No runtime path queries a table absent from the migration chain — asserted against a migration-built schema, never `create_all` | FSEP-00 — **already enforced**, continuously, by HRD-A-09's schema-drift test, independent of this program |
| **C27.2** | An obligation cannot be created without a resolvable fee schedule unless `pricing_source` is explicit and reasoned | FSEP-05 |
| **C27.3** | A settled amount in a `closed` period cannot be mutated; corrections appear as new open-period entries | FSEP-05/08 |
| **C27.4** | 10,000 duplicate provider events produce exactly one ledger effect | FSEP-07 |
| **C27.5** | Adding a second payment provider changes zero lines of domain code | FSEP-07 |
| **C27.6** | Cross-tenant read fails at RLS **and** ABAC, independently | FSEP-12 |
| **C27.7** | `sum(allocations) <= obligation.amount` holds under concurrency | FSEP-08 |
| **C27.8** | The ledger rejects UPDATE/DELETE at the database level | FSEP-01 |
| **C27.9** | The reward rule engine cannot represent a grade-linked financial penalty | Phase 4 |

Only C27.1 has anything to verify today — the rest gate code that doesn't exist yet.

## 5. Architecture Decision Records (Ch. 26 — transcribed verbatim from the Masterbook)

Per `DLU-FSEP_Architecture_Masterbook_v1.0.docx` §26, "Architecture Decision Records." These are
the Masterbook's own decisions, recorded here verbatim so BOOK-27 is a complete DAS-side reference
without requiring the docx to be open alongside it. Cross-referenced (not restated a third time)
in `dlu_builder_tk/docs/ARCHITECTURE_DECISIONS.md`.

| ADR | Decision |
|---|---|
| ADR-FIN-001 | DLU owns the financial domain model; Stripe does not |
| ADR-FIN-002 | Payment execution is separated from academic entitlement |
| ADR-FIN-003 | Each university operates as an isolated financial tenant |
| ADR-FIN-004 | Regulated services are delegated to regulated providers |
| ADR-FIN-005 | Student, payer, sponsor and guarantor are separate entities |
| ADR-FIN-006 | Rewards and University Credits are DLU domain entities |
| ADR-FIN-007 | AI consumes governed financial context through an AI Context Gateway |
| ADR-FIN-008 | Academic evaluation remains independent of financial status |
| ADR-FIN-009 | DLU-FSEP is provider- and country-abstracted |
| ADR-FIN-010 | Financial transactions generate immutable DLU domain events |
| ADR-FIN-011 | DLU maintains a logical ledger distinct from Stripe and ERP ledgers |
| ADR-FIN-012 | University Credits launch as closed-loop credits, not cryptocurrency |
| ADR-FIN-013 | Consumer credit is optional and not an MVP dependency |
| ADR-FIN-014 | Financial account/savings marketing follows regulated provider terminology and disclosures |
| ADR-FIN-015 | Marketplace settlement rules are contract- and tenant-policy-driven |

Repository-scoped decisions specific to *how* `dlu_builder_tk` implements the above (not Masterbook
content — the implementation plan's own proposals) are ADR-FSEP-R001…R008, recorded in
`dlu_builder_tk/docs/ARCHITECTURE_DECISIONS.md` rather than here, since they concern that repo's
own code structure, not a DAS-normative decision.

## 6. Turnkey / Annex mapping

Not yet applicable — no FSEP sprint has produced a Turnkey artifact. Populate this section
alongside the R27.x/C27.x fill-in at FSEP-04-03, once Phase 1 sprints exist to map.
