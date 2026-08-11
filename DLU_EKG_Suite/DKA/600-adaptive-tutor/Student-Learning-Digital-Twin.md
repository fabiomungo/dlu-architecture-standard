# Student Learning Digital Twin — ATA 1.0

## Purpose
A canonical, machine-readable representation of the learner's current educational state. It is not a personality profile; it stores only learning-relevant state needed to plan, explain and evaluate interventions.

## Aggregate

```text
StudentLearningTwin
├── identityRef
├── activeGoals[]
├── masteryStates[]
├── misconceptionStates[]
├── prerequisiteReadiness[]
├── learningPreferences[]
├── learningConstraints[]
├── recentEpisodes[]
├── recommendations[]
└── policyContext
```

## Core entities

| Entity | Key attributes | Notes |
|---|---|---|
| LearningGoal | goalId, type, targetUri, priority, deadline?, status | course, assessment, competency, career or learner-defined |
| MasteryState | subjectUri, mastery, confidence, evidenceCount, updatedAt | subject can be Concept/MLO/CLO/Skill |
| MisconceptionState | conceptUri, misconceptionType, probability, evidenceRefs | probabilistic, never displayed as fact without confidence |
| PrerequisiteReadiness | targetUri, readiness, blockers[] | derived from EKG dependencies |
| LearningPreference | modality, verbosity, examplePreference, language | soft preference; never overrides academic requirements |
| LearningConstraint | availability, accessibility, pacing | learner-declared or system constraints |
| LearningEpisode | intervention, response, outcome, timestamp | compact episodic record |

## Mastery semantics

`mastery ∈ [0,1]` estimates current capability.  
`confidence ∈ [0,1]` estimates reliability of that estimate.

A state with `mastery=.90, confidence=.25` is not equivalent to `mastery=.90, confidence=.95`.

## Goal priorities

1. Regulatory / safety / academic progression constraints
2. Explicit current learner goal
3. Program/course outcome targets
4. Career target
5. Optional enrichment

## Example

```json
{
  "studentId": "stu:1048",
  "activeGoals": [
    {"goalId":"goal:rag","type":"competency","targetUri":"dlu:concept/rag","priority":1,"status":"active"},
    {"goalId":"goal:career","type":"career","targetUri":"dlu:job/generative-ai-engineer","priority":3,"status":"active"}
  ],
  "masteryStates": [
    {"subjectUri":"dlu:concept/embeddings","mastery":0.87,"confidence":0.91,"evidenceCount":9},
    {"subjectUri":"dlu:concept/vector-search","mastery":0.62,"confidence":0.66,"evidenceCount":4},
    {"subjectUri":"dlu:concept/rag","mastery":0.44,"confidence":0.52,"evidenceCount":2}
  ]
}
```

## Persistence
The twin is reconstructed from canonical evidence, mastery observations and goals. Cached snapshots are allowed for performance but are not the source of truth.
