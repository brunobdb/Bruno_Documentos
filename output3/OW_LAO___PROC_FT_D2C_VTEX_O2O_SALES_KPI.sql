/***********************************************************************************************
ALTER BY : Luciano Mariani
DATE : 2023-07-28
***********************************************************************************************/
CREATE PROCEDURE OW_LAO.PROC_FT_D2C_VTEX_O2O_SALES_KPI LANGUAGE SQLSCRIPT
AS
BEGIN
	
	CALL OW_LAO.PROC_D2C_VTEX_O2O_SALES_KPI;
	
	/************************** 
	DROP TABLE OW_LAO.FT_D2C_VTEX_O2O_SALES_KPI;
	
	SELECT 'SEDA' AS subsidiary
		,z.division AS dimprod_division
		,z.product_group_1 AS dimprod_product_group
		,z.product_1 AS dimprod_product
		,seda_bu_estore AS dimprod_seda_bu_estore
		,seda_division_estore AS dimprod_seda_division_estore
		,seda_category_estore AS dimprod_seda_category_estore
		,seda_family_estore AS dimprod_seda_family_estore
		,seda_desc_estore AS dimprod_seda_mkt_desc_estore
		,now() AS KPI_LAST_UPDATE
		,cast(a."amount_order" / c.exchange_rate AS NUMERIC(15, 2)) AS amount_order_usd
		,YYYYMM
		,YYYYWW
		,a.*
	FROM "U_PRJ_ECOM"."VIEW_ECOM_ENDLESS_AISLE_REPORT" a
	JOIN "OW_MD"."DIM_CALENDAR" b ON b.YYYYMMDD = a."order_creation_date"
	LEFT JOIN "OW_LAO".FT_AP2_EXCHANGE_RATE c ON c.valid_from = a."order_creation_date"
	LEFT JOIN OW_MD.DIM_PRODUCT z ON z.sku = a."reference_code"
	WHERE "order_creation_date" < cast(now() AS DATE)
		AND c.to_currency = 'BRL'
	**************************/
END
