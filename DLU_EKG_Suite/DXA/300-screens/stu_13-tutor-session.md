# STU-13 — Adaptive Tutor Session

## Purpose
Primary workspace for an adaptive tutoring episode.

## Layout
1. Session header: active goal + current topic.
2. Conversation / activity canvas.
3. Compact “Why this?” action for adaptive interventions.
4. Progress rail: prerequisite -> target -> checkpoint.
5. Controls: hint, example, try myself, change goal, end session.

## View model
`sessionId, activeGoal, target, strategy, difficulty, masterySummary, confidenceSummary, messages[], nextActions[], explanationRef`

## Guardrails
Do not show full EKG. Do not expose hidden chain-of-thought. Explain decisions using observable state and policy rationale only.
