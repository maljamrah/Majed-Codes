# **--Refferals--**





## --15--# of Enhanced Services Medicaid Members with at least one referral (std or enhanced referral)





--=============================================================================================================================================================================================================================

--DATA ENTRY 9 : Count of unique Medicaid Members with one or more requested HRSN Referral (within the past month):

--=============================================================================================================================================================================================================================

--The referral must be someone who already met metric 8 conditions (confirmed unmet need, gave consent, said yes, and eligible via ESMF ) 

--This version counts referrals regardless of program type (no '%enhanced%' filter)



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

&nbsp;	WHERE f.form\_name LIKE '%eligibility%'   -- only eligibility screeners

&nbsp;	  AND cin.question LIKE '%CIN%'

&nbsp;	  AND f.started\_at >=  '2025-01-01' 

&nbsp;	  AND f.started\_at <  DATEADD(DAY, 1, CAST(GETDATE() AS date))



&nbsp;	  AND f.seeker\_id IS NOT NULL

),



consented AS (

&nbsp;	SELECT DISTINCT form\_submission\_id, cin, seeker\_id

&nbsp;	FROM eligibility\_data

&nbsp;	WHERE (question LIKE 'We use%' AND answer = 'YES Member consents')

&nbsp;	   OR (question LIKE 'Confirm consent with Member to move%' AND answer = 'Member consents')

),



want\_services AS (

&nbsp;	SELECT DISTINCT form\_submission\_id, cin, seeker\_id

&nbsp;	FROM eligibility\_data

&nbsp;	WHERE question LIKE 'Does the member want%'

&nbsp;	  AND answer = 'yes'

),



eligible\_flags AS (

&nbsp;	SELECT DISTINCT mbrID

&nbsp;	FROM dbo.nyec\_esmf

&nbsp;	WHERE \[EPOPHighUtilizer]     = 'Y'

&nbsp;	   OR \[EPOPHHEnrolled]       = 'Y'

&nbsp;	   OR \[EPOPOther]            = 'Y'

&nbsp;	   OR \[EPOPPregPostpartum]   = 'Y'

&nbsp;	   OR \[EPOPUnder18Nutrition] = 'Y'

&nbsp;	   OR \[EPOPUnder18]          = 'Y'

&nbsp;	   OR \[EPOPAdultCJ]          = 'Y'

&nbsp;          OR \[EPOPIDD]              = 'Y'

),



all\_referrals AS ( 

&nbsp;	SELECT DISTINCT r.seeker\_id

&nbsp;	FROM FH\_flipa\_mbr\_insights\_referrals r

&nbsp;	JOIN FH\_flipa\_mbr\_insights\_programs p

&nbsp;		ON r.program\_numeric\_id = p.program\_numeric\_id

&nbsp;	WHERE r.referral\_date >= '2025-01-01'

&nbsp;	  AND r.referral\_date <  DATEADD(DAY, 1, CAST(GETDATE() AS date))



)



-- Final count : (all referrals, not just enhanced)

SELECT COUNT(DISTINCT c.cin) AS Metric\_15\_Count

FROM consented c

JOIN want\_services w 

&nbsp;	ON c.form\_submission\_id = w.form\_submission\_id

JOIN eligible\_flags ef

&nbsp;	ON c.cin = ef.MbrID

JOIN all\_referrals ar

&nbsp;	ON c.seeker\_id = ar.seeker\_id;

















































## --16--# of Enhanced Services Medicaid Members with at least one enhanced HRSN referral

## 





--=============================================================================================================================================================================================================================

--DATA ENTRY 9 : Count of unique Medicaid Members with one or more requested Enhanced HRSN Referral (within the past month):

--=============================================================================================================================================================================================================================

--The referral must be someone who already met metric 8 conditions (confirmed unmet need, gave consent, said yes, and eligible via ESMF ) 

--The referral itself must be for an ENHANCED service (Programs with Enhanced keyword)





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

&nbsp;	WHERE f.form\_name LIKE '%eligibility%'-----THIS FILTERS ONLY HRSN SCREENERS

&nbsp;	  AND cin.question LIKE '%CIN%'

&nbsp;	  AND f.started\_at >= '2025-01-01'

&nbsp;	  AND f.started\_at < DATEADD(DAY, 1, CAST(GETDATE() AS date))

&nbsp;	  AND f.seeker\_id IS NOT NULL

),

consented as (

&nbsp;	SELECT DISTINCT form\_submission\_id, cin, seeker\_id

&nbsp;	FROM eligibility\_data

&nbsp;	WHERE (

&nbsp;			(question like 'We use%' AND answer = 'YES Member consents')

&nbsp;	     OR (question like 'Confirm consent with Member to move%' AND answer = 'Member consents')     

&nbsp;		 )

),

want\_services AS (

&nbsp;	SELECT  DISTINCT form\_submission\_id, cin, seeker\_id

&nbsp;	FROM eligibility\_data

&nbsp;	WHERE question LIKE 'Does the member want%'

&nbsp;		AND answer = 'yes'

),



eligible\_flags AS (

&nbsp;	SELECT DISTINCT mbrID

&nbsp;	FROM dbo.nyec\_esmf

&nbsp;	WHERE \[EPOPHighUtilizer] = 'Y' OR \[EPOPHHEnrolled] = 'Y' OR \[EPOPOther] = 'Y' OR \[EPOPPregPostpartum] = 'Y' OR \[EPOPUnder18Nutrition] = 'Y' OR

&nbsp;      \[EPOPUnder18] = 'Y' OR \[EPOPAdultCJ] = 'Y' OR \[EPOPIDD] = 'Y'

),



enhanced\_referrals AS ( 

&nbsp;	SELECT DISTINCT r.seeker\_id

&nbsp;	FROM FH\_flipa\_mbr\_insights\_referrals r

&nbsp;	JOIN FH\_flipa\_mbr\_insights\_programs p

&nbsp;		ON r.program\_numeric\_id = p.program\_numeric\_id

&nbsp;	WHERE p.program\_name LIKE '%enhanced%'

&nbsp;		AND r.referral\_date >= '2025-01-01'

&nbsp;		AND r.referral\_date < DATEADD(DAY, 1, CAST(GETDATE() AS date))

)



--Final count : Metric9

SELECT COUNT(DISTINCT c.cin) AS Metric\_16\_Count

FROM consented C 

JOIN want\_services w 

&nbsp;	ON c.form\_submission\_id = w.form\_submission\_id

JOIN eligible\_flags ef

&nbsp;	ON c.cin = ef.MbrID

JOIN enhanced\_referrals er

&nbsp;	ON c.seeker\_id = er.seeker\_id;











































## --17--# of Enhanced Services Medicaid Members with at least one enhanced HRSN service initiated







--==================================================================================================================================================================================================================================

--Data Entry 11  :  Count of unique Medicaid Members with one or more Enhanced HRSN services initiated (within the past month):

--==================================================================================================================================================================================================================================

--Pull referrals from the last month.

--Join to programs, keep only those with 'Enhanced'

--Fitler referrlas whose status from definitions tab ("Needs client action" , "Pending", "Referred Elsewhere" , "Got Help", "Eligible")

--Join back to Metric 8's eligible members( to avoid poker-machine false positives).

--Count distinct CINs.



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

&nbsp;	WHERE f.form\_name LIKE '%eligibility%'-----THIS FILTERS ONLY HRSN SCREENERS

&nbsp;	  AND cin.question LIKE '%CIN%'

&nbsp;	  AND f.started\_at >= '2025-01-01' 

&nbsp;	  AND f.started\_at < DATEADD(DAY, 1, CAST(GETDATE() AS date))

&nbsp;	  AND f.seeker\_id IS NOT NULL

),

consented as (

&nbsp;	SELECT DISTINCT form\_submission\_id, cin, seeker\_id

&nbsp;	FROM eligibility\_data

&nbsp;	WHERE (

&nbsp;			(question like 'We use%' AND answer = 'YES Member consents')

&nbsp;	     OR (question like 'Confirm consent with Member to move%' AND answer = 'Member consents')     

&nbsp;		 )

),

want\_services AS (

&nbsp;	SELECT  DISTINCT form\_submission\_id, cin, seeker\_id

&nbsp;	FROM eligibility\_data

&nbsp;	WHERE question LIKE 'Does the member want%'

&nbsp;		AND answer = 'yes'

),



eligible\_flags AS (

&nbsp;	SELECT DISTINCT mbrID

&nbsp;	FROM dbo.nyec\_esmf

&nbsp;	WHERE \[EPOPHighUtilizer] = 'Y' OR \[EPOPHHEnrolled] = 'Y' OR \[EPOPOther] = 'Y' OR \[EPOPPregPostpartum] = 'Y' OR \[EPOPUnder18Nutrition] = 'Y' OR

&nbsp;      \[EPOPUnder18] = 'Y' OR \[EPOPAdultCJ] = 'Y' OR \[EPOPIDD] = 'Y'

),



enhanced\_referrals AS ( 

&nbsp;	SELECT DISTINCT r.seeker\_id, r.referral\_status

&nbsp;	FROM FH\_flipa\_mbr\_insights\_referrals r

&nbsp;	JOIN FH\_flipa\_mbr\_insights\_programs p

&nbsp;		ON r.program\_numeric\_id = p.program\_numeric\_id

&nbsp;	WHERE p.program\_name LIKE '%enhanced%'

&nbsp;		AND r.referral\_date >= '2025-01-01'

&nbsp;		AND r.referral\_date < DATEADD(DAY, 1, CAST(GETDATE() AS date))

&nbsp;		---Metric 11 change: Referall status show "initiated" from Definitions tab

&nbsp;		AND r.referral\_status IN ('needs client action' , 'pending' , 'referred elsewhere' , 'got help','eligible')

)



--Final count : Metric11

SELECT COUNT(DISTINCT c.cin) AS Metric\_17\_Count

FROM consented C 

JOIN want\_services w 

&nbsp;	ON c.form\_submission\_id = w.form\_submission\_id

JOIN eligible\_flags ef

&nbsp;	ON c.cin = ef.MbrID

JOIN enhanced\_referrals er

&nbsp;	ON c.seeker\_id = er.seeker\_id



































## ---25---# of unique members referred to a standard or enhanced service---







WITH eligibility\_data AS (

 	SELECT

 		f.seeker\_id,

 		f.form\_submission\_id,

 		cin.answer as cin,

 		f.started\_at,

 		f.question,

 		f.answer

 	FROM FH\_flipa\_mbr\_insights\_forms f

 	JOIN FH\_flipa\_mbr\_insights\_forms cin

 	  ON f.form\_submission\_id = cin.form\_submission\_id

 	WHERE f.form\_name LIKE '%eligibility%'   -- only eligibility screeners

 	  AND cin.question LIKE '%CIN%'

 	  AND f.started\_at >=  '2025-01-01'

 	  AND f.started\_at <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

 	  AND f.seeker\_id IS NOT NULL

),



consented AS (

 	SELECT DISTINCT form\_submission\_id, cin, seeker\_id

 	FROM eligibility\_data

 	WHERE (question LIKE 'We use%' AND answer = 'YES Member consents')

 	   OR (question LIKE 'Confirm consent with Member to move%' AND answer = 'Member consents')

),



want\_services AS (

 	SELECT DISTINCT form\_submission\_id, cin, seeker\_id

 	FROM eligibility\_data

 	WHERE question LIKE 'Does the member want%'

 	  AND answer = 'yes'

),



all\_referrals AS (

 	SELECT DISTINCT r.seeker\_id

 	FROM FH\_flipa\_mbr\_insights\_referrals r

 	JOIN FH\_flipa\_mbr\_insights\_programs p

 		ON r.program\_numeric\_id = p.program\_numeric\_id

 	WHERE r.referral\_date >= '2025-01-01'

 	  AND r.referral\_date <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

)



-- Final count : Metric9 (all referrals, not just enhanced)

SELECT COUNT(DISTINCT c.cin) AS Metric\_25\_Count

FROM consented c

JOIN want\_services w

 	ON c.form\_submission\_id = w.form\_submission\_id

JOIN all\_referrals ar

 	ON c.seeker\_id = ar.seeker\_id;











































## --26--# of total referrals made to a standard or enhanced service--













-- # of total referrals made to a standard or enhanced service (YTD)

-- Counts every referral row (activity volume), not distinct members.



;WITH referrals\_ytd AS (

    SELECT

        r.referral\_id,

        r.seeker\_id,

        r.referral\_date,

        p.program\_name

    FROM FH\_flipa\_mbr\_insights\_referrals r

    JOIN FH\_flipa\_mbr\_insights\_programs  p

      ON r.program\_numeric\_id = p.program\_numeric\_id

    WHERE r.referral\_date >= '2025-01-01'

      AND r.referral\_date < DATEADD(DAY, 1, CAST(GETDATE() AS date))

      )



-- Total referrals

SELECT COUNT(\*) AS total\_referrals\_YTD

FROM referrals\_ytd;

































## --28--# of members for which a service is initiated--









--==================================================================================================================================================================================================================================

--Data Entry 11  :  Count of unique Medicaid Members with one or more Enhanced HRSN services initiated (within the past month):

--==================================================================================================================================================================================================================================

--Pull referrals from the last month.

--Join to programs, keep only those with 'Enhanced'

--Fitler referrlas whose status from definitions tab ("Needs client action" , "Pending", "Referred Elsewhere" , "Got Help", "Eligible")

--Join back to Metric 8's eligible members( to avoid poker-machine false positives).

--Count distinct CINs.



WITH eligibility\_data AS (

 	SELECT

 		f.seeker\_id,

 		f.form\_submission\_id,

 		cin.answer as cin,

 		f.started\_at,

 		f.question,

 		f.answer

 	FROM FH\_flipa\_mbr\_insights\_forms f

 	JOIN FH\_flipa\_mbr\_insights\_forms cin

 	  ON f.form\_submission\_id = cin.form\_submission\_id

 	WHERE f.form\_name LIKE '%eligibility%'-----THIS FILTERS ONLY HRSN SCREENERS

 	  AND cin.question LIKE '%CIN%'

 	  AND f.started\_at >= '2025-01-01'

 	  AND f.started\_at < DATEADD(DAY, 1, CAST(GETDATE() AS date))



 	  AND f.seeker\_id IS NOT NULL

),

consented as (

 	SELECT DISTINCT form\_submission\_id, cin, seeker\_id

 	FROM eligibility\_data

 	WHERE (

 			(question like 'We use%' AND answer = 'YES Member consents')

 	     OR (question like 'Confirm consent with Member to move%' AND answer = 'Member consents')

 		 )

),

want\_services AS (

 	SELECT  DISTINCT form\_submission\_id, cin, seeker\_id

 	FROM eligibility\_data

 	WHERE question LIKE 'Does the member want%'

 		AND answer = 'yes'

),



eligible\_flags AS (

 	SELECT DISTINCT mbrID

 	FROM dbo.nyec\_esmf

 	WHERE \[EPOPHighUtilizer] = 'Y' OR \[EPOPHHEnrolled] = 'Y' OR \[EPOPOther] = 'Y' OR \[EPOPPregPostpartum] = 'Y' OR \[EPOPUnder18Nutrition] = 'Y' OR

       \[EPOPUnder18] = 'Y' OR \[EPOPAdultCJ] = 'Y' OR \[EPOPIDD] = 'Y'



),



enhanced\_referrals AS (

 	SELECT DISTINCT r.seeker\_id, r.referral\_status

 	FROM FH\_flipa\_mbr\_insights\_referrals r

 	JOIN FH\_flipa\_mbr\_insights\_programs p

 		ON r.program\_numeric\_id = p.program\_numeric\_id

 	WHERE p.program\_name LIKE '%enhanced%'

 		AND r.referral\_date >= '2025-01-01'

 		AND r.referral\_date < DATEADD(DAY, 1, CAST(GETDATE() AS date))



 		---Metric 11 change: Referall status show "initiated" from Definitions tab

 		AND r.referral\_status IN ('needs client action' , 'pending' , 'referred elsewhere' , 'got help','eligible')

)



--Final count : Metric11

SELECT COUNT(DISTINCT c.cin) AS Metric\_28\_Count

FROM consented C

JOIN want\_services w

 	ON c.form\_submission\_id = w.form\_submission\_id

JOIN eligible\_flags ef

 	ON c.cin = ef.MbrID

JOIN enhanced\_referrals er

 	ON c.seeker\_id = er.seeker\_id







































## ---- # of total referrals made to a STANDARD service (YTD)

-- Counts every referral row to programs NOT marked "enhanced".



;WITH std\_referrals\_ytd AS (

    SELECT

        r.referral\_id,

        r.seeker\_id,

        r.referral\_date,

        p.program\_name

    FROM FH\_flipa\_mbr\_insights\_referrals r

    JOIN FH\_flipa\_mbr\_insights\_programs p

      ON r.program\_numeric\_id = p.program\_numeric\_id

    WHERE r.referral\_date >= '2025-01-01'

      AND r.referral\_date <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

      AND p.program\_name NOT LIKE '%enhanced%'   -- STANDARD services only

 

)

SELECT COUNT(\*) AS total\_standard\_referrals\_YTD

FROM std\_referrals\_ytd;

























































## -- % of members referred to STANDARD services-- among those who completed Eligibility Assessment (CONSENTED) – YTD



WITH base\_responses AS (

    SELECT

        seeker\_id,

        question,

        answer,

        form\_submission\_id,

        started\_at

    FROM FH\_flipa\_mbr\_insights\_forms

    WHERE form\_name LIKE '%eligibility%'      -- Eligibility Assessments

      AND seeker\_id IS NOT NULL               -- exclude orphaned

),

responses\_ytd AS (                             -- YTD window

    SELECT \*

    FROM base\_responses

    WHERE started\_at >= '2025-01-01'

      AND started\_at <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

),

consented\_members AS (                         -- denominator cohort

    SELECT DISTINCT form\_submission\_id, seeker\_id

    FROM responses\_ytd

    WHERE (question LIKE 'We use%' AND answer = 'YES Member consents')

       OR (question LIKE 'Confirm consent with Member to move%' AND answer = 'Member consents')

),

std\_ref\_members AS (                           -- numerator: ≥1 Standard referral

    SELECT DISTINCT cm.seeker\_id

    FROM consented\_members cm

    WHERE EXISTS (

        SELECT 1

        FROM FH\_flipa\_mbr\_insights\_referrals r

        JOIN FH\_flipa\_mbr\_insights\_programs p

          ON p.program\_numeric\_id = r.program\_numeric\_id

        WHERE r.seeker\_id = cm.seeker\_id

          AND r.referral\_date >= '2025-01-01'

          AND r.referral\_date <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

          AND p.program\_name NOT LIKE '%enhanced%'     -- STANDARD services

              )

)



SELECT

    (SELECT COUNT(DISTINCT seeker\_id) FROM consented\_members) AS denom\_consented\_YTD,

    (SELECT COUNT(DISTINCT seeker\_id) FROM std\_ref\_members)   AS numer\_std\_ref\_YTD,

    CAST(

        100.0 \* (SELECT COUNT(DISTINCT seeker\_id) FROM std\_ref\_members)

        / NULLIF((SELECT COUNT(DISTINCT seeker\_id) FROM consented\_members), 0)

        AS DECIMAL(5,2)

    ) AS pct\_std\_ref\_among\_consented\_YTD;



















































## --# of members for which a standard service is referred--









--=============================================================================================================================================================================================================================

--DATA ENTRY 9 : Count of unique Medicaid Members with one or more requested Enhanced HRSN Referral (within the past month)

--=============================================================================================================================================================================================================================

--Now simplified: Only checks for consented members who have any Enhanced referral (no "want\_services" or "eligible\_flags" filtering).



WITH eligibility\_data AS (

 	SELECT

 		f.seeker\_id,

 		f.form\_submission\_id,

 		cin.answer AS cin,

 		f.started\_at,

 		f.question,

 		f.answer

 	FROM FH\_flipa\_mbr\_insights\_forms f

 	JOIN FH\_flipa\_mbr\_insights\_forms cin

 	  ON f.form\_submission\_id = cin.form\_submission\_id

 	WHERE f.form\_name LIKE '%eligibility%'   -- Only eligibility screeners

 	  AND cin.question LIKE '%CIN%'

 	  AND f.started\_at >= '2025-01-01'

 	  AND f.started\_at <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

 	  AND f.seeker\_id IS NOT NULL

),



consented AS (

 	SELECT DISTINCT form\_submission\_id, cin, seeker\_id

 	FROM eligibility\_data

 	WHERE (question LIKE 'We use%' AND answer = 'YES Member consents')

 	   OR (question LIKE 'Confirm consent with Member to move%' AND answer = 'Member consents')

),



enhanced\_referrals AS (

 	SELECT DISTINCT r.seeker\_id

 	FROM FH\_flipa\_mbr\_insights\_referrals r

 	JOIN FH\_flipa\_mbr\_insights\_programs p

 		ON r.program\_numeric\_id = p.program\_numeric\_id

 	WHERE p.program\_name NOT LIKE '%enhanced%'

 	  AND r.referral\_date >= '2025-01-01'

 	  AND r.referral\_date <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

)



--Final Count: Enhanced HRSN Referrals (Consent only)

SELECT COUNT(DISTINCT c.cin) AS Metric\_9\_Count

FROM consented c

JOIN enhanced\_referrals er

 	ON c.seeker\_id = er.seeker\_id;







































































## 

## --29--% of inbound enhanced referrals to housing services--









--=============================================================================================================================================================================================================================

-- % of inbound ENHANCED referrals to HOUSING services (YTD) — using Program Categories

--=============================================================================================================================================================================================================================

-- Denominator: Members who are consented, want services, ESMF-eligible, and have ≥1 enhanced referral

-- Numerator: Subset of those referrals where category = 'Housing' (or contains 'Hous')



DECLARE @denominator INT;

DECLARE @numerator INT;



-- ===== Base Eligibility \& Consent =====

WITH eligibility\_data AS (

 	SELECT

 		f.seeker\_id,

 		f.form\_submission\_id,

 		cin.answer AS cin,

 		f.started\_at,

 		f.question,

 		f.answer

 	FROM FH\_flipa\_mbr\_insights\_forms f

 	JOIN FH\_flipa\_mbr\_insights\_forms cin

 	  ON f.form\_submission\_id = cin.form\_submission\_id

 	WHERE f.form\_name LIKE '%eligibility%'

 	  AND cin.question LIKE '%CIN%'

 	  AND f.started\_at >= '2025-01-01'

 	  AND f.started\_at <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

 	  AND f.seeker\_id IS NOT NULL

),



consented AS (

 	SELECT DISTINCT form\_submission\_id, cin, seeker\_id

 	FROM eligibility\_data

 	WHERE (question LIKE 'We use%' AND answer = 'YES Member consents')

 	   OR (question LIKE 'Confirm consent with Member to move%' AND answer = 'Member consents')

),



want\_services AS (

 	SELECT DISTINCT form\_submission\_id, cin, seeker\_id

 	FROM eligibility\_data

 	WHERE question LIKE 'Does the member want%' AND answer = 'yes'

),



eligible\_flags AS (

 	SELECT DISTINCT mbrID

 	FROM dbo.nyec\_esmf

 	WHERE \[EPOPHighUtilizer]     = 'Y'

 	   OR \[EPOPHHEnrolled]       = 'Y'

 	   OR \[EPOPOther]            = 'Y'

 	   OR \[EPOPPregPostpartum]   = 'Y'

 	   OR \[EPOPUnder18Nutrition] = 'Y'

 	   OR \[EPOPUnder18]          = 'Y'

 	   OR \[EPOPAdultCJ]          = 'Y'

           OR \[EPOPIDD]                                      =  'Y'

),



-- ===== Enhanced referrals: now including program category instead of name =====

enhanced\_referrals AS (

 	SELECT DISTINCT r.seeker\_id, p.categories

 	FROM FH\_flipa\_mbr\_insights\_referrals r

 	JOIN FH\_flipa\_mbr\_insights\_programs p

 	  ON r.program\_numeric\_id = p.program\_numeric\_id

 	WHERE p.program\_name LIKE '%enhanced%'

 	  AND r.referral\_date >= '2025-01-01'

 	  AND r.referral\_date <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

),



-- ===== Denominator: all enhanced referrals (for eligible, consented, want services) =====

denominator\_cte AS (

 	SELECT DISTINCT c.cin

 	FROM consented c

 	JOIN want\_services w   ON c.form\_submission\_id = w.form\_submission\_id

 	JOIN eligible\_flags ef ON ef.mbrID = c.cin

 	JOIN enhanced\_referrals er ON er.seeker\_id = c.seeker\_id

),



-- ===== Numerator: same, but only referrals categorized as Housing =====

numerator\_cte AS (

 	SELECT DISTINCT c.cin

 	FROM consented c

 	JOIN want\_services w   ON c.form\_submission\_id = w.form\_submission\_id

 	JOIN eligible\_flags ef ON ef.mbrID = c.cin

 	JOIN enhanced\_referrals er ON er.seeker\_id = c.seeker\_id

 	WHERE er.categories LIKE '%hous%'

)



-- ===== Final Counts and % =====

SELECT

 	@denominator = (SELECT COUNT(DISTINCT cin) FROM denominator\_cte),

 	@numerator   = (SELECT COUNT(DISTINCT cin) FROM numerator\_cte);



SELECT

 	@denominator AS Denominator\_Metric9\_YTD,

 	@numerator   AS Numerator\_Housing\_YTD,

 	CAST(100.0 \* @numerator / NULLIF(@denominator, 0) AS DECIMAL(5,2)) AS Pct\_Housing\_of\_Enhanced\_Referrals\_YTD;





































## --30--% of inbound enhanced referrals to food/nutrition services --









--=============================================================================================================================================================================================================================

-- % of inbound enhanced referrals to food/nutrition services (YTD) — using Program Categories

--=============================================================================================================================================================================================================================

-- Denominator: Members who are consented, want services, ESMF-eligible, and have ≥1 enhanced referral

-- Numerator: Subset of those referrals where category = 'food/nutrition'



DECLARE @denominator INT;

DECLARE @numerator INT;



-- ===== Base Eligibility \& Consent =====

WITH eligibility\_data AS (

 	SELECT

 		f.seeker\_id,

 		f.form\_submission\_id,

 		cin.answer AS cin,

 		f.started\_at,

 		f.question,

 		f.answer

 	FROM FH\_flipa\_mbr\_insights\_forms f

 	JOIN FH\_flipa\_mbr\_insights\_forms cin

 	  ON f.form\_submission\_id = cin.form\_submission\_id

 	WHERE f.form\_name LIKE '%eligibility%'

 	  AND cin.question LIKE '%CIN%'

 	  AND f.started\_at >= '2025-01-01'

 	  AND f.started\_at <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

 	  AND f.seeker\_id IS NOT NULL

),



consented AS (

 	SELECT DISTINCT form\_submission\_id, cin, seeker\_id

 	FROM eligibility\_data

 	WHERE (question LIKE 'We use%' AND answer = 'YES Member consents')

 	   OR (question LIKE 'Confirm consent with Member to move%' AND answer = 'Member consents')

),



want\_services AS (

 	SELECT DISTINCT form\_submission\_id, cin, seeker\_id

 	FROM eligibility\_data

 	WHERE question LIKE 'Does the member want%' AND answer = 'yes'

),



eligible\_flags AS (

 	SELECT DISTINCT mbrID

 	FROM dbo.nyec\_esmf

 	WHERE \[EPOPHighUtilizer]     = 'Y'

 	   OR \[EPOPHHEnrolled]       = 'Y'

 	   OR \[EPOPOther]            = 'Y'

 	   OR \[EPOPPregPostpartum]   = 'Y'

 	   OR \[EPOPUnder18Nutrition] = 'Y'

 	   OR \[EPOPUnder18]          = 'Y'

 	   OR \[EPOPAdultCJ]          = 'Y'

           OR \[EPOPIDD]                                      =  'Y'



),



-- ===== Enhanced referrals: now including program category instead of name =====

enhanced\_referrals AS (

 	SELECT DISTINCT r.seeker\_id, p.categories

 	FROM FH\_flipa\_mbr\_insights\_referrals r

 	JOIN FH\_flipa\_mbr\_insights\_programs p

 	  ON r.program\_numeric\_id = p.program\_numeric\_id

 	WHERE p.program\_name LIKE '%enhanced%'

 	  AND r.referral\_date >= '2025-01-01'

 	  AND r.referral\_date <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

),



-- ===== Denominator: all enhanced referrals (for eligible, consented, want services) =====

denominator\_cte AS (

 	SELECT DISTINCT c.cin

 	FROM consented c

 	JOIN want\_services w   ON c.form\_submission\_id = w.form\_submission\_id

 	JOIN eligible\_flags ef ON ef.mbrID = c.cin

 	JOIN enhanced\_referrals er ON er.seeker\_id = c.seeker\_id

),



-- ===== Numerator: same, but only referrals categorized as food/nutrition =====

numerator\_cte AS (

 	SELECT DISTINCT c.cin

 	FROM consented c

 	JOIN want\_services w   ON c.form\_submission\_id = w.form\_submission\_id

 	JOIN eligible\_flags ef ON ef.mbrID = c.cin

 	JOIN enhanced\_referrals er ON er.seeker\_id = c.seeker\_id

 	WHERE er.categories LIKE '%food%'-- match 'Housing', 'House Assistance', etc.

 	   OR er.categories LIKE '%nutr%'

)



-- ===== Final Counts and % =====

SELECT

 	@denominator = (SELECT COUNT(DISTINCT cin) FROM denominator\_cte),

 	@numerator   = (SELECT COUNT(DISTINCT cin) FROM numerator\_cte);



SELECT

 	@denominator AS Denominator\_Metric9\_YTD,

 	@numerator   AS Numerator\_Housing\_YTD,

 	CAST(100.0 \* @numerator / NULLIF(@denominator, 0) AS DECIMAL(5,2)) AS Pct\_Housing\_of\_Enhanced\_Referrals\_YTD;



























# 

# --31--% of inbound enhanced referrals to care management services--









--=============================================================================================================================================================================================================================

-- % of inbound enhanced referrals to care management services (YTD) — using Program Categories

--=============================================================================================================================================================================================================================

-- Denominator: Members who are consented, want services, ESMF-eligible, and have ≥1 enhanced referral

-- Numerator: Subset of those referrals where category = 'care management services'



DECLARE @denominator INT;

DECLARE @numerator INT;



-- ===== Base Eligibility \& Consent =====

WITH eligibility\_data AS (

 	SELECT

 		f.seeker\_id,

 		f.form\_submission\_id,

 		cin.answer AS cin,

 		f.started\_at,

 		f.question,

 		f.answer

 	FROM FH\_flipa\_mbr\_insights\_forms f

 	JOIN FH\_flipa\_mbr\_insights\_forms cin

 	  ON f.form\_submission\_id = cin.form\_submission\_id

 	WHERE f.form\_name LIKE '%eligibility%'

 	  AND cin.question LIKE '%CIN%'

 	  AND f.started\_at >= '2025-01-01'

 	  AND f.started\_at <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

 	  AND f.seeker\_id IS NOT NULL

),



consented AS (

 	SELECT DISTINCT form\_submission\_id, cin, seeker\_id

 	FROM eligibility\_data

 	WHERE (question LIKE 'We use%' AND answer = 'YES Member consents')

 	   OR (question LIKE 'Confirm consent with Member to move%' AND answer = 'Member consents')

),



want\_services AS (

 	SELECT DISTINCT form\_submission\_id, cin, seeker\_id

 	FROM eligibility\_data

 	WHERE question LIKE 'Does the member want%' AND answer = 'yes'

),



eligible\_flags AS (

 	SELECT DISTINCT mbrID

 	FROM dbo.nyec\_esmf

 	WHERE \[EPOPHighUtilizer]     = 'Y'

 	   OR \[EPOPHHEnrolled]       = 'Y'

 	   OR \[EPOPOther]            = 'Y'

 	   OR \[EPOPPregPostpartum]   = 'Y'

 	   OR \[EPOPUnder18Nutrition] = 'Y'

 	   OR \[EPOPUnder18]          = 'Y'

 	   OR \[EPOPAdultCJ]          = 'Y'

           OR \[EPOPIDD]                                      =  'Y'



),



-- ===== Enhanced referrals: now including program category instead of name =====

enhanced\_referrals AS (

 	SELECT DISTINCT r.seeker\_id, p.categories

 	FROM FH\_flipa\_mbr\_insights\_referrals r

 	JOIN FH\_flipa\_mbr\_insights\_programs p

 	  ON r.program\_numeric\_id = p.program\_numeric\_id

 	WHERE p.program\_name LIKE '%enhanced%'

 	  AND r.referral\_date >= '2025-01-01'

 	  AND r.referral\_date <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

),



-- ===== Denominator: all enhanced referrals (for eligible, consented, want services) =====

denominator\_cte AS (

 	SELECT DISTINCT c.cin

 	FROM consented c

 	JOIN want\_services w   ON c.form\_submission\_id = w.form\_submission\_id

 	JOIN eligible\_flags ef ON ef.mbrID = c.cin

 	JOIN enhanced\_referrals er ON er.seeker\_id = c.seeker\_id

),



-- ===== Numerator: same, but only referrals categorized as care management services =====

numerator\_cte AS (

 	SELECT DISTINCT c.cin

 	FROM consented c

 	JOIN want\_services w   ON c.form\_submission\_id = w.form\_submission\_id

 	JOIN eligible\_flags ef ON ef.mbrID = c.cin

 	JOIN enhanced\_referrals er ON er.seeker\_id = c.seeker\_id

 	WHERE er.categories LIKE '%manag%'--

 	   OR er.categories LIKE '%care%'

)



-- ===== Final Counts and % =====

SELECT

 	@denominator = (SELECT COUNT(DISTINCT cin) FROM denominator\_cte),

 	@numerator   = (SELECT COUNT(DISTINCT cin) FROM numerator\_cte);



SELECT

 	@denominator AS Denominator\_Metric9\_YTD,

 	@numerator   AS Numerator\_Housing\_YTD,

 	CAST(100.0 \* @numerator / NULLIF(@denominator, 0) AS DECIMAL(5,2)) AS Pct\_Housing\_of\_Enhanced\_Referrals\_YTD;































## --32--% of inbound enhanced referrals to transportation services--

















--=============================================================================================================================================================================================================================

-- % of inbound enhanced referrals to transportation services (YTD) — using Program Categories

--=============================================================================================================================================================================================================================

-- Denominator: Members who are consented, want services, ESMF-eligible, and have ≥1 enhanced referral

-- Numerator: Subset of those referrals where category = 'transportation'



DECLARE @denominator INT;

DECLARE @numerator INT;



-- ===== Base Eligibility \& Consent =====

WITH eligibility\_data AS (

 	SELECT

 		f.seeker\_id,

 		f.form\_submission\_id,

 		cin.answer AS cin,

 		f.started\_at,

 		f.question,

 		f.answer

 	FROM FH\_flipa\_mbr\_insights\_forms f

 	JOIN FH\_flipa\_mbr\_insights\_forms cin

 	  ON f.form\_submission\_id = cin.form\_submission\_id

 	WHERE f.form\_name LIKE '%eligibility%'

 	  AND cin.question LIKE '%CIN%'

 	  AND f.started\_at >= '2025-01-01'

 	  AND f.started\_at <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

 	  AND f.seeker\_id IS NOT NULL

),



consented AS (

 	SELECT DISTINCT form\_submission\_id, cin, seeker\_id

 	FROM eligibility\_data

 	WHERE (question LIKE 'We use%' AND answer = 'YES Member consents')

 	   OR (question LIKE 'Confirm consent with Member to move%' AND answer = 'Member consents')

),



want\_services AS (

 	SELECT DISTINCT form\_submission\_id, cin, seeker\_id

 	FROM eligibility\_data

 	WHERE question LIKE 'Does the member want%' AND answer = 'yes'

),



eligible\_flags AS (

 	SELECT DISTINCT mbrID

 	FROM dbo.nyec\_esmf

 	WHERE \[EPOPHighUtilizer]     = 'Y'

 	   OR \[EPOPHHEnrolled]       = 'Y'

 	   OR \[EPOPOther]            = 'Y'

 	   OR \[EPOPPregPostpartum]   = 'Y'

 	   OR \[EPOPUnder18Nutrition] = 'Y'

 	   OR \[EPOPUnder18]          = 'Y'

 	   OR \[EPOPAdultCJ]          = 'Y'

           OR \[EPOPIDD]                                      =  'Y'



),



-- ===== Enhanced referrals: now including program category instead of name =====

enhanced\_referrals AS (

 	SELECT DISTINCT r.seeker\_id, p.service\_tags

 	FROM FH\_flipa\_mbr\_insights\_referrals r

 	JOIN FH\_flipa\_mbr\_insights\_programs p

 	  ON r.program\_numeric\_id = p.program\_numeric\_id

 	WHERE p.program\_name LIKE '%enhanced%'

 	  AND r.referral\_date >= '2025-01-01'

 	  AND r.referral\_date <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

),



-- ===== Denominator: all enhanced referrals (for eligible, consented, want services) =====

denominator\_cte AS (

 	SELECT DISTINCT c.cin

 	FROM consented c

 	JOIN want\_services w   ON c.form\_submission\_id = w.form\_submission\_id

 	JOIN eligible\_flags ef ON ef.mbrID = c.cin

 	JOIN enhanced\_referrals er ON er.seeker\_id = c.seeker\_id

),



-- ===== Numerator: same, but only referrals categorized as transportatio =====

numerator\_cte AS (

 	SELECT DISTINCT c.cin

 	FROM consented c

 	JOIN want\_services w   ON c.form\_submission\_id = w.form\_submission\_id

 	JOIN eligible\_flags ef ON ef.mbrID = c.cin

 	JOIN enhanced\_referrals er ON er.seeker\_id = c.seeker\_id

 	WHERE er.service\_tags LIKE '%transp%'-- match 'Housing', 'House Assistance', etc.

 

)



-- ===== Final Counts and % =====

SELECT

 	@denominator = (SELECT COUNT(DISTINCT cin) FROM denominator\_cte),

 	@numerator   = (SELECT COUNT(DISTINCT cin) FROM numerator\_cte);



SELECT

 	@denominator AS Denominator\_Metric9\_YTD,

 	@numerator   AS Numerator\_Housing\_YTD,

 	CAST(100.0 \* @numerator / NULLIF(@denominator, 0) AS DECIMAL(5,2)) AS Pct\_Housing\_of\_Enhanced\_Referrals\_YTD;











































