set define off;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "REST_DB_LINK_API"."RGENERATOR_PKG" 
as


  type meta_col_rec is record
  (
    columnname varchar2(128)
    ,datatype varchar2(30)
  );
  
  type meta_link_rec is record
  (
    rel varchar2(30)
    ,href varchar2(4000)
    ,mediatype varchar2(4000)
  );
    
  --%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

--*=============================================================================
--* Private API 
--*=============================================================================

  function ret_rest_ddl_view_stub
  return clob
  --*===========================================================================
  --* NAME:        ret_rest_ddl_view_stub
  --*
  --* DESCRIPTION: Returns a placeholder template to generate DDL for a view
  --*              
  --*
  --* CREATED:     2021-05-06
  --* AUTHOR:      hellsulf, EpicoTech
  --*
  --*
  --*===========================================================================  
  is
   lv_stmt_stub clob;
  begin
    lv_stmt_stub := q'#set define off
create or replace view ${VIEWNAME}
as
select ${VIEWCOLS}
from table(rest_db_link_api.rest_db_links.http_rest_response('${RESTURL}${QPARAMS}')) t
,json_table(t.response, '$.items[*]'
columns ( ${JSONCOLS}
)
) j
/
show errors#';
                     
    return lv_stmt_stub;
  end ret_rest_ddl_view_stub;
  
  --%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  function ret_metadata_masterkeys
            (
              p_in_metaurl in varchar2
            ) return clob
  --*===========================================================================
  --* NAME:        ret_metadata_masterkeys
  --*
  --* DESCRIPTION: Helper and sanity function that checks masterkyes from
  --*              metadata-catalog to check we have the correct keys.
  --*              
  --*
  --* CREATED:     2021-05-17 (The day of Norway)
  --* AUTHOR:      hellsulf, EpicoTech
  --*
  --*
  --*===========================================================================            
  is
    
    lv_retval clob;
    lv_metadata   json_object_t;
    lv_masterkeys json_array_t;
    lv_key_list   json_key_list;
    
  begin

    lv_masterkeys := new json_array_t;
    lv_metadata := json_object_t.parse(rest_db_links.http_rest_request(p_in_metaurl));
    lv_key_list := lv_metadata.get_keys;
    for i in 1..lv_key_list.count loop
      lv_masterkeys.append(lv_key_list(i));
    end loop;
    lv_retval := lv_masterkeys.to_string;
  
    return lv_retval;
    
  end ret_metadata_masterkeys;
  
  --%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  

  function ret_metadata_object_name
            (
              p_in_metaurl in varchar2
            ) return varchar2
  --*===========================================================================
  --* NAME:        ret_metadata_object_name
  --*
  --* DESCRIPTION: Returns name of remote object we will REST'ify.
  --*              
  --*              
  --*
  --* CREATED:     2021-05-11 
  --* AUTHOR:      hellsulf, EpicoTech
  --*
  --*
  --*===========================================================================            
  is
  
    lv_clob clob;
    lv_json json_object_t;
    lv_viewname varchar2(128);  
    lv_retval varchar2(128);
  
  begin
  
    lv_clob := rest_db_links.http_rest_request(p_in_metaurl);
    lv_json := json_object_t.parse(lv_clob);
    lv_viewname := lv_json.get_string('name'); 
    lv_retval := lv_viewname;
    
    return lv_retval;
    
  end ret_metadata_object_name;  

  --%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  function gen_datatype_format
            (
              p_in_colname in varchar2
              ,p_in_datatype in varchar2
             ) return varchar2
  --*===========================================================================
  --* NAME:        gen_datatype_format
  --*
  --* DESCRIPTION: Helper function that format number,date cols 
  --*              if requested as inparameter to generator
  --*              
  --*
  --* CREATED:     2021-05-18 
  --* AUTHOR:      hellsulf, EpicoTech
  --*
  --*
  --*===========================================================================             
  is
        lv_retval varchar2(4000);      
  begin
  
   case p_in_datatype
   when 'NUMBER' then
     lv_retval := 'to_number('||upper(p_in_colname)||', '||''''||'999999999999D99999999'||''''||','||''''||'nls_numeric_characters='||''''||''''||',.'||''''||''''||''''||') '||upper(p_in_colname);
   when 'DATE' then
     lv_retval := 'to_date('||upper(p_in_colname)||','||''''||'RRRR-MM-DD HH24:MI:SS'||''''||') '||upper(p_in_colname);
   when 'TIMESTAMP' then
      lv_retval := 'to_timestamp('||upper(p_in_colname)||','||''''||'RRRR-MM-DD HH24:MI:SSXFF TZR'||''''||') '||upper(p_in_colname);
   else
      lv_retval := upper(p_in_colname);
   end case;
   
   return lv_retval;
   
  end gen_datatype_format;

  --%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  function gen_sel_row
             (
                p_in_colname in varchar2
                ,p_in_datatype in varchar2
                ,p_in_first_row boolean default false
                ,p_in_format_datatypes in boolean default false
             ) return clob
  --*===========================================================================
  --* NAME:        gen_sel_row
  --*
  --* DESCRIPTION: Helper function that returns a row for the select-- from
  --*              part and if requested also format datatypes like number
  --*              and dates.
  --*              
  --*
  --* CREATED:     2021-05-11 
  --* AUTHOR:      hellsulf, EpicoTech
  --*
  --*
  --*===========================================================================             
  is
   
    lv_retval clob;
  
  begin
  
    if p_in_first_row then
      if p_in_format_datatypes then
         lv_retval := gen_datatype_format
                        (
                          p_in_colname => p_in_colname
                          ,p_in_datatype => p_in_datatype
                        );
      else
        lv_retval := upper(p_in_colname);
      end if;
    else
      if p_in_format_datatypes then
        lv_retval := ', '||gen_datatype_format
                        (
                          p_in_colname => p_in_colname
                          ,p_in_datatype => p_in_datatype
                        );
      else
        lv_retval := ', '||upper(p_in_colname);
      end if;
    end if;
    
    return lv_retval;
    
  end gen_sel_row;

  --%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  function gen_json_tab_row
             (
                p_in_colname in varchar2
                ,p_in_datatype in varchar2
                ,p_in_first_row boolean default false
             ) return clob
  --*===========================================================================
  --* NAME:        gen_json_tab_row
  --*
  --* DESCRIPTION: Helper function that returns a row for the from json_table()
  --*              part of the DDL.
  --*              
  --*              
  --*
  --* CREATED:     2021-05-11 
  --* AUTHOR:      hellsulf, EpicoTech
  --*
  --*
  --*===========================================================================             
  is
   
    lv_retval clob;
  
  begin
   
   if p_in_first_row then   
     lv_retval := upper(p_in_colname)||' '||p_in_datatype||' PATH '||''''||'$.'||p_in_colname||'''';
   else
     lv_retval := ','||upper(p_in_colname)||' '||p_in_datatype||' PATH '||''''||'$.'||p_in_colname||'''';
   end if;
   
   return lv_retval;
  
  end gen_json_tab_row;
                
  --%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
  
--*=============================================================================
--* Public API 
--*=============================================================================

  procedure generator
    (
      p_in_viewname in varchar2
      ,p_in_metaurl in varchar2
      ,p_in_metaparams in varchar2
      ,p_in_format_datatypes in boolean default false
    )
  --*===========================================================================
  --* NAME:        generator
  --*
  --* DESCRIPTION: Master prodcedure generating DDL to transform REST calls 
  --*              to Oracle view
  --*
  --* CREATED:     2021-05-06
  --* AUTHOR:      hellsulf, EpicoTech
  --*
  --* Example Call:
  --*
  --*  begin
  --*    rgenerator_pkk.generator
  --*          (
  --*            p_in_viewname => 'v_my_rest_view'
  --*            ,p_in_metaurl => 'http://localhost:8080/ords/utv1/f1_access/metadata-catalog/results/'
  --*            ,p_in_metaparams => '?limit=1000'
  --*           );
  --*  end;
  --*
  --*===========================================================================    
  is
  
    lv_template clob;
    lv_col_row clob;
    lv_sel_row clob;
    lv_col_rows clob;
    lv_sel_rows clob;
    lv_rest_to_data_link clob;
    lv_remote_obj_name varchar2(128);
    lv_masterkeys clob;
    crlf constant varchar2(2) := chr(13)||chr(10); 
    
    type meta_col_data is table of meta_col_rec;
    meta_col_arr meta_col_data;
    type meta_link_data is table of meta_link_rec;
    meta_link_arr meta_link_data;
    
  begin
  
    -- get all masterkeys
    lv_masterkeys := ret_metadata_masterkeys
                      (
                        p_in_metaurl => p_in_metaurl
                       );
    -- debug info                   
    dbms_output.put_line('Masterkeys: '||lv_masterkeys);                   
    -- get remote name of object
    lv_template := ret_rest_ddl_view_stub;
    --dbms_output.put_line(lv_template);
    lv_remote_obj_name := ret_metadata_object_name
                            (
                              p_in_metaurl => p_in_metaurl
                            );
    -- debug info                        
    dbms_output.put_line('Remote Object Name: '||lv_remote_obj_name);
    -- get links metadata
    select rel
           ,href
           ,mediatype
    bulk collect into meta_link_arr       
    from JSON_TABLE(rest_db_links.http_rest_request(p_in_metaurl)
                      ,'$.links[*]'
                      COLUMNS(rel varchar2(4000) PATH '$.rel'
                             ,href varchar2(4000) PATH '$.href'
                      ,mediatype varchar2(4000) PATH '$.mediaType')
                    );    
    -- get columns and datatypes from meta-data
    select columnname,
           case columntype when 'CHAR' then 'VARCHAR2'
           else columntype
           end as datatype
    bulk collect into meta_col_arr       
    from JSON_TABLE(rest_db_links.http_rest_request(p_in_metaurl) 
                      ,'$.members[*]' --path to resultset metadata
                       COLUMNS(columnname VARCHAR2(4000) PATH '$.name'
                      ,columntype VARCHAR2(4000) PATH '$.type')
                    );
    -- get metadata for link of rel = describes e.g link to fetch data from
    for i in meta_link_arr.first..meta_link_arr.last loop
      if meta_link_arr(i).rel = 'describes' then
        lv_rest_to_data_link := meta_link_arr(i).href;
      end if;
    end loop;
    -- Build select and json_table column list from metadata...
    for i in meta_col_arr.first..meta_col_arr.last loop
       if i = 1 then
          lv_sel_row := gen_sel_row
                          (
                            p_in_colname => meta_col_arr(i).columnname
                            ,p_in_datatype => meta_col_arr(i).datatype
                            ,p_in_first_row => true
                            ,p_in_format_datatypes => p_in_format_datatypes
                           );
                           
          lv_col_row := gen_json_tab_row
                          (
                            p_in_colname => meta_col_arr(i).columnname
                            ,p_in_datatype => meta_col_arr(i).datatype
                            ,p_in_first_row => true
                          );
       else
          lv_sel_row := gen_sel_row
                          (
                            p_in_colname => meta_col_arr(i).columnname
                            ,p_in_datatype => meta_col_arr(i).datatype
                            ,p_in_first_row => false
                            ,p_in_format_datatypes => p_in_format_datatypes
                           );
                           
          lv_col_row := gen_json_tab_row
                          (
                            p_in_colname => meta_col_arr(i).columnname
                            ,p_in_datatype => meta_col_arr(i).datatype
                          );
       end if;
       lv_sel_rows := lv_sel_rows||lv_sel_row||crlf;
       lv_col_rows := lv_col_rows||lv_col_row||crlf;
    end loop;
        
    -- build DDL from temporary template
    lv_template := replace(lv_template,'${VIEWNAME}',upper(p_in_viewname));
    lv_template := replace(lv_template,'${RESTURL}',lv_rest_to_data_link);
    lv_template := replace(lv_template,'${QPARAMS}',p_in_metaparams);
    lv_template := replace(lv_template,'${VIEWCOLS}',lv_sel_rows); 
    lv_template := replace(lv_template,'${JSONCOLS}',lv_col_rows);
    dbms_output.put_line('Local REST view');
    dbms_output.put_line('***************');
    dbms_output.put_line(lv_template);
    
  end generator;

end rgenerator_pkg;

/
