CREATE OR REPLACE PROCEDURE OW_LAO.proc_ods_sales_control_tower_table_u_prj_ecom()
LANGUAGE PLvSQL AS $$
BEGIN
  
  -- Sales nao BRSHOP
  PERFORM TRUNCATE TABLE ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom;
  
  PERFORM INSERT INTO ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom
  SELECT CAST(a.creation_date AS DATE)                          AS po_date
       , EXTRACT(YEAR FROM a.creation_date)                     AS podate_year
       , EXTRACT(MONTH FROM a.creation_date)                    AS podate_month
       , e.country                                              AS country
       , COALESCE(b.is_samsung_care, 0)                         AS samsung_care_order
       , COALESCE(b.is_samsung_care, 0)                         AS samsung_care
       , COALESCE(b.is_samsung_care, 0)                         AS samsung_care_eligibility
       , 0                                                      AS trade_in
       , 0                                                      AS trade_in_eligibility
       , 0                                                      AS trade_up
       , 0                                                      AS trade_up_eligibility
       , a.affiliate_id                                         AS costumer_code_id_name
       , a.external_order_id                                    AS po_orderid
       , a.seller_order_id                                      AS seller_po_orderid
       , CAST(NULL AS VARCHAR(3000))                            AS payment_card_brand
       , CAST(NULL AS VARCHAR(3000))                            AS payment_type
       , 0                                                      AS installment
       , NULL                                                   AS installment_eligibility
       , a.cancellation_reason                                  AS po_cancelation_reason
       , f.product_group_1                                      AS po_productgroup
       , a.cod_sales_channel                                    AS po_code_sales_channel
       , a.customer_id                                          AS po_costumer_id
       , a.hostname                                             AS po_sitecode
       , a.status                                               AS po_internal_status
       , a.invoice_number                                       AS po_invoicenumber
       , a.mkt_campaign_tags                                    AS po_campain_tags
       , a.mkt_utm_campaign                                     AS po_campain
       , a.mkt_utm_coupon                                       AS po_coupon
       , a.mkt_utm_medium                                       AS po_medium
       , a.mkt_utm_src                                          AS po_src
       , a.mkt_utmi_campaign                                    AS po_utmi_campaing
       , a.order_sequence                                       AS po_sequence_orderid
       , LISTAGG(b.product_name USING PARAMETERS separator='|')::VARCHAR  AS po_prodname
       , COALESCE(
              b.reference_code
            , LISTAGG(b.product_name USING PARAMETERS separator='|')::VARCHAR
         )                                                      AS po_sku
       , a.seller_id                                            AS po_seller_id
       , a.seller_name                                          AS po_seller_name
       , g.status                                               AS po_status
       , a.subsidiary_id                                        AS client_subsidiary_id
       , e.subsidiary                                           AS subsidiary
       , e.currency                                             AS currency
       , a.trade_policy                                         AS po_tradepolicy
       , a.vendor                                               AS po_vendortype
       , NULL                                                   AS channel
       , NULL                                                   AS biz_type
       , NULL                                                   AS audience_type
       , NULL                                                   AS po_storename
       , a.acquirer_message                                     AS client_acquirer_message
       , a.last_update_date                                     AS po_lastupdate_date_hour
       , 0                                                      AS po_orderqty
       , SUM(b.quantity)                                        AS po_qty
       , SUM(b.discount)                                        AS po_itemdiscount_localcurr
       , 0                                                      AS po_itemdiscount_usd
       , SUM(b.price)                                           AS po_price_localcurr
       , 0                                                      AS po_price_usd
       , 'u_prj_ecom.ft_ecom_order'                             AS po_plataform_datasource
       , a.insert_date                                          AS po_source_insert_date
       , a.last_update_date                                     AS po_source_last_update_date
       , CURRENT_TIMESTAMP                                      AS po_insert_date
       , NULL                                                   AS po_last_update_date
       , CAST(NULL AS VARCHAR(3000))                            AS po_payment_remark
       , CAST(a.creation_date AS TIME)                          AS po_hour
       , 0                                                      AS po_totalprice_usd
       , 0                                                      AS po_totalprice_local
       , 1                                                      AS po_plataform_datasource_type_id
       , a.id                                                   AS po_plataform_datasource_order_id
       , NULL                                                   AS po_devicetype
       , ''                                                     AS po_sku_kit
       , ''                                                     AS po_prodname_kit
       , 0.00                                                   AS po_price_localcurr_kit
       , 0.00                                                   AS po_itemdiscount_localcurr_kit
       , FALSE                                                  AS is_kit
       , CASE WHEN a.subsidiary_id = 7 AND a.country IS NULL THEN 'PAN'
              WHEN a.subsidiary_id = 17 THEN 'FLA'
              WHEN a.subsidiary_id = 16 THEN 'CAR'
              ELSE a.country END                                AS country_cd
       , NULL                                                   AS biz_type_ebi_hq
       , NULL                                                   AS global_channel_ebi_hq
       , CAST(NULL AS VARCHAR(255))                             AS customer_type
       , CAST(NULL AS VARCHAR(255))                             AS po_mobile_os
       , 0                                                      AS crp
       , CURRENT_TIMESTAMP                                      AS load_date
       , CAST(NULL AS DATE)                                     AS nerp_billingdate
       , CAST(NULL AS DATE)                                     AS so_date
       , CAST(NULL AS DATE)                                     AS do_date
       , CAST(NULL AS DATE)                                     AS billing_date_local
       , CAST(NULL AS VARCHAR(255))                             AS shipping_method
       , CAST(NULL AS VARCHAR(255))                             AS delivery_mode
  FROM u_prj_ecom.ft_ecom_order                                  a
  JOIN u_prj_ecom.ft_ecom_order_item                             b ON b.order_id = a.id
  LEFT JOIN u_prj_ecom.dim_customer                              d ON d.id = a.customer_id
  JOIN u_prj_ecom.dim_subsidiary                                 e ON e.id = a.subsidiary_id
  LEFT JOIN ow_md.dim_product                                     f ON f.sku = b.reference_code
  LEFT JOIN ow_lao.dim_ods_sales_control_tower_table_status_mapping g ON g.status_origin = a.status
  WHERE a.creation_date >= TIMESTAMPADD(DAY, -180, CURRENT_DATE)
    AND a.subsidiary_id NOT IN (1, 6, 9)
    AND NOT EXISTS (
      SELECT 1
      FROM ow_lao.ods_sales_control_tower_table aa
      WHERE aa.po_orderid = a.external_order_id
        AND aa.po_sku = b.reference_code
        AND aa.country = e.country
        AND aa.po_internal_status = a.status
        AND aa.po_source_last_update_date >= a.last_update_date
    )
  GROUP BY a.creation_date
         , e.country
         , COALESCE(b.is_samsung_care, 0)
         , COALESCE(a.is_trade_in, 0)
         , a.affiliate_id
         , a.external_order_id
         , a.seller_order_id
         , a.cancellation_reason
         , f.product_group_1
         , a.cod_sales_channel
         , a.customer_id
         , a.hostname
         , a.status
         , a.invoice_number
         , a.mkt_campaign_tags
         , a.mkt_utm_campaign
         , a.mkt_utm_coupon
         , a.mkt_utm_medium
         , a.mkt_utm_src
         , a.mkt_utmi_campaign
         , a.order_sequence
         , b.reference_code
         , a.seller_id
         , a.seller_name
         , g.status
         , a.subsidiary_id
         , e.subsidiary
         , e.currency
         , a.trade_policy
         , a.vendor
         , a.acquirer_message
         , a.last_update_date
         , a.insert_date
         , a.id
         , CASE WHEN a.subsidiary_id = 7 AND a.country IS NULL THEN 'PAN'
                WHEN a.subsidiary_id = 17 THEN 'FLA'
                WHEN a.subsidiary_id = 16 THEN 'CAR'
                ELSE a.country END
         , NULL
         , NULL
  ORDER BY CAST(a.creation_date AS DATE) DESC, a.external_order_id;
  
  -- Bundles Discount
  PERFORM TRUNCATE TABLE ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom_discount;
  PERFORM INSERT INTO ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom_discount
    SELECT a.po_orderid
         , a.po_sku
         , a.country
         , a.po_sku_kit
         , CASE 
              WHEN ABS(a.po_itemdiscount_localcurr_kit) > 0.00 AND ABS(a.po_itemdiscount_localcurr) > 0.00
                THEN ROUND(
                       a.po_itemdiscount_localcurr_kit * ROUND(
                         ABS(a.po_itemdiscount_localcurr) / (
                           SUM(ABS(a.po_itemdiscount_localcurr)) OVER (PARTITION BY a.po_orderid, a.po_sku_kit)
                         )
                       , 2)
                     , 2)
              WHEN ABS(a.po_itemdiscount_localcurr_kit) > 0.00 AND ABS(a.po_itemdiscount_localcurr) = 0.00
                THEN ROUND(
                       a.po_itemdiscount_localcurr_kit * ROUND(
                         ABS(a.po_price_localcurr) / (
                           SUM(ABS(a.po_price_localcurr)) OVER (PARTITION BY a.po_orderid, a.po_sku_kit)
                         )
                       , 2)
                     , 2)
              WHEN ABS(a.po_itemdiscount_localcurr_kit) = 0.00
                THEN ABS(a.po_itemdiscount_localcurr)
              ELSE 0.00
            END AS po_itemdiscount_localcurr
    FROM ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom a
    WHERE is_kit = TRUE
    GROUP BY a.po_orderid
           , a.po_sku
           , a.country
           , a.po_sku_kit
           , a.po_itemdiscount_localcurr_kit
           , ABS(a.po_itemdiscount_localcurr)
           , a.po_price_localcurr;
  
  PERFORM UPDATE ow_lao.tmp_ods_sales_control_tower_table_bundle a
     SET po_itemdiscount_localcurr = b.po_itemdiscount_localcurr
    FROM ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom_discount b
   WHERE a.is_kit = TRUE
     AND b.country = a.country
     AND b.po_orderid = a.po_orderid
     AND b.po_sku = a.po_sku
     AND b.po_sku_kit = a.po_sku_kit;
  
  -- Bundles flag
  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom
     SET po_sku_kit = po_sku
       , is_kit     = TRUE
   WHERE po_sku LIKE '%+%'
     AND client_subsidiary_id IN (7,8,9,10,11,12,13,14,15,16,17,18,19)
     AND po_sku NOT LIKE '%+'
     AND po_sku_kit IS NULL;
  
  -- Payments staging
  PERFORM TRUNCATE TABLE ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom_payments;
  PERFORM INSERT INTO ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom_payments
    SELECT a.po_plataform_datasource_order_id
         , a.po_plataform_datasource_type_id
         , MAX(installment)                                        AS installment
         , LISTAGG(a.brand        USING PARAMETERS separator='|')::VARCHAR   AS payment_card_brand
         , LISTAGG(a.payment_type USING PARAMETERS separator='|')::VARCHAR   AS payment_type
         , LISTAGG(a.payment_type || ':' || a.brand || ':' || a.value || ':' || a.installment USING PARAMETERS separator='|')::VARCHAR AS po_payment_remark
    FROM (
      SELECT DISTINCT
             a.po_plataform_datasource_order_id
           , a.po_plataform_datasource_type_id
           , COALESCE(b.brand, '')         AS brand
           , COALESCE(b.payment_type, '')  AS payment_type
           , b.value
           , b.installment
      FROM ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom a
      JOIN u_prj_ecom.ft_ecom_order_payment b ON b.order_id = a.po_plataform_datasource_order_id
      WHERE a.po_plataform_datasource_type_id = 1
    ) a
    GROUP BY a.po_plataform_datasource_order_id, a.po_plataform_datasource_type_id;
  
  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom a
     SET installment        = b.installment
       , payment_card_brand = b.payment_card_brand
       , payment_type       = b.payment_type
       , po_payment_remark  = b.po_payment_remark
    FROM ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom_payments b
   WHERE b.po_plataform_datasource_order_id = a.po_plataform_datasource_order_id
     AND b.po_plataform_datasource_type_id  = a.po_plataform_datasource_type_id;
  
  -- Aggregations
  PERFORM TRUNCATE TABLE ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom_agg;
  PERFORM INSERT INTO ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom_agg
    SELECT country
         , po_orderid
         , SUM(po_qty)             AS po_orderqty
         , SUM(po_price_localcurr) AS po_totalprice_local
    FROM ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom
    GROUP BY country, po_orderid;
  
  PERFORM TRUNCATE TABLE ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom_sku_agg;
  PERFORM INSERT INTO ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom_sku_agg
    SELECT country
         , po_orderid
         , po_sku
         , SUM(po_qty)                    AS po_orderqty
         , SUM(po_price_localcurr)        AS po_totalprice_local
         , SUM(po_itemdiscount_localcurr) AS po_itemdiscount_localcurr
    FROM ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom
    GROUP BY country, po_orderid, po_sku;
  
  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom a
     SET po_orderqty         = b.po_orderqty,
         po_totalprice_local = (c.po_totalprice_local * c.po_orderqty) - c.po_itemdiscount_localcurr,
         po_price_localcurr  = (c.po_totalprice_local * c.po_orderqty) - c.po_itemdiscount_localcurr
  FROM ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom_agg b,
       ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom_sku_agg c
  WHERE b.country   = a.country
    AND b.po_orderid = a.po_orderid
    AND c.country    = a.country
    AND c.po_orderid = a.po_orderid
    AND c.po_sku     = a.po_sku;

  -- Exchange rate conversions
  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom a
     SET po_itemdiscount_usd = COALESCE(po_itemdiscount_localcurr / CAST(b.exchange_rate AS DECIMAL(18,6)), 0)
       , po_price_usd        = COALESCE(po_price_localcurr        / CAST(b.exchange_rate AS DECIMAL(18,6)), 0)
       , po_totalprice_usd   = COALESCE(po_totalprice_local       / CAST(b.exchange_rate AS DECIMAL(18,6)), 0)
    FROM ow_lao.ft_ap2_exchange_rate b
   WHERE b.valid_from::TIMESTAMP  = TIMESTAMPADD(DAY, -1, a.po_date)
     AND b.to_currency = a.currency;
  
  -- Sales custom
  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom a
     SET nerp_billingdate   = b.delivered_date::DATE
       , so_date            = b.invoice_date::DATE
       , do_date            = b.delivered_date::DATE
       , billing_date_local = b.delivered_date::DATE
       , po_coupon          = b.coupon_code
       , shipping_method    = b.shipping_and_handling
       , po_hour            = CAST(b.creation_date AS TIME)
    FROM ow_lao.ods_sela_custom_orders_items b
   WHERE b.order_id      = a.po_orderid
     AND b.code          = a.po_sku
     AND b.subsidiary_id = a.client_subsidiary_id
     AND b.account       = a.po_sitecode
     AND a.client_subsidiary_id IN (7, 8, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19);
  
  -- Sales channel
  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom a
     SET channel              = b.global_channel
       , biz_type             = b.biz_type
       , audience_type        = b.audience_type
       , po_storename         = b.partner_level
       , biz_type_ebi_hq      = b.biz_type_ebi
       , global_channel_ebi_hq= b.global_channel_ebi
       , customer_type        = b.customer_type
       , po_mobile_os         = b.po_mobile_os
    FROM ow_md.sales_channel b
   WHERE LOWER(b.country) = LOWER(a.country)
     AND b.sales_channel = a.po_code_sales_channel
     AND COALESCE(b.identifier,'') = a.costumer_code_id_name
     AND b.plataform_account = a.po_sitecode
     AND a.client_subsidiary_id IN (1)
     AND LOWER(b.plataform_type) = 'vtex'
     AND COALESCE(has_store_id, 'N') = 'N'
     AND COALESCE(b.identifier,'') <> '';
  
  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom a
     SET channel              = b.global_channel
       , biz_type             = b.biz_type
       , audience_type        = b.audience_type
       , po_storename         = b.partner_level
       , biz_type_ebi_hq      = b.biz_type_ebi
       , global_channel_ebi_hq= b.global_channel_ebi
       , customer_type        = b.customer_type
       , po_mobile_os         = b.po_mobile_os
    FROM ow_md.sales_channel b
   WHERE LOWER(b.country) = LOWER(a.country)
     AND b.sales_channel = a.po_code_sales_channel
     AND b.plataform_account = a.po_sitecode
     AND a.client_subsidiary_id IN (1, 8, 9)
     AND LOWER(b.plataform_type) = 'vtex'
     AND COALESCE(has_store_id, 'N') = 'N'
     AND COALESCE(b.identifier,'') = '';
  
  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom a
     SET channel              = b.global_channel
       , biz_type             = b.biz_type
       , audience_type        = b.audience_type
       , po_storename         = b.partner_level
       , biz_type_ebi_hq      = b.biz_type_ebi
       , global_channel_ebi_hq= b.global_channel_ebi
       , customer_type        = b.customer_type
       , po_mobile_os         = b.po_mobile_os
    FROM ow_md.sales_channel b
   WHERE LOWER(b.country) = LOWER(a.country)
     AND LOWER(b.identifier) = LOWER(a.po_sitecode)
     AND a.client_subsidiary_id IN (7, 8, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19)
     AND LOWER(b.plataform_type) = 'magento'
     AND COALESCE(b.sku_mapping, '') = '';
  
  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom a
     SET channel              = b.global_channel
       , biz_type             = b.biz_type
       , audience_type        = b.audience_type
       , po_storename         = (b.partner_level || '-' || b.biz_type)
       , biz_type_ebi_hq      = b.biz_type_ebi
       , global_channel_ebi_hq= b.global_channel_ebi
       , customer_type        = b.customer_type
       , po_mobile_os         = b.po_mobile_os
    FROM ow_md.sales_channel b
   WHERE LOWER(b.country) = LOWER(a.country)
     AND LOWER(b.identifier) = LOWER(a.po_sitecode)
     AND b.sku_mapping = REGEXP_SUBSTR(a.po_sku, '-[^-]*$')
     AND a.client_subsidiary_id IN (7, 8, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19)
     AND LOWER(b.plataform_type) = 'magento'
     AND COALESCE(b.sku_mapping, '') <> '';
  
  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom a
     SET channel              = b.channel
       , biz_type             = b.byz_type
       , audience_type        = b.audience_type
       , po_storename         = b.storename
       , biz_type_ebi_hq      = b.biz_type_ebi_hq
       , global_channel_ebi_hq= b.global_channel_ebi_hq
    FROM ow_lao.temp_dim_ecom_store_seasa_mkm b
   WHERE b.id = SUBSTR(a.po_orderid, 1, 6)
     AND a.client_subsidiary_id = 1
     AND a.costumer_code_id_name = 'MKM';
  
  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom a
     SET channel              = 'eStore'
       , biz_type             = '3PD'
       , audience_type        = '3PD'
       , po_storename         = 'Mercado Libre'
       , biz_type_ebi_hq      = 'B2C'
       , global_channel_ebi_hq= '3PD'
   WHERE a.po_plataform_datasource IN ('u_prj_ecom_synapcom.ft_ecom_order', 'u_prj_ecom.ft_ecom_order')
     AND a.client_subsidiary_id = 1
     AND a.costumer_code_id_name = 'MKM'
     AND a.channel IS NULL
     AND NOT EXISTS (
       SELECT 1 FROM ow_lao.temp_dim_ecom_store_seasa_mkm aa WHERE aa.id = SUBSTR(a.po_orderid, 1, 6)
     );
  
  -- mkb seasa inserted 04/07/2024
  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom a
     SET channel              = b.global_channel
       , biz_type             = b.biz_type
       , audience_type        = b.audience_type
       , po_storename         = b.partner_level
       , biz_type_ebi_hq      = b.biz_type_ebi
       , global_channel_ebi_hq= b.global_channel_ebi
    FROM ow_md.sales_channel b
   WHERE LOWER(b.country) = LOWER(a.country)
     AND COALESCE(b.identifier,'') = a.costumer_code_id_name
     AND b.plataform_account = a.po_sitecode
     AND a.client_subsidiary_id IN (1)
     AND LOWER(b.plataform_type) = 'vtex'
     AND COALESCE(has_store_id, 'N') = 'N'
     AND COALESCE(b.identifier,'') <> ''
     AND SUBSTR(a.po_orderid, 1, 3) = 'MKB';
  
  -- App Samsung device type
  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom
     SET po_devicetype = 'MOBILEAPP'
   WHERE po_sitecode IN ('samsungarapp', 'samsungarappios')
     AND client_subsidiary_id = 1;
  
  -- O2O ENDLESS AISLE
  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom a
     SET channel              = 'eStore'
       , biz_type             = 'EPP'
       , audience_type        = 'Endless Aisle'
       , po_storename         = 'Endless Aisle'
       , biz_type_ebi_hq      = 'EPP'
       , global_channel_ebi_hq= 'eStore'
    FROM U_PRJ_ECOM.FT_ECOM_ORDER b
   WHERE b.EXTERNAL_ORDER_ID = a.po_orderid
     AND a.client_subsidiary_id = 1
     AND b.ADDRESS_TYPE = 'pickup';
  
  -- Timezone adjustment
  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom a
     SET po_date = CAST(TIMESTAMPADD(SECOND, (b.timezone * 60) * 60, CAST(c.creation_date AS TIMESTAMP)) AS DATE),
         po_hour = CAST(TIMESTAMPADD(SECOND, (b.timezone * 60) * 60, CAST(c.creation_date AS TIMESTAMP)) AS TIME),
         podate_year  = EXTRACT(YEAR  FROM CAST(TIMESTAMPADD(SECOND, (b.timezone * 60) * 60, CAST(c.creation_date AS TIMESTAMP)) AS DATE)),
         podate_month = EXTRACT(MONTH FROM CAST(TIMESTAMPADD(SECOND, (b.timezone * 60) * 60, CAST(c.creation_date AS TIMESTAMP)) AS DATE))
  FROM u_prj_ecom.dim_subsidiary b,
       u_prj_ecom.ft_ecom_order c
  WHERE b.country = a.country
    AND b.order_apply_timezone = 1
    AND c.external_order_id = a.po_orderid;

  
  -- Update po_internal status Sela
  PERFORM TRUNCATE TABLE ow_lao.tmp_ecommerce_sales_control_tower_table_sela_status;
  PERFORM INSERT INTO ow_lao.tmp_ecommerce_sales_control_tower_table_sela_status
    SELECT DISTINCT
           a.po_orderid
         , b.internal_status AS po_internal_status
         , COALESCE(c.status, NULL) AS po_status
         , b.subsidiary_id AS client_subsidiary_id
    FROM ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom a
    JOIN u_prj_ecom.ft_ecom_order b ON b.external_order_id = a.po_orderid AND b.subsidiary_id = a.client_subsidiary_id
    LEFT JOIN ow_lao.dim_ods_sales_control_tower_table_status_mapping c ON c.status_origin = b.internal_status
    WHERE a.client_subsidiary_id IN (7, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19);
  
  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom a
     SET po_internal_status = b.po_internal_status
       , po_status          = b.po_status
    FROM ow_lao.tmp_ecommerce_sales_control_tower_table_sela_status b
   WHERE b.po_orderid = a.po_orderid
     AND b.client_subsidiary_id = a.client_subsidiary_id;
  
  -- CRP
  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom a
     SET CRP = 1
  FROM u_prj_ecom.dim_subsidiary b,
       ow_lao.dim_lao_crp_cs_storename c
  WHERE LOWER(c.sku_mapping) LIKE '%' || REGEXP_SUBSTR(a.po_sku, '-[^-]*$') || '%'
    AND c.subsidiary = b.subsidiary
    AND LOWER(b.country_code) = LOWER(a.country)
    AND a.crp IS NULL
    AND a.client_subsidiary_id IN (7,8,9,10,11,12,13,14,15,16,17,18,19)
    AND 1 = 0;

  
  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom
     SET CRP = 0
   WHERE CRP IS NULL
     AND client_subsidiary_id IN (7,8,9,10,11,12,13,14,15,16,17,18,19);
  
  -- TRADE_IN
  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom
     SET TRADE_IN = 1
       , TRADE_IN_ELIGIBILITY = 1
   WHERE TRADE_IN = 0
     AND po_sku LIKE '%-ECO'
     AND client_subsidiary_id IN (7,8,9,10,11,12,13,14,15,16,17,18,19);
  
  -- default po_device_type
  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom
     SET po_devicetype = 'Web'
   WHERE po_devicetype IS NULL;
  
  -- DELIVERY_MODE MAPPING
  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom a
     SET delivery_mode = b.delivery_mode
    FROM ow_lao.dim_lao_delivery_mode_mapping_control_tower b
   WHERE b.subsidiary = a.subsidiary
     AND b.shipping_method = a.shipping_method
     AND b.active = TRUE
     AND a.delivery_mode IS NULL;
  
  -- Control Tower merge
  PERFORM UPDATE ow_lao.ods_sales_control_tower_table a
       SET po_date                    = b.po_date
         , po_hour                    = b.po_hour
         , podate_year                = b.podate_year
         , podate_month               = b.podate_month
         , samsung_care_order         = b.samsung_care_order
         , samsung_care               = b.samsung_care
         , samsung_care_eligibility   = b.samsung_care_eligibility
         , trade_in                   = b.trade_in
         , trade_in_eligibility       = b.trade_in_eligibility
         , costumer_code_id_name      = b.costumer_code_id_name
         , seller_po_orderid          = b.seller_po_orderid
         , payment_card_brand         = b.payment_card_brand
         , payment_type               = b.payment_type
         , installment                = b.installment
         , installment_eligibility    = b.installment_eligibility
         , po_cancelation_reason      = b.po_cancelation_reason
         , po_productgroup            = b.po_productgroup
         , po_code_sales_channel      = b.po_code_sales_channel
         , po_costumer_id             = b.po_costumer_id
         , po_sitecode                = b.po_sitecode
         , po_internal_status         = b.po_internal_status
         , po_invoicenumber           = b.po_invoicenumber
         , po_campain_tags            = b.po_campain_tags
         , po_campain                 = b.po_campain
         , po_coupon                  = b.po_coupon
         , po_medium                  = b.po_medium
         , po_src                     = b.po_src
         , po_utmi_campaing           = b.po_utmi_campaing
         , po_prodname                = b.po_prodname
         , po_seller_id               = b.po_seller_id
         , po_seller_name             = b.po_seller_name
         , po_status                  = b.po_status
         , client_subsidiary_id       = b.client_subsidiary_id
         , subsidiary                 = b.subsidiary
         , currency                   = b.currency
         , po_tradepolicy             = b.po_tradepolicy
         , po_vendortype              = b.po_vendortype
         , channel                    = b.channel
         , biz_type                   = b.biz_type
         , audience_type              = b.audience_type
         , po_storename               = b.po_storename
         , client_acquirer_message    = b.client_acquirer_message
         , po_lastupdate_date_hour    = b.po_lastupdate_date_hour
         , po_orderqty                = b.po_orderqty
         , po_qty                     = b.po_qty
         , po_itemdiscount_localcurr  = b.po_itemdiscount_localcurr
         , po_itemdiscount_usd        = b.po_itemdiscount_usd
         , po_price_localcurr         = b.po_price_localcurr
         , po_price_usd               = b.po_price_usd
         , po_plataform_datasource    = b.po_plataform_datasource
         , po_source_insert_date      = b.po_source_insert_date
         , po_source_last_update_date = b.po_source_last_update_date
         , po_insert_date             = b.po_insert_date
         , po_last_update_date        = b.po_last_update_date
         , po_payment_remark          = b.po_payment_remark
         , po_totalprice_usd          = b.po_totalprice_usd
         , po_totalprice_local        = b.po_totalprice_local
         , po_devicetype              = b.po_devicetype
         , updated_datetime           = CURRENT_TIMESTAMP
         , po_sku_kit                 = b.po_sku_kit
         , po_prodname_kit            = b.po_prodname_kit
         , is_kit                     = b.is_kit
         , country_cd                 = b.country_cd
         , biz_type_ebi_hq            = b.biz_type_ebi_hq
         , global_channel_ebi_hq      = b.global_channel_ebi_hq
         , customer_type              = b.customer_type
         , po_mobile_os               = b.po_mobile_os
         , nerp_billingdate           = b.nerp_billingdate
         , so_date                    = b.so_date
         , do_date                    = b.do_date
         , billing_date_local         = b.billing_date_local
         , shipping_method            = b.shipping_method
         , delivery_mode              = b.delivery_mode
    FROM ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom b
    WHERE b.po_orderid = a.po_orderid
      AND b.po_sku     = a.po_sku
      AND b.country    = a.country
      AND b.po_sku_kit = a.po_sku_kit;

  PERFORM INSERT INTO ow_lao.ods_sales_control_tower_table (
           po_date
         , po_hour
         , podate_year
         , podate_month
         , country
         , samsung_care_order
         , samsung_care
         , samsung_care_eligibility
         , trade_in
         , trade_in_eligibility
         , costumer_code_id_name
         , po_orderid
         , seller_po_orderid
         , payment_card_brand
         , payment_type
         , installment
         , installment_eligibility
         , po_cancelation_reason
         , po_productgroup
         , po_code_sales_channel
         , po_costumer_id
         , po_sitecode
         , po_internal_status
         , po_invoicenumber
         , po_campain_tags
         , po_campain
         , po_coupon
         , po_medium
         , po_src
         , po_utmi_campaing
         , po_sequence_orderid
         , po_prodname
         , po_sku
         , po_seller_id
         , po_seller_name
         , po_status
         , client_subsidiary_id
         , subsidiary
         , currency
         , po_tradepolicy
         , po_vendortype
         , channel
         , biz_type
         , audience_type
         , po_storename
         , client_acquirer_message
         , po_lastupdate_date_hour
         , po_orderqty
         , po_qty
         , po_itemdiscount_localcurr
         , po_itemdiscount_usd
         , po_price_localcurr
         , po_price_usd
         , po_plataform_datasource
         , po_source_insert_date
         , po_source_last_update_date
         , po_insert_date
         , po_last_update_date
         , po_payment_remark
         , po_totalprice_usd
         , po_totalprice_local
         , po_devicetype
         , po_sku_kit
         , po_prodname_kit
         , is_kit
         , country_cd
         , biz_type_ebi_hq
         , global_channel_ebi_hq
         , customer_type
         , po_mobile_os
         , nerp_billingdate
         , so_date
         , do_date
         , billing_date_local
         , shipping_method
         , delivery_mode
    )
    SELECT 
           b.po_date
         , b.po_hour
         , b.podate_year
         , b.podate_month
         , b.country
         , b.samsung_care_order
         , b.samsung_care
         , b.samsung_care_eligibility
         , b.trade_in
         , b.trade_in_eligibility
         , b.costumer_code_id_name
         , b.po_orderid
         , b.seller_po_orderid
         , b.payment_card_brand
         , b.payment_type
         , b.installment
         , b.installment_eligibility
         , b.po_cancelation_reason
         , b.po_productgroup
         , b.po_code_sales_channel
         , b.po_costumer_id
         , b.po_sitecode
         , b.po_internal_status
         , b.po_invoicenumber
         , b.po_campain_tags
         , b.po_campain
         , b.po_coupon
         , b.po_medium
         , b.po_src
         , b.po_utmi_campaing
         , b.po_sequence_orderid
         , b.po_prodname
         , b.po_sku
         , b.po_seller_id
         , b.po_seller_name
         , b.po_status
         , b.client_subsidiary_id
         , b.subsidiary
         , b.currency
         , b.po_tradepolicy
         , b.po_vendortype
         , b.channel
         , b.biz_type
         , b.audience_type
         , b.po_storename
         , b.client_acquirer_message
         , b.po_lastupdate_date_hour
         , b.po_orderqty
         , b.po_qty
         , b.po_itemdiscount_localcurr
         , b.po_itemdiscount_usd
         , b.po_price_localcurr
         , b.po_price_usd
         , b.po_plataform_datasource
         , b.po_source_insert_date
         , b.po_source_last_update_date
         , b.po_insert_date
         , b.po_last_update_date
         , b.po_payment_remark
         , b.po_totalprice_usd
         , b.po_totalprice_local
         , b.po_devicetype
         , b.po_sku_kit
         , b.po_prodname_kit
         , b.is_kit
         , b.country_cd
         , b.biz_type_ebi_hq
         , b.global_channel_ebi_hq
         , b.customer_type
         , b.po_mobile_os
         , b.nerp_billingdate
         , b.so_date
         , b.do_date
         , b.billing_date_local
         , b.shipping_method
         , b.delivery_mode
    FROM ow_lao.tmp_ecommerce_sales_control_tower_table_u_prj_ecom b
    LEFT JOIN ow_lao.ods_sales_control_tower_table a
           ON b.po_orderid = a.po_orderid
          AND b.po_sku     = a.po_sku
          AND b.country    = a.country
          AND b.po_sku_kit = a.po_sku_kit
    WHERE a.po_orderid IS NULL;


END;
$$;
