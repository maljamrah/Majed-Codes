-- Provider Attestation Counts (exclude anyone with a "Y" on ESMF)
-- Output: counts of UNIQUE members by goal_status

;WITH provider_attestation_goals AS (
    SELECT DISTINCT
        g.seeker_id,
        g.goal_id,
        g.goal_status,
        g.goal_created_at,
        g.category,
        g.subdomain,
        g.goal_description
    FROM dbo.FH_flipa_mbr_insights_goals g
    WHERE
        -- Use whatever field your team considers the "goal type"
        -- Keep all 3 checks to be safe:
        (g.category LIKE '%provider attest%'
         OR g.subdomain LIKE '%provider attest%'
         OR g.goal_description LIKE '%provider attest%')
),

-- Map seeker_id -> CIN (from forms table)
cin_map AS (
    SELECT DISTINCT
        f.seeker_id,
        LTRIM(RTRIM(f.answer)) AS cin
    FROM dbo.FH_flipa_mbr_insights_forms f
    WHERE f.question LIKE '%CIN%'
      AND f.answer IS NOT NULL
),

-- ESMF "Y" flags (people to REMOVE)
esmf_y AS (
    SELECT DISTINCT
        e.mbrID
    FROM dbo.nyec_esmf e
    WHERE e.[EPOPHighUtilizer]     = 'Y'
       OR e.[EPOPHHEnrolled]       = 'Y'
       OR e.[EPOPOther]            = 'Y'
       OR e.[EPOPPregPostpartum]   = 'Y'
       OR e.[EPOPUnder18Nutrition] = 'Y'
       OR e.[EPOPUnder18]          = 'Y'
       OR e.[EPOPAdultCJ]          = 'Y'
       -- OR e.[EPOPIDD]           = 'Y'  -- include if needed
),

-- Join goals -> CIN, then EXCLUDE anyone in ESMF_Y
provider_attestation_filtered AS (
    SELECT
        pag.seeker_id,
        cm.cin,
        pag.goal_status
    FROM provider_attestation_goals pag
    LEFT JOIN cin_map cm
        ON cm.seeker_id = pag.seeker_id
    LEFT JOIN esmf_y ey
        ON ey.mbrID = cm.cin
    WHERE ey.mbrID IS NULL   -- remove anyone with any "Y" in ESMF
)

-- Final breakdown: UNIQUE members by goal_status
SELECT
    goal_status,
    COUNT(DISTINCT COALESCE(cin, CAST(seeker_id AS varchar(50)))) AS unique_members
FROM provider_attestation_filtered
GROUP BY goal_status
ORDER BY unique_members DESC;
