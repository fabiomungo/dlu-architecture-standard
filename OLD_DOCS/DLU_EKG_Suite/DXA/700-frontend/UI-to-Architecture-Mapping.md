# DXA-700 — Frontend Architecture Mapping

UI components consume typed View Models. The UI never builds Cypher and never queries Neo4j directly.

`Screen → Component → ViewModel → REST/GraphQL → Projection Service → EKG/analytics`

Recommended implementation: web shell in React/Next.js where appropriate; Flutter for native/mobile surfaces; shared token and schema packages; generated API clients from OpenAPI/GraphQL; server-side authorization plus client capability hints.
