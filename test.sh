#!/usr/bin/env bash
# Runs inside the candidate image as UID 26. Proves that PostgreSQL is the
# expected version, starts with VectorChord preloaded the way Immich's cluster
# runs it, and can build and use a vchordrq index -- the index Immich searches.
set -euo pipefail

: "${PG_EXPECTED:?set PG_EXPECTED to the major.minor the image must report}"

initdb -D /tmp/pg -U postgres >/dev/null
pg_ctl -D /tmp/pg -w -l /tmp/pg.log \
  -o "-c shared_preload_libraries=vchord -c listen_addresses= -c unix_socket_directories=/tmp" \
  start >/dev/null || { cat /tmp/pg.log; exit 1; }

q() { psql -h /tmp -U postgres -X -A -t -q -v ON_ERROR_STOP=1 -c "$1"; }

echo "server_version $(q "SHOW server_version")"
# server_version carries Debian's suffix; the number is 170012 for 17.12.
want=$(( ${PG_EXPECTED%%.*} * 10000 + ${PG_EXPECTED#*.} ))
[ "$(q "SHOW server_version_num")" = "$want" ] || { echo "expected PostgreSQL $PG_EXPECTED"; exit 1; }

q "CREATE EXTENSION vchord CASCADE"
q "SELECT extname || ' ' || extversion FROM pg_extension WHERE extname IN ('vector', 'vchord') ORDER BY 1"

q "CREATE TABLE t (v vector(3))"
q "INSERT INTO t SELECT ARRAY[random(), random(), random()]::vector FROM generate_series(1, 1000)"
q "CREATE INDEX t_v ON t USING vchordrq (v vector_l2_ops)"

plan=$(PGOPTIONS="-c enable_seqscan=off" q "EXPLAIN SELECT 1 FROM t ORDER BY v <-> '[0.5,0.5,0.5]' LIMIT 10")
echo "$plan" | grep -q "t_v" || { echo "the query did not use the vchordrq index:"; echo "$plan"; exit 1; }
rows=$(PGOPTIONS="-c enable_seqscan=off" q "SELECT count(*) FROM (SELECT 1 FROM t ORDER BY v <-> '[0.5,0.5,0.5]' LIMIT 10) s")
[ "$rows" = 10 ] || { echo "expected 10 rows from the index scan, got $rows"; exit 1; }
echo "vchordrq index built and used"

pg_ctl -D /tmp/pg -w stop >/dev/null
