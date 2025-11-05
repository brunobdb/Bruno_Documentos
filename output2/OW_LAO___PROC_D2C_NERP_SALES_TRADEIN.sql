/***********************************************************************************************
CREATED BY : Luciano Mariani
CREATION DATE : 2023-11-13
ALTER BY : Luciano Mariani
ALTER DATE : 2023-12-15
CALL OW_LAO.PROC_D2C_NERP_SALES_TRADEIN ( ADD_DAYS(CURRENT_TIMESTAMP, -1),  ADD_DAYS(CURRENT_TIMESTAMP, 2))
SELECT * FROM OW_LAO.TF_D2C_PO_VTEX_TRADE_IN
***********************************************************************************************/
CREATE PROCEDURE OW_LAO.PROC_D2C_NERP_SALES_TRADEIN(
	  p_DATE_INI DATE DEFAULT NULL
	, P_DATE_FIM DATE DEFAULT NULL
) LANGUAGE SQLSCRIPT
AS
BEGIN
	
	/*********************************************************
	* CRIA A TMP_PARAMETER_VTEX_TRADEIN
	* *******************************************************/
	 IF EXISTS ( SELECT TABLE_NAME FROM SYS.TABLES WHERE SCHEMA_NAME = 'OW_LAO' AND TABLE_NAME = 'TMP_PARAMETER_VTEX_TRADEIN' ) THEN
		DROP TABLE OW_LAO.TMP_PARAMETER_VTEX_TRADEIN;
	 END IF ;
	 CREATE COLUMN TABLE OW_LAO.TMP_PARAMETER_VTEX_TRADEIN AS (
		SELECT ADD_DAYS(CURRENT_TIMESTAMP, -15) AS DATE_INI, ADD_DAYS(CURRENT_TIMESTAMP, 2) AS DATE_FIM FROM DUMMY
	 );
	 UPDATE OW_LAO.TMP_PARAMETER_VTEX_TRADEIN SET
		 DATE_INI = IFNULL(p_DATE_INI, ADD_DAYS(CURRENT_TIMESTAMP, -30)) -- 30 dias dafault
		,DATE_FIM = IFNULL(P_DATE_FIM, ADD_DAYS(CURRENT_TIMESTAMP, 2)) 
	 ;
	 
	 /*********************************************************
	 * TABELA TEMPORÁRIA - TMP_PO_ORDER_ID_PO_VTEX_TRADE_IN
	 * SEPARA ORDER QUE SERÃO BUSCADAS NA VTEX
	 * E CLASSIFICA O CUSTOMER_PO
	 * *******************************************************/
	  IF EXISTS( SELECT TABLE_NAME FROM SYS.TABLES WHERE SCHEMA_NAME = 'OW_LAO' AND TABLE_NAME = 'TMP_PO_ORDER_ID_PO_VTEX_TRADE_IN') THEN
	        DROP TABLE OW_LAO.TMP_PO_ORDER_ID_PO_VTEX_TRADE_IN;
	  END IF;
	  CREATE COLUMN TABLE OW_LAO.TMP_PO_ORDER_ID_PO_VTEX_TRADE_IN AS(
	        SELECT V.ORDER_ID
				 , MAX( CASE WHEN S.CUSTOMER_PO IS NOT NULL THEN S.CUSTOMER_PO ELSE CAST("SEQUENCE" AS VARCHAR(100)) END ) AS CUSTOMER_PO
	        FROM U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER V
	              LEFT JOIN OW_LAO.ODS_NERP_ZRSDD6A120_SALES_ORDER_TRACKING S ON V.ORDER_ID = S.CUSTOMER_PO
	        --WHERE V.CREATION_TIMESTAMP BETWEEN ADD_DAYS(CURRENT_TIMESTAMP, -30) AND ADD_DAYS(CURRENT_TIMESTAMP, 10)
	        WHERE V.CREATION_TIMESTAMP BETWEEN ( SELECT DATE_INI FROM OW_LAO.TMP_PARAMETER_VTEX_TRADEIN ) AND (SELECT DATE_FIM FROM OW_LAO.TMP_PARAMETER_VTEX_TRADEIN )
	        	  AND V.STATUS IS NOT NULL
	        	  AND V.ORDER_ID <> '1413902933157-01'
	        GROUP BY
	              V.ORDER_ID
	  );
	  DROP TABLE OW_LAO.TMP_PARAMETER_VTEX_TRADEIN;
	 
	 /*********************************************************
	 * TABELA TEMPORÁRIA - TMP_ITEM_COMPONENTS_PO_VTEX_TRADE_IN
	 *  COMPONENTS (KITS) QUE SERÃO USADOS
	 * NAS 2 ETAPAS (ORDER SEM KITS E ORDERS COM KIT)
	 * *******************************************************/        
	  IF EXISTS( SELECT TABLE_NAME FROM SYS.TABLES WHERE SCHEMA_NAME = 'OW_LAO' AND TABLE_NAME = 'TMP_ITEM_COMPONENTS_PO_VTEX_TRADE_IN' ) THEN
	  	 DROP TABLE OW_LAO.TMP_ITEM_COMPONENTS_PO_VTEX_TRADE_IN;
	  END IF;
	  CREATE COLUMN TABLE OW_LAO.TMP_ITEM_COMPONENTS_PO_VTEX_TRADE_IN AS(
	        SELECT -- DISTINCT
	               CP.ORDER_ID
	              ,CP.SKU_ID
	              ,CP.SKU_ID_COMPONENT
	              ,CP.REF_ID
	              ,CP.NAME
	              ,CP.QUANTITY
	              ,CP.PRICE
	              ,CP.COST_PRICE
	        FROM U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER_ITEM_COMPONENTS CP
	              INNER JOIN OW_LAO.TMP_PO_ORDER_ID_PO_VTEX_TRADE_IN TP ON CP.ORDER_ID = TP.ORDER_ID
	        WHERE (CP.REF_ID IS NOT NULL)
	  );
	
	 /*********************************************************
	 * TABELA TEMPORÁRIA - TMP_PO_VTEX_TRADE_IN_DETAIL
	 * RETORNA OS DETALHES DAS ORDER NA VTEX
	 * SEPARADAS EM 2 ETAPAS (ORDER SEM KITS E ORDERS COM KIT)
	 * *******************************************************/
	IF EXISTS( SELECT TABLE_NAME FROM SYS.TABLES WHERE SCHEMA_NAME = 'OW_LAO' AND TABLE_NAME = 'TMP_PO_VTEX_TRADE_IN_DETAIL') THEN
		DROP TABLE OW_LAO.TMP_PO_VTEX_TRADE_IN_DETAIL;
	END IF;
	CREATE COLUMN TABLE OW_LAO.TMP_PO_VTEX_TRADE_IN_DETAIL AS(
		SELECT *		
		FROM (
             /*****************************************************************
                    PO (VTEX [SOMENTE ITENS]) {CREATION_TIMESTAMP}
             *****************************************************************/                  
              SELECT  TO_DATE(BSO.CREATION_TIMESTAMP) AS DATE_REF
                    , BSO.CREATION_TIMESTAMP AS PO_CREATION_DATE
                    , BSO.AFFILIATE_ID
                    , BSO.ORDER_ID
                    , BSO.MARKETPLACE_ORDER_ID
                    , BSO.HOSTNAME AS ENVIRONMENT
                    , BSO.STATUS AS STATUS_PO                       
                    ,	CASE
							  WHEN 
								   (CASE -- CD_STORE_INFORMATION
										 WHEN BSO.CD_STORE_INFORMATION IS NOT NULL THEN
											   BSO.CD_STORE_INFORMATION
										  ELSE
											   SSO.CD_STORE_INFORMATION
								   END) IS NOT NULL 
							  THEN
								   (CASE -- CD_STORE_INFORMATION
										 WHEN BSO.CD_STORE_INFORMATION IS NOT NULL THEN
											   BSO.CD_STORE_INFORMATION
										 ELSE
											   SSO.CD_STORE_INFORMATION
								   END)
							  ELSE
								   (CASE -- UTM_SOURCE
										 WHEN BSO.UTM_SOURCE IS NOT NULL THEN
											   BSO.UTM_SOURCE
										 ELSE
											   SSO.UTM_SOURCE
								   END)
						END AS STORE_ID
                    , BSO.SALES_CHANNEL
					,	CASE
							  WHEN BSO.CD_VENDEDOR IS NOT NULL THEN BSO.CD_VENDEDOR 
							  WHEN SSO.CD_VENDEDOR IS NOT NULL THEN SSO.CD_VENDEDOR
						END AS STORE_EMPLOYEE_CPF                           
                    , LI.CUSTOMER_PO                          
                    , BSI.ITEM_INDEX
                    , '' AS REFERENCE_CODE_KIT -- NULO PARA ITEM POIS NÃO É KIT
                    , BSI.REF_ID AS REFERENCE_CODE -- não é kit (item)
                    , BSI.NAME AS ITEM_NAME
                    --,(BSI.COST_PRICE / 100) AS PRICE_FROM
                    , (BSI.PRICE / 100) AS PRICE_TO
                    , CAST(BSI.QUANTITY AS INTEGER) AS QTY
                    , (CASE WHEN (BSO.TOTAL_DISCOUNTS <> 0 AND BSO.TOTAL_ITEMS > 0) THEN -- DESCONTOS
							  ( (BSI.PRICE * BSI.QUANTITY) / BSO.TOTAL_ITEMS ) * BSO.TOTAL_DISCOUNTS
						ELSE 0 END / 100) AS AMOUNT_DISCOUNT
						,(CASE WHEN (BSO.TOTAL_SHIPPING <> 0 AND BSO.TOTAL_ITEMS > 0) THEN -- FRETE
							  ( (BSI.PRICE * BSI.QUANTITY) / BSO.TOTAL_ITEMS ) * BSO.TOTAL_SHIPPING
						ELSE 0 END / 100) AS AMOUNT_SHIPPING                             
                    , CAST((
                               ( BSI.PRICE * BSI.QUANTITY ) 
                               + CASE WHEN (BSO.TOTAL_DISCOUNTS <> 0 AND BSO.TOTAL_ITEMS > 0) THEN -- (SUBTRAI OS DESCONTOS)
                                     ( (BSI.PRICE * BSI.QUANTITY) / BSO.TOTAL_ITEMS ) * BSO.TOTAL_DISCOUNTS
                               ELSE 0 END
                               + CASE WHEN (BSO.TOTAL_SHIPPING <> 0 AND BSO.TOTAL_ITEMS > 0) THEN -- FRETE SOMA O FRETE
                                     ( (BSI.PRICE * BSI.QUANTITY) / BSO.TOTAL_ITEMS ) * BSO.TOTAL_SHIPPING
                               ELSE 0 END
                          ) / 100
                    AS DECIMAL(18,2)) AS AMOUNT_LOCAL
                    
                    , IFNULL( IFNULL( EPI.SKU_ID ,SSI.SKU_ID ),BSI.SKU_ID) AS SKU_ID -- não é kit (item)
                    
                    , EPI.SKU_ID AS SKU_ID_EPP2
					, SSI.SKU_ID AS SKU_ID_SSG_BR
					, BSI.SKU_ID AS SKU_ID_BR_SHOP
                    , NULL AS SKU_ID_COMPONENT_EPP
					, NULL AS SKU_ID_COMPONENT_SSG_BR
					, NULL AS SKU_ID_COMPONENT_SHOP						
                    
                    , NULL AS SKU_ID_COMPONENT
								
					, IFNULL(IFNULL(
						( -- EPP2
							IFNULL(IFNULL(IFNULL(
							 CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[0].fields.eco_troca_products') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[0].fields.eco_troca_products')  END
							,CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[1].fields.eco_troca_products') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[1].fields.eco_troca_products')  END )
							,CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[2].fields.eco_troca_products') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[2].fields.eco_troca_products')  END )
							,CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[3].fields.eco_troca_products') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[3].fields.eco_troca_products')  END )
						 )
						,
						( -- SSG BR
							IFNULL(IFNULL(IFNULL(
							 CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[0].fields.eco_troca_products') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[0].fields.eco_troca_products')  END
							,CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[1].fields.eco_troca_products') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[1].fields.eco_troca_products')  END )
							,CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[2].fields.eco_troca_products') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[2].fields.eco_troca_products')  END )
							,CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[3].fields.eco_troca_products') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[3].fields.eco_troca_products')  END )
						 )
						),
						( -- BR SHOP 
							IFNULL(IFNULL(IFNULL(
							 CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[0].fields.eco_troca_products') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[0].fields.eco_troca_products') END
							,CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[1].fields.eco_troca_products') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[1].fields.eco_troca_products') END )
							,CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[2].fields.eco_troca_products') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[2].fields.eco_troca_products') END )
							,CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[3].fields.eco_troca_products') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[3].fields.eco_troca_products') END )
						 )
					 ) AS ECO_TROCA
					, IFNULL(IFNULL(
						( -- EPP2
							IFNULL(IFNULL(IFNULL(
							 CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[0].fields.trade_in_option_selected') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[0].fields.trade_in_option_selected') END
							,CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[1].fields.trade_in_option_selected') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[1].fields.trade_in_option_selected') END)
							,CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[2].fields.trade_in_option_selected') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[2].fields.trade_in_option_selected') END)
							,CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[3].fields.trade_in_option_selected') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[3].fields.trade_in_option_selected') END)
						 )
						,
						( -- SSG BR
							IFNULL(IFNULL(IFNULL(
							 CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[0].fields.trade_in_option_selected') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[0].fields.trade_in_option_selected') END
							,CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[1].fields.trade_in_option_selected') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[1].fields.trade_in_option_selected') END )
							,CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[2].fields.trade_in_option_selected') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[2].fields.trade_in_option_selected') END )
							,CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[3].fields.trade_in_option_selected') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[3].fields.trade_in_option_selected') END )
						 ) 						
						),
						( -- BR SHOP 
							IFNULL(IFNULL(IFNULL(
							 CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[0].fields.trade_in_option_selected') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[0].fields.trade_in_option_selected') END
							,CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[1].fields.trade_in_option_selected') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[1].fields.trade_in_option_selected') END)
							,CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[2].fields.trade_in_option_selected') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[2].fields.trade_in_option_selected') END)
							,CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[3].fields.trade_in_option_selected') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[3].fields.trade_in_option_selected') END)
						 ) 
					 )AS TRADE_IN_OPTION
					
					, IFNULL(IFNULL(
						( -- EPP2
							IFNULL(IFNULL(IFNULL(
							 CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[0].fields.trade_in_total_value') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[0].fields.trade_in_total_value') END
							,CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[1].fields.trade_in_total_value') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[1].fields.trade_in_total_value') END )
							,CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[2].fields.trade_in_total_value') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[2].fields.trade_in_total_value') END )
							,CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[3].fields.trade_in_total_value') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[3].fields.trade_in_total_value') END )
						 )
						,
						( -- SSG BR
							IFNULL(IFNULL(IFNULL(
							 CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[0].fields.trade_in_total_value') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[0].fields.trade_in_total_value') END
							,CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[1].fields.trade_in_total_value') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[1].fields.trade_in_total_value') END )
							,CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[2].fields.trade_in_total_value') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[2].fields.trade_in_total_value') END )
							,CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[3].fields.trade_in_total_value') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[3].fields.trade_in_total_value') END )
						 ) 						
						),
						( -- BR SHOP 
							IFNULL(IFNULL(IFNULL(
							 CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[0].fields.trade_in_total_value') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[0].fields.trade_in_total_value')  END
							,CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[1].fields.trade_in_total_value') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[1].fields.trade_in_total_value')  END )
							,CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[2].fields.trade_in_total_value') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[2].fields.trade_in_total_value')  END )
							,CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[3].fields.trade_in_total_value') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[3].fields.trade_in_total_value')  END )
						 ) 
					 ) AS TRADE_IN_TOTAL
					,	OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						
						OW_LAO.REPLACE_TEXT(
							IFNULL(IFNULL(
								 CASE WHEN (JSON_VALUE(EPO.OPEN_TEXT_FIELD, '$.value') IS NOT NULL) AND (JSON_VALUE(EPO.OPEN_TEXT_FIELD, '$.value') NOT IN ('[]','') ) THEN 
									( -- EPP2
										CASE WHEN JSON_VALUE(EPO.OPEN_TEXT_FIELD, '$.value')  LIKE '[%' THEN '' ELSE '[' END
										|| REPLACE(JSON_VALUE(EPO.OPEN_TEXT_FIELD, '$.value') ,'''', '"') ||
										CASE WHEN JSON_VALUE(EPO.OPEN_TEXT_FIELD, '$.value')  LIKE '%]' THEN '' ELSE ']' END
									)
								 END
								, CASE WHEN (JSON_VALUE(SSO.OPEN_TEXT_FIELD, '$.value') IS NOT NULL) AND (JSON_VALUE(SSO.OPEN_TEXT_FIELD, '$.value') NOT IN ('[]','') ) THEN 
									( -- SSG BR
										CASE WHEN JSON_VALUE(SSO.OPEN_TEXT_FIELD, '$.value')  LIKE '[%' THEN '' ELSE '[' END
										|| REPLACE(JSON_VALUE(SSO.OPEN_TEXT_FIELD, '$.value') ,'''', '"') ||
										CASE WHEN JSON_VALUE(SSO.OPEN_TEXT_FIELD, '$.value')  LIKE '%]' THEN '' ELSE ']' END								
									 ) 
								  END
								)
								, CASE WHEN (JSON_VALUE(BSO.OPEN_TEXT_FIELD, '$.value') IS NOT NULL) AND (JSON_VALUE(BSO.OPEN_TEXT_FIELD, '$.value') NOT IN ('[]','') ) THEN 
									( -- BR SHOP 
										CASE WHEN JSON_VALUE(BSO.OPEN_TEXT_FIELD, '$.value')  LIKE '[%' THEN '' ELSE '[' END
										|| REPLACE(JSON_VALUE(BSO.OPEN_TEXT_FIELD, '$.value') ,'''', '"') ||
										CASE WHEN JSON_VALUE(BSO.OPEN_TEXT_FIELD, '$.value')  LIKE '%]' THEN '' ELSE ']' END		
									 ) 
								  END
							 )
						
						,'[{ean":"','[{"ean":"',FALSE)
						
						,'0, }]', '0", }]',TRUE)
						,'1, }]', '1", }]',TRUE)
						,'2, }]', '2", }]',TRUE)
						,'3, }]', '3", }]',TRUE)
						,'4, }]', '4", }]',TRUE)
						,'5, }]', '5", }]',TRUE)
						,'6, }]', '6", }]',TRUE)
						,'7, }]', '7", }]',TRUE)
						,'8, }]', '8", }]',TRUE)
						,'9, }]', '9", }]',TRUE)
						,'0", }]', '0"}, ]',TRUE)
						,'1", }]', '1"}, ]',TRUE)
						,'2", }]', '2"}, ]',TRUE)
						,'3", }]', '3"}, ]',TRUE)
						,'4", }]', '4"}, ]',TRUE)
						,'5", }]', '5"}, ]',TRUE)
						,'6", }]', '6"}, ]',TRUE)
						,'7", }]', '7"}, ]',TRUE)
						,'8", }]', '8"}, ]',TRUE)
						,'9", }]', '9"}, ]',TRUE)					
					  AS TEXT_FIELD					
					, UPPER(IFNULL(IFNULL(EPO.COUPON, SSO.COUPON), BSO.COUPON)) AS COUPON
					, UPPER(IFNULL(IFNULL(EPO.MARKETING_TAGS, SSO.MARKETING_TAGS), BSO.MARKETING_TAGS)) AS MARKETING_TAGS
					, CASE 
						WHEN 
							-- EPP2
							OW_LAO.replace_text(
							   CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[0].id') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[0].id') || ' | ' ELSE '' END
							   || CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[1].id') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[1].id') || ' | ' ELSE '' END 
							   || CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[2].id') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[2].id') || ' | ' ELSE '' END 
							   || CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[3].id') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[3].id') || ' | ' ELSE '' END 
							, ' | ','',TRUE) <> ''
						THEN 
							-- EPP2
							OW_LAO.replace_text(
							   CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[0].id') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[0].id') || ' | ' ELSE '' END
							   || CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[1].id') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[1].id') || ' | ' ELSE '' END 
							   || CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[2].id') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[2].id') || ' | ' ELSE '' END 
							   || CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[3].id') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[3].id') || ' | ' ELSE '' END 
							, ' | ','',TRUE)
						WHEN
						  -- SSG BR
						  OW_LAO.replace_text(
							CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[0].id') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[0].id') || ' | ' ELSE '' END
								|| CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[1].id') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[1].id') || ' | ' ELSE '' END 
								|| CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[2].id') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[2].id') || ' | ' ELSE '' END 
								|| CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[3].id') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[3].id') || ' | ' ELSE '' END 
							, ' | ','',TRUE) <> ''
						THEN
							-- SSG BR
							OW_LAO.replace_text(
								CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[0].id') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[0].id') || ' | ' ELSE '' END
									|| CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[1].id') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[1].id') || ' | ' ELSE '' END 
									|| CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[2].id') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[2].id') || ' | ' ELSE '' END 
									|| CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[3].id') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[3].id') || ' | ' ELSE '' END 
								, ' | ','',TRUE)
						ELSE		
							-- BR SHOP 
							OW_LAO.replace_text(
								  CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[0].id') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[0].id') || ' | ' ELSE '' END
								|| CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[1].id') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[1].id') || ' | ' ELSE '' END 
								|| CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[2].id') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[2].id') || ' | ' ELSE '' END 
								|| CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[3].id') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[3].id') || ' | ' ELSE '' END 
							, ' | ','',TRUE)
						END
			  		AS CUSTOM_DATA_ID
              FROM OW_LAO.TMP_PO_ORDER_ID_PO_VTEX_TRADE_IN LI -- (LISTA DE ALTERAÇÕES E INSERÇÕES)
                    
                    /********** BR SHOP  ***********/
                    INNER JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER BSO -- (BR SHOP - ORDER )
                          ON BSO.ORDER_ID = LI.ORDER_ID
                    
                    INNER JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER_ITEM BSI -- (BR SHOP - ITEM)
                          ON BSO.ORDER_ID = BSI.ORDER_ID
                    
                    LEFT JOIN OW_LAO.TMP_ITEM_COMPONENTS_PO_VTEX_TRADE_IN BSC -- (BR SHOP - COMPONENTES) [NÃO DEVE TER COMPONENTS POR ISSO LEFT]
                          ON BSI.ORDER_ID = BSC.ORDER_ID 
                             AND BSI.SKU_ID = BSC.SKU_ID
                    
                    /********** SSG BR  ***********/
                    LEFT JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_SALES_ORDER SSO -- (SSG BR - ORDER )
                          ON BSO.MARKETPLACE_ORDER_ID = SSO.ORDER_ID
                    
                    LEFT JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER_ITEM SSI -- (BR SHOP - ITEM)
                          ON BSO.MARKETPLACE_ORDER_ID = SSI.ORDER_ID
                             AND BSI.REF_ID = -- SSI.REF_ID
                             	 CASE WHEN RIGHT(SSI.REF_ID,5) LIKE '_OUT%' THEN LEFT (SSI.REF_ID, LENGTH(SSI.REF_ID) - 5) ELSE SSI.REF_ID END
                             AND BSI.ITEM_INDEX = SSI.ITEM_INDEX
                    
                    /********** EPP2  ***********/
                    LEFT JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_EPP2_SALES_ORDER EPO --(EPP2 - ORDER)
                          ON BSO.MARKETPLACE_ORDER_ID = EPO.ORDER_ID
                    
                    LEFT JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_EPP2_SALES_ORDER_ITEM EPI -- (BR SHOP - ITEM)
                          ON BSO.MARKETPLACE_ORDER_ID = EPI.ORDER_ID
                             AND BSI.REF_ID = -- EPI.REF_ID
                             	 CASE WHEN RIGHT(EPI.REF_ID,5) LIKE '_OUT%' THEN LEFT (EPI.REF_ID, LENGTH(EPI.REF_ID) - 5) ELSE EPI.REF_ID END
                             AND BSI.ITEM_INDEX = EPI.ITEM_INDEX           
              WHERE 1=1
                    AND BSC.REF_ID IS NULL -- NÃO DEVE TER COMPONENTS
                    AND BSI.QUANTITY IS NOT NULL
                    AND BSI.PRICE IS NOT NULL
					AND ( CASE WHEN EPO.ORDER_ID IS NOT NULL THEN EPO.STATUS
						       WHEN SSO.ORDER_ID IS NOT NULL THEN SSO.STATUS
						       ELSE BSO.STATUS
					      END 
					    ) IS NOT NULL                    
                    AND BSO.ORDER_ID NOT IN('MBS-1343130745868-01','STD-1341210731553-01') -- KITS COM PROBLEMA NA EPP PRECISA VIR DE BR_SHOP
                    
             /*****************************************************************
              PO (VTEX-[SOMENTE COMPONENTES] {CREATION_TIMESTAMP}) 
            ******************************************************************/
              UNION ALL
              SELECT
                      TO_DATE(BSO.CREATION_TIMESTAMP) AS DATE_REF
                    , BSO.CREATION_TIMESTAMP AS PO_CREATION_DATE
                    , BSO.AFFILIATE_ID
                    , BSO.ORDER_ID
                    , BSO.MARKETPLACE_ORDER_ID
                    , BSO.HOSTNAME AS ENVIRONMENT
                    , BSO.STATUS AS STATUS_PO
                    , CASE
                          WHEN 
                               (CASE -- CD_STORE_INFORMATION
                                     WHEN BSO.CD_STORE_INFORMATION IS NOT NULL THEN
                                           BSO.CD_STORE_INFORMATION
                                     ELSE SSO.CD_STORE_INFORMATION
                               END) IS NOT NULL 
                          THEN
                               (CASE -- CD_STORE_INFORMATION
                                     WHEN BSO.CD_STORE_INFORMATION IS NOT NULL THEN
                                           BSO.CD_STORE_INFORMATION
                                     ELSE SSO.CD_STORE_INFORMATION
                               END)
                          ELSE
                               (CASE -- UTM_SOURCE
                                     WHEN BSO.UTM_SOURCE IS NOT NULL THEN
                                           BSO.UTM_SOURCE
                                     ELSE SSO.UTM_SOURCE
                               END)
                      END AS STORE_ID
                    , BSO.SALES_CHANNEL
                    , IFNULL(IFNULL(BSO.CD_VENDEDOR, SSO.CD_VENDEDOR), EPO.CD_VENDEDOR) AS STORE_EMPLOYEE_CPF
                    , LI.CUSTOMER_PO
                    , BSI.ITEM_INDEX
                    , BSI.REF_ID AS REFERENCE_CODE_KIT
                    , BSC.REF_ID AS REFERENCE_CODE -- é kit (components)
                    , BSC.NAME AS ITEM_NAME
                    --,(BSC.COST_PRICE / 100) AS PRICE_FROM
                    , (BSC.PRICE/ 100) AS PRICE_TO
                    , CAST(BSC.QUANTITY * BSI.QUANTITY AS INTEGER) AS QTY -- (MULTIPLICA QTY DE KIT PELO DE ITEM )
                    , (CASE WHEN (BSO.TOTAL_DISCOUNTS <> 0 AND BSO.TOTAL_ITEMS > 0) THEN -- DESCONTOS
							  ( (BSC.PRICE * (BSC.QUANTITY * BSI.QUANTITY)) / BSO.TOTAL_ITEMS ) * BSO.TOTAL_DISCOUNTS
						ELSE 0 END / 100) AS AMOUNT_DISCOUNT
                    , (CASE WHEN (BSO.TOTAL_SHIPPING <> 0 AND BSO.TOTAL_ITEMS > 0) THEN -- FRETE
							  ( (BSC.PRICE * (BSC.QUANTITY * BSI.QUANTITY)) / BSO.TOTAL_ITEMS ) * BSO.TOTAL_SHIPPING
						ELSE 0 END / 100) AS AMOUNT_SHIPPING                             
					, CAST((
								   (BSC.PRICE * (BSC.QUANTITY * BSI.QUANTITY)) 
								   + CASE WHEN (BSO.TOTAL_DISCOUNTS <> 0 AND BSO.TOTAL_ITEMS > 0) THEN -- (SUBTRAI OS DESCONTOS)
										  ( (BSC.PRICE * (BSC.QUANTITY * BSI.QUANTITY)) / BSO.TOTAL_ITEMS ) * BSO.TOTAL_DISCOUNTS
								   ELSE 0 END
								   + CASE WHEN (BSO.TOTAL_SHIPPING <> 0 AND BSO.TOTAL_ITEMS > 0) THEN -- FRETE SOMA O FRETE
										 ( (BSC.PRICE * (BSC.QUANTITY * BSI.QUANTITY)) / BSO.TOTAL_ITEMS ) * BSO.TOTAL_SHIPPING
								   ELSE 0 END
							  )  / 100
					  AS DECIMAL(18,2)) AS AMOUNT_LOCAL
                    , IFNULL( IFNULL( EPI.SKU_ID ,SSI.SKU_ID ),BSI.SKU_ID) AS SKU_ID 
                    
                    , EPI.SKU_ID AS SKU_ID_EPP2
					, SSI.SKU_ID AS SKU_ID_SSG_BR
					, BSI.SKU_ID AS SKU_ID_BR_SHOP
                    , NULL AS SKU_ID_COMPONENT_EPP
					, NULL AS SKU_ID_COMPONENT_SSG_BR
					, BSC.SKU_ID_COMPONENT AS SKU_ID_COMPONENT_SHOP						
					
                    , BSC.SKU_ID_COMPONENT -- é kit (components)
								
					, IFNULL(IFNULL(
						( -- EPP2
							IFNULL(IFNULL(IFNULL(
							  CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[0].fields.eco_troca_products') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[0].fields.eco_troca_products')  END
							, CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[1].fields.eco_troca_products') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[1].fields.eco_troca_products')  END )
							, CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[2].fields.eco_troca_products') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[2].fields.eco_troca_products')  END )
							, CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[3].fields.eco_troca_products') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[3].fields.eco_troca_products')  END )
						 )
						,
						( -- SSG BR
							IFNULL(IFNULL(IFNULL(
							  CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[0].fields.eco_troca_products') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[0].fields.eco_troca_products')  END
							, CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[1].fields.eco_troca_products') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[1].fields.eco_troca_products')  END )
							, CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[2].fields.eco_troca_products') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[2].fields.eco_troca_products')  END )
							, CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[3].fields.eco_troca_products') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[3].fields.eco_troca_products')  END )
						 )
						),
						( -- BR SHOP 
							IFNULL(IFNULL(IFNULL(
							  CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[0].fields.eco_troca_products') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[0].fields.eco_troca_products') END
							, CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[1].fields.eco_troca_products') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[1].fields.eco_troca_products') END )
							, CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[2].fields.eco_troca_products') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[2].fields.eco_troca_products') END )
							, CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[3].fields.eco_troca_products') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[3].fields.eco_troca_products') END )
						 )
					 ) AS ECO_TROCA
					, IFNULL(IFNULL(
						( -- EPP2
							IFNULL(IFNULL(IFNULL(
							  CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[0].fields.trade_in_option_selected') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[0].fields.trade_in_option_selected') END
							, CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[1].fields.trade_in_option_selected') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[1].fields.trade_in_option_selected') END )
							, CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[2].fields.trade_in_option_selected') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[2].fields.trade_in_option_selected') END )
							, CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[3].fields.trade_in_option_selected') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[3].fields.trade_in_option_selected') END )
						 )
						,
						( -- SSG BR
							IFNULL(IFNULL(IFNULL(
							  CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[0].fields.trade_in_option_selected') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[0].fields.trade_in_option_selected') END
							, CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[1].fields.trade_in_option_selected') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[1].fields.trade_in_option_selected') END )
							, CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[2].fields.trade_in_option_selected') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[2].fields.trade_in_option_selected') END )
							, CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[3].fields.trade_in_option_selected') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[3].fields.trade_in_option_selected') END )
						 ) 						
						),
						( -- BR SHOP 
							IFNULL(IFNULL(IFNULL(
							  CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[0].fields.trade_in_option_selected') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[0].fields.trade_in_option_selected') END
							, CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[1].fields.trade_in_option_selected') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[1].fields.trade_in_option_selected') END )
							, CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[2].fields.trade_in_option_selected') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[2].fields.trade_in_option_selected') END )
							, CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[3].fields.trade_in_option_selected') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[3].fields.trade_in_option_selected') END )
						 ) 
					 )AS TRADE_IN_OPTION
					
					, IFNULL(IFNULL(
						( -- EPP2
							IFNULL(IFNULL(IFNULL(
							  CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[0].fields.trade_in_total_value') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[0].fields.trade_in_total_value') END
							, CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[1].fields.trade_in_total_value') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[1].fields.trade_in_total_value') END )
							, CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[2].fields.trade_in_total_value') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[2].fields.trade_in_total_value') END )
							, CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[3].fields.trade_in_total_value') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[3].fields.trade_in_total_value') END )
						 )
						,
						( -- SSG BR
							IFNULL(IFNULL(IFNULL(
							  CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[0].fields.trade_in_total_value') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[0].fields.trade_in_total_value') END
							, CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[1].fields.trade_in_total_value') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[1].fields.trade_in_total_value') END )
							, CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[2].fields.trade_in_total_value') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[2].fields.trade_in_total_value') END )
							, CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[3].fields.trade_in_total_value') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[3].fields.trade_in_total_value') END )
						 ) 						
						),
						( -- BR SHOP 
							IFNULL(IFNULL(IFNULL(
							  CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[0].fields.trade_in_total_value') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[0].fields.trade_in_total_value')  END
							, CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[1].fields.trade_in_total_value') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[1].fields.trade_in_total_value')  END )
							, CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[2].fields.trade_in_total_value') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[2].fields.trade_in_total_value')  END )
							, CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[3].fields.trade_in_total_value') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[3].fields.trade_in_total_value')  END )
						 ) 
					 ) AS TRADE_IN_TOTAL
					,	OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						OW_LAO.REPLACE_TEXT(
						
						OW_LAO.REPLACE_TEXT(
							IFNULL(IFNULL(
								CASE WHEN (JSON_VALUE(EPO.OPEN_TEXT_FIELD, '$.value') IS NOT NULL) AND (JSON_VALUE(EPO.OPEN_TEXT_FIELD, '$.value') NOT IN ('[]','') ) THEN 
									( -- EPP2
										CASE WHEN JSON_VALUE(EPO.OPEN_TEXT_FIELD, '$.value')  LIKE '[%' THEN '' ELSE '[' END
										|| REPLACE(JSON_VALUE(EPO.OPEN_TEXT_FIELD, '$.value') ,'''', '"') ||
										CASE WHEN JSON_VALUE(EPO.OPEN_TEXT_FIELD, '$.value')  LIKE '%]' THEN '' ELSE ']' END
									)
								 END
								, CASE WHEN (JSON_VALUE(SSO.OPEN_TEXT_FIELD, '$.value') IS NOT NULL) AND (JSON_VALUE(SSO.OPEN_TEXT_FIELD, '$.value') NOT IN ('[]','') ) THEN 
									( -- SSG BR
										CASE WHEN JSON_VALUE(SSO.OPEN_TEXT_FIELD, '$.value')  LIKE '[%' THEN '' ELSE '[' END
										|| REPLACE(JSON_VALUE(SSO.OPEN_TEXT_FIELD, '$.value') ,'''', '"') ||
										CASE WHEN JSON_VALUE(SSO.OPEN_TEXT_FIELD, '$.value')  LIKE '%]' THEN '' ELSE ']' END								
									 ) 
								  END
								)
								, CASE WHEN (JSON_VALUE(BSO.OPEN_TEXT_FIELD, '$.value') IS NOT NULL) AND (JSON_VALUE(BSO.OPEN_TEXT_FIELD, '$.value') NOT IN ('[]','') ) THEN 
									( -- BR SHOP 
										CASE WHEN JSON_VALUE(BSO.OPEN_TEXT_FIELD, '$.value')  LIKE '[%' THEN '' ELSE '[' END
										|| REPLACE(JSON_VALUE(BSO.OPEN_TEXT_FIELD, '$.value') ,'''', '"') ||
										CASE WHEN JSON_VALUE(BSO.OPEN_TEXT_FIELD, '$.value')  LIKE '%]' THEN '' ELSE ']' END		
									 ) 
								  END
							 )
						
						,'[{ean":"','[{"ean":"',FALSE)
						
						,'0, }]', '0", }]',TRUE)
						,'1, }]', '1", }]',TRUE)
						,'2, }]', '2", }]',TRUE)
						,'3, }]', '3", }]',TRUE)
						,'4, }]', '4", }]',TRUE)
						,'5, }]', '5", }]',TRUE)
						,'6, }]', '6", }]',TRUE)
						,'7, }]', '7", }]',TRUE)
						,'8, }]', '8", }]',TRUE)
						,'9, }]', '9", }]',TRUE)
						,'0", }]', '0"}, ]',TRUE)
						,'1", }]', '1"}, ]',TRUE)
						,'2", }]', '2"}, ]',TRUE)
						,'3", }]', '3"}, ]',TRUE)
						,'4", }]', '4"}, ]',TRUE)
						,'5", }]', '5"}, ]',TRUE)
						,'6", }]', '6"}, ]',TRUE)
						,'7", }]', '7"}, ]',TRUE)
						,'8", }]', '8"}, ]',TRUE)
						,'9", }]', '9"}, ]',TRUE)					
					  AS TEXT_FIELD
					, IFNULL(IFNULL(EPO.COUPON, SSO.COUPON), BSO.COUPON) AS COUPON
					, UPPER(IFNULL(IFNULL(EPO.MARKETING_TAGS, SSO.MARKETING_TAGS), BSO.MARKETING_TAGS)) AS MARKETING_TAGS
                    
					, CASE 
						WHEN 
							-- EPP2
							OW_LAO.replace_text(
							   CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[0].id') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[0].id') || ' | ' ELSE '' END
							   || CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[1].id') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[1].id') || ' | ' ELSE '' END 
							   || CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[2].id') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[2].id') || ' | ' ELSE '' END 
							   || CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[3].id') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[3].id') || ' | ' ELSE '' END 
							, ' | ','',TRUE) <> ''
						THEN 
							-- EPP2
							OW_LAO.replace_text(
							   CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[0].id') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[0].id') || ' | ' ELSE '' END
							   || CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[1].id') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[1].id') || ' | ' ELSE '' END 
							   || CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[2].id') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[2].id') || ' | ' ELSE '' END 
							   || CASE WHEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[3].id') NOT IN ('[]','') THEN JSON_VALUE(EPO.CUSTOM_DATA, '$.customApps[3].id') || ' | ' ELSE '' END 
							, ' | ','',TRUE)
						WHEN
						  -- SSG BR
						  OW_LAO.replace_text(
							CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[0].id') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[0].id') || ' | ' ELSE '' END
								|| CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[1].id') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[1].id') || ' | ' ELSE '' END 
								|| CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[2].id') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[2].id') || ' | ' ELSE '' END 
								|| CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[3].id') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[3].id') || ' | ' ELSE '' END 
							, ' | ','',TRUE) <> ''
						THEN
							-- SSG BR
							OW_LAO.replace_text(
								CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[0].id') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[0].id') || ' | ' ELSE '' END
									|| CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[1].id') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[1].id') || ' | ' ELSE '' END 
									|| CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[2].id') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[2].id') || ' | ' ELSE '' END 
									|| CASE WHEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[3].id') NOT IN ('[]','') THEN JSON_VALUE(SSO.CUSTOM_DATA, '$.customApps[3].id') || ' | ' ELSE '' END 
								, ' | ','',TRUE)
						ELSE		
							-- BR SHOP 
							OW_LAO.replace_text(
								  CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[0].id') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[0].id') || ' | ' ELSE '' END
								|| CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[1].id') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[1].id') || ' | ' ELSE '' END 
								|| CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[2].id') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[2].id') || ' | ' ELSE '' END 
								|| CASE WHEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[3].id') NOT IN ('[]','') THEN JSON_VALUE(BSO.CUSTOM_DATA, '$.customApps[3].id') || ' | ' ELSE '' END 
							, ' | ','',TRUE)
						END
			  		AS CUSTOM_DATA_ID
					
              FROM OW_LAO.TMP_PO_ORDER_ID_PO_VTEX_TRADE_IN LI -- (LISTA DE ALTERAÇÕES E INSERÇÕES)
                    
                    /********** BR SHOP  ***********/
                    INNER JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER BSO -- (BR SHOP - ORDER )
                          ON BSO.ORDER_ID = LI.ORDER_ID
                    
                    INNER JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER_ITEM BSI -- (BR SHOP - ITEM)
                          ON BSO.ORDER_ID = BSI.ORDER_ID
                    
                    INNER JOIN OW_LAO.TMP_ITEM_COMPONENTS_PO_VTEX_TRADE_IN BSC -- (BR SHOP - COMPONENTES) [NÃO DEVE TER COMPONENTS POR ISSO LEFT]
                          ON BSI.ORDER_ID = BSC.ORDER_ID 
                             AND BSI.SKU_ID = BSC.SKU_ID
 
                    /********** SSG BR  ***********/
                    LEFT JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_SALES_ORDER SSO -- (SSG BR - ORDER )
                          ON BSO.MARKETPLACE_ORDER_ID = SSO.ORDER_ID
                    
                    LEFT JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER_ITEM SSI -- (BR SHOP - ITEM)
                          ON BSO.MARKETPLACE_ORDER_ID = SSI.ORDER_ID
                             AND BSI.REF_ID = -- SSI.REF_ID
                             	 CASE WHEN RIGHT(SSI.REF_ID,5) LIKE '_OUT%' THEN LEFT (SSI.REF_ID, LENGTH(SSI.REF_ID) - 5) ELSE SSI.REF_ID END
                             AND BSI.ITEM_INDEX = SSI.ITEM_INDEX
                    
                    /********** EPP2  ***********/
                    LEFT JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_EPP2_SALES_ORDER EPO --(EPP2 - ORDER)
                          ON BSO.MARKETPLACE_ORDER_ID = EPO.ORDER_ID
                    
                    LEFT JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_EPP2_SALES_ORDER_ITEM EPI -- (BR SHOP - ITEM)
                          ON BSO.MARKETPLACE_ORDER_ID = EPI.ORDER_ID
                             AND BSI.REF_ID = -- EPI.REF_ID
                             	 CASE WHEN RIGHT(EPI.REF_ID,5) LIKE '_OUT%' THEN LEFT (EPI.REF_ID, LENGTH(EPI.REF_ID) - 5) ELSE EPI.REF_ID END
                             AND BSI.ITEM_INDEX = EPI.ITEM_INDEX  
              WHERE BSC.REF_ID IS NOT NULL -- SOMENTE COMPONENTS
                    AND BSC.QUANTITY IS NOT NULL
                    AND BSC.PRICE IS NOT NULL
					AND ( CASE WHEN EPO.ORDER_ID IS NOT NULL THEN EPO.STATUS
						       WHEN SSO.ORDER_ID IS NOT NULL THEN SSO.STATUS
						       ELSE BSO.STATUS
					      END 
					    ) IS NOT NULL                      
                    AND BSO.ORDER_ID NOT IN('MBS-1343130745868-01','STD-1341210731553-01') -- KITS COM PROBLEMA NA EPP PRECISA VIR DE BR_SHOP
		   )PO_
		   LEFT JOIN U_PRJ_ECOM.ODS_VTEX_SSG_BR_SHOP_DATA_ENTITIES_STORES_SDS ES
				ON ES.ID_STORE = PO_.STORE_ID -- ENDLESS_STORE
		WHERE 1 = 1
		    AND ( --- SOMENTE SE FOR TRADE-IN OU ECOTROCA
				   JSON_VALUE(PO_.ECO_TROCA, '$.skuId') IS NOT NULL				   
				OR JSON_VALUE(PO_.TEXT_FIELD, '$.isTradeIn') = 'true'
				OR JSON_VALUE(PO_.TRADE_IN_OPTION, '$.skuId') IS NOT NULL
				OR JSON_VALUE(PO_.TRADE_IN_OPTION, '$.sku') IS NOT NULL				
			)
			
	);
 	/********************************************************
	* LIMPA ORDERS CASO EXISTAM NA TABELA FINAL
	* DROP TABLE OW_LAO.TF_D2C_PO_VTEX_TRADE_IN
	********************************************************/
	DELETE FROM OW_LAO.TF_D2C_PO_VTEX_TRADE_IN
	WHERE ORDER_ID IN ( SELECT DISTINCT ORDER_ID
					    FROM OW_LAO.TMP_PO_VTEX_TRADE_IN_DETAIL
				      );
	/*********************************************************
	* ALIMENTA TABELA FINAL - TF_D2C_PO_VTEX_TRADE_IN
	* RETORNA OS DETALHES DAS ORDER NA VTEX
	* SEPARADAS EM 2 ETAPAS (ORDER SEM KITS E ORDERS COM KIT)
	* *******************************************************/
	INSERT INTO OW_LAO.TF_D2C_PO_VTEX_TRADE_IN(
		"SOURCE"
		,DATE_REF
		,YYYYWW
		,YYYYMM
		,YYYYQQ
		,PO_CREATION_DATE
		,PO_WEEK_DAY_NUM
		,PO_WEEK_DAY_NAME
		,PO_HOUR
		,SALES_CHANNEL
		,SUBSIDIARY
		,CHANNEL
		,SUB_CHANNEL
		,SALES_CHANNEL_ATTR_1
		,SALES_CHANNEL_ATTR_2
		,AFFILIATE_ID
		,SKU
		,PDROD_DIVISION
		,PDROD_PRODUCT_GROUP
		,PDROD_PRODUCT
		,PROD_ATTB_1
		,SEDA_BU_ESTORE
		,SEDA_DIVISION_ESTORE
		,SEDA_CATEGORY_ESTORE
		,SEDA_FAMILY_ESTORE
		,SEDA_DESC_ESTORE
		,QTY
		,AMOUNT_LOCAL
		,AMOUNT_USD
		,PRICE_TO
		,AMOUNT_DISCOUNT
		,AMOUNT_SHIPPING
		,ITEM_NAME
		,ORDER_ID
		,SELECTED_SLA
		,WAREHOUSE_ID_GROUP
		,ADDRESSTYPE
		,FRIENDLYNAME
		,STATE
		,CITY
		,MARKETPLACE_ORDER_ID
		,CUSTOMER_PO
		,ENVIRONMENT
		,STORE_ID
		,NAME_STORE
		,STORE_EMPLOYEE_CPF
		,CHANNEL_TYPE
		,O2O_TYPE
		,REFERENCE_CODE_KIT
		,REFERENCE_CODE
		,STATUS_PO
		,AFFILIATE_ID_ADJUSTED
		,AFFILIATE_CHANNEL
		,AFFILIATE_SUB_CHANNEL
		,AFFILIATE_PARTNER_LEVEL
		,GLOBAL_CHANNEL
		,BIZ_TYPE
		,AUDIENCE_TYPE
		,SKU_ID_EPP2
		,SKU_ID_SSG_BR
		,SKU_ID_BR_SHOP
		,SKU_ID_COMPONENT_EPP
		,SKU_ID_COMPONENT_SSG_BR
		,SKU_ID_COMPONENT_SHOP
		,ECO_SKUID
		,ECO_BRAND
		,ECO_BOOST
		,ECO_CATEGORY_NAME
		,TRADE_IN_SKUID
		,TRADE_IN_GTI
		,TRADE_IN_BOOST
		,TRADE_IN_TOTAL
		,TRADE_IN_REFID
		,IS_TRADE_IN
		,IS_GTI
		,IS_ECO_TROCA
		,TRADE_IN_PRODUCT_NAME
		,PRODUCT_BRAND
		,TRADE_IN_PRODUCT_PRICE
		,COUPON
		,COUNTRY
		,CURRENCY
		,MODEL_TYPE
		,CHANNEL_O2O
		,PARTNER_O2O
		,STORE_TYPE_O2O
		,STORE_NAME_O2O
		,LAST_UPDATE
		,CUSTOM_DATA_ID
	)
	-- CREATE COLUMN TABLE OW_LAO.TF_D2C_PO_VTEX_TRADE_IN AS(
	SELECT
		  "SOURCE"
		, DATE_REF
		, YYYYWW
		, YYYYMM
		, YYYYQQ
		, PO_CREATION_DATE
		, "PO_WEEK_DAY_NUM"
		, "PO_WEEK_DAY_NAME"
		, "PO_HOUR"
		, SALES_CHANNEL
		, SUBSIDIARY
		, CHANNEL 
		, SUB_CHANNEL 
		, SALES_CHANNEL_ATTR_1 
		, SALES_CHANNEL_ATTR_2
		, AFFILIATE_ID
		, SKU
		, PDROD_DIVISION
		, PDROD_PRODUCT_GROUP 
		, PDROD_PRODUCT 
		, PROD_ATTB_1 
		, SEDA_BU_ESTORE
		, SEDA_DIVISION_ESTORE
		, SEDA_CATEGORY_ESTORE
		, SEDA_FAMILY_ESTORE
		, SEDA_DESC_ESTORE		
		, QTY
		, AMOUNT_LOCAL
		, AMOUNT_USD
		, PRICE_TO
		, AMOUNT_DISCOUNT
		, AMOUNT_SHIPPING
		, ITEM_NAME
		, ORDER_ID
		, "SELECTED_SLA"
		, "WAREHOUSE_ID_GROUP"
		, ADDRESSTYPE
		, FRIENDLYNAME
		, "STATE"
		, CITY
		, MARKETPLACE_ORDER_ID
		, CUSTOMER_PO
		, ENVIRONMENT
		, STORE_ID
		, NAME_STORE
		, "STORE_EMPLOYEE_CPF"
		, CHANNEL_TYPE
		, O2O_TYPE
		, REFERENCE_CODE_KIT
		, REFERENCE_CODE
		, STATUS_PO
		, AFFILIATE_ID_ADJUSTED
		, AFFILIATE_CHANNEL
		, AFFILIATE_SUB_CHANNEL
		, AFFILIATE_PARTNER_LEVEL
		, GLOBAL_CHANNEL
		, BIZ_TYPE
		, AUDIENCE_TYPE
		, SKU_ID_EPP2
		, SKU_ID_SSG_BR
		, SKU_ID_BR_SHOP
		, SKU_ID_COMPONENT_EPP
		, SKU_ID_COMPONENT_SSG_BR
		, SKU_ID_COMPONENT_SHOP
		, "ECO_SKUID"  
		, "ECO_BRAND"
		, "ECO_BOOST"
		, "ECO_CATEGORY_NAME"
		, "TRADE_IN_SKUID"
		, "TRADE_IN_GTI"
		, "TRADE_IN_BOOST"
		, "TRADE_IN_TOTAL"
		, "TRADE_IN_REFID"
		, IS_TRADE_IN
		, IS_GTI		
		, IS_ECO_TROCA
		, TRADE_IN_PRODUCT_NAME
		, PRODUCT_BRAND		  
		, TRADE_IN_PRODUCT_PRICE			  
		, "COUPON"
		, COUNTRY
		, CURRENCY
		, MODEL_TYPE
		
		, CASE WHEN O2O_TYPE = 'BOPIS' THEN
		 	 CASE 
			 	WHEN (UPPER(SELECTED_SLA) LIKE 'CLIQUE RETIRE%') AND UPPER(ADDRESSTYPE) = 'PICKUP' THEN 'LOCKER' -- BOPIL
		 		WHEN TRIM(SUBSTRING_REGEXPR( '(CSP[a-zA-Z0-9]+)' IN SELECTED_SLA FROM 1 OCCURRENCE 1)) LIKE 'CSP%' THEN 'CSP'
		 	 END
		   ELSE
			TRIM(SUBSTRING_REGEXPR('[^|]+' IN NAME_STORE FROM 1 OCCURRENCE 1))
		   END AS CHANNEL_O2O
		, CASE WHEN O2O_TYPE = 'BOPIS' THEN
		 	 CASE 
			 	WHEN (UPPER(SELECTED_SLA) LIKE 'CLIQUE RETIRE%') AND UPPER(ADDRESSTYPE) = 'PICKUP' THEN 'Clique Retire' -- BOPIL
		 		--WHEN TRIM(SUBSTRING_REGEXPR( '(CSP[a-zA-Z0-9]+)' IN SELECTED_SLA FROM 1 OCCURRENCE 1)) LIKE 'CSP%' THEN 'CSP'
		 	 END
		  ELSE
				TRIM(SUBSTRING_REGEXPR('[^|]+' IN NAME_STORE FROM 1 OCCURRENCE 2)) 
		  END AS PARTNER_O2O
		  
		, TRIM(SUBSTRING_REGEXPR('[^|]+' IN NAME_STORE FROM 1 OCCURRENCE 3)) AS STORE_TYPE_O2O
		
		, CASE
			 WHEN O2O_TYPE = 'BOPIS' THEN
				IFNULL( CAST( OW_LAO.REPLACE_TEXT(TRIM(SUBSTRING_REGEXPR( '(CSP[a-zA-Z0-9]+)' IN SELECTED_SLA FROM 1 OCCURRENCE 1)),'CSP','',FALSE) AS VARCHAR(5000))
					   ,CASE WHEN UPPER(SELECTED_SLA) LIKE 'CLIQUE RETIRE%' THEN CAST(FRIENDLYNAME AS VARCHAR(5000))  END)
		   ELSE
				TRIM(SUBSTRING_REGEXPR('[^|]+' IN NAME_STORE FROM 1 OCCURRENCE 4)) 
	 	   END AS STORE_NAME_O2O
			
		--KPI_LAST_UPDATE
		, CURRENT_TIMESTAMP AS LAST_UPDATE
		
		, CUSTOM_DATA_ID	
	FROM(
		SELECT
			  'PO' AS SOURCE
			, PO.DATE_REF
			, CL.YYYYWW AS YYYYWW
			, CL.YYYYMM AS YYYYMM
			, CL.YYYYQQ AS YYYYQQ
			, PO.PO_CREATION_DATE
			, WEEKDAY(PO.PO_CREATION_DATE) AS "PO_WEEK_DAY_NUM"
			, DAYNAME(PO.PO_CREATION_DATE) AS "PO_WEEK_DAY_NAME"
			, EXTRACT_HOUR(PO.PO_CREATION_DATE) AS "PO_HOUR"
			-- CHANNEL
			, PO.SALES_CHANNEL
			, CASE WHEN AF.SUBSIDIARY IS NOT NULL THEN TRIM(AF.SUBSIDIARY) ELSE 'SEDA' END AS SUBSIDIARY
			, CH.CHANNEL 
			, CH.SUB_CHANNEL 
			, CH.SALES_CHANNEL_ATTR_1 
			, CH.SALES_CHANNEL_ATTR_2
			, PO.AFFILIATE_ID
			-- PRODUCT
			, PD.SKU
			, PD."DIVISION" AS PDROD_DIVISION
			, PD.PRODUCT_GROUP_1 AS PDROD_PRODUCT_GROUP 
			, PD.PRODUCT_1 AS PDROD_PRODUCT 
			, PD.ATTB01 AS PROD_ATTB_1 
			, PD.SEDA_BU_ESTORE
			, PD.SEDA_DIVISION_ESTORE
			, PD.SEDA_CATEGORY_ESTORE
			, PD.SEDA_FAMILY_ESTORE
			, PD.SEDA_DESC_ESTORE		
			, PO.QTY
			, PO.AMOUNT_LOCAL
			--,0 AS AMOUNT_USD
			, CAST( PO.AMOUNT_LOCAL / EX.EXCHANGE_RATE AS DECIMAL(18,2) ) AS AMOUNT_USD
			--,PO.PRICE_FROM
			, PO.PRICE_TO
			, PO.AMOUNT_DISCOUNT
			, PO.AMOUNT_SHIPPING
			, PO.ITEM_NAME
			, PO.ORDER_ID
			, SL."SELECTED_SLA"
			, SL."WAREHOUSE_ID_GROUP"
			, SL.ADDRESSTYPE
			, SL.FRIENDLYNAME
			, SL.STATE
			, SL.CITY
			, PO.MARKETPLACE_ORDER_ID
			, PO.CUSTOMER_PO
			, PO.ENVIRONMENT
			, PO.STORE_ID
			, PO.NAME_STORE
			, PO."STORE_EMPLOYEE_CPF"
			, PO.CHANNEL_TYPE
	
			, CASE 
				WHEN ( TRIM(UPPER(SL."SELECTED_SLA")) LIKE 'SHIP TO STORE %' 
						OR TRIM(UPPER(SL."SELECTED_SLA"))LIKE 'PONTO DE RETIRADA %'
						OR TRIM(UPPER(SL."SELECTED_SLA"))LIKE 'CLIQUE%'
					 )
					 AND PO.CHANNEL_TYPE = 'Store+'
				THEN 'BOPIS + EA'
				WHEN ( TRIM(UPPER(SL."SELECTED_SLA")) LIKE 'SHIP TO STORE %'
					   OR TRIM(UPPER(SL."SELECTED_SLA"))LIKE 'PONTO DE RETIRADA %'
					   OR TRIM(UPPER(SL."SELECTED_SLA"))LIKE 'CLIQUE%'
				)
				THEN 'BOPIS'
				WHEN ( PO.CHANNEL_TYPE = 'Store+' )
				THEN 'EA'
			 ELSE NULL END AS O2O_TYPE
			 
			, PO.REFERENCE_CODE_KIT
			, PO.REFERENCE_CODE
			, PO.STATUS_PO
			
			-- AFFILIATE INFORMATION
			, PO.AFFILIATE_ID_ADJUSTED
			, AF.AFFILIATE_CHANNEL
			, AF.AFFILIATE_SUB_CHANNEL
			, AF.AFFILIATE_PARTNER_LEVEL
			, AF.GLOBAL_CHANNEL
			, AF.BIZ_TYPE
			, AF.AUDIENCE_TYPE
			
			, PO.SKU_ID_EPP2
			, PO.SKU_ID_SSG_BR
			, PO.SKU_ID_BR_SHOP
	
			, PO.SKU_ID_COMPONENT_EPP
			, PO.SKU_ID_COMPONENT_SSG_BR
			, PO.SKU_ID_COMPONENT_SHOP
	
			-- OBS: CASO SÓ TENHA 1 ITEM NÃO PRECISA VERIFICAR O SKU ID DO TRADE IN  
			, PO."ECO_SKUID" AS "ECO_SKUID"  
			, CASE WHEN PO."ECO_SKUID" IN (PO.SKU_ID, PO.SKU_ID_COMPONENT) OR PO.QTY_ITEMS_ORDER_ET = 1 THEN
						PO."ECO_BRAND"
			  END AS "ECO_BRAND"
			, CASE WHEN PO."ECO_SKUID" IN (PO.SKU_ID, PO.SKU_ID_COMPONENT) OR PO.QTY_ITEMS_ORDER_ET = 1 THEN
						PO."ECO_BOOST"
			  END AS "ECO_BOOST"
			, CASE WHEN PO."ECO_SKUID" IN (PO.SKU_ID, PO.SKU_ID_COMPONENT) OR PO.QTY_ITEMS_ORDER_ET = 1 THEN
						PO."ECO_CATEGORY_NAME"
			  END AS "ECO_CATEGORY_NAME"
			  
			, PO."TRADE_IN_SKUID" AS "TRADE_IN_SKUID"
			, CASE WHEN PO."TRADE_IN_SKUID" IN (PO.SKU_ID, PO.SKU_ID_COMPONENT) OR PO.QTY_ITEMS_ORDER = 1 THEN 
						PO."TRADE_IN_GTI" 
			  END AS "TRADE_IN_GTI"
			, CASE WHEN PO."TRADE_IN_SKUID" IN (PO.SKU_ID, PO.SKU_ID_COMPONENT) OR PO.QTY_ITEMS_ORDER = 1 THEN 
						PO."TRADE_IN_BOOST" 
			  END AS "TRADE_IN_BOOST"
			, CASE WHEN PO."TRADE_IN_SKUID" IN (PO.SKU_ID, PO.SKU_ID_COMPONENT) OR PO.QTY_ITEMS_ORDER = 1 THEN
			  			PO."TRADE_IN_TOTAL" 
			  END AS "TRADE_IN_TOTAL"
			, CASE WHEN PO."TRADE_IN_SKUID" IN (PO.SKU_ID, PO.SKU_ID_COMPONENT) OR PO.QTY_ITEMS_ORDER = 1 THEN 
						PO."TRADE_IN_REFID"
			  END AS "TRADE_IN_REFID"
			
			, IFNULL(
				  PO.IS_TRADE_IN
				, CASE WHEN PO."TRADE_IN_SKUID" IS NOT NULL THEN 'true' END 
			) AS IS_TRADE_IN
			
			, PO.IS_GTI
			
			--, PO.IS_ECO_TROCA			
			, CASE WHEN PO."ECO_SKUID" IN (PO.SKU_ID, PO.SKU_ID_COMPONENT) OR PO.QTY_ITEMS_ORDER_ET = 1 THEN
			  			PO.IS_ECO_TROCA
			  ELSE FALSE END AS IS_ECO_TROCA
			  
			, CASE WHEN PO."TRADE_IN_SKUID" IN (PO.SKU_ID, PO.SKU_ID_COMPONENT) OR PO.QTY_ITEMS_ORDER = 1 THEN 
						PO.TRADE_IN_PRODUCT_NAME
			  END AS TRADE_IN_PRODUCT_NAME
			--,PO.TRADE_IN_PRODUCT_NAME
			  
			, CASE WHEN PO."TRADE_IN_SKUID" IN (PO.SKU_ID, PO.SKU_ID_COMPONENT) OR PO.QTY_ITEMS_ORDER = 1 THEN 
						OW_LAO.CONTAINS_BRAND(PO.TRADE_IN_PRODUCT_NAME)
			  END AS PRODUCT_BRAND		  
			
			--, OW_LAO.CONTAINS_BRAND(PO.TRADE_IN_PRODUCT_NAME) AS PRODUCT_BRAND
			, CASE WHEN PO."TRADE_IN_SKUID" IN (PO.SKU_ID, PO.SKU_ID_COMPONENT) OR PO.QTY_ITEMS_ORDER = 1 THEN 
						PO.TRADE_IN_PRODUCT_PRICE
			  END AS TRADE_IN_PRODUCT_PRICE			  
			--, PO.TRADE_IN_PRODUCT_PRICE
	
			, PO."COUPON"
			, AF.COUNTRY
			, AF.CURRENCY
			
			-- PREMIUM MODEL
			, CASE WHEN PR.MATERIAL IS NOT NULL THEN 'PREMIUM MODEL' ELSE 'NORMAL MODEL' END AS MODEL_TYPE
			, PO.CUSTOM_DATA_ID
		FROM(
			SELECT
				  PO_.DATE_REF
				, PO_.PO_CREATION_DATE
				, PO_.SALES_CHANNEL
				, PO_.AFFILIATE_ID
				--,'BRL' AS CURRENCY
				, PO_.ORDER_ID
				, PO_.MARKETPLACE_ORDER_ID
				, PO_.CUSTOMER_PO
				, PO_.ITEM_INDEX
				, PO_.ENVIRONMENT
				, ES.ID_STORE AS STORE_ID --,PO_.STORE_ID
				, ES.NAME AS NAME_STORE
				, PO_."STORE_EMPLOYEE_CPF"
				, CASE WHEN ES.ID_STORE IS NOT NULL THEN 'Store+' ELSE 'Shop' END AS CHANNEL_TYPE				 
				, PO_.REFERENCE_CODE_KIT
				, PO_.REFERENCE_CODE
				, PO_.ITEM_NAME
				, PO_.STATUS_PO
				--,PO_.PRICE_FROM
				, PO_.PRICE_TO
				, PO_.AMOUNT_DISCOUNT
				, PO_.AMOUNT_SHIPPING
				, PO_.QTY
				, PO_.AMOUNT_LOCAL
				
				, OW_LAO.AFFILIATE_ID_ADJUSTED(ES.ID_STORE, PO_.AFFILIATE_ID, PO_.SALES_CHANNEL) AS AFFILIATE_ID_ADJUSTED
		
				, PO_.SKU_ID_EPP2
				, PO_.SKU_ID_SSG_BR
				, PO_.SKU_ID_BR_SHOP
		
				, PO_.SKU_ID_COMPONENT_EPP
				, PO_.SKU_ID_COMPONENT_SSG_BR
				, PO_.SKU_ID_COMPONENT_SHOP
				
				, PO_.SKU_ID
				, PO_.SKU_ID_COMPONENT
	
				, CAST(OW_LAO.CASTDECIMAL(JSON_VALUE(PO_.ECO_TROCA, '$.skuId')) AS INTEGER) AS "ECO_SKUID"
				, TRIM(JSON_VALUE(PO_.ECO_TROCA, '$.brand')) AS "ECO_BRAND"	
				--, CAST(JSON_VALUE(PO_.ECO_TROCA, '$.boost') AS DECIMAL(18,2)) AS "ECO_BOOST"
				, OW_LAO.CASTDECIMAL(JSON_VALUE(PO_.ECO_TROCA, '$.boost')) AS "ECO_BOOST"
				, TRIM(JSON_VALUE(PO_.ECO_TROCA, '$.categoryName')) AS "ECO_CATEGORY_NAME"
				
				, CAST(IFNULL( OW_LAO.CASTDECIMAL(JSON_VALUE(PO_.TRADE_IN_OPTION, '$.skuId'))
							 ,OW_LAO.CASTDECIMAL(JSON_VALUE(TRADE_IN_OPTION, '$.sku')) ) AS INTEGER) AS "TRADE_IN_SKUID"
							 
				--, CAST(JSON_VALUE(PO_.TRADE_IN_OPTION, '$.gtiValue') AS DECIMAL(18,2)) AS TRADE_IN_GTI
				, OW_LAO.CASTDECIMAL(JSON_VALUE(PO_.TRADE_IN_OPTION, '$.gtiValue')) AS TRADE_IN_GTI
				
				, IFNULL( OW_LAO.CASTDECIMAL( JSON_VALUE(PO_.TRADE_IN_OPTION, '$.boostSSG') )
						,OW_LAO.CASTDECIMAL( JSON_VALUE(PO_.TRADE_IN_OPTION, '$.boost') )
				 ) AS TRADE_IN_BOOST
				
				, PO_.TRADE_IN_TOTAL AS TRADE_IN_TOTAL
				, TRIM(JSON_VALUE(PO_.TRADE_IN_OPTION, '$.refId')) AS TRADE_IN_REFID
				
				, JSON_VALUE(PO_.TEXT_FIELD, '$.isTradeIn') AS IS_TRADE_IN
				
				, CASE WHEN PO_.MARKETING_TAGS LIKE '%GTI%' OR 
							CAST(JSON_VALUE(PO_.TRADE_IN_OPTION, '$.gtiValue') AS DECIMAL(18,2)) IS NOT NULL THEN TRUE ELSE FALSE 
				  END AS IS_GTI
				
				, CASE WHEN --PO_.MARKETING_TAGS LIKE '%ECOTROCA%' OR 
							CAST(OW_LAO.CASTDECIMAL(JSON_VALUE(PO_.ECO_TROCA, '$.skuId')) AS INTEGER) IS NOT NULL THEN TRUE ELSE FALSE 
				  END AS IS_ECO_TROCA
				, IFNULL(  CASE WHEN JSON_VALUE(PO_.TRADE_IN_OPTION, '$.evaluatedProducts[0].name') IS NOT NULL THEN  -- O PRIMEIRO PRODUTO NÃO PODE SER NULO
									CONCAT( 
											JSON_VALUE(PO_.TRADE_IN_OPTION, '$.evaluatedProducts[0].name')
										   ,CONCAT(CONCAT(
													CASE WHEN JSON_VALUE(PO_.TRADE_IN_OPTION, '$.evaluatedProducts[1].name') IS NOT NULL THEN 
														CONCAT( ' | ', JSON_VALUE(PO_.TRADE_IN_OPTION, '$.evaluatedProducts[1].name'))
													ELSE '' END
												   ,CASE WHEN JSON_VALUE(PO_.TRADE_IN_OPTION, '$.evaluatedProducts[2].name') IS NOT NULL THEN 
														CONCAT( ' | ', JSON_VALUE(PO_.TRADE_IN_OPTION, '$.evaluatedProducts[2].name'))
													ELSE '' END
												),CASE WHEN JSON_VALUE(PO_.TRADE_IN_OPTION, '$.evaluatedProducts[3].name') IS NOT NULL THEN 
														CONCAT( ' | ', JSON_VALUE(PO_.TRADE_IN_OPTION, '$.evaluatedProducts[3].name'))
												  ELSE '' END
											)
									)
						  END
						, JSON_VALUE(PO_.TRADE_IN_OPTION, '$.modelo') 
				 ) AS TRADE_IN_PRODUCT_NAME
						
				, IFNULL( CASE WHEN OW_LAO.CASTDECIMAL(JSON_VALUE(PO_.TRADE_IN_OPTION, '$.evaluatedProducts[0].price')) IS NOT NULL THEN 
								OW_LAO.CASTDECIMAL(JSON_VALUE(PO_.TRADE_IN_OPTION, '$.evaluatedProducts[0].price'))
								+  IFNULL(OW_LAO.CASTDECIMAL(JSON_VALUE(PO_.TRADE_IN_OPTION, '$.evaluatedProducts[1].price')), 0)
								+  IFNULL(OW_LAO.CASTDECIMAL(JSON_VALUE(PO_.TRADE_IN_OPTION, '$.evaluatedProducts[2].price')), 0)
								+  IFNULL(OW_LAO.CASTDECIMAL(JSON_VALUE(PO_.TRADE_IN_OPTION, '$.evaluatedProducts[3].price')), 0)					
						  END
						,OW_LAO.CASTDECIMAL(JSON_VALUE(PO_.TRADE_IN_OPTION, '$.oferta') )
				 ) AS TRADE_IN_PRODUCT_PRICE				
				
				, PO_.COUPON
				
				, IT.QTY_ITEMS_ORDER
				, CE.QTY_ITEMS_ORDER_ET
				, PO_.CUSTOM_DATA_ID
			FROM OW_LAO.TMP_PO_VTEX_TRADE_IN_DETAIL PO_
				
				LEFT JOIN U_PRJ_ECOM.ODS_VTEX_SSG_BR_SHOP_DATA_ENTITIES_STORES_SDS ES
					ON ES.ID_STORE = PO_.STORE_ID -- ENDLESS_STORE
								
				LEFT JOIN(
			       /***** (CONTADOR TRADEIN) CONTA TOTAL DE ITENS DA ORDER ***/
					SELECT 
						 ORDER_ID
						,COUNT('') AS QTY_ITEMS_ORDER
					FROM OW_LAO.TMP_PO_VTEX_TRADE_IN_DETAIL
					GROUP BY
						ORDER_ID
				) IT ON PO_.ORDER_ID = IT.ORDER_ID
				LEFT JOIN( 
			       /***** (CONTADOR ECOTROCA) CONTA TOTAL DE ITENS DA ORDER (SEM OS 3 ULTIMOS DIG EX "-01") ***/ 
					SELECT 
						 SUBSTRING(ORDER_ID, 1, LENGTH(ORDER_ID) - 3) AS ORDER_ID -- ORDER SEM OS 3 ULTIMOS DIG EX "-01"
						,COUNT('') AS QTY_ITEMS_ORDER_ET
					FROM OW_LAO.TF_D2C_PO_VTEX_TRADE_IN
					GROUP BY
						SUBSTRING(ORDER_ID, 1, LENGTH(ORDER_ID) - 3) --AS ORDER_ID
				) CE ON (SUBSTRING(PO_.ORDER_ID, 1, LENGTH(PO_.ORDER_ID) - 3)) = IT.ORDER_ID					
		) PO
		LEFT JOIN OW_MD.DIM_SALES_CHANNEL CH ON PO.SALES_CHANNEL = CH.VTEX_POLICY
		LEFT JOIN OW_MD.DIM_PRODUCT PD ON PD.SKU = PO.REFERENCE_CODE
		LEFT JOIN (   SELECT DISTINCT TRIM(ITEM) AS MATERIAL
					  FROM OW_LAO.ODS_GSCM_PREMIUM_MODELS
				  ) PR ON PR.MATERIAL = PO.REFERENCE_CODE
		LEFT JOIN OW_MD.DIM_CALENDAR CL ON CL.YYYYMMDD = PO.DATE_REF
		LEFT JOIN OW_LAO.DIM_AFFILIATE_CHANNEL AF ON AF.AFFILIATE_ID = PO.AFFILIATE_ID_ADJUSTED
		LEFT JOIN OW_LAO.FT_AP2_EXCHANGE_RATE EX ON EX.VALID_FROM = PO.DATE_REF
												AND EX.TO_CURRENCY = 'BRL' -- AF.CURRENCY
												AND EX.FROM_CURRENCY = 'USD'
		LEFT JOIN (
			SELECT TO_CURRENCY
				 , VALID_FROM
				 , EXCHANGE_RATE
			FROM (
				SELECT TO_CURRENCY
					 , VALID_FROM
					 , EXCHANGE_RATE
					 , RANK() OVER( PARTITION BY TO_CURRENCY ORDER BY VALID_FROM DESC) AS SEQ
				FROM OW_LAO.FT_AP2_EXCHANGE_RATE EX 
				WHERE FROM_CURRENCY = 'USD'
			)
			WHERE SEQ = 1
		) EX2 ON EX2.TO_CURRENCY = 'BRL' -- AF.CURRENCY
		
		LEFT JOIN( -- PEGA O SELECTED_SLA
			SELECT OS.ORDER_ID
				 , OS.ITEM_INDEX
				 , MAX(JSON_VALUE('[' || OS.PICKUP_STORE_INFO || ']', '$.address.addressType')) AS ADDRESSTYPE
				 , MAX(JSON_VALUE('[' || OS.PICKUP_STORE_INFO || ']', '$.friendlyName')) AS FRIENDLYNAME
				 , MAX(OS.STATE) AS STATE
				 , MAX(OS.CITY) AS CITY
				 , MAX(OS.SELECTED_SLA) AS SELECTED_SLA
				 , STRING_AGG(OS.WAREHOUSE_ID, ' | ') AS WAREHOUSE_ID_GROUP
			FROM U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER_SHIPPING OS
				INNER JOIN OW_LAO.TMP_PO_ORDER_ID_PO_VTEX_TRADE_IN OD ON OD.ORDER_ID = OS.ORDER_ID
			GROUP BY OS.ORDER_ID
				   , OS.ITEM_INDEX
		) SL ON PO.ORDER_ID = SL.ORDER_ID AND SL.ITEM_INDEX = PO.ITEM_INDEX	
	)
 	--)
	;
	/*********************************************************
	* ATUALIZA IS_GTI PARA CSP'S
	* *******************************************************/
	UPDATE FT SET 
		IS_GTI = TRUE
	FROM OW_LAO.TF_D2C_PO_VTEX_TRADE_IN FT
		 INNER JOIN (SELECT DISTINCT ORDER_ID 
		             FROM OW_LAO.TMP_PO_VTEX_TRADE_IN_DETAIL
		 ) OD ON OD.ORDER_ID = FT.ORDER_ID
	WHERE STORE_TYPE_O2O = 'CSP'
		AND TRADE_IN_BOOST IS NOT NULL
		AND IFNULL(IS_GTI,FALSE) <> TRUE;
	
	/*********************************************************
	* ATUALIZA TF_D2C_NERP_SALES COM FLAGS :
	* 		 IS_TRADE_IN, IS_GTI E IS_ECO_TROCA
	* *******************************************************/	
	UPDATE NS SET 
		  IS_TRADE_IN = TI.IS_TRADE_IN
		, IS_GTI = TI.IS_GTI
		, IS_ECO_TROCA = TI.IS_ECO_TROCA
	FROM OW_LAO.TF_D2C_NERP_SALES NS
		INNER JOIN (
			SELECT 
				  FT.ORDER_ID
				, CASE WHEN UPPER(MAX(IS_TRADE_IN)) = 'TRUE' THEN TRUE ELSE FALSE END AS IS_TRADE_IN
				, CASE WHEN MAX(CAST(IS_GTI AS INTEGER)) = 1 THEN TRUE ELSE FALSE END AS IS_GTI
				, CASE WHEN MAX(CAST(IS_ECO_TROCA AS INTEGER)) = 1 THEN TRUE ELSE FALSE END AS IS_ECO_TROCA
			FROM OW_LAO.TF_D2C_PO_VTEX_TRADE_IN FT
				 --INNER JOIN (SELECT DISTINCT ORDER_ID 
				 --			 FROM OW_LAO.TMP_PO_VTEX_TRADE_IN_DETAIL
				 --) OD ON OD.ORDER_ID = FT.ORDER_ID
			GROUP BY
				  FT.ORDER_ID
		) TI ON NS.ORDER_ID = TI.ORDER_ID 
	WHERE NS."SOURCE" = 'PO'
		AND NS.SUBSIDIARY = 'SEDA'
		AND (
			   IFNULL(NS.IS_TRADE_IN,FALSE) <> TI.IS_TRADE_IN
			OR IFNULL(NS.IS_GTI,FALSE) <> TI.IS_GTI
			OR IFNULL(NS.IS_ECO_TROCA,FALSE) <> TI.IS_ECO_TROCA
		);
	
	UPDATE NS SET IS_TRADE_IN = FALSE
	FROM OW_LAO.TF_D2C_NERP_SALES NS
	WHERE NS."SOURCE" = 'PO' AND NS.SUBSIDIARY = 'SEDA' AND NS.IS_TRADE_IN IS NULL;
	
	UPDATE NS SET IS_GTI = FALSE
	FROM OW_LAO.TF_D2C_NERP_SALES NS
	WHERE NS."SOURCE" = 'PO' AND NS.SUBSIDIARY = 'SEDA' AND NS.IS_GTI IS NULL ;
	
	UPDATE NS SET IS_ECO_TROCA = FALSE
	FROM OW_LAO.TF_D2C_NERP_SALES NS
	WHERE NS."SOURCE" = 'PO' AND NS.SUBSIDIARY = 'SEDA' AND NS.IS_ECO_TROCA IS NULL ;
	
	/*********************************************************
	* ATUALIZA STATUS CASO TENHA MUDADO
	* *******************************************************/		
	UPDATE FT SET FT.STATUS_PO = BSO.STATUS
	FROM OW_LAO.TF_D2C_PO_VTEX_TRADE_IN FT
		INNER JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER BSO ON FT.ORDER_ID = BSO.ORDER_ID
	WHERE FT.STATUS_PO <> BSO.STATUS;
	
	/***** APAGA TABELAS TEMPORÁRIAS ***/
	DROP TABLE OW_LAO.TMP_PO_ORDER_ID_PO_VTEX_TRADE_IN;
	DROP TABLE OW_LAO.TMP_ITEM_COMPONENTS_PO_VTEX_TRADE_IN;
	DROP TABLE OW_LAO.TMP_PO_VTEX_TRADE_IN_DETAIL;
	
END