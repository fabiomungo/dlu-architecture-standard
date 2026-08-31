# Learning Evidence & Misconceptions — ATA 1.0

## Evidence classes

### QualifiedEvidence
May update assessed mastery with normal weight. Examples: graded quiz item, rubric-scored assignment, proctored or authenticated assessment.

### TutorEvidence
Generated from a tutor micro-assessment. Carries evaluator model/version, prompt, rubric and confidence. Weight is capped unless validated.

### InformalSignal
Conversation-derived clue (hesitation, explanation quality, repeated error). Used for diagnosis and intervention planning; does not directly drive high-stakes mastery.

## Evidence weighting

`effectiveWeight = baseWeight × reliability × authenticity × recency × difficultyCalibration`

## Misconception state
A misconception is represented as a hypothesis:

```json
{
  "conceptUri":"dlu:concept/semantic-search",
  "type":"confuses_with_keyword_search",
  "probability":0.74,
  "evidenceRefs":["ev:91","ev:104"],
  "status":"active"
}
```

It must be re-evaluated after remediation. The Tutor should say “It looks like...” rather than asserting a misconception as a fact when confidence is limited.
