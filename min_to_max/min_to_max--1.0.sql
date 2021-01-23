/* min_to_max.sql */
-- complain if script is sourced in psql, rather than via CREATE EXTENSION

\echo Use "CREATE EXTENSION min_to_max" to load this file. \quit

CREATE OR REPLACE FUNCTION min_to_max_array(anyarray, anyelement) 
  RETURNS anyarray
AS '$libdir/min_to_max_array','min_to_max_array'
LANGUAGE C IMMUTABLE;

COMMENT ON FUNCTION min_to_max_array(anyarray, anyelement) IS 'builds an array from an input set for min_to_max aggregate.';

CREATE OR REPLACE FUNCTION min_to_max(anyarray)
  RETURNS text
AS $def$
    WITH max AS (
        SELECT val 
          FROM unnest($1) val 
         WHERE val IS NOT NULL ORDER BY 1 DESC LIMIT 1
    )
    , min AS (
        SELECT val 
          FROM unnest($1) val 
         WHERE val IS NOT NULL ORDER BY 1 ASC LIMIT 1
    ) 
    SELECT min.val || ' -> ' || max.val FROM min, max;
$def$
LANGUAGE sql IMMUTABLE STRICT;

COMMENT ON FUNCTION min_to_max(anyarray) IS 'returns minimum and maximum values from an input set for min_to_max aggregate.';

CREATE AGGREGATE min_to_max (anyelement)
(
    sfunc = min_to_max_array,
    initcond = '{}',
    stype = anyarray,
    finalfunc = min_to_max
);
COMMENT ON AGGREGATE min_to_max(anyelement) IS 'an aggregate that returns a text formatted like: min_to_max for any type, 
where min and max are minimum and maximum values of the list respectively.';

-- make the aggregate output configurable
CREATE OR REPLACE FUNCTION min_to_max_config(p_output text DEFAULT '->')
  RETURNS void
AS $conf$
BEGIN
    EXECUTE format($func$
        CREATE OR REPLACE FUNCTION min_to_max(anyarray)
          RETURNS text
        AS $def$ 
            WITH max AS (
                SELECT val 
                  FROM unnest($1) val 
                 WHERE val IS NOT NULL ORDER BY 1 DESC LIMIT 1
            )
            , min AS (
                SELECT val 
                  FROM unnest($1) val 
                 WHERE val IS NOT NULL ORDER BY 1 ASC LIMIT 1
            ) 
            SELECT min.val || ' %1$s ' || max.val FROM min, max;
        $def$
        LANGUAGE sql IMMUTABLE STRICT
    $func$, p_output);
END
$conf$
LANGUAGE plpgsql;
COMMENT ON FUNCTION min_to_max_config(text) IS 'helper function to configure the output format of min_to_max aggregate.';
