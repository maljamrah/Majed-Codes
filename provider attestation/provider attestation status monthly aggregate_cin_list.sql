-- Provider Attestation: MONTHLY list of CINs by goal_status
-- Excludes anyone with any ESMF flag = 'Y'
-- Window: 2025-01-01 through today

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
    WHERE g.goal_created_at >= '2025-01-01'
      AND g.goal_created_at <  DATEADD(DAY, 1, CAST(GETDATE() AS date))
      AND (
            g.category         LIKE '%provider attest%'
         OR g.subdomain        LIKE '%provider attest%'
         OR g.goal_description LIKE '%provider attest%'
      )
),

-- Map seeker_id -> CIN (pick one CIN per seeker if multiple)
cin_map AS (
    SELECT
        pag.seeker_id,
        MAX(LTRIM(RTRIM(f.answer))) AS cin
    FROM provider_attestation_goals pag
    LEFT JOIN dbo.FH_flipa_mbr_insights_forms f
        ON f.seeker_id = pag.seeker_id
       AND f.question LIKE '%CIN%'
       AND f.answer IS NOT NULL
    GROUP BY pag.seeker_id
),

-- ESMF members to remove (any Y)
esmf_y AS (
    SELECT DISTINCT e.mbrID
    FROM dbo.nyec_esmf e
    WHERE e.[EPOPHighUtilizer]     = 'Y'
       OR e.[EPOPHHEnrolled]       = 'Y'
       OR e.[EPOPOther]            = 'Y'
       OR e.[EPOPPregPostpartum]   = 'Y'
       OR e.[EPOPUnder18Nutrition] = 'Y'
       OR e.[EPOPUnder18]          = 'Y'
       OR e.[EPOPAdultCJ]          = 'Y'
        OR e.[EPOPIDD]            = 'Y'  -- add if needed
),

filtered AS (
    SELECT
        DATEFROMPARTS(YEAR(pag.goal_created_at), MONTH(pag.goal_created_at), 1) AS month_start,
        pag.goal_status,
        pag.seeker_id,
        cm.cin
    FROM provider_attestation_goals pag
    LEFT JOIN cin_map cm
        ON cm.seeker_id = pag.seeker_id
    LEFT JOIN esmf_y ey
        ON ey.mbrID = cm.cin
    WHERE ey.mbrID IS NULL
),

-- Dedupe: one row per (month, status, cin)
final_list AS (
    SELECT DISTINCT
        month_start,
        goal_status,
        cin,
        seeker_id
    FROM filtered
)

SELECT
    month_start,
    goal_status,
    cin,
    seeker_id
FROM final_list
ORDER BY month_start, goal_status, cin;
