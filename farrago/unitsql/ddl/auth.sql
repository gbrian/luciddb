-- $Id$
-- Test DDL on Authorization: 
-- User, Role, Role Inheritance structure

-------------------------------------------------------------------------
-- Basic setup

-- Create a security manager and login as this user to perform all grant 
-- tests. 

create schema extra;
create table extra.t(i int not null primary key);

create user SECMAN authorization 'Unknown' DEFAULT CATALOG localdb;
create user SECMAN_2 authorization 'Unknown' DEFAULT CATALOG localdb;

create user SECMAN_3 identified by 'tiger' DEFAULT CATALOG sys_boot;

create user SECMAN_4 identified by '' DEFAULT SCHEMA extra;

create role rf;

create role rg;

grant select on extra.t to secman_4;

-- Redundant grant to make sure they get coalesced correctly in the catalog
grant select on extra.t to secman_4;

grant role rf to secman_4;

-- test role grant upgrade, and verify that there is no downgrade
grant role rg to secman_4;
grant role rg to secman_4 with admin option;
grant role rg to secman_4;

-- test privilege grant upgrade, and verify that there is not downgrade
grant select on extra.t to secman_2;
grant select on extra.t to secman_2 with grant option;
grant select on extra.t to secman_2;

-- should fail:  unknown grantee
grant select on extra.t to nobody;

-- should fail:  duplicate user
create user SECMAN_4;

create role R1;

-- should fail:  duplicate role
create role R1;

-- should fail:  role name conflicts with user name
create role SECMAN_4;

-- should fail:  user name conflicts with role name
create user R1;

-- should fail:  can't grant user to role
grant role SECMAN_4 to R1;

!closeall
!connect jdbc:farrago: SECMAN tiger

-- should fail:  grantor has no rights
grant select on extra.t to secman_3;

-- should fail:  same reason
grant role r1 to secman_3;

create schema authtest;
set schema 'authtest';

create view grant_view as 
select  me."name" granted_element,  gte."name" grantee,  gto."name" grantor, g."action", 
g."withGrantOption"
from 
        sys_fem."Security"."Grant" g
inner join
        sys_fem."Security"."AuthId" gto
on      g."Grantor" = gto."mofId"
inner join 
        sys_fem."Security"."AuthId" gte
on      g."Grantee" = gte."mofId"
inner join 
        sys_cwm."Core"."ModelElement" me
on      g."Element" = me."mofId";

create user "MockLoginModuleTestUser" authorization 'Unknown';

-------------------------------------------------------------------------
-- Test 1: 
-- Create User U1, 
-- o grant a role to the user, 
-- o check the system catalog to ensure that the appropriate records has 
--   been written.

Create user U1 AUTHORIZATION 'Unknown' DEFAULT CATALOG localdb;

-- Create Role 1 at  level 1
Create Role R1_L1;

-- Grant the role R1_L1 directly to U1
Grant Role R1_L1 to U1;

-- Redundant grant to make sure they get coalesced correctly in the catalog
Grant Role R1_L1 to U1;

-- Alter user to make Role R1_L1 the default
-- Alter user default role R1_L1;

-- Check system catalog for the objects and system generated grants

-- Check out the role created
select "name" from sys_fem."Security"."Role" where "name" like 'R%_L%'
order by "name";
select "name" from sys_fem."Security"."User" where "name" like 'U%'
order by "name";

-- check out the grants created
select  granted_element,  grantee,  grantor, "action", "withGrantOption"
from grant_view
where grantee = 'U1' or grantee= 'R1_L1'
order by granted_element;

-- check out another one
select  granted_element,  grantee,  grantor, "action", "withGrantOption"
from grant_view
where grantee = 'SECMAN_4'
order by granted_element;

-- and one more
select  granted_element,  grantee,  grantor, "action", "withGrantOption"
from grant_view
where grantee = 'SECMAN_2'
order by granted_element;

-- verify password encryption; we use a platform-independent algorithm
-- so it should always come out the same
select "encryptedPassword", "passwordEncryptionAlgorithm"
from sys_fem."Security"."User"
where "name" = 'SECMAN_3';

-------------------------------------------------------------------------
-- Test 2: user, roles at two different levels hierarchies
-- 
-- o U2 -> R2_L1 -> R1_L2 -> R1_L3
-- o U4 -> ( R1_L1, R2_L1, R3_L1, R4_L1)
-- o U5, U6, U7 -> (R3_L1, R4_L1, R1_L3)

Create user U2 AUTHORIZATION 'Unknown' DEFAULT CATALOG localdb;
Create user U3 AUTHORIZATION 'Unknown' DEFAULT CATALOG localdb;
Create user U4 AUTHORIZATION 'Unknown' DEFAULT CATALOG localdb;
Create user U5 AUTHORIZATION 'Unknown' DEFAULT CATALOG localdb;
Create user U6 AUTHORIZATION 'Unknown' DEFAULT CATALOG localdb;
Create user U7 AUTHORIZATION 'Unknown' DEFAULT CATALOG localdb;

select "name" from sys_fem."Security"."User" where "name" like 'U%' 
order by "name";

-- Create Role 2, 3 and 4 at level 1
Create Role R2_L1 WITH ADMIN SECMAN_2;
Create Role R3_L1 WITH ADMIN SECMAN_2;
Create Role R4_L1 WITH ADMIN SECMAN_2;

select "name" from sys_fem."Security"."Role" where "name" like 'R%_L%'
order by "name";

-- Grant the role R2_L1 directly to U2
Grant Role R2_L1 to U2;


-- Grant  R2_L1 -> R1_L2 -> R1_L3
Create Role R1_L2;
Create Role R1_L3;

select "name" from sys_fem."Security"."Role" where "name" like 'R%_L%'
order by "name";

Grant Role R1_L2 to R2_L1 WITH ADMIN OPTION;
Grant Role R1_L3 to R1_L2;

-- should fail:  role cycle
grant role R1_L2 to R1_L3;

-- should fail:  unknown grantee
Grant Role R1_L3 to BOZOS;

-- should fail:  unknown role
Grant Role BOZOS to R1_L3;

select  granted_element,  grantee,  grantor, "action", "withGrantOption"
from grant_view
where grantee = 'U2' or grantee = 'R2_L1' or grantee = 'R1_L3'
order by granted_element;


-- Grant all level 1 roles to U3 i.e. U3 -> ( R1_L1, R2_L1, R3_L1) 
grant role R1_L1, R2_L1, R3_L1 to U3;

select  granted_element,  grantee,  grantor, "action", "withGrantOption"
from grant_view
where grantee = 'U3'
order by granted_element;

-- Grant to user U5, U6, U7 the roles (R3_L1, R4_L1, R1_L3)
Grant role R3_L1, R4_L1, R1_L3 to U5, U6, U7;

select  granted_element,  grantee,  grantor, "action", "withGrantOption"
from grant_view
where grantee = 'U5' or grantee = 'U6' or grantee = 'U7'
order by grantee, granted_element;

-- Alter user to make Role R1_L1 the default
-- Alter user default role R1_L1;R1_L1, R2_L1, R3_L1


-------------------------------------------------------------------------
-- Test 3:
-- authentication

-- should fail:  unknown user
!closeall
!connect jdbc:farrago: BOBO tiger

-- should succeed:  local driver, user with wrong password
!closeall
!connect jdbc:farrago: "MockLoginModuleTestUser" blah

-- should fail:  spoof remote driver, user with wrong password
!closeall
!connect jdbc:farrago:;remoteProtocol="HTTP" "MockLoginModuleTestUser" blah

-- should succeed:  spoof remote driver, user with correct password
!closeall
!connect jdbc:farrago:;remoteProtocol="HTTP" "MockLoginModuleTestUser" secret

-- should succeed:  correct catalog password
!closeall
!connect jdbc:farrago: SECMAN_3 tiger

-- should fail:  incorrect catalog password
!closeall
!connect jdbc:farrago: SECMAN_3 hobbes

-- should succeed:  blank password is equivalent to no password
!closeall
!connect jdbc:farrago: SECMAN_4 whatever

-- change password
create or replace user SECMAN_3 identified by 'cougar';

-- should fail:  old password no longer works
!closeall
!connect jdbc:farrago: SECMAN_3 tiger

-- should succeed:  new password works
!closeall
!connect jdbc:farrago: SECMAN_3 cougar

-- unset password
create or replace user SECMAN_3;

-- should succeed:  any password works
!closeall
!connect jdbc:farrago: SECMAN_3 puma


!closeall
!connect jdbc:farrago: SECMAN_2 tiger

-- should succeed because secman_2 has grant option
grant select on extra.t to secman_3;

-------------------------------------------------------------------------
-- Test 4:
-- default schemas and catalogs

!closeall
!connect jdbc:farrago: SECMAN_3 tiger

-- default catalog is sys_boot
select * from jdbc_metadata.table_types_view order by table_type;

!closeall
!connect jdbc:farrago: SECMAN_4 tiger

-- default schema is extra
select * from t;

-- should fail: grantor has access but no GRANT OPTION
grant select on extra.t to secman;

-- should fail:  grantor has role but no ADMIN OPTION
grant role rf to secman;

-- should succeed:  grantor has ADMIN OPTION
grant role rg to secman;

-- verify that dropping default schema does not cascade to user
drop schema extra cascade;

!closeall
!connect jdbc:farrago: SECMAN_4 tiger

-- should fail:  it's gone now
select * from t;

-- should fail:  no such role
set role 'goofball';

!closeall
-- should fail:  cannot log in as _SYSTEM ever
!connect jdbc:farrago: _SYSTEM ""
