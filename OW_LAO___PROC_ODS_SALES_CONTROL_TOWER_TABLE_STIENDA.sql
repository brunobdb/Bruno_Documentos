CREATE OR REPLACE PROCEDURE OW_LAO.proc_ods_sales_control_tower_table_stienda()
LANGUAGE PLvSQL AS $$
BEGIN
  
  PERFORM DROP TABLE IF EXISTS stg_sales_orders_stienda_uruguay_prepare;
  PERFORM CREATE LOCAL TEMPORARY TABLE stg_sales_orders_stienda_uruguay_prepare ON COMMIT PRESERVE ROWS AS (
    SELECT 
      CAST(TO_TIMESTAMP(REPLACE(SUBSTR(a.fechainicio,1,16),'T',' '), 'YYYY-MM-DD HH24:MI') AS DATE) AS po_date,
      EXTRACT(YEAR FROM TO_TIMESTAMP(REPLACE(SUBSTR(a.fechainicio,1,16),'T',' '), 'YYYY-MM-DD HH24:MI'))::INT AS po_year,
      EXTRACT(MONTH FROM TO_TIMESTAMP(REPLACE(SUBSTR(a.fechainicio,1,16),'T',' '), 'YYYY-MM-DD HH24:MI'))::INT AS po_month,
      'Uruguay'                            AS country,
      0                                    AS samsung_care_order,
      0                                    AS samsung_care,
      0                                    AS samsung_care_eligibility,
      0                                    AS trade_in,
      0                                    AS trade_in_eligibility,
      0                                    AS trade_up,
      0                                    AS trade_up_eligibility,
      ''                                   AS costumer_code_id_name,
      CAST(a.idorden AS VARCHAR(3000))     AS po_orderid,
      0                                    AS seller_po_orderid,
      CAST(NULL AS VARCHAR(3000))          AS payment_card_brand,
      CAST(NULL AS VARCHAR(3000))          AS payment_type,
      0                                    AS installment,
      NULL                                 AS installment_eligibility,
      ''                                   AS po_cancelation_reason,
      d.product_group_1                    AS po_productgroup,
      ''                                   AS po_code_sales_channel,
      NULL                                 AS po_costumer_id,
      'stienda_uy'                         AS po_sitecode,
      a.estado                             AS po_internal_status,
      NULL                                 AS po_invoicenumber,
      b.nombre                             AS po_prodname,
      COALESCE(b.sku, b.nombre)            AS po_sku,
      e.status                             AS po_status,
      9                                    AS client_subsidiary_id,
      'SELA'                               AS subsidiary,
      a.moneda                             AS currency,
      NULL                                 AS po_tradepolicy,
      CAST(NULL AS VARCHAR(255))           AS channel,
      CAST(NULL AS VARCHAR(255))           AS biz_type,
      CAST(NULL AS VARCHAR(255))           AS audience_type,
      CAST(NULL AS VARCHAR(255))           AS po_storename,
      CAST(NULL AS VARCHAR(255))           AS client_acquirer_message,
      CAST(NULL AS VARCHAR(255))           AS customer_type,
      CAST(NULL AS VARCHAR(255))           AS po_seller_name,
      'stienda_uy'                         AS po_store_name,
      CAST(NULL AS VARCHAR(255))           AS po_mobile_os,
      CURRENT_TIMESTAMP                    AS po_source_insert_date,
      NULL                                 AS po_lastupdate_date_hour,
      0                                    AS po_orderqty,
      SUM(b.cantidad)                      AS po_qty,
      SUM(c.monto)                         AS po_itemdiscount_localcurr,
      0                                    AS po_itemdiscount_usd,
      SUM(b.precio) - SUM(c.monto)         AS po_price_localcurr,
      0                                    AS po_price_usd,
      'ow_lao.stg_sales_orders_stienda_uruguay'  AS po_plataform_datasource,
      CURRENT_TIMESTAMP                    AS po_source_last_update_date,
      CURRENT_TIMESTAMP                    AS po_insert_date,
      NULL                                 AS po_last_update_date,
      CAST(NULL AS VARCHAR(3000))          AS po_payment_remark,
      CAST(TO_TIMESTAMP(REPLACE(SUBSTR(a.fechainicio,1,16),'T',' '), 'YYYY-MM-DD HH24:MI') AS TIME) AS po_hour,
      0                                    AS po_totalprice_usd,
      0                                    AS po_totalprice_local,
      CAST('' AS VARCHAR(255))             AS po_sku_kit,
      CAST('' AS VARCHAR(255))             AS po_prodname_kit,
      CAST(0.00 AS DECIMAL(18,2))          AS po_price_localcurr_kit,
      CAST(0.00 AS DECIMAL(18,2))          AS po_itemdiscount_localcurr_kit,
      FALSE                                AS is_kit,
      'URY'                                AS country_cd,
      CAST(NULL AS VARCHAR(255))           AS biz_type_ebi_hq,
      CAST(NULL AS VARCHAR(255))           AS global_channel_ebi_hq,
      a.origen                             AS po_devicetype
    FROM ow_lao.stg_sales_orders_stienda_uruguay                 a
    JOIN ow_lao.stg_sales_orders_itens_stienda_uruguay           b ON b.idorden       = a.idorden
    JOIN ow_lao.stg_sales_orders_itens_discounts_stienda_uruguay c ON c.idorden       = b.idorden 
                                                                   AND c.sku           = b.sku
    LEFT JOIN ow_md.dim_product                                       d ON d.sku           = b.sku
    LEFT JOIN ow_lao.dim_ods_sales_control_tower_table_status_mapping e ON e.status_origin = COALESCE(a.estado, 'incomplete')
    WHERE NOT EXISTS (
      SELECT 1
      FROM ow_lao.ods_sales_control_tower_table aa
      WHERE aa.po_orderid         = CAST(a.idorden AS VARCHAR(255))
        AND aa.po_sku             = b.sku
        AND aa.country            = 'Uruguay'
        AND aa.po_internal_status = COALESCE(a.estado, 'incomplete')
        AND aa.po_sitecode        = 'stienda_uy'
    )
    GROUP BY a.fechainicio, a.idorden, d.product_group_1, a.estado, e.status, b.sku, b.nombre, a.moneda, a.origen
  );  
  
  PERFORM DROP TABLE IF EXISTS stg_sales_orders_stienda_uruguay_prepare_agg;
  PERFORM CREATE LOCAL TEMPORARY TABLE stg_sales_orders_stienda_uruguay_prepare_agg ON COMMIT PRESERVE ROWS AS (
    SELECT country,
           po_orderid,
           SUM(po_qty)             AS po_orderqty,
           SUM(po_price_localcurr) AS po_totalprice_local
    FROM stg_sales_orders_stienda_uruguay_prepare 
    GROUP BY country, po_orderid
  );
  
  PERFORM DROP TABLE IF EXISTS stg_sales_orders_stienda_uruguay_prepare_sku_agg;
  PERFORM CREATE LOCAL TEMPORARY TABLE stg_sales_orders_stienda_uruguay_prepare_sku_agg ON COMMIT PRESERVE ROWS AS (
    SELECT country,
           po_orderid,
           po_sku,
           SUM(po_qty)                    AS po_orderqty,
           SUM(po_price_localcurr)        AS po_totalprice_local,
           SUM(po_itemdiscount_localcurr) AS po_itemdiscount_localcurr
    FROM stg_sales_orders_stienda_uruguay_prepare  
    GROUP BY country, po_orderid, po_sku
  );  
  
  PERFORM UPDATE stg_sales_orders_stienda_uruguay_prepare a
     SET po_orderqty         = b.po_orderqty,
         po_totalprice_local = (c.po_totalprice_local * c.po_orderqty) - c.po_itemdiscount_localcurr
    FROM stg_sales_orders_stienda_uruguay_prepare_agg     b
    JOIN stg_sales_orders_stienda_uruguay_prepare_sku_agg c ON c.country    = b.country
                                                           AND c.po_orderid = b.po_orderid
   WHERE b.country    = a.country
     AND b.po_orderid = a.po_orderid
     AND c.country    = a.country
     AND c.po_orderid = a.po_orderid
     AND c.po_sku     = a.po_sku;
                                                                            
  PERFORM UPDATE stg_sales_orders_stienda_uruguay_prepare a
     SET po_itemdiscount_usd = a.po_itemdiscount_localcurr / CAST(b.exchange_rate AS DECIMAL),
         po_price_usd        = a.po_price_localcurr        / CAST(b.exchange_rate AS DECIMAL),
         po_totalprice_usd   = a.po_totalprice_local       / CAST(b.exchange_rate AS DECIMAL)
    FROM ow_lao.ft_ap2_exchange_rate b
   WHERE b.valid_from  = TIMESTAMPADD(DAY, -1, a.po_date)
     AND b.to_currency = a.currency;  
                                              
  PERFORM UPDATE stg_sales_orders_stienda_uruguay_prepare a
     SET channel               = b.global_channel,
         biz_type              = b.biz_type,
         audience_type         = b.audience_type,
         biz_type_ebi_hq       = b.biz_type_ebi,
         global_channel_ebi_hq = b.global_channel_ebi,
         po_storename          = b.partner_level,
         customer_type         = b.customer_type,
         po_mobile_os          = b.po_mobile_os
    FROM ow_md.sales_channel b
   WHERE LOWER(b.country)    = LOWER(a.country)
     AND LOWER(b.identifier) = LOWER(a.po_sitecode)
     AND a.client_subsidiary_id    = 9
     AND LOWER(b.plataform_type) = 'stienda';         
           
  PERFORM UPDATE stg_sales_orders_stienda_uruguay_prepare
     SET po_devicetype = 'Web'
   WHERE po_devicetype IS NULL;     
           
  PERFORM UPDATE stg_sales_orders_stienda_uruguay_prepare
     SET global_channel_ebi_hq = '3PD',   
         biz_type_ebi_hq       = 'B2C'
   WHERE global_channel_ebi_hq IS NULL;     
     
  PERFORM UPDATE stg_sales_orders_stienda_uruguay_prepare
     SET channel       = 'eStore',   
         biz_type      = '3PD',
         audience_type = '3PD'   
   WHERE channel IS NULL;                       
     
  PERFORM MERGE INTO ow_lao.ods_sales_control_tower_table                 a
  USING stg_sales_orders_stienda_uruguay_prepare            b 
     ON b.po_orderid  = a.po_orderid
    AND b.po_sku      = a.po_sku
    AND b.country     = a.country
    AND b.po_sku_kit  = a.po_sku_kit
    AND b.po_sitecode = a.po_sitecode
  WHEN MATCHED THEN UPDATE  
          SET a.po_date                          = b.po_date,
              a.podate_month                     = b.po_month,
              a.podate_year                      = b.po_year,
              a.country                          = b.country,
              a.subsidiary                       = b.subsidiary,
              a.currency                         = b.currency,
              a.po_lastupdate_date_hour          = b.po_lastupdate_date_hour,
              a.po_source_last_update_date       = b.po_source_last_update_date,
              a.po_orderid                       = b.po_orderid,
              a.po_seller_name                   = b.po_seller_name,
              a.po_prodname                      = b.po_prodname,
              a.po_store_name                    = b.po_store_name,
              a.po_storename                     = b.po_storename,
              a.channel                          = b.channel,
              a.biz_type                         = b.biz_type,
              a.audience_type                    = b.audience_type,
              a.po_status                        = b.po_status,
              a.po_internal_status               = b.po_internal_status,
              a.po_sku                           = b.po_sku,
              a.po_qty                           = b.po_qty,
              a.po_orderqty                      = b.po_orderqty,
              a.po_itemdiscount_localcurr        = b.po_itemdiscount_localcurr,
              a.po_itemdiscount_usd              = b.po_itemdiscount_usd,
              a.po_price_localcurr               = b.po_price_localcurr,
              a.po_price_usd                     = b.po_price_usd,
              a.po_plataform_datasource          = b.po_plataform_datasource,  
              a.po_source_insert_date            = b.po_source_insert_date,
              a.po_totalprice_usd                = b.po_totalprice_usd,
              a.po_totalprice_local              = b.po_totalprice_local,
              a.po_devicetype                    = b.po_devicetype,
              a.po_sku_kit                       = b.po_sku_kit,
              a.po_prodname_kit                  = b.po_prodname_kit,
              a.is_kit                           = b.is_kit,
              a.country_cd                       = b.country_cd,
              a.biz_type_ebi_hq                  = b.biz_type_ebi_hq,
              a.global_channel_ebi_hq            = b.global_channel_ebi_hq,
              a.customer_type                    = b.customer_type,
              a.po_mobile_os                     = b.po_mobile_os,
              a.installment                      = b.installment,
              a.updated_datetime                 = CURRENT_TIMESTAMP
  WHEN NOT MATCHED THEN INSERT(
              po_date,
              podate_month,
              podate_year,
              country,
              subsidiary,
              currency,
              po_lastupdate_date_hour,
              po_source_last_update_date,
              po_orderid,
              po_seller_name,
              po_prodname,                    
              po_store_name,
              po_storename,
              channel,
              biz_type,
              audience_type,
              po_status,
              po_internal_status,
              po_sku,
              po_qty,
              po_orderqty,
              po_itemdiscount_localcurr,
              po_itemdiscount_usd,
              po_price_localcurr,
              po_price_usd,
              po_plataform_datasource,
              po_source_insert_date,
              po_totalprice_usd,
              po_totalprice_local,
              po_devicetype,
              po_sku_kit,
              po_prodname_kit,
              is_kit,
              country_cd,
              biz_type_ebi_hq,
              global_channel_ebi_hq,
              installment,
              samsung_care_order,
              samsung_care_eligibility,
              trade_in_eligibility,
              client_subsidiary_id,
              po_sitecode,
              customer_type,
              po_mobile_os
          )
          VALUES(
              b.po_date,
              b.po_month,
              b.po_year,
              b.country,
              b.subsidiary,
              b.currency,
              b.po_lastupdate_date_hour,
              b.po_source_last_update_date,
              b.po_orderid,
              b.po_seller_name,
              b.po_prodname,                    
              b.po_store_name,
              b.po_storename,
              b.channel,
              b.biz_type,
              b.audience_type,
              b.po_status,
              b.po_internal_status,
              b.po_sku,
              b.po_qty,
              b.po_orderqty,
              b.po_itemdiscount_localcurr,
              b.po_itemdiscount_usd,
              b.po_price_localcurr,
              b.po_price_usd,
              b.po_plataform_datasource,
              b.po_source_insert_date,
              b.po_totalprice_usd,
              b.po_totalprice_local,
              b.po_devicetype,
              b.po_sku_kit,
              b.po_prodname_kit,
              b.is_kit,
              b.country_cd,
              b.biz_type_ebi_hq,
              b.global_channel_ebi_hq,
              b.installment, 
              0,
              0,
              0,
              b.client_subsidiary_id,
              b.po_sitecode,
              b.customer_type,
              b.po_mobile_os
          ); 
  
END
$$;

-- CALL OW_LAO.proc_ods_sales_control_tower_table_stienda();
-- ERROR: Severity: ERROR, Message: Relation "ow_lao.stg_sales_orders_stienda_uruguay" does not exist, Sqlstate: 42V01, Where: PL/vSQL procedure proc_ods_sales_control_tower_table_stienda line 5 at static SQL, Routine: throwRelationDoesNotExist, File: /data/jenkins/workspace/RE-ReleaseBuilds/RE-Nibbler/server/vertica/Catalog/CatalogLookup.cpp, Line: 4341, Error Code: 4568, 
-- CALL OW_LAO.proc_ods_sales_control_tower_table_stienda();
-- ERROR: Severity: ERROR, Message: Relation "ow_lao.stg_sales_orders_stienda_uruguay" does not exist, Sqlstate: 42V01, Where: PL/vSQL procedure proc_ods_sales_control_tower_table_stienda line 5 at static SQL, Routine: throwRelationDoesNotExist, File: /data/jenkins/workspace/RE-ReleaseBuilds/RE-Nibbler/server/vertica/Catalog/CatalogLookup.cpp, Line: 4341, Error Code: 4568, 
