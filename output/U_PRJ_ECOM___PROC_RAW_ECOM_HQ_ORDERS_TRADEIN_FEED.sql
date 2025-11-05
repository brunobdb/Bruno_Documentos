CREATE PROCEDURE U_PRJ_ECOM.PROC_RAW_ECOM_HQ_ORDERS_TRADEIN_FEED
 LANGUAGE SQLSCRIPT AS
 BEGIN
--DROP TABLE U_PRJ_ECOM.TMP_ECOM_HQ_ORDERS_TRADEIN_FEED;
DROP TABLE U_PRJ_ECOM.TMP_ECOM_HQ_ORDERS_TRADEIN_FEED;
DROP TABLE U_PRJ_ECOM.TMP_ECOM_HQ_ORDERS_TRADEIN_FEED_SEND;
 
-- TF ENVIO NOVO FEED TRADE IN
CREATE COLUMN TABLE U_PRJ_ECOM.TMP_ECOM_HQ_ORDERS_TRADEIN_FEED  AS 
(
 
SELECT DISTINCT 
a.COUNTRY_CD AS "country_cd",
a.PO_ORDERID AS "order_id",
a.PO_SKU  AS "line_item_id",
b.BRAND AS "exchange_brand",
b.CATEGORY_NAME AS "exchange_category",
b.MODEL AS "exchange_device_name",
'' AS "exchange_grade",
'' AS "exchange_id",
'' AS "exchange_type",
'' AS "is_accessory",
'' AS "is_financed_order",
 CASE WHEN a.INSTALLMENT > 1 THEN 'TRUE' ELSE 'FALSE'
     END   AS  "is_financing",
 '' AS "is_financing_eligible",
CASE  WHEN  a.SAMSUNG_CARE =  1 THEN 'TRUE'  
      ELSE 'FALSE'
     END   AS "is_samsung_care_order",          
'TRUE' AS "is_traded_in",
'' AS "is_under_extended_warranty",
CAST (a.PO_DATE AS date) || ' ' || a.PO_HOUR AS "order_date",
CAST (a.PO_DATE AS date) || ' ' || a.PO_HOUR AS "order_time_utc",
 a.PO_ORDERID  AS "po_id",
a.PO_INTERNAL_STATUS  AS "po_status",
a.PO_SKU  AS "sku",
'' AS "tradein_ext_memory",
'' AS "tradein_ext_product_family_name",
'' AS "tradein_ext_product_identifier",
'' AS "upgrade_id",                   
'' AS "upgrade_loan_number",            
'' AS "upgrade_root_order_date",      
'' AS "upgrade_status",               
'' AS "ex_est_exch_discount_amount",
'' AS "ex_est_exch_value_amount",    
'' AS "ex_est_total_amount",            
'' AS "ex_identity_id",               
'' AS "ex_sku",                         
'' AS "ex_status",
 'FALSE' as "is_upgrade",
'FALSE' AS "is_tariff_order",
SUM (b.TRADE_IN_DISCOUNT) AS "discount_amount"
 
FROM  OW_LAO.ODS_SALES_CONTROL_TOWER_TABLE    a
JOIN   U_PRJ_ECOM.ODS_ECOM_HQ_ORDERS_PRODUCTS_TRADEIN b ON a.PO_ORDERID           = b."Order_Id" 
                                                           AND a.po_sku               = b."Reference_Code" 
                                                           AND a.CLIENT_SUBSIDIARY_ID = b.SUBSIDIARY_ID
                                                                
                                                                   
WHERE a.CLIENT_SUBSIDIARY_ID  IN  (6,1)
AND   not exists(
                  select 1
                    from  U_PRJ_ECOM.RAW_ECOM_HQ_ORDERS_TRADEIN_FEED aa
                  WHERE         aa."order_id"            = a.PO_ORDERID 
                           AND  aa."line_item_id"        = a.PO_SKU 
                            
                 )
                 
AND B.IS_TRADE_IN = 'TRUE'  
AND a.PO_DATE >= '2023-01-01'                
GROUP BY 
a.COUNTRY_CD ,
a.PO_ORDERID ,
a.PO_SKU ,
b.BRAND ,
b.CATEGORY_NAME ,
b.MODEL ,
'' ,
'' ,
'' ,
'' ,
'' ,
 CASE WHEN a.INSTALLMENT > 1 THEN 'TRUE' ELSE 'FALSE'
     END   ,
 '' ,
CASE  WHEN  a.SAMSUNG_CARE =  1 THEN 'TRUE'  
      ELSE 'FALSE'
     END   ,          
'TRUE' ,
'' ,
CAST (a.PO_DATE AS date) ,
a.PO_HOUR  ,
a.PO_ORDERID  ,
a.PO_INTERNAL_STATUS  ,
a.PO_SKU ,
'' ,
'' ,
'' ,
'' ,                   
'' ,            
'' ,      
'' ,               
'' ,
'' ,    
'' ,            
'' ,               
'' ,                         
'' ,
 'FALSE' ,
'FALSE'
)
;
 --PROCESSO PEDIDOS NAO ENVIADOS HQ 
 --AJUSTE DATA 
             
CREATE COLUMN TABLE U_PRJ_ECOM.TMP_ECOM_HQ_ORDERS_TRADEIN_FEED_SEND AS  (
 SELECT DISTINCT 
 A."country_cd",
A."order_id",
A."line_item_id",
A."discount_amount",
A."exchange_brand",
A."exchange_category",
A."exchange_device_name",
A."exchange_grade",
A."exchange_id",
A."exchange_type",
A."is_accessory",
A."is_financed_order",
A."is_financing",
A."is_financing_eligible",
A."is_samsung_care_order",
A."is_traded_in",
A."is_under_extended_warranty",
A."order_date",
 TO_VARCHAR(
        ADD_SECONDS(CAST("order_time_utc" AS TIMESTAMP), -3 * 3600),  -- Subtrai 3 horas (em segundos)
        'YYYY-MM-DD HH24:MI:SS'
    ) AS "order_time_utc",
A."po_id",
A."po_status",
A."sku",
A."tradein_ext_memory",
A."tradein_ext_product_family_name",
A."tradein_ext_product_identifier",
A."upgrade_id",
A."upgrade_loan_number",
A."upgrade_root_order_date",
A."upgrade_status",
A."ex_est_exch_discount_amount",
A."ex_est_exch_value_amount",
A."ex_est_total_amount",
A."ex_identity_id",
A."ex_sku",
A."ex_status",
"is_upgrade",
"is_tariff_order"
 
 
 FROM  U_PRJ_ECOM.TMP_ECOM_HQ_ORDERS_TRADEIN_FEED  a
 WHERE  not exists(
                  select 1
                    from  U_PRJ_ECOM.RAW_ECOM_HQ_ORDERS_TRADEIN_FEED aa
                  WHERE         aa."order_id"            = a."order_id"
                           AND  aa."line_item_id"        = a."line_item_id"
                            
                  )
 
 
 )
 ;
	INSERT INTO U_PRJ_ECOM.RAW_ECOM_HQ_ORDERS_TRADEIN_FEED 
(SELECT DISTINCT 
"country_cd",
"order_id",
"line_item_id",
"discount_amount",
"exchange_brand",
"exchange_category",
"exchange_device_name",
"exchange_grade",
"exchange_id",
"exchange_type",
"is_accessory",
"is_financed_order",
"is_financing",
"is_financing_eligible",
"is_samsung_care_order",
"is_traded_in",
"is_under_extended_warranty",
"order_date",
"order_time_utc",
"po_id",
"po_status",
"sku",
"tradein_ext_memory",
"tradein_ext_product_family_name",
"tradein_ext_product_identifier",
"upgrade_id",
"upgrade_loan_number",
"upgrade_root_order_date",
"upgrade_status",
"ex_est_exch_discount_amount",
"ex_est_exch_value_amount",
"ex_est_total_amount",
"ex_identity_id",
"ex_sku",
"ex_status",
"is_upgrade",
"is_tariff_order",
CURRENT_TIMESTAMP AS LOAD_DATE, 
CURRENT_TIMESTAMP AS LAST_UPDATE_DATE
FROM U_PRJ_ECOM.TMP_ECOM_HQ_ORDERS_TRADEIN_FEED_SEND
 
)
;
END