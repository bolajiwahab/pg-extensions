CREATE EXTENSION min_to_max;
SELECT min_to_max_config();
SELECT pg_sleep(.5);
SELECT 1;
SELECT min_to_max(val) FROM (VALUES(NULL),(NULL)) t(val);
SELECT min_to_max(val) FROM (VALUES(5),(10),(NULL)) t(val);
SELECT min_to_max(val) FROM (VALUES(5),(3),(6),(7),(9),(10),(7)) t(val);
SELECT min_to_max(val) FROM (VALUES('a'),('b'),(' ')) t(val);
SELECT min_to_max_config('>>');
SELECT min_to_max(val) FROM (VALUES(5),(3),(6),(7),(9),(10),(7)) t(val);
SELECT min_to_max_config();
DROP EXTENSION min_to_max;
