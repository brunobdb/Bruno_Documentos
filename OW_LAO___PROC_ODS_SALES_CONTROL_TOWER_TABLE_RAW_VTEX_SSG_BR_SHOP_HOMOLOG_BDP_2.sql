CREATE OR REPLACE PROCEDURE OW_LAO.proc_ods_sales_control_tower_table_raw_vtex_ssg_br_shop_homolog_BDP_2()
LANGUAGE PLvSQL AS $$
BEGIN
  
  PERFORM TRUNCATE TABLE ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_br_shop_homolog_2;

  PERFORM INSERT INTO ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_br_shop_homolog_2
  SELECT  
    CAST(a.creation_timestamp AS DATE)                                      AS po_date,
    EXTRACT(YEAR FROM a.creation_timestamp)                                  AS podate_year,
    EXTRACT(MONTH FROM a.creation_timestamp)                                 AS podate_month,
    'Brazil'                                                                 AS country,
    0                                                                        AS samsung_care_order,
    0                                                                        AS samsung_care,
    0                                                                        AS samsung_care_eligibility,
    0                                                                        AS trade_in,
    0                                                                        AS trade_in_eligibility,
    0                                                                        AS trade_up,
    0                                                                        AS trade_up_eligibility ,
    a.affiliate_id                                                           AS costumer_code_id_name,
    a.order_id                                                               AS po_orderid,
    a.seller_order_id                                                        AS seller_po_orderid,
    CAST(NULL AS VARCHAR(3000))                                              AS payment_card_brand,
    CAST(NULL AS VARCHAR(3000))                                              AS payment_type,
    0                                                                        AS installment,
    NULL                                                                     AS installment_eligibility,
    a.cancellation_reason                                                    AS po_cancelation_reason,
    e.product_group_1                                                        AS po_productgroup,
    a.sales_channel                                                          AS po_code_sales_channel,
    NULL                                                                     AS po_costumer_id,
    a.hostname                                                               AS po_sitecode,
    a.status                                                                 AS po_internal_status,
    NULL                                                                     AS po_invoicenumber,
    a.marketing_tags                                                         AS po_campain_tags,
    a.utm_campaign                                                           AS po_campain,
    a.coupon                                                                 AS po_coupon,
    a.utm_medium                                                             AS po_medium,
    a.utm_source                                                             AS po_src,
    a.utmi_campaign                                                          AS po_utmi_campaing,
    a.sequence                                                               AS po_sequence_orderid,
    b.name                                                                   AS po_prodname,
    COALESCE (C.REF_ID_KIT, b.REF_ID)                                        AS po_sku ,
    a.seller_id                                                              AS po_seller_id,
    a.seller_name                                                            AS po_seller_name,
    f.status                                                                 AS po_status,
    6                                                                        AS client_subsidiary_id,
    'SEDA'                                                                   AS subsidiary,
    'BRL'                                                                    AS currency,
    NULL                                                                     AS po_tradepolicy,
    a.origin                                                                 AS po_vendortype  ,     
    CAST(NULL AS VARCHAR(255))                                               AS channel,
    CAST(NULL AS VARCHAR(255))                                               AS biz_type,
    CAST(NULL AS VARCHAR(255))                                               AS audience_type,
    CAST(NULL AS VARCHAR(255))                                               AS po_storename,
    CAST(NULL AS VARCHAR(255))                                               AS client_acquirer_message,
    a.updated_at                                                             AS po_lastupdate_date_hour,
    0                                                                        AS po_orderqty,
    COALESCE (C.QUANTITY_KIT, b.QUANTITY)                                    AS po_qty,
    (D.PRICE_SHIPPING/ D.NUM_ROWS)                                           AS po_price_shipping,  
    COALESCE (C.DISCOUNT_KIT, b.DISCOUNT)                                    AS po_itemdiscount_localcurr,
    0                                                                        AS po_itemdiscount_usd,
    COALESCE (C.PRICE_KIT, b.PRICE)                                          AS po_price_localcurr ,
    0                                                                        AS po_price_usd,
    'u_prj_ecom.raw_vtex_ssg_br_shop_sales_order'                            AS po_plataform_datasource,
    a.created_at                                                             AS po_source_insert_date,
    a.updated_at                                                             AS po_source_last_update_date,
    CURRENT_TIMESTAMP                                                        AS po_insert_date,
    NULL                                                                     AS po_last_update_date,
    CAST(NULL AS VARCHAR(3000))                                              AS po_payment_remark,
    CAST(a.creation_timestamp AS TIME)                                       AS po_hour ,
    0                                                                        AS po_totalprice_usd,
    0                                                                        AS po_totalprice_local,
    CAST(NULL AS VARCHAR(255))                                               AS po_devicetype,
    C.REF_ID                                                                 AS po_sku_kit,
    C.NAME                                                                   AS po_prodname_kit,
    CAST(0.00 AS NUMERIC(18,2))                                              AS po_price_localcurr_kit,
    CAST(0.00 AS NUMERIC(18,2))                                              AS po_itemdiscount_localcurr_kit,
    COALESCE(c.is_kit, FALSE)                                                AS is_kit ,
    'BRA'                                                                    AS country_cd,
    CAST(NULL AS VARCHAR(255))                                               AS biz_type_ebi_hq,
    CAST(NULL AS VARCHAR(255))                                               AS global_channel_ebi_hq,
    D.selected_sla                                                           AS shipping_method
  FROM U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER   a 
  JOIN 
  (
    SELECT 
      ORDER_ID,
      item_index ,
      UNIQUE_ID,
      name , 
      SKU_ID,
      REF_ID, 
      PRICE/100 AS PRICE, 
      QUANTITY,
      (PRICE - SELLING_PRICE)/100 * QUANTITY AS DISCOUNT
    FROM U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER_item 
  ) b ON b.ORDER_ID = a.ORDER_ID 
  LEFT JOIN 
  (
    SELECT
      A.ORDER_ID,
      A.UNIQUE_ID,
      A.SKU_ID,
      B.REF_ID, 
      A.REF_ID AS REF_ID_KIT, 
      A.NAME,
      A.PRICE/100 AS PRICE_KIT, 
      b.QUANTITY* a.QUANTITY AS QUANTITY_KIT,
      TRUE                   as is_kit, 
      (A.PRICE - A.SELLING_PRICE)/100 * (b.QUANTITY* a.QUANTITY) AS DISCOUNT_KIT
    FROM U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER_ITEM_COMPONENTS A
    JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER_item b       
      ON  b.ORDER_ID  = a.ORDER_ID 
      AND b.UNIQUE_ID = a.UNIQUE_ID   
      AND b.SKU_ID    = a.SKU_ID
  ) C 
    ON C.ORDER_ID =  A.ORDER_ID 
   AND C.UNIQUE_ID = B.UNIQUE_ID   
   AND C.SKU_ID    = B.SKU_ID
  LEFT JOIN 
  (  SELECT 
        A.ORDER_ID,
        B.ITEM_INDEX,
        D.PRICE/100 AS PRICE_SHIPPING,
        C.UNIQUE_ID, 
        C.SKU_ID, 
        D.SELECTED_SLA ,
        COUNT(*) AS NUM_ROWS
      FROM U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER A
      JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER_ITEM B 
        ON B.ORDER_ID = A.ORDER_ID
      LEFT JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER_ITEM_COMPONENTS C 
        ON  C.ORDER_ID  = A.ORDER_ID 
        AND C.UNIQUE_ID = B.UNIQUE_ID 
        AND C.SKU_ID    = B.SKU_ID
      LEFT JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER_SHIPPING D
        ON D.ORDER_ID   = A.ORDER_ID
       AND D.ITEM_INDEX = B.ITEM_INDEX   
      GROUP BY 
        A.ORDER_ID,
        B.ITEM_INDEX,
        D.PRICE,
        C.UNIQUE_ID, 
        C.SKU_ID,
        D.SELECTED_SLA 
  ) D ON D.ORDER_ID   = A.ORDER_ID
      AND D.ITEM_INDEX = B.ITEM_INDEX 
  LEFT JOIN ow_md.dim_product     e   ON e.sku = COALESCE (C.REF_ID_KIT, b.REF_ID)
  LEFT JOIN ow_lao.dim_ods_sales_control_tower_table_status_mapping f
       ON f.status_origin = COALESCE(a.status, 'incomplete')
  WHERE CAST (a.CREATION_TIMESTAMP AS DATE) >= '2025-05-01';

  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_br_shop_homolog_2
    SET po_totalprice_local = ROUND(
        COALESCE(po_price_localcurr, 0) * COALESCE(po_qty, 0) 
        - COALESCE(po_itemdiscount_localcurr, 0) 
        + COALESCE(po_price_shipping, 0),
        5);

  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_br_shop_homolog_2
    SET samsung_care = 1
    WHERE UPPER(po_prodname) LIKE '%SAMSUNG CARE%';

  PERFORM CREATE LOCAL TEMPORARY TABLE tmp_payments_homolog_2 ON COMMIT PRESERVE ROWS AS
    SELECT a.po_orderid
         , MAX(a.installments)                                             AS installment
         , LISTAGG(a.brand      USING PARAMETERS separator='|')            AS payment_card_brand
         , LISTAGG(a.payment_type USING PARAMETERS separator='|')          AS payment_type
         , LISTAGG(
              a.payment_type || ':' || a.brand || ':' || (a.value / 100.00)::VARCHAR || ':' || a.installments::VARCHAR
              USING PARAMETERS separator='|'
           )                                                               AS po_payment_remark
      FROM (
              SELECT DISTINCT
                     a.po_orderid
                   , CASE COALESCE(b.payment_group, '')
                        WHEN '' THEN ''
                        ELSE COALESCE(b.payment_system_name, '')
                     END                                   AS brand
                   , COALESCE(b.payment_group      , '')   AS payment_type
                   , b.value
                   , CASE WHEN b.installments IS NULL THEN 1 ELSE b.installments END AS installments
                FROM ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_br_shop_homolog_2 a  
                JOIN u_prj_ecom.raw_vtex_ssg_br_shop_sales_order_payment           b 
                  ON b.order_id = a.po_orderid
           ) a
     GROUP BY a.po_orderid;

  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_br_shop_homolog_2 a
     SET installment        = b.installment,
         payment_card_brand = b.payment_card_brand,
         payment_type       = b.payment_type,
         po_payment_remark  = b.po_payment_remark
    FROM tmp_payments_homolog_2 b
   WHERE b.po_orderid = a.po_orderid;        
 
  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_br_shop_homolog_2  a
     SET po_itemdiscount_usd = ROUND(COALESCE (a.po_itemdiscount_localcurr / CAST(b.exchange_rate AS NUMERIC),0),2),
         po_price_usd        = ROUND(COALESCE (a.po_price_localcurr        / CAST(b.exchange_rate AS NUMERIC),0),2),
         po_totalprice_usd   = ROUND(COALESCE (a.po_totalprice_local       / CAST(b.exchange_rate AS NUMERIC),0),2)
    FROM ow_lao.ft_ap2_exchange_rate b 
   WHERE b.valid_from  = TIMESTAMPADD(DAY, -1, a.po_date)
     AND b.to_currency = a.currency;   

  PERFORM UPDATE  ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_br_shop_homolog_2 a
     SET a.channel               = b.global_channel,
         a.biz_type              = b.biz_type,
         a.audience_type         = b.audience_type,
         a.po_storename          = b.partner_level,
         a.biz_type_ebi_hq       = b.biz_type_ebi,
         a.global_channel_ebi_hq = b.global_channel_ebi
    FROM  ow_md.sales_channel b
   WHERE LOWER(b.country)            = LOWER(a.country)
     AND b.sales_channel             = a.po_code_sales_channel
     AND COALESCE(b.affiliate_id,'') = COALESCE(a.costumer_code_id_name,'')
     AND a.client_subsidiary_id IN (6)
     AND LOWER(b.plataform_type) = 'vtex'
     AND COALESCE(b.has_store_id, 'N') = 'N';   
  
  PERFORM UPDATE  ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_br_shop_homolog_2 a
     SET a.channel               = b.global_channel,
         a.biz_type              = b.biz_type,
         a.audience_type         = b.audience_type,
         a.po_storename          = b.partner_level,
         a.biz_type_ebi_hq       = b.biz_type_ebi,
         a.global_channel_ebi_hq = b.global_channel_ebi
    FROM  ow_md.sales_channel b
   WHERE LOWER(b.country)            = LOWER(a.country)
     AND b.sales_channel             = a.po_code_sales_channel
     AND a.client_subsidiary_id IN (6)
     AND a.PO_CODE_SALES_CHANNEL IN ('62','65','22');

  PERFORM UPDATE  ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_br_shop_homolog_2 a
     SET a.channel               = 'eStore',
         a.biz_type              = 'B2C', 
         a.audience_type         = 'Store+', 
         a.po_storename          = 'Store+', 
         a.biz_type_ebi_hq       = 'B2C',
         a.global_channel_ebi_hq = 'eStore'
    FROM  "U_PRJ_ECOM"."VIEW_ECOM_ENDLESS_AISLE_REPORT" b
   WHERE b."order_id" = a.po_orderid
     AND a.client_subsidiary_id IN (6);

  PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_br_shop_homolog_2
     SET po_devicetype = 'MOBILEAPP'
   WHERE po_storename IN ('App Samsung','App IOS','App Android')
     AND client_subsidiary_id = 6;            
  
  PERFORM UPDATE  ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_br_shop_homolog_2
     SET po_devicetype = 'Web'
   WHERE po_devicetype IS NULL
     AND client_subsidiary_id = 6; 

  PERFORM MERGE INTO OW_LAO.ODS_SALES_CONTROL_TOWER_TABLE_HOMOLOG_BDP a
  USING  ow_lao.tmp_ecommerce_sales_control_tower_raw_vtex_ssg_br_shop_homolog_2 b 
    ON b.po_orderid = a.po_orderid
   AND b.po_sku     = a.po_sku
   AND b.country    = a.country
   AND b.po_sku_kit = a.po_sku_kit
  WHEN MATCHED THEN UPDATE  
    SET a.po_date                    = b.po_date,
        a.po_hour                    = b.po_hour,
        a.podate_year                = b.podate_year,
        a.podate_month               = b.podate_month,
        a.samsung_care_order         = b.samsung_care_order,
        a.samsung_care               = b.samsung_care,
        a.samsung_care_eligibility   = b.samsung_care_eligibility,
        a.trade_in                   = b.trade_in,
        a.trade_in_eligibility       = b.trade_in_eligibility,
        a.costumer_code_id_name      = b.costumer_code_id_name,
        a.seller_po_orderid          = b.seller_po_orderid,
        a.payment_card_brand         = b.payment_card_brand,
        a.payment_type               = b.payment_type,
        a.installment                = b.installment,
        a.installment_eligibility    = b.installment_eligibility,
        a.po_cancelation_reason      = b.po_cancelation_reason,
        a.po_productgroup            = b.po_productgroup,
        a.po_code_sales_channel      = b.po_code_sales_channel,
        a.po_costumer_id             = b.po_costumer_id,
        a.po_sitecode                = b.po_sitecode,
        a.po_internal_status         = b.po_internal_status,
        a.po_invoicenumber           = b.po_invoicenumber,
        a.po_campain_tags            = b.po_campain_tags,
        a.po_campain                 = b.po_campain,
        a.po_coupon                  = b.po_coupon,
        a.po_medium                  = b.po_medium,
        a.po_src                     = b.po_src,
        a.po_utmi_campaing           = b.po_utmi_campaing,
        a.po_prodname                = b.po_prodname,
        a.po_seller_id               = b.po_seller_id,
        a.po_seller_name             = b.po_seller_name,
        a.po_status                  = b.po_status,
        a.client_subsidiary_id       = b.client_subsidiary_id,
        a.subsidiary                 = b.subsidiary,
        a.currency                   = b.currency,
        a.po_tradepolicy             = b.po_tradepolicy,
        a.po_vendortype              = b.po_vendortype,
        a.channel                    = b.channel,
        a.biz_type                   = b.biz_type,
        a.audience_type              = b.audience_type,
        a.po_storename               = b.po_storename,
        a.client_acquirer_message    = b.client_acquirer_message,
        a.po_lastupdate_date_hour    = b.po_lastupdate_date_hour,
        a.po_orderqty                = b.po_orderqty,
        a.po_qty                     = b.po_qty,
        a.po_itemdiscount_localcurr  = b.po_itemdiscount_localcurr,
        a.po_itemdiscount_usd        = b.po_itemdiscount_usd,
        a.po_price_localcurr         = b.po_price_localcurr,
        a.po_price_usd               = b.po_price_usd,
        a.po_plataform_datasource    = b.po_plataform_datasource,
        a.po_source_insert_date      = b.po_source_insert_date,
        a.po_source_last_update_date = b.po_source_last_update_date,
        a.po_insert_date             = b.po_insert_date,
        a.po_last_update_date        = b.po_last_update_date,
        a.po_payment_remark          = b.po_payment_remark,
        a.po_totalprice_usd          = b.po_totalprice_usd,
        a.po_totalprice_local        = b.po_totalprice_local,
        a.po_devicetype              = b.po_devicetype,
        a.updated_datetime           = CURRENT_TIMESTAMP,
        a.po_sku_kit                 = b.po_sku_kit,  
        a.po_prodname_kit            = b.po_prodname_kit,           
        a.is_kit                     = b.is_kit,
        a.country_cd                 = b.country_cd,  
        a.biz_type_ebi_hq            = b.biz_type_ebi_hq, 
        a.global_channel_ebi_hq      = b.global_channel_ebi_hq,
        a.shipping_method            = b.shipping_method
  WHEN NOT MATCHED THEN INSERT (
        po_date,
        po_hour,
        podate_year,
        podate_month,
        country,
        samsung_care_order,
        samsung_care,
        samsung_care_eligibility,
        trade_in,
        trade_in_eligibility,
        costumer_code_id_name,
        po_orderid,
        seller_po_orderid,
        payment_card_brand,
        payment_type,
        installment,
        installment_eligibility,
        po_cancelation_reason,
        po_productgroup,
        po_code_sales_channel,
        po_costumer_id,
        po_sitecode,
        po_internal_status,
        po_invoicenumber,
        po_campain_tags,
        po_campain,
        po_coupon,
        po_medium,
        po_src,
        po_utmi_campaing,
        po_sequence_orderid,
        po_prodname,
        po_sku,
        po_seller_id,
        po_seller_name,
        po_status,
        client_subsidiary_id,
        subsidiary,
        currency,
        po_tradepolicy,
        po_vendortype,
        channel,
        biz_type,
        audience_type,
        po_storename,
        client_acquirer_message,
        po_lastupdate_date_hour,
        po_orderqty,
        po_qty,
        po_itemdiscount_localcurr,
        po_itemdiscount_usd,
        po_price_localcurr,
        po_price_usd,
        po_plataform_datasource,
        po_source_insert_date,
        po_source_last_update_date,
        po_insert_date,
        po_last_update_date,
        po_payment_remark,
        po_totalprice_usd,
        po_totalprice_local,
        po_devicetype,
        po_sku_kit,
        po_prodname_kit,
        is_kit,
        country_cd,
        biz_type_ebi_hq,
        global_channel_ebi_hq,
        shipping_method
    )
    VALUES (
        b.po_date,
        b.po_hour,
        b.podate_year,
        b.podate_month,
        b.country,
        b.samsung_care_order,
        b.samsung_care,
        b.samsung_care_eligibility,
        b.trade_in,
        b.trade_in_eligibility,
        b.costumer_code_id_name,
        b.po_orderid,
        b.seller_po_orderid,
        b.payment_card_brand,
        b.payment_type,
        b.installment,
        b.installment_eligibility,
        b.po_cancelation_reason,
        b.po_productgroup,
        b.po_code_sales_channel,
        b.po_costumer_id,
        b.po_sitecode,
        b.po_internal_status,
        b.po_invoicenumber,
        b.po_campain_tags,
        b.po_campain,
        b.po_coupon,
        b.po_medium,
        b.po_src,
        b.po_utmi_campaing,
        b.po_sequence_orderid,
        b.po_prodname,
        b.po_sku,
        b.po_seller_id,
        b.po_seller_name,
        b.po_status,
        b.client_subsidiary_id,
        b.subsidiary,
        b.currency,
        b.po_tradepolicy,
        b.po_vendortype,
        b.channel,
        b.biz_type,
        b.audience_type,
        b.po_storename,
        b.client_acquirer_message,
        b.po_lastupdate_date_hour,
        b.po_orderqty,
        b.po_qty,
        b.po_itemdiscount_localcurr,
        b.po_itemdiscount_usd,
        b.po_price_localcurr,
        b.po_price_usd,
        b.po_plataform_datasource,
        b.po_source_insert_date,
        b.po_source_last_update_date,
        b.po_insert_date,
        b.po_last_update_date,
        b.po_payment_remark,
        b.po_totalprice_usd,
        b.po_totalprice_local,
        b.po_devicetype,
        b.po_sku_kit,
        b.po_prodname_kit,
        b.is_kit,
        b.country_cd,
        b.biz_type_ebi_hq,
        b.global_channel_ebi_hq,
        b.shipping_method
    );
END;
$$;

-- CALL OW_LAO.proc_ods_sales_control_tower_table_raw_vtex_ssg_br_shop_homolog_BDP_2();
-- ERROR: Severity: ERROR, Message: Relation "ow_md.dim_product" does not exist, Sqlstate: 42V01, Where: PL/vSQL procedure proc_ods_sales_control_tower_table_raw_vtex_ssg_br_shop_homolog_BDP_2 line 6 at static SQL, Routine: throwRelationDoesNotExist, File: /data/jenkins/workspace/RE-ReleaseBuilds/RE-Nibbler/server/vertica/Catalog/CatalogLookup.cpp, Line: 4341, Error Code: 4568, 
-- CALL OW_LAO.proc_ods_sales_control_tower_table_raw_vtex_ssg_br_shop_homolog_BDP_2();
-- ERROR: Severity: ERROR, Message: Relation "ow_md.dim_product" does not exist, Sqlstate: 42V01, Where: PL/vSQL procedure proc_ods_sales_control_tower_table_raw_vtex_ssg_br_shop_homolog_BDP_2 line 6 at static SQL, Routine: throwRelationDoesNotExist, File: /data/jenkins/workspace/RE-ReleaseBuilds/RE-Nibbler/server/vertica/Catalog/CatalogLookup.cpp, Line: 4341, Error Code: 4568, 
