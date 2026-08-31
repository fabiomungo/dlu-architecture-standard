# DLU Architecture Suite

Version: 1.1  
Status: Working Architecture Baseline  
Purpose: single, versionable architecture workspace for DLU product, knowledge, experience and solution design.

## Repositories

- **DKA — DLU Knowledge Architecture**: EKG ontology, semantic model, standards mapping, mastery/evidence semantics.
- **DXA — DLU Experience Architecture**: UX principles, EKG visualization, component library, screen catalogue, AI interaction patterns.
- **DSA — DLU Solution Architecture**: microservices, APIs, events, deployment, security, integrations and observability.
- **DPA — DLU Product Architecture**: capabilities, workspaces, roadmap, release model, product governance and traceability.

## Operating model

Every production feature should be traceable across four views:

`Product capability (DPA) → Experience/view (DXA) → Semantic entities (DKA) → Services/APIs/events (DSA)`

Architecture decisions are recorded as ADRs; experience decisions as EDRs. Small Markdown files are preferred over monolithic documents.

## Maintenance rules

1. One concept/component/screen/decision per file where practical.
2. Stable IDs in filenames and front matter.
3. Never expose raw graph complexity directly to end users.
4. Every screen identifies owner, role, intent, data/view model, APIs, permissions and telemetry.
5. Every semantic change states migration and compatibility impact.
6. Every cross-repository change updates `TRACEABILITY.md`.

## ATA 1.0 — Adaptive Tutor Architecture
The suite includes a cross-cutting adaptive tutoring architecture. Start at `ATA/README.md`. ATA is distributed across DKA, DXA, DSA and DPA so that knowledge semantics, experience, implementation and product capability remain governed by their owning domains.
