CREATE OR REPLACE PROCEDURE OW_LAO.proc_ods_sales_control_tower_table_ow_lao_ods_hybris_sales()
LANGUAGE PLvSQL AS $$
BEGIN    
	
PERFORM CREATE TABLE IF NOT EXISTS OW_LAO.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales
(
    country varchar(30),
    po_storename varchar(255),
    po_orderid varchar(255),
    po_status varchar(500),
    po_internal_status varchar(255),
    po_date timestamp,
    po_hour time,
    podate_year int,
    podate_month int,
    samsung_care_order int,
    samsung_care_eligibility int,
    trade_up int,
    trade_up_eligibility int,
    trade_in int,
    po_totalprice float,
    po_totalprice_usd float,
    po_totaltax float,
    currency varchar(255),
    po_sku varchar(255),
    po_prodname varchar(255),
    po_totalprice_local float,
    po_price_localcurr float,
    po_qty int,
    po_coupon varchar(2000),
    payment_type varchar(255),
    costumertype varchar(255),
    po_ordersid varchar(255),
    samsung_care int,
    po_added_services varchar(255),
    trade_in_eligibility int,
    po_paymentprovider varchar(255),
    payment_card_brand varchar(255),
    po_paymentdate timestamp,
    client_subsidiary_id int,
    subsidiary varchar(10),
    po_store_id varchar(255),
    po_store_name varchar(255),
    client_trade_in_exchange_brand varchar(255),
    trade_in_discount numeric(2,2),
    trade_in_discount_details varchar(2000),
    client_trade_in_exchange_model varchar(255),
    po_costumer_id varchar(255),
    po_external_service_type varchar(255),
    po_devicetype varchar(255),
    po_plataform_datasource varchar(23),
    po_source_insert_date timestamp,
    po_source_last_update_date timestamp,
    po_insert_date timestamptz(6),
    po_itemdiscount_usd float,
    po_price_usd float,
    channel varchar(255),
    biz_type varchar(255),
    audience_type varchar(255),
    po_orderqty int,
    access_code varchar(2000),
    po_itemdiscount_localcurr float,
    warranty int,
    warranty_eligibility int,
    crp int,
    shipping_method varchar(255),
    delivery_mode varchar(255),
    customer_type varchar(255),
    po_mobile_os varchar(255),
    installment_amount float,
    installment int,
    select_ai int,
    select_ai_eligibility int,
    subscription int,
    po_sku_kit varchar(255),
    is_kit boolean,
    po_sitecode varchar(255)
) ORDER BY 
    country,           -- Primary segmentation key
    po_orderid,        -- Primary segmentation key & frequent join
    subsidiary,        -- Frequent join key
    po_sku,            -- Frequent join key
    po_date            -- Range filter
SEGMENTED BY HASH(country, po_orderid) ALL NODES KSAFE 1;

PERFORM TRUNCATE TABLE ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales;
PERFORM INSERT INTO ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales
SELECT  
    b.country                                                   AS country
    ,a.site                                                     AS po_storename
    ,a.order_code                                               AS po_orderid
    ,d.status                                                   AS po_status
    ,a.order_status                                             AS po_internal_status
    ,CAST (a.order_creation_date AS datetime)                   AS po_date
    ,CAST (a.order_creation_date AS  time)                      AS po_hour
    ,YEAR (a.order_creation_date::timestamp)                    AS podate_year
    ,MONTH (a.order_creation_date::timestamp)                   AS podate_month
    , CASE WHEN a.external_service_type = 'INSURANCE' 
      THEN 1
      ELSE 0 
      END                                                       AS samsung_care_order
    , CASE WHEN a.external_service_type = 'INSURANCE' 
      THEN 1
      ELSE 0 
      END                                                       AS samsung_care_eligibility
    , 0                                                         AS trade_up
    , 0                                                         AS trade_up_eligibility
    , CASE WHEN a.external_service_type = 'TRADE_IN'
      THEN 1
      WHEN a.exchange_model  = 'T-TRADEUP_VARIANT'
      THEN 1
      WHEN a.exchange_brand  = 'T-TRADEUP'
      THEN 1
      ELSE 0 
      END                                                       AS trade_in 
    ,a.order_entry_total_price::float                                  AS po_totalprice
    ,0::float                                                          AS po_totalprice_usd
    ,a.order_entry_total_tax::float                                    AS po_totaltax
    ,a.order_currency                                           AS currency
    ,a.product_code                                             AS po_sku
    ,a.product_name                                             AS po_prodname
    ,a.order_entry_total_price::float                                  AS po_totalprice_local
    ,a.order_entry_unit_price::float                                   AS po_price_localcurr
    , CAST (
    replace  (a.order_entry_quantity, '.00', '')
    AS int 
    )                                                           AS po_qty
    ,a.voucer_code                                              AS po_coupon
    ,a.payment_mode                                             AS payment_type
    ,a.customer_type                                            AS costumertype
    ,a.sales_order                                              AS po_ordersid
    ,CASE WHEN a.external_service_type = 'INSURANCE' 
      THEN 1
      ELSE 0 
      END                                                       AS samsung_care
    ,a.added_services                                           AS po_added_services
    , CASE WHEN a.external_service_type = 'TRADE_IN'
      THEN 1
      WHEN a.exchange_model  = 'T-TRADEUP_VARIANT'
      THEN 1
      WHEN a.exchange_brand  = 'T-TRADEUP'
      THEN 1
      ELSE 0 
      END                                                       AS trade_in_eligibility 
    ,a.payment_provider                                         AS po_paymentprovider
    ,a.payment_mode_creditcardtype                              AS payment_card_brand
    ,a.payment_date::timestamp                                             AS po_paymentdate
    ,b.id                                                       AS client_subsidiary_id
    ,b.subsidiary                                               AS subsidiary
    ,a.store_id                                                 AS po_store_id
    ,a.store_name                                               AS po_store_name
    ,a.exchange_brand                                           AS client_trade_in_exchange_brand
    ,0.00                                                       AS trade_in_discount
    ,a.trade_in_discount                                        AS trade_in_discount_details
    ,a.exchange_model                                           AS client_trade_in_exchange_model
    ,a.guid                                                     AS po_costumer_id
    ,a.external_service_type                                    AS po_external_service_type
    ,a.sales_application                                        AS po_devicetype
    ,'ow_lao.ods_hybris_sales'                                  AS po_plataform_datasource
    ,a.inserted_date                                            AS po_source_insert_date
    ,a.updated_datetime                                         AS po_source_last_update_date
    ,current_timestamp                                          AS po_insert_date
    ,CAST (0.00 AS float )                                       AS po_itemdiscount_usd
    ,CAST (0.00 AS float )                                       AS po_price_usd
    ,CAST (NULL AS varchar(255))                                AS channel
    ,CAST (NULL AS varchar(255))                                AS biz_type
    ,CAST (NULL AS varchar(255))                                AS audience_type
    ,0                                                          AS po_orderqty
    ,SUBSTR(Access_Code, INSTR(Access_Code, ',', -1) + 1)       AS access_code
    ,(a.order_entry_unit_price * order_entry_quantity) 
      - a.order_entry_total_price                               as po_itemdiscount_localcurr
    ,CASE WHEN a.external_service_type = 'WARRANTY'            
      THEN 1
      ELSE 0 
      END                                                      as warranty
    ,CASE WHEN a.external_service_type = 'WARRANTY'            
      THEN 1
      ELSE 0 
      END                                                      as warranty_eligibility
    ,a.crp                                                     AS crp
    ,a.SHIPPING_METHOD                                         AS shipping_method
    ,CAST (NULL AS varchar(255))                               AS delivery_mode
    ,CAST (NULL AS varchar(255))                               AS customer_type
    ,CAST (NULL AS varchar(255))                               AS po_mobile_os
    ,CAST (0.00 AS float )                                      AS installment_amount
    ,CAST (0 AS int )                                          AS installment
    , cast(0 as int)                                           as select_ai
    , cast(0 as int)                                           as select_ai_eligibility
    , cast(0 as int)                                           as subscription
    , CAST ('' AS varchar(255))                              as po_sku_kit
    , false                                                    as is_kit
    , a.site                                                   as po_sitecode
    FROM ow_lao.ods_hybris_sales                                      a
    LEFT JOIN u_prj_ecom.dim_subsidiary                               b ON lower(b.country_code) =  lower(a.country_cd)
    LEFT JOIN ow_md.dim_product                                       c ON c.sku                 = a.PRODUCT_CODE 
    LEFT JOIN ow_lao.dim_ods_sales_control_tower_table_status_mapping d ON d.status_origin       = a.order_status
    WHERE 1 = 1
    AND a.order_creation_date::timestamp >= CAST(TIMESTAMPADD(DAY, -30, CAST(current_date AS DATE)) AS DATE)
    AND NOT EXISTS (
    SELECT 1
    FROM ow_lao.ods_sales_control_tower_table aa
    WHERE aa.po_orderid             = a.order_code
    AND   aa.po_sku                 = a.product_code
    AND   aa.country                = b.country
    AND   aa.po_sitecode            = a.site
    AND   aa.po_source_last_update_date::timestamp >= CAST (coalesce(a.updated_datetime, '19000101') AS timestamp)
    )
    ORDER BY a.order_creation_date DESC 
            ,a.order_code;
    
-- timezone adjustment
PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales a
     SET po_date      =       TIMESTAMPADD(hour, COALESCE(b.timezone,0), a.po_date::timestamp) 
       , po_hour      = cast( TIMESTAMPADD(hour, COALESCE(b.timezone,0), a.po_date::timestamp) AS time)
       , podate_year  = year( TIMESTAMPADD(hour, COALESCE(b.timezone,0), a.po_date::timestamp))
       , podate_month = month(TIMESTAMPADD(hour, COALESCE(b.timezone,0), a.po_date::timestamp))
    from u_prj_ecom.dim_subsidiary                                              b 
   WHERE lower(b.country) = lower (a.country)
     and b.ORDER_APPLY_TIMEZONE  = 1
     and a.po_storename not in ('cl_parismarketplace', 'clfalabella')
     and not exists(
            select 1
              from ow_lao.ods_dim_subsidiary_timezone_exceptions e 
             where e.subsidiary_id =  b.id
               AND a.po_date BETWEEN e.timezone_from AND e.timezone_until      
      );

PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales a
     SET po_date      =       TIMESTAMPADD(hour, COALESCE(b.timezone,0), a.po_date::timestamp) 
       , po_hour      = cast( TIMESTAMPADD(hour, COALESCE(b.timezone,0), a.po_date::timestamp) AS time)
       , podate_year  = year( TIMESTAMPADD(hour, COALESCE(b.timezone,0), a.po_date::timestamp))
       , podate_month = month(TIMESTAMPADD(hour, COALESCE(b.timezone,0), a.po_date::timestamp))
    from u_prj_ecom.dim_subsidiary                                              b 
    JOIN ow_lao.ods_dim_subsidiary_timezone_exceptions                           e ON e.subsidiary_id =  b.id
   WHERE lower(b.country) = lower (a.country)
     AND a.po_date    BETWEEN e.timezone_from AND e.timezone_until
     and b.ORDER_APPLY_TIMEZONE  = 1
     and a.po_storename not in ('cl_parismarketplace', 'clfalabella');

  PERFORM COMMIT;
 
PERFORM CREATE TABLE IF NOT EXISTS ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales_agg
	AS (
		SELECT country
		,po_orderid
		,sum(cast(po_qty AS decimal))  AS po_orderqty
		FROM ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales
		GROUP BY country
		,po_orderid
	) ORDER BY 
	    country,           -- PRIMARY: Matches segmentation key, enables RLE compression
	    po_orderid         -- SECONDARY: Matches join key, co-locates related orders
	SEGMENTED BY HASH(country, po_orderid) ALL NODES KSAFE 1;

-- web device type adjustment
PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales      a
	SET  PO_DEVICETYPE  = 'Web'
	WHERE a.PO_DEVICETYPE  NOT IN ('MOBILEAPP', 'WebMobile');

-- orders aggregations
PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales      a
	 SET PO_ORDERQTY  =  b.po_orderqty
	 FROM ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales_agg   b  
	 where b.country = a.country
	 AND b.PO_ORDERID = a.PO_ORDERID ;

--currecncy conversions
 PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales    a
	SET po_price_usd        =   COALESCE ( a.po_price_localcurr / CAST (b.exchange_rate AS decimal),0)
	,   po_totalprice_usd   =   COALESCE ( a.po_totalprice      / CAST (b.exchange_rate AS decimal),0)
	,   po_itemdiscount_usd =   COALESCE ( a.po_itemdiscount_localcurr      / CAST (b.exchange_rate AS decimal),0)
	FROM    ow_lao.FT_AP2_EXCHANGE_RATE                                                  b 
	where b.VALID_FROM::date  = a.po_date::date  -1
	 AND b.TO_CURRENCY = a.CURRENCY ; 
	                                                                          
                                    
--sales channel identification
 PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales     a
	 SET channel       = b.global_channel
	 ,   biz_type      = b.biz_type
	 ,   audience_type = b.audience_type
	 ,   customer_type = b.customer_type
	 ,   po_mobile_os  = b.po_mobile_os
	 FROM ow_md.sales_channel                                                           b 
	where lower(b.COUNTRY)    = lower (a.COUNTRY)
	     AND lower(b.IDENTIFIER) =  lower (a.PO_STORENAME) 
	;

PERFORM COMMIT;

--CRP mapping Storename
PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales     a
	SET
	    CRP = 1
	FROM u_prj_ecom.dim_subsidiary      b 
	JOIN OW_LAO.DIM_LAO_CRP_CS_STORENAME c on c.SUBSIDIARY = b.SUBSIDIARY
	    WHERE a.CRP IS null
	    and lower(b.COUNTRY_CODE) =  lower(a.COUNTRY)
	    and lower(c.STORENAME_CRP) = lower (a.PO_STORE_NAME);
    
PERFORM UPDATE
	    ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales     a
	SET
	    CRP = 0
	    WHERE a.crp IS NULL;
   
---------DELIVERY_MODE MAPPING --lucas.gil 02/06
PERFORM UPDATE 
        ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales      a
    SET   
        delivery_mode         = b.delivery_mode
    FROM    
        ow_lao.dim_lao_delivery_mode_mapping_control_tower          b 
        where b.subsidiary       = a.subsidiary 
        AND  b.shipping_method  = a.shipping_method 
    and  
        b.active = TRUE
        AND a.delivery_mode IS NULL;

---------INSTALLMENT --lucas.gil 14/08
PERFORM UPDATE 
	    ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales      a
	SET   
	     installment_amount   = CAST (b.installment_amount AS decimal)
	    ,installment          = CAST (b.installments AS int)
	FROM   
	    ow_lao.raw_lao_orders_installment_report_hybris_control_tower b     
	    where    b.order_code    = a.po_orderid
	    and   b.order_status  = a.po_internal_status
	    and   b.site          = a.po_storename  
	and  a.installment IS NULL
	   and coalesce(b.installments, '') != '';
          

PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales  a
	SET 
	    po_sku_kit = b.reference_code,
	    is_kit     = true
	FROM ow_lao.ods_hybris_combo                                               b 
	where LEFT (a.po_orderid,17) = LEFT (b.order_code,17)
	       AND a.po_sku               = b.product_code
	       AND a.subsidiary           = b.subsidiary                           
	 and po_plataform_datasource  = 'ow_lao.ods_hybris_sales'
	 AND CAST (PO_DATE AS DATE) >= '2025-01-01';

--CRP mapping Offers p.anaalinne 25/08 ------------------------------------------
PERFORM UPDATE  ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales  a
	set    crp = 3
	from   ow_lao.ods_lao_offers_promotion             b 
	where  left (b.order_code,17) = left (a.po_orderid,17) 
	     and  b.product_code        = a.po_sku  
	     and  b.subsidiary          = a.subsidiary
	and b.campaing_in_hybris_code like 'CRP%'
	and   a.crp = 0;


--Select AI-------------------------------------------------------------------------
 -- Mark Select AI Sales Flag
 
  -- without audience type      
    -- without combo   
PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales a
       set select_ai             = 1
         , select_ai_eligibility = 1
      from ow_lao.manual_mapping_selectai_hybris_sales                            b 
     where b.sku1     = a.po_sku
       and b.sub      = a.subsidiary
       and b.bizType  = a.biz_type
       and b.is_combo is null
       and a.po_date >= cast(b.ActivationDate as date)
       and b.division in ('MX', 'DA', 'VD')
       and coalesce(b.audience_type, '')      = '';


    -- with combo
       -- Sku 1    
PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales a
       set select_ai             = 1
         , select_ai_eligibility = 1
      from ow_lao.manual_mapping_selectai_hybris_sales                            b
     where b.sku1       = a.po_sku
       and b.sub        = a.subsidiary
       and b.bizType    = a.biz_type
       and b.is_combo is not null
       and a.po_date >= cast(b.ActivationDate as date)
       and b.division in ('VD', 'DA')
       and coalesce(b.audience_type, '')      = ''
       and exists(
                select 1
                  from ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales c 
                 where c.po_sku     = b.sku2 
                   and c.subsidiary = b.sub
                   and c.biz_type   = b.bizType 
                   and c.po_orderid = a.po_orderid
           );

       -- Sku 2       
PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales a
       set select_ai             = 1
         , select_ai_eligibility = 1
      from ow_lao.manual_mapping_selectai_hybris_sales                            b                                                              
     where b.sku2       = a.po_sku
       and b.sub        = a.subsidiary
       and b.bizType    = a.biz_type
       and b.is_combo is not null
       and a.po_date >= cast(b.ActivationDate as date)
       and b.division in ('VD', 'DA')
       and coalesce(b.audience_type, '')      = ''
       and exists(
                select 1
                  from ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales c 
                 where c.po_orderid = a.po_orderid 
                   and c.po_sku     = b.sku1
                   and c.subsidiary = b.sub
                   and c.biz_type   = b.bizType
           );   

  -- with audience type      
    -- without combo   
PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales a
       set select_ai             = 1
         , select_ai_eligibility = 1
      from ow_lao.manual_mapping_selectai_hybris_sales                            b
     where b.sku1          = a.po_sku
       and b.sub           = a.subsidiary
       and b.bizType       = a.biz_type
       and b.audience_type = a.audience_type
       and b.is_combo is null
       and a.po_date >= cast(b.ActivationDate as date)
       and b.division in ('MX', 'DA', 'VD')
       and coalesce(b.audience_type, '')      != '';


    -- with combo
       -- Sku 1
PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales a
       set select_ai             = 1
         , select_ai_eligibility = 1
      from ow_lao.manual_mapping_selectai_hybris_sales                            b                                                      
     where b.sku1          = a.po_sku
       and b.sub           = a.subsidiary
       and b.bizType       = a.biz_type
       and b.audience_type = a.audience_type
       and b.is_combo is not null
       and a.po_date >= cast(b.ActivationDate as date)
       and b.division in ('VD', 'DA')
       and coalesce(b.audience_type, '')      != ''
       and exists(
                select 1
                  from ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales c 
                 where c.po_orderid    = a.po_orderid 
                   and c.po_sku        = b.sku2 
                   and c.subsidiary    = b.sub
                   and c.biz_type      = b.bizType
                   and c.audience_type = b.audience_type     
           );   

       -- Sku 2       
PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales a
       set select_ai             = 1
         , select_ai_eligibility = 1
      from ow_lao.manual_mapping_selectai_hybris_sales                            b                                                                 
     where b.sku1          = a.po_sku
       and b.sub           = a.subsidiary
       and b.bizType       = a.biz_type
       and b.audience_type = a.audience_type
       and b.is_combo is not null
       and a.po_date >= cast(b.ActivationDate as date)
       and b.division in ('VD', 'DA')
       and coalesce(b.audience_type, '')      != ''
       and exists(
                select 1
                  from ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales c 
                 where c.po_orderid    = a.po_orderid 
                   and c.po_sku        = b.sku2 
                   and c.subsidiary    = b.sub
                   and c.biz_type      = b.bizType
                   and c.audience_type = b.audience_type          
           );   


  -- Mark Select AI Elegibility Flag
 
   -- without audience type        
    -- without combo   
PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales a
       set select_ai_eligibility = 1
      from ow_lao.manual_mapping_selectai_hybris_elegibility                      b
     where b.sku1     = a.po_sku
       and b.sub      = a.subsidiary
       and b.bizType  = a.biz_type
       and b.is_combo is null
       and a.po_date >= cast(b.ActivationDate as date)
       and b.division in ('MX', 'DA', 'VD')
       and coalesce(b.audience_type, '')      = '';


    -- with combo
       -- Sku 1
    PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales a
       set select_ai_eligibility = 1
      from ow_lao.manual_mapping_selectai_hybris_elegibility                      b                                                             
     where b.sku1       = a.po_sku
       and b.sub        = a.subsidiary
       and b.bizType    = a.biz_type
       and b.is_combo is not null
       and a.po_date >= cast(b.ActivationDate as date)
       and b.division in ('VD', 'DA')
       and coalesce(b.audience_type, '')      = ''
       and exists(
                select 1
                  from ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales c 
                 where c.po_orderid = a.po_orderid 
                   and c.po_sku     = b.sku2 
                   and c.subsidiary = b.sub
                   and c.biz_type   = b.bizType          
           );  

       -- Sku 2       
    PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales a
       set select_ai_eligibility = 1
      from ow_lao.manual_mapping_selectai_hybris_elegibility                      b                                                          
     where b.sku2       = a.po_sku
       and b.sub        = a.subsidiary
       and b.bizType    = a.biz_type
       and b.is_combo is not null
       and a.po_date >= cast(b.ActivationDate as date)
       and b.division in ('VD', 'DA')
       and coalesce(b.audience_type, '')      = ''
       and exists(
                select 1
                  from ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales c 
                 where c.po_orderid = a.po_orderid 
                   and c.po_sku     = b.sku1
                   and c.subsidiary = b.sub
                   and c.biz_type   = b.bizType          
           );  
       
   -- with audience type        
    -- without combo   
    PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales a
       set select_ai_eligibility = 1
      from ow_lao.manual_mapping_selectai_hybris_elegibility                      b
     where b.sku1          = a.po_sku
       and b.sub           = a.subsidiary
       and b.bizType       = a.biz_type
       and b.audience_type = a.audience_type
       and b.is_combo is null
       and a.po_date >= cast(b.ActivationDate as date)
       and b.division in ('MX', 'DA', 'VD')
       and coalesce(b.audience_type, '')      != '';


    -- with combo
       -- Sku 1
    PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales a
       set select_ai_eligibility = 1
      from ow_lao.manual_mapping_selectai_hybris_elegibility                      b
     where b.sku1          = a.po_sku
       and b.sub           = a.subsidiary
       and b.bizType       = a.biz_type
       and b.audience_type = a.audience_type
       and b.is_combo is not null
       and a.po_date >= cast(b.ActivationDate as date)
       and b.division in ('VD', 'DA')
       and coalesce(b.audience_type, '')      != ''
       and exists(
                select 1
                  from ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales c 
                 where c.po_orderid    = a.po_orderid 
                   and c.po_sku        = b.sku2 
                   and c.subsidiary    = b.sub
                   and c.biz_type      = b.bizType
                   and c.audience_type = b.audience_type           
           );  

       -- Sku 2       
    PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales a
       set select_ai_eligibility = 1
      from ow_lao.manual_mapping_selectai_hybris_elegibility                      b                                                            
     where b.sku1          = a.po_sku
       and b.sub           = a.subsidiary
       and b.bizType       = a.biz_type
       and b.audience_type = a.audience_type
       and b.is_combo is not null
       and a.po_date >= cast(b.ActivationDate as date)
       and b.division in ('VD', 'DA')
       and coalesce(b.audience_type, '')      != ''
       and exists(
                select 1
                  from ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales c 
                 where c.po_orderid    = a.po_orderid 
                   and c.po_sku        = b.sku2 
                   and c.subsidiary    = b.sub
                   and c.biz_type      = b.bizType
                   and c.audience_type = b.audience_type           
           );         
       
  -- Mark Select AI Subscription Flagging
       
    -- without combo   
    PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales a
       set select_ai_eligibility = 1
         , select_ai             = 1
         , subscription          = 1
      from ow_lao.manual_mapping_selectai_hybris_subscription                     b
     where b.sku1     = a.po_sku
       and b.sub      = a.subsidiary
       and b.bizType  = a.biz_type
       and b.is_combo is null
       and a.po_date >= cast(b.ActivationDate as date)
       and b.division in ('MX', 'DA', 'VD')
       and a.po_plataform_datasource = 'ow_lao.ods_hybris_sales';  


    -- with combo
       -- Sku 1
    PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales a
       set select_ai_eligibility = 1
         , select_ai             = 1
         , subscription          = 1
      from ow_lao.manual_mapping_selectai_hybris_subscription                     b                                                             
     where b.sku1       = a.po_sku
       and b.sub        = a.subsidiary
       and b.bizType    = a.biz_type
       and b.is_combo is not null
       and a.po_date >= cast(b.ActivationDate as date)
       and b.division in ('VD', 'DA')
       and a.po_plataform_datasource = 'ow_lao.ods_hybris_sales'
       and exists(
                select 1
                  from ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales c 
                 where c.po_orderid = a.po_orderid 
                   and c.po_sku     = b.sku2 
                   and c.subsidiary = b.sub
                   and c.biz_type   = b.bizType         
           );   

       -- Sku 2       
    PERFORM UPDATE ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales a
       set select_ai_eligibility = 1
         , select_ai             = 1
         , subscription          = 1
      from ow_lao.manual_mapping_selectai_hybris_subscription                     b                                                           
     where b.sku2       = a.po_sku
       and b.sub        = a.subsidiary
       and b.bizType    = a.biz_type
       and b.is_combo is not null
       and a.po_date >= cast(b.ActivationDate as date)
       and b.division in ('VD', 'DA')
       and a.po_plataform_datasource = 'ow_lao.ods_hybris_sales'
       and exists(
                select 1
                  from ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales c 
                 where c.po_orderid = a.po_orderid 
                   and c.po_sku     = b.sku1
                   and c.subsidiary = b.sub
                   and c.biz_type   = b.bizType        
           );          

PERFORM COMMIT;

--Select AI end----------------------------------------------------------------------
                                                    
        PERFORM UPDATE ow_lao.ods_sales_control_tower_table                               a
           SET    po_date                         = b.po_date
                , po_hour                         = b.po_hour
                , podate_year                     = b.podate_year
                , podate_month                    = b.podate_month
                , po_storename                    = b.po_storename
                , po_status                       = b.po_status
                , po_internal_status              = b.po_internal_status
                , po_totalprice                   = b.po_totalprice
                , po_totalprice_usd               = b.po_totalprice_usd
                , po_totaltax                     = b.po_totaltax
                , currency                        = b.currency
                , po_prodname                     = b.po_prodname                 
                , po_totalprice_local             = b.po_totalprice_local
                , po_price_localcurr              = b.po_price_localcurr
                , po_qty                          = b.po_qty
                , po_coupon                       = b.po_coupon
                , payment_type                    = b.payment_type
                , costumertype                    = b.costumertype
                , po_ordersid                     = b.po_ordersid
                , samsung_care                    = b.samsung_care
                , trade_in_eligibility            = b.trade_in_eligibility
                , po_paymentprovider              = b.po_paymentprovider
                , payment_card_brand              = b.payment_card_brand 
                , po_paymentdate                  = b.po_paymentdate
                , client_subsidiary_id            = b.client_subsidiary_id
                , subsidiary                      = b.subsidiary
                , po_store_id                     = b.po_store_id
                , po_store_name                   = b.po_store_name
                , client_trade_in_exchange_brand  = b.client_trade_in_exchange_brand
                , trade_in_discount               = b.trade_in_discount
                , client_trade_in_exchange_model  = b.client_trade_in_exchange_model
                , po_costumer_id                  = b.po_costumer_id
                , trade_in                        = b.trade_in
                , po_devicetype                   = b.po_devicetype
                , po_plataform_datasource         = b.po_plataform_datasource
                , po_source_insert_date           = b.po_source_insert_date
                , po_source_last_update_date      = b.po_source_last_update_date
                , po_insert_date                  = b.po_insert_date 
                , po_itemdiscount_usd             = b.po_itemdiscount_usd
                , po_price_usd                    = b.po_price_usd
                , channel                         = b.channel
                , biz_type                        = b.biz_type
                , audience_type                   = b.audience_type  
                , samsung_care_order              = b.samsung_care_order
                , samsung_care_eligibility        = b.samsung_care_eligibility
                , po_orderqty                     = b.po_orderqty 
                , po_added_services               = b.po_added_services
                , po_external_service_type        = b.po_external_service_type
                , trade_in_discount_details       = b.trade_in_discount_details
                , access_code                     = b.access_code
                , updated_datetime                = current_timestamp AT TIME ZONE 'America/Sao_Paulo'
                , warranty                        = b.warranty
                , warranty_eligibility            = b.warranty_eligibility
                , crp                             = b.crp
                , shipping_method                 = b.shipping_method
                , delivery_mode                   = b.delivery_mode
                , customer_type                   = b.customer_type
                , po_mobile_os                    = b.po_mobile_os
                , installment_amount              = b.installment_amount
                , installment                     = b.installment
                , select_ai                       = b.select_ai
                , select_ai_eligibility           = b.select_ai_eligibility
                , subscription                    = b.subscription
                , po_sku_kit                      = b.po_sku_kit
             from ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales  b 
            where b.po_orderid  = a.PO_ORDERID 
              AND b.po_sku      = a.PO_SKU 
              AND b.country     = a.COUNTRY
              and b.po_sku_kit  = a.po_sku_kit
              and b.po_sitecode = a.po_sitecode;
                
                  PERFORM INSERT INTO ow_lao.ods_sales_control_tower_table(
                         country
                        ,po_storename
                        ,po_orderid
                        ,po_sitecode
                        ,po_status
                        ,po_internal_status
                        ,po_date
                        ,po_hour
                        ,po_totalprice
                        ,po_totalprice_usd
                        ,po_totaltax
                        ,currency
                        ,po_sku
                        ,po_prodname
                        ,po_totalprice_local
                        ,po_price_localcurr
                        ,po_qty
                        ,po_coupon
                        ,payment_type
                        ,costumertype
                        ,po_ordersid
                        ,samsung_care
                        ,trade_in_eligibility
                        ,po_paymentprovider
                        ,payment_card_brand
                        ,po_paymentdate
                        ,client_subsidiary_id
                        ,subsidiary
                        ,po_store_id
                        ,po_store_name
                        ,client_trade_in_exchange_brand
                        ,trade_in_discount
                        ,client_trade_in_exchange_model
                        ,po_costumer_id
                        ,trade_in
                        ,po_devicetype
                        ,po_plataform_datasource
                        ,po_source_insert_date
                        ,po_source_last_update_date
                        ,po_insert_date
                        ,po_itemdiscount_usd              
                        ,po_price_usd                    
                        ,channel                         
                        ,biz_type                        
                        ,audience_type                    
                        ,samsung_care_order               
                        ,samsung_care_eligibility        
                        ,po_orderqty                      
                        ,po_added_services            
                        ,po_external_service_type       
                        ,trade_in_discount_details        
                        ,podate_year
                        ,podate_month
                        ,access_code 
                        ,po_itemdiscount_localcurr
                        ,warranty 
                        ,warranty_eligibility
                        ,crp
                        ,shipping_method
                        ,delivery_mode
                        ,customer_type
                        ,po_mobile_os
                        ,installment_amount
                        ,installment
                        ,select_ai
                        ,select_ai_eligibility
                        ,subscription
                        ,po_sku_kit
                        )
                   select
                         b.country
                        ,b.po_storename
                        ,b.po_orderid
                        ,b.po_sitecode
                        ,b.po_status
                        ,b.po_internal_status
                        ,b.po_date
                        ,b.po_hour
                        ,b.po_totalprice
                        ,b.po_totalprice_usd
                        ,b.po_totaltax
                        ,b.currency
                        ,b.po_sku
                        ,b.po_prodname
                        ,b.po_totalprice_local
                        ,b.po_price_localcurr
                        ,b.po_qty
                        ,b.po_coupon
                        ,b.payment_type
                        ,b.costumertype
                        ,b.po_ordersid
                        ,b.samsung_care
                        ,b.trade_in_eligibility
                        ,b.po_paymentprovider
                        ,b.payment_card_brand
                        ,b.po_paymentdate
                        ,b.client_subsidiary_id
                        ,b.subsidiary
                        ,b.po_store_id
                        ,b.po_store_name
                        ,b.client_trade_in_exchange_brand
                        ,b.trade_in_discount
                        ,b.client_trade_in_exchange_model
                        ,b.po_costumer_id
                        ,b.trade_in
                        ,b.po_devicetype
                        ,b.po_plataform_datasource
                        ,b.po_source_insert_date
                        ,b.po_source_last_update_date
                        ,b.po_insert_date
                        ,b.po_itemdiscount_usd              
                        ,b.po_price_usd                    
                        ,b.channel                         
                        ,b.biz_type                        
                        ,b.audience_type                    
                        ,b.samsung_care_order               
                        ,b.samsung_care_eligibility        
                        ,b.po_orderqty                      
                        ,b.po_added_services            
                        ,b.po_external_service_type       
                        ,b.trade_in_discount_details        
                        ,b.podate_year
                        ,b.podate_month
                        ,b.access_code 
                        ,b.po_itemdiscount_localcurr
                        ,b.warranty 
                        ,b.warranty_eligibility
                        ,b.crp
                        ,b.shipping_method
                        ,b.delivery_mode
                        ,b.customer_type
                        ,b.po_mobile_os
                        ,b.installment_amount
                        ,b.installment
                        ,b.select_ai
                        ,b.select_ai_eligibility
                        ,b.subscription
                        ,b.po_sku_kit
                    from ow_lao.tmp_ecommerce_sales_control_tower_table_ow_lao_ods_hybris_sales  b 
                   where not exists (
                              select 1
                                from ow_lao.ods_sales_control_tower_table aa
                               where b.po_orderid  = aa.PO_ORDERID 
                                 AND b.po_sku      = aa.PO_SKU 
                                 AND b.country     = aa.COUNTRY
                                 AND b.po_sku_kit  = aa.po_sku_kit
                                 and b.po_sitecode = aa.po_sitecode
                         );
                       
   END;
   $$

