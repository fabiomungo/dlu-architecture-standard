# ADR-0027 — One exchange format for institution structure and catalog

**Status:** Accepted · **Date:** 1 September 2026
**Supersedes in practice:** the `institution-organization` / `catalogue` artifacts produced by
`backend/services/catalogue_service.py`
**Verified against:** `dlu_builder_tk` at commit `0df2427`

## Context

After the "bootstrap a tenant from files" programme (`3729914`), the estate has **two parallel
mechanisms** for exporting and importing an institution's structure and catalog. The duplication was
not designed; it was discovered while mapping the UI, and it exists because the planning evaluation
asserted that no exchange format existed for the structure layer. That assertion was wrong — it came
from searching `docs/*.schema.json` and services with "structure" in their name, and searching neither
the frontend nor `catalogue_service.py`.

### Mechanism A — `catalogue_service`, the older one, with a UI

| | |
|---|---|
| Routes | `/api/catalogue/{export,import}/{organization,catalogue}` (`backend/api/routes/catalogue.py`) |
| Format | `schema_version: "1.0"`, `artifact_type: "institution-organization"` — no JSON Schema file, no integrity hash |
| Export coverage | `Institution`, `College`, `School`, `Department`, `AcademicTerm`, `ILO`; separately `Program`, `ProgramCourse`, `PLO`, `CLO` |
| **Import coverage** | **The hierarchy is not imported at all.** `import_organization` returns `skipped: {"colleges": "hierarchy import not implemented in MVP", "schools": …}` and only upserts ILOs by code. `import_catalogue` skips content products entirely. |
| Consumers | `frontend/src/components/CatalogueManager.js` (`/organization/catalogue`) |
| Tests | none found |

### Mechanism B — the new one, without a UI

| | |
|---|---|
| Routes | `GET`/`POST /admin/tenants/{id}/{profile-bundle,structure,catalog}` |
| Format | `dlu.institution_structure.v1` and the extended `dlu.course_catalog.v1`, both with a JSON Schema, `additionalProperties: false`, business keys, canonical `sha256` |
| Coverage | both directions, plus dry-run with a structured diff, idempotence on business keys, an `orphaned` section, and refusal on a tenant-identity mismatch |
| Consumers | none — API only |
| Tests | ~1,085 lines of conformance tests |

## Decision

**Mechanism B is the single exchange format. Mechanism A is retired.**

This is not a preference between two comparable options. Mechanism A is **export-complete and
import-incomplete**: it can dump a university and cannot rebuild one, which is precisely the capability
the feature exists to provide. Mechanism B does everything A does, in both directions, with a schema, an
integrity hash, a dry-run and tests.

The blast radius is small enough to make retirement the cheap option as well as the right one: the only
consumers of A anywhere in either repository are its own route file and one React component. No test,
no script, no other service. No artifact in the old format exists in the repositories, so no file
migration is required.

## Consequences

1. `CatalogueManager` is rewired to the `structure` and `catalog` endpoints of Mechanism B. This is not
   extra work: it is the first of the four import/export screens the UI needs anyway, and it arrives
   with a diff preview the old screen never had.
2. The four `/api/catalogue/{import,export}/*` routes are deprecated. The two **export** routes become
   thin adapters delegating to B's exporters for one release, so an integration nobody has told us
   about does not break silently. The two **import** routes refuse with `501` and a message naming the
   replacement — they never did the job, so preserving their behaviour preserves nothing.
3. `catalogue_service.py`'s four functions are removed once nothing calls them, not before.
4. A guard test asserts there is exactly one import path for structure and catalog, so a third does not
   appear the way the second did.
5. The evaluation document `DLU_Institution_Exchange_Feature_Evaluation_v1.0.md` §2 carries a
   correction: the structure layer was not "a real gap, zero exchange format".

## Alternatives considered

**Keep both, with a written boundary.** Rejected. A boundary between "the export that works" and "the
import that works" is not a boundary between two purposes; it is a description of a defect. Anyone
exporting from A and importing into B would find the formats incompatible, and would be right to be
surprised.

**Retire B, extend A.** Rejected. A has no schema, no integrity hash, no dry-run, no idempotence
guarantee and no tests, and its import is an explicit MVP stub. Extending it means rebuilding B inside
it while discarding B's tests.

**Have B emit A's format for backward compatibility.** Rejected as unnecessary: no artifact in A's
format exists in either repository, and A's only consumer is a screen this decision rewires anyway.

## Open item, not blocking

The extended `dlu.course_catalog.v1` carries `programs[].plos` and `courses[].clos`, and a
`competencies` block. Whether the `CLO → competency` mapping actually resolves by `caseGuid` /
`externalUri` to the platform competency registry — as the execution backlog specified — was not
verified when this ADR was written. It should be checked before the catalog screen ships, since a
mapping that silently does not resolve looks identical to one that does.
