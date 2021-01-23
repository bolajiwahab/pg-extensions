MODULES = min_to_max_array
EXTENSION = min_to_max
DATA = min_to_max--1.0.sql
PGFILEDESC = "min_to_max - get min and max values from an input set"
REGRESS = basic min_to_max
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
