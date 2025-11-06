CREATE OR REPLACE PROCEDURE OW_LAO.proc_ods_sales_control_tower_table_diggit_hist_homolg()
LANGUAGE PLvSQL AS $$
BEGIN
  
  PERFORM DROP TABLE IF EXISTS u_prj_ecom.tmp_ods_diggit_ecom_orders_prepare_hist_homolg;
  PERFORM DROP TABLE IF EXISTS u_prj_ecom.tmp_ods_diggit_ecom_orders_prepare_agg_hist_homolg;
  PERFORM DROP TABLE IF EXISTS u_prj_ecom.tmp_ods_diggit_ecom_orders_prepare_sku_agg_hist_homolg;
  
  PERFORM CREATE TABLE u_prj_ecom.tmp_ods_diggit_ecom_orders_prepare_hist_homolg AS
    SELECT CAST((a.order_creation_date || ' ' || a.order_creation_hour) AS TIMESTAMP)          AS po_date
         , EXTRACT(MONTH FROM a.order_creation_date)                                           AS po_month
         , EXTRACT(YEAR FROM a.order_creation_date)                                            AS po_year
         , b.country                                                                           AS country
         , b.subsidiary                                                                        AS subsidiary
         , b.currency                                                                          AS currency
         , COALESCE(a.updated_timestamp, a.inserted_timestamp)                                 AS po_lastupdate_date_hour
         , COALESCE(a.updated_timestamp, a.inserted_timestamp)                                 AS po_source_last_update_date
         , a.order_code                                                                        AS po_orderid
         , 'diggit'                                                                            AS po_seller_name
         , a.sku                                                                               AS po_prodname
         , a.store_name                                                                        AS po_storename
         , CAST(NULL AS VARCHAR(255))                                                          AS channel
         , CAST(NULL AS VARCHAR(255))                                                          AS biz_type
         , CAST(NULL AS VARCHAR(255))                                                          AS audience_type
         , c.status                                                                            AS po_status
         , a.order_status                                                                      AS po_internal_status
         , a.sku                                                                               AS po_sku
         , SUM(ABS(a.qty))                                                                     AS po_qty
         , 0                                                                                   AS po_orderqty
         , CAST(0.00 AS DECIMAL(18,2))                                                         AS po_itemdiscount_localcurr
         , CAST(0.00 AS DECIMAL(18,2))                                                         AS po_itemdiscount_usd
         , SUM(CAST(a.product_price AS DECIMAL(18,2)))                                         AS po_price_localcurr
         , CAST(0.00 AS DECIMAL(18,2))                                                         AS po_price_usd
         , 'u_prj_ecom.ods_diggit_ecom_orders'                                                 AS po_plataform_datasource
         , a.inserted_timestamp                                                                AS po_source_insert_date
         , CAST(0.00 AS DECIMAL(18,2))                                                         AS po_totalprice_usd
         , CAST(0.00 AS DECIMAL(18,2))                                                         AS po_totalprice_local
         , MAX(a.id)                                                                           AS po_plataform_datasource_order_id
         , CAST(NULL AS VARCHAR(255))                                                          AS po_devicetype
         , ''                                                                                  AS po_sku_kit
         , ''                                                                                  AS po_prodname_kit
         , CAST(0.00 AS DECIMAL(18,2))                                                         AS po_price_localcurr_kit
         , CAST(0.00 AS DECIMAL(18,2))                                                         AS po_itemdiscount_localcurr_kit
         , FALSE                                                                               AS is_kit
         , 'ARG'                                                                               AS country_cd
         , CAST(NULL AS VARCHAR(3))                                                            AS biz_type_ebi_hq
         , CAST(NULL AS VARCHAR(3))                                                            AS global_channel_ebi_hq
         , 1                                                                                   AS installment
         , MAX(b.id)                                                                           AS client_subsidiary_id
         , 'diggit'                                                                            AS po_sitecode
         , CAST(a.order_creation_hour AS TIME)                                                 AS po_hour
         , CAST(a.order_creation_date || ' ' || a.order_creation_hour || '.000' AS TIMESTAMP)  AS po_timestamp
    FROM u_prj_ecom.ods_diggit_ecom_orders_hist_homolog a
    JOIN u_prj_ecom.dim_subsidiary b ON b.id = 1
    LEFT JOIN ow_lao.dim_ods_sales_control_tower_table_status_mapping c
      ON c.status_origin = COALESCE(a.order_status, 'incomplete')
   WHERE a.qty > 0
     AND NOT EXISTS (
           SELECT 1
             FROM ow_lao.ods_sales_control_tower_table_diggit_homolg aa
            WHERE aa.po_orderid           = a.order_code
              AND aa.po_sku               = a.sku
              AND aa.client_subsidiary_id = 1
              AND aa.po_sitecode          = 'diggit'
              AND aa.po_internal_status   = a.order_status
         )
   GROUP BY CAST((a.order_creation_date || ' ' || a.order_creation_hour) AS TIMESTAMP)
          , EXTRACT(MONTH FROM a.order_creation_date)
          , EXTRACT(YEAR FROM a.order_creation_date)
          , b.country
          , b.subsidiary
          , b.currency
          , a.inserted_timestamp
          , a.updated_timestamp
          , a.order_code
          , c.status
          , a.order_status
          , a.sku
          , a.store_name
          , CAST(a.order_creation_hour AS TIME)
          , CAST(a.order_creation_date || ' ' || a.order_creation_hour || '.000' AS TIMESTAMP)
  ;

  PERFORM CREATE TABLE u_prj_ecom.tmp_ods_diggit_ecom_orders_prepare_agg_hist_homolg AS
    SELECT country
         , po_orderid
         , SUM(po_qty)             AS po_orderqty
         , SUM(po_price_localcurr) AS po_totalprice_local
      FROM u_prj_ecom.tmp_ods_diggit_ecom_orders_prepare_hist_homolg
     GROUP BY country, po_orderid
  ;

  PERFORM CREATE TABLE u_prj_ecom.tmp_ods_diggit_ecom_orders_prepare_sku_agg_hist_homolg AS
    SELECT country
         , po_orderid
         , po_sku
         , SUM(po_qty)                    AS po_orderqty
         , SUM(po_price_localcurr)        AS po_totalprice_local
         , SUM(po_itemdiscount_localcurr) AS po_itemdiscount_localcurr
      FROM u_prj_ecom.tmp_ods_diggit_ecom_orders_prepare_hist_homolg
     GROUP BY country, po_orderid, po_sku
  ;

  PERFORM UPDATE u_prj_ecom.tmp_ods_diggit_ecom_orders_prepare_hist_homolg a
     SET po_orderqty         = b.po_orderqty
       , po_totalprice_local = (c.po_totalprice_local * c.po_orderqty) - c.po_itemdiscount_localcurr
    FROM u_prj_ecom.tmp_ods_diggit_ecom_orders_prepare_agg_hist_homolg b
    JOIN u_prj_ecom.tmp_ods_diggit_ecom_orders_prepare_sku_agg_hist_homolg c
      ON c.country = a.country
     AND c.po_orderid = a.po_orderid
     AND c.po_sku = a.po_sku
   WHERE b.country = a.country
     AND b.po_orderid = a.po_orderid
  ;

  PERFORM UPDATE u_prj_ecom.tmp_ods_diggit_ecom_orders_prepare_hist_homolg a
     SET po_itemdiscount_usd = a.po_itemdiscount_localcurr / CAST(b.exchange_rate AS DECIMAL(18,6))
       , po_price_usd        = a.po_price_localcurr        / CAST(b.exchange_rate AS DECIMAL(18,6))
       , po_totalprice_usd   = a.po_totalprice_local       / CAST(b.exchange_rate AS DECIMAL(18,6))
    FROM ow_lao.ft_ap2_exchange_rate b
   WHERE b.valid_from  = DATEADD(day, -1, CAST(a.po_date AS DATE))
     AND b.to_currency = a.currency
  ;

  PERFORM UPDATE u_prj_ecom.tmp_ods_diggit_ecom_orders_prepare_hist_homolg a
     SET channel               = b.global_channel
       , biz_type              = b.biz_type
       , audience_type         = b.audience_type
       , biz_type_ebi_hq       = b.biz_type_ebi
       , global_channel_ebi_hq = b.global_channel_ebi
    FROM ow_md.sales_channel b
   WHERE LOWER(b.country) = LOWER(a.country)
     AND LOWER(b.identifier) = LOWER(a.po_storename)
     AND a.client_subsidiary_id = 1
     AND LOWER(b.plataform_type) = 'diggit'
  ;

  PERFORM UPDATE u_prj_ecom.tmp_ods_diggit_ecom_orders_prepare_hist_homolg
     SET po_devicetype = 'MOBILEAPP'
   WHERE po_sitecode = 'samsungarapp'
     AND client_subsidiary_id = 1
  ;

  PERFORM UPDATE u_prj_ecom.tmp_ods_diggit_ecom_orders_prepare_hist_homolg
     SET po_devicetype = 'Web'
   WHERE po_devicetype IS NULL
  ;

  PERFORM UPDATE u_prj_ecom.tmp_ods_diggit_ecom_orders_prepare_hist_homolg
     SET global_channel_ebi_hq = '3PD'
       , biz_type_ebi_hq = 'B2C'
   WHERE global_channel_ebi_hq IS NULL
  ;

  PERFORM UPDATE u_prj_ecom.tmp_ods_diggit_ecom_orders_prepare_hist_homolg
     SET channel = 'eStore'
       , biz_type = '3PD'
       , audience_type = '3PD'
   WHERE channel IS NULL
  ;

  PERFORM MERGE INTO ow_lao.ods_sales_control_tower_table_diggit_homolg a
  USING u_prj_ecom.tmp_ods_diggit_ecom_orders_prepare_hist_homolg b
     ON b.po_orderid = a.po_orderid
    AND b.po_sku = a.po_sku
    AND b.country = a.country
    AND b.po_sku_kit = a.po_sku_kit
    AND b.po_sitecode = a.po_sitecode
  WHEN MATCHED THEN UPDATE SET
       po_date                         = b.po_date
     , podate_month                    = b.po_month
     , podate_year                     = b.po_year
     , country                         = b.country
     , subsidiary                      = b.subsidiary
     , currency                        = b.currency
     , po_lastupdate_date_hour         = b.po_lastupdate_date_hour
     , po_source_last_update_date      = b.po_source_last_update_date
     , po_orderid                      = b.po_orderid
     , po_seller_name                  = b.po_seller_name
     , po_prodname                     = b.po_prodname
     , po_storename                    = b.po_storename
     , channel                         = b.channel
     , biz_type                        = b.biz_type
     , audience_type                   = b.audience_type
     , po_status                       = b.po_status
     , po_internal_status              = b.po_internal_status
     , po_sku                          = b.po_sku
     , po_qty                          = b.po_qty
     , po_orderqty                     = b.po_orderqty
     , po_itemdiscount_localcurr       = b.po_itemdiscount_localcurr
     , po_itemdiscount_usd             = b.po_itemdiscount_usd
     , po_price_localcurr              = b.po_price_localcurr
     , po_price_usd                    = b.po_price_usd
     , po_plataform_datasource         = b.po_plataform_datasource
     , po_source_insert_date           = b.po_source_insert_date
     , po_totalprice_usd               = b.po_totalprice_usd
     , po_totalprice_local             = b.po_totalprice_local
     , po_devicetype                   = b.po_devicetype
     , po_sku_kit                      = b.po_sku_kit
     , po_prodname_kit                 = b.po_prodname_kit
     , is_kit                          = b.is_kit
     , country_cd                      = b.country_cd
     , biz_type_ebi_hq                 = b.biz_type_ebi_hq
     , global_channel_ebi_hq           = b.global_channel_ebi_hq
     , installment                     = b.installment
     , updated_datetime                = CURRENT_TIMESTAMP
     , po_timestamp                    = b.po_timestamp
  WHEN NOT MATCHED THEN INSERT (
       po_date
     , podate_month
     , podate_year
     , country
     , subsidiary
     , currency
     , po_lastupdate_date_hour
     , po_source_last_update_date
     , po_orderid
     , po_seller_name
     , po_prodname
     , po_storename
     , channel
     , biz_type
     , audience_type
     , po_status
     , po_internal_status
     , po_sku
     , po_qty
     , po_orderqty
     , po_itemdiscount_localcurr
     , po_itemdiscount_usd
     , po_price_localcurr
     , po_price_usd
     , po_plataform_datasource
     , po_source_insert_date
     , po_totalprice_usd
     , po_totalprice_local
     , po_devicetype
     , po_sku_kit
     , po_prodname_kit
     , is_kit
     , country_cd
     , biz_type_ebi_hq
     , global_channel_ebi_hq
     , installment
     , samsung_care_order
     , samsung_care_eligibility
     , trade_in_eligibility
     , client_subsidiary_id
     , po_sitecode
     , po_timestamp
  ) VALUES (
       b.po_date
     , b.po_month
     , b.po_year
     , b.country
     , b.subsidiary
     , b.currency
     , b.po_lastupdate_date_hour
     , b.po_source_last_update_date
     , b.po_orderid
     , b.po_seller_name
     , b.po_prodname
     , b.po_storename
     , b.channel
     , b.biz_type
     , b.audience_type
     , b.po_status
     , b.po_internal_status
     , b.po_sku
     , b.po_qty
     , b.po_orderqty
     , b.po_itemdiscount_localcurr
     , b.po_itemdiscount_usd
     , b.po_price_localcurr
     , b.po_price_usd
     , b.po_plataform_datasource
     , b.po_source_insert_date
     , b.po_totalprice_usd
     , b.po_totalprice_local
     , b.po_devicetype
     , b.po_sku_kit
     , b.po_prodname_kit
     , b.is_kit
     , b.country_cd
     , b.biz_type_ebi_hq
     , b.global_channel_ebi_hq
     , b.installment
     , 0
     , 0
     , 0
     , b.client_subsidiary_id
     , b.po_sitecode
     , b.po_timestamp
  );

END;
$$;

-- CALL OW_LAO.proc_ods_sales_control_tower_table_diggit_hist_homolg();
-- ERROR: Severity: ERROR, Message: Relation "u_prj_ecom.ods_diggit_ecom_orders_hist_homolog" does not exist, Sqlstate: 42V01, Where: PL/vSQL procedure proc_ods_sales_control_tower_table_diggit_hist_homolg line 8 at static SQL, Routine: throwRelationDoesNotExist, File: /data/jenkins/workspace/RE-ReleaseBuilds/RE-Nibbler/server/vertica/Catalog/CatalogLookup.cpp, Line: 4341, Error Code: 4568, 
-- CALL OW_LAO.proc_ods_sales_control_tower_table_diggit_hist_homolg();
-- ERROR: Severity: ERROR, Message: Relation "u_prj_ecom.ods_diggit_ecom_orders_hist_homolog" does not exist, Sqlstate: 42V01, Where: PL/vSQL procedure proc_ods_sales_control_tower_table_diggit_hist_homolg line 8 at static SQL, Routine: throwRelationDoesNotExist, File: /data/jenkins/workspace/RE-ReleaseBuilds/RE-Nibbler/server/vertica/Catalog/CatalogLookup.cpp, Line: 4341, Error Code: 4568, 
