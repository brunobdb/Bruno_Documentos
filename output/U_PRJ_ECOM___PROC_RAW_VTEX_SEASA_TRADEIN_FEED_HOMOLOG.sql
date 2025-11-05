CREATE PROCEDURE U_PRJ_ECOM.PROC_RAW_VTEX_SEASA_TRADEIN_FEED_HOMOLOG
 LANGUAGE SQLSCRIPT AS
 BEGIN     
	 
	 
 
 
	 --- Temporária que inseri os dados na tabela raw_vtex_seasa_tradein
 CREATE TABLE U_PRJ_ECOM.TMP_VTEX_SEASA_TRADEIN_FEED AS (
SELECT 
   a.ORDER_ID,
   a.CREATION_DATE,
   a.HOSTNAME,
   a.UNIQUE_ID AS UNIQUEID,
   a.SKU_ID AS SKUID,
   a.PRODUCT_ID AS PRODUCTID,
   a.EAN,
   a.REF_ID AS REFID,
   a.DEVICE_BRAND AS BRAND_DEVICE,
   a.DEVICE_MODEL AS MODEL_DEVICE,
   a.DEVICE_VALUE/100 AS TRADE_IN_DISCOUNT_DEVICE ,
    CURRENT_TIMESTAMP AS INSERT_DATE, 
    CURRENT_TIMESTAMP AS LAST_UPDATE_DATE
     
FROM (
-- Query para device1
SELECT
    a.order_id,
    b.CREATION_TIMESTAMP AS CREATION_DATE,
    b.HOSTNAME,
    a.UNIQUE_ID,
    a.SKU_ID,
    a.REF_ID AS REF_ID,  -- Alias para REF_ID
    a.PRODUCT_ID,
    a.EAN,
    JSON_VALUE(
        REPLACE(
            REPLACE(
                REPLACE(
                    a.attachments, 
                    '\', ''  
                ), 
                '"{', '{'  
            ), 
            '}"', '}'  
        ),
        '$.content.TradeIn.bonoTotal' DEFAULT NULL ON EMPTY
    ) AS bonoTotal,
    
    -- Device 1 Fields
    JSON_VALUE(
        REPLACE(
            REPLACE(
                REPLACE(
                    a.attachments, 
                    '\', ''  
                ), 
                '"{', '{'  
            ), 
            '}"', '}'  
        ),
        '$.content.TradeIn.device1.type' DEFAULT NULL ON EMPTY
    ) AS device_type,
    
    JSON_VALUE(
        REPLACE(
            REPLACE(
                REPLACE(
                    a.attachments, 
                    '\', ''  
                ), 
                '"{', '{'  
            ), 
            '}"', '}'  
        ),
        '$.content.TradeIn.device1.brand' DEFAULT NULL ON EMPTY
    ) AS device_brand,
    
    JSON_VALUE(
        REPLACE(
            REPLACE(
                REPLACE(
                    a.attachments, 
                    '\', ''  
                ), 
                '"{', '{'  
            ), 
            '}"', '}'  
        ),
        '$.content.TradeIn.device1.value' DEFAULT NULL ON EMPTY
    ) AS device_value,
    -- Adicionando o campo model
    JSON_VALUE(
        REPLACE(
            REPLACE(
                REPLACE(
                    a.attachments, 
                    '\', ''  
                ), 
                '"{', '{'  
            ), 
            '}"', '}'  
        ),
        '$.content.TradeIn.device1.model' DEFAULT NULL ON EMPTY
    ) AS device_model, -- Novo campo model
    -- Regra para calcular tradeIn para device1
    CASE 
        WHEN JSON_VALUE(
            REPLACE(
                REPLACE(
                    REPLACE(
                       a.attachments, 
                        '\', ''  
                    ), 
                    '"{', '{'  
                ), 
                '}"', '}'  
            ),
            '$.content.TradeIn.device1' DEFAULT 'false' ON EMPTY
        ) = 'false' THEN 0
        ELSE 1
    END AS tradeIn
FROM u_prj_ecom.raw_vtex_ssg_ar_sales_order_item a
LEFT JOIN u_prj_ecom.raw_vtex_ssg_ar_sales_order b ON a.ORDER_ID = b.ORDER_ID 
WHERE a.attachments IS NOT NULL
UNION ALL
-- Query para device2
SELECT
    a.order_id,
    b.CREATION_TIMESTAMP AS CREATION_DATE,
    b.HOSTNAME,
    a.UNIQUE_ID,
    a.SKU_ID,
    a.REF_ID AS REF_ID,  -- Alias para REF_ID
    a.PRODUCT_ID,
    a.EAN,
    JSON_VALUE(
        REPLACE(
            REPLACE(
                REPLACE(
                    a.attachments, 
                    '\', ''  
                ), 
                '"{', '{'  
            ), 
            '}"', '}'  
        ),
        '$.content.TradeIn.bonoTotal' DEFAULT NULL ON EMPTY
    ) AS bonoTotal,
    
    -- Device 2 Fields
    JSON_VALUE(
        REPLACE(
            REPLACE(
                REPLACE(
                    a.attachments, 
                    '\', ''  
                ), 
                '"{', '{'  
            ), 
            '}"', '}'  
        ),
        '$.content.TradeIn.device2.type' DEFAULT NULL ON EMPTY
    ) AS device_type,
    
    JSON_VALUE(
        REPLACE(
            REPLACE(
                REPLACE(
                    a.attachments, 
                    '\', ''  
                ), 
                '"{', '{'  
            ), 
            '}"', '}'  
        ),
        '$.content.TradeIn.device2.brand' DEFAULT NULL ON EMPTY
    ) AS device_brand,
    
    JSON_VALUE(
        REPLACE(
            REPLACE(
                REPLACE(
                    a.attachments, 
                    '\', ''  
                ), 
                '"{', '{'  
            ), 
            '}"', '}'  
        ),
        '$.content.TradeIn.device2.value' DEFAULT NULL ON EMPTY
    ) AS device_value,
    -- Adicionando o campo model para device2 (caso exista)
    JSON_VALUE(
        REPLACE(
            REPLACE(
                REPLACE(
                    a.attachments, 
                    '\', ''  
                ), 
                '"{', '{'  
            ), 
            '}"', '}'  
        ),
        '$.content.TradeIn.device2.model' DEFAULT NULL ON EMPTY
    ) AS device_model, -- Novo campo model
    -- Regra para calcular tradeIn para device2
    CASE 
        WHEN JSON_VALUE(
            REPLACE(
                REPLACE(
                    REPLACE(
                       a.attachments, 
                        '\', ''  
                    ), 
                    '"{', '{'  
                ), 
                '}"', '}'  
            ),
            '$.content.TradeIn.device2' DEFAULT 'false' ON EMPTY
        ) = 'false' THEN 0
        ELSE 1
    END AS tradeIn
FROM u_prj_ecom.raw_vtex_ssg_ar_sales_order_item a
LEFT JOIN u_prj_ecom.raw_vtex_ssg_ar_sales_order b ON a.ORDER_ID = b.ORDER_ID 
WHERE a.attachments IS NOT NULL)  a
WHERE a.TRADEIN = 1
AND a.CREATION_DATE IS NOT NULL 
--AND a.ORDER_ID = '1475523608352-01'
AND  not exists(
                  select 1
                    from "U_PRJ_ECOM"."RAW_VTEX_SEASA_TRADEIN_FEED" aa
                  WHERE         aa.ORDER_ID              = a.ORDER_ID
	                        AND aa.REFID                 = a.REF_ID
	               
                        )
                        );
                       
                       
  -- inserção de dados na tabela raw
	INSERT INTO U_PRJ_ECOM.RAW_VTEX_SEASA_TRADEIN_FEED
(SELECT DISTINCT 
 ORDER_ID,
CREATION_DATE,
HOSTNAME,
UNIQUEID,
SKUID,
PRODUCTID,
EAN,
REFID,
BRAND_DEVICE,
MODEL_DEVICE,
TRADE_IN_DISCOUNT_DEVICE,
INSERT_DATE,
LAST_UPDATE_DATE
	  FROM U_PRJ_ECOM.TMP_VTEX_SEASA_TRADEIN_FEED  tmp
	 WHERE  1=1
	   AND tmp. ORDER_ID IS NOT NULL
	   AND not exists(
                  select 1
                    from "U_PRJ_ECOM"."RAW_VTEX_SEASA_TRADEIN_FEED" aa
                  WHERE         aa.ORDER_ID              = tmp.ORDER_ID
                    and          aa.REFID                = tmp.REFID
	                            
                  ))                     
                       ;
                     	                       
      --- drop tabela temporária
                      
                      DROP TABLE U_PRJ_ECOM.TMP_VTEX_SEASA_TRADEIN_FEED;
                     
                     END