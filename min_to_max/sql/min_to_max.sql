CREATE EXTENSION min_to_max;

-- set output format to default 
SELECT min_to_max_config();

-- get min and max from a simple values list
SELECT min_to_max(val) FROM (VALUES(5),(3),(6),(7),(9),(10),(7)) t(val);

-- set output format to non-default
SELECT min_to_max_config('>>');

-- get min and max from a simple values list
SELECT min_to_max(val) FROM (VALUES(5),(3),(6),(7),(9),(10),(7)) t(val);

-- reset output format to default
SELECT min_to_max_config();

-- get min and max from strings
SELECT min_to_max(val) FROM (VALUES('a'),('b'),('c'),('d'),('e'),('f'),('g')) t(val);

-- get min and max from floats
SELECT min_to_max(val) FROM (VALUES(5.1),(3.95),(6.666),(7.222),(9),(10.5),(7.4)) t(val);

-- get min and max from dates
SELECT min_to_max(val) FROM (VALUES('2021-01-01'),('2021-01-02'),('2021-01-03'),('2021-01-04')) t(val);

-- min and max from a table comprising of integer, float, string, timestamp and date values
CREATE TEMPORARY TABLE min_to_max AS SELECT generate_series(1,1000) AS a, generate_series(1.7,1000) AS b,
generate_series(timestamp '2019-01-01', '2021-12-31', '1 day') AS c, 
generate_series(timestamp '2019-01-01', '2021-12-31', '1 day')::date as d,chr(generate_series(65,90)) AS e;

SET datestyle = 'ISO, YMD';
SELECT min_to_max(a),min_to_max(b),min_to_max(c),min_to_max(d),min_to_max(e) FROM min_to_max ;

DROP TABLE min_to_max;

DROP EXTENSION min_to_max;
