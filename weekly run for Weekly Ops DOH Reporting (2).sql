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
    WHERE started_at >= '2025-01-01'
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

SELECT COUNT(DISTINCT c.seeker_id) AS Members_Screened, 
       @last_friday AS data_through_date
FROM consented_members c
JOIN valid_screening_responses v
  ON c.form_submission_id = v.form_submission_id;






-- Members Screened with Unmet Need(s) (#--Data Entry Point 6 -- Count of unique Medicaid Members with >=1 Completed Screening indicating a confirmed unmet HRSN
-- DOH weekly: cumulative since 2025-01-01 through the most-recent Friday
-- =======================================================================================================================


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

responses_since_start AS ( -- cumulative window 2025-01-01 .. last Friday (inclusive)
    SELECT *
    FROM base_responses
    WHERE started_at >= '2025-01-01'
      AND started_at < DATEADD(day, 1, @last_friday)
),

consented_members AS (     -- consent = yes
    SELECT DISTINCT form_submission_id, seeker_id
    FROM responses_since_start
    WHERE question LIKE 'We use%'   -- consent stem
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
)

SELECT COUNT(DISTINCT v.seeker_id) AS Members_Screened_with_Unmet_Needs,
       @last_friday AS data_through_date
FROM valid_unmet_responses v
JOIN consented_members c
  ON v.form_submission_id = c.form_submission_id;





-- 3) Members Assessed (#)----Date Entry - 7 : Count of unique Medicaid Members with a Completed Eligibility Assessment
-- DOH weekly: cumulative since 2025-01-01 through the most-recent Friday
-- ======================================================================================================================



WITH base_responses AS (
    SELECT 
        seeker_id,
        question,
        answer,
        form_submission_id,
        started_at
    FROM FH_flipa_mbr_insights_forms
    WHERE form_name LIKE '%eligibility%'          -- filter Eligibility Assessment forms
      AND seeker_id IS NOT NULL                   -- exclude orphaned records
),

responses_since_start AS (                        -- cumulative window: 2025-01-01 .. last Friday (inclusive)
    SELECT * 
    FROM base_responses
    WHERE started_at >= '2025-01-01'
      AND started_at < DATEADD(day, 1, @last_friday)
),

consented_members AS (                            -- members who consented to proceed with Eligibility Assessment
    SELECT DISTINCT form_submission_id, seeker_id
    FROM responses_since_start
    WHERE 
        (
            question LIKE 'We use%' 
            AND answer IN ('YES Member consents','Yes, I consent','Member agreed','Member consents')
        )
        OR
        (
            question LIKE 'Confirm consent with Member to move%' 
            AND answer IN ('Member consents','Yes, I consent','Member agreed')
        )
        -- Exclude non-responses / declines just in case wording overlaps
        AND answer NOT IN ('Asked but Member declined to answer.','Decline to answer','Screener did not ask Member.')
        AND answer IS NOT NULL
)

-- If you have a specific "Assessment Status" question that marks completion,
-- add another CTE to require Status='Completed' and join to it here.
SELECT 
    COUNT(DISTINCT seeker_id) AS Members_Assessed,
    @last_friday AS data_through_date
FROM consented_members;






-- Metric 4: Members Navigated to existing federal/state/local services
-- DOH weekly window: cumulative since 2025-01-01 through the most-recent Friday
-- Definition here: any referral to a NON-Enhanced program (no status filtering)


-- 1) HRSN screening population with consent
WITH base_responses AS (
    SELECT
        form_submission_id,
        seeker_id,
        question,
        answer,
        form_name,
        started_at
    FROM FH_flipa_mbr_insights_forms
    WHERE form_name LIKE '%HRSN%'
      AND seeker_id IS NOT NULL
),
responses_since_start AS (
    SELECT *
    FROM base_responses
    WHERE started_at >= '2025-01-01'
      AND started_at < DATEADD(day, 1, @last_friday)
),
consented_screenings AS (
    SELECT DISTINCT form_submission_id, seeker_id
    FROM responses_since_start
    WHERE question LIKE 'We use%'
      AND answer IN ('Yes, I consent','Member agreed','Member consents','YES Member consents')
      AND answer NOT IN ('Asked but Member declined to answer.','Decline to answer','Screener did not ask Member.')
      AND answer IS NOT NULL
),

-- 2) Referrals to existing (NON-Enhanced) programs in the window
navigation_events AS (
    SELECT DISTINCT r.seeker_id
    FROM FH_flipa_mbr_insights_referrals r
    JOIN FH_flipa_mbr_insights_programs p
      ON r.program_numeric_id = p.program_numeric_id
    WHERE p.program_name NOT LIKE '%enhanced%'           -- existing services only
      AND r.referral_date >= '2025-01-01'
      AND r.referral_date < DATEADD(day, 1, @last_friday)
)

-- 3) Final count
SELECT 
    COUNT(DISTINCT cs.seeker_id) AS navigated_count,
    @last_friday                 AS data_through_date
FROM consented_screenings cs
JOIN navigation_events ne
  ON cs.seeker_id = ne.seeker_id;





--Members referred to Enhanced HRSN services (#)--- DATA ENTRY 9 : Count of unique Medicaid Members with one or more requested Enhanced HRSN Referral
-- DOH weekly window: cumulative since 2025-01-01 through the most-recent Friday
-- Metric 9 = (Metric 8 population) ∩ (Enhanced referral requested in window)
-- ================================================================================================



-- -------------------------
-- Metric 8 as a CTE (reused)
-- -------------------------
WITH eligibility_data AS (  -- source: eligibility forms
    SELECT 
        f.seeker_id,
        f.form_submission_id,
        cin.answer AS cin,
        f.started_at,
        f.question,
        f.answer
    FROM FH_flipa_mbr_insights_forms f
    JOIN FH_flipa_mbr_insights_forms cin
      ON f.form_submission_id = cin.form_submission_id
    WHERE f.form_name LIKE '%eligibility%'
      AND cin.question LIKE '%CIN%'
      AND f.started_at >= '2025-01-01'
      AND f.started_at < DATEADD(day, 1, @last_friday)
      AND f.seeker_id IS NOT NULL
),
consented AS ( -- consent to proceed
    SELECT DISTINCT form_submission_id, cin, seeker_id
    FROM eligibility_data
    WHERE (
            (question LIKE 'We use%' AND answer IN ('YES Member consents','Yes, I consent','Member agreed','Member consents'))
         OR (question LIKE 'Confirm consent with Member to move%' AND answer IN ('Member consents','Yes, I consent','Member agreed'))
          )
),
want_services AS ( -- member wants services
    SELECT DISTINCT form_submission_id, cin, seeker_id
    FROM eligibility_data
    WHERE question LIKE 'Does the member want%'
      AND LOWER(LTRIM(RTRIM(answer))) = 'yes'
),
eligible_flags AS ( -- eligibility via ESMF
    SELECT DISTINCT mbrID
    FROM dbo.nyec_esmf
    WHERE [EPOPHighUtilizer] = 'Y' OR [EPOPHHEnrolled] = 'Y' OR [EPOPOther] = 'Y'
       OR [EPOPPregPostpartum] = 'Y' OR [EPOPUnder18Nutrition] = 'Y' OR [EPOPUnder18] = 'Y'
       OR [EPOPAdultCJ] = 'Y' OR [EPOPIDD] = 'Y'
),
metric8_population AS ( -- distinct members meeting Metric 8 conditions
    SELECT DISTINCT c.cin, c.seeker_id
    FROM consented c
    JOIN want_services w
      ON c.form_submission_id = w.form_submission_id
     AND c.seeker_id        = w.seeker_id
     AND c.cin              = w.cin
    JOIN eligible_flags ef
      ON c.cin = ef.mbrID
),

-- --------------------------------
-- Enhanced referrals in the window
-- --------------------------------
enhanced_referrals AS ( 
    SELECT DISTINCT r.seeker_id
    FROM FH_flipa_mbr_insights_referrals r
    JOIN FH_flipa_mbr_insights_programs p
      ON r.program_numeric_id = p.program_numeric_id
    WHERE p.program_name LIKE '%enhanced%'                   -- Enhanced HRSN only
      AND r.referral_date >= '2025-01-01'
      AND r.referral_date < DATEADD(day, 1, @last_friday)   -- inclusive of last Friday
)

-- -----------------
-- Final Metric 9
-- -----------------
SELECT COUNT(DISTINCT m8.cin) AS Members_referred_to_Enhanced_HRSN_services,
       @last_friday          AS data_through_date
FROM metric8_population m8
JOIN enhanced_referrals er
  ON m8.seeker_id = er.seeker_id;




--Members for whom a service is initiated--- Data Entry 11 : Count of unique Medicaid Members with one or more Enhanced HRSN services initiated
-- DOH weekly window: cumulative since 2025-01-01 through the most-recent Friday
-- =================================================================================================


WITH eligibility_data AS (
    SELECT 
        f.seeker_id,
        f.form_submission_id,
        cin.answer AS cin,
        f.started_at,
        f.question,
        f.answer
    FROM FH_flipa_mbr_insights_forms f
    JOIN FH_flipa_mbr_insights_forms cin
      ON f.form_submission_id = cin.form_submission_id
    WHERE f.form_name LIKE '%eligibility%'   -- filter Eligibility Assessment forms
      AND cin.question LIKE '%CIN%'
      AND f.started_at >= '2025-01-01'
      AND f.started_at < DATEADD(day, 1, @last_friday)
      AND f.seeker_id IS NOT NULL
),
consented AS (
    SELECT DISTINCT form_submission_id, cin, seeker_id
    FROM eligibility_data
    WHERE (
            (question LIKE 'We use%' AND answer IN ('YES Member consents','Yes, I consent','Member agreed','Member consents'))
         OR (question LIKE 'Confirm consent with Member to move%' AND answer IN ('Member consents','Yes, I consent','Member agreed'))
          )
),
want_services AS (
    SELECT DISTINCT form_submission_id, cin, seeker_id
    FROM eligibility_data
    WHERE question LIKE 'Does the member want%'
      AND LOWER(LTRIM(RTRIM(answer))) = 'yes'
),
eligible_flags AS (
    SELECT DISTINCT mbrID
    FROM dbo.nyec_esmf
    WHERE [EPOPHighUtilizer] = 'Y' OR [EPOPHHEnrolled] = 'Y' OR [EPOPOther] = 'Y'
       OR [EPOPPregPostpartum] = 'Y' OR [EPOPUnder18Nutrition] = 'Y' OR [EPOPUnder18] = 'Y'
       OR [EPOPAdultCJ] = 'Y'
),
enhanced_referrals AS ( 
    SELECT DISTINCT r.seeker_id, r.referral_status
    FROM FH_flipa_mbr_insights_referrals r
    JOIN FH_flipa_mbr_insights_programs p
      ON r.program_numeric_id = p.program_numeric_id
    WHERE p.program_name LIKE '%enhanced%'
      AND r.referral_date >= '2025-01-01'
      AND r.referral_date < DATEADD(day, 1, @last_friday)
      -- NOTE: If "initiated" means a specific status (often 'In Progress'),
      -- replace the list below with ('In Progress').
      AND r.referral_status IN ('needs client action','pending','referred elsewhere','got help','eligible')
)

-- Final count : Metric 11
SELECT COUNT(DISTINCT c.cin) AS Members_for_whom_a_service_is_initiated,
       @last_friday          AS data_through_date
FROM consented c
JOIN want_services w 
  ON c.form_submission_id = w.form_submission_id
JOIN eligible_flags ef
  ON c.cin = ef.MbrID
JOIN enhanced_referrals er
  ON c.seeker_id = er.seeker_id;




