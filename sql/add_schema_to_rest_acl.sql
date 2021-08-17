REM
REM This script setup the REST_DB_LINK Generator API
REM This script must be run as SYS/INTERNAL or any DBA user with correct permissions
REM Ulf Hellstrom, Epicotech oraminute@gmail.com 2021-06
REM
@setup_params.sql
@setup_acl_sys.sql
@grants.sql

