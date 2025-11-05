CREATE PROCEDURE OW_SEDA_S.PROC_FT_OST_PLUGGTO
LANGUAGE SQLSCRIPT AS
BEGIN
	--DECLARE EXIT HANDLER FOR SQLEXCEPTION  -- -- Ignora erros ao tentar apagar a tabela TEMP
	--
	------------------------------------------------------------------
    -- PASSO 1 - BUSCA PEDIDOS - BASE VTEX - COM ultimos 210 + 90 DIAS
    --  
	IF EXISTS(  SELECT TABLE_NAME
				  FROM SYS.TABLES
				 WHERE SCHEMA_NAME = 'OW_SEDA_S' 
				   AND TABLE_NAME  = 'TMP_OST_PLUGG_VTEX_BASE'
		     ) THEN 
			 DROP TABLE OW_SEDA_S.TMP_OST_PLUGG_VTEX_BASE;
	END IF;
    --  
	CREATE COLUMN TABLE OW_SEDA_S.TMP_OST_PLUGG_VTEX_BASE 
        AS (
			  WITH 
			  CT_VTEX
			  AS
				(		SELECT   DISTINCT 
							     MKTP_ORDER_ID
							    --
								,ORDER_ID
								,SEQUENCE
								--
								,AFFILIATE_ID
								-- 
								,STATUS_DESCRIPTION		AS STATUS_VTEX
								,CREATION_TIMESTAMP
								--
							    ,CASE --
							          WHEN MKTP_CREATION_DATE LIKE '__/__/____ %:%:%' THEN TO_TIMESTAMP(MKTP_CREATION_DATE, 'MM/DD/YYYY HH24:MI:SS')
							          WHEN MKTP_CREATION_DATE LIKE '____-__-__T%:%:%' THEN TO_TIMESTAMP(MKTP_CREATION_DATE, 'YYYY-MM-DD"T"HH24:MI:SS')
							          WHEN MKTP_CREATION_DATE LIKE '____-__-__ %:%:%' THEN TO_TIMESTAMP(MKTP_CREATION_DATE, 'YYYY-MM-DD HH24:MI:SS')
							          ELSE NULL -- Ou alguma outra lógica para formatos desconhecidos
							      END AS MKTP_CREATION_DATE
								--
								--,SELLER_ID 
								--,SELLER_NAME
								--
								,TOTAL_ITEMS 
								,TOTAL_DISCOUNTS 
								,TOTAL_SHIPPING 
								,TOTAL_TAX  
							    --
					     FROM	(
									SELECT --DISTINCT
										--REPLACE_REGEXPR('["\[\]]' IN JSON_QUERY(CUSTOM_DATA, '$.customApps.fields.orderIdMarketplace' WITH WRAPPER) WITH '') ORDER_MELI,
									    --
									    CASE -- MELI
									    	 WHEN R.AFFILIATE_ID IN ('MMC','MMP')
									    	 THEN JSON_VALUE(CAST(R.CUSTOM_DATA AS VARCHAR), '$.customApps.fields.orderIdMarketplace' DEFAULT NULL ON EMPTY) 
									    	 --
											 WHEN R.AFFILIATE_ID IN ('VVJ','VVV') 
											 THEN '9862'||R.MARKETPLACE_ORDER_ID
									    	 --
											 WHEN R.AFFILIATE_ID = 'MGT' 
											 THEN R.MARKETPLACE_ORDER_ID||'2435'
									    	 --
											 WHEN R.AFFILIATE_ID IN ('BBW','BWW') 
											 THEN REPLACE(R.MARKETPLACE_ORDER_ID,'_',' ')
									    	 --
											 ELSE R.MARKETPLACE_ORDER_ID
									    	 --
									     END AS MKTP_ORDER_ID
									    --
										,R.ORDER_ID
										--
										,R.SEQUENCE
										,R.AFFILIATE_ID
										-- 
										,R.STATUS_DESCRIPTION
										,R.CREATION_TIMESTAMP
										--
										-- select distinct 1 
										,CASE --
									    	 WHEN R.AFFILIATE_ID IN ('MMC','MMP')
									    	 THEN REPLACE(
									    	      JSON_VALUE(CAST(R.CUSTOM_DATA AS VARCHAR), '$.customApps.fields.CreationDate' DEFAULT NULL ON EMPTY) 
									    	      ,'Z','')
									    	 --
									    	 ELSE REPLACE(
									    	      JSON_VALUE(CAST(R.CUSTOM_DATA AS VARCHAR), '$.customApps.fields.marketplaceCreationDate' DEFAULT NULL ON EMPTY) 
									    	      ,'Z','')
									    	 --
										 END  AS MKTP_CREATION_DATE
										--
										--,SELLER_ID 
										--,SELLER_NAME
										--
										,TO_DECIMAL(R.TOTAL_ITEMS    ,20, 2)/100  AS TOTAL_ITEMS 
										,TO_DECIMAL(R.TOTAL_DISCOUNTS,20, 2)/100  AS TOTAL_DISCOUNTS 
										,TO_DECIMAL(R.TOTAL_SHIPPING ,20, 2)/100  AS TOTAL_SHIPPING 
										,TO_DECIMAL(R.TOTAL_TAX	     ,20, 2)/100  AS TOTAL_TAX  
										--
										--
									-- select *
									FROM       U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER AS  R
									--
									--FROM U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER AS R
									WHERE 1 =1
								 	  AND R.AFFILIATE_ID IN ('MMC','MMP','MGT','VVJ','VVV','BBW','BWW','LRM','CRF','MZN','KBM','LVL','FSH')
									  --
								 	  AND R.CREATION_TIMESTAMP >= ADD_DAYS(CURRENT_DATE,-210 -90)  -- DIAS +90 de antecipa
								) A
								--ORDER BY AFFILIATE_ID,  ORDER_ID
				)
			 --------
			 SELECT * FROM CT_VTEX  
           );
    --  
	------------------------------------------------------------------
    -- PASSO 2 - BUSCA PEDIDOS - COMPLETA VTEX - novos atribuitos
    --  
	IF EXISTS(  SELECT TABLE_NAME
				  FROM SYS.TABLES
				 WHERE SCHEMA_NAME = 'OW_SEDA_S' 
				   AND TABLE_NAME  = 'TMP_OST_PLUGG_VTEX'
		     ) THEN 
			 DROP TABLE OW_SEDA_S.TMP_OST_PLUGG_VTEX;
	END IF;
    --  
	CREATE COLUMN TABLE OW_SEDA_S.TMP_OST_PLUGG_VTEX 
        AS (
			  WITH 
			  CT_VTEX
			  AS
				(    SELECT  DISTINCT
						    --
						     R.MKTP_ORDER_ID
						    --
							,F.MARKETPLACE_ORDER_ID
							,R.ORDER_ID
							--
							,R.SEQUENCE
							--
							,F.AFFILIATE_ID
							,F.AFFILIATE_CHANNEL			
							,F.AFFILIATE_SUB_CHANNEL
							,F.CUSTOMER_PO
							--
							,F.STATE
							,F.CHANNEL_TYPE
							-- 
							,R.STATUS_VTEX 
							--
							,R.CREATION_TIMESTAMP
							,R.MKTP_CREATION_DATE
							--
							,R.TOTAL_ITEMS 
							,R.TOTAL_DISCOUNTS 
							,R.TOTAL_SHIPPING 
							,R.TOTAL_TAX  
							--
							,SUM( TO_DECIMAL(F.QTY			  ,20, 0 )) OVER(PARTITION BY F.ORDER_ID,F.SEQUENCE ) AS QTY
							,SUM( TO_DECIMAL(F.AMOUNT_LOCAL   ,20, 2 )) OVER(PARTITION BY F.ORDER_ID,F.SEQUENCE ) AS AMOUNT_LOCAL
							,SUM( TO_DECIMAL(F.AMOUNT_USD	  ,20, 2 )) OVER(PARTITION BY F.ORDER_ID,F.SEQUENCE ) AS AMOUNT_USD
							,SUM( TO_DECIMAL(F.PRICE_TO	      ,20, 2 )) OVER(PARTITION BY F.ORDER_ID,F.SEQUENCE ) AS PRICE_TO 
							,SUM( TO_DECIMAL(F.AMOUNT_DISCOUNT,20, 2 )) OVER(PARTITION BY F.ORDER_ID,F.SEQUENCE ) AS AMOUNT_DISCOUNT 	
							,SUM( TO_DECIMAL(F.AMOUNT_SHIPPING,20, 2 )) OVER(PARTITION BY F.ORDER_ID,F.SEQUENCE ) AS AMOUNT_SHIPPING
							--
							--,F.REFERENCE_CODE
							--,F.SEDA_DESC_ESTORE
							--
							--
						-- select *
						FROM       OW_SEDA_S.TMP_OST_PLUGG_VTEX_BASE           AS  R
						--
						INNER JOIN OW_LAO.TF_D2C_NERP_SALES 				   AS  F
						        ON F.ORDER_ID = R.ORDER_ID 
						       AND F.SEQUENCE = R.SEQUENCE 
						--
						WHERE 1 =1
						  --AND F.SKU_ID IS NOT NULL 
						  AND F.SOURCE = 'PO'
						--
						ORDER BY 2
				)
			 --------
			 SELECT * FROM CT_VTEX  
           );
    --  
	------------------------------------------------------------------
    -- PASSO 3 - BUSCA PEDIDOS - STATUS PLUGGTO + DATA DE STATUS - ULIMOS 210 DIAS
    --  
	IF EXISTS(  SELECT TABLE_NAME
				  FROM SYS.TABLES
				 WHERE SCHEMA_NAME = 'OW_SEDA_S' 
				   AND TABLE_NAME  = 'TMP_OST_PLUGG_STATUS'
		     ) THEN 
			 DROP TABLE OW_SEDA_S.TMP_OST_PLUGG_STATUS;
	END IF;
    --  
	CREATE COLUMN TABLE OW_SEDA_S.TMP_OST_PLUGG_STATUS 
        AS (
			  WITH 
			  CT_ATUAL
			  AS
				(SELECT A.*
				   FROM --
						 (SELECT DISTINCT 
								 ORIGINAL_ORDER_ID  
								,STATUS
								,DATE_GMT_BRAZIL
								,ROW_NUMBER() OVER (PARTITION BY ORIGINAL_ORDER_ID
								                        ORDER BY DATE_GMT_BRAZIL DESC
								                                ,LOAD_DATE DESC 
								                                ,STATUS
								                   ) AS SEQ_STATUS 
							FROM OW_SEDA_S.ODS_PLUGG_MARKETPLACE_ORDER_STATUS_HISTORY 
							WHERE 1 =1 
							AND DATE_GMT_BRAZIL >= ADD_DAYS(CURRENT_DATE,-210)
							--
							--WHERE STATUS IN ('canceled', 'under_review')
							--AND DATE_GMT_BRAZIL >= ADD_DAYS(CURRENT_DATE,-180)
							--ORDER BY 1, 3 DESC, 2
						) A
				  WHERE A.SEQ_STATUS = 1
				)
			 --------
			 ,CT_CRIA
			  AS
				(SELECT A.*
				   FROM --
						( SELECT DISTINCT 
								 ORIGINAL_ORDER_ID  
								--,STATUS
								,DATE_GMT_BRAZIL
								,ROW_NUMBER() OVER (PARTITION BY ORIGINAL_ORDER_ID
								                        ORDER BY DATE_GMT_BRAZIL DESC
								                                ,LOAD_DATE DESC 
								                                --,STATUS
								                   ) AS SEQ_CRIA 
							FROM OW_SEDA_S.ODS_PLUGG_MARKETPLACE_ORDER_LOG_HISTORY 
							WHERE 1 =1 
							AND DATE_GMT_BRAZIL >= ADD_DAYS(CURRENT_DATE,-210)
							--
							AND INSTR( MESSAGE, 'cria' ) > 0
							--
							--ORDER BY 1, 3 DESC, 2
					  ) A
				 WHERE A.SEQ_CRIA = 1
				)
			 --------
			 ,CT_STATUS
			  AS
				(	  SELECT DISTINCT 
							 S.ORIGINAL_ORDER_ID  
							,A.STATUS
							,C.DATE_GMT_BRAZIL		AS CREATE_DATE_GMT_BRAZIL
							,A.DATE_GMT_BRAZIL		AS STATUS_DATE_GMT_BRAZIL
							--
						FROM       OW_SEDA_S.ODS_PLUGG_MARKETPLACE_ORDER_STATUS_HISTORY  AS S
						INNER JOIN CT_ATUAL                                              AS A
						        ON S.ORIGINAL_ORDER_ID = A.ORIGINAL_ORDER_ID
						       --AND A.SEQ_STATUS = 1
						LEFT  JOIN CT_CRIA                                               AS C
						        ON S.ORIGINAL_ORDER_ID = C.ORIGINAL_ORDER_ID
						        --AND C.SEQ_CRIA = 1
				)
			 --------
			 SELECT * FROM CT_STATUS
           );
    --  
	------------------------------------------------------------------
    -- PASSO 4 - BUSCA PEDIDOS - UNIR STATUS PLUGGTO + VTEXT  
    --  
	IF EXISTS(  SELECT TABLE_NAME
				  FROM SYS.TABLES
				 WHERE SCHEMA_NAME = 'OW_SEDA_S' 
				   AND TABLE_NAME  = 'TMP_OST_PLUGG_STATUS_COM_VTEX'
		     ) THEN 
			 DROP TABLE OW_SEDA_S.TMP_OST_PLUGG_STATUS_COM_VTEX;
	END IF;
    --  
	CREATE COLUMN TABLE OW_SEDA_S.TMP_OST_PLUGG_STATUS_COM_VTEX 
        AS (
			  WITH 
			--D2C_PLUGG_STATUS  --> OST_PLUGG_STATUS_COM_VTEX
			  CT_STATUS
			  AS
				(		SELECT *
				          FROM OW_SEDA_S.TMP_OST_PLUGG_STATUS
			    )
			 --------
			 ,CT_VTEX
			  AS
				(		SELECT *
				          FROM OW_SEDA_S.TMP_OST_PLUGG_VTEX 
			    )
			 --------
			 SELECT      --
				         S.ORIGINAL_ORDER_ID
					    ,V.MKTP_ORDER_ID
					    ,V.MARKETPLACE_ORDER_ID
						 --
						,V.ORDER_ID
						,V.SEQUENCE
						--
						,V.AFFILIATE_ID	
						,V.AFFILIATE_CHANNEL	
						,V.AFFILIATE_SUB_CHANNEL	
						,V.CUSTOMER_PO	
						,V.STATE	
						,V.CHANNEL_TYPE
						-- 
						,S.STATUS		 		AS STATUS_PLUGG
						,V.STATUS_VTEX   				
						--
						,IFNULL(S.CREATE_DATE_GMT_BRAZIL, V.MKTP_CREATION_DATE) AS CREATE_DATE_TIME
						--
						,V.CREATION_TIMESTAMP			AS VTEX_CREATE_DATE_TIME
					    ,V.MKTP_CREATION_DATE			AS MKTP_CREATE_DATE_TIME
					    --
						,S.CREATE_DATE_GMT_BRAZIL		AS STATUS_CREATE_DATE_TIME
						,S.STATUS_DATE_GMT_BRAZIL		AS STATUS_CURRENT_DATE_TIME
						--
						--,V.SELLER_ID 
						--,V.SELLER_NAME
						--
						,V.TOTAL_ITEMS 
						,V.TOTAL_DISCOUNTS 
						,V.TOTAL_SHIPPING 
						,V.TOTAL_TAX  
						--
						--
						,V.QTY	
						,V.PRICE_TO	
						,V.AMOUNT_LOCAL	
						,V.AMOUNT_USD	
						,V.AMOUNT_DISCOUNT	
						,V.AMOUNT_SHIPPING
						--
			     FROM	   CT_STATUS AS S
			     LEFT JOIN CT_VTEX   AS V
				        ON S.ORIGINAL_ORDER_ID = V.MKTP_ORDER_ID
           );
    --  
	------------------------------------------------------------------
    -- PASSO 5 - BUSCA PEDIDOS - ATUAIS DE PLUGGTO - ULITMOS 210 DIAS
    --  
	IF EXISTS(  SELECT TABLE_NAME
				  FROM SYS.TABLES
				 WHERE SCHEMA_NAME = 'OW_SEDA_S' 
				   AND TABLE_NAME  = 'TMP_OST_PLUGG'
		     ) THEN 
			 DROP TABLE OW_SEDA_S.TMP_OST_PLUGG;
	END IF;
    --  
	CREATE COLUMN TABLE OW_SEDA_S.TMP_OST_PLUGG 
        AS (
			  WITH 
			  CT_PLUGG
			  AS
				(		
				 SELECT --
						 O.CHANNEL
						--
						,P.AFFILIATE_ID	
						,P.AFFILIATE_CHANNEL	
						,P.AFFILIATE_SUB_CHANNEL	
						,P.CUSTOMER_PO	
						,P.STATE	
						,P.CHANNEL_TYPE
						--
						,P.STATUS_PLUGG --STATUS_HIST,
						,P.STATUS_VTEX
						--
						,TO_DATE(P.STATUS_CURRENT_DATE_TIME) 	DATE_STATUS_PLUGG
						,HOUR(P.STATUS_CURRENT_DATE_TIME) 		HOUR
						,WEEKDAY(P.STATUS_CURRENT_DATE_TIME) 	WEEKDAY
						--
						,P.STATUS_CURRENT_DATE_TIME
						,P.CREATE_DATE_TIME 
						--
						,CASE 
							WHEN O.CHANNEL = 'Cnova' 		  	THEN SUBSTRING(O.ORIGINAL_ORDER_ID, 5, 99)
							WHEN O.CHANNEL = 'MagazineLuiza'  	THEN SUBSTRING(O.ORIGINAL_ORDER_ID, 1, LENGTH(O.ORIGINAL_ORDER_ID)-4)
							WHEN O.CHANNEL = 'MercadoLivre' 	THEN O.ORIGINAL_ORDER_ID
							WHEN O.CHANNEL = 'b2w' 				THEN REPLACE(O.ORIGINAL_ORDER_ID,' ','_')
							WHEN O.CHANNEL = 'Carrefour' 		THEN O.ORIGINAL_ORDER_ID
							WHEN O.CHANNEL = 'LeroyMerlin' 		THEN O.ORIGINAL_ORDER_ID
							WHEN O.CHANNEL LIKE '%Amazon%' 		THEN O.ORIGINAL_ORDER_ID
							WHEN O.CHANNEL = 'kabum' 			THEN O.ORIGINAL_ORDER_ID
						ELSE O.ORIGINAL_ORDER_ID --NULL
						END ORIGINAL_ORDER_ID
						--
						--
				        --,P.ORIGINAL_ORDER_ID
					    --,P.MKTP_ORDER_ID
					    ,P.MARKETPLACE_ORDER_ID
						 --
						,P.ORDER_ID
						,P.SEQUENCE
						--
						,O.DELIVERY_TYPE 
						--,O.INTERMEDIARY_SELLER_ID 
						--
						--,TO_DECIMAL(O.TOTAL_PAID, 20, 2)		TOTAL_PAID 
						--
						--,P.TOTAL_ITEMS 
						--,P.TOTAL_DISCOUNTS 
						--,P.TOTAL_SHIPPING 
						--,P.TOTAL_TAX  
					    --
						,P.QTY
						,P.PRICE_TO	
						,P.AMOUNT_LOCAL	
						,P.AMOUNT_USD	
						,P.AMOUNT_DISCOUNT	
						,P.AMOUNT_SHIPPING
						--
						,NOW()	AS LOAD_DATE
					--	
					FROM       OW_SEDA_S.ODS_PLUGG_MARKETPLACE_ORDER 		    O
					-- LEFT
					INNER JOIN OW_SEDA_S.TMP_OST_PLUGG_STATUS_COM_VTEX			P
						    ON O.ORIGINAL_ORDER_ID  = P.ORIGINAL_ORDER_ID
					--
				    WHERE 1=1
				    --  AND o.STATUS IN ('canceled', 'under_review')
					--ORDER BY CANCELED_DATE_TIME DESC
			    )
			 --------
			 SELECT * 
			   FROM CT_PLUGG
          );
    --  
	------------------------------------------------------------------
    -- PASSO 5 - CRIA TABELA FATO
    --  
	IF EXISTS(  SELECT TABLE_NAME
				  FROM SYS.TABLES
				 WHERE SCHEMA_NAME = 'OW_SEDA_S' 
				   AND TABLE_NAME  = 'FT_OST_PLUGGTO'
		     ) THEN 
			 DROP TABLE OW_SEDA_S.FT_OST_PLUGGTO;
	END IF;
    --  
	CREATE COLUMN TABLE OW_SEDA_S.FT_OST_PLUGGTO 
        AS (
			 --------
			 SELECT * 
			   FROM OW_SEDA_S.TMP_OST_PLUGG
			  ORDER BY CHANNEL, STATUS_PLUGG, STATUS_CURRENT_DATE_TIME
          );
    --  
	------------------------------------------------------------------
    -- GRANT SELECT ON  "OW_SEDA_S"."FT_OST_PLUGGTO" TO TGT_SEDA_BI_ESTORE WITH GRANT OPTION;
    --  
	------------------------------------------------------------------
	------------------------------------------------------------------
	    --SELECT * FROM OW_SEDA_S.TMP_OST_PLUGG_VTEX_BASE
	    --SELECT * FROM OW_SEDA_S.TMP_OST_PLUGG_VTEX
	    --SELECT * FROM OW_SEDA_S.TMP_OST_PLUGG_STATUS
		--SELECT * FROM OW_SEDA_S.TMP_OST_PLUGG_STATUS_COM_VTEX
		--SELECT * FROM OW_SEDA_S.TMP_OST_PLUGG
		--SELECT * FROM OW_SEDA_S.FT_OST_PLUGGTO
    	--
		--> USAR O PREFIxO - TF_OST_ --
END;
