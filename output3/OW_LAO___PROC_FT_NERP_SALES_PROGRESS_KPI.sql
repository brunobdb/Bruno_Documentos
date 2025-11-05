/***********************************************************************************************
CREATED BY : Rodrigo
CREATION DATE : 2023-08-01
ALTER DATE : 
ALTERED BY : Luciano Mariani
ALTER DATE : 2023-10-24
VERSION: 2
	CALL OW_LAO.PROC_FT_NERP_SALES_PROGRESS_KPI 
	
	select 
		 MEASURE_TYPE
		, REFERENCIA
		, sum(MEASURE_VALUE) as MEASURE_VALUE
	from OW_LAO.FT_NERP_SALES_PROGRESS_KPI	
	where  MEASURE_DESC = 'Forecast'
		and MEASURE_VALUE <> 0
	group by
		  MEASURE_TYPE
		, REFERENCIA
	order by 1,2
***********************************************************************************************/
CREATE PROCEDURE OW_LAO.PROC_FT_NERP_SALES_PROGRESS_KPI
LANGUAGE SQLSCRIPT AS
BEGIN
		drop table OW_LAO.AUX_NERP_SALES_PROGRESS_KPI_INTENCTIVE_RULES ;
		drop table OW_LAO.AUX_NERP_SALES_PROGRESS_KPI ;
		drop table OW_LAO.AUX_NERP_SALES_PROGRESS_KPI_TARGET ;
		drop table OW_LAO.TF_AP2_EXCHANGE_RATE_END_OF_MONTH ;
		drop table OW_LAO.TF_NERP_SALES_PROGRESS_KPI ;
		drop table OW_LAO.FT_NERP_SALES_PROGRESS_KPI ;   
		drop table OW_LAO.RAW_NERP_ZRCOA20250_FORECAST_SALES_DEDUP ;
     
     	  --/*****************
	     -- TMP_SALES_ORDER_TRACKING
		IF EXISTS( SELECT '' FROM SYS.TABLES WHERE SCHEMA_NAME = 'OW_LAO' AND TABLE_NAME = 'TMP_SOT_SALES_PROGRESS_KPI') THEN
			DROP TABLE OW_LAO.TMP_SOT_SALES_PROGRESS_KPI;
		END IF ;
	    CREATE COLUMN TABLE OW_LAO.TMP_SOT_SALES_PROGRESS_KPI AS (
			SELECT DISTINCT
				  CAST(SALES_DOCUMENT AS varchar(70)) AS SALES_DOCUMENT
				, MATERIAL 
				, SO_LOCAL_CREATE_ON_D
				, SALES_ORG
			FROM OW_LAO.ODS_NERP_ZRSDD6A120_SALES_ORDER_TRACKING
			WHERE SALES_ORG = '8201' -- SEDA
		) ;
		INSERT INTO OW_LAO.TMP_SOT_SALES_PROGRESS_KPI(
			  SALES_DOCUMENT
			, MATERIAL 
			, SO_LOCAL_CREATE_ON_D
			, SALES_ORG		
		)
		SELECT DISTINCT
			   CAST(O.CUSTOMER_PO AS varchar(70)) AS SALES_DOCUMENT
			, O.MATERIAL 
			, O.SO_LOCAL_CREATE_ON_D
			, O.SALES_ORG
		FROM OW_LAO.ODS_NERP_ZRSDD6A120_SALES_ORDER_TRACKING O
			LEFT JOIN OW_LAO.TMP_SOT_SALES_PROGRESS_KPI S ON CAST(O.CUSTOMER_PO AS varchar(70))  = S.SALES_DOCUMENT
		WHERE O.SALES_ORG = '8201' -- SEDA
			AND O.CUSTOMER_PO IS NOT null
		;
		INSERT INTO OW_LAO.TMP_SOT_SALES_PROGRESS_KPI(
			  SALES_DOCUMENT
			, MATERIAL 
			, SO_LOCAL_CREATE_ON_D
			, SALES_ORG		
		)		
		SELECT DISTINCT
			  CAST(O.REFERENCE_DOC_SO_PO AS varchar(70)) AS SALES_DOCUMENT
			, O.MATERIAL
		 	, O.SO_CREATED_ON
			, O.SALES_ORG
		FROM OW_LAO.ODS_NERP_ZLLEJ50090_OUTBOUND_TRACKING O
			LEFT JOIN OW_LAO.TMP_SOT_SALES_PROGRESS_KPI S ON CAST(O.REFERENCE_DOC_SO_PO AS varchar(70)) = S.SALES_DOCUMENT
		WHERE 1 = 1
			AND S.SALES_DOCUMENT IS null
			AND O.SALES_ORG = '8201' -- SEDA
			-- AND O.SO_TYPE NOT IN ('YS10', 'YS03')
			AND O.REFERENCE_DOC_SO_PO IS NOT NULL 
		;
    	
  		/************************ RAW_NERP_ZRCOA20250_FORECAST_SALES_DEDUP ************************/
		CREATE COLUMN TABLE OW_LAO.RAW_NERP_ZRCOA20250_FORECAST_SALES_DEDUP AS (
				SELECT
					  LEFT(FCT.PERIOD,4) AS "YEAR"
					, RIGHT(FCT.PERIOD,2) AS "MONTH"
					,FCT.SALES_ORGANIZATION
					, SUB.SUBSIDIARY
					--, FCT.SALES_ORGANIZATION AS SALES_ORGANIZATION
					, FCT.PRODUCT_NUMBER AS "PRODUCT_NUMBER"
					, FCT.CUSTOMER AS CUSTOMER
					, FCT.CURRENCY AS CURRENCY
					, SUM(FCT.QUANTITY_NET) AS QUANTITY_NET
					, SUM(FCT.NET_SALES) AS NET_SALES
					--, RANK() OVER( PARTITION BY SUB.SUBSIDIARY, FCT.PRODUCT_NUMBER , FCT.PERIOD ORDER BY CAST(SUBSTR_REGEXPR('([[:digit:]]{8})' IN FILE_NAME) AS DATE) DESC) AS SEQ
				FROM OW_LAO.RAW_NERP_ZRCOA20250_FORECAST_SALES FCT
					INNER JOIN OW_MD.DIM_SUBSIDIARY SUB ON 1=1
						AND FCT.SALES_ORGANIZATION = SUB.SALES_ORG
						AND SUB.SUBSIDIARY = 'SEDA' -- SOMENTE SEDA
					INNER JOIN ( 
						SELECT -- GET LAST FILE
							  LEFT(F.PERIOD,4) AS "YEAR"
							, RIGHT(F.PERIOD,2) AS "MONTH"
							, S.SUBSIDIARY
							, MAX(CAST(SUBSTR_REGEXPR('([[:digit:]]{8})' IN F.FILE_NAME) AS DATE)) AS FILE_NAME_DATE
						FROM OW_LAO.RAW_NERP_ZRCOA20250_FORECAST_SALES F
							INNER JOIN OW_MD.DIM_SUBSIDIARY S ON F.SALES_ORGANIZATION = S.SALES_ORG
						WHERE S.SUBSIDIARY = 'SEDA'
						GROUP BY
							  LEFT(F.PERIOD,4)
							, RIGHT(F.PERIOD,2)
							, S.SUBSIDIARY
					) LF -- LAST FILE
					ON 1=1
						AND LF.FILE_NAME_DATE = CAST(SUBSTR_REGEXPR('([[:digit:]]{8})' IN FCT.FILE_NAME) AS DATE)
						AND LF."YEAR" = LEFT(FCT.PERIOD,4)
						AND LF."MONTH" = RIGHT(FCT.PERIOD,2)
						AND LF.SUBSIDIARY = SUB.SUBSIDIARY
				WHERE FCT.CUSTOMER IN (
						SELECT DISTINCT
							CAST(SOLD_TO_PARTY AS VARCHAR(50)) SOLD_TO_PARTY
						FROM OW_LAO.DIM_SOLD_TO 
						WHERE SUBSIDIARY = 'SEDA'
					)	
				GROUP BY
					  LEFT(FCT.PERIOD,4) --AS "YEAR"
					, RIGHT(FCT.PERIOD,2) --AS "MONTH"
					--,FCT.SALES_ORGANIZATION
					, SUB.SUBSIDIARY
					, FCT.SALES_ORGANIZATION --AS SALES_ORGANIZATION
					, FCT.PRODUCT_NUMBER --AS "PRODUCT_NUMBER"
					, FCT.CUSTOMER --AS CUSTOMER
					, FCT.CURRENCY --AS CURRENCY
		);
    
    create column table OW_LAO.AUX_NERP_SALES_PROGRESS_KPI_INTENCTIVE_RULES as
    (
    
        select subsidiary
             , month
             , year
             , referencia
             , plant
             , transport_zone_destination
             , item_division
             , dimprod_division
             , dimprod_product_group
             , dimprod_seda_bu_estore
             , dimprod_seda_division_estore
             , dimprod_seda_category_estore
             , sum(SoProgressQuantity)                 as So_Progress_Quantity
             , sum(SoProgressAmount)                   as So_Progress_Amount
             , sum(So_Progress_Next_Month_Quantity)    as So_Progress_Next_Month_Quantity
             , sum(So_Progress_Next_Month_Amount)      as So_Progress_Next_Month_Amount
             , sum(DoProgressQuantity)                 as Do_Progress_Quantity
             , sum(DoProgressAmount)                   as Do_Progress_Amount
             , sum(GIProgressQuantity)                 as GI_Progress_Quantity
             , sum(GIProgressAmount)                   as GI_Progress_Amount
             , sum(InTransitQuantity)                  as In_Transit_Quantity
             , sum(InTransitAmount)                    as In_Transit_Amount
             , sum(billingIODProgressQuantity)         as billing_IOD_Progress_Quantity
             , sum(billingIODProgressAmount)           as billing_IOD_Progress_Amount
             , sum(billingIODProgressPreviousQuantity) as billingIODProgressPreviousQuantity
             , sum(billingIODProgressPreviousAmount)   as billingIODProgressPreviousAmount
             , sum(InTransitNetTotalQuantity)          as InTransitNetTotalQuantity
             , sum(InTransitNetTotalAmount)            as InTransitNetTotalAmount
             , sum(ForecastQuantity)                   as ForecastQuantity
             , sum(ForecastAmount)                     as ForecastAmount
             , sum(InTransitNextMonthQuantity)         as InTransitNextMonthQuantity
             , sum(InTransitNextMonthAmount)           as InTransitNextMonthAmount
          from (
                select b.subsidiary                                                    as subsidiary
                     , month(a.SO_LOCAL_CREATE_ON_D)                                   as month
                     , year(a.SO_LOCAL_CREATE_ON_D)                                    as year
                     , TO_VARCHAR(TO_DATE(a.SO_LOCAL_CREATE_ON_D), 'YYYYMM')           as referencia
                     , a.plant                                                         as plant
                     , substring(transport_zone, 3, 2)                                 as transport_zone_destination
                     , a.item_division                                                 as item_division
                     , z.division                                                      as dimprod_division
                     , z.product_group_1                                               as dimprod_product_group  
                     , z.seda_bu_estore                                                as dimprod_seda_bu_estore       
                     , z.seda_division_estore                                          as dimprod_seda_division_estore 
                     , z.seda_category_estore                                          as dimprod_seda_category_estore 
                     , sum(cast(a.ORDER_QTY_BASE as int))                              as SoProgressQuantity
                     , sum(cast(replace(a.SO_NET_VALUE, ',' ,'') as numeric(15,2)))    as SoProgressAmount
                     , cast(0    as int)                                               as So_Progress_Next_Month_Quantity
                     , cast(0.00 as decimal)                                           as So_Progress_Next_Month_Amount
                     , 0                                                               as DoProgressQuantity
                     , 0                                                               as DoProgressAmount
                     , 0                                                               as GIProgressQuantity
                     , 0                                                               as GIProgressAmount
                     , 0                                                               as InTransitQuantity
                     , 0                                                               as InTransitAmount
                     , 0                                                               as billingIODProgressQuantity
                     , 0                                                               as billingIODProgressAmount
                     , 0                                                               as billingIODProgressPreviousQuantity
                     , 0                                                               as billingIODProgressPreviousAmount
                     , 0                                                               as InTransitNetTotalQuantity
                     , 0                                                               as InTransitNetTotalAmount
                     , 0                                                               as ForecastQuantity
                     , 0                                                               as ForecastAmount
                     , cast(0 as int)                                                  as InTransitNextMonthQuantity
                     , cast(0 as numeric(15,2))                                        as InTransitNextMonthAmount
                  from OW_LAO.ODS_NERP_ZRSDD6A120_SALES_ORDER_TRACKING a
                  join "OW_MD"."DIM_SUBSIDIARY"                          b on b.sales_org = a.sales_org
             left join OW_MD.DIM_PRODUCT                                 z on z.sku       = a.material
                 where b.sur_key_subsidiary = 1 -- SEDA
                   and cast(a.SO_LOCAL_CREATE_ON_D as date )>= '2023-04-01'
                   and a.REJECT_REASON is null
                   and a.REJECT_REASON_1 is null
                   and cast(a.ORDER_QTY_BASE as int) >= 0
                   and cast(replace(a.SO_NET_VALUE, ',' ,'') as numeric(15,2)) >= 0
              group by b.subsidiary
                     , month(a.SO_LOCAL_CREATE_ON_D)
                     , year(a.SO_LOCAL_CREATE_ON_D)
                     , TO_VARCHAR(TO_DATE(a.SO_LOCAL_CREATE_ON_D), 'YYYYMM')
                     , a.plant
                     , substring(transport_zone, 3, 2)
                     , a.item_division
                     , z.division
                     , z.product_group_1   
                     , z.seda_bu_estore
                     , z.seda_division_estore
                     , z.seda_category_estore
                     
                 union all
                 
                select b.subsidiary                                                    as subsidiary
                     , month(a.SO_LOCAL_CREATE_ON_D)                                   as month
                     , year(a.SO_LOCAL_CREATE_ON_D)                                    as year
                     , TO_VARCHAR(TO_DATE(a.SO_LOCAL_CREATE_ON_D), 'YYYYMM')           as referencia
                     , a.plant                                                         as plant
                     , substring(transport_zone, 3, 2)                                 as transport_zone_destination
                     , a.item_division                                                 as item_division
                     , z.division                                                      as dimprod_division
                     , z.product_group_1                                               as dimprod_product_group  
                     , z.seda_bu_estore                                                as dimprod_seda_bu_estore       
                     , z.seda_division_estore                                          as dimprod_seda_division_estore 
                     , z.seda_category_estore                                          as dimprod_seda_category_estore 
                     , 0                                                               as SoProgressQuantity
                     , 0                                                               as SoProgressAmount
                     , cast(0    as int)                                               as So_Progress_Next_Month_Quantity
                     , cast(0.00 as decimal)                                           as So_Progress_Next_Month_Amount
                     , sum(cast(a.ORDER_QTY_BASE as int))                              as DoProgressQuantity
                     , sum(cast(replace(a.SO_NET_VALUE, ',' ,'') as numeric(15,2)))    as DoProgressAmount
                     , 0                                                               as GIProgressQuantity
                     , 0                                                               as GIProgressAmount
                     , 0                                                               as InTransitQuantity
                     , 0                                                               as InTransitAmount
                     , 0                                                               as billingIODProgressQuantity
                     , 0                                                               as billingIODProgressAmount
                     , 0                                                               as billingIODProgressPreviousQuantity
                     , 0                                                               as billingIODProgressPreviousAmount
                     , 0                                                               as InTransitNetTotalQuantity
                     , 0                                                               as InTransitNetTotalAmount
                     , 0                                                               as ForecastQuantity
                     , 0                                                               as ForecastAmount
                     , cast(0 as int)                                                  as InTransitNextMonthQuantity
                     , cast(0 as numeric(15,2))                                        as InTransitNextMonthAmount
                  from OW_LAO.ODS_NERP_ZRSDD6A120_SALES_ORDER_TRACKING  a
                  join "OW_MD"."DIM_SUBSIDIARY"                          b on b.sales_org = a.sales_org
             left join OW_MD.DIM_PRODUCT                                 z on z.sku       = a.material
                 where b.sur_key_subsidiary = 1 -- SEDA
                   and cast(a.SO_LOCAL_CREATE_ON_D as date )>= '2023-04-01'
                   and a.REJECT_REASON        is null
                   and a.REJECT_REASON_1      is null
                   and a.DO_LOCAL_CREATE_ON_D is not null
                   and cast(a.ORDER_QTY_BASE as int)                           >= 0
                   and cast(replace(a.SO_NET_VALUE, ',' ,'') as numeric(15,2)) >= 0
              group by b.subsidiary
                     , month(a.SO_LOCAL_CREATE_ON_D)
                     , year(a.SO_LOCAL_CREATE_ON_D)
                     , TO_VARCHAR(TO_DATE(a.SO_LOCAL_CREATE_ON_D), 'YYYYMM')
                     , a.plant
                     , substring(transport_zone, 3, 2)
                     , a.item_division
                     , z.division
                     , z.product_group_1     
                     , z.seda_bu_estore
                     , z.seda_division_estore
                     , z.seda_category_estore
                     
                 union all
                 
                select b.subsidiary                                                    as subsidiary
                     , month(a.SO_LOCAL_CREATE_ON_D)                                   as month
                     , year(a.SO_LOCAL_CREATE_ON_D)                                    as year
                     , TO_VARCHAR(TO_DATE(a.SO_LOCAL_CREATE_ON_D), 'YYYYMM')           as referencia
                     , a.plant                                                         as plant
                     , substring(transport_zone, 3, 2)                                 as transport_zone_destination
                     , a.item_division                                                 as item_division
                     , z.division                                                      as dimprod_division
                     , z.product_group_1                                               as dimprod_product_group  
                     , z.seda_bu_estore                                                as dimprod_seda_bu_estore       
                     , z.seda_division_estore                                          as dimprod_seda_division_estore 
                     , z.seda_category_estore                                          as dimprod_seda_category_estore 
                     , 0                                                               as SoProgressQuantity
                     , 0                                                               as SoProgressAmount
                     , cast(0    as int)                                               as So_Progress_Next_Month_Quantity
                     , cast(0.00 as decimal)                                           as So_Progress_Next_Month_Amount
                     , 0                                                               as DOProgressQuantity
                     , 0                                                               as DOProgressAmount
                     , sum(cast(a.ORDER_QTY_BASE as int))                              as GIProgressQuantity
                     , sum(cast(replace(a.SO_NET_VALUE, ',' ,'') as numeric(15,2)))    as GIProgressAmount
                     , 0                                                               as InTransitQuantity
                     , 0                                                               as InTransitAmount
                     , 0                                                               as billingIODProgressQuantity
                     , 0                                                               as billingIODProgressAmount
                     , 0                                                               as billingIODProgressPreviousQuantity
                     , 0                                                               as billingIODProgressPreviousAmount
                     , 0                                                               as InTransitNetTotalQuantity
                     , 0                                                               as InTransitNetTotalAmount
                     , 0                                                               as ForecastQuantity
                     , 0                                                               as ForecastAmount
                     , cast(0 as int)                                                  as InTransitNextMonthQuantity
                     , cast(0 as numeric(15,2))                                        as InTransitNextMonthAmount
                  from OW_LAO.ODS_NERP_ZRSDD6A120_SALES_ORDER_TRACKING a
                  join "OW_MD"."DIM_SUBSIDIARY"                          b on b.sales_org = a.sales_org
             left join OW_MD.DIM_PRODUCT                                 z on z.sku       = a.material
                 where b.sur_key_subsidiary = 1 -- SEDA
                   and cast(a.SO_LOCAL_CREATE_ON_D as date )>= '2023-04-01'
                   and a.REJECT_REASON         is null
                   and a.REJECT_REASON_1       is null
                   and a."1ST_GI_LOCAL_CREATE" is not null
                   and cast(a.ORDER_QTY_BASE as int)                           >= 0
                   and cast(replace(a.SO_NET_VALUE, ',' ,'') as numeric(15,2)) >= 0
              group by b.subsidiary
                     , month(a.SO_LOCAL_CREATE_ON_D)
                     , year(a.SO_LOCAL_CREATE_ON_D)
                     , TO_VARCHAR(TO_DATE(a.SO_LOCAL_CREATE_ON_D), 'YYYYMM')
                     , a.plant
                     , substring(transport_zone, 3, 2)
                     , a.item_division
                     , z.division
                     , z.product_group_1         
                     , z.seda_bu_estore
                     , z.seda_division_estore
                     , z.seda_category_estore
                     
                 union all
                 
                select b.subsidiary                                                    as subsidiary
                     , month(a.SO_LOCAL_CREATE_ON_D)                                   as month
                     , year(a.SO_LOCAL_CREATE_ON_D)                                    as year
                     , TO_VARCHAR(TO_DATE(a.SO_LOCAL_CREATE_ON_D), 'YYYYMM')           as referencia
                     , a.plant                                                         as plant
                     , substring(transport_zone, 3, 2)                                 as transport_zone_destination
                     , a.item_division                                                 as item_division
                     , z.division                                                      as dimprod_division
                     , z.product_group_1                                               as dimprod_product_group  
                     , z.seda_bu_estore                                                as dimprod_seda_bu_estore       
                     , z.seda_division_estore                                          as dimprod_seda_division_estore 
                     , z.seda_category_estore                                          as dimprod_seda_category_estore 
                     , 0                                                               as SoProgressQuantity
                     , 0                                                               as SoProgressAmount
                     , cast(0    as int)                                               as So_Progress_Next_Month_Quantity
                     , cast(0.00 as decimal)                                           as So_Progress_Next_Month_Amount
                     , 0                                                               as DoProgressQuantity
                     , 0                                                               as DoProgressAmount
                     , 0                                                               as GIProgressQuantity
                     , 0                                                               as GIProgressAmount
                     , sum(cast(a.ORDER_QTY_BASE as int))                              as InTransitQuantity
                     , sum(cast(replace(a.SO_NET_VALUE, ',' ,'') as numeric(15,2)))    as InTransitAmount
                     , 0                                                               as billingIODProgressQuantity
                     , 0                                                               as billingIODProgressAmount
                     , 0                                                               as billingIODProgressPreviousQuantity
                     , 0                                                               as billingIODProgressPreviousAmount
                     , 0                                                               as InTransitNetTotalQuantity
                     , 0                                                               as InTransitNetTotalAmount
                     , 0                                                               as ForecastQuantity
                     , 0                                                               as ForecastAmount
                     , cast(0 as int)                                                  as InTransitNextMonthQuantity
                     , cast(0 as numeric(15,2))                                        as InTransitNextMonthAmount
                  from OW_LAO.ODS_NERP_ZRSDD6A120_SALES_ORDER_TRACKING a
                  join "OW_MD"."DIM_SUBSIDIARY"                          b on b.sales_org = a.sales_org
             left join OW_MD.DIM_PRODUCT                                 z on z.sku       = a.material
                 where b.sur_key_subsidiary = 1 -- SEDA
                   and cast(a.SO_LOCAL_CREATE_ON_D as date )>= '2023-04-01'
                   and a.REJECT_REASON         is null
                   and a.REJECT_REASON_1       is null
                   and a.BILLING_LOCAL_CREATE  is null
                   and a."1ST_GI_LOCAL_CREATE" is not null
                   and cast(a.ORDER_QTY_BASE as int)                           >= 0
                   and cast(replace(a.SO_NET_VALUE, ',' ,'') as numeric(15,2)) >= 0
                   and last_day(a.SO_LOCAL_CREATE_ON_D) = last_day(
                                                                 coalesce(
                                                                       cast(billing_create_on  as date )
                                                                     , cast(final_sch_date     as date )
                                                                     , cast(first_sc_date      as date )
                                                                 )
                                                          )
              group by b.subsidiary
                     , month(a.SO_LOCAL_CREATE_ON_D)
                     , year(a.SO_LOCAL_CREATE_ON_D)
                     , TO_VARCHAR(TO_DATE(a.SO_LOCAL_CREATE_ON_D), 'YYYYMM')
                     , a.plant
                     , substring(transport_zone, 3, 2)
                     , a.item_division
                     , z.division
                     , z.product_group_1        
                     , z.seda_bu_estore
                     , z.seda_division_estore
                     , z.seda_category_estore
                     
                 union all
                 
                select b.subsidiary                                                    as subsidiary
                     , month(a.SO_LOCAL_CREATE_ON_D)                                   as month
                     , year(a.SO_LOCAL_CREATE_ON_D)                                    as year
                     , TO_VARCHAR(TO_DATE(a.SO_LOCAL_CREATE_ON_D), 'YYYYMM')           as referencia
                     , a.plant                                                         as plant
                     , substring(transport_zone, 3, 2)                                 as transport_zone_destination
                     , a.item_division                                                 as item_division
                     , z.division                                                      as dimprod_division
                     , z.product_group_1                                               as dimprod_product_group  
                     , z.seda_bu_estore                                                as dimprod_seda_bu_estore       
                     , z.seda_division_estore                                          as dimprod_seda_division_estore 
                     , z.seda_category_estore                                          as dimprod_seda_category_estore 
                     , 0                                                               as SoProgressQuantity
                     , 0                                                               as SoProgressAmount
                     , cast(0    as int)                                               as So_Progress_Next_Month_Quantity
                     , cast(0.00 as decimal)                                           as So_Progress_Next_Month_Amount
                     , 0                                                               as DoProgressQuantity
                     , 0                                                               as DoProgressAmount
                     , 0                                                               as GIProgressQuantity
                     , 0                                                               as GIProgressAmount
                     , 0                                                               as InTransitQuantity
                     , 0                                                               as InTransitAmount
                     , 0                                                               as billingIODProgressQuantity
                     , 0                                                               as billingIODProgressAmount
                     , 0                                                               as billingIODProgressPreviousQuantity
                     , 0                                                               as billingIODProgressPreviousAmount
                     , sum(cast(a.ORDER_QTY_BASE as int))                              as InTransitNetTotalQuantity
                     , sum(cast(replace(a.SO_NET_VALUE, ',' ,'') as numeric(15,2)))    as InTransitNetTotalAmount
                     , 0                                                               as ForecastQuantity
                     , 0                                                               as ForecastAmount
                     , cast(0 as int)                                                  as InTransitNextMonthQuantity
                     , cast(0 as numeric(15,2))                                        as InTransitNextMonthAmount
                  from OW_LAO.ODS_NERP_ZRSDD6A120_SALES_ORDER_TRACKING a
                  join "OW_MD"."DIM_SUBSIDIARY"                          b on b.sales_org = a.sales_org
             left join OW_MD.DIM_PRODUCT                                 z on z.sku       = a.material
                 where b.sur_key_subsidiary = 1 -- SEDA
                   and cast(a.SO_LOCAL_CREATE_ON_D as date )>= '2023-04-01'
                   and a.REJECT_REASON         is null
                   and a.REJECT_REASON_1       is null
                   and a.BILLING_LOCAL_CREATE  is null
                   and a."1ST_GI_LOCAL_CREATE" is not null
                   and cast(a.ORDER_QTY_BASE as int)                           >= 0
                   and cast(replace(a.SO_NET_VALUE, ',' ,'') as numeric(15,2)) >= 0
              group by b.subsidiary
                     , month(a.SO_LOCAL_CREATE_ON_D)
                     , year(a.SO_LOCAL_CREATE_ON_D)
                     , TO_VARCHAR(TO_DATE(a.SO_LOCAL_CREATE_ON_D), 'YYYYMM')
                     , a.plant
                     , substring(transport_zone, 3, 2)
                     , a.item_division
                     , z.division
                     , z.product_group_1   
                     , z.seda_bu_estore
                     , z.seda_division_estore
                     , z.seda_category_estore
                     
                 union all
                 
                select b.subsidiary                                                    as subsidiary
                     , month(a.SO_LOCAL_CREATE_ON_D)                                   as month
                     , year(a.SO_LOCAL_CREATE_ON_D)                                    as year
                     , TO_VARCHAR(TO_DATE(a.SO_LOCAL_CREATE_ON_D), 'YYYYMM')           as referencia
                     , a.plant                                                         as plant
                     , substring(transport_zone, 3, 2)                                 as transport_zone_destination
                     , a.item_division                                                 as item_division
                     , z.division                                                      as dimprod_division
                     , z.product_group_1                                               as dimprod_product_group  
                     , z.seda_bu_estore                                                as dimprod_seda_bu_estore       
                     , z.seda_division_estore                                          as dimprod_seda_division_estore 
                     , z.seda_category_estore                                          as dimprod_seda_category_estore 
                     , 0                                                               as SoProgressQuantity
                     , 0                                                               as SoProgressAmount
                     , sum(cast(a.ORDER_QTY_BASE as int))                              as So_Progress_Next_Month_Quantity
                     , sum(cast(replace(a.SO_NET_VALUE, ',' ,'') as numeric(15,2)))    as So_Progress_Next_Month_Amount
                     , 0                                                               as DoProgressQuantity
                     , 0                                                               as DoProgressAmount
                     , 0                                                               as GIProgressQuantity
                     , 0                                                               as GIProgressAmount
                     , 0                                                               as InTransitQuantity
                     , 0                                                               as InTransitAmount
                     , 0                                                               as billingIODProgressQuantity
                     , 0                                                               as billingIODProgressAmount
                     , 0                                                               as billingIODProgressPreviousQuantity
                     , 0                                                               as billingIODProgressPreviousAmount
                     , 0                                                               as InTransitNetTotalQuantity
                     , 0                                                               as InTransitNetTotalAmount
                     , 0                                                               as ForecastQuantity
                     , 0                                                               as ForecastAmount
                     , cast(0 as int)                                                  as InTransitNextMonthQuantity
                     , cast(0 as numeric(15,2))                                        as InTransitNextMonthAmount
                  from OW_LAO.ODS_NERP_ZRSDD6A120_SALES_ORDER_TRACKING a
                  join "OW_MD"."DIM_SUBSIDIARY"                          b on b.sales_org = a.sales_org
             left join OW_MD.DIM_PRODUCT                                 z on z.sku       = a.material
                 where b.sur_key_subsidiary = 1 -- SEDA
                   and cast(a.SO_LOCAL_CREATE_ON_D as date )>= '2023-04-01'
                   and a.REJECT_REASON         is null
                   and a.REJECT_REASON_1       is null
                   and cast(a.ORDER_QTY_BASE as int)                           >= 0
                   and cast(replace(a.SO_NET_VALUE, ',' ,'') as numeric(15,2)) >= 0
                   and last_day(
                             add_months(a.SO_LOCAL_CREATE_ON_D, 1)                           
                       )                                = last_day(
                                                                 coalesce(
                                                                       cast(billing_create_on  as date )
                                                                     , cast(final_sch_date     as date )
                                                                     , cast(first_sc_date      as date )
                                                                 )
                                                          )
              group by b.subsidiary
                     , month(a.SO_LOCAL_CREATE_ON_D)
                     , year(a.SO_LOCAL_CREATE_ON_D)
                     , TO_VARCHAR(TO_DATE(a.SO_LOCAL_CREATE_ON_D), 'YYYYMM')
                     , a.plant
                     , substring(transport_zone, 3, 2)
                     , a.item_division
                     , z.division
                     , z.product_group_1   
                     , z.seda_bu_estore
                     , z.seda_division_estore
                     , z.seda_category_estore
                     
                 union all
                 
                select b.subsidiary                                                    as subsidiary
                     , month(a.SO_LOCAL_CREATE_ON_D)                                   as month
                     , year(a.SO_LOCAL_CREATE_ON_D)                                    as year
                     , TO_VARCHAR(TO_DATE(a.SO_LOCAL_CREATE_ON_D), 'YYYYMM')           as referencia
                     , a.plant                                                         as plant
                     , substring(transport_zone, 3, 2)                                 as transport_zone_destination
                     , a.item_division                                                 as item_division
                     , z.division                                                      as dimprod_division
                     , z.product_group_1                                               as dimprod_product_group  
                     , z.seda_bu_estore                                                as dimprod_seda_bu_estore       
                     , z.seda_division_estore                                          as dimprod_seda_division_estore 
                     , z.seda_category_estore                                          as dimprod_seda_category_estore 
                     , 0                                                               as SoProgressQuantity
                     , 0                                                               as SoProgressAmount
                     , cast(0    as int)                                               as So_Progress_Next_Month_Quantity
                     , cast(0.00 as decimal)                                           as So_Progress_Next_Month_Amount
                     , 0                                                               as DoProgressQuantity
                     , 0                                                               as DoProgressAmount
                     , 0                                                               as GIProgressQuantity
                     , 0                                                               as GIProgressAmount
                     , 0                                                               as InTransitQuantity
                     , 0                                                               as InTransitAmount
                     , 0                                                               as billingIODProgressQuantity
                     , 0                                                               as billingIODProgressAmount
                     , 0                                                               as billingIODProgressPreviousQuantity
                     , 0                                                               as billingIODProgressPreviousAmount
                     , 0                                                               as InTransitNetTotalQuantity
                     , 0                                                               as InTransitNetTotalAmount
                     , 0                                                               as ForecastQuantity
                     , 0                                                               as ForecastAmount
                     , sum(cast(a.ORDER_QTY_BASE as int))                              as InTransitNextMonthQuantity
                     , sum(cast(replace(a.SO_NET_VALUE, ',' ,'') as numeric(15,2)))    as InTransitNextMonthAmount
                  from OW_LAO.ODS_NERP_ZRSDD6A120_SALES_ORDER_TRACKING a
                  join "OW_MD"."DIM_SUBSIDIARY"                          b on b.sales_org = a.sales_org
             left join OW_MD.DIM_PRODUCT                                 z on z.sku       = a.material
                 where b.sur_key_subsidiary = 1 -- SEDA
                   and cast(a.SO_LOCAL_CREATE_ON_D as date )>= '2023-04-01'
                   and a.REJECT_REASON         is null
                   and a.REJECT_REASON_1       is null
                   and a.BILLING_LOCAL_CREATE  is null
                   and a."1ST_GI_LOCAL_CREATE" is not null
                   and cast(a.ORDER_QTY_BASE as int)                           >= 0
                   and cast(replace(a.SO_NET_VALUE, ',' ,'') as numeric(15,2)) >= 0
                   and last_day(
                             add_months(a.SO_LOCAL_CREATE_ON_D, 1)                           
                       ) = 
                                                                  last_day(
                                                                         coalesce(
                                                                               cast(billing_create_on  as date )
                                                                             , cast(final_sch_date     as date )
                                                                             , cast(first_sc_date      as date )
                                                                         )
                                                                  )
              group by b.subsidiary
                     , month(a.SO_LOCAL_CREATE_ON_D)
                     , year(a.SO_LOCAL_CREATE_ON_D)
                     , TO_VARCHAR(TO_DATE(a.SO_LOCAL_CREATE_ON_D), 'YYYYMM')
                     , a.plant
                     , substring(transport_zone, 3, 2)
                     , a.item_division
                     , z.division
                     , z.product_group_1   
                     , z.seda_bu_estore
                     , z.seda_division_estore
                     , z.seda_category_estore
             ) a
             
      group by subsidiary
             , month
             , year
             , referencia
             , plant
             , transport_zone_destination
             , item_division
             , dimprod_division
             , dimprod_product_group    
             , dimprod_seda_bu_estore
             , dimprod_seda_division_estore
             , dimprod_seda_category_estore     
      );
      
      
    update OW_LAO.AUX_NERP_SALES_PROGRESS_KPI_INTENCTIVE_RULES a
       set So_Progress_Amount            = (a.So_Progress_Amount            * b.incentive_total)
         , So_Progress_Next_Month_Amount = (a.So_Progress_Next_Month_Amount * b.incentive_total)
         , Do_Progress_Amount            = (a.Do_Progress_Amount            * b.incentive_total)
         , GI_Progress_Amount            = (a.GI_Progress_Amount            * b.incentive_total)
         , In_Transit_Amount             = (a.In_Transit_Amount             * b.incentive_total)
         , InTransitNetTotalAmount       = (a.InTransitNetTotalAmount       * b.incentive_total)
         , InTransitNextMonthAmount      = (a.InTransitNextMonthAmount      * b.incentive_total)
      from OW_LAO.AUX_NERP_SALES_PROGRESS_KPI_INTENCTIVE_RULES a
      join OW_LAO."DIM_PLANT_DESTINATION_INCENTIVE"          b on b.plant    = a.plant
                                                                and b.division = a.item_division 
     where b.division_all                       = false
       and b.incentive_to_different_destination = false
       and a.transport_zone_destination         = 'SP'
       and a.transport_zone_destination         is not null;      
       
    update OW_LAO.AUX_NERP_SALES_PROGRESS_KPI_INTENCTIVE_RULES a
       set So_Progress_Amount            = (a.So_Progress_Amount            * b.incentive_total)
         , So_Progress_Next_Month_Amount = (a.So_Progress_Next_Month_Amount * b.incentive_total)
         , Do_Progress_Amount            = (a.Do_Progress_Amount            * b.incentive_total)
         , GI_Progress_Amount            = (a.GI_Progress_Amount            * b.incentive_total)
         , In_Transit_Amount             = (a.In_Transit_Amount             * b.incentive_total)
         , InTransitNetTotalAmount       = (a.InTransitNetTotalAmount       * b.incentive_total)
         , InTransitNextMonthAmount      = (a.InTransitNextMonthAmount      * b.incentive_total)
      from OW_LAO.AUX_NERP_SALES_PROGRESS_KPI_INTENCTIVE_RULES a
      join OW_LAO."DIM_PLANT_DESTINATION_INCENTIVE"          b on b.plant    = a.plant
                                                                and b.division = a.item_division 
     where b.division_all                       = false
       and b.incentive_to_different_destination = true
       and a.transport_zone_destination        != 'SP'
       and a.transport_zone_destination         is not null;      
       
    update OW_LAO.AUX_NERP_SALES_PROGRESS_KPI_INTENCTIVE_RULES a
       set So_Progress_Amount            = (a.So_Progress_Amount            * b.incentive_total)
         , So_Progress_Next_Month_Amount = (a.So_Progress_Next_Month_Amount * b.incentive_total)
         , Do_Progress_Amount            = (a.Do_Progress_Amount            * b.incentive_total)
         , GI_Progress_Amount            = (a.GI_Progress_Amount            * b.incentive_total)
         , In_Transit_Amount             = (a.In_Transit_Amount             * b.incentive_total)
         , InTransitNetTotalAmount       = (a.InTransitNetTotalAmount       * b.incentive_total)
         , InTransitNextMonthAmount      = (a.InTransitNextMonthAmount      * b.incentive_total)
      from OW_LAO.AUX_NERP_SALES_PROGRESS_KPI_INTENCTIVE_RULES a
      join OW_LAO."DIM_PLANT_DESTINATION_INCENTIVE"          b on b.plant    = a.plant
                                                                and b.division = a.item_division 
     where b.division_all                 = false
       and b.incentive_to_all_destination = true
       and a.transport_zone_destination   is not null;      
       
    update OW_LAO.AUX_NERP_SALES_PROGRESS_KPI_INTENCTIVE_RULES a
       set So_Progress_Amount            = (a.So_Progress_Amount            * b.incentive_total)
         , So_Progress_Next_Month_Amount = (a.So_Progress_Next_Month_Amount * b.incentive_total)
         , Do_Progress_Amount            = (a.Do_Progress_Amount            * b.incentive_total)
         , GI_Progress_Amount            = (a.GI_Progress_Amount            * b.incentive_total)
         , In_Transit_Amount             = (a.In_Transit_Amount             * b.incentive_total)
         , InTransitNetTotalAmount       = (a.InTransitNetTotalAmount       * b.incentive_total)
         , InTransitNextMonthAmount      = (a.InTransitNextMonthAmount      * b.incentive_total)
      from OW_LAO.AUX_NERP_SALES_PROGRESS_KPI_INTENCTIVE_RULES a
      join OW_LAO."DIM_PLANT_DESTINATION_INCENTIVE"          b on b.plant = a.plant
     where b.division_all                 = true
       and b.incentive_to_all_destination = true
       and a.transport_zone_destination   is not null;      
      
      
    
    create column table OW_LAO.AUX_NERP_SALES_PROGRESS_KPI as
    (
    
        select subsidiary
             , month
             , year
             , referencia
             , dimprod_division
             , dimprod_product_group
             , dimprod_seda_bu_estore
             , dimprod_seda_division_estore
             , dimprod_seda_category_estore
             , sum(So_Progress_Quantity)               as So_Progress_Quantity
             , sum(So_Progress_Amount)                 as So_Progress_Amount
             , sum(So_Progress_Next_Month_Quantity)    as So_Progress_Next_Month_Quantity
             , sum(So_Progress_Next_Month_Amount)      as So_Progress_Next_Month_Amount
             , sum(Do_Progress_Quantity)               as Do_Progress_Quantity
             , sum(Do_Progress_Amount)                 as Do_Progress_Amount
             , sum(GI_Progress_Quantity)               as GI_Progress_Quantity
             , sum(GI_Progress_Amount)                 as GI_Progress_Amount
             , sum(In_Transit_Quantity)                as In_Transit_Quantity
             , sum(In_Transit_Amount)                  as In_Transit_Amount
             , sum(billing_IOD_Progress_Quantity)      as billing_IOD_Progress_Quantity
             , sum(billing_IOD_Progress_Amount)        as billing_IOD_Progress_Amount
             , sum(billingIODProgressPreviousQuantity) as billingIODProgressPreviousQuantity
             , sum(billingIODProgressPreviousAmount)   as billingIODProgressPreviousAmount
             , sum(InTransitNetTotalQuantity)          as InTransitNetTotalQuantity
             , sum(InTransitNetTotalAmount)            as InTransitNetTotalAmount
             , sum(ForecastQuantity)                   as ForecastQuantity
             , sum(ForecastAmount)                     as ForecastAmount
             , sum(InTransitNextMonthQuantity)         as InTransitNextMonthQuantity
             , sum(InTransitNextMonthAmount)           as InTransitNextMonthAmount
          from (
                select subsidiary
                     , month
                     , year
                     , referencia
                     , dimprod_division
                     , dimprod_product_group
                     , dimprod_seda_bu_estore
                     , dimprod_seda_division_estore
                     , dimprod_seda_category_estore
                     , sum(So_Progress_Quantity)               as So_Progress_Quantity
                     , sum(So_Progress_Amount)                 as So_Progress_Amount
                     , sum(So_Progress_Next_Month_Quantity)    as So_Progress_Next_Month_Quantity
                     , sum(So_Progress_Next_Month_Amount)      as So_Progress_Next_Month_Amount
                     , sum(Do_Progress_Quantity)               as Do_Progress_Quantity
                     , sum(Do_Progress_Amount)                 as Do_Progress_Amount
                     , sum(GI_Progress_Quantity)               as GI_Progress_Quantity
                     , sum(GI_Progress_Amount)                 as GI_Progress_Amount
                     , sum(In_Transit_Quantity)                as In_Transit_Quantity
                     , sum(In_Transit_Amount)                  as In_Transit_Amount
                     , sum(billing_IOD_Progress_Quantity)      as billing_IOD_Progress_Quantity
                     , sum(billing_IOD_Progress_Amount)        as billing_IOD_Progress_Amount
                     , sum(billingIODProgressPreviousQuantity) as billingIODProgressPreviousQuantity
                     , sum(billingIODProgressPreviousAmount)   as billingIODProgressPreviousAmount
                     , sum(InTransitNetTotalQuantity)          as InTransitNetTotalQuantity
                     , sum(InTransitNetTotalAmount)            as InTransitNetTotalAmount
                     , 0                                       as ForecastQuantity
                     , 0                                       as ForecastAmount
                     , sum(InTransitNextMonthQuantity)         as InTransitNextMonthQuantity
                     , sum(InTransitNextMonthAmount)           as InTransitNextMonthAmount
                  from OW_LAO.AUX_NERP_SALES_PROGRESS_KPI_INTENCTIVE_RULES
              group by subsidiary
                     , month
                     , year
                     , referencia
                     , dimprod_division
                     , dimprod_product_group
                     , dimprod_seda_bu_estore
                     , dimprod_seda_division_estore
                     , dimprod_seda_category_estore
                
                union all                
                
                select c.subsidiary
                     , a.posting_period                       as month
                     , a.year                                 as year
                     , case
                            when length(a.posting_period) = 1
                            then concat(a.year, concat('0', a.posting_period))
                            else concat(a.year, a.posting_period) 
                        end                                   as referencia
                     , z.division                             as dimprod_division
                     , z.product_group_1                      as dimprod_product_group  
                     , z.seda_bu_estore                       as dimprod_seda_bu_estore       
                     , z.seda_division_estore                 as dimprod_seda_division_estore 
                     , z.seda_category_estore                 as dimprod_seda_category_estore 
                     , 0                                      as SoProgressQuantity
                     , 0                                      as SoProgressAmount
                     , cast(0    as int)                      as So_Progress_Next_Month_Quantity
                     , cast(0.00 as decimal)                  as So_Progress_Next_Month_Amount
                     , 0                                      as DoProgressQuantity
                     , 0                                      as DoProgressAmount
                     , 0                                      as GIProgressQuantity
                     , 0                                      as GIProgressAmount
                     , 0                                      as InTransitQuantity
                     , 0                                      as InTransitAmount
                     , sum(a.sales_qty)                       as billingIODProgressQuantity
                     , sum(a.amount_company_code_currency)    as billingIODProgressAmount
                     , 0                                      as billingIODProgressPreviousQuantity
                     , 0                                      as billingIODProgressPreviousAmount
                     , 0                                      as InTransitNetTotalQuantity
                     , 0                                      as InTransitNetTotalAmount
                     , 0                                      as ForecastQuantity
                     , 0                                      as ForecastAmount
                     , cast(0 as int)                         as InTransitNextMonthQuantity
                     , cast(0 as numeric(15,2))               as InTransitNextMonthAmount
                  from OW_LAO.ODS_NERP_ZKE24_DISPLAY_ACTUAL_LINE_ITEMS a
	                  INNER join OW_MD.DIM_SUBSIDIARY c on c.company_code = a.company_code
	                  /***********************
	                  INNER join OW_LAO.ODS_NERP_ZRSDD6A120_SALES_ORDER_TRACKING b on b.sales_document = a.sales_order
	                                                                          and b.material = a.product
	                                                                          and month(b.SO_LOCAL_CREATE_ON_D) = a.posting_period
	                                                                          and year(b.SO_LOCAL_CREATE_ON_D)  = a.year
	                                                                          and c.sales_org = b.sales_org
	                  ***********************/	                  
	                  --/***********************
	                  INNER join OW_LAO.TMP_SOT_SALES_PROGRESS_KPI b on b.sales_document = CAST(a.sales_order AS varchar(70)) --b on b.sales_document = a.sales_order
	                                                                          and b.material = a.product
	                                                                          and month(b.SO_LOCAL_CREATE_ON_D) = a.posting_period
	                                                                          and year(b.SO_LOCAL_CREATE_ON_D)  = a.year
	                                                                          and c.sales_org = b.sales_org
	                   --***********************/
             		  left join OW_MD.DIM_PRODUCT z on z.sku = a.product
              where c.sur_key_subsidiary = 1 -- SEDA
              group by c.subsidiary
                     , a.year
                     , a.posting_period   
                     , z.division
                     , z.product_group_1      
                     , z.seda_bu_estore
                     , z.seda_division_estore
                     , z.seda_category_estore 
                     
                 union all
                 
                select b.subsidiary
                     , a.posting_period                       as month
                     , a.year                                 as year
                     , case
                            when length(a.posting_period) = 1
                            then concat(a.year, concat('0', a.posting_period))
                            else concat(a.year, a.posting_period) 
                        end                                   as referencia
                     , z.division                             as dimprod_division
                     , z.product_group_1                      as dimprod_product_group  
                     , z.seda_bu_estore                       as dimprod_seda_bu_estore       
                     , z.seda_division_estore                 as dimprod_seda_division_estore 
                     , z.seda_category_estore                 as dimprod_seda_category_estore 
                     , 0                                      as SoProgressQuantity
                     , 0                                      as SoProgressAmount
                     , cast(0    as int)                      as So_Progress_Next_Month_Quantity
                     , cast(0.00 as decimal)                  as So_Progress_Next_Month_Amount
                     , 0                                      as DoProgressQuantity
                     , 0                                      as DoProgressAmount
                     , 0                                      as GIProgressQuantity
                     , 0                                      as GIProgressAmount
                     , 0                                      as InTransitQuantity
                     , 0                                      as InTransitAmount
                     , sum(a.sales_qty)                       as billingIODProgressQuantity
                     , sum(a.amount_company_code_currency)    as billingIODProgressAmount
                     , 0                                      as billingIODProgressPreviousQuantity
                     , 0                                      as billingIODProgressPreviousAmount
                     , 0                                      as InTransitNetTotalQuantity
                     , 0                                      as InTransitNetTotalAmount
                     , 0                                      as ForecastQuantity
                     , 0                                      as ForecastAmount
                     , cast(0 as int)                         as InTransitNextMonthQuantity
                     , cast(0 as numeric(15,2))               as InTransitNextMonthAmount
                  from OW_LAO.ODS_NERP_ZKE24_DISPLAY_ACTUAL_LINE_ITEMS a
                  join "OW_MD"."DIM_SUBSIDIARY"                          b on b.company_code = a.company_code
             left join OW_MD.DIM_PRODUCT                                 z on z.sku          = a.product
                 where a.sales_order is null
                   and b.sur_key_subsidiary = 1 -- SEDA
              group by b.subsidiary
                     , a.year
                     , a.posting_period   
                     , z.division
                     , z.product_group_1    
                     , z.seda_bu_estore
                     , z.seda_division_estore
                     , z.seda_category_estore
                     
                 union all
                 
                select c.subsidiary
                     , a.posting_period                       as month
                     , a.year                                 as year
                     , case
                            when length(a.posting_period) = 1
                            then concat(a.year, concat('0', a.posting_period))
                            else concat(a.year, a.posting_period) 
                        end                                   as referencia
                     , z.division                             as dimprod_division
                     , z.product_group_1                      as dimprod_product_group  
                     , z.seda_bu_estore                       as dimprod_seda_bu_estore       
                     , z.seda_division_estore                 as dimprod_seda_division_estore 
                     , z.seda_category_estore                 as dimprod_seda_category_estore 
                     , 0                                      as SoProgressQuantity
                     , 0                                      as SoProgressAmount
                     , cast(0    as int)                      as So_Progress_Next_Month_Quantity
                     , cast(0.00 as decimal)                  as So_Progress_Next_Month_Amount
                     , 0                                      as DoProgressQuantity
                     , 0                                      as DoProgressAmount
                     , 0                                      as GIProgressQuantity
                     , 0                                      as GIProgressAmount
                     , 0                                      as InTransitQuantity
                     , 0                                      as InTransitAmount
                     , 0                                      as billingIODProgressQuantity
                     , 0                                      as billingIODProgressAmount
                     , sum(a.sales_qty)                       as billingIODProgressPreviousQuantity
                     , sum(a.amount_company_code_currency)    as billingIODProgressPreviousAmount
                     , 0                                      as InTransitNetTotalQuantity
                     , 0                                      as InTransitNetTotalAmount
                     , 0                                      as ForecastQuantity
                     , 0                                      as ForecastAmount
                     , cast(0 as int)                         as InTransitNextMonthQuantity
                     , cast(0 as numeric(15,2))               as InTransitNextMonthAmount
                  from OW_LAO.ODS_NERP_ZKE24_DISPLAY_ACTUAL_LINE_ITEMS a
                  join "OW_MD"."DIM_SUBSIDIARY"                          c on c.company_code = a.company_code
                  /*****************
                  join OW_LAO.ODS_NERP_ZRSDD6A120_SALES_ORDER_TRACKING b on b.sales_document = a.sales_order
                                                                          and b.material                    = a.product
                                                                          and b.SO_LOCAL_CREATE_ON_D < to_date(concat( concat( a.year, concat(CASE WHEN a.posting_period BETWEEN 1 AND 9 THEN '0' ELSE '' END, a.posting_period) ),'01'))
                                                                          -- and month(b.SO_LOCAL_CREATE_ON_D) < a.posting_period
                                                                          -- and  year(b.SO_LOCAL_CREATE_ON_D) = a.year
                                                                          and c.sales_org                   = b.sales_org
                  **********************/
                  --/*****************
	              join OW_LAO.TMP_SOT_SALES_PROGRESS_KPI b on b.sales_document = CAST(a.sales_order AS varchar(70)) -- b.sales_document = a.sales_order
                                                                          and b.material = a.product
                                                                          and b.SO_LOCAL_CREATE_ON_D < to_date(concat( concat( a.year, concat(CASE WHEN a.posting_period BETWEEN 1 AND 9 THEN '0' ELSE '' END, a.posting_period) ),'01'))
                                                                          and c.sales_org = b.sales_org
                  --**********************/
             	  left join OW_MD.DIM_PRODUCT z on z.sku = a.product
              where c.sur_key_subsidiary = 1 -- SEDA
              group by c.subsidiary
                     , a.year
                     , a.posting_period   
                     , z.division
                     , z.product_group_1    
                     , z.seda_bu_estore
                     , z.seda_division_estore
                     , z.seda_category_estore
                     
                 union all
                 
                select b.subsidiary                           as subsidiary
                     , a.month                                as month
                     , a.year                                 as year
                     , concat(a.year, a.month)                as referencia
                     , z.division                             as dimprod_division
                     , z.product_group_1                      as dimprod_product_group  
                     , z.seda_bu_estore                       as dimprod_seda_bu_estore       
                     , z.seda_division_estore                 as dimprod_seda_division_estore 
                     , z.seda_category_estore                 as dimprod_seda_category_estore 
                     , 0                                      as SoProgressQuantity
                     , 0                                      as SoProgressAmount
                     , cast(0    as int)                      as So_Progress_Next_Month_Quantity
                     , cast(0.00 as decimal)                  as So_Progress_Next_Month_Amount
                     , 0                                      as DoProgressQuantity
                     , 0                                      as DoProgressAmount
                     , 0                                      as GIProgressQuantity
                     , 0                                      as GIProgressAmount
                     , 0                                      as InTransitQuantity
                     , 0                                      as InTransitAmount
                     , 0                                      as billingIODProgressQuantity
                     , 0                                      as billingIODProgressAmount
                     , 0                                      as billingIODProgressPreviousQuantity
                     , 0                                      as billingIODProgressPreviousAmount
                     , 0                                      as InTransitNetTotalQuantity
                     , 0                                      as InTransitNetTotalAmount
                     , sum(a.quantity_net)                    as ForecastQuantity
                     , sum(a.net_sales)                       as ForecastAmount
                     , cast(0 as int)                         as InTransitNextMonthQuantity
                     , cast(0 as numeric(15,2))               as InTransitNextMonthAmount
                  from OW_LAO.RAW_NERP_ZRCOA20250_FORECAST_SALES_DEDUP a
                  join "OW_MD"."DIM_SUBSIDIARY"                        b on b.sales_org = a.sales_organization
             left join OW_MD.DIM_PRODUCT                               z on z.sku       = a.product_number
                 where b.sur_key_subsidiary = 1 -- SEDA
              group by b.subsidiary
                     , a.year
                     , a.month 
                     , z.division
                     , z.product_group_1    
                     , z.seda_bu_estore
                     , z.seda_division_estore
                     , z.seda_category_estore
             ) a
             
      group by subsidiary
             , month
             , year
             , referencia
             , dimprod_division
             , dimprod_product_group    
             , dimprod_seda_bu_estore
             , dimprod_seda_division_estore
             , dimprod_seda_category_estore     
      );         
        
     
    create column table OW_LAO.AUX_NERP_SALES_PROGRESS_KPI_TARGET as
    (   
    --/**********************
       SELECT
		  SP.*
		 ,TA.TARGET_QTY AS TARGET_QTY
		 ,TA.TARGET_AMOUNT AS TARGET_AMOUNT
		 ,CAST(0.0000 as decimal) AS exchange_rate_usd  
		FROM OW_LAO.AUX_NERP_SALES_PROGRESS_KPI SP
			LEFT JOIN (
				SELECT 
					  TAR."YEAR"
					, TAR."MONTH"
					, PRD.DIVISION AS DIMPROD_DIVISION
					, PRD.PRODUCT_GROUP_1 AS DIMPROD_PRODUCT_GROUP
					, PRD.SEDA_BU_ESTORE AS DIMPROD_SEDA_BU_ESTORE
					, PRD.SEDA_DIVISION_ESTORE AS DIMPROD_SEDA_DIVISION_ESTORE
					, PRD.SEDA_CATEGORY_ESTORE AS DIMPROD_SEDA_CATEGORY_ESTORE
					, SUM(CAST(TAR.QTY as decimal)) AS TARGET_QTY
					, SUM(CAST(TAR.AMOUNT as decimal)) TARGET_AMOUNT
				FROM OW_LAO.VIEW_NERP_ZRCOS43400_TARGET TAR
					INNER JOIN OW_MD.DIM_PRODUCT PRD ON PRD.SKU = TAR.MATERIAL
				WHERE UPPER(TAR.COMPANY_CODE_DESC) = 'SEDA' -- SOMENTE SEDA
				GROUP BY 
					  TAR."YEAR"
					, TAR."MONTH"
					, PRD.DIVISION --AS DIMPROD_DIVISION
					, PRD.PRODUCT_GROUP_1 --AS DIMPROD_PRODUCT_GROUP
					, PRD.SEDA_BU_ESTORE --AS DIMPROD_SEDA_BU_ESTORE
					, PRD.SEDA_DIVISION_ESTORE --AS DIMPROD_SEDA_DIVISION_ESTORE
					, PRD.SEDA_CATEGORY_ESTORE --AS DIMPROD_SEDA_CATEGORY_ESTORE
				--HAVING 	
				--	 SUM(CAST(TAR.QTY as decimal)) > 0
				--	and SUM(CAST(TAR.AMOUNT as decimal)) > 0					
			) TA ON TA.YEAR = SP.YEAR
					AND TA.MONTH = SP.MONTH
					AND TA.DIMPROD_DIVISION = SP.DIMPROD_DIVISION
					AND TA.DIMPROD_PRODUCT_GROUP = SP.DIMPROD_PRODUCT_GROUP
					AND TA.DIMPROD_SEDA_BU_ESTORE = SP.DIMPROD_SEDA_BU_ESTORE
					AND TA.DIMPROD_SEDA_DIVISION_ESTORE = SP.DIMPROD_SEDA_DIVISION_ESTORE
					AND TA.DIMPROD_SEDA_CATEGORY_ESTORE = SP.DIMPROD_SEDA_CATEGORY_ESTORE	    
	--***********************/		
    /**********************
        select a.*
             , b.target_qty
             , b.target_amount
             , cast(0.0000 as decimal)        as exchange_rate_usd
          from OW_LAO.AUX_NERP_SALES_PROGRESS_KPI                                                            a
     left join OW_LAO.TF_NERP_ZRCOS43400_DISPLAY_SELL_OUT_PLAN_SALES_PROGRESS_KPI_UNPIVOT_AGG_DIVISION_GROUP b on b.year                         = a.year
                                                                                                              and b.month                        = a.month
                                                                                                              and b.dimprod_division             = a.dimprod_division
                                                                                                              and b.dimprod_product_group        = a.dimprod_product_group
                                                                                                              and b.dimprod_seda_bu_estore       = a.dimprod_seda_bu_estore
                                                                                                              and b.dimprod_seda_division_estore = a.dimprod_seda_division_estore
                                                                                                              and b.dimprod_seda_category_estore = a.dimprod_seda_category_estore                                                                                                             
    --***********************/
    );
    
    
   insert into OW_LAO.AUX_NERP_SALES_PROGRESS_KPI_TARGET
    
        select 'SEDA' as subsidiary
             , b.month
             , b.year
             , case
                    when length(b.month) = 1
                    then concat(b.year, concat('0', b.month))
                    else concat(b.year, b.month) 
                end as referencia
             , b.dimprod_division
             , b.dimprod_product_group
             , b.dimprod_seda_bu_estore
             , b.dimprod_seda_division_estore
             , b.dimprod_seda_category_estore
             , 0 as So_Progress_Quantity
             , 0 as So_Progress_Amount
             , 0 as So_Progress_Next_Month_Quantity
             , 0 as So_Progress_Next_Month_Amount
             , 0 as Do_Progress_Quantity
             , 0 as Do_Progress_Amount
             , 0 as GI_Progress_Quantity
             , 0 as GI_Progress_Amount
             , 0 as In_Transit_Quantity
             , 0 as In_Transit_Amount
             , 0 as billing_IOD_Progress_Quantity
             , 0 as billing_IOD_Progress_Amount
             , 0 as billingIODProgressPreviousQuantity
             , 0 as billingIODProgressPreviousAmount
             , 0 as InTransitNetTotalQuantity
             , 0 as InTransitNetTotalAmount
             , 0 as ForecastQuantity
             , 0 as ForecastAmount
             , cast(0 as int) as InTransitNextMonthQuantity
             , cast(0 as numeric(15,2)) as InTransitNextMonthAmount
             
             , sum(b.target_qty) as target_qty
             , sum(b.target_amount) as target_amount
             , cast(0.0000 as decimal) as exchange_rate_usd
    FROM
    /******
     OW_LAO.TF_NERP_ZRCOS43400_DISPLAY_SELL_OUT_PLAN_SALES_PROGRESS_KPI_UNPIVOT_AGG_DIVISION_GROUP b
    --******/
    --/******
	  (
			SELECT 
				  TAR."YEAR"
				, TAR."MONTH"
				, PRD.DIVISION AS DIMPROD_DIVISION
				, PRD.PRODUCT_GROUP_1 AS DIMPROD_PRODUCT_GROUP
				, PRD.SEDA_BU_ESTORE AS DIMPROD_SEDA_BU_ESTORE
				, PRD.SEDA_DIVISION_ESTORE AS DIMPROD_SEDA_DIVISION_ESTORE
				, PRD.SEDA_CATEGORY_ESTORE AS DIMPROD_SEDA_CATEGORY_ESTORE
				, SUM(CAST(TAR.QTY as decimal)) AS TARGET_QTY
				, SUM(CAST(TAR.AMOUNT as decimal)) TARGET_AMOUNT
			FROM OW_LAO.VIEW_NERP_ZRCOS43400_TARGET TAR
				INNER JOIN OW_MD.DIM_PRODUCT PRD ON PRD.SKU = TAR.MATERIAL
 				INNER JOIN (
 					SELECT DISTINCT
 						 "YEAR" 
 						,"MONTH"
 					FROM OW_LAO.AUX_NERP_SALES_PROGRESS_KPI_TARGET
 				) DT ON 1=1
					AND TAR."YEAR" = DT."YEAR"
		       		AND TAR."MONTH" = DT."MONTH"			
			WHERE UPPER(TAR.COMPANY_CODE_DESC) = 'SEDA' -- SOMENTE SEDA
			GROUP BY 
				  TAR."YEAR"
				, TAR."MONTH"
				, PRD.DIVISION --AS DIMPROD_DIVISION
				, PRD.PRODUCT_GROUP_1 --AS DIMPROD_PRODUCT_GROUP
				, PRD.SEDA_BU_ESTORE --AS DIMPROD_SEDA_BU_ESTORE
				, PRD.SEDA_DIVISION_ESTORE --AS DIMPROD_SEDA_DIVISION_ESTORE
				, PRD.SEDA_CATEGORY_ESTORE --AS DIMPROD_SEDA_CATEGORY_ESTORE
			--HAVING 	
			--	 SUM(CAST(TAR.QTY as decimal)) > 0
			--	 AND SUM(CAST(TAR.AMOUNT as decimal)) > 0
		)  b
	--******/
	 where 1 = 1
	       and not exists(
	                select 1
	                from OW_LAO.AUX_NERP_SALES_PROGRESS_KPI a
	                where b.year = a.year
	                   and b.month = a.month
	                   and b.dimprod_division = a.dimprod_division
	                   and b.dimprod_product_group = a.dimprod_product_group
	                   and b.dimprod_seda_bu_estore = a.dimprod_seda_bu_estore
	                   and b.dimprod_seda_division_estore = a.dimprod_seda_division_estore
	                   and b.dimprod_seda_category_estore = a.dimprod_seda_category_estore  
	            ) 
    group by
		b.month
        , b.year
        , case
                when length(b.month) = 1
                then concat(b.year, concat('0', b.month))
                else concat(b.year, b.month) 
          end
         , b.dimprod_division
         , b.dimprod_product_group
         , b.dimprod_seda_bu_estore
         , b.dimprod_seda_division_estore
         , b.dimprod_seda_category_estore  
      ;
    
    
     create column table OW_LAO.TF_AP2_EXCHANGE_RATE_END_OF_MONTH as
    (  
          select year(valid_from)   year
               , month(valid_from)  month
               , row_number()
                    over(partition by year(valid_from), month(valid_from), to_currency
                            order by valid_from desc)                                       as dedup 
               , 'SEDA'                                                                     as subsidiary
               , cast(exchange_rate as decimal)                                             as exchange_rate
            from OW_LAO.FT_AP2_EXCHANGE_RATE 
           where to_currency = 'BRL'
           
    );         
    
        delete
        from OW_LAO.TF_AP2_EXCHANGE_RATE_END_OF_MONTH
        where dedup != 1;
         
        insert into OW_LAO.TF_AP2_EXCHANGE_RATE_END_OF_MONTH
        
        select year(current_date)             as year
             , month(current_date)            as month
             , 1                              as dedup
             , 'SEDA'                         as subsidiary
             , cast(exchange_rate as decimal) as exchange_rate
          from OW_LAO.TF_AP2_EXCHANGE_RATE_END_OF_MONTH a
         where last_day(add_months(current_date, -1)) = case
                                                            when length(a.month) = 1
                                                            then last_day(to_date(concat(a.year, concat('0', a.month))))
                                                            else last_day(to_date(concat(a.year, a.month))) 
                                                         end
           and not exists(         
                     select 1
                       from OW_LAO.TF_AP2_EXCHANGE_RATE_END_OF_MONTH
                      where year(current_date)  = year
                        and month(current_date) = month
               );
 
 
 update OW_LAO.AUX_NERP_SALES_PROGRESS_KPI_TARGET a
        set exchange_rate_usd = coalesce(b.exchange_rate, 0.0000)
       from OW_LAO.AUX_NERP_SALES_PROGRESS_KPI_TARGET a
 left join OW_LAO.TF_AP2_EXCHANGE_RATE_END_OF_MONTH  b 
 		on b.year       = a.year
	       and b.month      = a.month
	       and b.subsidiary = a.subsidiary
 ;  
create column table OW_LAO.TF_NERP_SALES_PROGRESS_KPI 
    as (             
	 SELECT 
		  subsidiary
		, dimprod_division
		, dimprod_product_group
		, dimprod_seda_bu_estore
		, dimprod_seda_division_estore
		, dimprod_seda_category_estore
		, year
		, referencia
		, MAP(element_number,
			   1, 'QTY'
			,  2, 'QTY'
			,  3, 'QTY'
			,  4, 'QTY'
			,  5, 'QTY'
			,  6, 'QTY'
			,  7, 'QTY'
			,  8, 'QTY'
			,  9, 'AMT_Local'
			, 10, 'AMT_Local'
			, 11, 'AMT_Local'
			, 12, 'AMT_Local'
			, 13, 'AMT_Local'
			, 14, 'AMT_Local'
			, 15, 'AMT_Local'
			, 16, 'AMT_Local'
			, 17, 'AMT_USD'
			, 18, 'AMT_USD'
			, 19, 'AMT_USD'
			, 20, 'AMT_USD'
			, 21, 'AMT_USD'
			, 22, 'AMT_USD'
			, 23, 'AMT_USD'
			, 24, 'AMT_USD'
			, 25, 'AMT_Local'
			, 26, 'QTY'
			, 27, 'AMT_Local'
			, 28, 'AMT_USD'
			, 29, 'QTY'
			, 30, 'AMT_Local'
			, 31, 'AMT_USD'
			, 32, 'QTY'
			, 33, 'AMT_Local'
			, 34, 'AMT_USD'
		) AS measure_type
		, MAP(element_number,
			   1, 'SO Progress'
			,  2, 'DO Progress'
			,  3, 'GI Progress' 
			,  4, 'In Transit'
			,  5, 'In Transit Net Total'
			,  6, 'Billing (IOD)'
			,  7, 'Billing (IOD) Previous' 
			,  8, 'Target'  
			,  9, 'SO Progress'
			, 10, 'DO Progress'
			, 11, 'GI Progress' 
			, 12, 'In Transit'
			, 13, 'In Transit Net Total'
			, 14, 'Billing (IOD)'
			, 15, 'Billing (IOD) Previous' 
			, 16, 'Target'  
			, 17, 'SO Progress'
			, 18, 'DO Progress'
			, 19, 'GI Progress' 
			, 20, 'In Transit'
			, 21, 'In Transit Net Total'
			, 22, 'Billing (IOD)'
			, 23, 'Billing (IOD) Previous' 
			, 24, 'Target'  
			, 25, 'exchange_rate' 
			, 26, 'SO Progress Next Month' 
			, 27, 'SO Progress Next Month'  
			, 28, 'SO Progress Next Month'  
			, 29, 'Forecast'
			, 30, 'Forecast'
			, 31, 'Forecast'   
			, 32, 'In Transit Next Month'
			, 33, 'In Transit Next Month'
			, 34, 'In Transit Next Month'       
		) AS measure_desc
		, MAP(element_number ,
			   1, So_Progress_Quantity
			,  2, Do_Progress_Quantity
			,  3, GI_Progress_Quantity
			,  4, In_Transit_Quantity
			,  5, InTransitNetTotalQuantity              
			,  6, billing_IOD_Progress_Quantity          
			,  7, billingIODProgressPreviousQuantity     
			,  8, target_qty             
			,  9, So_Progress_Amount                     
			, 10, Do_Progress_Amount                     
			, 11, GI_Progress_Amount                     
			, 12, In_Transit_Amount                      
			, 13, InTransitNetTotalAmount                
			, 14, billing_IOD_Progress_Amount            
			, 15, billingIODProgressPreviousAmount       
			, 16, target_amount                        
			, 17, ( So_Progress_Amount / exchange_rate_usd )
			, 18, ( Do_Progress_Amount / exchange_rate_usd )
			, 19, ( GI_Progress_Amount / exchange_rate_usd )
			, 20, ( In_Transit_Amount / exchange_rate_usd )
			, 21, ( InTransitNetTotalAmount / exchange_rate_usd )
			, 22, ( billing_IOD_Progress_Amount / exchange_rate_usd )
			, 23, ( billingIODProgressPreviousAmount / exchange_rate_usd )
			, 24, ( target_amount / exchange_rate_usd )  
			, 25, exchange_rate_usd 
			, 26, So_Progress_Next_Month_Quantity
			, 27, So_Progress_Next_Month_Amount
			, 28, ( So_Progress_Next_Month_Amount / exchange_rate_usd )  
			, 29, ForecastQuantity
			, 30, ForecastAmount
			, 31, ( ForecastAmount / exchange_rate_usd )  
			, 32, InTransitNextMonthQuantity
			, 33, InTransitNextMonthAmount
			, 34, ( InTransitNextMonthAmount / exchange_rate_usd )              
		) AS measure_value
	FROM OW_LAO.AUX_NERP_SALES_PROGRESS_KPI_TARGET
          , SERIES_GENERATE_INTEGER(1, 1, 35)
   order by subsidiary
          , dimprod_division
          , dimprod_product_group
          , dimprod_seda_bu_estore
          , dimprod_seda_division_estore
          , dimprod_seda_category_estore
          , year
          , referencia
   );
   
 
 create column table OW_LAO.FT_NERP_SALES_PROGRESS_KPI 
    as ( 
      
            select a.subsidiary
                 , coalesce(a.dimprod_division            , '') as dimprod_division
                 , coalesce(a.dimprod_product_group       , '') as dimprod_product_group
                 , coalesce(a.dimprod_seda_bu_estore      , '') as dimprod_seda_bu_estore
                 , coalesce(a.dimprod_seda_division_estore, '') as dimprod_seda_division_estore
                 , coalesce(a.dimprod_seda_category_estore, '') as dimprod_seda_category_estore
                 , a.year
                 , a.referencia
                 , a.measure_type
                 , a.measure_desc
                 , a.measure_value
                 , current_timestamp                            as KPI_LAST_UPDATE
              from OW_LAO.TF_NERP_SALES_PROGRESS_KPI a
   );
   
     insert into OW_LAO.FT_NERP_SALES_PROGRESS_KPI
   
     select coalesce(a.subsidiary                  , 'Total') as subsidiary
          , coalesce(a.dimprod_division            , 'Total') as dimprod_division
          , coalesce(a.dimprod_product_group       , 'Total') as dimprod_product_group
          , coalesce(a.dimprod_seda_bu_estore      , 'Total') as dimprod_seda_bu_estore
          , coalesce(a.dimprod_seda_division_estore, 'Total') as dimprod_seda_division_estore
          , 'Total' as dimprod_seda_category_estore
          , a.year
          , a.referencia
          , a.measure_type
          , a.measure_desc
          , sum(a.measure_value)                              as measure_value
          , current_timestamp                                 as KPI_LAST_UPDATE
       from OW_LAO.FT_NERP_SALES_PROGRESS_KPI a
      --where 1 = 1
        --and referencia            = '202305'
        --and dimprod_division      in ( 'DA')
        --and dimprod_product_group = 'WEARABLE'  
        --and a.measure_type = 'AMT_Local'  
        --and a.measure_desc = 'Target'
       -- and a.dimprod_division is not null
   group by grouping sets (
             -- (a.year, a.referencia,  a.measure_type, a.measure_desc), --  total geral, para quando tiver mais de uma subsidiaria
            (a.year, a.referencia, a.subsidiary, a.measure_type, a.measure_desc)
          , (a.year, a.referencia, a.subsidiary, a.dimprod_division, a.measure_type, a.measure_desc)
          , (a.year, a.referencia, a.subsidiary, a.dimprod_division, a.dimprod_product_group, a.measure_type, a.measure_desc)
          , (a.year, a.referencia, a.subsidiary, a.dimprod_division, a.dimprod_product_group, a.dimprod_seda_bu_estore, a.measure_type, a.measure_desc)
          , (a.year, a.referencia, a.subsidiary, a.dimprod_division, a.dimprod_product_group, a.dimprod_seda_bu_estore, a.dimprod_seda_division_estore, a.measure_type, a.measure_desc)
   )
   order by a.year
          , a.referencia
          , a.subsidiary
          , a.dimprod_division
          , a.dimprod_product_group
          , a.dimprod_seda_bu_estore
          , a.dimprod_seda_division_estore
          , a.measure_type
          , a.measure_desc;
END