# OLD_DOCS — archived documentation

**Archived 31 August 2026.** Every file below was **moved**, not deleted, and keeps its original
relative path under this folder. Its full history is still in git; restoring one is a single `mv`.

## Why a file is here

A document was archived when it had no live claim on anyone's attention, judged on measurable signals
rather than taste:

- it is a point-in-time record (a sprint note, a phase report, a per-ticket completion or verification
  summary, a UAT or validation run, a generated report) — true when it was written, and not a
  description of the system as it is now;
- it belongs to a superseded toolchain (the RooCode prompt libraries), except where code or CI cites it
  as a specification;
- it is a byte-identical duplicate of a copy that was kept;
- it is superseded by a later version in the same family;
- it declares itself superseded or deprecated in its own header;
- or nothing in the codebase, the CI, or any live document has referenced it, and it has not been
  touched in over ninety days.

**Nothing cited by code or CI was archived**, whatever its age, unless its filename was too generic for
the citation to be attributed to it.

## Before you restore something

Ask what it would be the authority on. If a kept document already answers the same question, restoring
this one recreates the drift the archive was meant to end. If nothing answers it, the right move is
usually to write the answer into a kept document and leave this one here as the source.

The full reasoning, file by file, is in `docs/DLU_Documentation_Triage_Register_v1.0.md`.
