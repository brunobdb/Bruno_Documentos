CREATE PROCEDURE OW_LAO.PROC_DIM_TARGETS_CAMPAIGN_CADASTRA_UPDATE
LANGUAGE SQLSCRIPT AS
BEGIN
DROP TABLE OW_LAO.DIM_LAO_TARGETS_CAMPAIGN_CADASTRA;
CREATE TABLE OW_LAO.DIM_LAO_TARGETS_CAMPAIGN_CADASTRA AS (
WITH campaign_target AS (
    SELECT
        CAMPAIGN_NAME AS CAMPAIGN_TAG,
        CAST(SUB AS varchar) AS SUB,
        "DAY",
        CASE
            WHEN division IS NULL OR division = '' THEN 'all'
            ELSE UPPER(division)
        END AS DIVISION,
        CASE
            WHEN BIZ_TYPE IS NULL OR BIZ_TYPE = '' THEN 'all'
            ELSE UPPER(BIZ_TYPE)
        END AS BIZ_TYPE,
        CASE
            WHEN DEVICE_TYPE IS NULL OR DEVICE_TYPE = '' THEN 'all'
            ELSE LOWER(DEVICE_TYPE)
        END AS DEVICETYPE,
        CEJ_KPIS ,
          VALUE
    FROM OW_LAO.ODS_TARGETS_CAMPAIGN AS targets
    
   ),
-- Expansion for cases when all fields are 'all'
expanded_campaign AS (
    SELECT
        CAMPAIGN_TAG,
        "DAY",
        CAST(SUB AS varchar) AS SUB,
        'SMB' AS BIZ_TYPE,
        'app' AS DEVICETYPE,
        'MX' AS division,
        CEJ_KPIS,
        VALUE
    FROM campaign_target
    WHERE BIZ_TYPE = 'all' AND DEVICETYPE = 'all' AND division = 'all'
    UNION ALL
    -- Repeat for each combination
    SELECT
        CAMPAIGN_TAG,
        "DAY",
        CAST(SUB AS varchar) AS SUB,
        'SMB' AS BIZ_TYPE,
        'app' AS DEVICETYPE,
        'VD' AS division,
        CEJ_KPIS,
        VALUE
    FROM campaign_target
    WHERE BIZ_TYPE = 'all' AND DEVICETYPE = 'all' AND division = 'all'
    UNION ALL
    SELECT
        CAMPAIGN_TAG,
        "DAY",
        CAST(SUB AS varchar) AS SUB,
        'SMB' AS BIZ_TYPE,
        'app' AS DEVICETYPE,
        'DA' AS division,
        CEJ_KPIS,
        VALUE
    FROM campaign_target
    WHERE BIZ_TYPE = 'all' AND DEVICETYPE = 'all' AND division = 'all'
),
-- Expansion for cases when only division is 'all'
division_only_expansion AS (
    SELECT
        CAMPAIGN_TAG,
        CAST(SUB AS varchar) AS SUB,
        "DAY",
        BIZ_TYPE,
        DEVICETYPE,
        'MX' AS division,
        CEJ_KPIS,
        VALUE
    FROM campaign_target
    WHERE division = 'all' AND BIZ_TYPE != 'all' AND DEVICETYPE != 'all'
    UNION ALL
    SELECT
        CAMPAIGN_TAG,
        CAST(SUB AS varchar) AS SUB,
        "DAY",
        BIZ_TYPE,
        DEVICETYPE,
        'VD' AS division,
        CEJ_KPIS,
        VALUE
    FROM campaign_target
    WHERE division = 'all' AND BIZ_TYPE != 'all' AND DEVICETYPE != 'all'
    UNION ALL
    SELECT
        CAMPAIGN_TAG,
        CAST(SUB AS varchar) AS SUB,
        "DAY",
        BIZ_TYPE,
        DEVICETYPE,
        'DA' AS division,
        CEJ_KPIS,
        VALUE
    FROM campaign_target
    WHERE division = 'all' AND BIZ_TYPE != 'all' AND DEVICETYPE != 'all'
),
-- Expansion for cases when BIZ_TYPE and division are 'all'
business_division_expansion AS (
    SELECT
        CAMPAIGN_TAG,
        CAST(SUB AS varchar) AS SUB,
        "DAY",
        'SMB' AS BIZ_TYPE,
        DEVICETYPE,
        'MX' AS division,
        CEJ_KPIS,
        VALUE
    FROM campaign_target
    WHERE BIZ_TYPE = 'all' AND DEVICETYPE != 'all' AND division = 'all'
    UNION ALL
    SELECT
        CAMPAIGN_TAG,
        CAST(SUB AS varchar) AS SUB,
        "DAY",
        'SMB' AS BIZ_TYPE,
        DEVICETYPE,
        'VD' AS division,
        CEJ_KPIS,
        VALUE
    FROM campaign_target
    WHERE BIZ_TYPE = 'all' AND DEVICETYPE != 'all' AND division = 'all'
    UNION ALL
    SELECT
        CAMPAIGN_TAG,
        CAST(SUB AS varchar) AS SUB,
        "DAY",
        'SMB' AS BIZ_TYPE,
        DEVICETYPE,
        'DA' AS division,
        CEJ_KPIS,
        VALUE
    FROM campaign_target
    WHERE BIZ_TYPE = 'all' AND DEVICETYPE != 'all' AND division = 'all'
),
-- Final expansion combining all CTEs
final_expansion AS (
    SELECT CAMPAIGN_TAG, SUB, "DAY", BIZ_TYPE, DEVICETYPE, DIVISION, CEJ_KPIS, VALUE
    FROM campaign_target
    WHERE BIZ_TYPE != 'all' AND DEVICETYPE != 'all' AND DIVISION != 'all'
    UNION ALL
    SELECT DISTINCT CAMPAIGN_TAG, SUB, "DAY", BIZ_TYPE, DEVICETYPE, DIVISION, CEJ_KPIS, VALUE
    FROM expanded_campaign
    UNION ALL
    SELECT DISTINCT CAMPAIGN_TAG, SUB, "DAY",BIZ_TYPE, DEVICETYPE, DIVISION, CEJ_KPIS, VALUE
    FROM division_only_expansion
    UNION ALL
    SELECT DISTINCT CAMPAIGN_TAG, SUB, "DAY",BIZ_TYPE, DEVICETYPE, DIVISION, CEJ_KPIS, VALUE
    FROM business_division_expansion
)
SELECT *
FROM final_expansion A);
END 