# ADR-0020 — The Experience Lens is a governed projection contract

Status: Accepted (2026-08-09, implemented — EKG-W0-01…W6-08, see TRACEABILITY.md)
Related: ADR-0019 (EKG platform subsystem), EDR-001 (bounded graph), EDR-002 (mastery ≠ confidence), BOOK-17, BOOK-06/07/08, BOOK-19
Source: DLU Architecture Suite — EKG 1.1 UI/UX Experience Design Reference Guide (DXA)
Note: replaces the earlier working reference to "ADR-0015" for this decision (0015 is already assigned to gate-numbering reconciliation).

## Context

Graph-derived knowledge is powerful but hostile to end users if exposed raw: node-link diagrams, ontology labels and unbounded traversals overwhelm students, faculty, deans and provosts. Left to each screen, "how much graph to show" becomes an inconsistent, unsafe, per-team decision — leaking data across ACL boundaries and collapsing distinct concepts (e.g. mastery vs confidence). A single, governed abstraction is required between the EKG and every experience.

## Options considered

1. **Direct graph exposure / generic graph explorer.** Maximally flexible; unusable, unsafe (ACL leakage), high cognitive load. Rejected.
2. **Ad-hoc per-screen dashboards.** Ships fast; inconsistent semantics, duplicated ACL logic, mastery/confidence conflation, no reuse. Rejected.
3. **A governed Lens abstraction: a projection contract per role and intent.** (Chosen.)

## Decision

- The experience layer exposes an explicit **EKG Lens** abstraction. A Lens is **not** a dashboard configuration — it is a **governed projection contract** defining, for a specific role and intent: **visible entities, metrics, allowed graph depth, ranking logic, permitted actions, explainability level and ACL**. Formally: `Role × Intent × Scope × Projection × Depth × Actions × ACL`.
- **North-star rule:** never expose the whole graph; display the **smallest projection** that supports the user's current decision.
- **Progressive disclosure L0→L3:** L0 decision signal (not a graph) → L1 plain-language explanation → L2 drill-down into contributing outcomes/concepts/evidence → L3 **bounded local graph only when topology answers the question** (≤ 12–20 nodes, EDR-001).
- **Table before graph:** if a table, matrix, path or ordered list answers the question, a node-link graph MUST NOT be used.
- **Mastery ≠ confidence** are two distinct visual concepts everywhere (EDR-002).
- **Projection services sit between Neo4j and the UI.** The browser never queries Neo4j and never computes mastery; ACL/authorization is reflected in every projection and every drill-down (own evidence vs cohort aggregate vs institutional metric).
- Cross-role navigation is consistent: **signal → cause → evidence → action**; every metric is explainable by drill-down to source outcomes/evidence.
- Lens contracts and access grants are governed artefacts (`ekg_lens_contracts`, `lens_access_grants`) tied to RBAC+ABAC.

## Consequences

**Positive:** consistent, safe, low-cognitive-load experiences across Student/Faculty/Dean/Provost; ACL enforced uniformly; reuse of primitives (metric card, heatmap/matrix, path ladder, trace chain, bounded local graph); mastery/confidence never conflated; graph shown only where it earns its place.
**Costs/risks:** a projection/view-model tier and a Lens catalogue must be built and governed; designers must resist "just show the graph." 
**Enforcement:** UI review/lint rejects raw graph dumps where a table/matrix/path suffices, Neo4j/mastery computation in the browser, and drill-downs that bypass ACL; `EKG-W5-01` implements the Lens contracts and role lenses; skill `ekg-lens` encodes the rules.

## Related artifacts

`DLU_EKG_Suite/DXA/*` (Experience Principles, EDR-001/002, screens, components); skill `ekg-lens`; sprints `EKG-W2-05`, `EKG-W5-01`; BOOK-17.
