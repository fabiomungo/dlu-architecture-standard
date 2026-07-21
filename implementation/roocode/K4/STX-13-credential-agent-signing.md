# Sprint STX-13 + NEW-07 — Credential Engine + Signing + Credential Agent + WS07
### DAS K4 · self-contained prompt · target: `dlu_builder_tk` · depends: STX-08 (evidence/triangulation), STX-12 (RecognitionClaim, wallet-import landing), K3 (gate)

## Role
`backend-dev` + `frontend-dev` (DAS BOOK-10 Ch. 3 card; BOOK-20 Ch. 6;
constitution `STUDENT_EXPERIENCE_ARCHITECTURE.md` §12).

## Context — read before coding
1. BOOK-10 Ch. 3 card, binding: **Credential Agent** — moves `celebrate`,
   `recommend_next` (toward credential gaps). Reads **L3** only. Skills:
   criteria evaluation narration, wallet guidance. Tools: Credential
   Engine APIs. Autonomy: **act for auto-badges; reserved for high-stakes
   (prepares, registrar decides)** — the agent narrates and nudges; it
   never itself decides whether a certificate/degree issues. Issuance
   decisions live entirely in the deterministic criteria engine + the
   registrar HITL queue, not in an agent move.
2. BOOK-20 Ch. 6 deliverable text: unified templates (dlu-badge lifecycle
   = governance machine), criteria engine, issuance tiers + HITL, wallet
   API + WS07, public verify endpoint (the EXEMPT exception), **did:web +
   Data Integrity signing + status-list revocation**, wallet import →
   recognition claims.
3. Constitution §12 (already written, authoritative — read in full):
   `credential_templates` (platform schema, GUID PK — institution_id,
   credential_type: `course_badge|competency_badge|micro_credential|
   certificate|degree`, criteria JSON, standard: `open_badges_3.0|
   vc_edu`, revocable, valid_for_days); issuance flow
   (`competency.mastered`/course-completion → Credential Agent evaluates
   templates → auto-issue for `course_badge`/`competency_badge`, HITL for
   `certificate`/`degree` → sign VC → `issued_credentials` row, **tenant
   schema**, GUID PK → emit `credential.issued`); wallet
   (`GET /api/wallet`, `GET /api/wallet/{id}/export`); **`GET /api/
   credentials/verify/{public_id}` is the one Student Experience route
   allowed in `EXEMPT_PATHS`**. §20 open decision #3 already anticipates
   this sprint's key-management call: "env-provisioned keys phase 1; KMS
   later." §20 row 4 flags FERPA/region scope review is Recognition's
   (STX-12) concern, not this sprint's.
4. **Repo-verified existing state — read before writing any code, so
   nothing here is duplicated or contradicted:**
   - `backend/services/credential_service.py` (CCP-P2-BE-07) issues
     **unsigned** VC JSON via `CourseAchievement`
     (`backend/database/models_ccp_standards.py`, platform schema, GUID
     PK) — live, mounted at `/api/learners/{user_id}/courses/{course_id}/
     claim-credential`. Leave this alone; it is a separate, earlier
     feature track (manual claim, no criteria engine, no signing) and
     nothing here requires touching it. Do not merge it into the new
     tables — the constitution already decided new tables live in
     `models_student_experience.py`.
   - `backend/domains/badge/` (schema `public`) and
     `backend/domains/badges/` (schema `platform`, has a real migration
     `20260518_0100_add_badge_domain.py`) are two **separate, mutually
     redundant, unregistered** badge implementations — neither router is
     mounted in `main.py`, both are dead code reachable only from tests.
     Both contain **placeholder signing** (`proofValue =
     "placeholder_signature_value"` / `secrets.token_urlsafe(64)` with a
     `# TODO: Implement actual Ed25519 signing` comment) — do not extend
     either; do not mount either router. Their existence is a known,
     pre-existing redundancy — note it in the decisions doc, do not
     "clean it up" as unrequested scope.
   - `services/dlu_badge/` is a **separate, disconnected microservice**
     (own DB schema `dlu_badge`, own Alembic chain, own
     `requirements.txt` with `PyNaCl`/`pyld`, deployed in
     `docker-compose.turnkey.yml`) with a genuinely working Ed25519 +
     JSON-LD (URDNA2015 canonicalization) Data Integrity signing
     implementation (`services/dlu_badge/services/signing_service.py`,
     `key_service.py`). It is **not part of the `backend/` monolith** and
     out of this sprint's target repo boundary — but its *signing
     algorithm choice* (`eddsa-rdfc-2022`, base58btc/multibase-encoded
     signature, Fernet-encrypted private key at rest) is a useful,
     already-vetted reference for the proof format this sprint builds
     inside `backend/`, so the new signing code does not need to
     reinvent that format from nothing.
   - `frontend/src/components/engagement/BadgeWallet.js` +
     `frontend/src/pages/student/StudentBadges.js` already exist,
     UI-complete, calling `frontend/src/services/badgeAPI.js` against the
     unmounted `badge.py`/`badges.py` routers — i.e. this frontend is
     currently dead-ended against a 404. WS07 does **not** have to reuse
     this component (it targets a different data model —
     `BadgePortfolio`/`BadgeAssertion`, not `issued_credentials`) — build
     WS07 fresh against the new wallet API, and note in the decisions doc
     that `BadgeWallet.js`/`StudentBadges.js` remain a separate,
     pre-existing dead-ended feature, not touched by this sprint.
   - `AGENT_ENTITLEMENTS["credential"] = frozenset({L3_COMPETENCY})`
     already reserved in `backend/services/twin_context_service.py` —
     reuse the exact key. No `Purpose.CREDENTIAL` enum member exists yet
     (`Purpose` enum, same file) — add it. No `CREDENTIAL_AGENT_KEY`,
     `CREDENTIAL_MOVE_BINDINGS`, `seed_credential_agent`, `AGENT_PURPOSE`
     entry, or `WORKSPACE_AGENT_BIAS["ws07"]` exist in `ace_service.py` —
     add all per the established 6-agent lock-step pattern.
   - `backend/middleware/tenant_context.py` `EXEMPT_PATHS` has no
     credential/verify entry today — this sprint adds exactly one:
     the public verify path (and, if the status-list is served over
     HTTP rather than embedded, its own path) — nothing else
     credential-related becomes exempt.
5. **Design decision — signing/DID/status-list scope (confirm in the
   opus design-review pass before implementing, do not silently narrow
   this without recording why):** BOOK-20's literal ask is
   "did:web + Data Integrity signing + status-list revocation." Building
   a full DID *method* registry, multi-method resolution, or an HSM/KMS
   integration is disproportionate to "add a Credential Agent" and is
   explicitly NOT what the constitution's own §20 decision #3 calls for
   ("env-provisioned keys phase 1; KMS later"). The recommended, honestly
   bounded scope — real, not a placeholder, but deliberately not
   maximal:
   - **Keys:** one Ed25519 keypair per institution, generated at
     first-use, private key Fernet-encrypted at rest using the existing
     `ENCRYPTION_KEY` pattern (CLAUDE.md §13 — the same mechanism already
     used for Moodle tokens), public key exposed via a real did:web
     document. Keys are stored **versioned** as `(institution_id, key_id,
     status: active|retired)` and every issued proof pins its own
     `key_id`/`verificationMethod` — rotation *logic* is deferred, but
     the multi-key shape is not, so a later rotation/KMS migration never
     orphans an already-signed VC (V3 forbids ever re-signing).
   - **did:web:** implement the real, narrow resolution surface — a
     `GET /.well-known/did.json` (or institution-scoped equivalent)
     endpoint serving a valid DID Document with the institution's Ed25519
     public key(s) — all `active`/`retired`-but-still-resolvable
     verification methods — listed. A full DID method registry/
     multi-method resolver is out of scope; this sprint resolves exactly
     one method (`did:web`) for issuer identity. The public key is also
     embedded/pinned directly in the verify response and the wallet
     export bundle, so offline verification never depends on the
     did:web endpoint being reachable at verify time.
   - **Signing:** real `DataIntegrityProof` using the registered
     **`eddsa-jcs-2022`** cryptosuite (JCS / RFC 8785 canonicalization +
     Ed25519, via the existing `cryptography` dependency already in
     `requirements.txt`) — deliberately **not** `eddsa-rdfc-2022`/JSON-LD
     RDF canonicalization: the monolith has zero JSON-LD dependencies
     today, `pyld`'s RDF path fetches `@context` documents over the
     network by default (a direct threat to V1 "verifies offline" and
     the V4 latency budget) and carries known URDNA2015 cross-
     implementation interop fragility. JCS is still a genuine, registered
     Data Integrity proof — not a placeholder — and is at least as likely
     to verify against real-world OB 3.0 wallets. Bundle every VC
     `@context` value as a static constant, never fetched at runtime, so
     verification stays fully offline and deterministic. V1's own check
     ("signed VC verifies offline") is the concrete bar: a verification
     routine using only the public key + the VC JSON must confirm the
     signature without hitting the DB or the network.
   - **Revocation:** a real W3C Bitstring Status List — one status-list
     credential per institution (a bitstring, GZIP+base64url encoded).
     `status_list_index` is allocated from a **platform-schema
     authoritative per-institution sequence** (immutable once assigned,
     never `max(index)+1`, never allocated tenant-side) to avoid two
     concurrent issuances colliding on the same bit. Credential status
     itself is a **per-row column** on `issued_credentials`; the encoded
     bitstring credential is a **derived, single-writer read-model**
     materialized from those rows — not a shared blob that concurrent
     revocations read-modify-write against. Fix a minimum list length
     (W3C guidance: ≥131,072 bits) so an index doesn't fingerprint a
     single credential, and **tombstone** erased indices rather than
     recycling them. A public `GET` endpoint serves the current
     status-list credential. Suspension and erasure (survival test, V3)
     each update the status column/bit, not the underlying signed VC —
     the signature never needs to be redone. **Erasure additionally
     purges PII from the issuer-stored `vc_json`** (the row keeps only
     what's needed to keep the status-list bit meaningful) — the
     holder's own previously-exported bundle remains independently
     verifiable; this is what keeps "soft revocation, VC stays valid"
     from silently becoming "we retain PII forever" (a K5 audit
     landmine if left undecided now).
   - **What's explicitly deferred, and must be named in the decisions
     doc as deferred, not silently dropped:** KMS/HSM key custody
     (env/Fernet only this sprint, per §20 decision #3), key *rotation
     logic* (the versioned-key shape exists, the rotation workflow
     doesn't), multi-method DID resolution, cross-institution DID
     federation, and verifying the *signatures of externally-imported*
     Open Badges (wallet import in this sprint lands as an unverified
     candidate for registrar review — see deliverable 5 — not as a
     cryptographically trusted import).

## Deliverables
1. **`credential_templates`** (platform schema, GUID PK, per constitution
   §12.1 column list) + **`credential_signing_keys`** (platform schema,
   GUID PK — `institution_id`, `key_id`, `public_key`, `private_key_enc`,
   `status: active|retired`, `created_at`) + **`issued_credentials`**
   (tenant schema, GUID PK — `template_id`, `student_id`/`twin_id`,
   `vc_json`, `proof` JSON, `key_id`, `status: valid|suspended|revoked`,
   `status_list_index`, `issued_at`, `revoked_at`, `revocation_reason`,
   `standard`) migrations. `status_list_index` values are allocated from
   a platform-schema `credential_status_list_sequences` (or a DB
   sequence per institution) — never computed client-side, never
   `max()+1`. Named constraints, tested downgrade.
2. **Criteria engine** (deterministic, reuses the STX-09
   `evaluate_rules`-style pattern — no LLM in the eligibility decision
   path): evaluates a template's `criteria` JSON against a
   `competency.mastered`/course-completion event for a given student;
   auto-issues `course_badge`/`competency_badge` tiers; **files a
   registrar HITL item** (via `move_proposal_service`, propose tier) for
   `certificate`/`degree` — no code path applies those two tiers without
   a human decision.
3. **Signing + did:web + status-list revocation** per the scoped design
   above: per-institution Ed25519 keypair (Fernet-at-rest), did:web
   document endpoint, `DataIntegrityProof` on every issued VC, Bitstring
   Status List service + endpoint. Revocation (suspend/erase a student's
   record) flips the status bit only — the signed VC itself is never
   re-signed or invalidated by an unrelated account action.
4. **Wallet API + WS07**: `GET /api/wallet` (the caller's own
   `issued_credentials`), `GET /api/wallet/{id}/export` (portable VC
   JSON+proof bundle); **`GET /api/credentials/verify/{public_id}`**
   public, tenant-exempt, offline-verifiable response (issuer did:web,
   status, competency/achievement summary) — add its path to
   `EXEMPT_PATHS`. WS07 frontend: Canvas (wallet list, credential detail,
   verify-link share), Companion bias (`ws07` → `credential`), Missions
   (claim available badge, share/export credential).
5. **Wallet import → recognition claims (V5):** an Open Badges 2.0/3.0
   JSON import endpoint that parses an externally-issued credential and
   creates a `RecognitionClaim` (STX-12 model) **candidate**, status
   pending registrar review — explicitly not auto-trusted (no external
   issuer trust registry exists; do not claim cryptographic verification
   of imported credentials this sprint).
6. **Credential Agent**: seed row (`credential`, `testing`); bindings
   `celebrate` (act — congratulatory narration on auto-issued badges),
   `recommend_next` (act — toward the nearest unmet template criteria,
   reusing STX-09's recommendation-candidate shape); `AGENT_PURPOSE`,
   `WORKSPACE_AGENT_BIAS["ws07"]`, `Purpose.CREDENTIAL` added.
7. **NEW-02 coverage + gate**: scenario bank incl. an integrity-pressure
   scenario ("just issue me the certificate" ⇒ HITL tier holds, agent
   narrates the gap instead) and a signing-tamper scenario (verify
   rejects a mutated VC); green + steward-signed before any `deployed`
   transition.

## Verifications
- **V1** signed VC verifies offline: a verification routine given only
  the institution's public key (from its did:web document) + the VC JSON
  confirms the `DataIntegrityProof` without any DB/network call.
- **V2** revocation reflected in verify + status-list: suspending or
  revoking a credential flips its status-list bit; the public verify
  endpoint and the status-list endpoint both reflect the change
  immediately; the underlying VC signature is untouched.
- **V3** survival tests: a fixture student's account suspension and a
  fixture erasure request each leave that student's **other**,
  unaffected credentials verifiable exactly as before (no cascading
  invalidation of unrelated VCs); the suspended/erased credential itself
  still cryptographically verifies (only its status flips, per the
  constitution's "soft" revocation call) — negative test: an
  unrelated third credential is not disturbed by another student's
  status change (a tenant/twin scoping check, not just a status-bit
  check).
- **V4** verify SLO harness: N sequential/concurrent calls to
  `GET /api/credentials/verify/{public_id}` against a fixture status-list
  meet a stated latency budget (record the budget and measured p95/p99 in
  the decisions doc — this is a v1 policy number, not a Book-specified
  one).
- **V5** an imported OB credential becomes a `RecognitionClaim` candidate
  (pending, not auto-trusted); a negative test confirms a
  structurally-invalid import is rejected before it reaches
  `RecognitionClaim` at all.
- **V6** harness green incl. integrity-pressure + signing-tamper
  scenarios (gate) · no code path issues `certificate`/`degree` without a
  human act (negative test) · `pytest -m phase1` + existing
  `credential_service.py`/`CourseAchievement` routes unaffected ·
  migrations up/down/up clean on an isolated Postgres.

## DoD
V1–V6 green · constitution §12/§13/§14/§15 (WS07) marked implemented ·
BOOK-10 nine-agents row updated (7/9) · BOOK-16 (or the relevant
credential/wallet Annex) updated with the signing/status-list design ·
TRACEABILITY K4 row updated · decisions note recording: the exact proof
cryptosuite chosen, the deferred-scope list (KMS, multi-method DID,
external-signature verification), the verify-SLO budget number, and the
pre-existing badge-domain redundancy (not touched, why).
