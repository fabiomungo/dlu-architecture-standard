# ExplainabilityDrawer
Status: Baseline

## Purpose
Reusable DLU EKG experience primitive.

## UX rule
Must present domain language rather than graph implementation language.

## Required states
Default · Loading · Empty · Low confidence · Stale · Restricted · Error.

## Data contract
Expose stable semantic IDs, display labels, relevant metric(s), confidence/provenance when applicable, and permission-safe drill-down target.

## Accessibility
Keyboard reachable; textual equivalent for visual state; never encode meaning by color alone.

## Paper
Create as a named reusable component with explicit variants matching states.
