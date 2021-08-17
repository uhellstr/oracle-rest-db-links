declare
  
  lv_schema_name varchar2(128);
  lv_stmt clob;

begin
  
  lv_schema_name := '&DB_SCHEMA_NAME';
  lv_stmt := 'grant execute on rest_db_link_api.rest_db_links to '||lv_schema_name;
  execute immediate lv_stmt;

end;
/
