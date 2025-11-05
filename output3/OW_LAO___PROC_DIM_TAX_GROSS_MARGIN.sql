/***********************************************************************************************
CREATED BY : Luciano Mariani
CREATION DATE : 2023-06-29
ALTER BY : Luciano Mariani
ALTER DATE : 2025-04-17
CALL OW_LAO.PROC_DIM_TAX_GROSS_MARGIN
***********************************************************************************************/
CREATE PROCEDURE OW_LAO.PROC_DIM_TAX_GROSS_MARGIN LANGUAGE SQLSCRIPT
AS
BEGIN
	
	/*********************************************************
	* CRIA A DIM_TAX_GROSS_MARGIN_BY_SKU
	********************************************************/
	IF EXISTS ( SELECT '' FROM SYS.TABLES WHERE SCHEMA_NAME = 'OW_LAO' AND TABLE_NAME = 'DIM_TAX_GROSS_MARGIN_BY_SKU' ) THEN
		DROP TABLE OW_LAO.DIM_TAX_GROSS_MARGIN_BY_SKU;
	END IF ;
	CREATE COLUMN TABLE OW_LAO.DIM_TAX_GROSS_MARGIN_BY_SKU AS (
		SELECT *
		FROM (
		    SELECT *,
		        ROW_NUMBER() OVER (PARTITION BY SKU, REGION, GROUP_ID ORDER BY TOTAL_COUNT DESC) AS RN
		    FROM (
		        SELECT *,
		            SUM(
		                CASE 
		                    WHEN PREV_END IS NULL OR BILLING_DATE_MIN > PREV_END THEN 1 
		                    ELSE 0 
		                END
		            ) OVER (PARTITION BY SKU, REGION ORDER BY BILLING_DATE_MIN ROWS UNBOUNDED PRECEDING) AS GROUP_ID
		        FROM (
		            SELECT *,
		                CASE 
		                    WHEN PREV_END IS NULL OR BILLING_DATE_MIN > PREV_END THEN 1 
		                    ELSE 0 
		                END AS NEW_GROUP_FLAG
		            FROM (
		                SELECT *,
		                    LAG(BILLING_DATE_MAX) OVER (PARTITION BY SKU, REGION ORDER BY BILLING_DATE_MIN) AS PREV_END
		                FROM (
		                    SELECT 
		                        SKU,
		                        REGION,
		                        TAX_SKU,
		                        TAX_INCENTIVE_SKU,
		                        SUM(TOTAL_COUNT) AS TOTAL_COUNT,
		                        MIN(BILLING_DATE) AS BILLING_DATE_MIN,
		                        MAX(BILLING_DATE) AS BILLING_DATE_MAX 	
		                    FROM (
		                        SELECT   
		                            IFNULL(MP.SKU_MAN, GM.SKU) AS SKU,
		                            GM.REGION,
		                            GM.BILLING_DATE,
		                            GM.YYYYMM,
		                            COUNT(*) AS TOTAL_COUNT,
		                            ROUND(SUM(GM.AMOUNT_ZKE) / NULLIF(SUM(GM.NF_TOTAL_AMT), 0), 3) AS TAX_SKU,
		                            ROUND(SUM(GM.TAX_INCENTIVE_ZKE) / NULLIF(SUM(GM.NF_TOTAL_AMT), 0), 3) AS TAX_INCENTIVE_SKU
		                        FROM OW_LAO.TF_NERP_GROSS_MARGIN GM
		                        LEFT JOIN OW_MD.MAP_SKU_GROSS_MARGIN MP
		                            ON MP.SKU_SE = GM.SKU 
		                            AND MP.UF = UPPER(GM.REGION)
		                        WHERE 
		                            GM.AFFILIATE_SUB_CHANNEL <> 'Outlet'
		                            AND GM.SALES_DOCUMENT_TYPE NOT IN ('YR01', 'YRT1')
		                            AND GM.AMOUNT_ZKE >= 0
		                            AND GM.TAX_INCENTIVE_ZKE >= 0
		                        GROUP BY 
		                            IFNULL(MP.SKU_MAN, GM.SKU),
		                            GM.REGION,
		                            GM.BILLING_DATE,
		                            GM.YYYYMM 
		                    ) TX_SKU_DATE
		                    GROUP BY
		                        SKU,
		                        REGION,
		                        TAX_SKU,
		                        TAX_INCENTIVE_SKU
		                ) TX_SKU_GP
		            ) ordenado
		        ) marcado
		    ) com_grupo
		) classificados
		WHERE RN = 1
		ORDER BY SKU, REGION, GROUP_ID, RN
	);
	
	
	/*********************************************************
	* CRIA A DIM_TAX_GROSS_MARGIN_BY_CATEGORY
	********************************************************/
	IF EXISTS ( SELECT '' FROM SYS.TABLES WHERE SCHEMA_NAME = 'OW_LAO' AND TABLE_NAME = 'DIM_TAX_GROSS_MARGIN_BY_CATEGORY' ) THEN
		DROP TABLE OW_LAO.DIM_TAX_GROSS_MARGIN_BY_CATEGORY;
	END IF ;
	CREATE COLUMN TABLE OW_LAO.DIM_TAX_GROSS_MARGIN_BY_CATEGORY AS (
		SELECT *
		FROM (
		    SELECT *,
		        ROW_NUMBER() OVER (PARTITION BY SEDA_CATEGORY_ESTORE, REGION, GROUP_ID ORDER BY TOTAL_COUNT DESC) AS RN
		    FROM (
		        SELECT *,
		            SUM(
		                CASE 
		                    WHEN PREV_END IS NULL OR BILLING_DATE_MIN > PREV_END THEN 1 
		                    ELSE 0 
		                END
		            ) OVER (PARTITION BY SEDA_CATEGORY_ESTORE, REGION ORDER BY BILLING_DATE_MIN ROWS UNBOUNDED PRECEDING) AS GROUP_ID
		        FROM (
		            SELECT *,
		                CASE 
		                    WHEN PREV_END IS NULL OR BILLING_DATE_MIN > PREV_END THEN 1 
		                    ELSE 0 
		                END AS NEW_GROUP_FLAG
		            FROM (
		                SELECT *,
		                    LAG(BILLING_DATE_MAX) OVER (PARTITION BY SEDA_CATEGORY_ESTORE, REGION ORDER BY BILLING_DATE_MIN) AS PREV_END
		                FROM (
		                    SELECT 
		                        SEDA_CATEGORY_ESTORE,
		                        REGION,
		                        TAX_SEDA_CATEGORY_ESTORE,
		                        TAX_INCENTIVE_SEDA_CATEGORY_ESTORE,
		                        SUM(TOTAL_COUNT) AS TOTAL_COUNT,
		                        MIN(BILLING_DATE) AS BILLING_DATE_MIN,
		                        MAX(BILLING_DATE) AS BILLING_DATE_MAX 	
		                    FROM (
		                        SELECT   
		                            GM.SEDA_CATEGORY_ESTORE,
		                            GM.REGION,
		                            GM.BILLING_DATE,
		                            GM.YYYYMM,
		                            COUNT(*) AS TOTAL_COUNT,
		                            ROUND(SUM(GM.AMOUNT_ZKE) / NULLIF(SUM(GM.NF_TOTAL_AMT), 0), 3) AS TAX_SEDA_CATEGORY_ESTORE,
		                            ROUND(SUM(GM.TAX_INCENTIVE_ZKE) / NULLIF(SUM(GM.NF_TOTAL_AMT), 0), 3) AS TAX_INCENTIVE_SEDA_CATEGORY_ESTORE
		                        FROM OW_LAO.TF_NERP_GROSS_MARGIN GM
		                        WHERE 
		                            GM.AFFILIATE_SUB_CHANNEL <> 'Outlet'
		                            AND GM.SALES_DOCUMENT_TYPE NOT IN ('YR01', 'YRT1')
		                            AND GM.AMOUNT_ZKE >= 0
		                            AND GM.TAX_INCENTIVE_ZKE >= 0
		                        GROUP BY 
		                            GM.SEDA_CATEGORY_ESTORE,
		                            GM.REGION,
		                            GM.BILLING_DATE,
		                            GM.YYYYMM 
		                    ) TX_SEDA_CATEGORY_ESTORE_DATE
		                    GROUP BY
		                        SEDA_CATEGORY_ESTORE,
		                        REGION,
		                        TAX_SEDA_CATEGORY_ESTORE,
		                        TAX_INCENTIVE_SEDA_CATEGORY_ESTORE
		                ) TX_SEDA_CATEGORY_ESTORE_GP
		            ) ordenado
		        ) marcado
		    ) com_grupo
		) classificados
		WHERE RN = 1
		ORDER BY SEDA_CATEGORY_ESTORE, REGION, GROUP_ID, RN
	);
END