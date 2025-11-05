CREATE OR REPLACE PROCEDURE OW_LAO.proc_ods_sales_control_tower_table_RAW_VTEX_SSG_UY_SALES_ORDER()
 LANGUAGE PLvSQL AS $$
BEGIN
 
  PERFORM TRUNCATE TABLE ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_uy_sales_order;
 
  PERFORM INSERT INTO ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_uy_sales_order
SELECT
    CAST(TIMESTAMPADD(SECOND, -10800, a.creation_date) AS DATE) AS po_date,
    EXTRACT(YEAR FROM CAST(TIMESTAMPADD(SECOND, -10800, a.creation_date) AS DATE)) AS podate_year,
    EXTRACT(MONTH FROM CAST(TIMESTAMPADD(SECOND, -10800, a.creation_date) AS DATE)) AS podate_month,
    'Uruguay' AS country,
    0 AS samsung_care_order,
    0 AS samsung_care,
    0 AS samsung_care_eligibility,
    0 AS trade_in,
    0 AS trade_in_eligibility,
    0 AS trade_up,
    0 AS trade_up_eligibility,
    a.affiliate_id AS costumer_code_id_name,
    a.order_id AS po_orderid,
    a.seller_order_id AS seller_po_orderid,
    CAST(NULL AS VARCHAR(3000)) AS payment_card_brand,
    CAST(NULL AS VARCHAR(3000)) AS payment_type,
    0 AS installment,
    NULL AS installment_eligibility,
    a.cancellation_reason AS po_cancelation_reason,
    c.product_group_1 AS po_productgroup,
    a.sales_channel AS po_code_sales_channel,
    NULL AS po_costumer_id,
    a.hostname AS po_sitecode,
    a.status AS po_internal_status,
    NULL AS po_invoicenumber,
    a.marketing_tags AS po_campain_tags,
    a.utm_campaign AS po_campain,
    a.coupon AS po_coupon,
    a.utm_medium AS po_medium,
    a.utm_source AS po_src,
    a.utmi_campaign AS po_utmi_campaing,
    a.sequence AS po_sequence_orderid,
    b.name AS po_prodname,
    COALESCE(b.ref_id, b.name) AS po_sku,
    REPLACE(REPLACE(a.seller_id, '["',''), '"]','') AS po_seller_id,
    REPLACE(REPLACE(a.seller_name, '["',''), '"]','') AS po_seller_name,
    d.status AS po_status,
    9 AS client_subsidiary_id,
    'SELA-UY' AS subsidiary,
    'UYU' AS currency,
    NULL AS po_tradepolicy,
    a.origin AS po_vendortype,
    CAST(NULL AS VARCHAR(255)) AS channel,
    CAST(NULL AS VARCHAR(255)) AS biz_type,
    CAST(NULL AS VARCHAR(255)) AS audience_type,
    CAST(NULL AS VARCHAR(255)) AS po_storename,
    CAST(NULL AS VARCHAR(255)) AS client_acquirer_message,
    a.creation_timestamp AS po_lastupdate_date_hour,
    0 AS po_orderqty,
    SUM(b.quantity) AS po_qty,
    SUM(b.price - b.selling_price) / 100.00 AS po_itemdiscount_localcurr,
    0.00 AS po_itemdiscount_usd,
    SUM(b.price / 100.00) AS po_price_localcurr,
    0.00 AS po_price_usd,
    'u_prj_ecom.raw_vtex_ssg_uy_sales_order' AS po_plataform_datasource,
    a.created_at AS po_source_insert_date,
    a.creation_timestamp AS po_source_last_update_date,
    CURRENT_TIMESTAMP AS po_insert_date,
    NULL AS po_last_update_date,
    CAST(NULL AS VARCHAR(3000)) AS po_payment_remark,
    CAST(TIMESTAMPADD(SECOND, -10800, a.creation_date) AS TIME) AS po_hour,
    0.00 AS po_totalprice_usd,
    0.00 AS po_totalprice_local,
    CAST(NULL AS VARCHAR(255)) AS po_devicetype,
    CAST('' AS VARCHAR(255)) AS po_sku_kit,
    CAST('' AS VARCHAR(255)) AS po_prodname_kit,
    CAST(0.00 AS DECIMAL(18,2)) AS po_price_localcurr_kit,
    CAST(0.00 AS DECIMAL(18,2)) AS po_itemdiscount_localcurr_kit,
    FALSE AS is_kit,
    'URY' AS country_cd,
    CAST(NULL AS VARCHAR(255)) AS biz_type_ebi_hq,
    CAST(NULL AS VARCHAR(255)) AS global_channel_ebi_hq,
    CAST(NULL AS VARCHAR(255)) AS customer_type,
    CAST(NULL AS VARCHAR(255)) AS po_mobile_os
FROM u_prj_ecom.raw_vtex_ssg_uy_sales_order a
JOIN u_prj_ecom.raw_vtex_ssg_uy_sales_order_item b ON b.order_id = a.order_id
LEFT JOIN ow_md.dim_product c ON c.sku = b.ref_id
LEFT JOIN ow_lao.dim_ods_sales_control_tower_table_status_mapping d ON d.status_origin = COALESCE(a.status, 'incomplete')
WHERE a.creation_timestamp >= TIMESTAMPADD(DAY, -3, CURRENT_DATE)
  AND NOT EXISTS (
    SELECT 1
    FROM ow_lao.ods_sales_control_tower_table aa
    WHERE aa.po_orderid = a.order_id
      AND aa.po_sku = b.ref_id
      AND aa.country = 'Uruguay'
      AND aa.po_internal_status = COALESCE(a.status, 'incomplete')
      AND aa.po_source_last_update_date >= CAST(a.creation_timestamp AS TIMESTAMP)
  )
GROUP BY a.creation_date, a.affiliate_id, a.order_id, a.seller_order_id, a.cancellation_reason, c.product_group_1, a.sales_channel, a.hostname, a.status, a.marketing_tags, a.utm_campaign, a.coupon, a.utm_medium, a.utm_source, a.utmi_campaign, 
a.sequence, b.name, b.ref_id, a.seller_id, a.seller_name, d.status, a.created_at, a.creation_timestamp, a.origin;


                 
  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_uy_sales_order
     SET samsung_care = 1
   WHERE UPPER(po_prodname) LIKE UPPER('%samsung care%');
                 
  PERFORM TRUNCATE TABLE ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_uy_sales_payments;

  PERFORM INSERT INTO ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_uy_sales_payments
    (po_orderid, installment, payment_card_brand, payment_type, po_payment_remark)
  SELECT
      a.po_orderid,
      MAX(a.installments) AS installment,
      CAST(LISTAGG(a.brand USING PARAMETERS separator='|') AS VARCHAR(65000)) AS payment_card_brand,
      CAST(LISTAGG(a.payment_type USING PARAMETERS separator='|') AS VARCHAR(65000)) AS payment_type,
      CAST(LISTAGG(a.payment_type || ':' || a.brand || ':' || (a.value / 100.00)::VARCHAR || ':' || a.installments::VARCHAR USING PARAMETERS separator='|') AS VARCHAR(65000)) AS po_payment_remark
  FROM (
      SELECT DISTINCT
             a.po_orderid,
             CASE COALESCE(b.payment_group, '')
               WHEN '' THEN ''
               ELSE COALESCE(b.payment_system_name, '')
             END AS brand,
             COALESCE(b.payment_group, '') AS payment_type,
             b.value,
             CASE WHEN b.installments IS NULL THEN 1 ELSE b.installments END AS installments
      FROM ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_uy_sales_order a
      JOIN u_prj_ecom.raw_vtex_ssg_uy_sales_order_payment b ON b.order_id = a.po_orderid
  ) a
  GROUP BY a.po_orderid;
        
  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_uy_sales_order a
     SET installment        = b.installment,
         payment_card_brand = b.payment_card_brand,
         payment_type       = b.payment_type,
         po_payment_remark  = b.po_payment_remark
    FROM ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_uy_sales_payments b
   WHERE b.po_orderid = a.po_orderid;        
 
  PERFORM TRUNCATE TABLE ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_uy_sales_order_agg;
  
  PERFORM INSERT INTO ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_uy_sales_order_agg
    (country, po_orderid, po_orderqty, po_totalprice_local)
  SELECT country,
         po_orderid,
         SUM(po_qty) AS po_orderqty,
         SUM(po_price_localcurr) AS po_totalprice_local
  FROM ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_uy_sales_order   
  GROUP BY country, po_orderid;        
         
  PERFORM TRUNCATE TABLE ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_uy_sales_order_sku_agg;
  
  PERFORM INSERT INTO ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_uy_sales_order_sku_agg
    (country, po_orderid, po_sku, po_orderqty, po_totalprice_local, po_itemdiscount_localcurr)
  SELECT country,
         po_orderid,
         po_sku,
         SUM(po_qty)                    AS po_orderqty,
         SUM(po_price_localcurr)        AS po_totalprice_local,
         SUM(po_itemdiscount_localcurr) AS po_itemdiscount_localcurr
  FROM ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_uy_sales_order   
  GROUP BY country, po_orderid, po_sku;        
       
PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_uy_sales_order a
   SET po_orderqty         = b.po_orderqty,
       po_totalprice_local = (c.po_totalprice_local * c.po_orderqty) - c.po_itemdiscount_localcurr,
       po_price_localcurr  = (c.po_totalprice_local * c.po_orderqty) - c.po_itemdiscount_localcurr
  FROM ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_uy_sales_order_agg b,
       ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_uy_sales_order_sku_agg c
 WHERE a.country    = b.country
   AND a.po_orderid = b.po_orderid
   AND a.country    = c.country
   AND a.po_orderid = c.po_orderid
   AND a.po_sku     = c.po_sku;
  


  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_uy_sales_order a
     SET po_itemdiscount_usd = COALESCE (a.po_itemdiscount_localcurr / CAST(b.exchange_rate AS DECIMAL(18,6)),0),
         po_price_usd        = COALESCE (a.po_price_localcurr        / CAST(b.exchange_rate AS DECIMAL(18,6)),0),
         po_totalprice_usd   = COALESCE (a.po_totalprice_local       / CAST(b.exchange_rate AS DECIMAL(18,6)),0)
    FROM ow_lao.ft_ap2_exchange_rate                                          b
 --  WHERE b.valid_from  = TIMESTAMPADD(DAY, -1, a.po_date) erro aqui 
 WHERE b.valid_from  = TO_CHAR(TIMESTAMPADD(DAY, -1, CAST(a.po_date AS TIMESTAMP)), 'YYYY-MM-DD')
     AND b.to_currency = a.currency;   
  
  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_uy_sales_order a
     SET channel               = b.global_channel,
         biz_type              = b.biz_type,
         audience_type         = b.audience_type,
         po_storename          = b.partner_level,
         biz_type_ebi_hq       = b.biz_type_ebi,
         global_channel_ebi_hq = b.global_channel_ebi,
         customer_type         = b.customer_type,
         po_mobile_os          = b.po_mobile_os
    FROM ow_md.sales_channel                                                  b
   WHERE LOWER(b.country)     = LOWER(a.country)
     AND b.sales_channel      = a.po_code_sales_channel
     AND b.plataform_account  = a.po_sitecode
     AND a.client_subsidiary_id IN (9)
     AND LOWER(b.plataform_type)     = 'vtex'
     AND COALESCE(b.has_store_id, 'N') = 'N'
     AND COALESCE(b.identifier,'')   = '';                    
             
  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_uy_sales_order
     SET po_devicetype = 'Web'
   WHERE po_devicetype IS NULL
     AND client_subsidiary_id = 1;  
             
-- aqui tinha um MERGER SUBSTITUI POR UM INSERT E INTO

PERFORM UPDATE ow_lao.ods_sales_control_tower_table a
   SET po_date = b.po_date,
       po_hour = b.po_hour,
       podate_year = b.podate_year,
       podate_month = b.podate_month,
       samsung_care_order = b.samsung_care_order,
       samsung_care = b.samsung_care,
       samsung_care_eligibility = b.samsung_care_eligibility,
       trade_in = b.trade_in,
       trade_in_eligibility = b.trade_in_eligibility,
       costumer_code_id_name = b.costumer_code_id_name,
       seller_po_orderid = b.seller_po_orderid,
       payment_card_brand = b.payment_card_brand,
       payment_type = b.payment_type,
       installment = b.installment,
       installment_eligibility = b.installment_eligibility,
       po_cancelation_reason = b.po_cancelation_reason,
       po_productgroup = b.po_productgroup,
       po_code_sales_channel = b.po_code_sales_channel,
       po_costumer_id = b.po_costumer_id,
       po_sitecode = b.po_sitecode,
       po_internal_status = b.po_internal_status,
       po_invoicenumber = b.po_invoicenumber,
       po_campain_tags = b.po_campain_tags,
       po_campain = b.po_campain,
       po_coupon = b.po_coupon,
       po_medium = b.po_medium,
       po_src = b.po_src,
       po_utmi_campaing = b.po_utmi_campaing,
       po_prodname = b.po_prodname,
       po_seller_id = b.po_seller_id,
       po_seller_name = b.po_seller_name,
       po_status = b.po_status,
       client_subsidiary_id = b.client_subsidiary_id,
       subsidiary = b.subsidiary,
       currency = b.currency,
       po_tradepolicy = b.po_tradepolicy,
       po_vendortype = b.po_vendortype,
       channel = b.channel,
       biz_type = b.biz_type,
       audience_type = b.audience_type,
       po_storename = b.po_storename,
       client_acquirer_message = b.client_acquirer_message,
       po_lastupdate_date_hour = b.po_lastupdate_date_hour,
       po_orderqty = b.po_orderqty,
       po_qty = b.po_qty,
       po_itemdiscount_localcurr = b.po_itemdiscount_localcurr,
       po_itemdiscount_usd = b.po_itemdiscount_usd,
       po_price_localcurr = b.po_price_localcurr,
       po_price_usd = b.po_price_usd,
       po_plataform_datasource = b.po_plataform_datasource,
       po_source_insert_date = b.po_source_insert_date,
       po_source_last_update_date = b.po_source_last_update_date,
       po_insert_date = b.po_insert_date,
       po_last_update_date = b.po_last_update_date,
       po_payment_remark = b.po_payment_remark,
       po_totalprice_usd = b.po_totalprice_usd,
       po_totalprice_local = b.po_totalprice_local,
       po_devicetype = b.po_devicetype,
       updated_datetime = CURRENT_TIMESTAMP,
       po_sku_kit = b.po_sku_kit,
       po_prodname_kit = b.po_prodname_kit,
       is_kit = b.is_kit,
       country_cd = b.country_cd,
       biz_type_ebi_hq = b.biz_type_ebi_hq,
       global_channel_ebi_hq = b.global_channel_ebi_hq,
       customer_type = b.customer_type,
       po_mobile_os = b.po_mobile_os
  FROM ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_uy_sales_order b
 WHERE a.po_orderid = b.po_orderid
   AND a.po_sku = b.po_sku
   AND a.country = b.country
   AND a.po_sku_kit = b.po_sku_kit;


PERFORM INSERT INTO ow_lao.ods_sales_control_tower_table (
  po_date, po_hour, podate_year, podate_month, country, samsung_care_order, samsung_care,
  samsung_care_eligibility, trade_in, trade_in_eligibility, costumer_code_id_name, po_orderid,
  seller_po_orderid, payment_card_brand, payment_type, installment, installment_eligibility,
  po_cancelation_reason, po_productgroup, po_code_sales_channel, po_costumer_id, po_sitecode,
  po_internal_status, po_invoicenumber, po_campain_tags, po_campain, po_coupon, po_medium,
  po_src, po_utmi_campaing, po_sequence_orderid, po_prodname, po_sku, po_seller_id,
  po_seller_name, po_status, client_subsidiary_id, subsidiary, currency, po_tradepolicy,
  po_vendortype, channel, biz_type, audience_type, po_storename, client_acquirer_message,
  po_lastupdate_date_hour, po_orderqty, po_qty, po_itemdiscount_localcurr, po_itemdiscount_usd,
  po_price_localcurr, po_price_usd, po_plataform_datasource, po_source_insert_date,
  po_source_last_update_date, po_insert_date, po_last_update_date, po_payment_remark,
  po_totalprice_usd, po_totalprice_local, po_devicetype, po_sku_kit, po_prodname_kit, is_kit,
  country_cd, biz_type_ebi_hq, global_channel_ebi_hq, customer_type, po_mobile_os
)
SELECT
  b.po_date, b.po_hour, b.podate_year, b.podate_month, b.country, b.samsung_care_order, b.samsung_care,
  b.samsung_care_eligibility, b.trade_in, b.trade_in_eligibility, b.costumer_code_id_name, b.po_orderid,
  b.seller_po_orderid, b.payment_card_brand, b.payment_type, b.installment, b.installment_eligibility,
  b.po_cancelation_reason, b.po_productgroup, b.po_code_sales_channel, b.po_costumer_id, b.po_sitecode,
  b.po_internal_status, b.po_invoicenumber, b.po_campain_tags, b.po_campain, b.po_coupon, b.po_medium,
  b.po_src, b.po_utmi_campaing, b.po_sequence_orderid, b.po_prodname, b.po_sku, b.po_seller_id,
  b.po_seller_name, b.po_status, b.client_subsidiary_id, b.subsidiary, b.currency, b.po_tradepolicy,
  b.po_vendortype, b.channel, b.biz_type, b.audience_type, b.po_storename, b.client_acquirer_message,
  b.po_lastupdate_date_hour, b.po_orderqty, b.po_qty, b.po_itemdiscount_localcurr, b.po_itemdiscount_usd,
  b.po_price_localcurr, b.po_price_usd, b.po_plataform_datasource, b.po_source_insert_date,
  b.po_source_last_update_date, b.po_insert_date, b.po_last_update_date, b.po_payment_remark,
  b.po_totalprice_usd, b.po_totalprice_local, b.po_devicetype, b.po_sku_kit, b.po_prodname_kit, b.is_kit,
  b.country_cd, b.biz_type_ebi_hq, b.global_channel_ebi_hq, b.customer_type, b.po_mobile_os
FROM ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_uy_sales_order b
LEFT JOIN ow_lao.ods_sales_control_tower_table a
  ON a.po_orderid = b.po_orderid
 AND a.po_sku = b.po_sku
 AND a.country = b.country
 AND a.po_sku_kit = b.po_sku_kit
WHERE a.po_orderid IS NULL;

 
END
$$;


