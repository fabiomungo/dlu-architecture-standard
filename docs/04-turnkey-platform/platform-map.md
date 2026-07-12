# Turnkey Platform Map

## Existing building blocks considered by the architecture

- DLU Builder and AI authoring agents
- Moodle learning runtime
- Frappe / ERPNext Education
- Frappe CRM
- Next.js portals
- Neo4j graph services
- Keycloak identity and access management
- Kong API gateway
- n8n workflow orchestration
- Observability stack based on Grafana-compatible services
- Containerized installation and environment automation

## Architectural positioning

| Turnkey component | DLU role |
|---|---|
| DLU Builder | Academic content and course factory |
| Moodle | Learning delivery runtime |
| Frappe Education | Academic system of record and workflow backbone |
| Frappe CRM | Prospect, applicant and relationship management |
| Neo4j | Knowledge, competency and relationship graph |
| Keycloak | Identity federation and RBAC foundation |
| Kong | API governance and gateway |
| n8n | Workflow and integration automation |
| Next.js | Role-based experience portals |
| Grafana stack | Technical and product observability |

The reference architecture remains vendor-neutral; this mapping defines the Turnkey implementation profile.
