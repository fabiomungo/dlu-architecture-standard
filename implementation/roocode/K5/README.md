# K5 Prompt Pack — Profiles & Compliance
### DAS BOOK-20 Phase K5 · sprints NEW-11…15 · generated from the Masterbook v1.0-draft

**Target repo:** `dlu_builder_tk` (the reference implementation).
**Prerequisite:** K4 exit — see `../K4/README.md`/`K4-EXIT-REPORT.md`. K3
is fully delivered (9/9, including NEW-06 — see TRACEABILITY's K3 phase
row); K4's five sprints (STX-13+NEW-07, STX-14/15, NEW-08, NEW-09/10,
NEW-16) are delivered. **NEW-17** (Credit Recognition & Pre-Evaluation,
G16, added by BOOK-14A) is out of this pack's scope — it is being built
on a separate, concurrent track; do not fold its scope into anything
below, and do not touch its files.

**Scope of this pack.** BOOK-20 Ch. 7 names five K5 items: `NEW-11`
(ESSE3 driver + Italian profile), `NEW-12` (PagoPA + QES adapters),
`NEW-13` (compliance registers + calendar, G12/G13/G14), `NEW-14` (cost
attribution + economies), `NEW-15` (conformance suites + DR automation).
**All five are now authored** — see the status table below. None has
been executed yet; execute in the order below (NEW-11 first is a real
dependency, not just a suggestion — NEW-12 imports its code). This is
the last prompt pack in the entire DAS Masterbook implementation
blueprint (BOOK-00 through BOOK-20) — once these five sprints are
executed and NEW-15's own `K5-EXIT-REPORT.md` is produced, the blueprint
is complete through K5.

**Execution rules:** BOOK-20 Ch. 12 bind every sprint — read them first.
Digest: Turnkey `CLAUDE.md` guardrails are absolute (GUID PKs for new
tables, `Integer` only for FKs to `courses.id`, platform vs tenant schema,
async routes / sync Celery, additive-only migrations with tested
downgrade, soft delete, no column literally named `metadata`, no
cross-file `relationship()`); all V-checks green before DoD; docs sync in
the same change set (constitution + CLAUDE.md + Book Annexes +
TRACEABILITY); G/A-register duty; ontology naming via `dlu-core.yaml` or
RFC first; **all LLM calls via the ACP gateway (ADR-0013) — never direct
provider calls**; **every learner-facing agent stays
`lifecycle_state='testing'` until its NEW-02 harness run is green and
steward-signed — no exceptions.**

## Order and dependencies

```text
NEW-11 (ESSE3 driver + Italian profile — G3 execution, feeds G8/G14)
   — unblocks G3, the single biggest open constitutional gap; introduces
     the first real circuit breaker and the boundary-table pattern
     NEW-12 reuses
       └─► NEW-12 (PagoPA + QES adapters)
              — reuses NEW-11's boundary-table/circuit-breaker pattern;
                replaces NEW-08's always-unpaid PagoPA stub; closes G3's
                remaining QES-provider-alternative path
NEW-13 (Compliance registers + calendar — G12/G13/G14) ─┐
NEW-14 (Cost attribution + economies)                   ├─ no shared
                                                          │  files, no
                                                          │  dependency
                                                          │  between
                                                          │  them — run
                                                          │  in either
                                                          │  order or in
                                                          │  parallel
                                                         ─┘
NEW-15 (Conformance suites + DR automation) — last, by construction: it
   turns BOOK-20 Ch. 8's DAS-Core/Intelligent/Certified criteria (and the
   residual K3/K4 infra debt below) into CI-runnable suites, so it can
   only meaningfully run once NEW-11…14 exist to be checked.
```

- **NEW-11 first.** It closes G3 (verbalization execution — every sprint
  until now has only *prepared* the legal act, never executed it) and
  both NEW-12 and NEW-13 lean on driver scaffolding it introduces (the
  circuit breaker primitive, the boundary-table shape, the M-A/M-B/M-C
  pattern).
- **NEW-12 depends on NEW-11**, not the other way round — it reuses
  NEW-11's circuit-breaker/boundary-table pattern directly rather than
  inventing a second one.
- **NEW-13 and NEW-14 are independent of each other** — no shared files
  (compliance registers/calendar vs. cost-attribution dashboards), no
  data dependency. They can run in parallel once NEW-11/12 land (NEW-13's
  RSI/DE-DI ledgers want Moodle instructor-event capture per Masterbook
  Review finding M3 — a Moodle driver extension, not an ESSE3 one, so it
  has no hard edge to NEW-11 either).
- **NEW-15 is last.** Bundle the residual K3/K4 infrastructure debt below
  into it rather than treating it as a separate pass — it's the natural
  place those cross-cutting gaps finally get closed, since NEW-15's whole
  job is turning "criteria" into "CI-runnable suites."

## K3/K4 residual debt — still open, assign to NEW-15 unless redirected

From `../K4/README.md`'s own carried-forward table (itself carried from
`../K3/K3-EXIT-REPORT.md`) — none of this blocks NEW-11 functionally, but
none of it has been closed either:

| Debt item | Status |
|-----------|--------|
| NFR budget dashboards / alert wiring | Still open — **NEW-15 Deliverable 7** adds the DAS-specific budget panels to the existing Grafana dashboards |
| Cross-tenant leakage fuzz | API dimension closed (2026-07-24); graph/streams dimensions — **NEW-15 Deliverable 6** closes both (Neo4j integration test + Redis streams unit+integration split) |
| Driver bulkhead chaos tests | Partially closed (2026-07-24); most drivers + a real circuit breaker still open — **NEW-11 builds the circuit breaker** (closes part); ESSE3/PagoPA/QES driver coverage lands with NEW-11/12 themselves; Moodle/Frappe/Stripe/Keycloak/n8n chaos coverage remains open, not claimed by any authored K5 sprint |
| Erasure e2e chain | `revoke_or_suspend(purge_pii=True)` exists; no caller anywhere calls it — **still open, not claimed by any authored K5 sprint** — a genuine gap for a future pass |
| ACE trace-completeness measurement | Asserted-by-construction only, never actually measured — **NEW-15 Deliverable 4** closes this (a durable `AceCycleAttempt` table + daily reconciliation job) |
| One-voice / "why?" UX audit | Never performed — **NEW-15 Deliverable 3** builds a structural proxy (explicitly documented as a proxy, not the human audit itself, which stays open) |
| Agent GA gating | All 9 seeded agents remain `lifecycle_state="testing"`; zero have run `/agents/{id}/gate` + steward sign-off — **still open, explicitly out of every authored K5 sprint's scope** (an ops/steward action, not a code deliverable — confirmed by NEW-15's own research) |
| `MOVE_CONSULTS` has exactly one entry (`reframe_goal`) | Open only if a future sprint finds a real need — not touched by any K5 sprint |
| Audit fabric — two disconnected `AuditService` implementations coexist | **NEW-15 Deliverable 1** wires four DAS event types into the real, hash-chained `backend/domains/audit/` system; the second, non-hash-chained `audit_service.py` (auth/admin logging) is left running, cross-referenced, not consolidated — a documented, not silent, residual redundancy |

## Phase exit gate

**DAS-Certified auditable (BOOK-20 §8.3, external audit)** — DAS-Core +
DAS-Intelligent criteria (§8.1/§8.2, still only partially infrastructure-
complete per the debt table above) plus: AI Act register complete with
FRIA (NEW-13), audit fabric hash-chained (NEW-15), regulatory profile
suites — Italian (SPID/eIDAS/ANS — NEW-11/13) and US (RSI ledger + G13
policy + engagement mapping — NEW-13), a DR exercise on record (NEW-15),
and an external audit of a sampled evidence→credential chain and a
sampled cycle trace. Produce a `K5-EXIT-REPORT.md` once all five sprints
are delivered, following the exact honest-audit discipline
`K3-EXIT-REPORT.md`/`K4-EXIT-REPORT.md` established (functional delivery
vs. phase-infrastructure completeness are reported separately — never
conflated).

| Sprint | File | Status | Model rec. (CLAUDE.md §14) |
|--------|------|--------|---------------------------|
| NEW-11 | NEW-11-esse3-driver-italian-profile.md | ✅ prompt authored (opus design review complete) — not yet executed | opus for the circuit-breaker/adapter-layout/SPID-brokering-scope design review (already done — see the prompt's own header), sonnet impl |
| NEW-12 | NEW-12-pagopa-qes-adapters.md | ✅ prompt authored (opus design review complete) — not yet executed; depends on NEW-11 being EXECUTED first (reuses its `CircuitBreaker` + driver-package pattern as real code, not just spec) | opus for the QES-provider signature-round-trip/ESSE3-vs-QES routing design review (already done — see the prompt's own header), sonnet impl |
| NEW-13 | NEW-13-compliance-registers-calendar.md | ✅ prompt authored (opus design review complete) — not yet executed; soft-depends on NEW-11 for G8's ESSE3 boundary-table read (degrades honestly to `not_yet_available` if NEW-11 hasn't run yet) | opus for the RSI/DE-DI ledger data-source strategy + AI Act register shape design review (already done — see the prompt's own header), sonnet impl |
| NEW-14 | NEW-14-cost-attribution-economies.md | ✅ prompt authored — not yet executed; depends on NEW-10 (extends `three_economies_service.py`/`program_health_service.py`, no G-register item | sonnet (cost-attribution is Book-specified, lower design risk — confirmed by research; no opus pass needed, only scope-honesty guardrails for the largely-un-instrumented `C_learner` formula) |
| NEW-15 | NEW-15-conformance-suites-dr-automation.md | ✅ prompt authored (opus design review complete) — not yet executed; last sprint in the entire Masterbook blueprint, produces `K5-EXIT-REPORT.md` on completion | opus for the audit-fabric-consolidation/DR-automation/UX-audit-proxy/trace-completeness/maturity-collector design review (already done — see the prompt's own header), sonnet impl |

**All five K5 sprints are now authored.** None has been executed. Execute
in dependency order (NEW-11 → NEW-12; NEW-13/NEW-14 in either order or in
parallel; NEW-15 last). Once executed, `NEW-15`'s own DoD produces
`K5-EXIT-REPORT.md` — at that point the DAS Masterbook's BOOK-00 through
BOOK-20 implementation blueprint is complete through K5, and any further
work is either genuine new scope (a BOOK-21+ or an RFC) or closing
whatever that exit report honestly still lists as open (the erasure e2e
chain and most drivers' chaos coverage are already known, in-advance,
NOT to be closed by this pack — see the residual-debt table above).
