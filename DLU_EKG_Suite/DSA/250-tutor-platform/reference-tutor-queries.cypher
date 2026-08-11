// Load prerequisite blockers for a target concept
MATCH (s:Student {id:$studentId})-[:HAS_MASTERY]->(m:Mastery)-[:OF_CONCEPT]->(known:Concept),
      (pre:Concept)-[:PREREQUISITE_OF*1..3]->(target:Concept {uri:$targetUri})
WHERE known.uri = pre.uri AND m.score < $threshold
RETURN pre.uri AS prerequisite, m.score AS mastery, m.confidence AS confidence
ORDER BY mastery ASC;

// Retrieve active learning goals
MATCH (s:Student {id:$studentId})-[:HAS_GOAL]->(g:LearningGoal)-[:TARGETS]->(t)
WHERE g.status='active'
RETURN g.id, g.type, g.priority, t.uri
ORDER BY g.priority ASC;

// Intervention traceability
MATCH (i:LearningIntervention {id:$interventionId})-[:USES_STRATEGY]->(st:LearningStrategy),
      (i)-[:TARGETS_KNOWLEDGE]->(k),
      (i)-[:GENERATED_BY_POLICY]->(p:PolicyVersion)
OPTIONAL MATCH (i)-[:REMEDIATES]->(mc:Misconception)
RETURN i, st, k, p, collect(mc) AS misconceptions;
