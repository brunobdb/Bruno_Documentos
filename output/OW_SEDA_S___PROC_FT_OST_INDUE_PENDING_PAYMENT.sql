--CREATE PROCEDURE OW_LAO.PROC_FT_INDUE_PENDING_PAYMENT
--CREATE OR REPLACE PROCEDURE U_JM_BRANDAO.PROC_FT_INDUE_PENDING_PAYMENT
CREATE PROCEDURE OW_SEDA_S.PROC_FT_OST_INDUE_PENDING_PAYMENT
LANGUAGE SQLSCRIPT AS
BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION  -- -- Ignora erros ao tentar apagar a tabela TEMP
	--
	------------------------------------------------------------------
    -- PASSO 1 - BUSCA PEDIDOS - DAS BASE ORIGEM - POR MARKETPLACE
	BEGIN
        -- Ignora erros ao tentar apagar a tabela
	    DROP TABLE #TMP_OST_PEDIDOS;	
    END;
    --  
    CREATE LOCAL TEMPORARY TABLE #TMP_OST_PEDIDOS
        AS (
			SELECT DISTINCT 
					CURRENT_DATE					AS DATE_REF
				   ,'VV' 							AS MKTP
			       ,T.NUM_PEDIDO     				AS NUM_PEDIDO
			 FROM "OW_LAO"."RAW_SEDA_OST_MKTP_VIA_VAREJO" AS T
			WHERE T.STATUS_PEDIDO = 'Entregue' -- "Status do pedido"
			--
			UNION 
			--
			SELECT DISTINCT 
					CURRENT_DATE					AS DATE_REF
				   ,'CRF' 							AS MKTP
			       ,T.NUM_PEDIDO     				AS NUM_PEDIDO
			 FROM "OW_LAO"."RAW_SEDA_OST_MKTP_CARREFOUR" AS T
			 WHERE T.STATUS_RASTREIO  = 'Entrega Realizada Normalmente'  -- "Status do rastreio" 
			--
			UNION 
			--
			SELECT DISTINCT 
					CURRENT_DATE					AS DATE_REF
				   ,'MGZ' 							AS MKTP
			       ,T.NUM_PEDIDO     				AS NUM_PEDIDO
			 FROM "OW_LAO"."RAW_SEDA_OST_MKTP_MAGAZINE_LUIZA" AS T
			WHERE T.STATUS_PACOTE = 'Pedido entregue' -- T."Status pacote no momento que o relatório foi solicitado"
			--
			UNION 
			--
			SELECT DISTINCT 
					CURRENT_DATE					AS DATE_REF
				   ,'MLB' 							AS MKTP
			       ,T.NUMERO_VENDA 					AS NUM_PEDIDO -- ID_ANUNCIO
			 FROM "OW_LAO"."RAW_SEDA_OST_MKTP_MERCADO_LIVRE" AS T 
			WHERE  INSTR(T.ESTADO_VENDA, 'Venda entregue')
			      +INSTR(T.ESTADO_VENDA, 'Entregue no dia') > 0 -- 'Entregue no dia ..', "Venda entregue"
			--
			UNION 
			--
			SELECT DISTINCT 
					CURRENT_DATE					AS DATE_REF
				   ,'AMZ' 							AS MKTP
			       ,T.ORDER_ID     					AS NUM_PEDIDO
			 FROM "OW_LAO"."RAW_SEDA_OST_MKTP_AMAZON" AS T
			WHERE T.STATUS_PEDIDO = 'Shipped' -- "order-staus"
			--
			UNION 
			--
			SELECT DISTINCT 
					CURRENT_DATE					AS DATE_REF
				   ,'BNT' 							AS MKTP
			       ,T.MARKETPLACE_ORDER_ID			AS NUM_PEDIDO
			 FROM ( -- 
					SELECT F.MARKETPLACE_ORDER_ID, F.ORDER_ID --, F.*
					  FROM OW_LAO.TF_D2C_NERP_SALES 				   AS  F      
					--
					INNER JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER AS  R
					        ON F.ORDER_ID = R.ORDER_ID 
					       AND F.SEQUENCE = R.SEQUENCE 
					--		
					WHERE F.SEQUENCE IS NOT NULL  
					  AND R.STATUS_DESCRIPTION = 'Faturado'
					  AND LEFT(F.ORDER_ID,3)   = 'BNT'-- F.ORDER_ID LIKE '%BNT%' ORDER BY 1 DESC
				 ) T 				  
			--
           );
    	--
    	--SELECT * FROM #TMP_OST_PEDIDOS;
    	/*
    	 SELECT MKTP, COUNT(1) FROM #TMP_OST_PEDIDOS GROUP BY MKTP;
    	 
		SELECT * FROM "OW_LAO"."RAW_SEDA_OST_MKTP_MERCADO_LIVRE" AS T
    	 
			SELECT DISTINCT 
					CURRENT_DATE					AS DATE_REF
				   ,'MLB' 							AS MKTP
			       ,T.ID_ANUNCIO   					AS NUM_PEDIDO
			 -- SELECT *      
			 FROM "OW_LAO"."RAW_SEDA_OST_MKTP_MERCADO_LIVRE" AS T
			WHERE  INSTR(T.ESTADO_VENDA, 'Venda entregue')
			      +INSTR(T.ESTADO_VENDA, 'Entregue no dia') > 0 -- 'Entregue no dia ..', "Venda entregue"
			
		SELECT * FROM #TMP_OST_PEDIDOS
		WHERE NUM_PEDIDO = 		'MZN-701-3898166-8583415'			
			SELECT DISTINCT *
			 FROM "OW_LAO"."RAW_SEDA_OST_MKTP_AMAZON" AS T
		WHERE T.ORDER_ID = 		'MZN-701-3898166-8583415'			
    	
    	    	*/
    	--
	------------------------------------------------------------------
    -- PASSO 2 - BUSCA PEDIDOS EM VTEX
	BEGIN
        -- Ignora erros ao tentar apagar a tabela
	    DROP TABLE #TMP_OST_VTEX;	
    END;
    --  
    CREATE LOCAL TEMPORARY TABLE #TMP_OST_VTEX 
        AS (
	 		WITH CTE_BASE_VTEX  AS   
				(
				SELECT  --
						 M.DATE_REF
						,M.MKTP
						--
						,F.AFFILIATE_ID
						,F.AFFILIATE_CHANNEL			
						,F.AFFILIATE_SUB_CHANNEL
						,F.CUSTOMER_PO
						--
						,F.SEQUENCE
						,F.MARKETPLACE_ORDER_ID
						,F.ORDER_ID
						,F.BIZ_TYPE
						,F.GLOBAL_CHANNEL
						,F.CHANNEL_TYPE
						--
						,F.QTY
						,F.AMOUNT_LOCAL
						--
						--,R.ORDER_ID	
						--,R.SEQUENCE	
						--,R.MARKETPLACE_ORDER_ID
						--
						,R.STATUS	
						,R.STATUS_DESCRIPTION
						--
						--
				FROM       OW_LAO.TF_D2C_NERP_SALES 				   AS  F
				--
				INNER JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER AS  R
				        ON F.ORDER_ID = R.ORDER_ID 
				       AND F.SEQUENCE = R.SEQUENCE 
				--
				INNER JOIN #TMP_OST_PEDIDOS				   		       AS  M
				        ON F.MARKETPLACE_ORDER_ID = M.NUM_PEDIDO
				--		
				WHERE F.SEQUENCE IS NOT NULL --IN ('6804703','17975592')
				  AND R.STATUS_DESCRIPTION = 'Faturado'
				--
				)
				------------------------------------------------------
				SELECT DISTINCT * FROM CTE_BASE_VTEX
 			--
           );
    	--
    	--SELECT * FROM #TMP_OST_VTEX;
    	/*
    	 SELECT MKTP, COUNT(1) FROM #TMP_OST_VTEX GROUP BY MKTP;
    	*/
    	--
	------------------------------------------------------------------
    -- PASSO 3 - BUSCA PEDIDOS EM VTEX + SO_TRACKING  --
	BEGIN
        -- Ignora erros ao tentar apagar a tabela
	    DROP TABLE #TMP_OST_SO_TRACKING;	
    END;
    --  
    CREATE LOCAL TEMPORARY TABLE #TMP_OST_SO_TRACKING 
        AS (
			WITH CTE_SO_TRACK  AS   
			(
				SELECT  T.*
				       --
				       ,S.SO_NET_PRICE 
				       ,S.SO_NET_VALUE
				       ,S.BILLED_QTY_BASE
				       ,S.BILLING_NET_VALUE
				       --
				       ,S.ACCOUNT_CODE
				       ,S.ACCOUNT_NAME
				       ,S.DOCUMENT_DATE
				       ,S."2ND_GI_CREATE_ON" 
				       --
				       ,TO_DATE(S."2ND_GI_CREATE_ON")											AS DT_ENTREGA_PROD
					   ,DAYS_BETWEEN( TO_DATE(S."2ND_GI_CREATE_ON"), TO_DATE(T.DATE_REF) )  	AS DIAS_ENTREGA
					   ,CASE WHEN DAYS_BETWEEN( TO_DATE(S."2ND_GI_CREATE_ON"), TO_DATE(T.DATE_REF) )
					        BETWEEN 31 AND 45 THEN 1
					        ELSE 0
					        END 
					        AS IND_FICA_NA_FAIXA_ENTREGA 
				  --
				  FROM       OW_LAO.ODS_NERP_ZRSDD6A120_SALES_ORDER_TRACKING AS S
				  --
				  INNER JOIN #TMP_OST_VTEX					   		 		 AS T 
						ON  S.CUSTOMER_PO IN ( TO_CHAR(T.SEQUENCE), T.ORDER_ID ) 
				--
				)
				------------------------------------------------------
				SELECT DISTINCT 
				       S.*
				       ,CASE WHEN DIAS_ENTREGA <  35 THEN 'OVER 30'
				             WHEN DIAS_ENTREGA <  40 THEN 'OVER 35'
				             WHEN DIAS_ENTREGA >= 40 THEN 'OVER 40'
				        END AS RANGE_PERIOD
					  --
				  FROM CTE_SO_TRACK  AS S
           );
    	--
    	--
    	--SELECT * FROM #TMP_OST_SO_TRACKING;
    	/*
    	 SELECT MKTP, COUNT(1) FROM #TMP_OST_SO_TRACKING GROUP BY MKTP;
    	*/
	------------------------------------------------------------------
    -- PASSO 4 - BUSCA PEDIDOS EM VTEX + SO_TRACKING  + FBL5N --
	BEGIN
        -- Ignora erros ao tentar apagar a tabela
	    DROP TABLE #TMP_OST_FBL5N;	
    END;
    --  
    CREATE LOCAL TEMPORARY TABLE #TMP_OST_FBL5N 
        AS (
	  		WITH CTE_FBL5N  AS   
			    (
				SELECT --DISTINCT
					  -- S.*
				      --
					   F.ASSIGNMENT 
					  ,F.CUSTOMER  	
					  ,F.DOCUMENT_TYPE	
					  ,F.POSTING_KEY
					  ,F.DOCUMENT_NUMBER
					  ,F.AMOUNT_IN_LOCAL_CURRENCY  -- LANÇTO
					  --,COALESCE(TO_DOUBLE(F.AMOUNT_IN_LOCAL_CURRENCY),0) AS VAL_LANCTO
					  ,CONCAT(F.DOCUMENT_TYPE, F.POSTING_KEY) 			 AS DESC_AR
					  --
				  FROM  OW_SEDA_S.ODS_NERP_FBL5N_CUSTOMER_LINE_ITEM_DISPLAY_OPEN_ITEMS_HIST  	AS F
				  --
				  WHERE EXISTS ( SELECT 1  
							       FROM #TMP_OST_SO_TRACKING AS S
								  WHERE S.CUSTOMER_PO = F.ASSIGNMENT 
								     -- 
								     --AND S.MARKETPLACE_ORDER_ID = 'LU-1403470435041216' --'LU-1400670444144705'
							   )
				)
				------------------------------------------------------
				SELECT --DISTINCT
				        S.*
					   ,F.*
					  --
				  FROM ( 
						SELECT --DISTINCT
							    F.*
							   ,SUM(COALESCE(TO_DOUBLE(F.AMOUNT_IN_LOCAL_CURRENCY),0)) OVER(PARTITION BY F.ASSIGNMENT,F.CUSTOMER,F.DESC_AR) AS VAL_TOT_LANCTO_AR 
							  --
						  FROM ( 
								SELECT DISTINCT
									   F.*
									  --
								  FROM       CTE_FBL5N    	AS F
								  WHERE 1=1
								   AND F.DESC_AR  IN ('RV01','DC15')
								) AS F
				       ) AS F 
				  --
				  INNER JOIN  #TMP_OST_SO_TRACKING AS S
					      ON S.CUSTOMER_PO = F.ASSIGNMENT
					     AND S.IND_FICA_NA_FAIXA_ENTREGA = 1
           );
    	--
    	--
    	--SELECT * FROM #TMP_OST_FBL5N;
    	/*
    	 SELECT MKTP, COUNT(1) FROM #TMP_OST_FBL5N GROUP BY MKTP;
    	*/
	------------------------------------------------------------------
    -- PASSO 5 - BASE TRATADA  INDUE- PEDIDOS EM VTEX + SO_TRACKING  + FBL5N  --
	BEGIN
        -- Ignora erros ao tentar apagar a tabela
	    DROP TABLE #TMP_OST_BASE_INDUE;    --- TF_	
    END;
    --  
    CREATE LOCAL TEMPORARY TABLE #TMP_OST_BASE_INDUE 
        AS (
			WITH CTE_BASE  AS   
				(
					SELECT F.* 
						  --
						  ,C.ABBREVIATED_CUSTOMER_NAME
						  ,C.CUSTOMER_NAME
						  --,C.CHANNEL_IDENTIFICATION_TYPE
						  --
						  ,A.CHANNEL_IDENTIFICATION_TYPE	
						  ,A.ACCOUNTS_RECEIVABLE_TYPE_CODE	
						  ,A.ACCOUNTS_RECEIVABLE_TYPE
						  --
						  --,CONCAT(A.ACCOUNTS_RECEIVABLE_TYPE_CODE, A.CHANNEL_IDENTIFICATION_TYPE) AS DESC_AR
						  --
					FROM       #TMP_OST_FBL5N      					AS F
					--
					LEFT JOIN U_JM_BRANDAO.DIM_IDENTICACAO_CANAIS 	AS C
						   ON C.CUSTOMER_CODE = F.CUSTOMER
					--	   
					LEFT JOIN  U_JM_BRANDAO.DIM_TIPO_AR 			AS A
					       ON  A.ACCOUNTS_RECEIVABLE_TYPE_CODE = F.DESC_AR --CONCAT(F.DOCUMENT_TYPE, F.POSTING_KEY)
					       AND A.CHANNEL_IDENTIFICATION_TYPE   = C.CHANNEL_IDENTIFICATION_TYPE 
					--
					--ORDER BY F.MKTP, F.ASSIGNMENT
					--
				),
				------------------------------------------------------
				CTE_INDUE  AS   
				(
					SELECT T.*
						  --,CASE WHEN T.DESC_AR IN ('DC15MKTP') THEN T.VAL_TOT_LANCTO_AR
						  ,MAX(CASE WHEN T.DESC_AR IN ('DC15') THEN T.VAL_TOT_LANCTO_AR
						        END
						      ) OVER(PARTITION BY ORDER_ID)
						      AS VAL_CREDITO_DC15
						  --,CASE WHEN T.DESC_AR IN ('RV01MKTP') THEN T.VAL_TOT_LANCTO_AR
						  ,MAX( CASE WHEN T.DESC_AR IN ('RV01') THEN T.VAL_TOT_LANCTO_AR
						         END
						      ) OVER(PARTITION BY ORDER_ID)
						      AS VAL_ENTREGA_RV01
						  --	       
					FROM CTE_BASE AS T-- U_JM_BRANDAO.TMP_AMOSTRA T
				),
				------------------------------------------------------
				CTE_INDUE_TRATADO  AS   
				(
					SELECT DISTINCT
						   T.*
						  ,(COALESCE(T.VAL_CREDITO_DC15,0) + COALESCE(T.VAL_ENTREGA_RV01,0))					  AS VAL_SALDO
						  ,CASE WHEN (COALESCE(T.VAL_CREDITO_DC15,0) + COALESCE(T.VAL_ENTREGA_RV01,0))  >= 0.01 THEN  'OPEN'
						        WHEN (COALESCE(T.VAL_CREDITO_DC15,0) + COALESCE(T.VAL_ENTREGA_RV01,0))  < -0.01 THEN  'CREDIT'
						        ELSE 'CLOSE'
						   END AS STATUS_AR
						  --
					  FROM  CTE_INDUE  	AS T
					ORDER  BY T.CUSTOMER, T.SEQUENCE
				)
				------------------------------------------------------
				SELECT DISTINCT 
						--* -- MKTP	STATUS	STATUS_DESCRIPTION	SO_NET_PRICE	SO_NET_VALUE  DOCUMENT_DATE		"2ND_GI_CREATE_ON"	"ASSIGNMENT"	CUSTOMER	DOCUMENT_TYPE	POSTING_KEY	DOCUMENT_NUMBER	AMOUNT_IN_LOCAL_CURRENCY	ABBREVIATED_CUSTOMER_NAME ACCOUNTS_RECEIVABLE_TYPE_CODE	ACCOUNTS_RECEIVABLE_TYPE	DESC_AR	 ,BILLED_QTY_BASE	,BILLING_NET_VALUE
						--
						 DATE_REF	
						--,AFFILIATE_ID	  
						--,AFFILIATE_CHANNEL	
						,AFFILIATE_SUB_CHANNEL	
						--
						,CUSTOMER_PO	
						,CUSTOMER_NAME	
						--,"SEQUENCE"
						--	
						,MARKETPLACE_ORDER_ID	
						,ORDER_ID	
						--,BIZ_TYPE	
						--,GLOBAL_CHANNEL	
						--,CHANNEL_TYPE	
						--
						--,ACCOUNT_CODE	
						--,ACCOUNT_NAME	
						--
						,BILLED_QTY_BASE				AS QTY_BASE
						,BILLING_NET_VALUE				AS NET_VALUE
						--
						--,IND_FICA_NA_FAIXA_ENTREGA
						,DT_ENTREGA_PROD				AS DATE_DELIVERY_PRODUCT
						,DIAS_ENTREGA					AS QTY_DAYS_DELIVERY
						,RANGE_PERIOD	
						--
						,CHANNEL_IDENTIFICATION_TYPE	
						--
						,VAL_CREDITO_DC15	
						,VAL_ENTREGA_RV01	
						,VAL_SALDO	
						,STATUS_AR
						,CASE WHEN STATUS_AR = 'CLOSE'  THEN 'Payment done'
						      WHEN STATUS_AR = 'OPEN'   THEN 'Pending Payment'
						      WHEN STATUS_AR = 'CREDIT' THEN 'Payment Credit' 
						      END AS INDUE_STATUS 
						--
				  FROM CTE_INDUE_TRATADO AS T
           );
    	--
    	--
    	--SELECT * FROM #TMP_OST_BASE_INDUE;
    	/*
    	 SELECT AFFILIATE_SUB_CHANNEL, COUNT(1) FROM #TMP_OST_BASE_INDUE GROUP BY AFFILIATE_SUB_CHANNEL;
    	*/
	------------------------------------------------------------------
    -- PASSO 6 - CRIA/ATUALIZA TABELA FATO: OW_LAO.FT_INDUE_PENDING_PAYMENT
	BEGIN
		IF EXISTS(
			SELECT TABLE_NAME
			  FROM SYS.TABLES
			 --WHERE SCHEMA_NAME = 'OW_LAO' 
			 --  AND TABLE_NAME = 'FT_SEDA_INDUE_PENDING_PAYMENT'
			 WHERE SCHEMA_NAME = 'OW_SEDA_S' 
			   AND TABLE_NAME = 'FT_OST_INDUE_PENDING_PAYMENT'
		)
		THEN
			DROP TABLE OW_SEDA_S.FT_OST_INDUE_PENDING_PAYMENT;
		END IF;
    END;
    --  
	--CRIA NOVA TATBELA 
	--CREATE COLUMN TABLE OW_LAO.FT_SEDA_INDUE_PENDING_PAYMENT 
	CREATE COLUMN TABLE OW_SEDA_S.FT_OST_INDUE_PENDING_PAYMENT --OW_LAO.FT_SEDA_INDUE_PENDING_PAYMENT 
		AS (
				SELECT  * --DISTINCT 
						--
				  FROM #TMP_OST_BASE_INDUE AS T
		   );
	------------------------------------------------------------------
		--	
    	--
    	--SELECT * FROM #TMP_OST_PEDIDOS;
   		--SELECT * FROM #TMP_OST_VTEX;
        --SELECT * FROM #TMP_OST_SO_TRACKING;
	    --SELECT * FROM #TMP_OST_FBL5N;
		--SELECT * FROM #TMP_OST_BASE_INDUE;
	    --SELECT * FROM OW_LAO.FT_SEDA_INDUE_PENDING_PAYMENT;
	    --SELECT * FROM OW_SEDA_S.FT_OST_INDUE_PENDING_PAYMENT; --OW_LAO.FT_SEDA_INDUE_PENDING_PAYMENT;
    	--
		--> USAR O PREFIxO - TF_OST_ --
END;
-----------------------------------------------------------------------------
/*
	CREATE COLUMN TABLE OW_SEDA_S.FT_OST_INDUE_PENDING_PAYMENT --OW_LAO.FT_SEDA_INDUE_PENDING_PAYMENT 
		AS (
				SELECT  * --DISTINCT 
						--
				  FROM OW_LAO.FT_SEDA_INDUE_PENDING_PAYMENT AS T
		   );
SELECT * FROM OW_SEDA_S.FT_OST_INDUE_PENDING_PAYMENT;
*/
	
-- CALL U_JM_BRANDAO.PROC_FT_INDUE_PENDING_PAYMENT;
/*
SELECT * FROM OW_LAO.FT_INDUE_PENDING_PAYMENT;
SELECT COUNT(1) FROM OW_LAO.FT_INDUE_PENDING_PAYMENT;
**/