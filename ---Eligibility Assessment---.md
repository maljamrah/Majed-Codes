# **---Eligibility Assessment---**





## --11.a---# of Medicaid Members Assessed "VALID"





--=============================================================================================================================================================================================================================

--Date Entry - 7 : Count of unique Medicaid Members with a Completed Eligibility Assessment (within the past month):

--============================================================================================================================================================================================================================

--Filtering form name with 'Eligibility' and filtering out the date required

-- And include only who asnwered yes to consent



WITH base\_responses AS (

&nbsp;	SELECT 

&nbsp;		seeker\_id,

&nbsp;		question,

&nbsp;		answer,

&nbsp;		form\_submission\_id,

&nbsp;		started\_at

&nbsp;	FROM FH\_flipa\_mbr\_insights\_forms

&nbsp;	WHERE form\_name LIKE '%eligibility%'	-----THIS FILTERS ONLY HRSN SCREENERS

&nbsp;	  AND seeker\_id IS NOT NULL     -----EXCLUDE ANY ORPHANED RECORDS

),



responses\_in\_month AS (											--- CTE to filter the date for that specific month

&nbsp;	SELECT \* 

&nbsp;	FROM base\_responses

&nbsp;	  WHERE started\_at >= '2025-01-01' 

&nbsp;	  AND started\_at< DATEADD(DAY, 1, CAST(GETDATE() AS date))

),

consented\_members AS (											--- CTE to filter consent members who said yes

&nbsp;	SELECT DISTINCT form\_submission\_id, seeker\_id

&nbsp;	FROM responses\_in\_month

&nbsp;	WHERE 

&nbsp;		(

&nbsp;			question like 'We use%' 

&nbsp;			AND answer = 'YES Member consents'

&nbsp;		)

&nbsp;		OR

&nbsp;		( 

&nbsp;			question like 'Confirm consent with Member to move%' 

&nbsp;			AND answer = 'Member consents'

&nbsp;		)

)



SELECT COUNT(DISTINCT seeker\_id) AS KPI\_11a\_count

FROM consented\_members ;



































## --12---# of Enhanced Services Medicaid Members Assessed





-- Eligibility forms (YTD) + consent + ESMF eligible

WITH base\_responses AS (

&nbsp;   SELECT 

&nbsp;       seeker\_id,

&nbsp;       question,

&nbsp;       answer,

&nbsp;       form\_submission\_id,

&nbsp;       started\_at

&nbsp;   FROM FH\_flipa\_mbr\_insights\_forms

&nbsp;   WHERE form\_name LIKE '%eligibility%'

&nbsp;     AND seeker\_id IS NOT NULL

),

responses\_ytd AS (

&nbsp;   SELECT \* 

&nbsp;   FROM base\_responses

&nbsp;   WHERE started\_at >= '2025-01-01'

&nbsp;     AND started\_at <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

),

consented\_members AS (

&nbsp;   SELECT DISTINCT form\_submission\_id, seeker\_id

&nbsp;   FROM responses\_ytd

&nbsp;   WHERE (question LIKE 'We use%' AND answer = 'YES Member consents')

&nbsp;      OR (question LIKE 'Confirm consent with Member to move%' AND answer = 'Member consents')

),



-- pull CIN from the same eligibility submission

cin\_map AS (

&nbsp;   SELECT DISTINCT

&nbsp;       form\_submission\_id,

&nbsp;       seeker\_id,

&nbsp;       answer AS cin

&nbsp;   FROM responses\_ytd

&nbsp;   WHERE question LIKE '%CIN%'

&nbsp;     AND answer IS NOT NULL

),



-- ESMF eligibility flags (by CIN)

eligible\_flags AS (

&nbsp;   SELECT DISTINCT mbrID

&nbsp;   FROM dbo.nyec\_esmf

&nbsp;   WHERE \[EPOPHighUtilizer]     = 'Y'

&nbsp;      OR \[EPOPHHEnrolled]       = 'Y'

&nbsp;      OR \[EPOPOther]            = 'Y'

&nbsp;      OR \[EPOPPregPostpartum]   = 'Y'

&nbsp;      OR \[EPOPUnder18Nutrition] = 'Y'

&nbsp;      OR \[EPOPUnder18]          = 'Y'

&nbsp;      OR \[EPOPAdultCJ]          = 'Y'

&nbsp;      OR \[EPOPIDD]              = 'Y'  

)



SELECT

&nbsp;   COUNT(DISTINCT cm.cin) AS metric\_12

FROM consented\_members c

JOIN cin\_map cm

&nbsp; ON cm.form\_submission\_id = c.form\_submission\_id

JOIN eligible\_flags ef

&nbsp; ON ef.mbrID = cm.cin;











































## --13---# of Medicaid Members Assessed consenting to a referral





--=============================================================================================================================================================================================================================

--Date entry 8 ---Count of unique Medicaid Members who have one or more Completed Eligibility Assessments 

--indicating confirmed eligibility for Enhanced HRSN Services and have confirmed they want HRSN Services (within the past 12 months):

--=============================================================================================================================================================================================================================



WITH eligibility\_data AS (

&nbsp;	SELECT 

&nbsp;		f.seeker\_id,

&nbsp;		f.form\_submission\_id,

&nbsp;		cin.answer as cin,

&nbsp;		f.started\_at,

&nbsp;		f.question,

&nbsp;		f.answer

&nbsp;	FROM FH\_flipa\_mbr\_insights\_forms f

&nbsp;	JOIN FH\_flipa\_mbr\_insights\_forms cin

&nbsp;	  ON f.form\_submission\_id = cin.form\_submission\_id

&nbsp;     AND cin.question LIKE '%CIN%'

&nbsp;	WHERE f.form\_name LIKE '%eligibility%'   -- filters only eligibility screeners

&nbsp;	  AND f.started\_at >= '2025-01-01'

&nbsp;	  AND f.started\_at < DATEADD(DAY, 1, CAST(GETDATE() AS date))

&nbsp;	  AND f.seeker\_id IS NOT NULL

),



consented AS (

&nbsp;	SELECT DISTINCT form\_submission\_id, cin

&nbsp;	FROM eligibility\_data

&nbsp;	WHERE 

&nbsp;		(question LIKE 'We use%' AND answer = 'YES Member consents')

&nbsp;	     OR (question LIKE 'Confirm consent with Member to move%' AND answer = 'Member consents')     

),



want\_services AS (

&nbsp;	SELECT DISTINCT form\_submission\_id, cin

&nbsp;	FROM eligibility\_data

&nbsp;	WHERE question LIKE 'Does the member want%'

&nbsp;	  AND answer = 'yes'

)



-- Final count: members with consent + want services

SELECT COUNT(DISTINCT c.cin) AS metric\_13\_count

FROM consented c

JOIN want\_services w 

&nbsp; ON c.form\_submission\_id = w.form\_submission\_id;





























## --14--# of Enhanced Services Medicaid Members Assessed consenting to a referral   





--=============================================================================================================================================================================================================================

--Date entry 8 ---Count of unique Medicaid Members who have one or more Completed Eligibility Assessments indicating confirmed eligibility for Enhanced HRSN Services and have confirmed they want HRSN Services (within the past 12 months):

--=============================================================================================================================================================================================================================



WITH eligibility\_data AS (

&nbsp;	SELECT 

&nbsp;		f.seeker\_id,

&nbsp;		f.form\_submission\_id,

&nbsp;		cin.answer as cin,

&nbsp;		f.started\_at,

&nbsp;		f.question,

&nbsp;		f.answer

&nbsp;	FROM FH\_flipa\_mbr\_insights\_forms f

&nbsp;	JOIN FH\_flipa\_mbr\_insights\_forms cin

&nbsp;	  ON f.form\_submission\_id = cin.form\_submission\_id

&nbsp;     AND cin.question LIKE '%CIN%'

&nbsp;	WHERE f.form\_name LIKE '%eligibility%'-----THIS FILTERS ONLY HRSN SCREENERS

&nbsp;	  AND f.started\_at >'2025-01-01'

&nbsp;	  AND f.started\_at < DATEADD(DAY, 1, CAST(GETDATE() AS date))



&nbsp;	  AND f.seeker\_id IS NOT NULL

),

consented as (

&nbsp;	SELECT DISTINCT form\_submission\_id, cin

&nbsp;	FROM eligibility\_data

&nbsp;	WHERE (

&nbsp;			(question like 'We use%' AND answer = 'YES Member consents')

&nbsp;	     OR (question like 'Confirm consent with Member to move%' AND answer = 'Member consents')     

&nbsp;		 )

),

want\_services AS (

&nbsp;	SELECT  DISTINCT form\_submission\_id, cin

&nbsp;	FROM eligibility\_data

&nbsp;	WHERE question LIKE 'Does the member want%'

&nbsp;		AND answer = 'yes'

),



eligible\_flags AS (

&nbsp;	SELECT DISTINCT mbrID

&nbsp;	FROM dbo.nyec\_esmf

&nbsp;	WHERE \[EPOPHighUtilizer] = 'Y' OR \[EPOPHHEnrolled] = 'Y' OR \[EPOPOther] = 'Y' OR \[EPOPPregPostpartum] = 'Y' OR \[EPOPUnder18Nutrition] = 'Y' OR

&nbsp;      \[EPOPUnder18] = 'Y' OR \[EPOPAdultCJ] = 'Y'  OR \[EPOPIDD]              = 'Y'

)



SELECT COUNT(DISTINCT e.cin) AS metric\_14\_count

FROM eligibility\_data e

JOIN consented c ON e.form\_submission\_id = c.form\_submission\_id

JOIN want\_services w ON e.form\_submission\_id = w.form\_submission\_id

JOIN eligible\_flags f ON e.cin = f.mbrID;















