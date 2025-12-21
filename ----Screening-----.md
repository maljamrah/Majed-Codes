# **------Screening-----**



## ------5---- # of Medicaid Members Screened





--=============================================================================================================================================================================================================================

--Data Entry Point 5--Count of unique medicaid members with a completed screening (within the Past month by giving consent to Data Sharing AND answering at least one valid screening question.

--=============================================================================================================================================================================================================================

--Doh requirements : Based on Updated DOH guidance(Version 3 Monthly Report Instructions)

-- Screening questions : Q1 to Q12

-- Consent question : Must answer ("Yes I Consent", "Member Agreed" )

-- Excluded non-responses like 'declined to answer',screener did not ask member', Null

-- Cross check : Metric 5 = Metric 3-Metric 4



WITH base\_responses AS (                    ---Pull All HRSN form responses from isnights table

&nbsp;	SELECT 

&nbsp;		seeker\_id,

&nbsp;		question,

&nbsp;		answer,

&nbsp;		form\_name,

&nbsp;		started\_at,

&nbsp;		form\_submission\_id

&nbsp;	FROM FH\_flipa\_mbr\_insights\_forms

&nbsp;	WHERE form\_name LIKE '%HRSN%'

),



responses\_in\_month AS (											--- CTE to filter the date for that specific month

&nbsp;	SELECT \* 

&nbsp;	FROM base\_responses

&nbsp;	WHERE started\_at >= '2025-01-01' 

&nbsp;	  AND started\_at< DATEADD(DAY, 1, CAST(GETDATE() AS date))

),



consented\_members AS (											--- CTE to filter consent members who said yes

&nbsp;	SELECT DISTINCT form\_submission\_id, seeker\_id

&nbsp;	FROM responses\_in\_month

&nbsp;	WHERE question like 'We use%'

&nbsp;	  AND answer  in ('Yes, I consent','Member agreed','Member consents')

),



valid\_screening\_responses AS (		-- CTE to filter who answered 1 of the following 12 questions with valid responses this is optional as of sep 25 database as the screening is inserted into the DB the screening will be saved only if a question is asnwered.

&nbsp;	SELECT DISTINCT form\_submission\_id

&nbsp;	FROM responses\_in\_month

&nbsp;	WHERE question IN (

&nbsp;		---Question 1-8

&nbsp;		'What is your living situation today?', 

&nbsp;		'Think about the place you live. Do you have problems with any of the following?',

&nbsp;		'In the past 12 months has the electric, gas, oil, or water company threatened to shut off services in your home??', 

&nbsp;		'Within the past 12 months, you worried that your food would run out before you got money to buy more.',

&nbsp;		'Within the past 12 months, the food you bought just didn''t last and you didn''t have money to get more.',

&nbsp;		'In the past 12 months, has lack of reliable transportation kept you from medical appointments, meetings, work or from getting things needed for daily living?',

&nbsp;		'Do you want help finding or keeping work or a job?',

&nbsp;		'Do you want help with school or training? For example, starting or completing job training or getting a high school diploma, GED or equivalent',

&nbsp;		---Questions 9-12

&nbsp;		'How often does anyone, including family and friends, physically hurt you??',

&nbsp;		'How often does anyone, including family and friends, insult or talk down to you?',

&nbsp;		'How often does anyone, including family and friends, threaten you with harm?',

&nbsp;		'How often does anyone, including family and friends, scream or curse at you??'

&nbsp;	) 

&nbsp;	AND answer IS NOT NULL

&nbsp;	AND answer NOT IN ('Asked but Member declined to answer.','Decline to answer','Screener did not ask Member.')

)

select count(Distinct c.seeker\_id) AS completed\_screening\_count   --- Inner joins CTE Screenin and consent and give the rows which match both.

from consented\_members c

JOIN  valid\_screening\_responses v on c.form\_submission\_id = v.form\_submission\_id;













































## --------6--------# of Enhanced Services Medicaid Members Screened





--=============================================================================================================================================================================================================================

-- Data Entry Point 5 — Completed Screening (consent + ≥1 valid question) LIMITED TO ESMF-eligible members

--=============================================================================================================================================================================================================================



WITH base\_responses AS (                    -- Pull All HRSN form responses from insights table

&nbsp;   SELECT 

&nbsp;       seeker\_id,

&nbsp;       question,

&nbsp;       answer,

&nbsp;       form\_name,

&nbsp;       started\_at,

&nbsp;       form\_submission\_id

&nbsp;   FROM FH\_flipa\_mbr\_insights\_forms

&nbsp;   WHERE form\_name LIKE '%HRSN%'

),



responses\_in\_month AS (                     -- Month window (adjust dates as needed)

&nbsp;   SELECT \* 

&nbsp;   FROM base\_responses

&nbsp;   WHERE started\_at >= '2025-01-01' 

&nbsp;     AND started\_at < DATEADD(DAY, 1, CAST(GETDATE() AS date) )

),



consented\_members AS (                      -- Members who consented

&nbsp;   SELECT DISTINCT form\_submission\_id, seeker\_id

&nbsp;   FROM responses\_in\_month

&nbsp;   WHERE question LIKE 'We use%'

&nbsp;     AND answer IN ('Yes, I consent','Member agreed','Member consents')

),



valid\_screening\_responses AS (              -- ≥1 valid screening question answered (Q1–Q12)

&nbsp;   SELECT DISTINCT form\_submission\_id

&nbsp;   FROM responses\_in\_month

&nbsp;   WHERE question IN (

&nbsp;       -- Questions 1–8

&nbsp;       'What is your living situation today?', 

&nbsp;       'Think about the place you live. Do you have problems with any of the following?',

&nbsp;       'In the past 12 months has the electric, gas, oil, or water company threatened to shut off services in your home??', 

&nbsp;       'Within the past 12 months, you worried that your food would run out before you got money to buy more.',

&nbsp;       'Within the past 12 months, the food you bought just didn''t last and you didn''t have money to get more.',

&nbsp;       'In the past 12 months, has lack of reliable transportation kept you from medical appointments, meetings, work or from getting things needed for daily living?',

&nbsp;       'Do you want help finding or keeping work or a job?',

&nbsp;       'Do you want help with school or training? For example, starting or completing job training or getting a high school diploma, GED or equivalent',

&nbsp;       -- Questions 9–12

&nbsp;       'How often does anyone, including family and friends, physically hurt you??',

&nbsp;       'How often does anyone, including family and friends, insult or talk down to you?',

&nbsp;       'How often does anyone, including family and friends, threaten you with harm?',

&nbsp;       'How often does anyone, including family and friends, scream or curse at you??'

&nbsp;   )

&nbsp;     AND answer IS NOT NULL

&nbsp;     AND answer NOT IN ('Asked but Member declined to answer.','Decline to answer','Screener did not ask Member.')

),



-- Map CIN from the same HRSN submission so we can join to ESMF eligibility

cin\_map AS (

&nbsp;   SELECT DISTINCT

&nbsp;       form\_submission\_id,

&nbsp;       seeker\_id,

&nbsp;       answer AS cin

&nbsp;   FROM responses\_in\_month

&nbsp;   WHERE question LIKE '%CIN%'            -- adjust to exact CIN question text if needed

&nbsp;     AND answer IS NOT NULL

),



-- Your requested CTE: ESMF eligibility flags

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



-- Final: count distinct CIN among consented + valid-screened + ESMF-eligible

SELECT 

&nbsp;   COUNT(DISTINCT cm.cin) AS completed\_screening\_count\_eligible

FROM consented\_members c

JOIN valid\_screening\_responses v

&nbsp; ON c.form\_submission\_id = v.form\_submission\_id

JOIN cin\_map cm

&nbsp; ON cm.form\_submission\_id = c.form\_submission\_id

JOIN eligible\_flags ef

&nbsp; ON ef.mbrID = cm.cin;















## -----7--------------# of Medicaid Members Screened indicating an unmet need







--=============================================================================================================================================================================================================================

--Data Entry Point 6 --Count of unique Medicaid Members with one or more Completed Screenings indicating a confirmed unmet HRSN (within the past 12 months):

--=============================================================================================================================================================================================================================

WITH base\_responses AS (                    ---cte for FILTERING HRSN

&nbsp;	SELECT 

&nbsp;		form\_submission\_id,

&nbsp;		seeker\_id,

&nbsp;		question,

&nbsp;		answer,

&nbsp;		started\_at

&nbsp;	FROM FH\_flipa\_mbr\_insights\_forms

&nbsp;	WHERE form\_name LIKE '%HRSN%'

),



responses\_in\_range AS (											--- CTE to filter the date for that specific month

&nbsp;	SELECT  \*

&nbsp;	FROM base\_responses

&nbsp;	WHERE started\_at >='2025-01-01'

&nbsp;	  AND started\_at < DATEADD(DAY, 1, CAST(GETDATE() AS date) ) 	

),

consented\_members AS (											--- CTE to filter consent members who said yes

&nbsp;	SELECT DISTINCT form\_submission\_id, seeker\_id

&nbsp;	FROM responses\_in\_range

&nbsp;	WHERE question like 'We use%'                ----consent question

&nbsp;	  AND answer  in ('Yes, I consent','Member agreed','Member consents')

),



cte\_unmet\_criteria AS (

&nbsp;	SELECT 'What is your living situation today?' AS question,'I have a place to live today, but I am worried about losing it in the future' AS answer

&nbsp;	UNION ALL SELECT 'What is your living situation today?' ,'I do not have a steady place to live (I am temporarily staying with others, in a hotel, in a shelter, living outside on the street, on a beach, in a car, abandoned building, bus or train station, or in a park)' 

&nbsp;	

&nbsp;	UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Pests such as bugs, ants, or mice' 

&nbsp;	UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' ,'Mold' 

&nbsp;	UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' ,'Lead paint or pipes' 

&nbsp;	UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Lack of heat' 

&nbsp;	UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' ,'Oven or stove not working' 

&nbsp;	UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' ,'Smoke detectors missing or not working' 

&nbsp;	UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' ,'Water leaks' 



&nbsp;	UNION ALL SELECT 'In the past 12 months has the electric, gas, oil, or water company threatened to shut off services in your home?' ,'Yes' 

&nbsp;	UNION ALL SELECT 'In the past 12 months has the electric, gas, oil, or water company threatened to shut off services in your home?' ,'Already Shut Off' 



&nbsp;	UNION ALL SELECT 'Within the past 12 months, you worried that your food would run out before you got money to buy more.' ,'Often true' 

&nbsp;	UNION ALL SELECT 'Within the past 12 months, you worried that your food would run out before you got money to buy more.' ,'Sometimes true' 



&nbsp;	UNION ALL SELECT 'Within the past 12 months, the food you bought just didn''t last and you didn''t have money to get more.' ,'Often true' 

&nbsp;	UNION ALL SELECT 'Within the past 12 months, the food you bought just didn''t last and you didn''t have money to get more.' ,'Sometimes true' 



&nbsp;	UNION ALL SELECT 'In the past 12 months, has lack of reliable transportation kept you from medical appointments, meetings, work or from getting things needed for daily living?' ,'Yes'

&nbsp;	

&nbsp;	UNION ALL SELECT 'Do you want help finding or keeping work or a job?' ,'Yes, help finding work' 

&nbsp;	UNION ALL SELECT 'Do you want help finding or keeping work or a job?' ,'Yes, help keeping work' 



&nbsp;	UNION ALL SELECT 'Do you want help with school or training? For example, starting or completing job training or getting a high school diploma, GED or equivalent' ,'Yes' 



&nbsp;	UNION ALL SELECT 'How often does anyone, including family and friends, physically hurt you?' ,'Rarely (2)' 

&nbsp;	UNION ALL SELECT 'How often does anyone, including family and friends, physically hurt you?' ,'Sometimes (3)' 

&nbsp;	UNION ALL SELECT 'How often does anyone, including family and friends, physically hurt you?' ,'Fairly Often (4)' 

&nbsp;	UNION ALL SELECT 'How often does anyone, including family and friends, physically hurt you?' ,'Frequently (5)' 



&nbsp;	UNION ALL SELECT 'How often does anyone, including family and friends, insult or talk down to you?' ,'Rarely (2)' 

&nbsp;	UNION ALL SELECT 'How often does anyone, including family and friends, insult or talk down to you?' ,'Sometimes (3)' 

&nbsp;	UNION ALL SELECT 'How often does anyone, including family and friends, insult or talk down to you?' ,'Fairly Often (4)' 

&nbsp;	UNION ALL SELECT 'How often does anyone, including family and friends, insult or talk down to you?' ,'Frequently (5)' 



&nbsp;	UNION ALL SELECT 'How often does anyone, including family and friends, threaten you with harm?' ,'Rarely (2)' 

&nbsp;	UNION ALL SELECT 'How often does anyone, including family and friends, threaten you with harm?' ,'Sometimes (3)' 

&nbsp;	UNION ALL SELECT 'How often does anyone, including family and friends, threaten you with harm?' ,'Fairly Often (4)' 

&nbsp;	UNION ALL SELECT 'How often does anyone, including family and friends, threaten you with harm?' ,'Frequently (5)' 



&nbsp;	UNION ALL SELECT 'How often does anyone, including family and friends, scream or curse at you??' ,'Rarely (2)' 

&nbsp;	UNION ALL SELECT 'How often does anyone, including family and friends, scream or curse at you??' ,'Sometimes (3)' 

&nbsp;	UNION ALL SELECT 'How often does anyone, including family and friends, scream or curse at you??' ,'Fairly Often (4)' 

&nbsp;	UNION ALL SELECT 'How often does anyone, including family and friends, scream or curse at you??' ,'Frequently (5)' 

),



valid\_unmet\_responses AS (

&nbsp;	SELECT DISTINCT r.form\_submission\_id, r.seeker\_id

&nbsp;	FROM responses\_in\_range r

&nbsp;	JOIN cte\_unmet\_criteria u

&nbsp;		ON r.question = u.question AND r.answer = u.answer

&nbsp;	where r.answer not IN ('Asked but Member declined to answer.','Decline to answer','Screener did not ask Member.')

&nbsp;	AND r.answer IS NOT NULL

)

SELECT COUNT(DISTINCT v.seeker\_id) as KPI\_7\_count

FROM valid\_unmet\_responses v

JOIN consented\_members c

&nbsp;	on v.form\_submission\_id = c.form\_submission\_id;





























## -----8------# of Enhanced Services Medicaid Members Screened indicating an unmet need







--=============================================================================================================================================================================================================================

-- Data Entry Point 6 — Completed Screenings indicating confirmed unmet HRSN (YTD) LIMITED TO ESMF-eligible members

--=============================================================================================================================================================================================================================

WITH base\_responses AS (                    -- HRSN only

&nbsp;   SELECT 

&nbsp;       form\_submission\_id,

&nbsp;       seeker\_id,

&nbsp;       question,

&nbsp;       answer,

&nbsp;       started\_at

&nbsp;   FROM FH\_flipa\_mbr\_insights\_forms

&nbsp;   WHERE form\_name LIKE '%HRSN%'

),



responses\_in\_range AS (                     -- YTD: 2025-01-01 .. today (inclusive)

&nbsp;   SELECT  \*

&nbsp;   FROM base\_responses

&nbsp;   WHERE started\_at >= '2025-01-01'

&nbsp;     AND started\_at <  DATEADD(DAY, 1, CAST(GETDATE() AS date)) 

),



consented\_members AS (                      -- consent = yes

&nbsp;   SELECT DISTINCT form\_submission\_id, seeker\_id

&nbsp;   FROM responses\_in\_range

&nbsp;   WHERE question LIKE 'We use%'           -- consent question

&nbsp;     AND answer  IN ('Yes, I consent','Member agreed','Member consents')

),



cte\_unmet\_criteria AS (                     -- answers indicating confirmed unmet HRSN

&nbsp;   SELECT 'What is your living situation today?' AS question,'I have a place to live today, but I am worried about losing it in the future' AS answer

&nbsp;   UNION ALL SELECT 'What is your living situation today?' ,'I do not have a steady place to live (I am temporarily staying with others, in a hotel, in a shelter, living outside on the street, on a beach, in a car, abandoned building, bus or train station, or in a park)' 

&nbsp;   

&nbsp;   UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Pests such as bugs, ants, or mice' 

&nbsp;   UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' ,'Mold' 

&nbsp;   UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' ,'Lead paint or pipes' 

&nbsp;   UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Lack of heat' 

&nbsp;   UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' ,'Oven or stove not working' 

&nbsp;   UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' ,'Smoke detectors missing or not working' 

&nbsp;   UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' ,'Water leaks' 



&nbsp;   UNION ALL SELECT 'In the past 12 months has the electric, gas, oil, or water company threatened to shut off services in your home?' ,'Yes' 

&nbsp;   UNION ALL SELECT 'In the past 12 months has the electric, gas, oil, or water company threatened to shut off services in your home?' ,'Already Shut Off' 



&nbsp;   UNION ALL SELECT 'Within the past 12 months, you worried that your food would run out before you got money to buy more.' ,'Often true' 

&nbsp;   UNION ALL SELECT 'Within the past 12 months, you worried that your food would run out before you got money to buy more.' ,'Sometimes true' 



&nbsp;   UNION ALL SELECT 'Within the past 12 months, the food you bought just didn''t last and you didn''t have money to get more.' ,'Often true' 

&nbsp;   UNION ALL SELECT 'Within the past 12 months, the food you bought just didn''t last and you didn''t have money to get more.' ,'Sometimes true' 



&nbsp;   UNION ALL SELECT 'In the past 12 months, has lack of reliable transportation kept you from medical appointments, meetings, work or from getting things needed for daily living?' ,'Yes'

&nbsp;   

&nbsp;   UNION ALL SELECT 'Do you want help finding or keeping work or a job?' ,'Yes, help finding work' 

&nbsp;   UNION ALL SELECT 'Do you want help finding or keeping work or a job?' ,'Yes, help keeping work' 



&nbsp;   UNION ALL SELECT 'Do you want help with school or training? For example, starting or completing job training or getting a high school diploma, GED or equivalent' ,'Yes' 



&nbsp;   UNION ALL SELECT 'How often does anyone, including family and friends, physically hurt you?' ,'Rarely (2)' 

&nbsp;   UNION ALL SELECT 'How often does anyone, including family and friends, physically hurt you?' ,'Sometimes (3)' 

&nbsp;   UNION ALL SELECT 'How often does anyone, including family and friends, physically hurt you?' ,'Fairly Often (4)' 

&nbsp;   UNION ALL SELECT 'How often does anyone, including family and friends, physically hurt you?' ,'Frequently (5)' 



&nbsp;   UNION ALL SELECT 'How often does anyone, including family and friends, insult or talk down to you?' ,'Rarely (2)' 

&nbsp;   UNION ALL SELECT 'How often does anyone, including family and friends, insult or talk down to you?' ,'Sometimes (3)' 

&nbsp;   UNION ALL SELECT 'How often does anyone, including family and friends, insult or talk down to you?' ,'Fairly Often (4)' 

&nbsp;   UNION ALL SELECT 'How often does anyone, including family and friends, insult or talk down to you?' ,'Frequently (5)' 



&nbsp;   UNION ALL SELECT 'How often does anyone, including family and friends, threaten you with harm?' ,'Rarely (2)' 

&nbsp;   UNION ALL SELECT 'How often does anyone, including family and friends, threaten you with harm?' ,'Sometimes (3)' 

&nbsp;   UNION ALL SELECT 'How often does anyone, including family and friends, threaten you with harm?' ,'Fairly Often (4)' 

&nbsp;   UNION ALL SELECT 'How often does anyone, including family and friends, threaten you with harm?' ,'Frequently (5)' 



&nbsp;   UNION ALL SELECT 'How often does anyone, including family and friends, scream or curse at you??' ,'Rarely (2)' 

&nbsp;   UNION ALL SELECT 'How often does anyone, including family and friends, scream or curse at you??' ,'Sometimes (3)' 

&nbsp;   UNION ALL SELECT 'How often does anyone, including family and friends, scream or curse at you??' ,'Fairly Often (4)' 

&nbsp;   UNION ALL SELECT 'How often does anyone, including family and friends, scream or curse at you??' ,'Frequently (5)' 

),



valid\_unmet\_responses AS (

&nbsp;   SELECT DISTINCT r.form\_submission\_id, r.seeker\_id

&nbsp;   FROM responses\_in\_range r

&nbsp;   JOIN cte\_unmet\_criteria u

&nbsp;     ON r.question = u.question AND r.answer = u.answer

&nbsp;   WHERE r.answer NOT IN ('Asked but Member declined to answer.','Decline to answer','Screener did not ask Member.')

&nbsp;     AND r.answer IS NOT NULL

),



-- pull CIN from the same HRSN submission to join to ESMF

cin\_map AS (

&nbsp;   SELECT DISTINCT

&nbsp;       form\_submission\_id,

&nbsp;       seeker\_id,

&nbsp;       answer AS cin

&nbsp;   FROM responses\_in\_range

&nbsp;   WHERE question LIKE '%CIN%'        -- adjust to exact CIN question text if needed

&nbsp;     AND answer IS NOT NULL

),



-- your requested CTE: ESMF eligibility flags (by CIN)

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



-- Final: count distinct CIN meeting ALL conditions: consent + unmet HRSN + ESMF-eligible

SELECT 

&nbsp;   COUNT(DISTINCT cm.cin) AS KPI\_7\_count

FROM valid\_unmet\_responses v

JOIN consented\_members c

&nbsp; ON v.form\_submission\_id = c.form\_submission\_id

JOIN cin\_map cm

&nbsp; ON cm.form\_submission\_id = v.form\_submission\_id

JOIN eligible\_flags ef

&nbsp; ON ef.mbrID = cm.cin;































## --9---------# of Medicaid Members who decline to consent to screen





WITH base\_responses AS (

&nbsp;	SELECT 

&nbsp;		seeker\_id,

&nbsp;		question,

&nbsp;		answer,

&nbsp;		started\_at

&nbsp;	FROM FH\_flipa\_mbr\_insights\_forms

&nbsp;	WHERE form\_name LIKE '%HRSN%'	

)



SELECT COUNT (DISTINCT seeker\_id) as declined\_consent\_member\_count

FROM base\_responses

WHERE  question like 'We use%'

&nbsp;	AND answer  in (

&nbsp;		'I do not consent. (Please select submit form at bottom of page)',

&nbsp;		'Member does not consent. (Please select submit form at bottom of page)'

&nbsp;	 ) 

&nbsp;	AND started\_at >= '2025-01-01'

&nbsp;	AND started\_at< DATEADD(DAY, 1, CAST(GETDATE() AS date)) 



&nbsp;	AND seeker\_id is not null;





























































## -------10----------# of Enhanced Services Medicaid Members who decline to consent to screen







WITH base\_responses AS (

&nbsp;   SELECT 

&nbsp;       seeker\_id,

&nbsp;       question,

&nbsp;       answer,

&nbsp;       started\_at,

&nbsp;       form\_submission\_id

&nbsp;   FROM FH\_flipa\_mbr\_insights\_forms

&nbsp;   WHERE form\_name LIKE '%HRSN%'

),

responses\_ytd AS (

&nbsp;   SELECT \*

&nbsp;   FROM base\_responses

&nbsp;   WHERE started\_at >= '2025-01-01'

&nbsp;     AND started\_at <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

),



-- members who declined consent

declined\_consent AS (

&nbsp;   SELECT DISTINCT form\_submission\_id, seeker\_id

&nbsp;   FROM responses\_ytd

&nbsp;   WHERE question LIKE 'We use%'

&nbsp;     AND answer IN (

&nbsp;           'I do not consent. (Please select submit form at bottom of page)',

&nbsp;           'Member does not consent. (Please select submit form at bottom of page)'

&nbsp;     )

&nbsp;     AND seeker\_id IS NOT NULL

),



-- pull CIN from the same HRSN submission to join to ESMF

cin\_map AS (

&nbsp;   SELECT DISTINCT

&nbsp;       form\_submission\_id,

&nbsp;       seeker\_id,

&nbsp;       answer AS cin

&nbsp;   FROM responses\_ytd

&nbsp;   WHERE question LIKE '%CIN%'         -- adjust to exact CIN question text if needed

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

&nbsp;      OR \[EPOPIDD]           = 'Y'  

)



-- FINAL: declined consent among ESMF-eligible (count distinct CIN)

SELECT COUNT(DISTINCT cm.cin) AS declined\_consent\_member\_count\_eligible

FROM declined\_consent d

JOIN cin\_map cm

&nbsp; ON cm.form\_submission\_id = d.form\_submission\_id

JOIN eligible\_flags ef

&nbsp; ON ef.mbrID = cm.cin;

































## --18--% members with screens indicating a housing need



DECLARE @total\_completed INT;

DECLARE @housing\_need INT;



-- ===== A) TOTAL COMPLETED SCREENS  =====

;WITH base\_responses AS (

    SELECT seeker\_id, question, answer, form\_name, started\_at, form\_submission\_id

    FROM FH\_flipa\_mbr\_insights\_forms

    WHERE form\_name LIKE '%HRSN%'

),

responses\_in\_month AS (

    SELECT \*

    FROM base\_responses

    WHERE started\_at >= '2025-01-01'

      AND started\_at <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

),

consented\_members AS (

    SELECT DISTINCT form\_submission\_id, seeker\_id

    FROM responses\_in\_month

    WHERE question LIKE 'We use%'

      AND answer IN ('Yes, I consent','Member agreed','Member consents')

),

valid\_screening\_responses AS (

    SELECT DISTINCT form\_submission\_id

    FROM responses\_in\_month

    WHERE question IN (

        'What is your living situation today?',

        'Think about the place you live. Do you have problems with any of the following?',

        'In the past 12 months has the electric, gas, oil, or water company threatened to shut off services in your home??',

        'Within the past 12 months, you worried that your food would run out before you got money to buy more.',

        'Within the past 12 months, the food you bought just didn''t last and you didn''t have money to get more.',

        'In the past 12 months, has lack of reliable transportation kept you from medical appointments, meetings, work or from getting things needed for daily living?',

        'Do you want help finding or keeping work or a job?',

        'Do you want help with school or training? For example, starting or completing job training or getting a high school diploma, GED or equivalent',

        'How often does anyone, including family and friends, physically hurt you??',

        'How often does anyone, including family and friends, insult or talk down to you?',

        'How often does anyone, including family and friends, threaten you with harm?',

        'How often does anyone, including family and friends, scream or curse at you??'

    )

      AND answer IS NOT NULL

      AND answer NOT IN ('Asked but Member declined to answer.','Decline to answer','Screener did not ask Member.')

)

SELECT @total\_completed = COUNT(DISTINCT c.seeker\_id)

FROM consented\_members c

JOIN valid\_screening\_responses v

  ON c.form\_submission\_id = v.form\_submission\_id;



-- ===== B) HOUSING NEED  =====

;WITH base\_responses AS (

    SELECT seeker\_id, form\_submission\_id, question, answer, started\_at

    FROM FH\_flipa\_mbr\_insights\_forms

    WHERE form\_name LIKE '%HRSN%'

      AND seeker\_id IS NOT NULL

),

responses\_ytd AS (

    SELECT \*

    FROM base\_responses

    WHERE started\_at >= '2025-01-01'

      AND started\_at <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

),

cte\_housing\_need AS (

    SELECT 'What is your living situation today?' AS question,

           'I have a place to live today, but I am worried about losing it in the future' AS answer

    UNION ALL SELECT 'What is your living situation today?',

                     'I do not have a steady place to live (I am temporarily staying with others, in a hotel, in a shelter, living outside on the street, on a beach, in a car, abandoned building, bus or train station, or in a park)'

    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?', 'Pests such as bugs, ants, or mice'

    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?', 'Mold'

    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?', 'Lead paint or pipes'

    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?', 'Lack of heat'

    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?', 'Oven or stove not working'

    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?', 'Smoke detectors missing or not working'

    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?', 'Water leaks'

),

housing\_hits AS (

    SELECT DISTINCT r.seeker\_id, r.form\_submission\_id

    FROM responses\_ytd r

    JOIN cte\_housing\_need h

      ON r.question = h.question AND r.answer = h.answer

    WHERE r.answer IS NOT NULL

      AND r.answer NOT IN ('Asked but Member declined to answer.','Decline to answer','Screener did not ask Member.')

),

consented AS (

    SELECT DISTINCT form\_submission\_id, seeker\_id

    FROM responses\_ytd

    WHERE (question LIKE 'We use%' AND answer IN ('YES Member consents','Yes, I consent','Member agreed','Member consents'))

       OR (question LIKE 'Confirm consent with Member to move%' AND answer IN ('Member consents','Yes, I consent','Member agreed'))

)

SELECT @housing\_need = COUNT(DISTINCT h.seeker\_id)

FROM housing\_hits h

JOIN consented c

  ON c.form\_submission\_id = h.form\_submission\_id;



-- ===== C) FINAL % =====

SELECT

    @total\_completed AS total\_completed\_screens\_YTD,

    @housing\_need    AS members\_with\_housing\_need\_YTD,

    CAST(100.0 \* @housing\_need / NULLIF(@total\_completed, 0) AS DECIMAL(5,2)) AS pct\_housing\_need\_of\_completed\_YTD;





































## --19--% members with screens indicating utility need--









-- Compute % of members with screens indicating a UTILITY need (YTD)

-- Uses your existing TOTAL query block unchanged, then a separate UTILITY block, then divides.



DECLARE @total\_completed INT;

DECLARE @utility\_need INT;



-- ===== A) TOTAL COMPLETED SCREENS (your existing logic) =====

;WITH base\_responses AS (

    SELECT seeker\_id, question, answer, form\_name, started\_at, form\_submission\_id

    FROM FH\_flipa\_mbr\_insights\_forms

    WHERE form\_name LIKE '%HRSN%'

),

responses\_in\_month AS (

    SELECT \*

    FROM base\_responses

    WHERE started\_at >= '2025-01-01'

      AND started\_at <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

),

consented\_members AS (

    SELECT DISTINCT form\_submission\_id, seeker\_id

    FROM responses\_in\_month

    WHERE question LIKE 'We use%'

      AND answer IN ('Yes, I consent','Member agreed','Member consents')

),

valid\_screening\_responses AS (

    SELECT DISTINCT form\_submission\_id

    FROM responses\_in\_month

    WHERE question IN (

        'What is your living situation today?',

        'Think about the place you live. Do you have problems with any of the following?',

        'In the past 12 months has the electric, gas, oil, or water company threatened to shut off services in your home??',

        'Within the past 12 months, you worried that your food would run out before you got money to buy more.',

        'Within the past 12 months, the food you bought just didn''t last and you didn''t have money to get more.',

        'In the past 12 months, has lack of reliable transportation kept you from medical appointments, meetings, work or from getting things needed for daily living?',

        'Do you want help finding or keeping work or a job?',

        'Do you want help with school or training? For example, starting or completing job training or getting a high school diploma, GED or equivalent',

        'How often does anyone, including family and friends, physically hurt you??',

        'How often does anyone, including family and friends, insult or talk down to you?',

        'How often does anyone, including family and friends, threaten you with harm?',

        'How often does anyone, including family and friends, scream or curse at you??'

    )

      AND answer IS NOT NULL

      AND answer NOT IN ('Asked but Member declined to answer.','Decline to answer','Screener did not ask Member.')

)

SELECT @total\_completed = COUNT(DISTINCT c.seeker\_id)

FROM consented\_members c

JOIN valid\_screening\_responses v

  ON c.form\_submission\_id = v.form\_submission\_id;



-- ===== B) UTILITY NEED (consented + utility-need answers; YTD) =====

;WITH base\_responses AS (

    SELECT seeker\_id, form\_submission\_id, question, answer, started\_at

    FROM FH\_flipa\_mbr\_insights\_forms

    WHERE form\_name LIKE '%HRSN%'

      AND seeker\_id IS NOT NULL

),

responses\_ytd AS (

    SELECT \*

    FROM base\_responses

    WHERE started\_at >= '2025-01-01'

      AND started\_at <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

),

-- utility need answers (use LIKE to ignore punctuation differences)

utility\_hits AS (

    SELECT DISTINCT seeker\_id, form\_submission\_id

    FROM responses\_ytd

    WHERE question LIKE 'In the past 12 months has the electric, gas, oil, or water company threatened to shut off services in your home%'

      AND answer IN ('Yes','Already Shut Off')

),

consented AS (

    SELECT DISTINCT form\_submission\_id, seeker\_id

    FROM responses\_ytd

    WHERE (question LIKE 'We use%' AND answer IN ('YES Member consents','Yes, I consent','Member agreed','Member consents'))

       OR (question LIKE 'Confirm consent with Member to move%' AND answer IN ('Member consents','Yes, I consent','Member agreed'))

)

SELECT @utility\_need = COUNT(DISTINCT u.seeker\_id)

FROM utility\_hits u

JOIN consented c

  ON c.form\_submission\_id = u.form\_submission\_id;



-- ===== C) FINAL % =====

SELECT

    @total\_completed AS total\_completed\_screens\_YTD,

    @utility\_need    AS members\_with\_utility\_need\_YTD,

    CAST(100.0 \* @utility\_need / NULLIF(@total\_completed, 0) AS DECIMAL(5,2)) AS pct\_utility\_need\_of\_completed\_YTD;



































## 

## --20---% members with screens indicating food/nutrition need--





-- Compute % of members with screens indicating a FOOD/NUTRITION need (YTD)

-- Uses your existing TOTAL query block unchanged, then a separate FOOD block, then divides.



DECLARE @total\_completed INT;

DECLARE @food\_need INT;



-- ===== A) TOTAL COMPLETED SCREENS (your existing logic) =====

;WITH base\_responses AS (

    SELECT seeker\_id, question, answer, form\_name, started\_at, form\_submission\_id

    FROM FH\_flipa\_mbr\_insights\_forms

    WHERE form\_name LIKE '%HRSN%'

),

responses\_in\_month AS (

    SELECT \*

    FROM base\_responses

    WHERE started\_at >= '2025-01-01'

      AND started\_at <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

),

consented\_members AS (

    SELECT DISTINCT form\_submission\_id, seeker\_id

    FROM responses\_in\_month

    WHERE question LIKE 'We use%'

      AND answer IN ('Yes, I consent','Member agreed','Member consents')

),

valid\_screening\_responses AS (

    SELECT DISTINCT form\_submission\_id

    FROM responses\_in\_month

    WHERE question IN (

        'What is your living situation today?',

        'Think about the place you live. Do you have problems with any of the following?',

        'In the past 12 months has the electric, gas, oil, or water company threatened to shut off services in your home??',

        'Within the past 12 months, you worried that your food would run out before you got money to buy more.',

        'Within the past 12 months, the food you bought just didn''t last and you didn''t have money to get more.',

        'In the past 12 months, has lack of reliable transportation kept you from medical appointments, meetings, work or from getting things needed for daily living?',

        'Do you want help finding or keeping work or a job?',

        'Do you want help with school or training? For example, starting or completing job training or getting a high school diploma, GED or equivalent',

        'How often does anyone, including family and friends, physically hurt you??',

        'How often does anyone, including family and friends, insult or talk down to you?',

        'How often does anyone, including family and friends, threaten you with harm?',

        'How often does anyone, including family and friends, scream or curse at you??'

    )

      AND answer IS NOT NULL

      AND answer NOT IN ('Asked but Member declined to answer.','Decline to answer','Screener did not ask Member.')

)

SELECT @total\_completed = COUNT(DISTINCT c.seeker\_id)

FROM consented\_members c

JOIN valid\_screening\_responses v

  ON c.form\_submission\_id = v.form\_submission\_id;



-- ===== B) FOOD/NUTRITION NEED (consented + food-need answers; YTD) =====

;WITH base\_responses AS (

    SELECT seeker\_id, form\_submission\_id, question, answer, started\_at

    FROM FH\_flipa\_mbr\_insights\_forms

    WHERE form\_name LIKE '%HRSN%'

      AND seeker\_id IS NOT NULL

),

responses\_ytd AS (

    SELECT \*

    FROM base\_responses

    WHERE started\_at >= '2025-01-01'

      AND started\_at <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

),

food\_need\_hits AS (

    SELECT DISTINCT seeker\_id, form\_submission\_id

    FROM responses\_ytd

    WHERE

      (

        -- Q1: worried food would run out

        question LIKE 'Within the past 12 months, you worried that your food would run out before you got money to buy more%'

        AND answer IN ('Often true','Sometimes true')

      )

      OR

      (

        -- Q2: food didn''t last and no money

        question LIKE 'Within the past 12 months, the food you bought just didn''t last and you didn''t have money to get more%'

        AND answer IN ('Often true','Sometimes true')

      )

),

consented AS (

    SELECT DISTINCT form\_submission\_id, seeker\_id

    FROM responses\_ytd

    WHERE (question LIKE 'We use%' AND answer IN ('YES Member consents','Yes, I consent','Member agreed','Member consents'))

       OR (question LIKE 'Confirm consent with Member to move%' AND answer IN ('Member consents','Yes, I consent','Member agreed'))

)

SELECT @food\_need = COUNT(DISTINCT f.seeker\_id)

FROM food\_need\_hits f

JOIN consented c

  ON c.form\_submission\_id = f.form\_submission\_id;



-- ===== C) FINAL % =====

SELECT

    @total\_completed AS total\_completed\_screens\_YTD,

    @food\_need       AS members\_with\_food\_need\_YTD,

    CAST(100.0 \* @food\_need / NULLIF(@total\_completed, 0) AS DECIMAL(5,2)) AS pct\_food\_need\_of\_completed\_YTD;





































## --21--% of members with screens indicating transportation need







-- % of members with screens indicating a TRANSPORTATION need (YTD)

-- Same structure as your Utility/Food queries: run TOTAL first, then TRANSPORTATION, then divide.



DECLARE @total\_completed INT;

DECLARE @transport\_need INT;



-- ===== A) TOTAL COMPLETED SCREENS (your existing logic) =====

;WITH base\_responses AS (

    SELECT seeker\_id, question, answer, form\_name, started\_at, form\_submission\_id

    FROM FH\_flipa\_mbr\_insights\_forms

    WHERE form\_name LIKE '%HRSN%'

),

responses\_in\_month AS (

    SELECT \*

    FROM base\_responses

    WHERE started\_at >= '2025-01-01'

      AND started\_at <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

),

consented\_members AS (

    SELECT DISTINCT form\_submission\_id, seeker\_id

    FROM responses\_in\_month

    WHERE question LIKE 'We use%'

      AND answer IN ('Yes, I consent','Member agreed','Member consents')

),

valid\_screening\_responses AS (

    SELECT DISTINCT form\_submission\_id

    FROM responses\_in\_month

    WHERE question IN (

        'What is your living situation today?',

        'Think about the place you live. Do you have problems with any of the following?',

        'In the past 12 months has the electric, gas, oil, or water company threatened to shut off services in your home??',

        'Within the past 12 months, you worried that your food would run out before you got money to buy more.',

        'Within the past 12 months, the food you bought just didn''t last and you didn''t have money to get more.',

        'In the past 12 months, has lack of reliable transportation kept you from medical appointments, meetings, work or from getting things needed for daily living?',

        'Do you want help finding or keeping work or a job?',

        'Do you want help with school or training? For example, starting or completing job training or getting a high school diploma, GED or equivalent',

        'How often does anyone, including family and friends, physically hurt you??',

        'How often does anyone, including family and friends, insult or talk down to you?',

        'How often does anyone, including family and friends, threaten you with harm?',

        'How often does anyone, including family and friends, scream or curse at you??'

    )

      AND answer IS NOT NULL

      AND answer NOT IN ('Asked but Member declined to answer.','Decline to answer','Screener did not ask Member.')

)

SELECT @total\_completed = COUNT(DISTINCT c.seeker\_id)

FROM consented\_members c

JOIN valid\_screening\_responses v

  ON c.form\_submission\_id = v.form\_submission\_id;



-- ===== B) TRANSPORTATION NEED (consented + transportation-need answers; YTD) =====

;WITH base\_responses AS (

    SELECT seeker\_id, form\_submission\_id, question, answer, started\_at

    FROM FH\_flipa\_mbr\_insights\_forms

    WHERE form\_name LIKE '%HRSN%'

      AND seeker\_id IS NOT NULL

),

responses\_ytd AS (

    SELECT \*

    FROM base\_responses

    WHERE started\_at >= '2025-01-01'

      AND started\_at <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

),

transport\_need\_hits AS (

    SELECT DISTINCT seeker\_id, form\_submission\_id

    FROM responses\_ytd

    WHERE (

            question LIKE 'In the past 12 months, has lack of reliable transportation kept you from medical appointments, meetings, work or from getting things needed for daily living%'

 

          )

      AND answer = 'Yes'

),

consented AS (

    SELECT DISTINCT form\_submission\_id, seeker\_id

    FROM responses\_ytd

    WHERE (question LIKE 'We use%' AND answer IN ('YES Member consents','Yes, I consent','Member agreed','Member consents'))

       OR (question LIKE 'Confirm consent with Member to move%' AND answer IN ('Member consents','Yes, I consent','Member agreed'))

)

SELECT @transport\_need = COUNT(DISTINCT t.seeker\_id)

FROM transport\_need\_hits t

JOIN consented c

  ON c.form\_submission\_id = t.form\_submission\_id;



-- ===== C) FINAL % =====

SELECT

    @total\_completed  AS total\_completed\_screens\_YTD,

    @transport\_need   AS members\_with\_transportation\_need\_YTD,

    CAST(100.0 \* @transport\_need / NULLIF(@total\_completed, 0) AS DECIMAL(5,2)) AS pct\_transportation\_need\_of\_completed\_YTD;











































## --22--% of members with screens indicating career \& education need







-- % of members with screens indicating a CAREER \& EDUCATION need (YTD)

-- Same structure as your Utility/Food/Transportation queries:

--  A) compute TOTAL completed screens  B) compute CAREER+EDU need  C) divide.



DECLARE @total\_completed INT;

DECLARE @career\_edu\_need INT;



-- ===== A) TOTAL COMPLETED SCREENS (your existing logic) =====

;WITH base\_responses AS (

    SELECT seeker\_id, question, answer, form\_name, started\_at, form\_submission\_id

    FROM FH\_flipa\_mbr\_insights\_forms

    WHERE form\_name LIKE '%HRSN%'

),

responses\_in\_month AS (

    SELECT \*

    FROM base\_responses

    WHERE started\_at >= '2025-01-01'

      AND started\_at <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

),

consented\_members AS (

    SELECT DISTINCT form\_submission\_id, seeker\_id

    FROM responses\_in\_month

    WHERE question LIKE 'We use%'

      AND answer IN ('Yes, I consent','Member agreed','Member consents')

),

valid\_screening\_responses AS (

    SELECT DISTINCT form\_submission\_id

    FROM responses\_in\_month

    WHERE question IN (

        'What is your living situation today?',

        'Think about the place you live. Do you have problems with any of the following?',

        'In the past 12 months has the electric, gas, oil, or water company threatened to shut off services in your home??',

        'Within the past 12 months, you worried that your food would run out before you got money to buy more.',

        'Within the past 12 months, the food you bought just didn''t last and you didn''t have money to get more.',

        'In the past 12 months, has lack of reliable transportation kept you from medical appointments, meetings, work or from getting things needed for daily living?',

        'Do you want help finding or keeping work or a job?',

        'Do you want help with school or training? For example, starting or completing job training or getting a high school diploma, GED or equivalent',

        'How often does anyone, including family and friends, physically hurt you??',

        'How often does anyone, including family and friends, insult or talk down to you?',

        'How often does anyone, including family and friends, threaten you with harm?',

        'How often does anyone, including family and friends, scream or curse at you??'

    )

      AND answer IS NOT NULL

      AND answer NOT IN ('Asked but Member declined to answer.','Decline to answer','Screener did not ask Member.')

)

SELECT @total\_completed = COUNT(DISTINCT c.seeker\_id)

FROM consented\_members c

JOIN valid\_screening\_responses v

  ON c.form\_submission\_id = v.form\_submission\_id;



-- ===== B) CAREER \& EDUCATION NEED (consented + need answers; YTD) =====

;WITH base\_responses AS (

    SELECT seeker\_id, form\_submission\_id, question, answer, started\_at

    FROM FH\_flipa\_mbr\_insights\_forms

    WHERE form\_name LIKE '%HRSN%'

      AND seeker\_id IS NOT NULL

),

responses\_ytd AS (

    SELECT \*

    FROM base\_responses

    WHERE started\_at >= '2025-01-01'

      AND started\_at <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

),

career\_edu\_hits AS (

    SELECT DISTINCT seeker\_id, form\_submission\_id

    FROM responses\_ytd

    WHERE

      (

        -- Career: wants help with work

        question LIKE 'Do you want help finding or keeping work or a job%'

        AND answer IN ('Yes, help finding work','Yes, help keeping work')

      )

      OR

      (

        -- Education: wants help with school/training

        question LIKE 'Do you want help with school or training%getting a high school diploma, GED or equivalent%'

        AND answer = 'Yes'

      )

),

consented AS (

    SELECT DISTINCT form\_submission\_id, seeker\_id

    FROM responses\_ytd

    WHERE (question LIKE 'We use%' AND answer IN ('YES Member consents','Yes, I consent','Member agreed','Member consents'))

       OR (question LIKE 'Confirm consent with Member to move%' AND answer IN ('Member consents','Yes, I consent','Member agreed'))

)

SELECT @career\_edu\_need = COUNT(DISTINCT h.seeker\_id)

FROM career\_edu\_hits h

JOIN consented c

  ON c.form\_submission\_id = h.form\_submission\_id;



-- ===== C) FINAL % =====

SELECT

    @total\_completed   AS total\_completed\_screens\_YTD,

    @career\_edu\_need   AS members\_with\_career\_education\_need\_YTD,

    CAST(100.0 \* @career\_edu\_need / NULLIF(@total\_completed, 0) AS DECIMAL(5,2)) AS pct\_career\_education\_need\_of\_completed\_YTD;









































## --23--% of members with screens indicating a safety need



-- % of members with screens indicating a SAFETY need (YTD)

-- Same structure as your other need metrics:

--   A) TOTAL completed screens

--   B) SAFETY need (any of the 4 safety items answered Rarely/Sometimes/Fairly Often/Frequently)

--   C) Divide



DECLARE @total\_completed INT;

DECLARE @safety\_need INT;



-- ===== A) TOTAL COMPLETED SCREENS (your existing logic) =====

;WITH base\_responses AS (

    SELECT seeker\_id, question, answer, form\_name, started\_at, form\_submission\_id

    FROM FH\_flipa\_mbr\_insights\_forms

    WHERE form\_name LIKE '%HRSN%'

),

responses\_in\_month AS (

    SELECT \*

    FROM base\_responses

    WHERE started\_at >= '2025-01-01'

      AND started\_at <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

),

consented\_members AS (

    SELECT DISTINCT form\_submission\_id, seeker\_id

    FROM responses\_in\_month

    WHERE question LIKE 'We use%'

      AND answer IN ('Yes, I consent','Member agreed','Member consents')

),

valid\_screening\_responses AS (

    SELECT DISTINCT form\_submission\_id

    FROM responses\_in\_month

    WHERE question IN (

        'What is your living situation today?',

        'Think about the place you live. Do you have problems with any of the following?',

        'In the past 12 months has the electric, gas, oil, or water company threatened to shut off services in your home??',

        'Within the past 12 months, you worried that your food would run out before you got money to buy more.',

        'Within the past 12 months, the food you bought just didn''t last and you didn''t have money to get more.',

        'In the past 12 months, has lack of reliable transportation kept you from medical appointments, meetings, work or from getting things needed for daily living?',

        'Do you want help finding or keeping work or a job?',

        'Do you want help with school or training? For example, starting or completing job training or getting a high school diploma, GED or equivalent',

        'How often does anyone, including family and friends, physically hurt you??',

        'How often does anyone, including family and friends, insult or talk down to you?',

        'How often does anyone, including family and friends, threaten you with harm?',

        'How often does anyone, including family and friends, scream or curse at you??'

    )

      AND answer IS NOT NULL

      AND answer NOT IN ('Asked but Member declined to answer.','Decline to answer','Screener did not ask Member.')

)

SELECT @total\_completed = COUNT(DISTINCT c.seeker\_id)

FROM consented\_members c

JOIN valid\_screening\_responses v

  ON c.form\_submission\_id = v.form\_submission\_id;



-- ===== B) SAFETY NEED (consented + safety-need answers; YTD) =====

;WITH base\_responses AS (

    SELECT seeker\_id, form\_submission\_id, question, answer, started\_at

    FROM FH\_flipa\_mbr\_insights\_forms

    WHERE form\_name LIKE '%HRSN%'

      AND seeker\_id IS NOT NULL

),

responses\_ytd AS (

    SELECT \*

    FROM base\_responses

    WHERE started\_at >= '2025-01-01'

      AND started\_at <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

),

safety\_hits AS (

    SELECT DISTINCT seeker\_id, form\_submission\_id

    FROM responses\_ytd

    WHERE

      (

        -- any of the 4 interpersonal safety questions

        question LIKE 'How often does anyone, including family and friends, physically hurt you%'

        OR question LIKE 'How often does anyone, including family and friends, insult or talk down to you%'

        OR question LIKE 'How often does anyone, including family and friends, threaten you with harm%'

        OR question LIKE 'How often does anyone, including family and friends, scream or curse at you%'

      )

      -- responses that indicate a safety concern

      AND answer IN ('Rarely (2)','Sometimes (3)','Fairly Often (4)','Frequently (5)')

),

consented AS (

    SELECT DISTINCT form\_submission\_id, seeker\_id

    FROM responses\_ytd

    WHERE (question LIKE 'We use%' AND answer IN ('YES Member consents','Yes, I consent','Member agreed','Member consents'))

       OR (question LIKE 'Confirm consent with Member to move%' AND answer IN ('Member consents','Yes, I consent','Member agreed'))

)

SELECT @safety\_need = COUNT(DISTINCT s.seeker\_id)

FROM safety\_hits s

JOIN consented c

  ON c.form\_submission\_id = s.form\_submission\_id;



-- ===== C) FINAL % =====

SELECT

    @total\_completed AS total\_completed\_screens\_YTD,

    @safety\_need     AS members\_with\_safety\_need\_YTD,

    CAST(100.0 \* @safety\_need / NULLIF(@total\_completed, 0) AS DECIMAL(5,2)) AS pct\_safety\_need\_of\_completed\_YTD;



































































## --24--% of screens indicating a physical ability need







-- % of members with screens indicating a PHYSICAL ABILITY need (YTD)

-- Definition: Either of these answered "Yes":

--   1) Do you have serious difficulty walking or climbing stairs? (5 years or older)

--   2) Do you have difficulty dressing or bathing? (5 years or older)



DECLARE @total\_completed INT;

DECLARE @phys\_ability\_need INT;



-- ===== A) TOTAL COMPLETED SCREENS (your same logic) =====

;WITH base\_responses AS (

    SELECT seeker\_id, question, answer, form\_name, started\_at, form\_submission\_id

    FROM FH\_flipa\_mbr\_insights\_forms

    WHERE form\_name LIKE '%HRSN%'

),

responses\_in\_month AS (

    SELECT \*

    FROM base\_responses

    WHERE started\_at >= '2025-01-01'

      AND started\_at <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

),

consented\_members AS (

    SELECT DISTINCT form\_submission\_id, seeker\_id

    FROM responses\_in\_month

    WHERE question LIKE 'We use%'

      AND answer IN ('Yes, I consent','Member agreed','Member consents')

),

valid\_screening\_responses AS (

    SELECT DISTINCT form\_submission\_id

    FROM responses\_in\_month

    WHERE question IN (

        'What is your living situation today?',

        'Think about the place you live. Do you have problems with any of the following?',

        'In the past 12 months has the electric, gas, oil, or water company threatened to shut off services in your home??',

        'Within the past 12 months, you worried that your food would run out before you got money to buy more.',

        'Within the past 12 months, the food you bought just didn''t last and you didn''t have money to get more.',

        'In the past 12 months, has lack of reliable transportation kept you from medical appointments, meetings, work or from getting things needed for daily living?',

        'Do you want help finding or keeping work or a job?',

        'Do you want help with school or training? For example, starting or completing job training or getting a high school diploma, GED or equivalent',

        'How often does anyone, including family and friends, physically hurt you??',

        'How often does anyone, including family and friends, insult or talk down to you?',

        'How often does anyone, including family and friends, threaten you with harm?',

        'How often does anyone, including family and friends, scream or curse at you??'

    )

      AND answer IS NOT NULL

      AND answer NOT IN ('Asked but Member declined to answer.','Decline to answer','Screener did not ask Member.')

)

SELECT @total\_completed = COUNT(DISTINCT c.seeker\_id)

FROM consented\_members c

JOIN valid\_screening\_responses v

  ON c.form\_submission\_id = v.form\_submission\_id;



-- ===== B) PHYSICAL ABILITY NEED (consented + need answers; YTD) =====

;WITH base\_responses AS (

    SELECT seeker\_id, form\_submission\_id, question, answer, started\_at

    FROM FH\_flipa\_mbr\_insights\_forms

    WHERE form\_name LIKE '%HRSN%'

      AND seeker\_id IS NOT NULL

),

responses\_ytd AS (

    SELECT \*

    FROM base\_responses

    WHERE started\_at >= '2025-01-01'

      AND started\_at <  DATEADD(DAY, 1, CAST(GETDATE() AS date))

),

phys\_ability\_hits AS (

    SELECT DISTINCT seeker\_id, form\_submission\_id

    FROM responses\_ytd

    WHERE (

            question LIKE 'Do you have serious difficulty walking or climbing stairs%5 years or older%'

            OR

            question LIKE 'Do you have difficulty dressing or bathing%5 years or older%'

          )

      AND answer = 'Yes'

),

consented AS (

    SELECT DISTINCT form\_submission\_id, seeker\_id

    FROM responses\_ytd

    WHERE (question LIKE 'We use%' AND answer IN ('YES Member consents','Yes, I consent','Member agreed','Member consents'))

       OR (question LIKE 'Confirm consent with Member to move%' AND answer IN ('Member consents','Yes, I consent','Member agreed'))

)

SELECT @phys\_ability\_need = COUNT(DISTINCT p.seeker\_id)

FROM phys\_ability\_hits p

JOIN consented c

  ON c.form\_submission\_id = p.form\_submission\_id;



-- ===== C) FINAL % =====

SELECT

    @total\_completed     AS total\_completed\_screens\_YTD,

    @phys\_ability\_need   AS members\_with\_physical\_ability\_need\_YTD,

    CAST(100.0 \* @phys\_ability\_need / NULLIF(@total\_completed, 0) AS DECIMAL(5,2)) AS pct\_physical\_ability\_need\_of\_completed\_YTD;











































