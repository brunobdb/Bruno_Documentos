/***********************************************************************************************
CREATED BY : João Brandão
CREATION DATE : 2025-07-17
CALL OW_LAO.PROC_D2C_VTEX_PAYMENT_SKU
SELECT TOP 100 * FROM OW_LAO.TF_D2C_VTEX_PAYMENT_SKU
-- VTEX_PAYMENTS
***********************************************************************************************/
--
CREATE PROCEDURE OW_LAO.PROC_D2C_VTEX_PAYMENT_SKU(
--CREATE OR REPLACE PROCEDURE OW_LAO.PROC_TESTE (
	  IN p_DATE_INI DATE DEFAULT NULL
	, IN p_DATE_FIM DATE DEFAULT NULL
)
LANGUAGE SQLSCRIPT
AS
BEGIN
	-- Declares a CLOB variable for custom JSON data.
	DECLARE v_JSON_CUSTOM_DATA CLOB;
	--
	/*********************************************************
	* CRIA A TMP_PARAMETER_VTEX_PAYMENT
	********************************************************/
	IF EXISTS ( SELECT 1 
	              FROM SYS.TABLES 
	             WHERE SCHEMA_NAME = 'OW_LAO' 
	               AND TABLE_NAME = 'TMP_PARAMETER_VTEX_PAYMENT' 
	          ) THEN
		DROP TABLE OW_LAO.TMP_PARAMETER_VTEX_PAYMENT;
	END IF ;
    --
	CREATE COLUMN TABLE OW_LAO.TMP_PARAMETER_VTEX_PAYMENT 
	   AS (
		   SELECT ADD_DAYS(CURRENT_TIMESTAMP, -7) AS DATE_INI
		         ,ADD_DAYS(CURRENT_TIMESTAMP,  2) AS DATE_FIM 
		     FROM DUMMY
	      );
    --
	UPDATE OW_LAO.TMP_PARAMETER_VTEX_PAYMENT 
	   SET
		  DATE_INI = IFNULL( p_DATE_INI, ADD_DAYS(CURRENT_TIMESTAMP, -7) ) -- 30 dias dafault
		, DATE_FIM = IFNULL( P_DATE_FIM, ADD_DAYS(CURRENT_TIMESTAMP,  2) ) 
	;
	--	
	------------------------------------------------------------------
	-- Checks if the temporary table 'TMP_PAYMENT_..' exists in schema 'OW_LAO'.
	IF EXISTS ( SELECT 1 
	              FROM SYS.TABLES 
	             WHERE SCHEMA_NAME = 'OW_LAO' 
	               AND TABLE_NAME = 'TMP_VTEX_PAYMENT_SALES' 
	          ) THEN
		DROP TABLE OW_LAO.TMP_VTEX_PAYMENT_SALES;
	END IF ;
	--
    --  
	------------------------------------------------------------------
	-- Creates a new table 'TMP_VTEX_PAYMENT_SALES'
	CREATE COLUMN TABLE OW_LAO.TMP_VTEX_PAYMENT_SALES
	AS (
		WITH CTE_TMP_PARAMETER_VTEX_PAYMENT
		  AS
		    (
			SELECT --
					DATE_INI,
					DATE_FIM
			FROM OW_LAO.TMP_PARAMETER_VTEX_PAYMENT 
		    )
			-----------
			-----------
			,CTE_TMP_01
		    AS
			(
			SELECT L.*
			FROM (
					SELECT DISTINCT -- *
							L.ORDER_ID
						   ,L.SEQUENCE
					       ,L.MARKETPLACE_ORDER_ID
						   ,L.STATUS 
						   ,l.CREATION_TIMESTAMP 
						   ,L.AUTHORIZED_DATE
						   ,L.STATUS_DESCRIPTION
					  FROM U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER AS L
				   --WHERE LIST.ORDER_ID IN ('SMB-1261642716378-01','SGP-1260391680258-01','SGP-1261160975591-01')
				) AS L
			)
			-----------
			-----------
			,CTE_TMP_02
			AS
			(
			SELECT T.*
			       --,COUNT(T.SKU) OVER(PARTITION BY T.ORDER_ID)   AS QT_SKU_PED
			 FROM ( 
					SELECT DISTINCT 
							L.ORDER_ID
						   ,L.SEQUENCE
					       ,L.MARKETPLACE_ORDER_ID
						   ,L.STATUS 
						   ,l.CREATION_TIMESTAMP 
						   ,L.AUTHORIZED_DATE
						   ,L.STATUS_DESCRIPTION
						   --
						   ,NS.DATE_REF
						   --,NS.ORDER_ID
						   --,NS.SEQUENCE
						   ,NS.STATUS_PO
						   --,NS.AFFILIATE_ID_ADJUSTED
						   ,NS.AFFILIATE_CHANNEL
						   ,NS.AFFILIATE_SUB_CHANNEL
						   ,NS.AFFILIATE_PARTNER_LEVEL
						   --,NS.SELLING_PRICE
					       ,SKU, QTY, AMOUNT_LOCAL, SELLING_AMOUNT_LOCAL
						   --
						   ,SEDA_BU_ESTORE
						   ,SEDA_DIVISION_ESTORE
						   ,SEDA_CATEGORY_ESTORE
						   ,SEDA_FAMILY_ESTORE
						   ,SEDA_DESC_ESTORE
						   --
					FROM OW_LAO.TF_D2C_NERP_SALES AS NS 
					--
					INNER JOIN CTE_TMP_01 AS L 
					        ON NS.ORDER_ID = L.ORDER_ID
					--        
					WHERE NS.SOURCE = 'PO'
					 --AND NS.STATUS_PO NOT LIKE '%cancel%'
						--
						AND NS.DATE_REF BETWEEN ( SELECT DATE_INI FROM CTE_TMP_PARAMETER_VTEX_PAYMENT )
										    AND ( SELECT DATE_FIM FROM CTE_TMP_PARAMETER_VTEX_PAYMENT )
			      ) AS T
			ORDER BY ORDER_ID, SKU
			)
			-----------
			-----------
		    --SELECT * FROM CTE_TMP_01
		    SELECT * FROM CTE_TMP_02
	   )
	;
	--
	--	
	------------------------------------------------------------------
	-- Checks if the temporary table 'TMP_PAYMENT_..' exists in schema 'OW_LAO'.
	IF EXISTS ( SELECT 1 
	              FROM SYS.TABLES 
	             WHERE SCHEMA_NAME = 'OW_LAO' 
	               AND TABLE_NAME = 'TMP_VTEX_PAYMENT_01' 
	          ) THEN
		DROP TABLE OW_LAO.TMP_VTEX_PAYMENT_01;
	END IF ;
    --
	------------------------------------------------------------------
	-- Creates a new table 'TMP_VTEX_PAYMENT'
	CREATE COLUMN TABLE OW_LAO.TMP_VTEX_PAYMENT_01
	AS (
		WITH CTE_TMP_01
			AS
			(
			SELECT DISTINCT 
					 P.ORDER_ID
					,P.PAYMENT_GROUP
					,P.ACQUIRER
					,P.TID, P.AUTH_ID, P.NSU
					,P.VALUE
					,P.INSTALLMENTS
					,P.PAYMENT_SYSTEM
					,P.PAYMENT_SYSTEM_NAME
					,P.UPDATED_AT
					--
					,P.FIRST_DIGITS	AS CARD_FIRST_DIGITS
					,P.LAST_DIGITS	AS CARD_LAST_DIGITS
					--
			  FROM       OW_LAO.TMP_VTEX_PAYMENT_SALES						 AS L 	
			  INNER JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER_PAYMENT AS P 
			         ON L.ORDER_ID = P.ORDER_ID
			ORDER BY ORDER_ID
			)
			-----------
			SELECT * FROM CTE_TMP_01
	   );			
	--
	--	
	------------------------------------------------------------------
	-- Checks if the temporary table 'TMP_PAYMENT_..' exists in schema 'OW_LAO'.
	IF EXISTS ( SELECT 1 
	              FROM SYS.TABLES 
	             WHERE SCHEMA_NAME = 'OW_LAO' 
	               AND TABLE_NAME = 'TMP_VTEX_PAYMENT_02' 
	          ) THEN
		DROP TABLE OW_LAO.TMP_VTEX_PAYMENT_02;
	END IF ;
    --
	------------------------------------------------------------------
	-- Creates a new table 'TMP_VTEX_PAYMENT'
	CREATE COLUMN TABLE OW_LAO.TMP_VTEX_PAYMENT_02
	AS (
		WITH CTE_TMP_BR
			AS
			(
			SELECT DISTINCT 
					 L.ORDER_ID
					--
					,P.PAYMENT_GROUP
					,P.ACQUIRER
					,P.TID, P.AUTH_ID, P.NSU
					,P.VALUE
					,P.INSTALLMENTS
					,P.PAYMENT_SYSTEM
					,P.PAYMENT_SYSTEM_NAME
					,P.UPDATED_AT
					--
					,P.FIRST_DIGITS	AS CARD_FIRST_DIGITS
					,P.LAST_DIGITS	AS CARD_LAST_DIGITS
					--
			  FROM       OW_LAO.TMP_VTEX_PAYMENT_SALES						AS L 	
			  INNER JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_SALES_ORDER_PAYMENT 	AS P 
			       --ON L.ORDER_ID = P.ORDER_ID
			         ON L.MARKETPLACE_ORDER_ID = P.ORDER_ID
			  WHERE 1=1 
			    AND P.PAYMENT_SYSTEM_NAME IS NOT NULL
			ORDER BY 1
			)
			-----------
			SELECT * FROM CTE_TMP_BR
	   );			
	--
	--	
	------------------------------------------------------------------
	-- Checks if the temporary table 'TMP_PAYMENT_..' exists in schema 'OW_LAO'.
	IF EXISTS ( SELECT 1 
	              FROM SYS.TABLES 
	             WHERE SCHEMA_NAME = 'OW_LAO' 
	               AND TABLE_NAME = 'TMP_VTEX_PAYMENT_03' 
	          ) THEN
		DROP TABLE OW_LAO.TMP_VTEX_PAYMENT_03;
	END IF ;
    --
	------------------------------------------------------------------
	-- Creates a new table 'TMP_VTEX_PAYMENT'
	CREATE COLUMN TABLE OW_LAO.TMP_VTEX_PAYMENT_03
	AS (
		WITH CTE_TMP_EPP
			AS
			(
			SELECT DISTINCT 
					 L.ORDER_ID
					--
					,P.PAYMENT_GROUP
					,P.ACQUIRER
					,P.TID, P.AUTH_ID, P.NSU
					,P.VALUE
					,P.INSTALLMENTS
					,P.PAYMENT_SYSTEM
					,P.PAYMENT_SYSTEM_NAME
					,P.UPDATED_AT
					--
					,P.FIRST_DIGITS	AS CARD_FIRST_DIGITS
					,P.LAST_DIGITS	AS CARD_LAST_DIGITS
					--
			  FROM       OW_LAO.TMP_VTEX_PAYMENT_SALES						AS L 	
			  INNER JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_EPP2_SALES_ORDER_PAYMENT AS P 
			       --ON L.ORDER_ID = P.ORDER_ID
			         ON L.MARKETPLACE_ORDER_ID = P.ORDER_ID
			  WHERE 1=1 
			    AND P.PAYMENT_SYSTEM_NAME IS NOT NULL
			ORDER BY 1
			)
			-----------
			SELECT * FROM CTE_TMP_EPP
	   );			
	--
	--	
	------------------------------------------------------------------
	-- Checks if the temporary table 'TMP_PAYMENT_..' exists in schema 'OW_LAO'.
	IF EXISTS ( SELECT 1 
	              FROM SYS.TABLES 
	             WHERE SCHEMA_NAME = 'OW_LAO' 
	               AND TABLE_NAME = 'TMP_VTEX_PAYMENT_04' 
	          ) THEN
		DROP TABLE OW_LAO.TMP_VTEX_PAYMENT_04;
	END IF ;
    --
	------------------------------------------------------------------
	-- Creates a new table 'TMP_VTEX_PAYMENT'
	CREATE COLUMN TABLE OW_LAO.TMP_VTEX_PAYMENT_04
	AS (
		WITH CTE_TMP_B2B
			AS
			(
			SELECT DISTINCT 
					 L.ORDER_ID
					--
					,P.PAYMENT_GROUP
					,P.ACQUIRER
					,P.TID, P.AUTH_ID, P.NSU
					,P.VALUE
					,P.INSTALLMENTS
					,P.PAYMENT_SYSTEM
					,P.PAYMENT_SYSTEM_NAME
					,P.UPDATED_AT
					--
					,P.FIRST_DIGITS	AS CARD_FIRST_DIGITS
					,P.LAST_DIGITS	AS CARD_LAST_DIGITS
					--
			  FROM       OW_LAO.TMP_VTEX_PAYMENT_SALES						 AS L 	
			  INNER JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_B2B_SALES_ORDER_PAYMENT  AS P 
			       --ON L.ORDER_ID = P.ORDER_ID
			         ON L.MARKETPLACE_ORDER_ID = P.ORDER_ID
			  WHERE 1=1 
			    AND P.PAYMENT_SYSTEM_NAME IS NOT NULL
			ORDER BY 1
			)
			-----------
			SELECT * FROM CTE_TMP_B2B
	   );			
	--
	--	
	------------------------------------------------------------------
	-- Checks if the temporary table 'TMP_PAYMENT_..' exists in schema 'OW_LAO'.
	IF EXISTS ( SELECT 1 
	              FROM SYS.TABLES 
	             WHERE SCHEMA_NAME = 'OW_LAO' 
	               AND TABLE_NAME = 'TMP_VTEX_PAYMENT' 
	          ) THEN
		DROP TABLE OW_LAO.TMP_VTEX_PAYMENT;
	END IF ;
    --
	------------------------------------------------------------------
	-- Creates a new table 'TMP_VTEX_PAYMENT'
	CREATE COLUMN TABLE OW_LAO.TMP_VTEX_PAYMENT
	AS (
		WITH CTE_BASE
		    AS
		    (
			SELECT --
					L.ORDER_ID
				   ,L.SEQUENCE
			       ,L.MARKETPLACE_ORDER_ID
			       ,L.STATUS
				   -- 
				   --
				   ,COALESCE(P_B2B.TID
				            ,P_EPP.TID
				            ,P_BR.TID
				            ,P.TID)
				      AS TID
				   --
				   ,P_B2B.TID				AS B2B_TID
				   ,P_EPP.TID				AS EPP_TID
				   ,P_BR.TID				AS BRS_TID
				   ,P.TID					AS SHP_TID
				   --
				   ,P_B2B.CARD_FIRST_DIGITS	AS B2B_CARD_FIRST_DIGITS
				   ,P_EPP.CARD_FIRST_DIGITS	AS EPP_CARD_FIRST_DIGITS
				   ,P_BR.CARD_FIRST_DIGITS	AS BRS_CARD_FIRST_DIGITS
				   ,P.CARD_FIRST_DIGITS		AS SHP_CARD_FIRST_DIGITS 						    
				   --
				   ,P_B2B.CARD_LAST_DIGITS	AS B2B_CARD_LAST_DIGITS
				   ,P_EPP.CARD_LAST_DIGITS	AS EPP_CARD_LAST_DIGITS
				   ,P_BR.CARD_LAST_DIGITS	AS BRS_CARD_LAST_DIGITS
				   ,P.CARD_LAST_DIGITS		AS SHP_CARD_LAST_DIGITS 						    
				   --
				   --		
				   ,CASE --
					     WHEN L.AUTHORIZED_DATE IS NULL 
					     THEN 'PENDENTE' 
					     --
					     ELSE 'APROVADO' 
					     END 
					     AS   ORDERS_AUTHORIZATION
				   -- 	
				   --
				   ,CASE --CALCULOS--   
						 WHEN L.STATUS_DESCRIPTION IN ('Preparando Entrega', 'Faturado','Aguardando autorização para despachar','Pronto para o manuseio') 
						 THEN 'PAYMENT APPROVED' 
					  	 --
						 WHEN L.STATUS_DESCRIPTION IN ('Pagamento Pendente') 
						 THEN 'NOT PAYMENT APPROVED' 
						 --
						 WHEN L.STATUS_DESCRIPTION IN ('Pagamento Pendente') 
						 THEN 'NOT PAYMENT APPROVED'  
						 --
						 ELSE 'CHECK STATUS'
						 END 
					     AS STATUS_DESCRIPTION
				   --
				   ,P_B2B.PAYMENT_GROUP		AS B2B_PAYMENT_GROUP
				   ,P_EPP.PAYMENT_GROUP		AS EPP_PAYMENT_GROUP
				   ,P_BR.PAYMENT_GROUP		AS BRS_PAYMENT_GROUP
				   ,P.PAYMENT_GROUP			AS SHP_PAYMENT_GROUP
				   --
				   ,P_B2B.ACQUIRER			AS B2B_ACQUIRER
				   ,P_EPP.ACQUIRER			AS EPP_ACQUIRER
				   ,P_BR.ACQUIRER			AS BRS_ACQUIRER
				   ,P.ACQUIRER				AS SHP_ACQUIRER
				   --
				   ,P_B2B.AUTH_ID			AS B2B_AUTH_ID
				   ,P_EPP.AUTH_ID			AS EPP_AUTH_ID
				   ,P_BR.AUTH_ID			AS BRS_AUTH_ID
				   ,P.AUTH_ID				AS SHP_AUTH_ID
				   --
				   ,P_B2B.NSU				AS B2B_NSU
				   ,P_EPP.NSU				AS EPP_NSU
				   ,P_BR.NSU				AS BRS_NSU
				   ,P.NSU					AS SHP_NSU
				   --
				   ,P_B2B.VALUE				AS B2B_VALUE
				   ,P_EPP.VALUE				AS EPP_VALUE
				   ,P_BR.VALUE				AS BRS_VALUE
				   ,P.VALUE					AS SHP_VALUE
				   --
				   ,P_B2B.INSTALLMENTS		AS B2B_INSTALLMENTS
				   ,P_EPP.INSTALLMENTS		AS EPP_INSTALLMENTS
				   ,P_BR.INSTALLMENTS		AS BRS_INSTALLMENTS
				   ,P.INSTALLMENTS			AS SHP_INSTALLMENTS
				   --
				   --
				   ,COALESCE(P_B2B.PAYMENT_SYSTEM
				            ,P_EPP.PAYMENT_SYSTEM
				            ,P_BR.PAYMENT_SYSTEM
				            ,P.PAYMENT_SYSTEM)
				      AS PAYMENT_SYSTEM_CODE
				   --
				   ,P_B2B.PAYMENT_SYSTEM	AS B2B_PAYMENT_SYSTEM_CODE
				   ,P_EPP.PAYMENT_SYSTEM	AS EPP_PAYMENT_SYSTEM_CODE
				   ,P_BR.PAYMENT_SYSTEM		AS BRS_PAYMENT_SYSTEM_CODE
				   ,P.PAYMENT_SYSTEM		AS SHP_PAYMENT_SYSTEM_CODE
				   --
				   ,P_B2B.PAYMENT_SYSTEM_NAME	AS B2B_PAYMENT_SYSTEM_NAME_ORIGIN
				   ,P_EPP.PAYMENT_SYSTEM_NAME	AS EPP_PAYMENT_SYSTEM_NAME_ORIGIN
				   ,P_BR.PAYMENT_SYSTEM_NAME	AS BRS_PAYMENT_SYSTEM_NAME_ORIGIN
				   ,P.PAYMENT_SYSTEM_NAME		AS SHP_PAYMENT_SYSTEM_NAME_ORIGIN
				   --
				   ,P_B2B.UPDATED_AT		AS B2B_UPDATED_AT
				   ,P_EPP.UPDATED_AT		AS EPP_UPDATED_AT
				   ,P_BR.UPDATED_AT			AS BRS_UPDATED_AT
				   ,P.UPDATED_AT			AS SHP_UPDATED_AT
				   --
				   ,L.CREATION_TIMESTAMP   
				   ,L.AUTHORIZED_DATE
				   ,ROUND(((SECONDS_BETWEEN(L.CREATION_TIMESTAMP, COALESCE(L.AUTHORIZED_DATE,CURRENT_TIMESTAMP))/60)/60),2) AS LT_HOURLY
				   ,DAYS_BETWEEN(L.CREATION_TIMESTAMP, COALESCE(L.AUTHORIZED_DATE,CURRENT_TIMESTAMP)) 						AS LT_DAILY
				   --
			  FROM      OW_LAO.TMP_VTEX_PAYMENT_SALES AS L 	
			  --
			  LEFT JOIN  OW_LAO.TMP_VTEX_PAYMENT_01   AS P
			         ON  L.ORDER_ID = P.ORDER_ID 
			  --
			  LEFT JOIN  OW_LAO.TMP_VTEX_PAYMENT_02 AS P_BR
			         ON  L.ORDER_ID = P_BR.ORDER_ID 
			  --
			  LEFT JOIN  OW_LAO.TMP_VTEX_PAYMENT_03 AS P_EPP
			         ON  L.ORDER_ID = P_EPP.ORDER_ID 
			  --
			  LEFT JOIN  OW_LAO.TMP_VTEX_PAYMENT_04 AS P_B2B
			         ON  L.ORDER_ID = P_B2B.ORDER_ID 
			)
			-----------------
			--SELECT * FROM CTE_BASE
			-----------------
		    ,CTE_BASE_01
		    AS
		    (
		     SELECT --
					P.ORDER_ID
				   ,P.SEQUENCE
			       ,P.MARKETPLACE_ORDER_ID
			       ,P.STATUS
				   --   
				   ,COALESCE(
							    MAX(P.B2B_CARD_FIRST_DIGITS) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_B2B_CARD_FIRST_DIGITS 
							   ,MAX(P.EPP_CARD_FIRST_DIGITS) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_EPP_CARD_FIRST_DIGITS 
							   ,MAX(P.BRS_CARD_FIRST_DIGITS) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_BRS_CARD_FIRST_DIGITS
							   ,MAX(P.SHP_CARD_FIRST_DIGITS) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_SHP_CARD_FIRST_DIGITS 
				            )
				      AS P_CARD_FIRST_DIGITS
				   --   
				   ,COALESCE(
							    MAX(P.B2B_CARD_LAST_DIGITS ) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_B2B_CARD_LAST_DIGITS 
							   ,MAX(P.EPP_CARD_LAST_DIGITS ) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_EPP_CARD_LAST_DIGITS 
							   ,MAX(P.BRS_CARD_LAST_DIGITS ) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_BRS_CARD_LAST_DIGITS
							   ,MAX(P.SHP_CARD_LAST_DIGITS ) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_SHP_CARD_LAST_DIGITS 
				            )
				      AS P_CARD_LAST_DIGITS
				   --   
				   ,P.B2B_CARD_FIRST_DIGITS 
				   ,P.EPP_CARD_FIRST_DIGITS 
				   ,P.BRS_CARD_FIRST_DIGITS
				   ,P.SHP_CARD_FIRST_DIGITS 
				   --   
				   ,P.B2B_CARD_LAST_DIGITS  
				   ,P.EPP_CARD_LAST_DIGITS  
				   ,P.BRS_CARD_LAST_DIGITS 
				   ,P.SHP_CARD_LAST_DIGITS  
				   --
				   ,'<<>><<>><<>>'
				   --   
				   ,COALESCE(
							    MAX(P.B2B_PAYMENT_GROUP) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_B2B_PAYMENT_GROUP
							   ,MAX(P.EPP_PAYMENT_GROUP) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_EPP_PAYMENT_GROUP
							   ,MAX(P.BRS_PAYMENT_GROUP) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_BRS_PAYMENT_GROUP
							   ,MAX(P.SHP_PAYMENT_GROUP) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_SHP_PAYMENT_GROUP
				            )
				      AS P_PAYMENT_GROUP
				   --
				   ,P.B2B_PAYMENT_GROUP
				   ,P.EPP_PAYMENT_GROUP
				   ,P.BRS_PAYMENT_GROUP
				   ,P.SHP_PAYMENT_GROUP
				   ,'<<>><<>><<>>'
				   --
				   ,COALESCE(
							    MAX(P.B2B_ACQUIRER) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_B2B_ACQUIRER
							   ,MAX(P.EPP_ACQUIRER) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_EPP_ACQUIRER
							   ,MAX(P.BRS_ACQUIRER) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_BRS_ACQUIRER
							   ,MAX(P.SHP_ACQUIRER) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_SHP_ACQUIRER
				            )
				      AS P_ACQUIRER
				   --
				   ,P.B2B_ACQUIRER
				   ,P.EPP_ACQUIRER
				   ,P.BRS_ACQUIRER
				   ,P.SHP_ACQUIRER
				   ,'<<>><<>><<>>'
				   --
				   ,COALESCE(
							    MAX(P.B2B_TID) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_B2B_AUTH_ID
							   ,MAX(P.EPP_TID) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_EPP_AUTH_ID
							   ,MAX(P.BRS_TID) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_BRS_AUTH_ID
							   ,MAX(P.SHP_TID) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_SHP_AUTH_ID
				            )
				      AS P_TID
				   --
				   ,P.B2B_TID
				   ,P.EPP_TID
				   ,P.BRS_TID
				   ,P.SHP_TID
				   ,'<<>><<>><<>>'
				   --
				   ,COALESCE(
							    MAX(P.B2B_AUTH_ID) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_B2B_AUTH_ID
							   ,MAX(P.EPP_AUTH_ID) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_EPP_AUTH_ID
							   ,MAX(P.BRS_AUTH_ID) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_BRS_AUTH_ID
							   ,MAX(P.SHP_AUTH_ID) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_SHP_AUTH_ID
				            )
				      AS P_AUTH_ID
				   --
				   ,P.B2B_AUTH_ID
				   ,P.EPP_AUTH_ID
				   ,P.BRS_AUTH_ID
				   ,P.SHP_AUTH_ID
				   ,'<<>><<>><<>>'
				   --
				   ,COALESCE(
							    MAX(P.B2B_NSU) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_B2B_NSU
							   ,MAX(P.EPP_NSU) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_EPP_NSU
							   ,MAX(P.BRS_NSU) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_BRS_NSU
							   ,MAX(P.SHP_NSU) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_SHP_NSU
				            )
				      AS P_NSU
				   --
				   ,P.B2B_NSU
				   ,P.EPP_NSU
				   ,P.BRS_NSU
				   ,P.SHP_NSU
				   ,'<<>><<>><<>>'
				   --
				   ,COALESCE(
							    MAX(P.B2B_VALUE) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_B2B_VALUE
							   ,MAX(P.EPP_VALUE) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_EPP_VALUE
							   ,MAX(P.BRS_VALUE) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_BRS_VALUE
							   ,MAX(P.SHP_VALUE) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_SHP_VALUE
				            )
				      AS P_VALUE
				   --
				   ,P.B2B_VALUE
				   ,P.EPP_VALUE
				   ,P.BRS_VALUE
				   ,P.SHP_VALUE
				   ,'<<>><<>><<>>'
				   --
				   ,COALESCE(
							    MAX(P.B2B_INSTALLMENTS) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_B2B_VALUE
							   ,MAX(P.EPP_INSTALLMENTS) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_EPP_VALUE
							   ,MAX(P.BRS_INSTALLMENTS) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_BRS_VALUE
							   ,MAX(P.SHP_INSTALLMENTS) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_SHP_VALUE
				            )
				      AS P_INSTALLMENTS
				   --
				   ,P.B2B_INSTALLMENTS
				   ,P.EPP_INSTALLMENTS
				   ,P.BRS_INSTALLMENTS
				   ,P.SHP_INSTALLMENTS
				   ,'<<>><<>><<>>'
				   --
				   ,COALESCE(
							    MAX(P.B2B_PAYMENT_SYSTEM_CODE) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_B2B_VALUE
							   ,MAX(P.EPP_PAYMENT_SYSTEM_CODE) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_EPP_VALUE
							   ,MAX(P.BRS_PAYMENT_SYSTEM_CODE) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_BRS_VALUE
							   ,MAX(P.SHP_PAYMENT_SYSTEM_CODE) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_SHP_VALUE
				            )
				      AS P_PAYMENT_SYSTEM_CODE
				   --
				   ,P.B2B_PAYMENT_SYSTEM_CODE
				   ,P.EPP_PAYMENT_SYSTEM_CODE
				   ,P.BRS_PAYMENT_SYSTEM_CODE
				   ,P.SHP_PAYMENT_SYSTEM_CODE
				   ,'<<>><<>><<>>'
				   --
				   ,COALESCE(
							    MAX(P.B2B_PAYMENT_SYSTEM_NAME_ORIGIN) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_B2B_VALUE
							   ,MAX(P.EPP_PAYMENT_SYSTEM_NAME_ORIGIN) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_EPP_VALUE
							   ,MAX(P.BRS_PAYMENT_SYSTEM_NAME_ORIGIN) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_BRS_VALUE
							   ,MAX(P.SHP_PAYMENT_SYSTEM_NAME_ORIGIN) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_SHP_VALUE
				            )
				      AS P_PAYMENT_SYSTEM_NAME_ORIGIN
				   --
				   ,P.B2B_PAYMENT_SYSTEM_NAME_ORIGIN
				   ,P.EPP_PAYMENT_SYSTEM_NAME_ORIGIN
				   ,P.BRS_PAYMENT_SYSTEM_NAME_ORIGIN
				   ,P.SHP_PAYMENT_SYSTEM_NAME_ORIGIN
				   ,'<<>><<>><<>>'
				   --
				   ,COALESCE(
							    MAX(P.B2B_UPDATED_AT) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_B2B_VALUE
							   ,MAX(P.EPP_UPDATED_AT) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_EPP_VALUE
							   ,MAX(P.BRS_UPDATED_AT) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_BRS_VALUE
							   ,MAX(P.SHP_UPDATED_AT) OVER(PARTITION BY P.ORDER_ID, P.TID, P.PAYMENT_SYSTEM_CODE ) --AS P_SHP_VALUE
				            )
				      AS P_UPDATED_AT
				   --
				   ,P.B2B_UPDATED_AT
				   ,P.EPP_UPDATED_AT
				   ,P.BRS_UPDATED_AT
				   ,P.SHP_UPDATED_AT
				   --   
				   --
				   ,'<<>><<>><<>>'
				   --
				   ,P.ORDERS_AUTHORIZATION
				   ,P.STATUS_DESCRIPTION
				   ,P.CREATION_TIMESTAMP
				   ,P.AUTHORIZED_DATE
				   ,P.LT_HOURLY
				   ,P.LT_DAILY
		     	   --
		      FROM CTE_BASE AS P
		    )
			-----------------
			--SELECT * FROM CTE_BASE_01 
			-----------------
		    ,CTE_VTEX_PAYMENTS
		    AS
		    (
		     SELECT --
					P.ORDER_ID
				   ,P.SEQUENCE
			       ,P.MARKETPLACE_ORDER_ID
			       ,P.STATUS
				   --
				   ,P.CREATION_TIMESTAMP
				   ,P.AUTHORIZED_DATE
				   ,P.LT_HOURLY
				   ,P.LT_DAILY
			       --
			       ,CASE --
			       	     WHEN P.P_PAYMENT_SYSTEM_NAME_ORIGIN IN ('Visa','Samsung Itaucard','Elo','Hipercard','Mastercard','American Express')
			       	      AND P.LT_HOURLY > 24 
						 THEN 'LT OVER 24H' 
						 --
						 ELSE 'NOT APLY' 
						 END 
						 AS LT_OVER_24       	      
				   --
				   ,P.ORDERS_AUTHORIZATION
				   ,P.STATUS_DESCRIPTION
				   --   
				   ,P.P_CARD_FIRST_DIGITS			AS CARD_FIRST_DIGITS 
				   ,P.P_CARD_LAST_DIGITS			AS CARD_LAST_DIGITS
				   --
				   ,P.P_PAYMENT_GROUP				AS PAYMENT_GROUP 
				   ,P.P_ACQUIRER					AS ACQUIRER
				   ,P.P_TID							AS TID
				   ,P.P_AUTH_ID						AS AUTH_ID
				   ,P.P_NSU							AS NSU 
				   ,P.P_VALUE						AS VALUE
				   ,P.P_INSTALLMENTS				AS INSTALLMENTS
				   ,P.P_PAYMENT_SYSTEM_CODE			AS PAYMENT_SYSTEM_CODE
				   ,P.P_PAYMENT_SYSTEM_NAME_ORIGIN	AS PAYMENT_SYSTEM_NAME_ORIGIN
				   --
			       ,CASE --
			       	     WHEN P.P_PAYMENT_SYSTEM_NAME_ORIGIN IN ('Boleto Bancário') 
			       	     THEN 'BOLETO BANCARIO'
			       	     --
			       	     WHEN P.P_PAYMENT_SYSTEM_NAME_ORIGIN IN ('Visa','Samsung Itaucard','Elo','Hipercard','Mastercard','American Express','Cartão Santander','Porto Seguro Mastercard','Diners','Porto Seguro Visa','Cartões Bradesco') 
			       	     THEN	'CREDIT CARD'
			       	     --
			       	     WHEN P.P_PAYMENT_SYSTEM_NAME_ORIGIN IN ('Pix') 
			       	     THEN 'PIX'
			       	     --
			       	     WHEN P.P_PAYMENT_SYSTEM_NAME_ORIGIN IN ('PicPay','Samsung Pay','AmeDigital') 
			       	     THEN 'DIGITAL'
			       	     --
			       	     WHEN P.P_PAYMENT_SYSTEM_NAME_ORIGIN IN ('Vale') 
			       	     THEN 'VALE'
			       	     --
			       	     WHEN P.P_PAYMENT_SYSTEM_NAME_ORIGIN LIKE 'Valor assumido pelo afiliado%' 
			       	     THEN 'MKT PLACE'
			       	     --
			       	     ELSE 'CHECK VALUES'
						 END
						 AS PAYMENT_SYSTEM_NAME
			       --
				   ,P.P_UPDATED_AT					AS UPDATED_AT
		     	   --
		      FROM CTE_BASE_01 AS P
		    )
			-----------------
			SELECT DISTINCT * FROM CTE_VTEX_PAYMENTS 
			-----------------
	   )
	;
	--
	--	
	------------------------------------------------------------------
	-- Checks if the temporary table 'TMP_PAYMENT_..' exists in schema 'OW_LAO'.
	IF EXISTS ( SELECT 1 
	              FROM SYS.TABLES 
	             WHERE SCHEMA_NAME = 'OW_LAO' 
	               AND TABLE_NAME = 'TMP_VTEX_PAYMENT_SKU' 
	          ) THEN
		DROP TABLE OW_LAO.TMP_VTEX_PAYMENT_SKU;
	END IF ;
    --
	------------------------------------------------------------------
	-- Creates a new table 'TMP_VTEX_PAYMENT'
	CREATE COLUMN TABLE OW_LAO.TMP_VTEX_PAYMENT_SKU
	AS (
		WITH CTE_VTEX_PAYMENTS_SKU
			AS
			(
			SELECT DISTINCT --
				    N.DATE_REF
				   --
				   ,L.ORDER_ID
				   ,L.SEQUENCE
				   ,L.MARKETPLACE_ORDER_ID
				   ,L.STATUS 
				   --
				   --,N.AFFILIATE_ID_ADJUSTED
				   ,N.AFFILIATE_CHANNEL
				   ,N.AFFILIATE_SUB_CHANNEL
				   ,N.AFFILIATE_PARTNER_LEVEL
				   --		
				   ,L.LT_HOURLY
				   ,L.LT_DAILY
				   ,L.LT_OVER_24
				   --
				   ,L.CREATION_TIMESTAMP   
				   ,L.AUTHORIZED_DATE
				   ,L.ORDERS_AUTHORIZATION
				   ,L.STATUS_DESCRIPTION
				   ,L.PAYMENT_GROUP
				   ,L.ACQUIRER
				   ,L.TID
				   ,L.AUTH_ID
				   ,L.NSU
				   --   
				   ,L.INSTALLMENTS
				   ,L.PAYMENT_SYSTEM_CODE
				   ,L.PAYMENT_SYSTEM_NAME_ORIGIN
				   --
				   ,L.PAYMENT_SYSTEM_NAME
				   --   
				   ,L.CARD_FIRST_DIGITS
				   ,L.CARD_LAST_DIGITS
				   --
				   ,N.SEDA_BU_ESTORE
				   ,N.SEDA_DIVISION_ESTORE
				   ,N.SEDA_CATEGORY_ESTORE
				   ,N.SEDA_FAMILY_ESTORE
				   ,N.SEDA_DESC_ESTORE
				   --
				   ,N.SKU --, N.QTY, N.AMOUNT_LOCAL, N.SELLING_AMOUNT_LOCAL
				   --,N.QT_SKU_PED
				   --   
				  --,N.SELLING_AMOUNT_LOCAL
			      --,TO_DECIMAL(L.VALUE / 100, 20, 2)  AS VALUE
				   --
			       -- calculo do rateio
			      ,(TO_DECIMAL(L.VALUE / 100, 20, 2) /											 -- valor pedido por meio pagto
			        SUM( TO_DECIMAL(L.VALUE / 100, 20, 2) ) OVER(PARTITION BY L.ORDER_ID, N.SKU) -- Total pedido com todos meio pagto
			       ) * N.SELLING_AMOUNT_LOCAL													 -- valor do produto por pedido
				   AS AMOUNT_LOCAL
			       --
			       --
			FROM       OW_LAO.TMP_VTEX_PAYMENT_SALES	AS N
			INNER JOIN OW_LAO.TMP_VTEX_PAYMENT		 	AS L
				    ON L.ORDER_ID = N.ORDER_ID 
			--	    
			ORDER BY L.ORDER_ID, N.SKU 
			)
			-----------
			-----------
			SELECT DISTINCT * FROM CTE_VTEX_PAYMENTS_SKU WHERE AMOUNT_LOCAL IS NOT NULL
	   )
	;
	--
	--	
	------------------------------------------------------------------
	-- Checks if the temporary table 'TMP_PAYMENT_..' exists in schema 'OW_LAO'.
	IF EXISTS ( SELECT 1 
	              FROM SYS.TABLES 
	             WHERE SCHEMA_NAME = 'OW_LAO' 
	               AND TABLE_NAME = 'TMP_VTEX_PAYMENT_SKU_FINAL' 
	          ) THEN
		DROP TABLE OW_LAO.TMP_VTEX_PAYMENT_SKU_FINAL;
	END IF ;
    -- 
	------------------------------------------------------------------
	-- Creates a new table 'TMP_VTEX_PAYMENT'
	CREATE COLUMN TABLE OW_LAO.TMP_VTEX_PAYMENT_SKU_FINAL
	AS (
		WITH CTE_VTEX_PAYMENTS_SKU_FINAL
		 AS ( 
			SELECT T.*
			      ,CASE WHEN P.ORDER_ID IS NULL 
			            THEN 'N'
			            ELSE 'S'
			       END
			       AS IND_EXCLUI 
			  FROM      OW_LAO.TMP_VTEX_PAYMENT_SKU      AS T 
			  LEFT JOIN OW_LAO.TF_D2C_VTEX_PAYMENT_SKU   AS P
			         ON T.ORDER_ID 					 = P.ORDER_ID
			        AND T.SKU      					 = P.SKU
			        AND T.PAYMENT_SYSTEM_NAME_ORIGIN = P.PAYMENT_SYSTEM_NAME_ORIGIN
		    )
			-----------
			-----------
			SELECT DISTINCT * FROM CTE_VTEX_PAYMENTS_SKU_FINAL 
	   )
	;
	-- SELECT COUNT(1) FROM OW_LAO.TMP_VTEX_PAYMENT_SKU_FINAL
	-- SELECT * FROM OW_LAO.TF_D2C_VTEX_PAYMENT_SKU
	--
	-- apaga orders que estiverem na tmp, marcadas pra excluir
	DELETE 
	  FROM OW_LAO.TF_D2C_VTEX_PAYMENT_SKU 
	 WHERE ORDER_ID IN (
						SELECT DISTINCT 
						       ORDER_ID 
						  FROM OW_LAO.TMP_VTEX_PAYMENT_SKU_FINAL
						 WHERE IND_EXCLUI = 'S'
						);
	--
	--
	--CREATE TABLE OW_LAO.TF... AS (
	INSERT INTO OW_LAO.TF_D2C_VTEX_PAYMENT_SKU 
	SELECT -- 
		    P.DATE_REF
		   --
		   ,P.ORDER_ID
		   ,P.SEQUENCE
		   ,P.MARKETPLACE_ORDER_ID
		   ,P.STATUS 
		   --
		   --,N.AFFILIATE_ID_ADJUSTED
		   ,P.AFFILIATE_CHANNEL
		   ,P.AFFILIATE_SUB_CHANNEL
		   ,P.AFFILIATE_PARTNER_LEVEL
		   --		
		   ,P.LT_HOURLY
		   ,P.LT_DAILY
		   ,P.LT_OVER_24
		   --
		   ,P.CREATION_TIMESTAMP   
		   ,P.AUTHORIZED_DATE
		   ,P.ORDERS_AUTHORIZATION
		   ,P.STATUS_DESCRIPTION
		   ,P.PAYMENT_GROUP
		   ,P.ACQUIRER
		   ,P.TID
		   ,P.AUTH_ID
		   ,P.NSU
		   --   
		   ,P.INSTALLMENTS
		   ,P.PAYMENT_SYSTEM_CODE
		   ,P.PAYMENT_SYSTEM_NAME_ORIGIN
		   --
		   ,P.PAYMENT_SYSTEM_NAME
		   --   
		   ,P.CARD_FIRST_DIGITS
		   ,P.CARD_LAST_DIGITS
		   --
		   ,P.SEDA_BU_ESTORE
		   ,P.SEDA_DIVISION_ESTORE
		   ,P.SEDA_CATEGORY_ESTORE
		   ,P.SEDA_FAMILY_ESTORE
		   ,P.SEDA_DESC_ESTORE
		   --
		   ,P.SKU --, N.QTY, N.AMOUNT_LOCAL, N.SELLING_AMOUNT_LOCAL
		   --   
		  --,P.SELLING_AMOUNT_LOCAL
	      --,P.VALUE
	      -- calculo do rateio
	      ,P.AMOUNT_LOCAL
	      --
	      -- SELECT *
	  FROM OW_LAO.TMP_VTEX_PAYMENT_SKU_FINAL AS P  
	;
	--
	--	
	--	
	--DELETE FROM OW_LAO.TMP_D2C_PAYMENT_ITAU;
	DROP TABLE  OW_LAO.TMP_PARAMETER_VTEX_PAYMENT;
	DROP TABLE  OW_LAO.TMP_VTEX_PAYMENT_SALES;
	DROP TABLE  OW_LAO.TMP_VTEX_PAYMENT_01;
	DROP TABLE  OW_LAO.TMP_VTEX_PAYMENT_02;
	DROP TABLE  OW_LAO.TMP_VTEX_PAYMENT_03;
	DROP TABLE  OW_LAO.TMP_VTEX_PAYMENT_04;
	DROP TABLE  OW_LAO.TMP_VTEX_PAYMENT;
	DROP TABLE  OW_LAO.TMP_VTEX_PAYMENT_SKU;
	--DROP TABLE  OW_LAO.TMP_VTEX_PAYMENT_SKU_FINAL; 
	--				
END