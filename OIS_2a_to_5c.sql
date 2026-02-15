-- Members Screened (#)- Data Entry Point 5--Count of unique medicaid members with a completed screening (within the Past month by giving consent to Data Sharing AND answering at least one valid screening question.

-- DOH weekly: cumulative since 2025-01-01 through the most-recent Friday
-- =======================================================================================================================
-- DOH requirements (V3): 
--   - Screening Qs: Q1–Q12
--   - Consent: ("Yes, I consent", "Member agreed", "Member consents")
--   - Exclude non-responses: 'Asked but Member declined to answer.', 'Decline to answer', 'Screener did not ask Member.', NULL
-- Cross-check idea: Metric_Completed = Initiated - DeclinedConsent (if you track those separately)

DECLARE @asof_date    date = CAST(GETDATE() AS date);  -- run date (today)
-- With DATEFIRST 7 (US default: Sunday=1,...,Friday=6,Saturday=7), this gives the most recent Friday (incl. today if Friday)
DECLARE @last_friday  date = DATEADD(day, -((DATEPART(weekday, @asof_date) + 1) % 7), @asof_date);

WITH base_responses AS (   -- Pull all HRSN form responses from insights table
    SELECT 
        seeker_id,
        question,
        answer,
        form_name,
        started_at,
        form_submission_id
    FROM FH_flipa_mbr_insights_forms
    WHERE form_name LIKE '%HRSN%'
),

responses_since_start AS ( -- CTE to filter cumulative window: 2025-01-01 .. last Friday (inclusive)
    SELECT *
    FROM base_responses
    WHERE started_at >= '2026-01-01'
      AND started_at < DATEADD(day, 1, @last_friday)   -- < next day to include full last Friday
),

consented_members AS (     -- Members who consented
    SELECT DISTINCT form_submission_id, seeker_id
    FROM responses_since_start
    WHERE question LIKE 'We use%'    -- your consent question stem
      AND answer IN ('Yes, I consent','Member agreed','Member consents')
),

valid_screening_responses AS (  -- At least one valid answer among the 12 screening questions
    SELECT DISTINCT form_submission_id
    FROM responses_since_start
    WHERE question IN (
        -- Q1–Q8
        'What is your living situation today?',
        'Think about the place you live. Do you have problems with any of the following?',
        'In the past 12 months has the electric, gas, oil, or water company threatened to shut off services in your home??',
        'Within the past 12 months, you worried that your food would run out before you got money to buy more.',
        'Within the past 12 months, the food you bought just didn''t last and you didn''t have money to get more.',
        'In the past 12 months, has lack of reliable transportation kept you from medical appointments, meetings, work or from getting things needed for daily living?',
        'Do you want help finding or keeping work or a job?',
        'Do you want help with school or training? For example, starting or completing job training or getting a high school diploma, GED or equivalent',
        -- Q9–Q12
        'How often does anyone, including family and friends, physically hurt you??',
        'How often does anyone, including family and friends, insult or talk down to you?',
        'How often does anyone, including family and friends, threaten you with harm?',
        'How often does anyone, including family and friends, scream or curse at you??'
    )
      AND answer IS NOT NULL
      AND answer NOT IN (
            'Asked but Member declined to answer.',
            'Decline to answer',
            'Screener did not ask Member.'
      )
)

SELECT COUNT(DISTINCT c.seeker_id) AS Members_Screened_On_Platform_2a, 
       @last_friday AS data_through_date
FROM consented_members c
JOIN valid_screening_responses v
  ON c.form_submission_id = v.form_submission_id;






-------------------------------------------------------


--Members that decline consent (#)


WITH base_responses AS (   -- Pull all HRSN form responses from insights table
    SELECT 
        seeker_id,
        question,
        answer,
        form_name,
        started_at,
        form_submission_id
    FROM FH_flipa_mbr_insights_forms
    WHERE form_name LIKE '%HRSN%'
      AND seeker_id IS NOT NULL
),

responses_since_start AS ( -- cumulative window: 2026-01-01 .. last Friday (inclusive)
    SELECT *
    FROM base_responses
    WHERE started_at >= '2026-01-01'
      AND started_at <  DATEADD(day, 1, @last_friday)
),

declined_members AS (      -- Members who DECLINED consent
    SELECT DISTINCT form_submission_id, seeker_id
    FROM responses_since_start
    WHERE question LIKE 'We use%'
      AND answer NOT IN (
          'Yes, I consent','Member agreed','Member consents'
      )
)

SELECT
    COUNT(DISTINCT seeker_id) AS Members_Declined_Consent_3,
    @last_friday AS data_through_date
FROM declined_members;




-------------------------------------------


/* =======================================================================================================================
  
   - Window: 2026-01-01 through last Friday
   - Metric 4a: Members Screened with Unmet Need(s)
   
   ======================================================================================================================= */

WITH
/* --------------------------
   Metric 2 build (unchanged logic, just 2026 window)
   -------------------------- */
base_responses AS (   -- cte for FILTERING HRSN
    SELECT 
        form_submission_id,
        seeker_id,
        question,
        answer,
        started_at
    FROM FH_flipa_mbr_insights_forms
    WHERE form_name LIKE '%HRSN%'
),
responses_since_start AS ( -- cumulative window 2026-01-01 .. last Friday (inclusive)
    SELECT *
    FROM base_responses
    WHERE started_at >= '2026-01-01'
      AND started_at < DATEADD(day, 1, @last_friday)
),
consented_members AS (     -- consent = yes
    SELECT DISTINCT form_submission_id, seeker_id
    FROM responses_since_start
    WHERE question LIKE 'We use%'
      AND answer IN ('Yes, I consent','Member agreed','Member consents')
),
cte_unmet_criteria AS (    -- answers that indicate confirmed unmet HRSN
    SELECT 'What is your living situation today?' AS question,'I have a place to live today, but I am worried about losing it in the future' AS answer
    UNION ALL SELECT 'What is your living situation today?' ,'I do not have a steady place to live (I am temporarily staying with others, in a hotel, in a shelter, living outside on the street, on a beach, in a car, abandoned building, bus or train station, or in a park)' 

    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Pests such as bugs, ants, or mice' 
    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Mold' 
    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Lead paint or pipes' 
    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Lack of heat' 
    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Oven or stove not working' 
    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Smoke detectors missing or not working' 
    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Water leaks' 

    UNION ALL SELECT 'In the past 12 months has the electric, gas, oil, or water company threatened to shut off services in your home?' , 'Yes' 
    UNION ALL SELECT 'In the past 12 months has the electric, gas, oil, or water company threatened to shut off services in your home?' , 'Already Shut Off' 

    UNION ALL SELECT 'Within the past 12 months, you worried that your food would run out before you got money to buy more.' , 'Often true' 
    UNION ALL SELECT 'Within the past 12 months, you worried that your food would run out before you got money to buy more.' , 'Sometimes true' 

    UNION ALL SELECT 'Within the past 12 months, the food you bought just didn''t last and you didn''t have money to get more.' , 'Often true' 
    UNION ALL SELECT 'Within the past 12 months, the food you bought just didn''t last and you didn''t have money to get more.' , 'Sometimes true' 

    UNION ALL SELECT 'In the past 12 months, has lack of reliable transportation kept you from medical appointments, meetings, work or from getting things needed for daily living?' , 'Yes'

    UNION ALL SELECT 'Do you want help finding or keeping work or a job?' , 'Yes, help finding work' 
    UNION ALL SELECT 'Do you want help finding or keeping work or a job?' , 'Yes, help keeping work' 

    UNION ALL SELECT 'Do you want help with school or training? For example, starting or completing job training or getting a high school diploma, GED or equivalent' , 'Yes' 

    UNION ALL SELECT 'How often does anyone, including family and friends, physically hurt you?' , 'Rarely (2)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, physically hurt you?' , 'Sometimes (3)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, physically hurt you?' , 'Fairly Often (4)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, physically hurt you?' , 'Frequently (5)' 

    UNION ALL SELECT 'How often does anyone, including family and friends, insult or talk down to you?' , 'Rarely (2)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, insult or talk down to you?' , 'Sometimes (3)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, insult or talk down to you?' , 'Fairly Often (4)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, insult or talk down to you?' , 'Frequently (5)' 

    UNION ALL SELECT 'How often does anyone, including family and friends, threaten you with harm?' , 'Rarely (2)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, threaten you with harm?' , 'Sometimes (3)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, threaten you with harm?' , 'Fairly Often (4)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, threaten you with harm?' , 'Frequently (5)' 

    UNION ALL SELECT 'How often does anyone, including family and friends, scream or curse at you??' , 'Rarely (2)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, scream or curse at you??' , 'Sometimes (3)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, scream or curse at you??' , 'Fairly Often (4)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, scream or curse at you??' , 'Frequently (5)' 
),
valid_unmet_responses AS (
    SELECT DISTINCT r.form_submission_id, r.seeker_id
    FROM responses_since_start r
    JOIN cte_unmet_criteria u
      ON r.question = u.question AND r.answer = u.answer
    WHERE r.answer NOT IN ('Asked but Member declined to answer.','Decline to answer','Screener did not ask Member.')
      AND r.answer IS NOT NULL
),
metric2_members AS (  
    SELECT DISTINCT v.seeker_id
    FROM valid_unmet_responses v
    JOIN consented_members c
      ON v.form_submission_id = c.form_submission_id
),

--/* --------------------------
--   Metric 3 build (eligibility consented) + join to metric2_members
--   -------------------------- */
--elig_base AS (
--    SELECT 
--        seeker_id,
--        question,
--        answer,
--        form_submission_id,
--        started_at
--    FROM FH_flipa_mbr_insights_forms
--    WHERE form_name LIKE '%eligibility%'
--      AND seeker_id IS NOT NULL
--),
--elig_responses_since_start AS (
--    SELECT *
--    FROM elig_base
--    WHERE started_at >= '2026-01-01'
--      AND started_at < DATEADD(day, 1, @last_friday)
--),
--elig_consented_members AS (
--    SELECT DISTINCT form_submission_id, seeker_id
--    FROM elig_responses_since_start
--    WHERE 
--        (
--            question LIKE 'We use%' 
--            AND answer  IN ('YES Member consents','Yes, I consent','Member agreed','Member consents')
--        )
--        OR
--        (
--            question LIKE 'Confirm consent with Member to move%' 
--            AND answer  IN ('Member consents','Yes, I consent','Member agreed')
--        )
--      AND answer NOT IN ('Asked but Member declined to answer.','Decline to answer','Screener did not ask Member.')
--      AND answer IS NOT NULL
--),

/* --------------------------
   Final counts 
   -------------------------- */
metric2_count AS (
    SELECT COUNT(DISTINCT seeker_id) AS Members_Screened_with_Unmet_Needs_4a
    FROM metric2_members

)

SELECT
    m2.Members_Screened_with_Unmet_Needs_4a,
   
    @last_friday AS data_through_date
FROM metric2_count m2
;



------------------------------------------------------------------------------



/* =======================================================================================================================
   
   - Metric 5a: Members Assessed (Eligibility consented) AND in Metric 2 population
 
   ======================================================================================================================= */

WITH
/* --------------------------
   Metric 2 build (unchanged logic, just 2026 window)
   -------------------------- */
base_responses AS (   -- cte for FILTERING HRSN
    SELECT 
        form_submission_id,
        seeker_id,
        question,
        answer,
        started_at
    FROM FH_flipa_mbr_insights_forms
    WHERE form_name LIKE '%HRSN%'
),
responses_since_start AS ( -- cumulative window 2026-01-01 .. last Friday (inclusive)
    SELECT *
    FROM base_responses
    WHERE started_at >= '2026-01-01'
      AND started_at < DATEADD(day, 1, @last_friday)
),
consented_members AS (     -- consent = yes
    SELECT DISTINCT form_submission_id, seeker_id
    FROM responses_since_start
    WHERE question LIKE 'We use%'
      AND answer IN ('Yes, I consent','Member agreed','Member consents')
),
cte_unmet_criteria AS (    -- answers that indicate confirmed unmet HRSN
    SELECT 'What is your living situation today?' AS question,'I have a place to live today, but I am worried about losing it in the future' AS answer
    UNION ALL SELECT 'What is your living situation today?' ,'I do not have a steady place to live (I am temporarily staying with others, in a hotel, in a shelter, living outside on the street, on a beach, in a car, abandoned building, bus or train station, or in a park)' 

    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Pests such as bugs, ants, or mice' 
    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Mold' 
    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Lead paint or pipes' 
    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Lack of heat' 
    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Oven or stove not working' 
    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Smoke detectors missing or not working' 
    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Water leaks' 

    UNION ALL SELECT 'In the past 12 months has the electric, gas, oil, or water company threatened to shut off services in your home?' , 'Yes' 
    UNION ALL SELECT 'In the past 12 months has the electric, gas, oil, or water company threatened to shut off services in your home?' , 'Already Shut Off' 

    UNION ALL SELECT 'Within the past 12 months, you worried that your food would run out before you got money to buy more.' , 'Often true' 
    UNION ALL SELECT 'Within the past 12 months, you worried that your food would run out before you got money to buy more.' , 'Sometimes true' 

    UNION ALL SELECT 'Within the past 12 months, the food you bought just didn''t last and you didn''t have money to get more.' , 'Often true' 
    UNION ALL SELECT 'Within the past 12 months, the food you bought just didn''t last and you didn''t have money to get more.' , 'Sometimes true' 

    UNION ALL SELECT 'In the past 12 months, has lack of reliable transportation kept you from medical appointments, meetings, work or from getting things needed for daily living?' , 'Yes'

    UNION ALL SELECT 'Do you want help finding or keeping work or a job?' , 'Yes, help finding work' 
    UNION ALL SELECT 'Do you want help finding or keeping work or a job?' , 'Yes, help keeping work' 

    UNION ALL SELECT 'Do you want help with school or training? For example, starting or completing job training or getting a high school diploma, GED or equivalent' , 'Yes' 

    UNION ALL SELECT 'How often does anyone, including family and friends, physically hurt you?' , 'Rarely (2)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, physically hurt you?' , 'Sometimes (3)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, physically hurt you?' , 'Fairly Often (4)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, physically hurt you?' , 'Frequently (5)' 

    UNION ALL SELECT 'How often does anyone, including family and friends, insult or talk down to you?' , 'Rarely (2)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, insult or talk down to you?' , 'Sometimes (3)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, insult or talk down to you?' , 'Fairly Often (4)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, insult or talk down to you?' , 'Frequently (5)' 

    UNION ALL SELECT 'How often does anyone, including family and friends, threaten you with harm?' , 'Rarely (2)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, threaten you with harm?' , 'Sometimes (3)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, threaten you with harm?' , 'Fairly Often (4)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, threaten you with harm?' , 'Frequently (5)' 

    UNION ALL SELECT 'How often does anyone, including family and friends, scream or curse at you??' , 'Rarely (2)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, scream or curse at you??' , 'Sometimes (3)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, scream or curse at you??' , 'Fairly Often (4)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, scream or curse at you??' , 'Frequently (5)' 
),
valid_unmet_responses AS (
    SELECT DISTINCT r.form_submission_id, r.seeker_id
    FROM responses_since_start r
    JOIN cte_unmet_criteria u
      ON r.question = u.question AND r.answer = u.answer
    WHERE r.answer NOT IN ('Asked but Member declined to answer.','Decline to answer','Screener did not ask Member.')
      AND r.answer IS NOT NULL
),
metric2_members AS (   -- <- "variable" to reuse in Metric 3
    SELECT DISTINCT v.seeker_id
    FROM valid_unmet_responses v
    JOIN consented_members c
      ON v.form_submission_id = c.form_submission_id
),

/* --------------------------
   Metric 3 build (eligibility consented) + join to metric2_members
   -------------------------- */
elig_base AS (
    SELECT 
        seeker_id,
        question,
        answer,
        form_submission_id,
        started_at
    FROM FH_flipa_mbr_insights_forms
    WHERE form_name LIKE '%eligibility%'
      AND seeker_id IS NOT NULL
),
elig_responses_since_start AS (
    SELECT *
    FROM elig_base
    WHERE started_at >= '2026-01-01'
      AND started_at < DATEADD(day, 1, @last_friday)
),
elig_consented_members AS (
    SELECT DISTINCT form_submission_id, seeker_id
    FROM elig_responses_since_start
    WHERE 
        (
            question LIKE 'We use%' 
            AND answer  IN ('YES Member consents','Yes, I consent','Member agreed','Member consents')
        )
        OR
        (
            question LIKE 'Confirm consent with Member to move%' 
            AND answer  IN ('Member consents','Yes, I consent','Member agreed')
        )
      AND answer NOT IN ('Asked but Member declined to answer.','Decline to answer','Screener did not ask Member.')
      AND answer IS NOT NULL
),

/* --------------------------
   Final counts 
   -------------------------- */
metric2_count AS (
    SELECT COUNT(DISTINCT seeker_id) AS Members_Screened_with_Unmet_Needs
    FROM metric2_members
),
metric3_count AS (
    SELECT COUNT(DISTINCT e.seeker_id) AS Members_Assessed_5a
    FROM elig_consented_members e
    JOIN metric2_members m2
      ON e.seeker_id = m2.seeker_id
)

SELECT
    m3.Members_Assessed_5a,
    @last_friday AS data_through_date
FROM metric3_count m3;



-------------------------------------------------




------------------Members for whom  Eligibility Assessment outreach was exhausted (#)
WITH
/* =========================================================
   A) Positive-need HRSN screen completed in CY2026
   ========================================================= */
hrsn_base_2026 AS (
    SELECT
        form_submission_id,
        seeker_id,
        question,
        answer,
        started_at
    FROM FH_flipa_mbr_insights_forms
    WHERE form_name LIKE '%HRSN%'
      AND seeker_id IS NOT NULL
      AND started_at >= '2026-01-01'
      AND started_at < DATEADD(day, 1, @last_friday)
),

hrsn_consented_2026 AS (
    SELECT DISTINCT form_submission_id, seeker_id
    FROM hrsn_base_2026
    WHERE question LIKE 'We use%'
      AND answer IN ('Yes, I consent','Member agreed','Member consents')
),

cte_unmet_criteria AS (
   SELECT 'What is your living situation today?' AS question,'I have a place to live today, but I am worried about losing it in the future' AS answer
    UNION ALL SELECT 'What is your living situation today?' ,'I do not have a steady place to live (I am temporarily staying with others, in a hotel, in a shelter, living outside on the street, on a beach, in a car, abandoned building, bus or train station, or in a park)' 

    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Pests such as bugs, ants, or mice' 
    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Mold' 
    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Lead paint or pipes' 
    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Lack of heat' 
    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Oven or stove not working' 
    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Smoke detectors missing or not working' 
    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Water leaks' 

    UNION ALL SELECT 'In the past 12 months has the electric, gas, oil, or water company threatened to shut off services in your home?' , 'Yes' 
    UNION ALL SELECT 'In the past 12 months has the electric, gas, oil, or water company threatened to shut off services in your home?' , 'Already Shut Off' 

    UNION ALL SELECT 'Within the past 12 months, you worried that your food would run out before you got money to buy more.' , 'Often true' 
    UNION ALL SELECT 'Within the past 12 months, you worried that your food would run out before you got money to buy more.' , 'Sometimes true' 

    UNION ALL SELECT 'Within the past 12 months, the food you bought just didn''t last and you didn''t have money to get more.' , 'Often true' 
    UNION ALL SELECT 'Within the past 12 months, the food you bought just didn''t last and you didn''t have money to get more.' , 'Sometimes true' 

    UNION ALL SELECT 'In the past 12 months, has lack of reliable transportation kept you from medical appointments, meetings, work or from getting things needed for daily living?' , 'Yes'

    UNION ALL SELECT 'Do you want help finding or keeping work or a job?' , 'Yes, help finding work' 
    UNION ALL SELECT 'Do you want help finding or keeping work or a job?' , 'Yes, help keeping work' 

    UNION ALL SELECT 'Do you want help with school or training? For example, starting or completing job training or getting a high school diploma, GED or equivalent' , 'Yes' 

    UNION ALL SELECT 'How often does anyone, including family and friends, physically hurt you?' , 'Rarely (2)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, physically hurt you?' , 'Sometimes (3)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, physically hurt you?' , 'Fairly Often (4)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, physically hurt you?' , 'Frequently (5)' 

    UNION ALL SELECT 'How often does anyone, including family and friends, insult or talk down to you?' , 'Rarely (2)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, insult or talk down to you?' , 'Sometimes (3)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, insult or talk down to you?' , 'Fairly Often (4)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, insult or talk down to you?' , 'Frequently (5)' 

    UNION ALL SELECT 'How often does anyone, including family and friends, threaten you with harm?' , 'Rarely (2)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, threaten you with harm?' , 'Sometimes (3)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, threaten you with harm?' , 'Fairly Often (4)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, threaten you with harm?' , 'Frequently (5)' 

    UNION ALL SELECT 'How often does anyone, including family and friends, scream or curse at you??' , 'Rarely (2)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, scream or curse at you??' , 'Sometimes (3)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, scream or curse at you??' , 'Fairly Often (4)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, scream or curse at you??' , 'Frequently (5)' 

),

positive_need_screen_2026 AS (
    SELECT DISTINCT h.seeker_id
    FROM hrsn_base_2026 h
    JOIN cte_unmet_criteria u
      ON h.question = u.question AND h.answer = u.answer
    JOIN hrsn_consented_2026 c
      ON h.form_submission_id = c.form_submission_id
     AND h.seeker_id          = c.seeker_id
    WHERE h.answer IS NOT NULL
      AND h.answer NOT IN ('Asked but Member declined to answer.',
                           'Decline to answer',
                           'Screener did not ask Member.')
),

/* =========================================================
   B) Outreach attempts since 1/1/26
   ========================================================= */
outreach_forms_2026 AS (
    SELECT
        seeker_id,
        form_submission_id,
        started_at
    FROM FH_flipa_mbr_insights_forms
    WHERE seeker_id IS NOT NULL
      AND started_at >= '2026-01-01'
      AND started_at < DATEADD(day, 1, @last_friday)
      AND form_name LIKE '%outreach%'   -- CHANGE if needed
),

outreach_attempts AS (
    SELECT
        seeker_id,
        COUNT(DISTINCT form_submission_id) AS outreach_attempt_count
    FROM outreach_forms_2026
    GROUP BY seeker_id
),

outreach_exhausted AS (
    SELECT seeker_id
    FROM outreach_attempts
    WHERE outreach_attempt_count >= 3
),

/* =========================================================
   C) Eligibility Assessment FOUND since 1/1/26
   ========================================================= */
ea_found_2026 AS (
    SELECT DISTINCT seeker_id
    FROM FH_flipa_mbr_insights_forms
    WHERE form_name LIKE '%eligibility%'
      AND seeker_id IS NOT NULL
      AND started_at >= '2026-01-01'
      AND started_at < DATEADD(day, 1, @last_friday)
)

/* =========================================================
   FINAL COUNT: Metric 5b
   ========================================================= */
SELECT
    COUNT(DISTINCT p.seeker_id) AS Members_EA_Outreach_Exhausted_5b,
    @last_friday                AS data_through_date
FROM positive_need_screen_2026 p
JOIN outreach_exhausted oe
  ON p.seeker_id = oe.seeker_id
LEFT JOIN ea_found_2026 ea
  ON p.seeker_id = ea.seeker_id
WHERE ea.seeker_id IS NULL;   -- <-- ensures NO EA found


----------------------------------------------------




-------------------Members who decline Eligibility Assessment (#)


WITH base_responses AS (   -- cte for FILTERING HRSN
    SELECT 
        form_submission_id,
        seeker_id,
        question,
        answer,
        started_at
    FROM FH_flipa_mbr_insights_forms
    WHERE form_name LIKE '%HRSN%'
),

responses_since_start AS ( -- cumulative window 2026-01-01 .. last Friday (inclusive)
    SELECT *
    FROM base_responses
    WHERE started_at >= '2026-01-01'
      AND started_at < DATEADD(day, 1, @last_friday)
),

consented_members AS (     -- consent = yes
    SELECT DISTINCT form_submission_id, seeker_id
    FROM responses_since_start
    WHERE question LIKE 'We use%'   -- consent stem
      AND answer IN ('Yes, I consent','Member agreed','Member consents')
),

/* REQUIRE: member said NO to continuing with Navigator */
navigator_declined AS (
    SELECT DISTINCT form_submission_id, seeker_id
    FROM responses_since_start
    WHERE question LIKE 'Would the member like to continue with a Navigator%'
      AND answer LIKE 'No%'
),

cte_unmet_criteria AS (    -- answers that indicate confirmed unmet HRSN
    SELECT 'What is your living situation today?' AS question,'I have a place to live today, but I am worried about losing it in the future' AS answer
    UNION ALL SELECT 'What is your living situation today?' ,'I do not have a steady place to live (I am temporarily staying with others, in a hotel, in a shelter, living outside on the street, on a beach, in a car, abandoned building, bus or train station, or in a park)' 

    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Pests such as bugs, ants, or mice' 
    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Mold' 
    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Lead paint or pipes' 
    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Lack of heat' 
    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Oven or stove not working' 
    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Smoke detectors missing or not working' 
    UNION ALL SELECT 'Think about the place you live. Do you have problems with any of the following?' , 'Water leaks' 

    UNION ALL SELECT 'In the past 12 months has the electric, gas, oil, or water company threatened to shut off services in your home?' , 'Yes' 
    UNION ALL SELECT 'In the past 12 months has the electric, gas, oil, or water company threatened to shut off services in your home?' , 'Already Shut Off' 

    UNION ALL SELECT 'Within the past 12 months, you worried that your food would run out before you got money to buy more.' , 'Often true' 
    UNION ALL SELECT 'Within the past 12 months, you worried that your food would run out before you got money to buy more.' , 'Sometimes true' 

    UNION ALL SELECT 'Within the past 12 months, the food you bought just didn''t last and you didn''t have money to get more.' , 'Often true' 
    UNION ALL SELECT 'Within the past 12 months, the food you bought just didn''t last and you didn''t have money to get more.' , 'Sometimes true' 

    UNION ALL SELECT 'In the past 12 months, has lack of reliable transportation kept you from medical appointments, meetings, work or from getting things needed for daily living?' , 'Yes'

    UNION ALL SELECT 'Do you want help finding or keeping work or a job?' , 'Yes, help finding work' 
    UNION ALL SELECT 'Do you want help finding or keeping work or a job?' , 'Yes, help keeping work' 

    UNION ALL SELECT 'Do you want help with school or training? For example, starting or completing job training or getting a high school diploma, GED or equivalent' , 'Yes' 

    UNION ALL SELECT 'How often does anyone, including family and friends, physically hurt you?' , 'Rarely (2)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, physically hurt you?' , 'Sometimes (3)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, physically hurt you?' , 'Fairly Often (4)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, physically hurt you?' , 'Frequently (5)' 

    UNION ALL SELECT 'How often does anyone, including family and friends, insult or talk down to you?' , 'Rarely (2)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, insult or talk down to you?' , 'Sometimes (3)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, insult or talk down to you?' , 'Fairly Often (4)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, insult or talk down to you?' , 'Frequently (5)' 

    UNION ALL SELECT 'How often does anyone, including family and friends, threaten you with harm?' , 'Rarely (2)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, threaten you with harm?' , 'Sometimes (3)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, threaten you with harm?' , 'Fairly Often (4)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, threaten you with harm?' , 'Frequently (5)' 

    UNION ALL SELECT 'How often does anyone, including family and friends, scream or curse at you??' , 'Rarely (2)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, scream or curse at you??' , 'Sometimes (3)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, scream or curse at you??' , 'Fairly Often (4)' 
    UNION ALL SELECT 'How often does anyone, including family and friends, scream or curse at you??' , 'Frequently (5)' 
),

valid_unmet_responses AS (
    SELECT DISTINCT r.form_submission_id, r.seeker_id
    FROM responses_since_start r
    JOIN cte_unmet_criteria u
      ON r.question = u.question AND r.answer = u.answer
    WHERE r.answer NOT IN ('Asked but Member declined to answer.','Decline to answer','Screener did not ask Member.')
      AND r.answer IS NOT NULL
)

SELECT 
    COUNT(DISTINCT v.seeker_id) AS Members_Screened_with_Unmet_Needs_Declined_EA_5c,
    @last_friday AS data_through_date
FROM valid_unmet_responses v
JOIN consented_members c
  ON v.form_submission_id = c.form_submission_id
JOIN navigator_declined nd
  ON v.form_submission_id = nd.form_submission_id;













