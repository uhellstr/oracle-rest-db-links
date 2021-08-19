# Model for usage

In the database where you want to expose data for rest callz use the following model. (e.g in the master example this is database PROD1)

* Never expose a table or view direcly from a schema that owns data. Instead create a separate access schema and grant select on underlying tables or views to this access schema. The access schema should ONLY be used for exposing rest enabled objects.
* In the access schema you granted select to create views on the underlying objects with SELECT permissions ONLY.
* Use SQL*Developer to REST enable your objects in the access schema. Again you can check Tim Hall's site for example on how to rest enable objects directly from PL/SQL.

In the database you want to fetch data from above install the PL/SQL API below. (e.g in the master example this is database PROD2)

# How to install the REST "database link" API.

In every database you plan to create one or several restbased view to fetch data from remote instance you should install the schema REST_DB_LINK_API.

The installation will create the following

* A new schema called REST_DB_LINK_API.
* In REST_DB_LINK_API the PL/SQL package REST_DB_LINKS (This package is used by every generated Oracle view that calls data over REST calls).
* In REST_DB_LINK_API the PL/SQL package RGENERATOR_PKG (This package is used by a developer to help to generate for rest based Oracle view.)

To install the API run the following sql script using SYS or INTERNAL or a user with necessary granted permissions (create user) etc.

run_me.sql

The script needs to setup Access Control List (ACL) to allow http call to the server where ORDS is installed. During the installation you will be prompted
for the address to this ORDS server. Input should be servername[.domaim] or ip-number to the server where ORDS is installed. If ORDS is installed on your 
local machine you give 127.0.0.1 or localhost as answer else use IP or fullname of the server.

Note: REST_DB_LINK_API will have the password REST_DB_LINK_API by default. After installation you should change this password immediate by

```
SQL> alter user REST_DB_LINK_API identified by "your_secret_and_secure_password";
```



