# Pedagogical Strategy Ontology — ATA 1.0

## Strategy taxonomy

| Strategy | Intent | Typical trigger |
|---|---|---|
| EXPLAIN | introduce or clarify | low/unknown mastery |
| SIMPLIFY | reduce representational complexity | repeated confusion |
| ELABORATE | add depth/connections | medium mastery, high confidence |
| SCAFFOLD | split complex task | low prerequisite readiness |
| SOCRATIC_QUESTION | induce reasoning | target Bloom Analyze/Evaluate |
| WORKED_EXAMPLE | model procedure | procedural concept, low mastery |
| HINT | preserve productive struggle | near-success attempt |
| PRACTICE | strengthen retrieval/application | adequate prerequisite readiness |
| REVIEW_PREREQUISITE | repair blocker | dependency gap detected |
| REMEDIATE | address persistent misconception | repeated evidence pattern |
| CHALLENGE | increase difficulty | high mastery/high confidence |
| REFLECT | metacognitive consolidation | after meaningful activity |
| ASSESS | collect qualified evidence | outcome checkpoint |
| REASSESS | verify remediation/retention | after intervention or time decay |

## LearningIntervention

Properties: `strategy`, `targetUri`, `goalRef`, `difficulty`, `bloomTarget`, `estimatedEffort`, `maxHints`, `contentRefs`, `policyVersion`, `explanation`.

## Selection contract
The Pedagogical Policy Engine selects the strategy and constraints. The LLM realizes the intervention within that policy. A generated answer must not silently change the selected strategy.

## Strategy graph examples

```text
REVIEW_PREREQUISITE -> WORKED_EXAMPLE -> PRACTICE -> REASSESS
EXPLAIN -> SOCRATIC_QUESTION -> REFLECT
PRACTICE -> HINT -> HINT -> WORKED_EXAMPLE (if repeated failure)
```
