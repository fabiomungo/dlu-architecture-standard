# STU-10 — Skills & Mastery
Status: Catalogue baseline  
Owner: UX  
Roles: student  
Primary intent: inspect mastery/confidence

## User outcome
The user can complete the primary decision/action without seeing irrelevant graph complexity.

## Information hierarchy
1. Signal / status
2. Key explanation
3. Recommended action or drill-down
4. Evidence / provenance on demand
5. Local graph only when relational structure adds value

## Components
Select from DXA-200 component library.

## View model
Role-safe projection assembled by EKG Experience/Projection service.

## EKG mapping
Document exact node/edge types during detailed design.

## API & events
Bind to DSA contracts; no direct Neo4j calls from UI.

## Permissions
Role + tenant + object scope + purpose.

## Required states
Loading · Empty · Partial/low-confidence · Restricted · Error · Stale.

## Telemetry
Open, drill-down, recommendation accepted/rejected, task completion, explainability opened.

## Paper artifact
Create one desktop primary frame plus responsive states; link component instances to DXA-200 naming.
