# RFC-0003 — DLU-FSEP Event Family

Status: **Proposed** · Author: architecture review, 2026-08-18
Owner Books: **27** (Financial Services & Student Economy Platform, skeleton — G24) · **04**
(Academic Domain Model, Ch. 7 — Aggregate ↔ Event Map) · **23** (Financial Operations &
Administrative Backbone, existing invoicing events)
Affected registers: **G24** (`TRACEABILITY.md`); the Turnkey constitution's closed event registry
(`dlu_builder_tk/docs/STUDENT_EXPERIENCE_ARCHITECTURE.md` §7.3, `event_taxonomy.py`)
Supersedes: nothing · Superseded by: nothing · Companion: none (no new ADR — the FSEP ADRs are
already recorded, `BOOK-27` §5)

> **Verdict up front.** `event_taxonomy.py`'s own header rule is explicit: *"THE REGISTRY IS
> CLOSED. To add an event type: amend constitution `docs/STUDENT_EXPERIENCE_ARCHITECTURE.md` §7.3
> + DAS BOOK-04 Ch. 7 FIRST (via RFC/PR to the standard), THEN add the constant here."* This RFC is
> that amendment for DLU-FSEP's event surface — and only that. It proposes **24 new event names**
> (22 from the Masterbook's own §16 list, plus 2 identified while designing the University Credits
> ledger, `docs/fsep/CREDIT_LIABILITY_DESIGN.md`) for the constitution and BOOK-04 to register.
> **It adds zero lines of code.** The actual Python constants land in `event_taxonomy.py` only once
> this RFC merges (FSEP-03-02, a separate, later, code-bearing task) — matching the closed
> registry's own two-step discipline, the same one RFC-0002/ADR-0019 followed for the EKG's five
> genuinely-new events.

---

## 1. Context

`DLU-FSEP_Architecture_Masterbook_v1.0.docx` §16 ("Event-Driven Architecture") names 23 events as
the financial domain's event surface. `dlu_builder_tk`'s own `docs/fsep/FSEP_IMPLEMENTATION_PLAN.md`
(finding V6) already flagged that simply adding all 23 as new constants would be wrong twice over:
it would violate the registry's own "RFC first" rule, and one of the 23 (`INVOICE_ISSUED`) already
exists under a name the financial-invoicing domain (BOOK-23, SPRINT-05/NEW-19) registered first.
This RFC does the verification the plan's own finding called for — re-checked directly against
`event_taxonomy.py`, not re-derived from the plan's own count — and produces the actual proposed
list.

## 2. Duplication audit (normative — nothing below may be re-declared under a new name)

Verified directly in `dlu_builder_tk/backend/services/event_taxonomy.py`:

| Masterbook event | Status | Evidence |
|---|---|---|
| `INVOICE_ISSUED` | **Already exists** — `event_taxonomy.py:124`, `INVOICE_ISSUED = "invoice.issued"` (SPRINT-05/NEW-19) | Reuse this constant. Do not re-declare. |
| *(not in the Masterbook's 23, but adjacent)* `INVOICE_PAID`, `INVOICE_OVERDUE` | **Already exist** — `event_taxonomy.py:125-126`, same sprint | The Masterbook's own `PAYMENT_SETTLED`/`INSTALLMENT_OVERDUE` cover conceptually similar ground under different names (payment-attempt-level vs. invoice-level) — both name spaces are kept, deliberately not merged (see §3, rows 8/9), since a payment settling and an invoice being marked paid are related but distinct events in this domain's own model (`FSEP_IMPLEMENTATION_PLAN.md` §6.2's Obligation/Allocation/Invoice separation). |

**Rule RFC3.1** — every one of the 24 proposed constants below is genuinely new; none re-declares
`INVOICE_ISSUED`/`INVOICE_PAID`/`INVOICE_OVERDUE`, `SUPPLIER_INVOICE_PAID`, `PERIOD_CLOSED`, or
`VARIANCE_FLAGGED` (all already registered, BOOK-23/NEW-19/NEW-30), under a different name. A
sprint that adds a 25th constant duplicating one of these fails review.

## 3. Proposed events

22 from the Masterbook's own §16 list (verbatim event names, `Business meaning` column quoted
directly from the docx), plus 2 identified during Phase-0 design work on the University Credits
ledger (`docs/fsep/CREDIT_LIABILITY_DESIGN.md` §3/§7 — not in the Masterbook, flagged there as
needing exactly this RFC to register rather than a second one later):

| # | Proposed event | Business meaning | Source |
|---|---|---|---|
| 1 | `STUDENT_FINANCIAL_PROFILE_CREATED` | Student finance onboarding | Masterbook §16 |
| 2 | `FINANCIAL_AGREEMENT_ACCEPTED` | Terms accepted | Masterbook §16 |
| 3 | `OBLIGATION_CREATED` | New payable amount | Masterbook §16 |
| 4 | `PAYMENT_AUTHORIZED` | Provider authorization | Masterbook §16 |
| 5 | `PAYMENT_CAPTURED` | Funds captured | Masterbook §16 |
| 6 | `PAYMENT_FAILED` | Collection failure | Masterbook §16 |
| 7 | `PAYMENT_SETTLED` | Settlement recorded | Masterbook §16 |
| 8 | `INSTALLMENT_OVERDUE` | Dunning trigger | Masterbook §16 |
| 9 | `SCHOLARSHIP_GRANTED` | Aid award | Masterbook §16 |
| 10 | `AID_APPLIED` | Aid allocation | Masterbook §16 |
| 11 | `FINANCING_APPLIED` | Loan workflow | Masterbook §16 |
| 12 | `FINANCING_APPROVED` | Provider approval state | Masterbook §16 |
| 13 | `FINANCING_DISBURSED` | Funds received | Masterbook §16 |
| 14 | `FINANCIAL_HOLD_CREATED` | Administrative hold | Masterbook §16 — **cross-reference**: this is a FSEP-domain event about a hold being raised, distinct from BOOK-23's existing `administrative_holds` table/service, which this event notifies about, never duplicates (D-03, `FSEP_IMPLEMENTATION_PLAN.md` §4) |
| 15 | `FINANCIAL_HOLD_REMOVED` | Hold cleared | Masterbook §16 (same cross-reference as #14) |
| 16 | `CARD_TRANSACTION_AUTHORIZED` | Card event | Masterbook §16 |
| 17 | `CARD_TRANSACTION_SETTLED` | Card settlement | Masterbook §16 |
| 18 | `REWARD_EARNED` | Reward accrual | Masterbook §16 |
| 19 | `UNIVERSITY_CREDIT_ISSUED` | Credit issuance | Masterbook §16 |
| 20 | `UNIVERSITY_CREDIT_REDEEMED` | Credit redemption | Masterbook §16 |
| 21 | `MARKETPLACE_ORDER_COMPLETED` | Marketplace transaction | Masterbook §16 |
| 22 | `RECONCILIATION_EXCEPTION_CREATED` | Mismatch detected | Masterbook §16 |
| 23 | `UNIVERSITY_CREDIT_EXPIRED` | A credit balance lapses under a tenant/country's expiry policy, where legally permitted (breakage) | `CREDIT_LIABILITY_DESIGN.md` §3 — not in the Masterbook; needed so the ledger has an event for the expiry lifecycle transition that section works out |
| 24 | `UNIVERSITY_CREDIT_REVERSED` | An issuance is undone (fraud, policy correction, erroneous grant) | `CREDIT_LIABILITY_DESIGN.md` §3 — same reasoning as #23 |

All 24 follow the constitution's existing dotted, lowercase, domain-scoped naming pattern once
implemented (matching `invoice.issued`, `student.created` — the Masterbook's own
`UPPER_SNAKE_CASE` above is its internal convention, translated at implementation time the same
way RFC-0002 handled the EKG suite's own differently-cased suggestions).

## 4. Decision

### 4.1 Constitution amendment (`docs/STUDENT_EXPERIENCE_ARCHITECTURE.md`)

A new subsection is added after §7.3's closed `student.*` table — additive, matching exactly how
RFC-0002 added §7.4 for its own five new events rather than editing §7.3's existing rows. This RFC
does not itself write that subsection (that edit lands in `dlu_builder_tk`, a separate repo from
this one); it is the governance decision that authorizes it. The subsection to add:

> ### 7.5 FSEP financial event family (RFC-0003 — proposed, not yet implemented)
>
> 24 new event types for the DLU-FSEP domain (obligation/payment/financing/hold/card/reward/
> University-Credit/marketplace/reconciliation lifecycle) — see RFC-0003 §3 for the full list and
> rationale. **Producers, consumers, and the actual `event_taxonomy.py` constants do not exist
> yet** — FSEP-03-02 adds them once this RFC merges, at the same time the obligation/ledger core
> that would emit them is built (Phase 1). Registering the names now, ahead of the code, follows
> the same "RFC first, constant second" discipline the registry itself requires — it does not mean
> the events are live.

### 4.2 BOOK-04 Ch. 7 (Aggregate ↔ Event Map)

A new row is added to Ch. 7's aggregate↔event table:

| Aggregate (context) | Canonical events |
|---|---|
| FSEP Obligation/Payment/Financing/Card/Reward (new context, BOOK-27 — not yet one of C1–C10) | The 24 events in RFC-0003 §3 (proposed, not yet implemented — see BOOK-27 §3/§4 for status) |

## 5. What this RFC does not do

- **No code.** `event_taxonomy.py` gains no new constant from this RFC alone. That is FSEP-03-02,
  gated on this RFC merging, itself gated on Phase 1 (the obligation/ledger core that would
  actually produce and consume these events) — which is suspended pending pilot evidence per
  `docs/ops/TRACK_C_POST_PILOT_PLAN.md`.
- **No producer/consumer wiring.** Nothing in this RFC claims any service emits or listens for any
  of the 24 events — that's the same Phase 1 work.
- **No change to the 6 already-registered financial events** (`INVOICE_ISSUED`/`_PAID`/`_OVERDUE`,
  `SUPPLIER_INVOICE_PAID`, `PERIOD_CLOSED`, `VARIANCE_FLAGGED`) — reused as-is, per §2.

## 6. Conformance checks

- **C27.10** *(new, extends BOOK-27's own C27.1–C27.9)*: Fixture — none of the 24 names in §3 exists
  as a Python constant in `event_taxonomy.py` until FSEP-03-02 lands; a static grep-based check that
  the registry only gains these names through that gated task, not silently before it.
- **C04.1** *(existing convention, BOOK-04)*: every aggregate in Ch. 7's table has at least one
  canonical event — the new FSEP row satisfies this the same way every other row does.

## 7. Sprint catalog

| Sprint | Scope | Books/Registers | Repo |
|---|---|---|---|
| **FSEP-03-01** | This RFC + the constitution/BOOK-04 amendments it authorizes. | 04, 27 | Standard + `dlu_builder_tk` (constitution file lives there) |
| **FSEP-03-02** *(deferred, gated on this RFC + Phase 1)* | Add the 24 constants to `event_taxonomy.py`; wire producers/consumers as each Phase-1 obligation/payment/financing service is built. | — | `dlu_builder_tk` |
