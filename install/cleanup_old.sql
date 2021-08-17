set serveroutput on
DECLARE
  lv_count number := 0;
BEGIN

  SELECT COUNT(*) 
  INTO lv_count
  FROM DBA_USERS
  WHERE USERNAME = 'REST_DB_LINK_TEST';

  IF lv_count > 0 THEN      
    dbms_output.put_line('Dropping schema REST_DB_LINK_TEST');
    EXECUTE IMMEDIATE 'DROP USER REST_DB_LINK_TEST CASCADE';
  END IF;

END;
/


set serveroutput on
declare
  lv_antal number := 0;

begin

  dbms_output.put_line('Removing ACL for REST_DB_LINK_TEST');

  select count(*) into lv_antal
  from dba_network_acls
  where acl = '/sys/acls/local_rest_acl_file.xml';


  if lv_antal > 0 then
    dbms_output.put_line('ACL local_rest_acl_file.xml exists dropping');
    DBMS_NETWORK_ACL_ADMIN.DROP_ACL(
         acl => 'local_rest_acl_file.xml'
    );
    commit;
  end if;
end;
/
