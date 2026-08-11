// 1. Accreditation trace: CLO -> MLO -> Assessment -> Evidence
MATCH (c:Course {tenantId:$tenantId,id:$courseId})-[:DEFINES]->(clo:Outcome {type:'CLO'})
OPTIONAL MATCH (mlo:Outcome {tenantId:$tenantId,type:'MLO'})-[:CONTRIBUTES_TO]->(clo)
OPTIONAL MATCH (a:Assessment {tenantId:$tenantId})-[:ASSESSES]->(mlo)
OPTIONAL MATCH (e:Evidence {tenantId:$tenantId})-[:EVIDENCES]->(a)
RETURN clo.id, clo.statement, collect(DISTINCT mlo.id) AS mlos, collect(DISTINCT a.id) AS assessments, count(DISTINCT e) AS evidenceCount;

// 2. Prerequisite closure
MATCH p=(start:Concept {tenantId:$tenantId,id:$conceptId})<-[:PREREQUISITE_OF*1..5]-(pre:Concept)
RETURN pre.id, pre.label, length(p) AS distance ORDER BY distance;

// 3. Skill gap
MATCH (j:JobRole {tenantId:$tenantId,id:$jobRoleId})-[r:REQUIRES_SKILL]->(s:Skill)
OPTIONAL MATCH (student:Student {tenantId:$tenantId,id:$studentId})-[:HAS_MASTERY]->(ms:MasteryState)-[:OF]->(s)
WITH s, r.requiredLevel AS required, coalesce(ms.mastery,0.0) AS mastery, coalesce(ms.confidence,0.0) AS confidence
RETURN s.id, s.label, required, mastery, confidence, max(0.0,required-mastery) AS gap
ORDER BY gap DESC;

// 4. Tenant safety invariant used by repository tests
MATCH (n) WHERE exists(n.tenantId) AND n.tenantId <> $tenantId RETURN count(n) AS forbiddenRows;
