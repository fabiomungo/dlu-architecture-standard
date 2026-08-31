# Tutor Policy Engine — ATA 1.0

## Purpose
Select the **Next Best Learning Action (NBLA)**. The policy chooses pedagogy; the LLM renders it.

## Context
`studentState, activeGoal, targetConcept, prerequisiteReadiness, recentInterventions, assessmentEvidence, constraints`

## Candidate actions
EXPLAIN, SIMPLIFY, ELABORATE, SCAFFOLD, SOCRATIC_QUESTION, WORKED_EXAMPLE, HINT, PRACTICE, REVIEW_PREREQUISITE, REMEDIATE, CHALLENGE, REFLECT, ASSESS, REASSESS.

## Baseline score

`Score(a) = w1*ExpectedLearningGain + w2*GoalAlignment + w3*PrerequisiteReadiness + w4*GapPriority + w5*RetentionValue + w6*EngagementProbability - w7*CognitiveLoad - w8*Redundancy - w9*RiskPenalty`

Weights are policy-versioned, observable and configurable by program/tenant within governance bounds.

## Learning evolution
1. V1 rules + expert weights.
2. V1.5 offline counterfactual evaluation and calibrated propensity logging.
3. V2 contextual bandit for eligible low-risk choices.
4. RL only after governance approval and only with constrained action space.

## Reward
Default composite (illustrative; calibrate empirically): learning gain 40%, delayed retention 20%, goal progress 15%, assessment improvement 10%, constructive engagement 10%, satisfaction 5%. Engagement alone is never the optimization target.

## Policy deployment
Draft -> simulation -> shadow -> A/B or interleaving -> academic review -> approved -> canary -> production -> monitor -> rollback.
