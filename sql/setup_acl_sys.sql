set serveroutput on
declare

  lv_antal number := 0;

begin


  select count(*) into lv_antal
  from dba_network_acls
  where acl = '/sys/acls/local_rest_acl_file.xml';

  
  if lv_antal > 0 then
    dbms_output.put_line('ACL local_rest_acl_file.xml exists!');
  end if;

end;
/

declare

  lv_schema_name varchar2(128);

begin

  lv_schema_name := '&DB_SCHEMA_NAME';

  DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE(
       acl => 'local_rest_acl_file.xml',
       principal => upper(lv_schema_name),
       is_grant => true,
       privilege => 'resolve',
       start_date => SYSTIMESTAMP,
       end_date => NULL
  );
  COMMIT;
                               
end;
/


-- Add ORDS Server here
-- Example ip 10.251.122.73 or localhost if ORDS running on local server.
--
--declare
--  p_in_ords_server varchar2(200);
--  
--begin
--  p_in_ords_server := '&DB_ORDS';
--  dbms_network_acl_admin.assign_acl(acl => 'local_rest_acl_file.xml', host => p_in_ords_server, lower_port => 8080, upper_port => null);
--  commit;
--end;
--/
