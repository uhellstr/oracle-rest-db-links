create table "REST_DB_LINK_API".logtab( tstmp timestamp default localtimestamp
                   , msg   varchar2(4000)
                   );
                   
                   
create or replace procedure "REST_DB_LINK_API".lg(p_msg in varchar2)
is
  pragma autonomous_transaction;
begin
  insert into logtab(msg) values (p_msg);
  commit;
exception
  when others then null;  
end;
/
show errors
