/***********************************************************************************************
CREATED BY : Luciano Mariani
CREATION DATE : 2024-10-10
CALL OW_LAO.PROC_D2C_PAYMENT_ITAU
SELECT TOP 100 * FROM OW_LAO.TF_D2C_PAYMENT_ITAU
--
MAINTENANCE: 2024-07-17  -  João Brandão
***********************************************************************************************/
--
CREATE PROCEDURE OW_LAO.PROC_D2C_PAYMENT_ITAU (
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
	* CRIA A TMP_PARAMETER_PAYMENT_ITAU
	********************************************************/
	IF EXISTS ( SELECT '' FROM SYS.TABLES WHERE SCHEMA_NAME = 'OW_LAO' AND TABLE_NAME = 'TMP_PARAMETER_PAYMENT_ITAU' ) THEN
		DROP TABLE OW_LAO.TMP_PARAMETER_PAYMENT_ITAU;
	END IF ;
	CREATE COLUMN TABLE OW_LAO.TMP_PARAMETER_PAYMENT_ITAU AS (
		SELECT ADD_DAYS(CURRENT_TIMESTAMP, -7) AS DATE_INI, ADD_DAYS(CURRENT_TIMESTAMP, 2) AS DATE_FIM FROM DUMMY
	);
	UPDATE OW_LAO.TMP_PARAMETER_PAYMENT_ITAU 
	   SET
		  DATE_INI = IFNULL( p_DATE_INI, ADD_DAYS(CURRENT_TIMESTAMP, -7) ) -- 30 dias dafault
		, DATE_FIM = IFNULL( P_DATE_FIM, ADD_DAYS(CURRENT_TIMESTAMP, 2) ) 
	;
	
	------------------------------------------------------------------
	-- Checks if the temporary table 'TMP_PAYMENT_ITAU_AJUSTADO' exists in schema 'OW_LAO'.
	-- If it exists, the table is dropped to ensure a clean creation.
	IF EXISTS ( SELECT 1 FROM SYS.TABLES WHERE SCHEMA_NAME = 'OW_LAO' AND TABLE_NAME = 'TMP_PAYMENT_ITAU_AJUSTADO' ) THEN
		DROP TABLE OW_LAO.TMP_PAYMENT_ITAU_AJUSTADO;
	END IF ;
	------------------------------------------------------------------
	-- Creates a new table 'TMP_PAYMENT_ITAU_AJUSTADO'
	CREATE COLUMN TABLE OW_LAO.TMP_PAYMENT_ITAU_AJUSTADO
	AS (
		WITH CTE_TMP_PARAMETER_PAYMENT_ITAU AS 
		    (
			SELECT --
					DATE_INI,
					DATE_FIM
			FROM OW_LAO.TMP_PARAMETER_PAYMENT_ITAU 
		    )
		-----
		-----
		,CTE_TMP_D2C_PAYMENT_ITAU AS 
		     ( --  
				SELECT
				    VT.ORDER_ID,
				    VT.SEQUENCE,
				    VT.STATUS_PO,
				    VT.DATE_REF,
				    VT.YYYYWW,
				    VT.YYYYMM,
				    VT.YYYYQQ,
				    VT.PO_CREATION_DATE,
				    VT.PO_WEEK_DAY_NUM,
				    VT.PO_WEEK_DAY_NAME,
				    VT.PO_HOUR,
				    VT.SUBSIDIARY,
				    VT.AFFILIATE_ID_ADJUSTED,
				    VT.AFFILIATE_CHANNEL,
				    VT.AFFILIATE_SUB_CHANNEL,
				    VT.AFFILIATE_PARTNER_LEVEL,
				    '{"ORDER_ID": "' || BSO.ORDER_ID || '", "SEQUENCE":"' || BSO.SEQUENCE || '", "JSON": ' ||
				        COALESCE(
				            NULLIF(EPO_APP0_TRANSACTION, ''),
				            NULLIF(SSO_APP0_TRANSACTION, ''),
				            NULLIF(BSO_APP0_TRANSACTION, ''),
				            NULLIF(B2B_APP0_TRANSACTION, ''),
				            ''
				        )
				    || '}' AS JSON_CUSTOM_DATA
				FROM (
				        SELECT 
				              ORDER_ID,
				              SEQUENCE,
				              STATUS_PO,
				              DATE_REF,
				              YYYYWW,
				              YYYYMM,
				              YYYYQQ,
				              PO_CREATION_DATE,
				              PO_WEEK_DAY_NUM,
				              PO_WEEK_DAY_NAME,
				              PO_HOUR,
				              SALES_CHANNEL,
				              SUBSIDIARY,
				              AFFILIATE_ID_ADJUSTED,
				              AFFILIATE_CHANNEL,
				              AFFILIATE_SUB_CHANNEL,
				              AFFILIATE_PARTNER_LEVEL
				        FROM (
				                SELECT DISTINCT S.*  
				                FROM OW_LAO.TF_D2C_NERP_SALES AS S 
				                INNER JOIN ( 
				                              SELECT DISTINCT ORDER_ID
				                              FROM OW_LAO.TF_D2C_PAYMENT_ITAU
				                              WHERE VALUE IS NULL 
				                           ) I
				                       ON S.ORDER_ID = I.ORDER_ID
				                WHERE S.SOURCE = 'PO'
				                  AND S.SUBSIDIARY = 'SEDA'
				                --
				                UNION 
				                --
				                SELECT DISTINCT S.*  
				                FROM OW_LAO.TF_D2C_NERP_SALES AS S 
				                WHERE S.SOURCE = 'PO'
				                  AND S.SUBSIDIARY = 'SEDA'
									AND DATE_REF BETWEEN ( SELECT DATE_INI FROM CTE_TMP_PARAMETER_PAYMENT_ITAU ) --OW_LAO.TMP_PARAMETER_PAYMENT_ITAU )
													 AND ( SELECT DATE_FIM FROM CTE_TMP_PARAMETER_PAYMENT_ITAU ) --OW_LAO.TMP_PARAMETER_PAYMENT_ITAU )
				        ) T
				        WHERE "SOURCE" = 'PO'
				          AND SUBSIDIARY = 'SEDA'
				        GROUP BY
				              ORDER_ID,
				              SEQUENCE,
				              STATUS_PO,
				              DATE_REF,
				              YYYYWW,
				              YYYYMM,
				              YYYYQQ,
				              PO_CREATION_DATE,
				              PO_WEEK_DAY_NUM,
				              PO_WEEK_DAY_NAME,
				              PO_HOUR,
				              SALES_CHANNEL,
				              SUBSIDIARY,
				              AFFILIATE_ID_ADJUSTED,
				              AFFILIATE_CHANNEL,
				              AFFILIATE_SUB_CHANNEL,
				              AFFILIATE_PARTNER_LEVEL
				    ) VT
				    /********** BR SHOP ***********/
				    INNER JOIN (
				        SELECT 
				            ORDER_ID,
				            MARKETPLACE_ORDER_ID,
				            SEQUENCE,
				            CASE 
						        WHEN CUSTOM_DATA LIKE '%"transaction"%' 
						        THEN TO_NVARCHAR(JSON_VALUE(CUSTOM_DATA, '$.customApps[0].id'))
						        ELSE ''
						    END AS BSO_APP0_ID,
				            CASE 
						        WHEN CUSTOM_DATA LIKE '%"transaction"%' 
						        THEN TO_NVARCHAR(JSON_VALUE(CUSTOM_DATA, '$.customApps[0].fields.transaction'))
						        ELSE ''
						    END AS BSO_APP0_TRANSACTION
				        FROM U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER
				    ) BSO
				        ON BSO.ORDER_ID = VT.ORDER_ID
				    /********** SSG BR ***********/
				    LEFT JOIN (
				        SELECT DISTINCT  
				            ORDER_ID,
						    CASE 
						        WHEN CUSTOM_DATA LIKE '%"transaction"%' 
						        THEN TO_NVARCHAR(JSON_VALUE(CUSTOM_DATA, '$.customApps[0].id'))
						        ELSE ''
						    END AS SSO_APP0_ID,
						    CASE 
						        WHEN CUSTOM_DATA LIKE '%"transaction"%' 
						        THEN TO_NVARCHAR(JSON_VALUE(CUSTOM_DATA, '$.customApps[0].fields.transaction'))
						        ELSE ''
						    END AS SSO_APP0_TRANSACTION
				        FROM U_PRJ_ECOM.RAW_VTEX_SSG_BR_SALES_ORDER 
				        WHERE CUSTOM_DATA IS NOT NULL        
				    ) SSO
				        ON BSO.MARKETPLACE_ORDER_ID = SSO.ORDER_ID
				    /********** EPP2 ***********/
				    LEFT JOIN (
				        SELECT 
				            ORDER_ID,
						    CASE 
						        WHEN CUSTOM_DATA LIKE '%"transaction"%' 
						        THEN TO_NVARCHAR(JSON_VALUE(CUSTOM_DATA, '$.customApps[0].id'))
						        ELSE ''
						    END AS EPO_APP0_ID,
				            CASE 
						        WHEN CUSTOM_DATA LIKE '%"transaction"%' 
						        THEN TO_NVARCHAR(JSON_VALUE(CUSTOM_DATA, '$.customApps[0].fields.transaction'))
						        ELSE ''
						    END AS EPO_APP0_TRANSACTION
				        FROM U_PRJ_ECOM.RAW_VTEX_SSG_BR_EPP2_SALES_ORDER 
				        WHERE CUSTOM_DATA IS NOT NULL 
				    ) EPO
				        ON BSO.MARKETPLACE_ORDER_ID = EPO.ORDER_ID
				    /********** B2B ***********/
				    LEFT JOIN (
				        SELECT 
				            ORDER_ID,
						    CASE 
						        WHEN CUSTOM_DATA LIKE '%"transaction"%' 
						        THEN TO_NVARCHAR(JSON_VALUE(CUSTOM_DATA, '$.customApps[0].id'))
						        ELSE ''
						    END AS B2B_APP0_ID,
				            CASE 
						        WHEN CUSTOM_DATA LIKE '%"transaction"%' 
						        THEN TO_NVARCHAR(JSON_VALUE(CUSTOM_DATA, '$.customApps[0].fields.transaction'))
						        ELSE ''
						    END AS B2B_APP0_TRANSACTION
				        FROM U_PRJ_ECOM.RAW_VTEX_SSG_BR_B2B_SALES_ORDER 
				        WHERE CUSTOM_DATA IS NOT NULL 
				    ) B2B
				        ON BSO.MARKETPLACE_ORDER_ID = B2B.ORDER_ID
				WHERE 
				    COALESCE(
				        NULLIF(EPO_APP0_ID, ''),
				        NULLIF(SSO_APP0_ID, ''),
				        NULLIF(BSO_APP0_ID, ''),
				        NULLIF(B2B_APP0_ID, ''),
				        ''
				    ) = 'itau-transaction'
			)
		-----
		-----
		,CTE_CURSOR_SELECT_JSON 
		AS (
				SELECT JSON_CUSTOM_DATA
				 FROM CTE_TMP_D2C_PAYMENT_ITAU  --OW_LAO.TMP_D2C_PAYMENT_ITAU
			)
		-----
		-----
		,CTE_TMP_JSON 
		AS ( 
				SELECT 
		 			  ORDER_ID
					, SEQUENCE
					, VALUE
					, PAYMENTSYSTEMNAME
					, INSTALLMENTS
					, AUTHID
					, TID
				FROM JSON_TABLE( CTE_CURSOR_SELECT_JSON.JSON_CUSTOM_DATA --:v_JSON_CUSTOM_DATA
				    ,'$'
					COLUMNS (
					        "ORDER_ID" NVARCHAR(256) PATH '$.ORDER_ID',
					        "SEQUENCE" NVARCHAR(256) PATH '$.SEQUENCE',
					        NESTED PATH '$.JSON.transactions.payments[*]' 
					        COLUMNS ( 
									"VALUE" NVARCHAR(1000) PATH '$.value',
									"PAYMENTSYSTEMNAME" NVARCHAR(1000) PATH '$.paymentSystemName',
									"INSTALLMENTS" NVARCHAR(1000) PATH '$.installments',
									"AUTHID" NVARCHAR(1000) PATH '$.connectorResponses.authId',
									"TID" NVARCHAR(1000) PATH '$.connectorResponses.Tid'
								 	)
							)
						 )
		   )
		-----
		-----
		,CTE_TF_D2C_PAYMENT_ITAU 
		AS ( 
			   SELECT PM.ORDER_ID
					, PM.SEQUENCE 
					, PM.STATUS_PO
					, PM.DATE_REF	
					, PM.YYYYWW	
					, PM.YYYYMM	
					, PM.YYYYQQ	
					, PM.PO_CREATION_DATE	
					, PM.PO_WEEK_DAY_NUM	
					, PM.PO_WEEK_DAY_NAME	
					, PM.PO_HOUR		
					, PM.SUBSIDIARY	
					, PM.AFFILIATE_ID_ADJUSTED
					, PM.AFFILIATE_CHANNEL
					, PM.AFFILIATE_SUB_CHANNEL
					, PM.AFFILIATE_PARTNER_LEVEL
					, JD.VALUE
					, JD.PAYMENTSYSTEMNAME
					, JD.INSTALLMENTS
					, JD.AUTHID
					, JD.TID	
				FROM      CTE_TMP_D2C_PAYMENT_ITAU AS PM --OW_LAO.TMP_D2C_PAYMENT_ITAU 			PM
				LEFT JOIN CTE_TMP_JSON	           AS JD --OW_LAO.TMP_JSON_CUSTOM_DATA_ITAU 		JD
			 			ON  PM.ORDER_ID = JD.ORDER_ID
						AND PM.SEQUENCE = JD.SEQUENCE
			   )
		-----
		-----
		,CTE_TF_D2C_PAYMENT_ITAU_FINAL 
		AS ( 
			SELECT T.*
			      ,CASE WHEN P.ORDER_ID IS NULL 
			            THEN 'N'
			            ELSE 'S'
			       END
			       AS IND_EXCLUI 
			  FROM      CTE_TF_D2C_PAYMENT_ITAU    AS T 
			  LEFT JOIN OW_LAO.TF_D2C_PAYMENT_ITAU AS P
			         ON T.ORDER_ID = P.ORDER_ID
		   )
		-----
		-----
		-- Selects all columns from the Common Table Expression (CTE)
		--SELECT * FROM CTE_TMP_PARAMETER_PAYMENT_ITAU
		--SELECT * FROM CTE_TMP_D2C_PAYMENT_ITAU
		--SELECT * FROM CTE_CURSOR_SELECT_JSON
		--SELECT * FROM CTE_TMP_JSON 
	    --SELECT * FROM CTE_TF_D2C_PAYMENT_ITAU 
		SELECT DISTINCT * FROM CTE_TF_D2C_PAYMENT_ITAU_FINAL ORDER BY ORDER_ID
	);
	--
	--				
	-- apaga orders que estiverem na tmp, marcadas pra excluir
	DELETE 
	  FROM OW_LAO.TF_D2C_PAYMENT_ITAU
	WHERE ORDER_ID IN (
		SELECT DISTINCT 
		       ORDER_ID
		  FROM OW_LAO.TMP_PAYMENT_ITAU_AJUSTADO 
		 WHERE IND_EXCLUI = 'S'
	);
	
	--CREATE TABLE OW_LAO.TF_D2C_PAYMENT_ITAU AS (
	INSERT INTO OW_LAO.TF_D2C_PAYMENT_ITAU(
		  ORDER_ID
		, "SEQUENCE"
		, STATUS_PO
		, DATE_REF
		, YYYYWW
		, YYYYMM
		, YYYYQQ
		, PO_CREATION_DATE
		, PO_WEEK_DAY_NUM
		, PO_WEEK_DAY_NAME
		, PO_HOUR
		, SUBSIDIARY
		, AFFILIATE_ID_ADJUSTED
		, AFFILIATE_CHANNEL
		, AFFILIATE_SUB_CHANNEL
		, AFFILIATE_PARTNER_LEVEL
		, VALUE
		, PAYMENTSYSTEMNAME
		, INSTALLMENTS
		, AUTHID
		, TID
	)
	SELECT -- 
	      P.ORDER_ID
		, P.SEQUENCE 
		, P.STATUS_PO
		, P.DATE_REF	
		, P.YYYYWW	
		, P.YYYYMM	
		, P.YYYYQQ	
		, P.PO_CREATION_DATE	
		, P.PO_WEEK_DAY_NUM	
		, P.PO_WEEK_DAY_NAME	
		, P.PO_HOUR		
		, P.SUBSIDIARY	
		, P.AFFILIATE_ID_ADJUSTED
		, P.AFFILIATE_CHANNEL
		, P.AFFILIATE_SUB_CHANNEL
		, P.AFFILIATE_PARTNER_LEVEL
		, P.VALUE
		, P.PAYMENTSYSTEMNAME
		, P.INSTALLMENTS
		, P.AUTHID
		, P.TID	
	FROM OW_LAO.TMP_PAYMENT_ITAU_AJUSTADO AS P;
	--	
	--DELETE FROM OW_LAO.TMP_D2C_PAYMENT_ITAU;
	DROP TABLE OW_LAO.TMP_PAYMENT_ITAU_AJUSTADO;
	--				
END