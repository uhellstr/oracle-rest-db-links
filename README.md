# oracle-rest-db-links

How to use REST enabled objects using Oracle Rest Data Services instead of traditional database links.

## This is a PL/SQL API to help you create DDL based oracle views that transforms JSON objects called over Oracle Rest Data Services to relational selectable ONLY Oracle views.

This framework was created to prove that you can use Oracle Rest Data Services (ORDS) instead of traditional database links to enable not only communication between  Oracle databases but also since we use REST from Oracle to anything that understans JSON and rest calls. That opens up usage of Python, Notebooks other databases like Postgres without the usage of Hetereogenous Services etc.

Using REST-based enabled objects not only mean we can commmunicate between Oracle databases but between Oracle an anything that understans JSON.

The work I have done is based on Robert Marz and his presentation at https://youtu.be/z7RZBV3yVAE and his github repository at https://github.com/its-people/rest-db-links.git
I have re-used most of the code he uses in rest_db_link pl/sql code but has fixed one or two bugs that prevented columns like 'ID' or 'UR* from working and also
done some work around handling unicode correctly.
The difference is that i have choosed to write i DDL generator in PL/SQL instead of Java Script that he uses in his generator. Pleas have a look at the spledid work Robert did a couple of years ago to demonstrate the possibilites of using REST as a replacement or in combination with traditional database links.



## Concept

We have a database named PROD1. In that database we have a table named CUSTOMERS that we need to join with data in database PROD2. 
The traditional way of doing this is to create a database link in PROD2 that points to the schema CUSTOMER table belongs too in PROD1.
First of all databaselinks needs TNS-aliases, they need username and password for the schema in PROD1 and they can only be created by the schema that should own the database link. Many databaselinks and many database and a DBA has a minor headache. Think password policies etc. They are a nightmare to handle in pipeline builds etc. So is there another way of fetching data from one source to another. Yes, there is a technology that is used allot in the mid-tier applications called RESTful API. Oracle has supported this technology for years using a technology called Oracle Rest Data Services (ORDS).

Using ORDS instead of databaselinks means that we open up the database not only for communicating between databases in the Oracle Technology stack but to the outside world and the configuration of ORDS is not so hardcoded into the database and the DBA do not have to handle database links when password changes etc.

This repository includes PL/SQL code that helps you generate DDL for a selecable Oracle view that fetches the data over REST.

The way to do this is described conceptual below:

* IN PROD1 we have the CUSTOMERS table in a schema called PRODDATA. We should never, ever rest enable this object directly!! The data should never be accessed directly in the schema that owns the table.
* Instead in PROD1 we create a access schema for allowing external access. Let's call this schema REST_ACCESS_API.
* We then grant select on PRODDATA.CUSTOMERS to the schema REST_ACCESS_API.
* In the schema REST_ACCESS_API we create a view called CUSTOMERS_REST_V
* We configure Oracle ORDS to allow "Rest Enabled SQL" against PROD1 on the node "myords.myorg.com"
* From SQL*Developer or directly using PL/SQL we REST enable the schema object REST_ACCESS_API.CUSTOMERS_REST_V
* From a browswer we check that we can fetch data over REST (The URL looks something like http[s]://myords.myorg.com:8080/ords/prod1/rest_acess_api/customers_rest_v)
 * In PROD2 we install the API in this repository. The default schema for this is REST_DB_LINK_API.
  
We now can generate DDL for a selectable view in PROD2 with the helper PL/SQL package RGENERATOR_PKG as follows.
Use SQL*Developer or SQLcmd to generate the output (generated with DBMS_OUTPUT). Copy the output for the create view statement
and paste it in your prefered environment.

```
set define off
set serveroutput on
begin
  rgenerator_pkg.generator
            (
              p_in_viewname => 'customers_rest_view'
              ,p_in_metaurl => 'http://myords.myorg.com:8080/ords/prod1/rest_access_api/metadata-catalog/customers_rest_v/'
              ,p_in_metaparams => '?limit=1000'
             );
end;
/
```

This will output the DDL that you can copy and run locally to create the view that fetches data over REST and transforms the JSON document to relational data.
If everyting works after running the DDL output from above you should now be able to do the following select in a schema in PROD2.

select * from [schema].customers_rest_view

If you test to use the URL used in the PL/SQL block above (after changing it to work in your environment) in a webbrowser like Firefox,Safari or Google Chromer that calls ORDS metadata catalog you will see that it will give you a description over the columns and datatypes used in the the object you access.


## Is this technology a total replacement for database links ?
The answer to that is NO. There are situations where databas links still is needed or you have choosen the wrong way of doing things. Fetching 1000 000 rows of data over a database link might not be fast but you fetch only the data. If you use REST to fetch the same amount of data you not only fetch the data itself since it will bel included in a huge JSON document. You vill fetch more over the network with REST then with traditional database links. So there might be situations where the database links outperform REST in such way that REST is not suitable. But REST uses filters just as normal SQL uses WHERE so if you can filter your data in your REST call to fetch as little data as possible it still can perform really well even with larger sets of data.

REST is also stateless it is not a read-consistant transaction. Let's say you want to fetch 500 000 rows. With REST you fetch the data in batches like 1000 rows of data per call. Someone could update some data further down in the fetch train and that could cause you logical corruption. It is not safe to asume that the millisecond you started to fetch the 500 000 rows you will get exactly the data that was in the remote table the millisecond you started to fetch the rows over REST. There is ways to get ORDS to guarantee that by passing som options in the call over REST but do not misstake stateless REST calls for Oracle read-consistant selects.

## What do i need to do before installing this framework ?

* You need to have ORDS installed and configured against the database you wish to fetch data from and it has to be configured with "   [1] SQL Developer Web  (Enables all features)" or "[2] REST Enabled SQL" options choosed.
* You should choose the latest version of ORDS from Oracle Technology Network and if you are using a older version upgrade to the latest version. There's been allot of optimization in the ORDS 20.x versions when it comes to fetching data over REST.
* If you already have ORDS installed but only configured for APEX you need to re-do the configuration against the database you wish to REST enable. It is not enough to install over the older installation. To reinstall use the uninstall option and then re-run the configuration and choose either option 1 or 2 above. Just rerun the configuration will not REST enable the configuration. 

## Where do I install ORDS ?

You have several opations availible
* In a local environment like youre own developer PC with Oracle installed you can install it as a standalone option on the developer PC directly. 
* You can install it on the same server as where Oracle software and database lives but that is not recommended unless it is development or smaller test envrionments.
* Preferely you install it on a separate server so that CPU-power is used only for ORDS. You can install it as a standalone or deploy your ORDS configuration to Tomcat
* If you install ORDS in a production environment you should protect the traffic using SSL and setup the configuration using https:// else everything is sent in clear text over the newtork. ORDS can use certificates from Let's Encrypt.

For more details about installing and configuring ORDS i recommend you look at official Oracle documentation or have a look at Tim Hall's 
https://oracle-base.com/misc/site-info

Tim Hall has a whole section about how to install and configure ORDS at https://oracle-base.com/articles/misc/articles-misc#ords

# Detailed instructions on how to install the PL/SQL API and how to use it is documentened in the README.md document in the install subdirectory.
