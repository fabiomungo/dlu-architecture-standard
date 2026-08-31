# Mastery Engine Mathematical Specification (v1.1)

## State
For learner u and target k at time t, maintain a Beta posterior Beta(alpha_{u,k,t}, beta_{u,k,t}).
Expected mastery: M = alpha / (alpha + beta).
Confidence: C = 1 - exp(-(alpha + beta - alpha0 - beta0)/tau), clipped to [0,1].

## Evidence update
Each observation e contributes effective weight w_e = q_e * r_e * d_e * a_e.
- q_e: evidence quality in [0,1]
- r_e: rubric reliability / evaluator calibration in [0,1]
- d_e: temporal decay exp(-lambda_k * age_days)
- a_e: assessment authenticity / integrity factor in [0,1]
Normalize score s_e to [0,1]. Update alpha += w_e*s_e; beta += w_e*(1-s_e).

## Hierarchical propagation
Concept -> MLO -> CLO -> Skill aggregation uses weighted noisy-AND for prerequisites and weighted mean for evidentiary contributions.
Prerequisite readiness R(target) = product_i (epsilon + (1-epsilon)*M_i)^(p_i/sum p).
Outcome mastery M_outcome = sum_j w_j*M_j/sum_j w_j, but capped by prerequisite readiness when configured as hard prerequisite.

## Confidence-sensitive gap
Effective mastery E = M * (gamma + (1-gamma)*C), gamma default 0.65.
Skill gap G = max(0, required_level - E).
Priority P = G * role_importance * prerequisite_centrality * urgency.

## Forgetting / recency
Do not mutate historical observations. At query time apply d_e = exp(-lambda_k*age_days). lambda_k may vary by knowledge type; default is calibrated empirically.

## Guardrails
- Never infer zero mastery from missing evidence; use the prior.
- Separate observed assessment evidence from LLM-generated estimates.
- Human overrides are append-only observations with provenance, not destructive edits.
- Model version is mandatory on every computed state.
