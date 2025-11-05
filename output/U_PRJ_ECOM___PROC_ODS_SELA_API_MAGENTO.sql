CREATE PROCEDURE U_PRJ_ECOM.PROC_ODS_SELA_API_MAGENTO
 LANGUAGE SQLSCRIPT AS
 BEGIN
 
 --call U_PRJ_ECOM.PROC_ODS_SELA_API_MAGENTO
 
drop table u_prj_ecom.tmp_ods_sela_api_magento_insert;
drop table u_prj_ecom.tmp_ods_sela_api_magento_update;
drop table u_prj_ecom.tmp_ods_sela_api_magento_sub;
drop table u_prj_ecom.ods_sela_api_magento_totals_temp;
drop table u_prj_ecom.ods_sela_api_magento_totals_temp_update;
drop table u_prj_ecom.ods_sela_api_magento_totals_temp_sub ;
drop table u_prj_ecom.ods_sela_api_magento_update_temp;
CREATE COLUMN TABLE u_prj_ecom.tmp_ods_sela_api_magento_insert  AS (
SELECT DISTINCT 
A.ID,
CURRENT_TIMESTAMP AS INSERTEDDATE,
A.ORDER_ID,
A.STATUS,
A.CREATION_DATE,
A.PAYMENT_APPROVED_DATE,
A.INVOICE_DATE,
A.SHIPPING_ESTIMATE_DATE,
A.HANDLING_DATE,
A.DELIVERED_DATE,
A.PAYMENT_TYPE,
A.PAYMENT_BRAND,
A.QTY_INSTALLMENTS,
A.CANCELATION_DATE,
A.SHIPPING_COST,
A.UNITS,
A.CHANNEL,
A.DISCOUNT,
A.CONSUMER_ID,
A.CURRENCY_CODE,
A.CODE,
A.DESCRIPTION,
A.PRICE,
A.QUANTITY,
A.SHIPPING_COST_SKU,
A.DISCOUNT_SKU,
A.ORDERVALUE,
A.SUBSIDIARYID,
A.COUNTRY,
A.COUNTRY_COD,
A.ORDERITEMQUANTITY,
A.SELLERINSTANCEID
FROM U_PRJ_ECOM.TMP_ODS_SELA_API_MAGENTO A
WHERE
     not exists(
                      select 1
                        from  U_PRJ_ECOM.FT_ECOM_ORDER B
                       where B.EXTERNAL_ORDER_ID = A.ORDER_ID
                       AND   B.SUBSIDIARY_ID     = A.SUBSIDIARYID
                           AND   B.internal_status   = A.STATUS
                 
                )
                
);  
CREATE COLUMN TABLE U_PRJ_ECOM.TMP_ODS_SELA_API_MAGENTO_UPDATE  AS (
SELECT DISTINCT 
A.ID,
CURRENT_TIMESTAMP AS INSERTEDDATE,
A.ORDER_ID,
A.STATUS,
A.CREATION_DATE,
A.PAYMENT_APPROVED_DATE,
A.INVOICE_DATE,
A.SHIPPING_ESTIMATE_DATE,
A.HANDLING_DATE,
A.DELIVERED_DATE,
A.PAYMENT_TYPE,
A.PAYMENT_BRAND,
A.QTY_INSTALLMENTS,
A.CANCELATION_DATE,
A.SHIPPING_COST,
A.UNITS,
A.CHANNEL,
A.DISCOUNT,
A.CONSUMER_ID,
A.CURRENCY_CODE,
A.CODE,
A.DESCRIPTION,
A.PRICE,
A.QUANTITY,
A.SHIPPING_COST_SKU,
A.DISCOUNT_SKU,
A.ORDERVALUE,
A.SUBSIDIARYID,
A.COUNTRY,
A.COUNTRY_COD,
A.ORDERITEMQUANTITY,
A.SELLERINSTANCEID
FROM U_PRJ_ECOM.TMP_ODS_SELA_API_MAGENTO A
WHERE
     not exists(
                      select 1
                        from  U_PRJ_ECOM.FT_ECOM_ORDER B
                       where B.EXTERNAL_ORDER_ID = A.ORDER_ID
                       AND   B.SUBSIDIARY_ID     = A.SUBSIDIARYID
                           AND   B.internal_status   = A.STATUS
                 
                )
                
); 
CREATE COLUMN TABLE U_PRJ_ECOM.TMP_ODS_SELA_API_MAGENTO_SUB  AS (
SELECT DISTINCT 
A.ID,
CURRENT_TIMESTAMP AS INSERTEDDATE,
A.ORDER_ID,
A.STATUS,
A.CREATION_DATE,
A.PAYMENT_APPROVED_DATE,
A.INVOICE_DATE,
A.SHIPPING_ESTIMATE_DATE,
A.HANDLING_DATE,
A.DELIVERED_DATE,
A.PAYMENT_TYPE,
A.PAYMENT_BRAND,
A.QTY_INSTALLMENTS,
A.CANCELATION_DATE,
A.SHIPPING_COST,
A.UNITS,
A.CHANNEL,
A.DISCOUNT,
A.CONSUMER_ID,
A.CURRENCY_CODE,
A.CODE,
A.DESCRIPTION,
A.PRICE,
A.QUANTITY,
A.SHIPPING_COST_SKU,
A.DISCOUNT_SKU,
A.ORDERVALUE,
A.SUBSIDIARYID,
A.COUNTRY,
A.COUNTRY_COD,
A.ORDERITEMQUANTITY,
A.SELLERINSTANCEID
FROM U_PRJ_ECOM.TMP_ODS_SELA_API_MAGENTO A
WHERE
     not exists(
                      select 1
                        from  U_PRJ_ECOM.FT_ECOM_ORDER B
                       where B.EXTERNAL_ORDER_ID = A.ORDER_ID
                       AND   B.SUBSIDIARY_ID     = A.SUBSIDIARYID
                       AND      B.internal_status   = A.STATUS
                )
                
);
 
delete 
      from u_prj_ecom.tmp_ods_sela_api_magento_insert
     where code is null;
delete 
      from u_prj_ecom.tmp_ods_sela_api_magento_insert
     where upper(currency_code) != 'GTQ'
       and subsidiaryId            = 10;     
delete       
      from u_prj_ecom.tmp_ods_sela_api_magento_insert
     where lower(code) like 'cup%';
delete 
      from U_PRJ_ECOM.TMP_ODS_SELA_API_MAGENTO_UPDATE
     where code is null;
 delete 
      from U_PRJ_ECOM.TMP_ODS_SELA_API_MAGENTO_UPDATE
     where upper(currency_code) != 'GTQ'
       and subsidiaryId            = 10;       
delete       
      from  U_PRJ_ECOM.TMP_ODS_SELA_API_MAGENTO_UPDATE
     where lower(code) like 'cup%'; 
delete 
      from U_PRJ_ECOM.TMP_ODS_SELA_API_MAGENTO_SUB
     where code is null;
    
delete 
      from U_PRJ_ECOM.TMP_ODS_SELA_API_MAGENTO_SUB
     where upper(currency_code) != 'GTQ'
       and subsidiaryId            = 10;       
delete       
      from U_PRJ_ECOM.TMP_ODS_SELA_API_MAGENTO_SUB
     where lower(code) like 'cup%';
CREATE COLUMN TABLE  U_PRJ_ECOM.ODS_SELA_API_MAGENTO_TOTALS_TEMP AS (
         select order_id                               as orderId
              , sum(quantity)                          as quantity
              , sum(cast(price as decimal) * quantity) as orderValue
              , sellerInstanceId                       as seller_instance_id
              , coalesce(consumer_id, '0')             as consumer_id
              , subsidiaryId                           as subsidiary_id
              , country_cod                            as country_cod
           from u_prj_ecom.tmp_ods_sela_api_magento_insert
          where coalesce(orderValue, 0) = 0
       group by subsidiaryId
              , sellerInstanceId
              , order_id
              , coalesce(consumer_id, '0')
              , country_cod)
; 
 
CREATE COLUMN TABLE  U_PRJ_ECOM.ODS_SELA_API_MAGENTO_TOTALS_TEMP_UPDATE AS ( 
         select order_id                               as orderId
              , sum(quantity)                          as quantity
              , sum(cast(price as decimal) * quantity) as orderValue
              , sellerInstanceId                       as seller_instance_id
              , coalesce(consumer_id, '0')             as consumer_id
              , subsidiaryId                           as subsidiary_id
              , country_cod                            as country_cod
           from U_PRJ_ECOM.TMP_ODS_SELA_API_MAGENTO_UPDATE
          where coalesce(orderValue, 0) = 0
       group by     
              subsidiaryId
              , sellerInstanceId
              , order_id
              , coalesce(consumer_id, '0')
              , country_cod)
;
 
CREATE COLUMN TABLE U_PRJ_ECOM.ODS_SELA_API_MAGENTO_TOTALS_TEMP_SUB AS ( 
         select order_id                               as orderId
              , sum(quantity)                          as quantity
              , sum(cast(price as decimal) * quantity) as orderValue
              , sellerInstanceId                       as seller_instance_id
              , coalesce(consumer_id, '0')             as consumer_id
              , subsidiaryId                           as subsidiary_id
              , country_cod                            as country_cod
           from U_PRJ_ECOM.TMP_ODS_SELA_API_MAGENTO_SUB
          where coalesce(orderValue, 0) = 0
       group by     
              subsidiaryId
              , sellerInstanceId
              , order_id
              , coalesce(consumer_id, '0')
              , country_cod)
;
 
 
    update u_prj_ecom.tmp_ods_sela_api_magento_insert b
       set orderValue        = a.orderValue
         , orderItemQuantity = a.quantity
         , consumer_id       = a.consumer_id
      from u_prj_ecom.tmp_ods_sela_api_magento_insert b
      join U_PRJ_ECOM.ODS_SELA_API_MAGENTO_TOTALS_TEMP a 
       on b.subsidiaryId     = a.subsidiary_id
       and b.sellerInstanceId = a.seller_instance_id
       and b.order_id         = a.orderId
       and b.country_cod      = a.country_cod
;     
    update U_PRJ_ECOM.TMP_ODS_SELA_API_MAGENTO_UPDATE  b
       set orderValue        = a.orderValue
         , orderItemQuantity = a.quantity
         , consumer_id       = a.consumer_id
      from U_PRJ_ECOM.TMP_ODS_SELA_API_MAGENTO_UPDATE b
      join U_PRJ_ECOM.ODS_SELA_API_MAGENTO_TOTALS_TEMP_UPDATE a 
       on b.subsidiaryId     = a.subsidiary_id
       and b.sellerInstanceId = a.seller_instance_id
       and b.order_id         = a.orderId
       and b.country_cod      = a.country_cod
;   
 
        update U_PRJ_ECOM.TMP_ODS_SELA_API_MAGENTO_SUB b
       set orderValue        = a.orderValue
         , orderItemQuantity = a.quantity
         , consumer_id       = a.consumer_id
      from U_PRJ_ECOM.TMP_ODS_SELA_API_MAGENTO_SUB b
      join U_PRJ_ECOM.ODS_SELA_API_MAGENTO_TOTALS_TEMP_SUB a 
       on b.subsidiaryId     = a.subsidiary_id
       and b.sellerInstanceId = a.seller_instance_id
       and b.order_id         = a.orderId
       and b.country_cod      = a.country_cod
;   
 
 
--clientes   
 insert into u_prj_ecom.dim_customer(
           external_id
         , insert_date
         , seller_instance_id
         , subsidiary_id
    )
    select a.consumer_id              as external_id
         , now()                      as insert_date
         , a.sellerInstanceId         as seller_instance_id
         , a.subsidiaryId             as subsidiary_id
      from u_prj_ecom.tmp_ods_sela_api_magento_insert a
     where not exists (
                select 1
                  from "U_PRJ_ECOM".dim_customer z
                 where z.subsidiary_id      = a.subsidiaryId
                   and z.seller_instance_id = a.sellerInstanceId
                   and z.external_id        = coalesce(a.consumer_id, '0')
           )
       --and order_Id = '5000014960'
       --and upper(a.currency_code) = 'GTQ'   
  group by a.consumer_id
         , a.subsidiaryId
         , a.sellerInstanceId
;    
  
 
 -- Pedidos
    insert into u_prj_ecom.ft_ecom_order (
           external_order_id
         , subsidiary_id
         , creation_date
         , status
         , internal_status
         , order_value
         , customer_id
         , country
         , shipping_cost
         , discount
         , status_order_created_date
         , status_payment_approved_date
         , status_invoiced_date
         , status_start_handling_date
         , status_handling_shipping_date
         , status_delivered_date
         , status_canceled_date
         , insert_date
         , last_update_date
         , affiliate_id
         , seller_instance_id
         , source
         , cod_sales_channel
         , is_trade_in
         , hostname
    )      
    
    select distinct
           a.order_id                                   as external_order_id
         , a.subsidiaryId                               as subsidiary_id
         , cast(a.creation_date          as timeStamp)  as creation_date
         , a.status                                     as status
         , a.status                                     as internal_status
         , a.orderValue                                 as order_value
         , b.id                                         as customer_id
         , a.country                                    as country
         , cast(a.shipping_cost          as decimal)    as shipping_cost
         , cast(a.discount               as decimal)    as discount
         , cast(a.creation_date          as timeStamp)  as status_order_created_date
         , cast(a.payment_approved_date  as timeStamp)  as status_payment_approved_date
         , cast(a.invoice_date           as timeStamp)  as status_invoiced_date
         , cast(a.handling_date          as timeStamp)  as status_start_handling_date
         , cast(a.shipping_estimate_date as timeStamp)  as status_handling_shipping_date
         , cast(a.delivered_date         as timeStamp)  as status_delivered_date
         , cast(a.cancelation_date       as timeStamp)  as status_canceled_date
         , now()                                        as insert_date
         , now()                                        as last_update_date
         , 'SAMSUNG'                                    as affiliate_id
         , a.sellerInstanceId                           as seller_instance_id
         , 'jenkins'                                    as source
         , a.channel                                    as cod_sales_channel
         , 0                                            as is_trade_in
         , a.country_cod                                as hostname
      from u_prj_ecom.tmp_ods_sela_api_magento_insert a
      join u_prj_ecom.dim_customer                       b on b.external_id        = a.consumer_id
                                                            and b.subsidiary_id      = a.subsidiaryId
                                                            and b.seller_instance_id = a.sellerInstanceId
      -- 06-05-2025 Jira: S2SDSLA-7830 
      -- join U_PRJ_ECOM.ODS_SELA_API_STATUS_MAP        c  on c.origem_fix         = ltrim(rtrim(a.status))  
     where not exists (
                select 1
                  from u_prj_ecom.ft_ecom_order z
                 where z.external_order_id  = a.order_id
                   and z.subsidiary_id      = a.subsidiaryId
                   and z.seller_instance_id = a.sellerInstanceId
                   and z.hostname           = a.country_cod
           );
 
-- Pedidos Itens
    insert into u_prj_ecom.ft_ecom_order_item (
           order_id
         , product_name         
         , reference_code
         , quantity
         , discount
         , ean
         , price
         , kit
         , is_samsung_care
    )
    select distinct
           b.id                              as order_id
         , a.description                     as product_name         
         , a.code                            as reference_code
         , cast(a.quantity     as int)       as quantity
         , cast(a.discount_sku as decimal)   as discount
         , case
                when length(a.code) > 20
                then null
                else a.code
            end                              as ean
         , cast(a.price      as decimal)     as price
         , 0                                 as kit
         , 0                                 as is_samsung_care
      from u_prj_ecom.tmp_ods_sela_api_magento_insert a
      join u_prj_ecom.ft_ecom_order          b on b.external_order_id = a.order_id
     where b.subsidiary_id      = a.subsidiaryId
       and b.source             = 'jenkins'
       and b.seller_instance_id = a.sellerInstanceId
       and b.hostname           = a.country_cod
       and not exists (
                select 1
                  from u_prj_ecom.ft_ecom_order_item z
                 where z.order_id       = b.id
                   and z.reference_code = a.code
           );
                
-- Pagamentos
    insert into u_prj_ecom.ft_ecom_order_payment (
           order_id
         , payment_type         
         , installment
         , brand
         , value
    )
    select distinct
           b.id                              as order_id
         , left(a.payment_type, 23)          as payment_type
         , coalesce(
            cast(a.qty_installments as int)
            , 1)                             as installment
         , left(a.payment_brand, 24)         as brand
         , a.orderValue                      as value
      from u_prj_ecom.tmp_ods_sela_api_magento_insert a
      join u_prj_ecom.ft_ecom_order          b on b.external_order_id = a.order_id
     where b.subsidiary_id      = a.subsidiaryId
       and b.source             = 'jenkins'
       and b.seller_instance_id = a.sellerInstanceId
       and b.hostname           = a.country_cod
       and not exists (
                select 1
                  from u_prj_ecom.ft_ecom_order_payment z
                 where z.order_id       = b.id
           );
       --and upper(a.currency_code) = 'GTQ';     
       --and order_Id = '5000014960';          
--clientes   
 insert into u_prj_ecom.dim_customer(
           external_id
         , insert_date
         , seller_instance_id
         , subsidiary_id
    )
    select a.consumer_id              as external_id
         , now()                      as insert_date
         , a.sellerInstanceId         as seller_instance_id
         , a.subsidiaryId             as subsidiary_id
      from U_PRJ_ECOM.TMP_ODS_SELA_API_MAGENTO_SUB a
     where not exists (
                select 1
                  from u_prj_ecom.dim_customer z
                 where z.subsidiary_id      = a.subsidiaryId
                   and z.seller_instance_id = a.sellerInstanceId
                   and z.external_id        = coalesce(a.consumer_id, '0')
           )
       --and order_Id = '5000014960'
       --and upper(a.currency_code) = 'GTQ'   
  group by a.consumer_id
         , a.subsidiaryId
         , a.sellerInstanceId
;    
   
 
 -- Pedidos
    insert into u_prj_ecom.ft_ecom_order (
           external_order_id
         , subsidiary_id
         , creation_date
         , status
         , internal_status
         , order_value
         , customer_id
         , country
         , shipping_cost
         , discount
         , status_order_created_date
         , status_payment_approved_date
         , status_invoiced_date
         , status_start_handling_date
         , status_handling_shipping_date
         , status_delivered_date
         , status_canceled_date
         , insert_date
         , last_update_date
         , affiliate_id
         , seller_instance_id
         , source
         , cod_sales_channel
         , is_trade_in
         , hostname
    )      
    
    select distinct
           a.order_id                                   as external_order_id
         , a.subsidiaryId                               as subsidiary_id
         , cast(a.creation_date          as timeStamp)  as creation_date
         , a.status                                     as status
         , a.status                                     as internal_status
         , a.orderValue                                 as order_value
         , b.id                                         as customer_id
         , a.country                                    as country
         , cast(a.shipping_cost          as decimal)    as shipping_cost
         , cast(a.discount               as decimal)    as discount
         , cast(a.creation_date          as timeStamp)  as status_order_created_date
         , cast(a.payment_approved_date  as timeStamp)  as status_payment_approved_date
         , cast(a.invoice_date           as timeStamp)  as status_invoiced_date
         , cast(a.handling_date          as timeStamp)  as status_start_handling_date
         , cast(a.shipping_estimate_date as timeStamp)  as status_handling_shipping_date
         , cast(a.delivered_date         as timeStamp)  as status_delivered_date
         , cast(a.cancelation_date       as timeStamp)  as status_canceled_date
         , now()                                        as insert_date
         , now()                                        as last_update_date
         , 'SAMSUNG'                                    as affiliate_id
         , a.sellerInstanceId                           as seller_instance_id
         , 'jenkins'                                    as source
         , a.channel                                    as cod_sales_channel
         , 0                                            as is_trade_in
         , a.country_cod                                as hostname
      from U_PRJ_ECOM.TMP_ODS_SELA_API_MAGENTO_SUB a
      join u_prj_ecom.dim_customer                     b on b.external_id        = a.consumer_id
                                                          and b.subsidiary_id      = a.subsidiaryId
                                                          and b.seller_instance_id = a.sellerInstanceId
      -- 06-05-2025 Jira: S2SDSLA-7830
      -- join U_PRJ_ECOM.ODS_SELA_API_STATUS_MAP        c on c.origem_fix         = ltrim(rtrim(a.status))  
     where not exists (
                select 1
                  from u_prj_ecom.ft_ecom_order z
                 where z.external_order_id  = a.order_id
                   and z.subsidiary_id      = a.subsidiaryId
                   and z.seller_instance_id = a.sellerInstanceId
                   and z.hostname           = a.country_cod
           );
-- Pedidos Itens
    insert into u_prj_ecom.ft_ecom_order_item (
           order_id
         , product_name         
         , reference_code
         , quantity
         , discount
         , ean
         , price
         , kit
         , is_samsung_care
    )
    select distinct
           b.id                              as order_id
         , a.description                     as product_name         
         , a.code                            as reference_code
         , cast(a.quantity     as int)       as quantity
         , cast(a.discount_sku as decimal)   as discount
         , case
                when length(a.code) > 20
                then null
                else a.code
            end                              as ean
         , cast(a.price      as decimal)     as price
         , 0                                 as kit
         , 0                                 as is_samsung_care
      from U_PRJ_ECOM.TMP_ODS_SELA_API_MAGENTO_SUB a
      join u_prj_ecom.ft_ecom_order          b on b.external_order_id = a.order_id
     where b.subsidiary_id      = a.subsidiaryId
       and b.source             = 'jenkins'
       and b.seller_instance_id = a.sellerInstanceId
       and b.hostname           = a.country_cod
       and not exists (
                select 1
                  from u_prj_ecom.ft_ecom_order_item z
                 where z.order_id       = b.id
                   and z.reference_code = a.code
           );
-- Pagamentos
    insert into u_prj_ecom.ft_ecom_order_payment (
           order_id
         , payment_type         
         , installment
         , brand
         , value
    )
    select distinct
           b.id                              as order_id
         , left(a.payment_type, 23)          as payment_type
         , coalesce(
            cast(a.qty_installments as int)
            , 1)                             as installment
         , left(a.payment_brand, 24)         as brand
         , a.orderValue                      as value
      from U_PRJ_ECOM.TMP_ODS_SELA_API_MAGENTO_SUB a
      join u_prj_ecom.ft_ecom_order          b on b.external_order_id = a.order_id
     where b.subsidiary_id      = a.subsidiaryId
       and b.source             = 'jenkins'
       and b.seller_instance_id = a.sellerInstanceId
       and b.hostname           = a.country_cod
       and not exists (
                select 1
                  from u_prj_ecom.ft_ecom_order_payment z
                 where z.order_id       = b.id
           );
create column table U_PRJ_ECOM.ODS_SELA_API_MAGENTO_UPDATE_TEMP as (
    select distinct
           a.order_id                                   as external_order_id
         , a.subsidiaryId                               as subsidiary_id
         , a.sellerInstanceId                           as seller_instance_id
         , cast(a.creation_date          as timeStamp)  as creation_date
         , a.status                                     as status
         , a.status                                     as internal_status
         , country_cod                                  as hostname
         ,CURRENT_TIMESTAMP                             as last_update_date
     from  U_PRJ_ECOM.TMP_ODS_SELA_API_MAGENTO_UPDATE    a
     -- 06-05-2025 Jira: S2SDSLA-7830
     -- join  U_PRJ_ECOM.ODS_SELA_API_STATUS_MAP  b on b.origem_fix    = ltrim(rtrim(a.status))
);
 
    UPDATE u_prj_ecom.ft_ecom_order  so
       SET 
           so.status = tmp.status,
           so.internal_status= tmp.internal_status,
           so.last_update_date = tmp.last_update_date
         
          
      FROM U_PRJ_ECOM.ft_ecom_order so
         join U_PRJ_ECOM.ODS_SELA_API_MAGENTO_UPDATE_TEMP  tmp ON so.external_order_id =  tmp.external_order_id 
                                                               and so.subsidiary_id     =  tmp.subsidiary_id 
                                                               and so.status            <> tmp.status
 ;
--- insert ods
     insert into U_PRJ_ECOM.ODS_SELA_API_MAGENTO
    (
    ID,
ORDER_ID,
STATUS,
CREATION_DATE,
PAYMENT_APPROVED_DATE,
INVOICE_DATE,
SHIPPING_ESTIMATE_DATE,
HANDLING_DATE,
DELIVERED_DATE,
PAYMENT_TYPE,
PAYMENT_BRAND,
QTY_INSTALLMENTS,
CANCELATION_DATE,
SHIPPING_COST,
UNITS,
CHANNEL,
DISCOUNT,
CONSUMER_ID,
CURRENCY_CODE,
CODE,
DESCRIPTION,
PRICE,
QUANTITY,
SHIPPING_COST_SKU,
DISCOUNT_SKU,
ORDERVALUE,
SUBSIDIARYID,
COUNTRY,
COUNTRY_COD,
ORDERITEMQUANTITY,
SELLERINSTANCEID
    )
SELECT DISTINCT 
a.ID,
a.ORDER_ID,
a.STATUS,
a.CREATION_DATE,
a.PAYMENT_APPROVED_DATE,
a.INVOICE_DATE,
a.SHIPPING_ESTIMATE_DATE,
a.HANDLING_DATE,
a.DELIVERED_DATE,
a.PAYMENT_TYPE,
a.PAYMENT_BRAND,
a.QTY_INSTALLMENTS,
a.CANCELATION_DATE,
a.SHIPPING_COST,
a.QUANTITY AS UNITS,
a.CHANNEL,
a.DISCOUNT,
a.CONSUMER_ID,
a.CURRENCY_CODE,
a.CODE,
a.DESCRIPTION,
a.PRICE,
a.QUANTITY,
a.SHIPPING_COST_SKU,
a.DISCOUNT_SKU,
a.ORDERVALUE,
a.SUBSIDIARYID,
a.COUNTRY,
a.COUNTRY_COD,
a.ORDERITEMQUANTITY,
a.SELLERINSTANCEID
FROM u_prj_ecom.tmp_ods_sela_api_magento_insert a
WHERE
     not exists(
                      select 1
                        from  U_PRJ_ECOM.ODS_SELA_API_MAGENTO B
                       where B.ORDER_ID           = A.ORDER_ID
                       AND   B.CODE               = A.CODE
                       AND   B.SUBSIDIARYID       = A.SUBSIDIARYID
 
                 
                );
                
                
-- update ods
    UPDATE U_PRJ_ECOM.ODS_SELA_API_MAGENTO   so
       SET 
           so.status = tmp.status,
       so.last_update_date = tmp.last_update_date
   
          
      FROM U_PRJ_ECOM.ODS_SELA_API_MAGENTO  so
      JOIN  U_PRJ_ECOM.ODS_SELA_API_MAGENTO_UPDATE_TEMP      tmp  on  so.order_id = tmp.external_order_id 
                                                                 and so.SUBSIDIARYID = tmp.subsidiary_id
                                                                 AND so.status <> tmp.status
        
        
        ;
       END