CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" INTEGER PRIMARY KEY, "inserted_at" TEXT_DATETIME);
CREATE TABLE IF NOT EXISTS "words" ("user_id" INTEGER NOT NULL, "word" TEXT NOT NULL, "pronunciation" TEXT NOT NULL, "senses" JSON NOT NULL, "inserted_at" TEXT_DATETIME NOT NULL, "updated_at" TEXT_DATETIME NOT NULL, PRIMARY KEY ("user_id", "word", "pronunciation"));
CREATE TABLE IF NOT EXISTS "longman_words" ("user_id" INTEGER NOT NULL, "word" TEXT NOT NULL, "pronunciation" TEXT NOT NULL, "senses" JSON NOT NULL, "inserted_at" TEXT_DATETIME NOT NULL, "updated_at" TEXT_DATETIME NOT NULL, PRIMARY KEY ("user_id", "word", "pronunciation"));
CREATE TABLE IF NOT EXISTS "kanji_dict" ("frequency" INTEGER, "jlpt" INTEGER, "jlpt_full" TEXT, "kanji" TEXT, "radical" TEXT, "radvar" TEXT, "phonetic" TEXT, "idc" TEXT, "compact_meaning" TEXT, "meaning" TEXT, "reg_on" TEXT, "reg_kun" TEXT, "onyomi" TEXT, "kunyomi" TEXT, "nanori" TEXT, "strokes" INTEGER, "type" TEXT, "grade" TEXT, "kanken" TEXT, "rtk1_3_new" INTEGER, "ko2001" INTEGER, "ko2301" INTEGER, "wrp_jkf" INTEGER, "wanikani" INTEGER) STRICT;
CREATE INDEX "kanji_dict_kanji_index" ON "kanji_dict" ("kanji");
INSERT INTO schema_migrations VALUES(20220212223410,'2022-05-08T11:18:24');
INSERT INTO schema_migrations VALUES(20220508111755,'2022-05-08T11:18:24');
INSERT INTO schema_migrations VALUES(20220703111736,'2022-07-03T11:52:36');
