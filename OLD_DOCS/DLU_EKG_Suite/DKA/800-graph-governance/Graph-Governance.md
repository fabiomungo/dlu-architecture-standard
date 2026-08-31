# Graph Governance

- Stable URI policy: `https://dlu.ai/ekg/{entity-type}/{id}`.
- No destructive rename of canonical IDs; use aliases/deprecation.
- Every edge type has direction, semantic definition, cardinality and provenance requirements.
- Student mastery is modeled as observations, not as a permanent `KNOWS` edge.
- Production graph projections must enforce tenant and ACL context before returning data.
