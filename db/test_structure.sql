CREATE TABLE "activated_topics" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "topic_id" integer NOT NULL, "teacher_id" integer NOT NULL, "credits" integer NOT NULL, "duration" integer NOT NULL, "semester_start" integer NOT NULL, "prerequisite_id" integer, "created_at" datetime, "updated_at" datetime, "delivery_type" varchar(4) DEFAULT 'TF' NOT NULL, "hours_in_mo" integer DEFAULT 0 NOT NULL, "hours_paid" integer DEFAULT 0 NOT NULL, "teacher_gross" decimal DEFAULT 0.0 NOT NULL, "teacher_net" decimal DEFAULT 0.0 NOT NULL, "school_gross" decimal DEFAULT 0.0 NOT NULL, "notes" text);
CREATE TABLE "blacklisted_dates" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "blacklisted" datetime NOT NULL, "description" varchar(4096) DEFAULT 'Il conservatorio è chiuso', "created_at" datetime, "updated_at" datetime);
CREATE TABLE "classrooms" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar(255) NOT NULL, "place_id" integer NOT NULL, "created_at" datetime, "updated_at" datetime);
CREATE TABLE "course_starting_years" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "course_id" integer NOT NULL, "color" varchar(7) NOT NULL, "starting_year" integer(4));
CREATE TABLE "course_topic_relations" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "activated_topic_id" integer NOT NULL, "course_starting_year_id" integer NOT NULL, "teaching_typology" varchar(2) DEFAULT 'C' NOT NULL, "mandatory_flag" boolean DEFAULT 't' NOT NULL);
CREATE TABLE "courses" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar(255) NOT NULL, "acronym" varchar(5) NOT NULL, "duration" integer NOT NULL, "created_at" datetime, "updated_at" datetime);
CREATE TABLE "lesson_conflicts" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "left_lesson_id" integer, "right_lesson_id" integer);
CREATE TABLE "lessons" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "start_date" datetime NOT NULL, "end_date" datetime NOT NULL, "description" text, "activated_topic_id" integer NOT NULL, "created_at" datetime, "updated_at" datetime, "place_id" integer);
CREATE TABLE "places" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar(255) NOT NULL, "created_at" datetime, "updated_at" datetime, "street" varchar(255) DEFAULT '' NOT NULL, "number" varchar(255) DEFAULT '' NOT NULL, "city" varchar(255) DEFAULT '' NOT NULL, "url" varchar(255) DEFAULT 'http://maps.google.it/maps?f=q&source=s_q&hl=it&geocode=&q=padova&sll=45.419721,11.888237&sspn=0.027653,0.077162&ie=UTF8&hq=&hnear=Padova,+Veneto&ll=45.409568,11.876585&spn=0.006914,0.01929&t=h&z=16&iwloc=A' NOT NULL);
CREATE TABLE "schema_migrations" ("version" varchar(255) NOT NULL);
CREATE TABLE "topics" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar(255) NOT NULL, "acronym" varchar(7) NOT NULL, "color" varchar(7) NOT NULL, "level" integer, "description" text, "created_at" datetime, "updated_at" datetime);
CREATE TABLE "users" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "login" varchar(255) NOT NULL, "first_name" varchar(255) NOT NULL, "last_name" varchar(255) NOT NULL, "email" varchar(255) NOT NULL, "url" varchar(255), "type" varchar(255) NOT NULL, "password" varchar(255) NOT NULL, "created_at" datetime, "updated_at" datetime, "teacher_typology" varchar(1) DEFAULT 'I' NOT NULL);
CREATE INDEX "index_activated_topics_on_teacher_id" ON "activated_topics" ("teacher_id");
CREATE INDEX "index_activated_topics_on_topic_id" ON "activated_topics" ("topic_id");
CREATE INDEX "index_course_starting_years_on_course_id" ON "course_starting_years" ("course_id");
CREATE INDEX "index_course_topic_relations_on_activated_topic_id" ON "course_topic_relations" ("activated_topic_id");
CREATE INDEX "index_course_topic_relations_on_course_starting_year_id" ON "course_topic_relations" ("course_starting_year_id");
CREATE INDEX "index_lesson_conflicts_on_left_lesson_id" ON "lesson_conflicts" ("left_lesson_id");
CREATE INDEX "index_lesson_conflicts_on_right_lesson_id" ON "lesson_conflicts" ("right_lesson_id");
CREATE INDEX "index_lessons_on_activated_topic_id" ON "lessons" ("activated_topic_id");
CREATE INDEX "index_lessons_on_place_id" ON "lessons" ("place_id");
CREATE UNIQUE INDEX "unique_schema_migrations" ON "schema_migrations" ("version");
INSERT INTO schema_migrations (version) VALUES ('20090115102353');

INSERT INTO schema_migrations (version) VALUES ('20090122095939');

INSERT INTO schema_migrations (version) VALUES ('20090205103341');

INSERT INTO schema_migrations (version) VALUES ('20090217100014');

INSERT INTO schema_migrations (version) VALUES ('20090217100909');

INSERT INTO schema_migrations (version) VALUES ('20090217115354');

INSERT INTO schema_migrations (version) VALUES ('20090303110107');

INSERT INTO schema_migrations (version) VALUES ('20090303110115');

INSERT INTO schema_migrations (version) VALUES ('20090827093516');

INSERT INTO schema_migrations (version) VALUES ('20090916171559');

INSERT INTO schema_migrations (version) VALUES ('20091111202754');

INSERT INTO schema_migrations (version) VALUES ('20091111220454');

INSERT INTO schema_migrations (version) VALUES ('20091115215549');

INSERT INTO schema_migrations (version) VALUES ('20100105071508');

INSERT INTO schema_migrations (version) VALUES ('20100107002319');

INSERT INTO schema_migrations (version) VALUES ('20100303232132');

INSERT INTO schema_migrations (version) VALUES ('20100221031636');

INSERT INTO schema_migrations (version) VALUES ('20100221003400');

INSERT INTO schema_migrations (version) VALUES ('20100107175752');