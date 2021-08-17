REM
REM This script setup the REST_DB_LINK Generator API
REM This script must be run as SYS/INTERNAL or any DBA user with correct permissions
REM Ulf Hellstrom, Epicotech oraminute@gmail.com 2021-06
REM
prompt "Creating user REST_DB_LINK_API"
@rest_db_link_user.sql
prompt "Setting upp Access Control Lists for REST_DB_LINK_API to allow http(s)"
@setup_acl_sys.sql
prompt "Setting up packages"
@logging.sql
@rest_db_links.pks
@rest_db_links.pkb
@RGENERATOR_PKS.sql
@RGENERATOR_PKB.sql
@grant_rest_db_link.sql
