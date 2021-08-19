# Model for usage

In the database where you want to expose data for rest calls use the following model. (e.g in the master example this is database PROD1)

* Never expose a table or view direcly from a schema that owns data the table or view. Instead create a separate "access" schema used for objects you want to rest enable and grant select on underlying tables or views to that schema. The "access" schema should ONLY be used for exposing rest enabled objects.
* In the "access" schema you granted select to create views on the underlying objects with SELECT/READONLY permissions.
* Use SQL*Developer to REST enable your objects in the access schema. Again you can check Tim Hall's site (See the master README.md for this repository) for example on how to rest enable objects directly from PL/SQL.

In the database you want to fetch data from above install the PL/SQL API below. (e.g in the master example this is database PROD2)

# How to install the REST "database link" API.

In every database you plan to create one or several restbased view(s) to fetch data from a remote rest enabled object you should install the schema REST_DB_LINK_API.

The installation will create the following

* A new schema called REST_DB_LINK_API.
* In REST_DB_LINK_API the PL/SQL package REST_DB_LINKS (This package is used by every generated Oracle view that calls data over REST calls).
* In REST_DB_LINK_API the PL/SQL package RGENERATOR_PKG (This package is used by a developer to help to generate DDL for a rest based Oracle view.)

To install the API run the following sql script using SYS or INTERNAL or a user with necessary granted permissions (create user, access to ACL packages..) etc.

```
SQL>conn sys@<TNS-ALIAS> as sysdba 
SQL>@run_me.sql
``` 

The script needs to setup Access Control List (ACL) to allow http call to the server where ORDS is installed. During the installation you will be prompted
for the address to this ORDS server. Input should be servername[.domain] or ip-number to the server where ORDS is installed. If ORDS is installed on your 
local machine you give 127.0.0.1 or localhost as answer else use IP or fullname of the server.

Note: REST_DB_LINK_API will have the password REST_DB_LINK_API by default. After installation you should change this password immediate by

```
SQL> alter user REST_DB_LINK_API identified by "your_secret_and_secure_password";
```

The package REST_DB_LINK_API.REST_DB_LINKS will grant with execute permissions against the PUBLIC schema by defalt so anyone can call this package.
If you do not want it be directly granted to all schemas in your database you will have to revoke this pemission and then manually grant
execute on REST_DB_LINK_API.REST_DB_LINKS to any schema that will create one or several REST based Oracle view since this package is called by
any such view to be able to parse and convert JSON to a relational view.

When API is installed you can generate the DDL for a REST based Oracle view using REST_DB_LINK_API.RGENERATOR_PKG as 

```
set define off
set serveroutput on
begin
  rgenerator_pkg.generator
            (
              p_in_viewname => '<name of the rest based oracle view'
              ,p_in_metaurl => '<ORDS URL to remove rest enabled object'
              ,p_in_metaparams => <filter parameters>
             );
end;
/
```

In this fictional example have a schema called REST_ACCES_API with a view called customers_v in the database PROD1.
ORDS is configured and we can test call the URL to access the data in customers_v view in PROD1
In PROD2 we now want to generate a rest based Oracle view that fetches the data from cusomers_v in PROD1.
Using the RGENERATOR_PKG described above we can genereate and then run the DDL for a view called customers_rest_view in PROD2 by calling the package above as.

```
set define off
set serveroutput on
begin
  rgenerator_pkg.generator
            (
              p_in_viewname => 'customers_rest_view'
              ,p_in_metaurl => 'http://myords.myorg.com:8080/ords/prod1/rest_access_api/metadata-catalog/customers_v/'
              ,p_in_metaparams => '?limit=1000'
             );
end;
/
```
# About the parameter p_in_metaparams in RGENERATOR_PKG.

The parameter p_in_metaparams tells the generator that the view should fetch 1000 rows in each batch until there is no more data to fetch. 1000 rows is a recommended value. Increasing this value will not increase the performance in my own test. Decreasing it can however slow down the fetch of data severly due
to multiple roundtrips needed to fetch the data.

What does this mean ? If the original underlying table for the customers_v in PROD1 has exact 5001 rows it will take 5 roundtrips to fetch all data from PRDO1 to PROD2 as

In step 1 we fetch the first 1000 rows and sets the offset to the 1001 row
In step 2 we fetch rows 1001-2000 and then sets the offset to the 2001 row
etc..

The parameter p_in_metaparams supports the usage of ORDS filtering. This can increase performance allot since you specify exactly and only the rows needed when fetching the data instead of filtering the data afterwards with a WHERE statement when performing a select on the view. Lets say that in the underlying table to the customsers_v in PROD1 there is a field determine if the customer is a man or a woman. This field is called SEX and can have the values 'MALE' or 'FEMALE' about 500 rows in the table includes customser that are men and we want only to fetch those rows. This can be done by modifying the above definition call for the rest based Oracle view to the following

```
set define off
set serveroutput on
begin
  rgenerator_pkg.generator
            (
              p_in_viewname => 'customers_rest_view'
              ,p_in_metaurl => 'http://myords.myorg.com:8080/ords/prod1/rest_access_api/metadata-catalog/customers_v/'
              ,p_in_metaparams => '?q={'SEX':'MALE'}&limit=1000'
             );
end;
/
```

For more information on how to use ORDS filtering (works like WHERE in SQL to filter data) see the Oracle Documentation for Oracle Rest Data Services or google on "Oracle Rest Data Services filter".

If you fetch allot of data over rest you can modify the output from above the above from CREATE VIEW to CREATE MATERIALIZED view and add statements to allow for regular or manual refresh. This can increase performance allot if you do joins on the local side since you no longer need to fetch data over the network for each join done.

# Final note:

Not all datatypes are supported for REST calls. The package above will handle all standard types as VARCHAR2,NUMBER and DATE and TIMESTAMP data types. CHAR vill be converted to VARCHAR2 since json do not support CHAR. Datatypes as LOB's are not supported. For more information what datatypes are supported by JSON see the ORDS documentation.
