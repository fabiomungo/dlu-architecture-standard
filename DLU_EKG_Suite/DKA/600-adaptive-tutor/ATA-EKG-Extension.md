# ATA 1.0 — EKG Extension

## New node types

`LearningGoal`, `LearningIntervention`, `LearningStrategy`, `TutorSession`, `TutorTurn`, `LearningEpisode`, `Misconception`, `Recommendation`, `LearningPlan`, `TutorEvidence`, `PolicyVersion`.

## New edge types

| Edge | From -> To | Cardinality |
|---|---|---|
| HAS_GOAL | Student -> LearningGoal | 0..N |
| TARGETS | LearningGoal -> Concept/MLO/CLO/Skill/JobRole | exactly 1 |
| HAS_SESSION | Student -> TutorSession | 0..N |
| CONTAINS_TURN | TutorSession -> TutorTurn | 1..N |
| USES_STRATEGY | LearningIntervention -> LearningStrategy | exactly 1 |
| TARGETS_KNOWLEDGE | LearningIntervention -> Concept/MLO/CLO/Skill | 1..N |
| PRODUCES_SIGNAL | TutorTurn -> TutorEvidence | 0..N |
| SUPPORTS | TutorEvidence -> MasteryObservation | 0..N |
| SUGGESTS | TutorEvidence -> Misconception | 0..N |
| REMEDIATES | LearningIntervention -> Misconception | 0..N |
| RECOMMENDS | LearningPlan -> LearningIntervention | 1..N |
| GENERATED_BY_POLICY | LearningIntervention -> PolicyVersion | exactly 1 |

## URI examples

`dlu:student/{id}/goal/{goalId}`  
`dlu:tutor/session/{uuid}`  
`dlu:tutor/intervention/{uuid}`  
`dlu:pedagogy/strategy/WORKED_EXAMPLE`  
`dlu:tutor/policy/{version}`

## Neo4j constraints

```cypher
CREATE CONSTRAINT learning_goal_id IF NOT EXISTS FOR (n:LearningGoal) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT tutor_session_id IF NOT EXISTS FOR (n:TutorSession) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT intervention_id IF NOT EXISTS FOR (n:LearningIntervention) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT policy_version_id IF NOT EXISTS FOR (n:PolicyVersion) REQUIRE n.id IS UNIQUE;
```
