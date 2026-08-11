// DLU EKG 1.1 - Neo4j bootstrap schema
CREATE CONSTRAINT tenant_id IF NOT EXISTS FOR (n:Tenant) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT program_id IF NOT EXISTS FOR (n:Program) REQUIRE (n.tenantId, n.id) IS NODE KEY;
CREATE CONSTRAINT course_id IF NOT EXISTS FOR (n:Course) REQUIRE (n.tenantId, n.id) IS NODE KEY;
CREATE CONSTRAINT module_id IF NOT EXISTS FOR (n:Module) REQUIRE (n.tenantId, n.id) IS NODE KEY;
CREATE CONSTRAINT lesson_id IF NOT EXISTS FOR (n:Lesson) REQUIRE (n.tenantId, n.id) IS NODE KEY;
CREATE CONSTRAINT outcome_id IF NOT EXISTS FOR (n:Outcome) REQUIRE (n.tenantId, n.id) IS NODE KEY;
CREATE CONSTRAINT concept_id IF NOT EXISTS FOR (n:Concept) REQUIRE (n.tenantId, n.id) IS NODE KEY;
CREATE CONSTRAINT skill_id IF NOT EXISTS FOR (n:Skill) REQUIRE (n.tenantId, n.id) IS NODE KEY;
CREATE CONSTRAINT assessment_id IF NOT EXISTS FOR (n:Assessment) REQUIRE (n.tenantId, n.id) IS NODE KEY;
CREATE CONSTRAINT evidence_id IF NOT EXISTS FOR (n:Evidence) REQUIRE (n.tenantId, n.id) IS NODE KEY;
CREATE CONSTRAINT mastery_obs_id IF NOT EXISTS FOR (n:MasteryObservation) REQUIRE (n.tenantId, n.id) IS NODE KEY;
CREATE CONSTRAINT jobrole_id IF NOT EXISTS FOR (n:JobRole) REQUIRE (n.tenantId, n.id) IS NODE KEY;
CREATE CONSTRAINT mapping_id IF NOT EXISTS FOR (n:ExternalMapping) REQUIRE (n.tenantId, n.id) IS NODE KEY;
CREATE INDEX concept_label IF NOT EXISTS FOR (n:Concept) ON (n.tenantId, n.label);
CREATE INDEX outcome_type IF NOT EXISTS FOR (n:Outcome) ON (n.tenantId, n.type);
CREATE INDEX mastery_student IF NOT EXISTS FOR (n:MasteryObservation) ON (n.tenantId, n.studentId, n.observedAt);
CREATE FULLTEXT INDEX ekg_text IF NOT EXISTS FOR (n:Concept|Outcome|LearningResource) ON EACH [n.label, n.title, n.statement, n.description];
// Vector indexes should be created with dimensions matching the production embedding model.
