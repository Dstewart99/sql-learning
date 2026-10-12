-- ============================================================
-- Saviynt Practice Dataset (FAKE data)
-- Table and column names follow Saviynt's "Fields and Descriptions
-- of Key Tables" schema guide (simplified: only key columns).
-- Runs in SQLite (and MySQL with minor changes).
--
-- How the tables connect:
--   users --(user_accounts)--> accounts --(account_entitlements1)--> entitlement_values
--   accounts.endpointkey -> endpoints
--   entitlement_values.entitlementtypekey -> entitlement_types
--   roles --(role_entitlements)--> entitlement_values
--   roles --(role_user_account)--> users / accounts
--   arstasks = provisioning tasks (pending, completed, future-dated)
--
-- Built-in problems to find: terminated users with active accounts,
-- orphan accounts, users whose manager is inactive, direct vs role
-- access, privileged access, SoD conflicts, pending tasks,
-- terminated users who still have O365_Users access.
-- ============================================================

DROP TABLE IF EXISTS arstasks;
DROP TABLE IF EXISTS role_user_account;
DROP TABLE IF EXISTS role_entitlements;
DROP TABLE IF EXISTS roles;
DROP TABLE IF EXISTS account_entitlements1;
DROP TABLE IF EXISTS account_entitlements;  -- old practice table
DROP TABLE IF EXISTS entitlement_values;
DROP TABLE IF EXISTS entitlement_types;
DROP TABLE IF EXISTS user_accounts;
DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS endpoints;
DROP TABLE IF EXISTS users;

-- People (identities)
CREATE TABLE users (
  userkey        INTEGER PRIMARY KEY,
  username       VARCHAR(255),
  firstname      VARCHAR(255),
  lastname       VARCHAR(255),
  email          VARCHAR(255),
  departmentname VARCHAR(255),
  title          VARCHAR(255),   -- job title
  manager        INTEGER,        -- userkey of this person's manager
  employeetype   VARCHAR(255),   -- Employee / Contractor
  statuskey      INTEGER,        -- 1 = Active, 0 = Inactive
  startdate      DATETIME,
  enddate        DATETIME,
  displayname    VARCHAR(255),   -- full name for display
  termdate       DATETIME        -- termination date (NULL = not terminated)
);

-- Applications / target systems
CREATE TABLE endpoints (
  endpointkey  INTEGER PRIMARY KEY,
  endpointname VARCHAR(255),
  displayname  VARCHAR(255)
);

-- Accounts in each application (NOTE: no userkey here)
CREATE TABLE accounts (
  accountkey    INTEGER PRIMARY KEY,
  name          VARCHAR(255),  -- account name in the target system
  endpointkey   INTEGER,
  status        VARCHAR(255),  -- 'Active' / 'Inactive'
  orphan        INTEGER,       -- 1 = no owner, 0 = has owner
  created_on    DATETIME,
  lastlogondate DATETIME
);

-- Links users to accounts (this is how you find whose account it is)
CREATE TABLE user_accounts (
  userkey    INTEGER,
  accountkey INTEGER
);

-- Kinds of entitlements per app (AD Group, SAP Role, etc.)
CREATE TABLE entitlement_types (
  entitlementtypekey INTEGER PRIMARY KEY,
  entitlementname    VARCHAR(255),
  endpointkey        INTEGER
);

-- The actual groups / roles / permissions
CREATE TABLE entitlement_values (
  entitlement_valuekey INTEGER PRIMARY KEY,
  entitlement_value    VARCHAR(255),
  entitlementtypekey   INTEGER,
  privileged           INTEGER,  -- 1 = privileged, 0 = not
  status               INTEGER   -- 1 = active
);

-- Which account has which entitlement
CREATE TABLE account_entitlements1 (
  accentkey            INTEGER PRIMARY KEY,
  accountkey           INTEGER,
  entitlement_valuekey INTEGER,
  assignedfromrole     INTEGER,  -- rolekey if given by a role; NULL = direct
  startdate            DATETIME,
  enddate              DATETIME
);

-- Business roles (bundles of entitlements)
CREATE TABLE roles (
  rolekey     INTEGER PRIMARY KEY,
  role_name   VARCHAR(255),
  description VARCHAR(255),
  privileged  INTEGER,
  status      INTEGER  -- 1 = active
);

-- Which entitlements each role contains
CREATE TABLE role_entitlements (
  rolekey              INTEGER,
  entitlement_valuekey INTEGER
);

-- Which users/accounts have which role
CREATE TABLE role_user_account (
  id         INTEGER PRIMARY KEY,
  rolekey    INTEGER,
  userkey    INTEGER,
  accountkey INTEGER,
  startdate  DATETIME,
  enddate    DATETIME
);

-- Provisioning tasks
-- status: the team's real query treats 1, 2, 6, 7 as pending.
--         3 = completed here is a practice value.
-- tasktype (practice values): 1 = Add Access, 2 = Remove Access, 3 = New Account, 4 = Disable Account
CREATE TABLE arstasks (
  taskkey              INTEGER PRIMARY KEY,
  tasktype             INTEGER,
  status               INTEGER,
  userkey              INTEGER,
  accountkey           INTEGER,
  endpoint             INTEGER,  -- endpointkey
  entitlement_valuekey INTEGER,
  requestedby          INTEGER,  -- userkey of requester
  taskdate             DATETIME, -- when the task was created
  startdate            DATETIME, -- when it should be worked (future = not yet)
  comments             VARCHAR(255)
);

INSERT INTO users VALUES
(1,'jmorgan','Janet','Morgan','jmorgan@example.com','IT','IT Director',NULL,'Employee',1,'2015-03-02',NULL,'Janet Morgan',NULL),
(2,'rpatel','Ravi','Patel','rpatel@example.com','IT','IAM Manager',1,'Employee',1,'2018-06-11',NULL,'Ravi Patel',NULL),
(3,'dlee','Dana','Lee','dlee@example.com','IT','IAM Analyst',2,'Employee',1,'2021-01-04',NULL,'Dana Lee',NULL),
(4,'mbrooks','Marcus','Brooks','mbrooks@example.com','IT','Systems Administrator',2,'Contractor',1,'2024-09-16',NULL,'Marcus Brooks',NULL),
(5,'kwilson','Karen','Wilson','kwilson@example.com','Finance','Finance Manager',1,'Employee',1,'2016-08-22',NULL,'Karen Wilson',NULL),
(6,'tnguyen','Tuan','Nguyen','tnguyen@example.com','Finance','Accountant',5,'Employee',1,'2020-02-10',NULL,'Tuan Nguyen',NULL),
(7,'sgarcia','Sofia','Garcia','sgarcia@example.com','Finance','Accountant',5,'Employee',0,'2019-05-13','2026-07-31','Sofia Garcia','2026-07-31'),
(8,'bharris','Brian','Harris','bharris@example.com','HR','HR Manager',1,'Employee',1,'2017-11-01',NULL,'Brian Harris',NULL),
(9,'akim','Alicia','Kim','akim@example.com','HR','HR Generalist',8,'Employee',1,'2022-04-18',NULL,'Alicia Kim',NULL),
(10,'cjohnson','Chris','Johnson','cjohnson@example.com','HR','Recruiter',8,'Contractor',0,'2025-01-06','2026-06-30','Chris Johnson','2026-06-30'),
(11,'lthomas','Lisa','Thomas','lthomas@example.com','Sales','Sales Manager',1,'Employee',1,'2018-03-19',NULL,'Lisa Thomas',NULL),
(12,'pwright','Paul','Wright','pwright@example.com','Sales','Sales Rep',11,'Employee',1,'2023-07-10',NULL,'Paul Wright',NULL),
(13,'emartin','Emily','Martin','emartin@example.com','Sales','Sales Rep',14,'Employee',1,'2024-02-05',NULL,'Emily Martin',NULL),   -- manager is terminated
(14,'jcarter','James','Carter','jcarter@example.com','Sales','Sales Team Lead',11,'Employee',0,'2021-09-27','2026-08-15','James Carter','2026-08-15'),
(15,'nrobinson','Nina','Robinson','nrobinson@example.com','IT','Help Desk Tech',NULL,'Contractor',1,'2025-10-01',NULL,'Nina Robinson',NULL),  -- no manager
(16,'oadams','Omar','Adams','oadams@example.com','Finance','Payroll Specialist',7,'Employee',1,'2022-11-14',NULL,'Omar Adams',NULL),
(17,'rgreen','Rachel','Green','rgreen@example.com','Sales','Sales Rep',11,'Employee',0,'2024-05-01','2026-10-04','Rachel Green','2026-10-04');  -- terminated recently (less than 5 days)    -- manager is terminated

INSERT INTO endpoints VALUES
(1,'ActiveDirectory','Corporate Active Directory'),
(2,'EntraID','Microsoft Entra ID'),
(3,'Workday','Workday HR'),
(4,'Salesforce','Salesforce CRM'),
(5,'SAP','SAP Finance');

INSERT INTO accounts VALUES
(101,'jmorgan',1,'Active',0,'2015-03-02','2026-09-30'),
(102,'rpatel',1,'Active',0,'2018-06-11','2026-10-01'),
(103,'dlee',1,'Active',0,'2021-01-04','2026-10-02'),
(104,'mbrooks',1,'Active',0,'2024-09-16','2026-09-29'),
(105,'kwilson',1,'Active',0,'2016-08-22','2026-09-25'),
(106,'tnguyen',1,'Active',0,'2020-02-10','2026-09-30'),
(107,'sgarcia',1,'Active',0,'2019-05-13','2026-07-30'),
(108,'bharris',1,'Active',0,'2017-11-01','2026-10-01'),
(109,'akim',1,'Active',0,'2022-04-18','2026-09-28'),
(110,'cjohnson',1,'Inactive',0,'2025-01-06','2026-06-29'),
(111,'lthomas',1,'Active',0,'2018-03-19','2026-09-30'),
(112,'pwright',1,'Active',0,'2023-07-10','2026-10-02'),
(113,'emartin',1,'Active',0,'2024-02-05','2026-09-15'),
(114,'jcarter',1,'Active',0,'2021-09-27','2026-08-14'),
(115,'nrobinson',1,'Active',0,'2025-10-01','2026-10-02'),
(116,'oadams',1,'Active',0,'2022-11-14','2026-09-30'),
(117,'svc_backup',1,'Active',1,'2014-01-01','2026-10-02'),
(118,'temp_admin',1,'Active',1,'2023-03-15','2024-01-10'),
(201,'jmorgan@example.com',2,'Active',0,'2020-01-01','2026-10-01'),
(202,'dlee@example.com',2,'Active',0,'2021-01-04','2026-10-02'),
(203,'sgarcia@example.com',2,'Active',0,'2020-01-01','2026-07-30'),
(204,'pwright@example.com',2,'Active',0,'2023-07-10','2026-10-01'),
(301,'bharris',3,'Active',0,'2017-11-01','2026-09-30'),
(302,'akim',3,'Active',0,'2022-04-18','2026-09-29'),
(303,'cjohnson',3,'Active',0,'2025-01-06','2026-06-28'),
(401,'lthomas',4,'Active',0,'2018-03-19','2026-10-01'),
(402,'pwright',4,'Active',0,'2023-07-10','2026-10-02'),
(403,'emartin',4,'Active',0,'2024-02-05','2026-09-15'),
(404,'jcarter',4,'Active',0,'2021-09-27','2026-08-14'),
(501,'kwilson',5,'Active',0,'2016-08-22','2026-09-25'),
(502,'tnguyen',5,'Active',0,'2020-02-10','2026-09-30'),
(503,'sgarcia',5,'Inactive',0,'2019-05-13','2026-07-30'),
(504,'oadams',5,'Active',0,'2022-11-14','2026-09-30'),
(505,'pwright',5,'Active',0,'2025-04-01','2025-04-02'),
(119,'rgreen',1,'Active',0,'2024-05-01','2026-10-03'),
(205,'jcarter@example.com',2,'Active',0,'2021-09-27','2026-08-14'),
(206,'cjohnson@example.com',2,'Active',0,'2025-01-06','2026-06-29'),
(207,'rgreen@example.com',2,'Active',0,'2024-05-01','2026-10-03'),
(208,'emartin@example.com',2,'Active',0,'2024-02-05','2026-09-15');

-- Who owns each account (orphans 117 and 118 have no row here)
INSERT INTO user_accounts VALUES
(1,101),(2,102),(3,103),(4,104),(5,105),(6,106),(7,107),(8,108),(9,109),(10,110),
(11,111),(12,112),(13,113),(14,114),(15,115),(16,116),
(1,201),(3,202),(7,203),(12,204),
(8,301),(9,302),(10,303),
(11,401),(12,402),(13,403),(14,404),
(5,501),(6,502),(7,503),(16,504),(12,505),
(17,119),(14,205),(10,206),(17,207),(13,208);

INSERT INTO entitlement_types VALUES
(1,'AD Group',1),
(2,'Entra Role',2),
(3,'Workday Security Group',3),
(4,'Salesforce Profile',4),
(5,'SAP Role',5);

INSERT INTO entitlement_values VALUES
(1,'Domain Users',1,0,1),
(2,'Domain Admins',1,1,1),
(3,'VPN Users',1,0,1),
(4,'Finance_Share_RW',1,0,1),
(5,'Global Administrator',2,1,1),
(6,'Helpdesk Administrator',2,1,1),
(7,'HR Admin',3,1,1),
(8,'HR Viewer',3,0,1),
(9,'Sales User',4,0,1),
(10,'Sales Admin',4,1,1),
(11,'AP Clerk',5,0,1),
(12,'Payment Approver',5,1,1),
(13,'Vendor Create',5,1,1),
(14,'O365_Users_E3',2,0,1);

INSERT INTO roles VALUES
(1,'Employee_Base','Standard access for every employee',0,1),
(2,'Finance_Base','Standard Finance department access',0,1),
(3,'Sales_Base','Standard Sales department access',0,1),
(4,'HR_Base','Standard HR department access',0,1),
(5,'IT_Admin','Privileged IT administration',1,1);

INSERT INTO role_entitlements VALUES
(1,1),(1,3),
(2,4),(2,11),
(3,9),
(4,8),
(5,2),(5,5);

-- Role assignments (userkey + the account the role applies to)
INSERT INTO role_user_account VALUES
(1,1,1,101,'2015-03-02',NULL),(2,1,2,102,'2018-06-11',NULL),(3,1,3,103,'2021-01-04',NULL),
(4,1,4,104,'2024-09-16',NULL),(5,1,5,105,'2016-08-22',NULL),(6,1,6,106,'2020-02-10',NULL),
(7,1,7,107,'2019-05-13',NULL),(8,1,8,108,'2017-11-01',NULL),(9,1,9,109,'2022-04-18',NULL),
(10,1,11,111,'2018-03-19',NULL),(11,1,12,112,'2023-07-10',NULL),(12,1,13,113,'2024-02-05',NULL),
(13,1,14,114,'2021-09-27',NULL),(14,1,15,115,'2025-10-01',NULL),(15,1,16,116,'2022-11-14',NULL),
(16,2,5,105,'2016-08-22',NULL),(17,2,6,106,'2020-02-10',NULL),(18,2,16,116,'2022-11-14',NULL),
(19,3,12,402,'2023-07-10',NULL),(20,3,13,403,'2024-02-05',NULL),(21,3,14,404,'2021-09-27',NULL),
(22,4,9,302,'2022-04-18',NULL),
(23,5,1,101,'2015-03-02',NULL),(24,5,2,102,'2019-01-15',NULL);

-- assignedfromrole = rolekey when it came from a role, NULL when assigned directly
INSERT INTO account_entitlements1 VALUES
(1,101,1,1,'2015-03-02',NULL),(2,101,2,5,'2015-03-02',NULL),
(3,102,1,1,'2018-06-11',NULL),(4,102,2,5,'2019-01-15',NULL),
(5,103,1,1,'2021-01-04',NULL),(6,103,3,1,'2021-01-04',NULL),
(7,104,1,1,'2024-09-16',NULL),(8,104,2,NULL,'2025-02-01',NULL),     -- contractor, Domain Admins DIRECT
(9,105,1,1,'2016-08-22',NULL),(10,105,4,2,'2016-08-22',NULL),
(11,106,1,1,'2020-02-10',NULL),(12,106,4,2,'2020-02-10',NULL),
(13,107,1,1,'2019-05-13',NULL),(14,107,3,1,'2019-05-13',NULL),(15,107,4,NULL,'2019-05-13',NULL),
(16,108,1,1,'2017-11-01',NULL),
(17,109,1,1,'2022-04-18',NULL),
(18,111,1,1,'2018-03-19',NULL),(19,111,3,1,'2018-03-19',NULL),
(20,112,1,1,'2023-07-10',NULL),(21,112,3,1,'2023-07-10',NULL),
(22,113,1,1,'2024-02-05',NULL),
(23,114,1,1,'2021-09-27',NULL),(24,114,3,1,'2021-09-27',NULL),
(25,115,1,1,'2025-10-01',NULL),
(26,116,1,1,'2022-11-14',NULL),(27,116,4,2,'2022-11-14',NULL),
(28,117,1,NULL,'2014-01-01',NULL),(29,117,2,NULL,'2014-01-01',NULL), -- orphan with Domain Admins
(30,118,2,NULL,'2023-03-15',NULL),
(31,201,5,5,'2020-01-01',NULL),
(32,202,6,NULL,'2021-06-01',NULL),
(33,203,6,NULL,'2022-03-01',NULL),                                   -- terminated user, privileged
(34,204,6,NULL,'2024-01-10',NULL),                                   -- sales rep with Helpdesk Admin
(35,301,7,NULL,'2017-11-01',NULL),
(36,302,8,4,'2022-04-18',NULL),
(37,303,7,NULL,'2025-01-06',NULL),                                   -- terminated contractor, HR Admin
(38,401,10,NULL,'2018-03-19',NULL),
(39,402,9,3,'2023-07-10',NULL),
(40,403,9,3,'2024-02-05',NULL),
(41,404,9,3,'2021-09-27',NULL),
(42,501,12,NULL,'2016-08-22',NULL),
(43,502,11,2,'2020-02-10',NULL),(44,502,12,NULL,'2023-05-01',NULL),(45,502,13,NULL,'2023-05-01',NULL), -- SoD conflict
(46,503,11,2,'2019-05-13',NULL),
(47,504,11,2,'2022-11-14',NULL),
(48,505,12,NULL,'2025-04-01',NULL),                                  -- sales rep approving payments
(49,201,14,NULL,'2020-01-01',NULL),(50,202,14,NULL,'2021-01-04',NULL),
(51,203,14,NULL,'2020-01-01',NULL),                                  -- terminated, still has O365
(52,204,14,NULL,'2023-07-10',NULL),
(53,205,14,NULL,'2021-09-27',NULL),                                  -- terminated, still has O365
(54,206,14,NULL,'2025-01-06',NULL),                                  -- terminated, still has O365
(55,207,14,NULL,'2024-05-01',NULL),                                  -- terminated recently (under 5 days)
(56,208,14,NULL,'2024-02-05',NULL),
(57,119,1,1,'2024-05-01',NULL);

INSERT INTO arstasks VALUES
(1001,3,3,15,115,1,NULL,2,'2025-09-25','2025-10-01','New hire AD account'),
(1002,4,3,10,110,1,NULL,8,'2026-06-30','2026-06-30','Disable AD for terminated contractor'),
(1003,4,1,7,107,1,NULL,5,'2026-07-31','2026-07-31','Disable AD - terminated user, still pending'),
(1004,2,1,7,203,2,6,5,'2026-07-31','2026-07-31','Remove Helpdesk Admin - terminated user'),
(1005,4,2,14,114,1,NULL,11,'2026-08-15','2026-08-15','Disable AD - in progress'),
(1006,2,1,14,404,4,9,11,'2026-08-15','2026-08-15','Remove Salesforce access - terminated user'),
(1007,1,1,6,502,5,12,5,'2026-09-28','2026-09-28','Add Payment Approver'),
(1008,1,1,13,403,4,10,11,'2026-10-01','2026-10-20','Add Sales Admin - future dated'),
(1009,3,1,12,NULL,2,NULL,11,'2026-10-02','2026-11-01','New Entra account - future dated'),
(1010,2,1,4,104,1,2,2,'2026-10-03','2026-10-03','Remove Domain Admins from contractor'),
(1011,1,3,3,103,1,3,2,'2021-01-04','2021-01-04','Add VPN Users'),
(1012,4,1,10,303,3,NULL,8,'2026-10-04','2026-12-31','Disable Workday - future dated'),
(1013,2,6,7,503,5,11,5,'2026-08-01','2026-08-01','Remove AP Clerk - status 6'),
(1014,4,7,14,205,2,NULL,11,'2026-08-16','2026-08-16','Disable Entra account - status 7'),
(1015,2,6,17,207,2,14,11,'2026-10-04','2026-10-25','Remove O365 - status 6, future dated');
