CREATE PROCEDURE OW_SEDA_S.PROC_OST_AFTERSALES_REFUND_TEMP_BRB2B
--
LANGUAGE SQLSCRIPT AS
BEGIN
	--DECLARE EXIT HANDLER FOR SQLEXCEPTION  -- -- Ignora erros ao tentar apagar a tabela TEMP
	--
	------------------------------------------------------------------
    -- PASSO 1 - BUSCA PEDIDOS - DAS BASE ORIGEM - POR MARKETPLACE 
    --  
	IF EXISTS(  SELECT TABLE_NAME
				  FROM SYS.TABLES
				 WHERE SCHEMA_NAME = 'OW_SEDA_S' 
				   AND TABLE_NAME  = 'TMP_OST_REFUND_2'
		     ) THEN 
			 DROP TABLE OW_SEDA_S.TMP_OST_REFUND_2;
	END IF;
    --  
	CREATE COLUMN TABLE OW_SEDA_S.TMP_OST_REFUND_2 
			/*
                     'BRSHOP'  			AS INSTANCES -- TMP_OST_REFUND_1 -- 
                     'BRB2B'   			AS INSTANCES -- TMP_OST_REFUND_2 -- 
                     'BREA'  			AS INSTANCES -- TMP_OST_REFUND_3 -- 
                     'BRSHOPMKTPL'  	AS INSTANCES -- TMP_OST_REFUND_4 -- 
                     'BREPP2'  			AS INSTANCES -- TMP_OST_REFUND_5 -- 
                     'EPP2ESTUDANTES'  	AS INSTANCES -- TMP_OST_REFUND_6 -- 
                     'EPP2MEMBERS'  	AS INSTANCES -- TMP_OST_REFUND_7 -- 
                     'EPP2PARCERIAS'  	AS INSTANCES -- TMP_OST_REFUND_8 -- 
                     'EPP2RESIDENCIAL'  AS INSTANCES -- TMP_OST_REFUND_9 -- 
			*/
        AS (
-------------------------------------------------
-------------------------------------------------
-------------------------------------------------
SELECT DISTINCT 
       T_INST.INSTANCES
      --
      ,TO_DATE( 
		      -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
		      ADD_SECONDS(TO_TIMESTAMP(GREATEST(A.CREATED_AT, A.UPDATED_AT)), -(3 * 60 * 60) ) 
             )																									AS "DATE_REF"
      ,CL.YYYYWW 																								AS "YYYYWW"
      ,CL.YYYYMM 																								AS "YYYYMM"
      --
     ,LPAD(TO_VARCHAR(HOUR(   -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
						      ADD_SECONDS(TO_TIMESTAMP(GREATEST(A.CREATED_AT, A.UPDATED_AT)), -(3 * 60 * 60) ) 
                          )), 2, '0')																			AS "Horas"
     ,LPAD(TO_VARCHAR(MINUTE( -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
						      ADD_SECONDS(TO_TIMESTAMP(GREATEST(A.CREATED_AT, A.UPDATED_AT)), -(3 * 60 * 60) ) 
                            )), 2, '0')																		    AS "Minutos"
	  --
     ,TO_VARCHAR(TO_TIME(     -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
						      ADD_SECONDS(TO_TIMESTAMP(GREATEST(A.CREATED_AT, A.UPDATED_AT)), -(3 * 60 * 60) ) 
                        ), 'HH24:MI:SS') 																		AS "Horário"
     --
	 -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
	 ,ADD_SECONDS(TO_TIMESTAMP(A.CREATED_AT), -(3 * 60 * 60) )													AS "Data criação Reembolso"
	 -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
	 ,ADD_SECONDS(TO_TIMESTAMP(A.UPDATED_AT), -(3 * 60 * 60) )													AS "Data atualização Reembolso" 
	  --
	  ,D.ID_DETAIL																								AS "ID Reembolso" 
	  ,D.REVERSE_ID  																							AS "ID Reversa"
	  ,D.REVERSE_STATUS_DESCRIPTION 																			AS "Status Reversa"
	  --
	  ,A.ORDER_ID																								AS "ID Pedido"			-- D.REVERSE_ECOMMERCEORDER_ORDER_ID
	  --
	  -- ATÉ 5 SELLERS_NAME / LOCAIS
	  ,CASE   WHEN JSON_VALUE(D.SELLERS_NAME, '$[0]' DEFAULT NULL ON EMPTY) IS NOT NULL
	          THEN JSON_VALUE(D.SELLERS_NAME, '$[0]' DEFAULT NULL ON EMPTY)
	          --
	          WHEN JSON_VALUE(D.SELLERS_NAME, '$[1]' DEFAULT NULL ON EMPTY) IS NOT NULL
	          THEN JSON_VALUE(D.SELLERS_NAME, '$[1]' DEFAULT NULL ON EMPTY)
	          --
	          WHEN JSON_VALUE(D.SELLERS_NAME, '$[2]' DEFAULT NULL ON EMPTY) IS NOT NULL
	          THEN JSON_VALUE(D.SELLERS_NAME, '$[2]' DEFAULT NULL ON EMPTY)
	          --
	          WHEN JSON_VALUE(D.SELLERS_NAME, '$[3]' DEFAULT NULL ON EMPTY) IS NOT NULL
	          THEN JSON_VALUE(D.SELLERS_NAME, '$[3]' DEFAULT NULL ON EMPTY)
	          --
	          WHEN JSON_VALUE(D.SELLERS_NAME, '$[4]' DEFAULT NULL ON EMPTY) IS NOT NULL
	          THEN JSON_VALUE(D.SELLERS_NAME, '$[4]' DEFAULT NULL ON EMPTY)
	     END     
	     AS "Local Origem Pedido"
	  --,REPLACE(REPLACE(D.SELLERS_NAME, '["', ''), '"]', '')				AS "Local Origem Pedido"
	  --
	  ,D.REVERSE_PARTNER_STORE																					AS "Loja Parceira"
	  --
	  ,CONCAT(CONCAT(D.CUSTOMER_FIRST_NAME,' '), D.CUSTOMER_LAST_NAME) 											AS "Nome Cliente"
	  ,D.CUSTOMER_EMAIL																							AS "Email Cliente"
	  ,D.CUSTOMER_DOCUMENT																						AS "Documento Cliente"
	  --
	  ,A.TYPE_DATA																								AS "Tipo Reembolso"  -- D.REVERSE_DETAIL_TYPE
	  ,A.ACTION_DATA																							AS "Ação Reembolso"	 -- D.REVERSE_DETAIL_ACTION
	  --
	  ,D.STATUS_DESCRIPTION																						AS "Status Reembolso"
	  --
	  ,TO_DECIMAL( D.REQUESTED_RAW_AMOUNT     , 20, 2 )															AS "Valor bruto solicitado"
	  ,TO_DECIMAL( D.REQUESTED_SHIPPING_AMOUNT, 20, 2 ) 														AS "Valor envio socilitado"
	  ,TO_DECIMAL( D.REQUESTED_AMOUNT 		  , 20, 2 )															AS "Valor solicitado"
	  ,TO_DECIMAL( D.BONUS_AMOUNT			  , 20, 2 )															AS "Valor bônus solicitado"
	  --
	  ,CASE WHEN D.FREE_SHIPPING = 'true'  THEN 'Sim'
	  		WHEN D.FREE_SHIPPING = 'false' THEN 'Não'
	        END																									AS "Retenção com frete grátis?"
	  --
	  ,TO_DECIMAL( D.REQUESTED_TOTAL_AMOUNT   , 20, 2 )															AS "Valor total solicitado"
	  ,TO_DECIMAL( D.RECEIVED_RAW_AMOUNT	  , 20, 2 )															AS "Valor bruto recebido"
	  ,TO_DECIMAL( D.RECEIVED_AMOUNT		  , 20, 2 )															AS "Valor recebido"
	  ,TO_DECIMAL( D.TOTAL_AMOUNT			  , 20, 2 )															AS "Valor total"
	  --
	  ,JSON_VALUE(CAST(D.VOUCHER AS VARCHAR), '$.giftcard_id' DEFAULT NULL ON EMPTY)							AS "Código Voucher"
	  --
	  --
	  ,CASE WHEN JSON_VALUE(CAST(D.CASHBACK_ACCOUNT AS VARCHAR), '$.bank.bank_code' DEFAULT NULL ON EMPTY) IS NOT NULL
	        THEN 'Sim'
	        END
	        AS "Tem conta bancária"
	  --	             
	  ,JSON_VALUE(CAST(D.CASHBACK_ACCOUNT AS VARCHAR), '$.bank.bank_code' 	  DEFAULT NULL ON EMPTY) 
	        AS "Banco"
	  ,JSON_VALUE(CAST(D.CASHBACK_ACCOUNT AS VARCHAR), '$.bank.bank_name' 	  DEFAULT NULL ON EMPTY) 
	        AS "Nome do Banco"
	  ,JSON_VALUE(CAST(D.CASHBACK_ACCOUNT AS VARCHAR), '$.bank.agency_number' DEFAULT NULL ON EMPTY) 
	        AS "Número da agência"
	  ,JSON_VALUE(CAST(D.CASHBACK_ACCOUNT AS VARCHAR), '$.bank.agency_digit'  DEFAULT NULL ON EMPTY) 
	        AS "Dígito da agência"
	  ,JSON_VALUE(CAST(D.CASHBACK_ACCOUNT AS VARCHAR), '$.id'  		  		  DEFAULT NULL ON EMPTY) 
	        AS "Número da conta"
	  --
	  --       AS "Dígito da conta"
	  --
	  ,JSON_VALUE(CAST(D.CASHBACK_ACCOUNT AS VARCHAR), '$.account_type' 	  DEFAULT NULL ON EMPTY) 
	        AS "Tipo de conta"
	  ,JSON_VALUE(CAST(D.CASHBACK_ACCOUNT AS VARCHAR), '$.pix_key_type' 	  DEFAULT NULL ON EMPTY) 
	        AS "Tipo de chave Pix"
	  ,JSON_VALUE(CAST(D.CASHBACK_ACCOUNT AS VARCHAR), '$.pix_key'		 	  DEFAULT NULL ON EMPTY) 
	        AS "Chave Pix"
	  --
	  --
	  -- ATÉ 5 PAGTOS CONCACTENADOS
	  ,CASE   WHEN JSON_VALUE(D.ORDER_PAYMENT_METHODS_DETAILED_VALUE, '$[0]' DEFAULT NULL ON EMPTY) IS NOT NULL
	          THEN
				     JSON_VALUE(D.ORDER_PAYMENT_METHODS_DETAILED_DESCRIPTION, '$[0]' DEFAULT NULL ON EMPTY)
				     || ': $' ||
				     REPLACE( JSON_VALUE(D.ORDER_PAYMENT_METHODS_DETAILED_VALUE, '$[0]' DEFAULT NULL ON EMPTY), '.', ',')
			  END
		 ||
	     CASE WHEN JSON_VALUE(D.ORDER_PAYMENT_METHODS_DETAILED_VALUE, '$[1]' DEFAULT NULL ON EMPTY) IS NOT NULL
	          THEN
				     ';  ' ||
				     JSON_VALUE(D.ORDER_PAYMENT_METHODS_DETAILED_DESCRIPTION, '$[1]' DEFAULT NULL ON EMPTY)
				     || ': $' ||
				     REPLACE( JSON_VALUE(D.ORDER_PAYMENT_METHODS_DETAILED_VALUE, '$[1]' DEFAULT NULL ON EMPTY), '.', ',')
			  ELSE ''
			  END
		 ||
	     CASE WHEN JSON_VALUE(D.ORDER_PAYMENT_METHODS_DETAILED_VALUE, '$[2]' DEFAULT NULL ON EMPTY) IS NOT NULL
	          THEN
				     ';  ' ||
				     JSON_VALUE(D.ORDER_PAYMENT_METHODS_DETAILED_DESCRIPTION, '$[2]' DEFAULT NULL ON EMPTY)
				     || ': $' ||
				     REPLACE( JSON_VALUE(D.ORDER_PAYMENT_METHODS_DETAILED_VALUE, '$[2]' DEFAULT NULL ON EMPTY), '.', ',')
			  ELSE ''
			  END
		 ||
	     CASE WHEN JSON_VALUE(D.ORDER_PAYMENT_METHODS_DETAILED_VALUE, '$[3]' DEFAULT NULL ON EMPTY) IS NOT NULL
	          THEN
				     ';  ' ||
				     JSON_VALUE(D.ORDER_PAYMENT_METHODS_DETAILED_DESCRIPTION, '$[3]' DEFAULT NULL ON EMPTY)
				     || ': $' ||
				     REPLACE( JSON_VALUE(D.ORDER_PAYMENT_METHODS_DETAILED_VALUE, '$[3]' DEFAULT NULL ON EMPTY), '.', ',')
			  ELSE ''
			  END
	      AS  "Métodos Pagamento do pedido"
/*	  --
Pix: R$ 5879,23
Vale Troca: R$ 99, Pix: R$ 30,84
Nubank: R$ 3920
Vale Troca: R$ 99, Cartão de Crédito: R$ 3700
Cartão de Crédito: R$ 3570,44
Cartão de Crédito: R$ 4499,1
Nubank: R$ 114,11
Cartão de Crédito: R$ 1599
MercadoPagoPro: R$ 16928,14
Nubank: R$ 1999
-- ORDER_PAYMENT_METHODS_DETAILED_VALUE  + ORDER_PAYMENT_METHODS_DETAILED_DESCRIPTION  +   
[5879.23]	["Pix"]
[5879.23]	["Pix"]
[99,30.84]	["Vale Troca","Pix"]
[3920]		["Nubank"]
[99,3700]	["Vale Troca","Cartão de Crédito"]
[3570.44]	["Cartão de Crédito"]
[4499.1]	["Cartão de Crédito"]
[114.11]	["Nubank"]
[1599]		["Cartão de Crédito"]
[16928.14]	["MercadoPagoPro"]
[1999]		["Nubank"]
*/
	  --
	  --
	  -- tratamento de 14 item dos matriz, pra identifica data da(s) coluna(s) -> 'Solicitado'
	  ,CASE WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[0]' DEFAULT NULL ON EMPTY) = 'Solicitado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[0]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[1]' DEFAULT NULL ON EMPTY) = 'Solicitado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[1]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[2]' DEFAULT NULL ON EMPTY) = 'Solicitado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[2]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[3]' DEFAULT NULL ON EMPTY) = 'Solicitado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[3]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[4]' DEFAULT NULL ON EMPTY) = 'Solicitado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[4]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[5]' DEFAULT NULL ON EMPTY) = 'Solicitado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[5]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[6]' DEFAULT NULL ON EMPTY) = 'Solicitado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[6]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[7]' DEFAULT NULL ON EMPTY) = 'Solicitado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[7]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[8]' DEFAULT NULL ON EMPTY) = 'Solicitado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[8]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[9]' DEFAULT NULL ON EMPTY) = 'Solicitado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[9]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[10]' DEFAULT NULL ON EMPTY) = 'Solicitado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[10]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[11]' DEFAULT NULL ON EMPTY) = 'Solicitado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[11]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[12]' DEFAULT NULL ON EMPTY) = 'Solicitado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[12]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[13]' DEFAULT NULL ON EMPTY) = 'Solicitado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[13]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[14]' DEFAULT NULL ON EMPTY) = 'Solicitado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[14]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[15]' DEFAULT NULL ON EMPTY) = 'Solicitado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[15]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
	        --
	        ELSE ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.TOTAL_AMOUNT_HISTORIES_DATE, '$[0]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
	   -- 
	   END AS "Solicitado em"
	  --
	  --
	  -- tratamento de 14 item dos matriz, pra identifica data da(s) coluna(s) -> 'Aprovado'
	  ,CASE WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[0]' DEFAULT NULL ON EMPTY) = 'Aprovado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[0]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[1]' DEFAULT NULL ON EMPTY) = 'Aprovado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[1]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[2]' DEFAULT NULL ON EMPTY) = 'Aprovado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[2]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[3]' DEFAULT NULL ON EMPTY) = 'Aprovado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[3]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[4]' DEFAULT NULL ON EMPTY) = 'Aprovado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[4]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[5]' DEFAULT NULL ON EMPTY) = 'Aprovado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[5]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[6]' DEFAULT NULL ON EMPTY) = 'Aprovado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[6]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[7]' DEFAULT NULL ON EMPTY) = 'Aprovado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[7]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[8]' DEFAULT NULL ON EMPTY) = 'Aprovado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[8]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[9]' DEFAULT NULL ON EMPTY) = 'Aprovado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[9]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[10]' DEFAULT NULL ON EMPTY) = 'Aprovado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[10]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[11]' DEFAULT NULL ON EMPTY) = 'Aprovado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[11]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[12]' DEFAULT NULL ON EMPTY) = 'Aprovado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[12]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[13]' DEFAULT NULL ON EMPTY) = 'Aprovado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[13]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[14]' DEFAULT NULL ON EMPTY) = 'Aprovado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[14]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[15]' DEFAULT NULL ON EMPTY) = 'Aprovado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[15]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
	        --
	   END AS "Aprovado em"
	  --
	  --
	  -- tratamento de 14 item dos matriz, pra identifica data da(s) coluna(s) -> 'Pago'
	  ,CASE WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[0]' DEFAULT NULL ON EMPTY) = 'Pago'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[0]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[1]' DEFAULT NULL ON EMPTY) = 'Pago'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[1]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[2]' DEFAULT NULL ON EMPTY) = 'Pago'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[2]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[3]' DEFAULT NULL ON EMPTY) = 'Pago'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[3]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[4]' DEFAULT NULL ON EMPTY) = 'Pago'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[4]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[5]' DEFAULT NULL ON EMPTY) = 'Pago'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[5]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[6]' DEFAULT NULL ON EMPTY) = 'Pago'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[6]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[7]' DEFAULT NULL ON EMPTY) = 'Pago'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[7]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[8]' DEFAULT NULL ON EMPTY) = 'Pago'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[8]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[9]' DEFAULT NULL ON EMPTY) = 'Pago'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[9]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[10]' DEFAULT NULL ON EMPTY) = 'Pago'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[10]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[11]' DEFAULT NULL ON EMPTY) = 'Pago'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[11]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[12]' DEFAULT NULL ON EMPTY) = 'Pago'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[12]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[13]' DEFAULT NULL ON EMPTY) = 'Pago'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[13]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[14]' DEFAULT NULL ON EMPTY) = 'Pago'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[14]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[15]' DEFAULT NULL ON EMPTY) = 'Pago'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[15]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
	        --
	   END AS "Pago em"
	  --
	  --
	  -- tratamento de 14 item dos matriz, pra identifica data da(s) coluna(s) -> 'Falha de pagamento'
	  ,CASE WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[0]' DEFAULT NULL ON EMPTY) = 'Falha de pagamento'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[0]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[1]' DEFAULT NULL ON EMPTY) = 'Falha de pagamento'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[1]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[2]' DEFAULT NULL ON EMPTY) = 'Falha de pagamento'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[2]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[3]' DEFAULT NULL ON EMPTY) = 'Falha de pagamento'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[3]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[4]' DEFAULT NULL ON EMPTY) = 'Falha de pagamento'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[4]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[5]' DEFAULT NULL ON EMPTY) = 'Falha de pagamento'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[5]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[6]' DEFAULT NULL ON EMPTY) = 'Falha de pagamento'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[6]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[7]' DEFAULT NULL ON EMPTY) = 'Falha de pagamento'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[7]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[8]' DEFAULT NULL ON EMPTY) = 'Falha de pagamento'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[8]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[9]' DEFAULT NULL ON EMPTY) = 'Falha de pagamento'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[9]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[10]' DEFAULT NULL ON EMPTY) = 'Falha de pagamento'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[10]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[11]' DEFAULT NULL ON EMPTY) = 'Falha de pagamento'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[11]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[12]' DEFAULT NULL ON EMPTY) = 'Falha de pagamento'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[12]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[13]' DEFAULT NULL ON EMPTY) = 'Falha de pagamento'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[13]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[14]' DEFAULT NULL ON EMPTY) = 'Falha de pagamento'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[14]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[15]' DEFAULT NULL ON EMPTY) = 'Falha de pagamento'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[15]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
	        --
	   END AS "Falha em"
	  --
	  --
	  -- tratamento de 14 item dos matriz, pra identifica data da(s) coluna(s) -> 'Cancelado'
	  ,CASE WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[0]' DEFAULT NULL ON EMPTY) = 'Cancelado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[0]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[1]' DEFAULT NULL ON EMPTY) = 'Cancelado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[1]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[2]' DEFAULT NULL ON EMPTY) = 'Cancelado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[2]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[3]' DEFAULT NULL ON EMPTY) = 'Cancelado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[3]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[4]' DEFAULT NULL ON EMPTY) = 'Cancelado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[4]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[5]' DEFAULT NULL ON EMPTY) = 'Cancelado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[5]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[6]' DEFAULT NULL ON EMPTY) = 'Cancelado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[6]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[7]' DEFAULT NULL ON EMPTY) = 'Cancelado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[7]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[8]' DEFAULT NULL ON EMPTY) = 'Cancelado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[8]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[9]' DEFAULT NULL ON EMPTY) = 'Cancelado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[9]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[10]' DEFAULT NULL ON EMPTY) = 'Cancelado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[10]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[11]' DEFAULT NULL ON EMPTY) = 'Cancelado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[11]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[12]' DEFAULT NULL ON EMPTY) = 'Cancelado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[12]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[13]' DEFAULT NULL ON EMPTY) = 'Cancelado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[13]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[14]' DEFAULT NULL ON EMPTY) = 'Cancelado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[14]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[15]' DEFAULT NULL ON EMPTY) = 'Cancelado'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[15]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
	        --
	   END AS "Cancelado em"
	  --
	  --
	  -- tratamento de 14 item dos matriz, pra identifica data da(s) coluna(s) -> 'Aguardando aprovação'  **
	  ,CASE WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[0]' DEFAULT NULL ON EMPTY) = 'Aguardando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[0]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[1]' DEFAULT NULL ON EMPTY) = 'Aguardando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[1]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[2]' DEFAULT NULL ON EMPTY) = 'Aguardando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[2]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[3]' DEFAULT NULL ON EMPTY) = 'Aguardando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[3]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[4]' DEFAULT NULL ON EMPTY) = 'Aguardando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[4]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[5]' DEFAULT NULL ON EMPTY) = 'Aguardando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[5]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[6]' DEFAULT NULL ON EMPTY) = 'Aguardando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[6]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[7]' DEFAULT NULL ON EMPTY) = 'Aguardando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[7]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[8]' DEFAULT NULL ON EMPTY) = 'Aguardando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[8]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[9]' DEFAULT NULL ON EMPTY) = 'Aguardando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[9]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[10]' DEFAULT NULL ON EMPTY) = 'Aguardando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[10]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[11]' DEFAULT NULL ON EMPTY) = 'Aguardando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[11]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[12]' DEFAULT NULL ON EMPTY) = 'Aguardando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[12]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[13]' DEFAULT NULL ON EMPTY) = 'Aguardando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[13]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[14]' DEFAULT NULL ON EMPTY) = 'Aguardando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[14]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[15]' DEFAULT NULL ON EMPTY) = 'Aguardando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[15]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
	        --
	   END AS "Aguardando aprovação em"
	  --
	  --
	  -- tratamento de 14 item dos matriz, pra identifica data da(s) coluna(s) -> 'Aguardando dados bancários'  **
	  ,CASE WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[0]' DEFAULT NULL ON EMPTY) = 'Aguardando dados bancários'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[0]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[1]' DEFAULT NULL ON EMPTY) = 'Aguardando dados bancários'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[1]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[2]' DEFAULT NULL ON EMPTY) = 'Aguardando dados bancários'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[2]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[3]' DEFAULT NULL ON EMPTY) = 'Aguardando dados bancários'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[3]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[4]' DEFAULT NULL ON EMPTY) = 'Aguardando dados bancários'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[4]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[5]' DEFAULT NULL ON EMPTY) = 'Aguardando dados bancários'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[5]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[6]' DEFAULT NULL ON EMPTY) = 'Aguardando dados bancários'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[6]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[7]' DEFAULT NULL ON EMPTY) = 'Aguardando dados bancários'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[7]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[8]' DEFAULT NULL ON EMPTY) = 'Aguardando dados bancários'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[8]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[9]' DEFAULT NULL ON EMPTY) = 'Aguardando dados bancários'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[9]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[10]' DEFAULT NULL ON EMPTY) = 'Aguardando dados bancários'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[10]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[11]' DEFAULT NULL ON EMPTY) = 'Aguardando dados bancários'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[11]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[12]' DEFAULT NULL ON EMPTY) = 'Aguardando dados bancários'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[12]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[13]' DEFAULT NULL ON EMPTY) = 'Aguardando dados bancários'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[13]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[14]' DEFAULT NULL ON EMPTY) = 'Aguardando dados bancários'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[14]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[15]' DEFAULT NULL ON EMPTY) = 'Aguardando dados bancários'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[15]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
	        --
	   END AS "Aguardando dados bancários em"
	  --
	  --
	  -- tratamento de 14 item dos matriz, pra identifica data da(s) coluna(s) -> 'Aguardando pagamento manual'  **
	  ,CASE WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[0]' DEFAULT NULL ON EMPTY) = 'Aguardando pagamento manual'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[0]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[1]' DEFAULT NULL ON EMPTY) = 'Aguardando pagamento manual'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[1]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[2]' DEFAULT NULL ON EMPTY) = 'Aguardando pagamento manual'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[2]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[3]' DEFAULT NULL ON EMPTY) = 'Aguardando pagamento manual'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[3]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[4]' DEFAULT NULL ON EMPTY) = 'Aguardando pagamento manual'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[4]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[5]' DEFAULT NULL ON EMPTY) = 'Aguardando pagamento manual'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[5]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[6]' DEFAULT NULL ON EMPTY) = 'Aguardando pagamento manual'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[6]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[7]' DEFAULT NULL ON EMPTY) = 'Aguardando pagamento manual'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[7]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[8]' DEFAULT NULL ON EMPTY) = 'Aguardando pagamento manual'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[8]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[9]' DEFAULT NULL ON EMPTY) = 'Aguardando pagamento manual'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[9]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[10]' DEFAULT NULL ON EMPTY) = 'Aguardando pagamento manual'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[10]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[11]' DEFAULT NULL ON EMPTY) = 'Aguardando pagamento manual'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[11]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[12]' DEFAULT NULL ON EMPTY) = 'Aguardando pagamento manual'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[12]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[13]' DEFAULT NULL ON EMPTY) = 'Aguardando pagamento manual'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[13]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[14]' DEFAULT NULL ON EMPTY) = 'Aguardando pagamento manual'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[14]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[15]' DEFAULT NULL ON EMPTY) = 'Aguardando pagamento manual'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[15]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
	        --
	   END AS "Aguardando pagamento manual em"
	  --
	  --
	  -- tratamento de 14 item dos matriz, pra identifica data da(s) coluna(s) -> 'Em avaliação'  **
	  ,CASE WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[0]' DEFAULT NULL ON EMPTY) = 'Em avaliação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[0]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[1]' DEFAULT NULL ON EMPTY) = 'Em avaliação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[1]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[2]' DEFAULT NULL ON EMPTY) = 'Em avaliação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[2]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[3]' DEFAULT NULL ON EMPTY) = 'Em avaliação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[3]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[4]' DEFAULT NULL ON EMPTY) = 'Em avaliação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[4]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[5]' DEFAULT NULL ON EMPTY) = 'Em avaliação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[5]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[6]' DEFAULT NULL ON EMPTY) = 'Em avaliação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[6]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[7]' DEFAULT NULL ON EMPTY) = 'Em avaliação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[7]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[8]' DEFAULT NULL ON EMPTY) = 'Em avaliação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[8]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[9]' DEFAULT NULL ON EMPTY) = 'Em avaliação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[9]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[10]' DEFAULT NULL ON EMPTY) = 'Em avaliação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[10]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[11]' DEFAULT NULL ON EMPTY) = 'Em avaliação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[11]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[12]' DEFAULT NULL ON EMPTY) = 'Em avaliação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[12]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[13]' DEFAULT NULL ON EMPTY) = 'Em avaliação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[13]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[14]' DEFAULT NULL ON EMPTY) = 'Em avaliação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[14]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[15]' DEFAULT NULL ON EMPTY) = 'Em avaliação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[15]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
	        --
	   END AS "Em avaliação em"
	  --
	  --
	  -- tratamento de 14 item dos matriz, pra identifica data da(s) coluna(s) -> 'Finalizado por abandono'  **
	  ,CASE WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[0]' DEFAULT NULL ON EMPTY) = 'Finalizado por abandono'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[0]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[1]' DEFAULT NULL ON EMPTY) = 'Finalizado por abandono'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[1]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[2]' DEFAULT NULL ON EMPTY) = 'Finalizado por abandono'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[2]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[3]' DEFAULT NULL ON EMPTY) = 'Finalizado por abandono'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[3]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[4]' DEFAULT NULL ON EMPTY) = 'Finalizado por abandono'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[4]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[5]' DEFAULT NULL ON EMPTY) = 'Finalizado por abandono'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[5]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[6]' DEFAULT NULL ON EMPTY) = 'Finalizado por abandono'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[6]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[7]' DEFAULT NULL ON EMPTY) = 'Finalizado por abandono'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[7]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[8]' DEFAULT NULL ON EMPTY) = 'Finalizado por abandono'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[8]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[9]' DEFAULT NULL ON EMPTY) = 'Finalizado por abandono'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[9]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[10]' DEFAULT NULL ON EMPTY) = 'Finalizado por abandono'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[10]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[11]' DEFAULT NULL ON EMPTY) = 'Finalizado por abandono'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[11]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[12]' DEFAULT NULL ON EMPTY) = 'Finalizado por abandono'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[12]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[13]' DEFAULT NULL ON EMPTY) = 'Finalizado por abandono'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[13]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[14]' DEFAULT NULL ON EMPTY) = 'Finalizado por abandono'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[14]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[15]' DEFAULT NULL ON EMPTY) = 'Finalizado por abandono'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[15]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
	        --
	   END AS "Finalizado por abandono em"
	  --
	  --
	  -- tratamento de 14 item dos matriz, pra identifica data da(s) coluna(s) -> 'Pendência Financeira'  **
	  ,CASE WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[0]' DEFAULT NULL ON EMPTY) = 'Pendência Financeira'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[0]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[1]' DEFAULT NULL ON EMPTY) = 'Pendência Financeira'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[1]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[2]' DEFAULT NULL ON EMPTY) = 'Pendência Financeira'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[2]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[3]' DEFAULT NULL ON EMPTY) = 'Pendência Financeira'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[3]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[4]' DEFAULT NULL ON EMPTY) = 'Pendência Financeira'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[4]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[5]' DEFAULT NULL ON EMPTY) = 'Pendência Financeira'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[5]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[6]' DEFAULT NULL ON EMPTY) = 'Pendência Financeira'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[6]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[7]' DEFAULT NULL ON EMPTY) = 'Pendência Financeira'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[7]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[8]' DEFAULT NULL ON EMPTY) = 'Pendência Financeira'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[8]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[9]' DEFAULT NULL ON EMPTY) = 'Pendência Financeira'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[9]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[10]' DEFAULT NULL ON EMPTY) = 'Pendência Financeira'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[10]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[11]' DEFAULT NULL ON EMPTY) = 'Pendência Financeira'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[11]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[12]' DEFAULT NULL ON EMPTY) = 'Pendência Financeira'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[12]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[13]' DEFAULT NULL ON EMPTY) = 'Pendência Financeira'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[13]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[14]' DEFAULT NULL ON EMPTY) = 'Pendência Financeira'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[14]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[15]' DEFAULT NULL ON EMPTY) = 'Pendência Financeira'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[15]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
	        --
	   END AS "Pendência Financeira em"
	  --
	  --
	  -- tratamento de 14 item dos matriz, pra identifica data da(s) coluna(s) -> 'Pendência Fiscal'  **
	  ,CASE WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[0]' DEFAULT NULL ON EMPTY) = 'Pendência Fiscal'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[0]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[1]' DEFAULT NULL ON EMPTY) = 'Pendência Fiscal'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[1]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[2]' DEFAULT NULL ON EMPTY) = 'Pendência Fiscal'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[2]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[3]' DEFAULT NULL ON EMPTY) = 'Pendência Fiscal'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[3]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[4]' DEFAULT NULL ON EMPTY) = 'Pendência Fiscal'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[4]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[5]' DEFAULT NULL ON EMPTY) = 'Pendência Fiscal'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[5]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[6]' DEFAULT NULL ON EMPTY) = 'Pendência Fiscal'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[6]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[7]' DEFAULT NULL ON EMPTY) = 'Pendência Fiscal'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[7]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[8]' DEFAULT NULL ON EMPTY) = 'Pendência Fiscal'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[8]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[9]' DEFAULT NULL ON EMPTY) = 'Pendência Fiscal'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[9]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[10]' DEFAULT NULL ON EMPTY) = 'Pendência Fiscal'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[10]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[11]' DEFAULT NULL ON EMPTY) = 'Pendência Fiscal'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[11]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[12]' DEFAULT NULL ON EMPTY) = 'Pendência Fiscal'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[12]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[13]' DEFAULT NULL ON EMPTY) = 'Pendência Fiscal'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[13]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[14]' DEFAULT NULL ON EMPTY) = 'Pendência Fiscal'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[14]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[15]' DEFAULT NULL ON EMPTY) = 'Pendência Fiscal'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[15]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
	        --
	   END AS "Pendência Fiscal em"
	  --
	  --
	  -- tratamento de 14 item dos matriz, pra identifica data da(s) coluna(s) -> 'Processando'  **
	  ,CASE WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[0]' DEFAULT NULL ON EMPTY) = 'Processando'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[0]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[1]' DEFAULT NULL ON EMPTY) = 'Processando'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[1]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[2]' DEFAULT NULL ON EMPTY) = 'Processando'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[2]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[3]' DEFAULT NULL ON EMPTY) = 'Processando'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[3]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[4]' DEFAULT NULL ON EMPTY) = 'Processando'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[4]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[5]' DEFAULT NULL ON EMPTY) = 'Processando'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[5]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[6]' DEFAULT NULL ON EMPTY) = 'Processando'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[6]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[7]' DEFAULT NULL ON EMPTY) = 'Processando'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[7]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[8]' DEFAULT NULL ON EMPTY) = 'Processando'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[8]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[9]' DEFAULT NULL ON EMPTY) = 'Processando'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[9]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[10]' DEFAULT NULL ON EMPTY) = 'Processando'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[10]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[11]' DEFAULT NULL ON EMPTY) = 'Processando'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[11]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[12]' DEFAULT NULL ON EMPTY) = 'Processando'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[12]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[13]' DEFAULT NULL ON EMPTY) = 'Processando'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[13]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[14]' DEFAULT NULL ON EMPTY) = 'Processando'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[14]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[15]' DEFAULT NULL ON EMPTY) = 'Processando'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[15]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
	        --
	   END AS "Processando em"
	  --
	  --
	  -- tratamento de 14 item dos matriz, pra identifica data da(s) coluna(s) -> 'Processando aprovação'  **
	  ,CASE WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[0]' DEFAULT NULL ON EMPTY) = 'Processando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[0]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[1]' DEFAULT NULL ON EMPTY) = 'Processando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[1]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[2]' DEFAULT NULL ON EMPTY) = 'Processando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[2]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[3]' DEFAULT NULL ON EMPTY) = 'Processando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[3]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[4]' DEFAULT NULL ON EMPTY) = 'Processando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[4]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[5]' DEFAULT NULL ON EMPTY) = 'Processando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[5]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[6]' DEFAULT NULL ON EMPTY) = 'Processando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[6]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[7]' DEFAULT NULL ON EMPTY) = 'Processando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[7]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[8]' DEFAULT NULL ON EMPTY) = 'Processando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[8]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[9]' DEFAULT NULL ON EMPTY) = 'Processando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[9]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[10]' DEFAULT NULL ON EMPTY) = 'Processando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[10]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[11]' DEFAULT NULL ON EMPTY) = 'Processando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[11]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[12]' DEFAULT NULL ON EMPTY) = 'Processando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[12]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[13]' DEFAULT NULL ON EMPTY) = 'Processando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[13]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[14]' DEFAULT NULL ON EMPTY) = 'Processando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[14]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			--   
	        WHEN 1=1
	         AND JSON_VALUE(D.STATUS_HISTORIES_STATUS_DESCRIPTION, '$[15]' DEFAULT NULL ON EMPTY) = 'Processando aprovação'
	        THEN ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.STATUS_HISTORIES_DATE, '$[15]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
	        --
	   END AS "Processando aprovação em"
	  --    
	  --
	  -- ATÉ 9 historicos de tipos de pagamentos CONCACTENADOS
	  ,CASE   WHEN JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[0]' DEFAULT NULL ON EMPTY) IS NOT NULL
	          THEN
				     COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[0]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[1]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[1]' DEFAULT NULL ON EMPTY),'') 
	                IN (COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[1]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[2]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[2]' DEFAULT NULL ON EMPTY),'') 
	                IN (COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[1]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[2]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[3]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[3]' DEFAULT NULL ON EMPTY),'') 
	                IN (COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[1]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[2]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[3]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[4]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[4]' DEFAULT NULL ON EMPTY),'') 
	                IN (COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[1]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[2]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[3]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[4]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[5]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[5]' DEFAULT NULL ON EMPTY),'') 
	                IN (COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[1]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[2]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[3]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[4]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[5]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[6]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[6]' DEFAULT NULL ON EMPTY),'') 
	                IN (COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[1]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[2]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[3]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[4]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[5]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[6]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[7]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[7]' DEFAULT NULL ON EMPTY),'') 
	                IN (COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[1]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[2]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[3]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[4]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[5]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[6]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[7]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[8]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[8]' DEFAULT NULL ON EMPTY),'') 
	                IN (COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[1]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[2]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[3]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[4]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[5]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[6]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[7]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.STATUS_HISTORIES_COMMENTS, '$[8]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	     AS "Tipos Pagamentos"
	  --
	  --
	  ,JSON_VALUE(D.ORDER_TRANSACTIONS_ACQUIRER, '$[0]' DEFAULT NULL ON EMPTY)  							AS "Adquirente Transação"
	  ,JSON_VALUE(D.ORDER_TRANSACTIONS_NSU     , '$[0]' DEFAULT NULL ON EMPTY)  							AS "NSU Transação"
	  ,JSON_VALUE(D.ORDER_TRANSACTIONS_TID     , '$[0]' DEFAULT NULL ON EMPTY)  							AS "TID Transação"
	  ,TO_DECIMAL( JSON_VALUE(D.ORDER_TRANSACTIONS_TOTAL_AMOUNT,'$[0]' DEFAULT NULL ON EMPTY), 20, 2)       AS "Valor Total Transação"
	  ,ADD_SECONDS(TO_TIMESTAMP(JSON_VALUE(D.ORDER_TRANSACTIONS_DATE, '$[0]' DEFAULT NULL ON EMPTY)), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
	    AS "Data Transação"
	  -- -------------------------------
	  -- -------------------------------
	  -- -------------------------------
	  --
	  --,'>>><<<'																								AS "ST"
	  -- -------------------------------
	  -- -------------------------------
	  -- -------------------------------
	  --
	  ,D.SHIPPING_METHOD																					AS "Método Entrega"
	  ,TO_DECIMAL( D.ADDED_TAXES_AMOUNT, 20, 2 )															AS "Impostos Adicionados"
	  --
	  ,D.CUSTOMER_ID																						AS "Id Cliente"
	  ,D.STATUS_ID 																							AS "Id Status Reembolso"
	  --
	  --
	  /*
	  ,JSON_VALUE(D.SELLERS_IS_STORE_REGISTERED, '$[0]' DEFAULT NULL ON EMPTY)  AS "Sellers Loja Registrada?"
	  --
	  ,CASE WHEN JSON_VALUE(D.SELLERS_MESSAGE, '$[0]' DEFAULT NULL ON EMPTY) 	IS NOT NULL
	  		THEN JSON_VALUE(D.SELLERS_MESSAGE, '$[0]' DEFAULT NULL ON EMPTY)
	  		--
	  		WHEN JSON_VALUE(D.SELLERS_MESSAGE, '$[1]' DEFAULT NULL ON EMPTY) 	IS NOT NULL
	  		THEN JSON_VALUE(D.SELLERS_MESSAGE, '$[1]' DEFAULT NULL ON EMPTY)
	  		--
	  		WHEN JSON_VALUE(D.SELLERS_MESSAGE, '$[2]' DEFAULT NULL ON EMPTY) 	IS NOT NULL
	  		THEN JSON_VALUE(D.SELLERS_MESSAGE, '$[2]' DEFAULT NULL ON EMPTY)
	  		--
	  		WHEN JSON_VALUE(D.SELLERS_MESSAGE, '$[3]' DEFAULT NULL ON EMPTY) 	IS NOT NULL
	  		THEN JSON_VALUE(D.SELLERS_MESSAGE, '$[3]' DEFAULT NULL ON EMPTY)
	  		--
	  		WHEN JSON_VALUE(D.SELLERS_MESSAGE, '$[4]' DEFAULT NULL ON EMPTY) 	IS NOT NULL
	  		THEN JSON_VALUE(D.SELLERS_MESSAGE, '$[4]' DEFAULT NULL ON EMPTY)
	  		--
	    END AS "Sellers mensagens"
	   ,D.SELLER_INFO 															AS "Seller informações"
	  */
	  --
	  -- 
	  ,JSON_VALUE(D.ORDER_TRANSACTIONS_ID, '$[0]' DEFAULT NULL ON EMPTY)        							AS "Id Transações Pedido"
	  ,JSON_VALUE(D.ORDER_TRANSACTIONS_ECOMMERCE_ORDER_ID, '$[0]' DEFAULT NULL ON EMPTY)        			AS "Id Transações Ecommerce"
	  ,JSON_VALUE(D.ORDER_TRANSACTIONS_TRANSACTION_ID, '$[0]' DEFAULT NULL ON EMPTY)            			AS "Id Transações Adquirente"
	  --
	  --
	  ,D.REVERSE_REVERSE_TYPE 																				AS "Tipo Reversa" 
	  ,ADD_SECONDS(TO_TIMESTAMP(D.REVERSE_CREATED_AT), -(3 * 60 * 60) ) -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
	       AS "Data Criação Reversa"
	  --
	  --
	  ,D.REVERSE_ECOMMERCEORDER_OPTIONS_ORDER_SEQUENCE_NUMBER												AS "Sequence"
	  ,D.REVERSE_ECOMMERCEORDER_OPTIONS_WAREHOUSE_NUMBER_ID													AS "ID WAREHOUSE"
	  --
	  ,CASE WHEN D.REVERSE_ECOMMERCEORDER_OPTIONS_PAID_WITH_VOUCHER = 'false' THEN 'Não'
	        WHEN D.REVERSE_ECOMMERCEORDER_OPTIONS_PAID_WITH_VOUCHER = 'true'  THEN 'Sim'
	        END AS	"PAID_WITH_VOUCHER"
	  --
	  /* 
	  -- ATÉ 4 GIFTCARDS_NAME  CONCACTENADOS
	  ,CASE   WHEN JSON_VALUE(D.REVERSE_ECOMMERCEORDER_OPTIONS_GIFTCARDS_NAME, '$[0]' DEFAULT NULL ON EMPTY) IS NOT NULL
	          THEN
				     JSON_VALUE(D.REVERSE_ECOMMERCEORDER_OPTIONS_GIFTCARDS_NAME, '$[0]' DEFAULT NULL ON EMPTY)
				     || '; ' 
			  END
		 ||
	     CASE WHEN JSON_VALUE(D.REVERSE_ECOMMERCEORDER_OPTIONS_GIFTCARDS_NAME, '$[1]' DEFAULT NULL ON EMPTY) IS NOT NULL
	          THEN
				     JSON_VALUE(D.REVERSE_ECOMMERCEORDER_OPTIONS_GIFTCARDS_NAME, '$[1]' DEFAULT NULL ON EMPTY)
				     || '; ' 
			  END
		 ||
	     CASE WHEN JSON_VALUE(D.REVERSE_ECOMMERCEORDER_OPTIONS_GIFTCARDS_NAME, '$[2]' DEFAULT NULL ON EMPTY) IS NOT NULL
	          THEN
				     JSON_VALUE(D.REVERSE_ECOMMERCEORDER_OPTIONS_GIFTCARDS_NAME, '$[2]' DEFAULT NULL ON EMPTY)
				     || '; ' 
			  END
		 ||
	     CASE WHEN JSON_VALUE(D.REVERSE_ECOMMERCEORDER_OPTIONS_GIFTCARDS_NAME, '$[3]' DEFAULT NULL ON EMPTY) IS NOT NULL
	          THEN
				     JSON_VALUE(D.REVERSE_ECOMMERCEORDER_OPTIONS_GIFTCARDS_NAME, '$[3]' DEFAULT NULL ON EMPTY)
				     || '; ' 
			  END
	      AS  "Nome Vale Presente Opções Pedido"
	  */
	  --
	  --
	  ,CASE   WHEN JSON_VALUE(D.REVERSE_ECOMMERCEORDER_OPTIONS_INVOICES, '$[0].number' DEFAULT NULL ON EMPTY) IS NOT NULL
	          THEN
				     JSON_VALUE(D.REVERSE_ECOMMERCEORDER_OPTIONS_INVOICES, '$[0].number' DEFAULT NULL ON EMPTY)
			  END
	      AS  "Número Fatura"
	  --
	  ,CASE   WHEN JSON_VALUE(D.REVERSE_ECOMMERCEORDER_OPTIONS_INVOICES, '$[0].nfe' DEFAULT NULL ON EMPTY) IS NOT NULL
	          THEN
				     JSON_VALUE(D.REVERSE_ECOMMERCEORDER_OPTIONS_INVOICES, '$[0].nfe' DEFAULT NULL ON EMPTY)
			  END
	      AS  "NFe Fatura"
	  --
	  /*
	  ,D.REVERSE_ECOMMERCEORDER_OPTIONS_PROFILE_CUSTOMER_ID									AS "Código Perfil Cliente"
	  */
	  --
	  --
	  -- ATÉ 5 MOTIVOS CONCACTENADOS
	  ,CASE   WHEN JSON_VALUE(D.PRODUCTS_REASON_DESCRIPTION, '$[0]' DEFAULT NULL ON EMPTY) IS NOT NULL
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_REASON_DESCRIPTION, '$[0]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.PRODUCTS_REASON_DESCRIPTION, '$[1]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.PRODUCTS_REASON_DESCRIPTION, '$[1]' DEFAULT NULL ON EMPTY),'')
	                IN (COALESCE(JSON_VALUE(D.PRODUCTS_REASON_DESCRIPTION, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_REASON_DESCRIPTION, '$[1]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.PRODUCTS_REASON_DESCRIPTION, '$[2]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.PRODUCTS_REASON_DESCRIPTION, '$[2]' DEFAULT NULL ON EMPTY),'')
	                IN (COALESCE(JSON_VALUE(D.PRODUCTS_REASON_DESCRIPTION, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_REASON_DESCRIPTION, '$[1]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_REASON_DESCRIPTION, '$[2]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.PRODUCTS_REASON_DESCRIPTION, '$[3]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.PRODUCTS_REASON_DESCRIPTION, '$[3]' DEFAULT NULL ON EMPTY),'')
	                IN (COALESCE(JSON_VALUE(D.PRODUCTS_REASON_DESCRIPTION, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_REASON_DESCRIPTION, '$[1]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_REASON_DESCRIPTION, '$[2]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_REASON_DESCRIPTION, '$[3]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.PRODUCTS_REASON_DESCRIPTION, '$[4]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.PRODUCTS_REASON_DESCRIPTION, '$[4]' DEFAULT NULL ON EMPTY),'')
	                IN (COALESCE(JSON_VALUE(D.PRODUCTS_REASON_DESCRIPTION, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_REASON_DESCRIPTION, '$[1]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_REASON_DESCRIPTION, '$[2]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_REASON_DESCRIPTION, '$[3]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_REASON_DESCRIPTION, '$[4]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	      AS  "Motivos devolução/cancelamento"
	  --
	  -- ATÉ 5 SUBMOTIVOS CONCACTENADOS
	  ,CASE   WHEN JSON_VALUE(D.PRODUCTS_SUBREASON_DESCRIPTION, '$[0]' DEFAULT NULL ON EMPTY) IS NOT NULL
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_SUBREASON_DESCRIPTION, '$[0]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.PRODUCTS_SUBREASON_DESCRIPTION, '$[1]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.PRODUCTS_SUBREASON_DESCRIPTION, '$[1]' DEFAULT NULL ON EMPTY) ,'')
	                IN (COALESCE(JSON_VALUE(D.PRODUCTS_SUBREASON_DESCRIPTION, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_SUBREASON_DESCRIPTION, '$[1]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.PRODUCTS_SUBREASON_DESCRIPTION, '$[2]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.PRODUCTS_SUBREASON_DESCRIPTION, '$[2]' DEFAULT NULL ON EMPTY) ,'')
	                IN (COALESCE(JSON_VALUE(D.PRODUCTS_SUBREASON_DESCRIPTION, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_SUBREASON_DESCRIPTION, '$[1]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_SUBREASON_DESCRIPTION, '$[2]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.PRODUCTS_SUBREASON_DESCRIPTION, '$[3]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.PRODUCTS_SUBREASON_DESCRIPTION, '$[3]' DEFAULT NULL ON EMPTY) ,'')
	                IN (COALESCE(JSON_VALUE(D.PRODUCTS_SUBREASON_DESCRIPTION, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_SUBREASON_DESCRIPTION, '$[1]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_SUBREASON_DESCRIPTION, '$[2]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_SUBREASON_DESCRIPTION, '$[3]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.PRODUCTS_SUBREASON_DESCRIPTION, '$[4]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.PRODUCTS_SUBREASON_DESCRIPTION, '$[4]' DEFAULT NULL ON EMPTY) ,'')
	                IN (COALESCE(JSON_VALUE(D.PRODUCTS_SUBREASON_DESCRIPTION, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_SUBREASON_DESCRIPTION, '$[1]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_SUBREASON_DESCRIPTION, '$[2]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_SUBREASON_DESCRIPTION, '$[3]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_SUBREASON_DESCRIPTION, '$[4]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	      AS  "SubMotivos devolução/cancelamento"
	  --
	  --
	  -- ATÉ 5 COMENTARIOS CONCACTENADOS
	  ,CASE   WHEN JSON_VALUE(CAST(D.PRODUCTS_COMMENTS AS VARCHAR), '$[0]' DEFAULT NULL ON EMPTY) IS NOT NULL
	            OR JSON_VALUE(CAST(D.PRODUCTS_COMMENTS AS VARCHAR), '$[0]' DEFAULT NULL ON EMPTY) <> ''
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_COMMENTS, '$[0]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.PRODUCTS_COMMENTS, '$[1]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.PRODUCTS_COMMENTS, '$[1]' DEFAULT NULL ON EMPTY),'') 
	                IN (COALESCE(JSON_VALUE(D.PRODUCTS_COMMENTS, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_COMMENTS, '$[1]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.PRODUCTS_COMMENTS, '$[2]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.PRODUCTS_COMMENTS, '$[2]' DEFAULT NULL ON EMPTY),'') 
	                IN (COALESCE(JSON_VALUE(D.PRODUCTS_COMMENTS, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_COMMENTS, '$[1]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_COMMENTS, '$[2]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.PRODUCTS_COMMENTS, '$[3]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.PRODUCTS_COMMENTS, '$[3]' DEFAULT NULL ON EMPTY),'') 
	                IN (COALESCE(JSON_VALUE(D.PRODUCTS_COMMENTS, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_COMMENTS, '$[1]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_COMMENTS, '$[2]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_COMMENTS, '$[3]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.PRODUCTS_COMMENTS, '$[4]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.PRODUCTS_COMMENTS, '$[4]' DEFAULT NULL ON EMPTY),'') 
	                IN (COALESCE(JSON_VALUE(D.PRODUCTS_COMMENTS, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_COMMENTS, '$[1]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_COMMENTS, '$[2]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_COMMENTS, '$[3]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_COMMENTS, '$[4]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	      AS "Comentários Produtos"
	  --
	  --,CAST(D.PRODUCTS_COMMENTS AS VARCHAR) AS cc1
	  --,COALESCE(JSON_VALUE(D.PRODUCTS_COMMENTS, '$[0]' DEFAULT NULL ON EMPTY),'') AS cc2 
	  --,COALESCE(JSON_VALUE(CAST(D.PRODUCTS_COMMENTS AS VARCHAR), '$[0]' DEFAULT NULL ON EMPTY),'') AS cc3 
	  --
	  --
	  -- ATÉ 5 SKU´s PRODUTOS CONCACTENADOS
	  ,CASE   WHEN JSON_VALUE(D.PRODUCTS_OPTIONS_REF_ID, '$[0]' DEFAULT NULL ON EMPTY) IS NOT NULL
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_REF_ID, '$[0]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.PRODUCTS_OPTIONS_REF_ID, '$[1]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_REF_ID, '$[1]' DEFAULT NULL ON EMPTY),'') 
	                IN (COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_REF_ID, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_REF_ID, '$[1]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.PRODUCTS_OPTIONS_REF_ID, '$[2]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_REF_ID, '$[2]' DEFAULT NULL ON EMPTY),'') 
	                IN (COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_REF_ID, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_REF_ID, '$[1]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_REF_ID, '$[2]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.PRODUCTS_OPTIONS_REF_ID, '$[3]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_REF_ID, '$[3]' DEFAULT NULL ON EMPTY),'') 
	                IN (COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_REF_ID, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_REF_ID, '$[1]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_REF_ID, '$[2]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_REF_ID, '$[3]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.PRODUCTS_OPTIONS_REF_ID, '$[4]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_REF_ID, '$[4]' DEFAULT NULL ON EMPTY),'') 
	                IN (COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_REF_ID, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_REF_ID, '$[1]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_REF_ID, '$[2]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_REF_ID, '$[3]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_REF_ID, '$[4]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	      AS "SKUs Produto(s)"
	  --
	  --
	  -- ATÉ 5 NOMES PRODUTOS CONCACTENADOS
	  ,CASE   WHEN JSON_VALUE(D.PRODUCTS_NAME, '$[0]' DEFAULT NULL ON EMPTY) IS NOT NULL
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_NAME, '$[0]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.PRODUCTS_NAME, '$[1]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  JSON_VALUE(D.PRODUCTS_NAME, '$[1]' DEFAULT NULL ON EMPTY) 
	                IN (JSON_VALUE(D.PRODUCTS_NAME, '$[0]' DEFAULT NULL ON EMPTY)
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_NAME, '$[1]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.PRODUCTS_NAME, '$[2]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  JSON_VALUE(D.PRODUCTS_NAME, '$[2]' DEFAULT NULL ON EMPTY) 
	                IN (JSON_VALUE(D.PRODUCTS_NAME, '$[0]' DEFAULT NULL ON EMPTY)
	                   ,JSON_VALUE(D.PRODUCTS_NAME, '$[1]' DEFAULT NULL ON EMPTY)
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_NAME, '$[2]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.PRODUCTS_NAME, '$[3]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  JSON_VALUE(D.PRODUCTS_NAME, '$[3]' DEFAULT NULL ON EMPTY) 
	                IN (JSON_VALUE(D.PRODUCTS_NAME, '$[0]' DEFAULT NULL ON EMPTY)
	                   ,JSON_VALUE(D.PRODUCTS_NAME, '$[1]' DEFAULT NULL ON EMPTY)
	                   ,JSON_VALUE(D.PRODUCTS_NAME, '$[2]' DEFAULT NULL ON EMPTY)
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_NAME, '$[3]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.PRODUCTS_NAME, '$[4]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  JSON_VALUE(D.PRODUCTS_NAME, '$[4]' DEFAULT NULL ON EMPTY) 
	                IN (JSON_VALUE(D.PRODUCTS_NAME, '$[0]' DEFAULT NULL ON EMPTY)
	                   ,JSON_VALUE(D.PRODUCTS_NAME, '$[1]' DEFAULT NULL ON EMPTY)
	                   ,JSON_VALUE(D.PRODUCTS_NAME, '$[2]' DEFAULT NULL ON EMPTY)
	                   ,JSON_VALUE(D.PRODUCTS_NAME, '$[3]' DEFAULT NULL ON EMPTY)
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_NAME, '$[4]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	      AS "Nome Produto(s)"
	  --
	  --
	  -- ATÉ 5 CÓDIGOS EAN PRODUTOS CONCACTENADOS
	  ,CASE   WHEN JSON_VALUE(D.PRODUCTS_OPTIONS_EAN, '$[0]' DEFAULT NULL ON EMPTY) IS NOT NULL
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_EAN, '$[0]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.PRODUCTS_OPTIONS_EAN, '$[1]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_EAN, '$[1]' DEFAULT NULL ON EMPTY),'') 
	                IN (COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_EAN, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_EAN, '$[1]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.PRODUCTS_OPTIONS_EAN, '$[2]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_EAN, '$[2]' DEFAULT NULL ON EMPTY),'') 
	                IN (COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_EAN, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_EAN, '$[1]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_EAN, '$[2]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.PRODUCTS_OPTIONS_EAN, '$[3]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_EAN, '$[3]' DEFAULT NULL ON EMPTY),'') 
	                IN (COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_EAN, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_EAN, '$[1]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_EAN, '$[2]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_EAN, '$[3]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	   ||
	   CASE   WHEN JSON_VALUE(D.PRODUCTS_OPTIONS_EAN, '$[4]' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND NOT  COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_EAN, '$[4]' DEFAULT NULL ON EMPTY),'') 
	                IN (COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_EAN, '$[0]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_EAN, '$[1]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_EAN, '$[2]' DEFAULT NULL ON EMPTY),'')
	                   ,COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_EAN, '$[3]' DEFAULT NULL ON EMPTY),'')
	                   )
	          THEN
				     COALESCE(JSON_VALUE(D.PRODUCTS_OPTIONS_EAN, '$[4]' DEFAULT NULL ON EMPTY),'')
				     || '; ' 
			  ELSE ''
			  END
	     AS "Códigos EAN (European Article Number)"
	  --
	  --
	  /*
	  ,JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[0].message' DEFAULT NULL ON EMPTY)  AS msg1
	  ,JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[1].message' DEFAULT NULL ON EMPTY)  AS msg2
	  ,JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[2].message' DEFAULT NULL ON EMPTY)  AS msg3
	  ,JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[3].message' DEFAULT NULL ON EMPTY)  AS msg4
	  ,JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[4].message' DEFAULT NULL ON EMPTY)  AS msg5
	  ,JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[5].message' DEFAULT NULL ON EMPTY)  AS msg6
	  ,JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[6].message' DEFAULT NULL ON EMPTY)  AS msg7
	  ,JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[7].message' DEFAULT NULL ON EMPTY)  AS msg8
	  ,JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[8].message' DEFAULT NULL ON EMPTY)  AS msg9
	  */
	  --
	  -- ATÉ 9 MSGS: RDO
	  ,CASE   WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[0].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[0].message' DEFAULT NULL ON EMPTY), 'RDO:') > 0   -- 'ERRO:'
	          THEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[0].message' DEFAULT NULL ON EMPTY)
				         || '; '
			  --
			  WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[1].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[1].message' DEFAULT NULL ON EMPTY), 'RDO:') > 0   -- 'ERRO:'
	          THEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[1].message' DEFAULT NULL ON EMPTY)
				         || '; '
			  --
			  WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[2].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[2].message' DEFAULT NULL ON EMPTY), 'RDO:') > 0   -- 'ERRO:'
	          THEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[2].message' DEFAULT NULL ON EMPTY)
				         || '; '
			  --
			  WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[3].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[3].message' DEFAULT NULL ON EMPTY), 'RDO:') > 0   -- 'ERRO:'
	          THEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[3].message' DEFAULT NULL ON EMPTY)
				         || '; '
			  --
			  WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[4].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[4].message' DEFAULT NULL ON EMPTY), 'RDO:') > 0   -- 'ERRO:'
	          THEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[4].message' DEFAULT NULL ON EMPTY)
				         || '; '
			  --
			  WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[5].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[5].message' DEFAULT NULL ON EMPTY), 'RDO:') > 0   -- 'ERRO:'
	          THEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[5].message' DEFAULT NULL ON EMPTY)
				         || '; '
			  --
			  WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[6].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[6].message' DEFAULT NULL ON EMPTY), 'RDO:') > 0   -- 'ERRO:'
	          THEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[6].message' DEFAULT NULL ON EMPTY)
				         || '; '
			  --
			  WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[7].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[7].message' DEFAULT NULL ON EMPTY), 'RDO:') > 0   -- 'ERRO:'
	          THEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[7].message' DEFAULT NULL ON EMPTY)
				         || '; '
			  --
			  WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[8].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[8].message' DEFAULT NULL ON EMPTY), 'RDO:') > 0   -- 'ERRO:'
	          THEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[8].message' DEFAULT NULL ON EMPTY)
				         || '; '
			  --
			  WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[9].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[9].message' DEFAULT NULL ON EMPTY), 'RDO:') > 0   -- 'ERRO:'
	          THEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[9].message' DEFAULT NULL ON EMPTY)
				         || '; '
			  --
			  ELSE ''
			  END AS "Mensagens RDO AferSales"
	  --
	  --
	  -- ATÉ 9 MSGS: ERRO
	  ,CASE   WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[0].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[0].message' DEFAULT NULL ON EMPTY), 'ERRO:') > 0   -- 'ERRO:'
	          THEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[0].message' DEFAULT NULL ON EMPTY)
				         || '; '
			  --
			  WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[1].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[1].message' DEFAULT NULL ON EMPTY), 'ERRO:') > 0   -- 'ERRO:'
	          THEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[1].message' DEFAULT NULL ON EMPTY)
				         || '; '
			  --
			  WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[2].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[2].message' DEFAULT NULL ON EMPTY), 'ERRO:') > 0   -- 'ERRO:'
	          THEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[2].message' DEFAULT NULL ON EMPTY)
				         || '; '
			  --
			  WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[3].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[3].message' DEFAULT NULL ON EMPTY), 'ERRO:') > 0   -- 'ERRO:'
	          THEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[3].message' DEFAULT NULL ON EMPTY)
				         || '; '
			  --
			  WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[4].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[4].message' DEFAULT NULL ON EMPTY), 'ERRO:') > 0   -- 'ERRO:'
	          THEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[4].message' DEFAULT NULL ON EMPTY)
				         || '; '
			  --
			  WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[5].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[5].message' DEFAULT NULL ON EMPTY), 'ERRO:') > 0   -- 'ERRO:'
	          THEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[5].message' DEFAULT NULL ON EMPTY)
				         || '; '
			  --
			  WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[6].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[6].message' DEFAULT NULL ON EMPTY), 'ERRO:') > 0   -- 'ERRO:'
	          THEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[6].message' DEFAULT NULL ON EMPTY)
				         || '; '
			  --
			  WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[7].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[7].message' DEFAULT NULL ON EMPTY), 'ERRO:') > 0   -- 'ERRO:'
	          THEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[7].message' DEFAULT NULL ON EMPTY)
				         || '; '
			  --
			  WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[8].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[8].message' DEFAULT NULL ON EMPTY), 'ERRO:') > 0   -- 'ERRO:'
	          THEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[8].message' DEFAULT NULL ON EMPTY)
				         || '; '
			  --
			  WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[9].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[9].message' DEFAULT NULL ON EMPTY), 'ERRO:') > 0   -- 'ERRO:'
	          THEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[9].message' DEFAULT NULL ON EMPTY)
				         || '; '
			  --
			  ELSE ''
			  END AS "Mensagens ERRO AferSales"
	  --
	  --
	  -- ATÉ 9 MSGS: <> ERRO, RDO
	  ,CASE   WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[0].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND(INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[0].message' DEFAULT NULL ON EMPTY), 'ERRO:') 
	             + INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[0].message' DEFAULT NULL ON EMPTY), 'RDO:' ) 
	             ) = 0   -- <> 'ERRO:', 'RDO:'
	          THEN       COALESCE(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[0].message' DEFAULT NULL ON EMPTY), '')
				         || '; '
			  --
			  ELSE ''
			  --
			  END
	   ||
	   CASE   WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[1].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND(INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[1].message' DEFAULT NULL ON EMPTY), 'ERRO:') 
	             + INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[1].message' DEFAULT NULL ON EMPTY), 'RDO:' ) 
	             ) = 0   -- <> 'ERRO:', 'RDO:'
	          THEN       COALESCE(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[1].message' DEFAULT NULL ON EMPTY), '')
				         || '; '
			  --
			  ELSE ''
			  END
	   ||
	   CASE   WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[2].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND(INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[2].message' DEFAULT NULL ON EMPTY), 'ERRO:') 
	             + INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[2].message' DEFAULT NULL ON EMPTY), 'RDO:' ) 
	             ) = 0   -- <> 'ERRO:', 'RDO:'
	          THEN       COALESCE(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[2].message' DEFAULT NULL ON EMPTY), '')
				         || '; '
			  --
			  ELSE ''
			  END
	   ||
	   CASE   WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[3].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND(INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[3].message' DEFAULT NULL ON EMPTY), 'ERRO:') 
	             + INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[3].message' DEFAULT NULL ON EMPTY), 'RDO:' ) 
	             ) = 0   -- <> 'ERRO:', 'RDO:'
	          THEN       COALESCE(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[3].message' DEFAULT NULL ON EMPTY), '')
				         || '; '
			  --
			  ELSE ''
			  END
	   ||
	   CASE   WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[4].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND(INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[4].message' DEFAULT NULL ON EMPTY), 'ERRO:') 
	             + INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[4].message' DEFAULT NULL ON EMPTY), 'RDO:' ) 
	             ) = 0   -- <> 'ERRO:', 'RDO:'
	          THEN       COALESCE(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[4].message' DEFAULT NULL ON EMPTY), '')
				         || '; '
			  --
			  ELSE ''
			  END
	   ||
	   CASE   WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[5].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND(INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[5].message' DEFAULT NULL ON EMPTY), 'ERRO:') 
	             + INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[5].message' DEFAULT NULL ON EMPTY), 'RDO:' ) 
	             ) = 0   -- <> 'ERRO:', 'RDO:'
	          THEN       COALESCE(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[5].message' DEFAULT NULL ON EMPTY), '')
				         || '; '
			  --
			  ELSE ''
			  END
	   ||
	   CASE   WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[6].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND(INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[6].message' DEFAULT NULL ON EMPTY), 'ERRO:') 
	             + INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[6].message' DEFAULT NULL ON EMPTY), 'RDO:' ) 
	             ) = 0   -- <> 'ERRO:', 'RDO:'
	          THEN       COALESCE(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[6].message' DEFAULT NULL ON EMPTY), '')
				         || '; '
			  --
			  ELSE ''
			  END
	   ||
	   CASE   WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[7].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND(INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[7].message' DEFAULT NULL ON EMPTY), 'ERRO:') 
	             + INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[7].message' DEFAULT NULL ON EMPTY), 'RDO:' ) 
	             ) = 0   -- <> 'ERRO:', 'RDO:'
	          THEN       COALESCE(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[7].message' DEFAULT NULL ON EMPTY), '')
				         || '; '
			  --
			  ELSE ''
			  END
	   ||
	   CASE   WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[8].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND(INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[8].message' DEFAULT NULL ON EMPTY), 'ERRO:') 
	             + INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[8].message' DEFAULT NULL ON EMPTY), 'RDO:' ) 
	             ) = 0   -- <> 'ERRO:', 'RDO:'
	          THEN       COALESCE(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[8].message' DEFAULT NULL ON EMPTY), '')
				         || '; '
			  --
			  ELSE ''
			  END
	   ||
	   CASE   WHEN       JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[9].message' DEFAULT NULL ON EMPTY) IS NOT NULL
	           AND(INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[9].message' DEFAULT NULL ON EMPTY), 'ERRO:') 
	             + INSTR(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[9].message' DEFAULT NULL ON EMPTY), 'RDO:' ) 
	             ) = 0   -- <> 'ERRO:', 'RDO:'
	          THEN       COALESCE(JSON_VALUE(D.ADMINISTRATIVE_RECORDS, '$[9].message' DEFAULT NULL ON EMPTY), '')
				         || '; '
			  --
			  ELSE ''
			  END AS "Outras Mensagens AferSales"
	  --
	  --
	  --,'<<>>',D.*
--FROM 		OW_LAO.ODS_AFTER_SALES_REFUND_DETAIL	AS D -- INSTANCES: samsungbrshop
--LEFT JOIN   OW_LAO.ODS_AFTER_SALES_REFUND			AS A -- INSTANCES: samsungbrshop
--
FROM 		OW_LAO.ODS_AFTER_SALES_REFUND_DETAIL_BRB2B		AS D -- INSTANCES: samsungbrb2b
LEFT JOIN   OW_LAO.ODS_AFTER_SALES_REFUND_BRB2B				AS A -- INSTANCES: samsungbrb2b
--
--FROM 		OW_LAO.ODS_AFTER_SALES_REFUND_DETAIL_BREA	AS D -- INSTANCES: samsungbrea
--LEFT JOIN   OW_LAO.ODS_AFTER_SALES_REFUND_BREA			AS A -- INSTANCES: samsungbrea
--
--FROM 		OW_LAO.ODS_AFTER_SALES_REFUND_DETAIL_BRSHOPMKTPL	AS D -- INSTANCES: samsungbrshopmktpl
--LEFT JOIN   OW_LAO.ODS_AFTER_SALES_REFUND_BRSHOPMKTPL			AS A -- INSTANCES: samsungbrshopmktpl
--
--FROM 		OW_LAO.ODS_AFTER_SALES_REFUND_DETAIL_EPP2	AS D -- INSTANCES: samsungbrepp2
--LEFT JOIN   OW_LAO.ODS_AFTER_SALES_REFUND_EPP2			AS A -- INSTANCES: samsungbrepp2
--
--FROM 		OW_LAO.ODS_AFTER_SALES_REFUND_DETAIL_EST	AS D -- INSTANCES: samsungbrepp2estudantes
--LEFT JOIN   OW_LAO.ODS_AFTER_SALES_REFUND_EST			AS A -- INSTANCES: samsungbrepp2estudantes
--
--FROM 		OW_LAO.ODS_AFTER_SALES_REFUND_DETAIL_MEMBERS	AS D -- INSTANCES: samsungbrepp2members
--LEFT JOIN   OW_LAO.ODS_AFTER_SALES_REFUND_MEMBERS			AS A -- INSTANCES: samsungbrepp2members
--
--FROM 		OW_LAO.ODS_AFTER_SALES_REFUND_DETAIL_PARC	AS D -- INSTANCES: samsungbrepp2parcerias
--LEFT JOIN   OW_LAO.ODS_AFTER_SALES_REFUND_PARC			AS A -- INSTANCES: samsungbrepp2parcerias
--
--FROM 		OW_LAO.ODS_AFTER_SALES_REFUND_DETAIL_RESID	AS D -- INSTANCES: samsungbrepp2residencial
--LEFT JOIN   OW_LAO.ODS_AFTER_SALES_REFUND_RESID			AS A -- INSTANCES: samsungbrepp2residencial
--
       ON   A.ID_DATA = D.ID_DETAIL 
--
 CROSS JOIN ( SELECT --
                     --'BRSHOP'  			 AS INSTANCES -- 1
                     'BRB2B'   	 	     AS INSTANCES -- 2
                     --'BREA'  			 AS INSTANCES -- 3
                     --'BRSHOPMKTPL'  	 AS INSTANCES -- 4
                     --'BREPP2'  		 AS INSTANCES -- 5
                     --'EPP2ESTUDANTES'  AS INSTANCES -- 6
                     --'EPP2MEMBERS'  	 AS INSTANCES -- 7
                     --'EPP2PARCERIAS'   AS INSTANCES -- 8
                     --'EPP2RESIDENCIAL' AS INSTANCES -- 9
                FROM DUMMY
           ) T_INST
--
LEFT JOIN OW_MD.DIM_CALENDAR  AS CL 
       ON CL.YYYYMMDD
		= TO_DATE( 
			      -- BRAZIL_DATETIME -- Subtraindo 3 horas (3 * 60 * 60 = 10800 segundos)
			      ADD_SECONDS(TO_TIMESTAMP(GREATEST(A.CREATED_AT, A.UPDATED_AT)), -(3 * 60 * 60) ) 
		         ) -- "DATE_REF"
--
WHERE 1=1
          );
    --  
END;
