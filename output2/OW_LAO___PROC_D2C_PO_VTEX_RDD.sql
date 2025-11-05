/***********************************************************************************************
CREATED BY : Luciano Mariani
CREATION DATE : 2023-11-13
ALTER BY : Luciano Mariani
ALTER DATE : 2023-12-15
CALL OW_LAO.PROC_D2C_PO_VTEX_RDD ( ADD_DAYS(CURRENT_TIMESTAMP, -39),  ADD_DAYS(CURRENT_TIMESTAMP, 1))
SELECT TOP 10 * FROM OW_LAO.TF_D2C_PO_VTEX_RDD
WHERE STATUS_PO like '%ful%' 
SELECT CONVERT_TZ('2023-01-01 12:00:00', 'GMT', '+03:00') AS data_brasilia FROM dummy;
***********************************************************************************************/
CREATE PROCEDURE OW_LAO.PROC_D2C_PO_VTEX_RDD(
	  p_DATE_INI DATE DEFAULT NULL
	, P_DATE_FIM DATE DEFAULT NULL
) LANGUAGE SQLSCRIPT
AS
BEGIN
	
	/*********************************************************
	* CRIA A TMP_PARAMETER_VTEX_RDD SELECT * FROM OW_LAO.TMP_PARAMETER_VTEX_RDD
	* *******************************************************/
	 IF EXISTS ( SELECT TABLE_NAME FROM SYS.TABLES WHERE SCHEMA_NAME = 'OW_LAO' AND TABLE_NAME = 'TMP_PARAMETER_VTEX_RDD' ) THEN
		DROP TABLE OW_LAO.TMP_PARAMETER_VTEX_RDD;
	 END IF ;
	 CREATE COLUMN TABLE OW_LAO.TMP_PARAMETER_VTEX_RDD AS (
		SELECT ADD_DAYS(CURRENT_TIMESTAMP, -30) AS DATE_INI, ADD_DAYS(CURRENT_TIMESTAMP, 2) AS DATE_FIM FROM DUMMY
	 );
	 UPDATE OW_LAO.TMP_PARAMETER_VTEX_RDD SET
		 DATE_INI = IFNULL(p_DATE_INI, ADD_DAYS(CURRENT_TIMESTAMP, -30)) -- 30 dias dafault
		,DATE_FIM = IFNULL(P_DATE_FIM, ADD_DAYS(CURRENT_TIMESTAMP, 2)) 
	 ;
	 
	 /*********************************************************
	 * TABELA TEMPORÁRIA - TMP_PO_ORDER_ID_PO_VTEX_RDD
	 * SEPARA ORDER QUE SERÃO BUSCADAS NA VTEX
	 * E CLASSIFICA O CUSTOMER_PO SELECT * FROM OW_LAO.TMP_PO_ORDER_ID_PO_VTEX_RDD
	 * *******************************************************/
	  IF EXISTS( SELECT TABLE_NAME FROM SYS.TABLES WHERE SCHEMA_NAME = 'OW_LAO' AND TABLE_NAME = 'TMP_PO_ORDER_ID_PO_VTEX_RDD') THEN
	        DROP TABLE OW_LAO.TMP_PO_ORDER_ID_PO_VTEX_RDD;
	  END IF;
	  CREATE COLUMN TABLE OW_LAO.TMP_PO_ORDER_ID_PO_VTEX_RDD AS(
	        SELECT V.ORDER_ID
				 , MAX( CASE WHEN S.CUSTOMER_PO IS NOT NULL THEN S.CUSTOMER_PO ELSE CAST("SEQUENCE" AS VARCHAR(100)) END ) AS CUSTOMER_PO
	        FROM U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER V
	              LEFT JOIN OW_LAO.ODS_NERP_ZRSDD6A120_SALES_ORDER_TRACKING S ON V.ORDER_ID = S.CUSTOMER_PO
	        --WHERE V.CREATION_TIMESTAMP BETWEEN ADD_DAYS(CURRENT_TIMESTAMP, -30) AND ADD_DAYS(CURRENT_TIMESTAMP, 10)
	        WHERE V.CREATION_TIMESTAMP BETWEEN ( SELECT DATE_INI FROM OW_LAO.TMP_PARAMETER_VTEX_RDD ) AND (SELECT DATE_FIM FROM OW_LAO.TMP_PARAMETER_VTEX_RDD )
	        	  AND V.STATUS IS NOT NULL
	        	  AND V.ORDER_ID <> '1413902933157-01'
	        GROUP BY
	              V.ORDER_ID
	  );
	  DROP TABLE OW_LAO.TMP_PARAMETER_VTEX_RDD;
	 
	 /*********************************************************
	 * TABELA TEMPORÁRIA - TMP_ITEM_COMPONENTS_PO_VTEX_RDD
	 *  COMPONENTS (KITS) QUE SERÃO USADOS
	 * NAS 2 ETAPAS (ORDER SEM KITS E ORDERS COM KIT)
	 * *******************************************************/        
	  IF EXISTS( SELECT TABLE_NAME FROM SYS.TABLES WHERE SCHEMA_NAME = 'OW_LAO' AND TABLE_NAME = 'TMP_ITEM_COMPONENTS_PO_VTEX_RDD' ) THEN
	  	 DROP TABLE OW_LAO.TMP_ITEM_COMPONENTS_PO_VTEX_RDD;
	  END IF;
	  CREATE COLUMN TABLE OW_LAO.TMP_ITEM_COMPONENTS_PO_VTEX_RDD AS(
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
	              INNER JOIN OW_LAO.TMP_PO_ORDER_ID_PO_VTEX_RDD TP ON CP.ORDER_ID = TP.ORDER_ID
	        WHERE (CP.REF_ID IS NOT NULL)
	  );
	
	 /*********************************************************
	 * TABELA TEMPORÁRIA - TMP_PO_VTEX_RDD_DETAIL
	 * RETORNA OS DETALHES DAS ORDER NA VTEX
	 * SEPARADAS EM 2 ETAPAS (ORDER SEM KITS E ORDERS COM KIT)
	 * *******************************************************/
	IF EXISTS( SELECT TABLE_NAME FROM SYS.TABLES WHERE SCHEMA_NAME = 'OW_LAO' AND TABLE_NAME = 'TMP_PO_VTEX_RDD_DETAIL') THEN
		DROP TABLE OW_LAO.TMP_PO_VTEX_RDD_DETAIL;
	END IF;
	CREATE COLUMN TABLE OW_LAO.TMP_PO_VTEX_RDD_DETAIL AS(
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
                    , COALESCE( EPO.AUTHORIZED_DATE, SSO.AUTHORIZED_DATE,  BSO.AUTHORIZED_DATE) AS AUTHORIZED_DATE                
                    , CASE
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
								
					, CASE
						WHEN JSON_VALUE(EPO.CUSTOM_DATA , '$.customApps[0].id') IN (
											  'integration-marketplace-magazineluiza'
											, 'integration-marketplace-skyhub'
											, 'marketplace-integration'
											, 'integration-marketplace-amazon'
											, 'integration-marketplace-viavarejo'
											, 'integration-marketplace-carrefour'
										)
						THEN EPO.CUSTOM_DATA
						WHEN JSON_VALUE(SSO.CUSTOM_DATA , '$.customApps[0].id') IN (
											  'integration-marketplace-magazineluiza'
											, 'integration-marketplace-skyhub'
											, 'marketplace-integration'
											, 'integration-marketplace-amazon'
											, 'integration-marketplace-viavarejo'
											, 'integration-marketplace-carrefour'
										)
						THEN SSO.CUSTOM_DATA
						WHEN JSON_VALUE(BSO.CUSTOM_DATA , '$.customApps[0].id') IN (
											  'integration-marketplace-magazineluiza'
											, 'integration-marketplace-skyhub'
											, 'marketplace-integration'
											, 'integration-marketplace-amazon'
											, 'integration-marketplace-viavarejo'
											, 'integration-marketplace-carrefour'
										)
						THEN BSO.CUSTOM_DATA
					END AS RDD_CUSTOM_DATA
					
              FROM OW_LAO.TMP_PO_ORDER_ID_PO_VTEX_RDD LI -- (LISTA DE ALTERAÇÕES E INSERÇÕES)
                    
                    /********** BR SHOP  ***********/
                    INNER JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER BSO -- (BR SHOP - ORDER )
                          ON BSO.ORDER_ID = LI.ORDER_ID
                    
                    INNER JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER_ITEM BSI -- (BR SHOP - ITEM)
                          ON BSO.ORDER_ID = BSI.ORDER_ID
                    
                    LEFT JOIN OW_LAO.TMP_ITEM_COMPONENTS_PO_VTEX_RDD BSC -- (BR SHOP - COMPONENTES) [NÃO DEVE TER COMPONENTS POR ISSO LEFT]
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
                    , COALESCE( EPO.AUTHORIZED_DATE, SSO.AUTHORIZED_DATE,  BSO.AUTHORIZED_DATE) AS AUTHORIZED_DATE
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
								
					, CASE
						WHEN JSON_VALUE(EPO.CUSTOM_DATA , '$.customApps[0].id') IN (
											  'integration-marketplace-magazineluiza'
											, 'integration-marketplace-skyhub'
											, 'marketplace-integration'
											, 'integration-marketplace-amazon'
											, 'integration-marketplace-viavarejo'
											, 'integration-marketplace-carrefour'
										)
						THEN EPO.CUSTOM_DATA
						WHEN JSON_VALUE(SSO.CUSTOM_DATA , '$.customApps[0].id') IN (
											  'integration-marketplace-magazineluiza'
											, 'integration-marketplace-skyhub'
											, 'marketplace-integration'
											, 'integration-marketplace-amazon'
											, 'integration-marketplace-viavarejo'
											, 'integration-marketplace-carrefour'
										)
						THEN SSO.CUSTOM_DATA
						WHEN JSON_VALUE(BSO.CUSTOM_DATA , '$.customApps[0].id') IN (
											  'integration-marketplace-magazineluiza'
											, 'integration-marketplace-skyhub'
											, 'marketplace-integration'
											, 'integration-marketplace-amazon'
											, 'integration-marketplace-viavarejo'
											, 'integration-marketplace-carrefour'
										)
						THEN BSO.CUSTOM_DATA
					END AS RDD_CUSTOM_DATA
					
              FROM OW_LAO.TMP_PO_ORDER_ID_PO_VTEX_RDD LI -- (LISTA DE ALTERAÇÕES E INSERÇÕES)
                    
                    /********** BR SHOP  ***********/
                    INNER JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER BSO -- (BR SHOP - ORDER )
                          ON BSO.ORDER_ID = LI.ORDER_ID
                    
                    INNER JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER_ITEM BSI -- (BR SHOP - ITEM)
                          ON BSO.ORDER_ID = BSI.ORDER_ID
                    
                    INNER JOIN OW_LAO.TMP_ITEM_COMPONENTS_PO_VTEX_RDD BSC -- (BR SHOP - COMPONENTES) [NÃO DEVE TER COMPONENTS POR ISSO LEFT]
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
			/*******************************************************************************
			 *    CASO NÃO SEJA UM DOS customApps ID LISTADOS NO CAMPO RDD_CUSTOM_DATA É NULO
			********************************************************************************/
		    -- AND RDD_CUSTOM_DATA IS NOT NULL -- TEM DE TER ALGUM RDD_CUSTOM_DATA
	    
			AND (CASE   
					WHEN JSON_VALUE(RDD_CUSTOM_DATA, '$.customApps[0].id') IN (
																				  'integration-marketplace-amazon' -- Amazon
																				, 'integration-marketplace-viavarejo' -- Via
																				, 'integration-marketplace-magazineluiza' -- Magalu
																				, 'integration-marketplace-skyhub' -- Americanas
																				, 'marketplace-integration' -- 	Meli					
																			  )
						AND PO_CREATION_DATE >= '2024-07-24'
					THEN 1
					WHEN JSON_VALUE(RDD_CUSTOM_DATA, '$.customApps[0].id') = 'integration-marketplace-carrefour' -- carrefour
						AND PO_CREATION_DATE >= '2024-08-05'
					THEN 1
					ELSE 0
			END) = 1			
		    
		    /*******
			AND CASE   
					WHEN JSON_VALUE(RDD_CUSTOM_DATA, '$.customApps[0].id') = 'integration-marketplace-magazineluiza' THEN 
						JSON_VALUE(RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate')
					WHEN JSON_VALUE(RDD_CUSTOM_DATA, '$.customApps[0].id') = 'integration-marketplace-skyhub' THEN
						JSON_VALUE(RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate')
					WHEN JSON_VALUE(RDD_CUSTOM_DATA, '$.customApps[0].id') = 'marketplace-integration' THEN
						JSON_VALUE(RDD_CUSTOM_DATA, '$.customApps[0].fields.creationDate')
					WHEN JSON_VALUE(RDD_CUSTOM_DATA, '$.customApps[0].id') = 'integration-marketplace-amazon' THEN
						JSON_VALUE(RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate')
					WHEN JSON_VALUE(RDD_CUSTOM_DATA, '$.customApps[0].id') = 'integration-marketplace-viavarejo' THEN
						JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate')
				END  IS NOT NULL --AS MKT_CREATION_DATE		
			***********/    
		    
	);
 	/********************************************************
	* LIMPA ORDERS CASO EXISTAM NA TABELA FINAL
	* DROP TABLE OW_LAO.TF_D2C_PO_VTEX_RDD
	********************************************************/
	DELETE FROM OW_LAO.TF_D2C_PO_VTEX_RDD
	WHERE ORDER_ID IN ( SELECT DISTINCT ORDER_ID
					    FROM OW_LAO.TMP_PO_VTEX_RDD_DETAIL
				      );
	/*********************************************************
	* ALIMENTA TABELA FINAL - TF_D2C_PO_VTEX_RDD
	* RETORNA OS DETALHES DAS ORDER NA VTEX -- DROP TABLE OW_LAO.TF_D2C_PO_VTEX_RDD
	* SEPARADAS EM 2 ETAPAS (ORDER SEM KITS E ORDERS COM KIT) 
	* *******************************************************/
	INSERT INTO OW_LAO.TF_D2C_PO_VTEX_RDD
	--CREATE COLUMN TABLE OW_LAO.TF_D2C_PO_VTEX_RDD AS(
	SELECT 
		  DATE_REF
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
		, AFFILIATE_ID_ADJUSTED
		, AFFILIATE_CHANNEL
		, AFFILIATE_SUB_CHANNEL
		, AFFILIATE_PARTNER_LEVEL
		, GLOBAL_CHANNEL
		, BIZ_TYPE
		, AUDIENCE_TYPE
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
	 	   
		, AUTHORIZED_DATE
		, STATUS_PO	 	   
		, ID_INTEGRATION
		--,  
			-- SELECT TO_TIMESTAMP('08/01/2024 02:59:59', 'MM/DD/YYYY HH24:MI:SS')  FROM DUMMY;
			/*** CASE 
				WHEN INSTR(MKT_CREATION_DATE, '/') > 0 THEN 
					TO_TIMESTAMP(MKT_CREATION_DATE, 'MM/DD/YYYY HH24:MI:SS')
				WHEN INSTR(MKT_CREATION_DATE, '-') > 0 THEN 
					TO_TIMESTAMP(replace(replace(MKT_CREATION_DATE,'z',''),'t',''))
			END AS MKT_CREATION_DATE ***/
		, ADD_SECONDS(MKT_CREATION_DATE, -10800) AS MKT_CREATION_DATE
		--, MKT_CREATION_DATE 
			-- CAST(MKT_CREATION_DATE AS TIMESTAMP) AS MKT_CREATION_DATE
		, MKT_LEAD_TIME
		--, MKT_LEAD_TIME
		--, TO_DATE(ADD_SECONDS(MKT_DELIVERY_DATE, -10800)) AS MKT_DELIVERY_DATE
		, MKT_DELIVERY_DATE
		--KPI_LAST_UPDATE
		, CURRENT_TIMESTAMP AS LAST_UPDATE
		
			/*****************************************************
			-- Quando [Status] = "authorize-fulfillment" fazer o calculo, senão trazer o próprio [estimatedDeliveryDate].
			-- Lógica [estimatedDeliveryDate_revised] = [authorized date] + ([estimatedDeliveryDate] - [creationDate do Marketplace])
			*****************************************************/				
			, CASE
				WHEN STATUS_PO = 'authorize-fulfillment' THEN
					-- AUTHORIZED_DATE + (MKT_DELIVERY_DATE - PO_CREATION_DATE)
					ADD_DAYS(AUTHORIZED_DATE, DAYS_BETWEEN(PO_CREATION_DATE, MKT_DELIVERY_DATE))
				ELSE
					MKT_DELIVERY_DATE	
			END
			
			AS estimatedDeliveryDate_revised		
	FROM(
		SELECT
			   PO.DATE_REF
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
			, AF.COUNTRY
			, AF.CURRENCY
			
			-- PREMIUM MODEL
			, CASE WHEN PR.MATERIAL IS NOT NULL THEN 'PREMIUM MODEL' ELSE 'NORMAL MODEL' END AS MODEL_TYPE
			, PO.ID_INTEGRATION
			, PO.MKT_CREATION_DATE	
			, PO.MKT_LEAD_TIME
			, PO.MKT_DELIVERY_DATE	
			, PO.AUTHORIZED_DATE
			
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
					
				, PO_.AUTHORIZED_DATE		
			
				, JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].id') AS ID_INTEGRATION
				
				-- ********** MKT_CREATION_DATE *************
				--, PO_.RDD_CUSTOM_DATA 
				, CASE
					
					WHEN JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].id') = 'integration-marketplace-magazineluiza' THEN 
						--JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate')
						CASE
							WHEN INSTR( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate' ) , '/') > 0 THEN 
								TO_TIMESTAMP( replace(REPLACE( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate'),'Z',''),'t',''), 'MM/DD/YYYY HH24:MI:SS')
							WHEN INSTR( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate') , '-') > 0 THEN 
								TO_TIMESTAMP( replace(REPLACE( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate' ),'Z',''),'t',''))
						END
						
					WHEN JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].id') = 'integration-marketplace-skyhub' THEN
						--JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate')
						CASE 
							WHEN INSTR( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate') , '/') > 0 THEN 
								TO_TIMESTAMP( replace(REPLACE( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate'),'Z',''),'t',''), 'MM/DD/YYYY HH24:MI:SS')
							WHEN INSTR( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate') , '-') > 0 THEN 
								TO_TIMESTAMP( replace(REPLACE( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate'),'Z',''),'t',''))
						END
						
					WHEN JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].id') = 'marketplace-integration' THEN
						--JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.creationDate')
						CASE 
							WHEN INSTR( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.creationDate') , '/') > 0 THEN 
								TO_TIMESTAMP( replace(REPLACE( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.creationDate'),'Z',''),'t',''), 'MM/DD/YYYY HH24:MI:SS')
							WHEN INSTR( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.creationDate') , '-') > 0 THEN 
								TO_TIMESTAMP( replace(REPLACE( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.creationDate'),'Z',''),'t',''))
						END
						
					WHEN JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].id') = 'integration-marketplace-amazon' THEN
						-- JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate')
						CASE 
							WHEN INSTR( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate') , '/') > 0 THEN 
								TO_TIMESTAMP( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate'), 'MM/DD/YYYY HH24:MI:SS')
							WHEN INSTR( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate') , '-') > 0 THEN 
								TO_TIMESTAMP( replace(replace(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate'),'z',''),'t',''))
						END
						
					WHEN JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].id') = 'integration-marketplace-viavarejo' THEN
						--JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate')
						CASE 
							WHEN INSTR( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate') , '/') > 0 THEN 
								TO_TIMESTAMP( replace(REPLACE(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate'),'Z',''),'t',''), 'MM/DD/YYYY HH24:MI:SS')
							WHEN INSTR( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate') , '-') > 0 THEN 
								TO_TIMESTAMP( replace(REPLACE(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate'),'Z',''),'t',''))
						END
						
					WHEN JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].id') = 'integration-marketplace-carrefour' THEN
						--JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate')
						CASE 
							WHEN INSTR( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate') , '/') > 0 THEN 
								TO_TIMESTAMP( replace(REPLACE(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate'),'Z',''),'t',''), 'MM/DD/YYYY HH24:MI:SS')
							WHEN INSTR( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate') , '-') > 0 THEN 
								TO_TIMESTAMP( replace(REPLACE(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate'),'Z',''),'t',''))
						END						
						
				END AS MKT_CREATION_DATE	
				
				-- ***************** MKT_LEAD_TIME ************
				, CASE
					
					WHEN JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].id') = 'integration-marketplace-magazineluiza' THEN 
						NULL -- JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.')
					
					WHEN JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].id') = 'integration-marketplace-skyhub' THEN
						NULL -- JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.')
					
					WHEN JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].id') = 'marketplace-integration' THEN
						--SUBSTRING(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.estimatedDeliveryInfo'), 1, INSTR(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.estimatedDeliveryInfo'), ' ') - 1)
						  CAST(
							CASE WHEN OW_LAO.ISNUMERIC(SUBSTRING(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.estimatedDeliveryInfo'), 1, INSTR(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.estimatedDeliveryInfo'), ' ') - 1) ) = 1 THEN 
								SUBSTRING(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.estimatedDeliveryInfo'), 1, INSTR(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.estimatedDeliveryInfo'), ' ') - 1)  END	
						  AS INT) --/ 24
					
					WHEN JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].id') = 'integration-marketplace-amazon' THEN
						NULL -- JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.')
					
					WHEN JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].id') = 'integration-marketplace-viavarejo' THEN
						JSON_VALUE(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceEstimatedDeliveryInfo'), '$.freight.transitTime')
					
					WHEN JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].id') = 'integration-marketplace-carrefour' THEN
						CASE WHEN OW_LAO.ISNUMERIC(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceEstimatedDeliveryDays')) = 1 THEN 
							JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceEstimatedDeliveryDays') END						
					
				END AS MKT_LEAD_TIME
				
				-- ************ MKT_DELIVERY_DATE **********
				, CASE
					
					WHEN JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].id') = 'integration-marketplace-magazineluiza' THEN 
						--TO_DATE(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceEstimatedDeliveryDate'))
						ADD_SECONDS( 
							CASE 
								WHEN INSTR( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceEstimatedDeliveryDate'), '/') > 0 THEN 
									TO_TIMESTAMP( replace(replace(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceEstimatedDeliveryDate'),'z',''),'t',''), 'MM/DD/YYYY HH24:MI:SS')
								WHEN INSTR( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceEstimatedDeliveryDate'), '-') > 0 THEN 
									TO_TIMESTAMP( replace(REPLACE(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceEstimatedDeliveryDate'),'Z',''),'t',''))
							END								
						, -10800)
						
					WHEN JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].id') = 'integration-marketplace-skyhub' THEN
						--TO_DATE(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceEstimatedDeliveryDate'))
						ADD_SECONDS( 
							CASE 
								WHEN INSTR( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceEstimatedDeliveryDate') , '/') > 0 THEN 
									TO_TIMESTAMP( replace(replace(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceEstimatedDeliveryDate'),'z',''),'t',''), 'MM/DD/YYYY HH24:MI:SS')
								WHEN INSTR( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceEstimatedDeliveryDate'), '-') > 0 THEN 
									TO_TIMESTAMP( replace(replace(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceEstimatedDeliveryDate'),'z',''),'t','') )
							END							
						, -10800)
						
					WHEN JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].id') = 'marketplace-integration' THEN
						--  OW_LAO.ADD_WORKING_DAYS('2024-07-25', 4)
						OW_LAO.ADD_WORKING_DAYS(
							  --JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.creationDate')
							ADD_SECONDS( 
									CASE 
										WHEN INSTR( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.creationDate') , '/') > 0 THEN 
											TO_TIMESTAMP( replace(replace(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.creationDate'),'z',''),'t',''), 'MM/DD/YYYY HH24:MI:SS')
										WHEN INSTR( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.creationDate') , '-') > 0 THEN 
											TO_TIMESTAMP( replace(replace(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.creationDate'),'z',''),'t','') )
									END	
							, -10800)
							, CAST(
								CASE WHEN OW_LAO.ISNUMERIC(SUBSTRING(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.estimatedDeliveryInfo'), 1, INSTR(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.estimatedDeliveryInfo'), ' ') - 1) ) = 1 THEN 
									SUBSTRING(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.estimatedDeliveryInfo'), 1, INSTR(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.estimatedDeliveryInfo'), ' ') - 1) 
								END
							  AS INT) / 24
						)
					WHEN JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].id') = 'integration-marketplace-amazon' THEN
						--TO_DATE(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceLatestDeliveryDate'))
						ADD_SECONDS( 
							CASE 
								WHEN INSTR( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceLatestDeliveryDate') , '/') > 0 THEN 
									TO_TIMESTAMP( replace(replace(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceLatestDeliveryDate'),'z',''),'t',''), 'MM/DD/YYYY HH24:MI:SS')
								WHEN INSTR( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceLatestDeliveryDate') , '-') > 0 THEN 
									TO_TIMESTAMP( replace(replace(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceLatestDeliveryDate'),'z',''),'t','') )
							END
						, -10800)
						
					WHEN JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].id') = 'integration-marketplace-viavarejo' THEN
						OW_LAO.ADD_WORKING_DAYS(
							  -- JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate')
								ADD_SECONDS( 
									CASE 
										WHEN INSTR( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate') , '/') > 0 THEN 
											TO_TIMESTAMP( replace(replace(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate'),'z',''),'t',''), 'MM/DD/YYYY HH24:MI:SS')
										WHEN INSTR( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate') , '-') > 0 THEN 
											TO_TIMESTAMP( replace(replace(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate'),'z',''),'t','') )
									END
								, -10800)
							, CAST(JSON_VALUE(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceEstimatedDeliveryInfo'), '$.freight.transitTime') AS INT) 
						)
						
					WHEN JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].id') = 'integration-marketplace-carrefour' THEN
						OW_LAO.ADD_WORKING_DAYS(
							  -- JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate')
								ADD_SECONDS( 
									CASE 
										WHEN INSTR( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate') , '/') > 0 THEN 
											TO_TIMESTAMP( replace(replace(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate'),'z',''),'t',''), 'MM/DD/YYYY HH24:MI:SS')
										WHEN INSTR( JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate') , '-') > 0 THEN 
											TO_TIMESTAMP( replace(replace(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceCreationDate'),'z',''),'t','') )
									END
								, -10800)
							, CAST( -- JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceEstimatedDeliveryDays') 
								CASE WHEN OW_LAO.ISNUMERIC(JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceEstimatedDeliveryDays')) = 1 THEN 
										  JSON_VALUE(PO_.RDD_CUSTOM_DATA, '$.customApps[0].fields.marketplaceEstimatedDeliveryDays') 
								END
							AS INT) 
	
						)
					
				END AS MKT_DELIVERY_DATE
			FROM OW_LAO.TMP_PO_VTEX_RDD_DETAIL PO_
				
				LEFT JOIN U_PRJ_ECOM.ODS_VTEX_SSG_BR_SHOP_DATA_ENTITIES_STORES_SDS ES
					ON ES.ID_STORE = PO_.STORE_ID -- ENDLESS_STORE
			
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
				INNER JOIN OW_LAO.TMP_PO_ORDER_ID_PO_VTEX_RDD OD ON OD.ORDER_ID = OS.ORDER_ID
			GROUP BY OS.ORDER_ID
				   , OS.ITEM_INDEX
		) SL ON PO.ORDER_ID = SL.ORDER_ID AND SL.ITEM_INDEX = PO.ITEM_INDEX	
	)
 	
	--)
	;
	/*********************************************************
	* ATUALIZA STATUS CASO TENHA MUDADO
	* *******************************************************/		
	UPDATE FT SET FT.STATUS_PO = BSO.STATUS
	FROM OW_LAO.TF_D2C_PO_VTEX_RDD FT
		INNER JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER BSO ON FT.ORDER_ID = BSO.ORDER_ID
	WHERE FT.STATUS_PO <> BSO.STATUS;
	
	/***** APAGA TABELAS TEMPORÁRIAS ***/
	DROP TABLE OW_LAO.TMP_PO_ORDER_ID_PO_VTEX_RDD;
	DROP TABLE OW_LAO.TMP_ITEM_COMPONENTS_PO_VTEX_RDD;
	DROP TABLE OW_LAO.TMP_PO_VTEX_RDD_DETAIL;
	
END