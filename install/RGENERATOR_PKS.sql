create or replace PACKAGE "REST_DB_LINK_API"."RGENERATOR_PKG" 
as 
  
  procedure generator
    (
      p_in_viewname in varchar2
      ,p_in_metaurl in varchar2
      ,p_in_metaparams in varchar2
      ,p_in_format_datatypes in boolean default true
    );

end rgenerator_pkg;
/