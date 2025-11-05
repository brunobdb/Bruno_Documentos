CREATE PROCEDURE u_prj_ecom.proc_ods_diggit_ecom_orders
 LANGUAGE SQLSCRIPT AS
 begin
 
        -- Problemas --
        -- Order codes mudam de data de criação de pedidos: S519866
        -- Order codes mudam quantidade de itens: S519866
        -- Order codes mudam store name: 2000006855519486 
 
        declare order_creation_min date;
        declare order_creation_max date;        
        
        select min(order_creation_date)  as order_creation_min
             , max(order_creation_date)  as order_creation_max
          into order_creation_min
             , order_creation_max
          from u_prj_ecom.stg_diggit_ecom_orders;
          
          
        select :order_creation_min as order_creation_min
             , :order_creation_max as order_creation_max
          from dummy;
          
          --drop table #stg_diggit_ecom_orders_aggregation;
        create local temporary table #stg_diggit_ecom_orders_aggregation 
            as (
                    
                   
select 
order_code,
order_creation_date,
order_creation_hour,
country,
sku,
order_status,
channel,
store_name,
currency,
qty,
product_price,
revenue
from (
select a.order_code
                        , a.order_creation_date
                        , a.order_creation_hour
                        , a.country
                        , a.sku
                        , a.order_status
                        , a.channel
                        , a.store_name
                        , a.currency
                        , sum(cast(a.qty     as int    ))   as qty
                        , a.product_price
                        , sum(cast(a.revenue as decimal))   as revenue,
        row_number() over (partition by order_code order by order_creation_date desc, order_creation_hour desc) as rn
                     from   u_prj_ecom.stg_diggit_ecom_orders a
                   --  where a.order_code  in ('156424274-1366545')
                 group by a.order_code
                        , a.country
                        , a.sku
                        , a.order_status
                        , a.channel
                        , a.store_name
                        , a.currency
                        , a.product_price
                        , a.order_creation_date
                        , a.order_creation_hour
 )
 where rn = 1
                        
            );        
            
            
           select cast(min(order_creation_date) as date)  as order_creation_min
                , cast(max(order_creation_date) as date)  as order_creation_max
             from #stg_diggit_ecom_orders_aggregation;            
          
          
        orders_codes_cancelleds =   select distinct 
                                           a.order_code
                                         , a.sku
                                      from u_prj_ecom.ods_diggit_ecom_orders a
                                     where order_creation_date between :order_creation_min and :order_creation_max
                                       and not exists(
                                                select 1
                                                  from u_prj_ecom.stg_diggit_ecom_orders aa
                                                 where aa.order_code = a.order_code
                                                   and aa.sku        = a.sku
                                                   and aa.store_name = a.store_name
                                           );
               
         update u_prj_ecom.ods_diggit_ecom_orders a
            set order_status      = 'Cancelled'
              , updated_timestamp = current_timestamp
           from u_prj_ecom.ods_diggit_ecom_orders a
           join :orders_codes_cancelleds          b on b.order_code = a.order_code
                                                   and b.sku        = a.sku
          where 1 = 1
            and order_status != 'Cancelled';
          
       
           
           
          merge into u_prj_ecom.ods_diggit_ecom_orders   a
               using #stg_diggit_ecom_orders_aggregation b on b.order_code = a.order_code
                                                          and b.sku        = a.sku
                 when    matched then update  
                                         set a.channel             = b.channel
                                           , a.store_name          = b.store_name  
                                           , a.currency            = b.currency
                                           , a.qty                 = b.qty
                                           , a.product_price       = b.product_price
                                           , a.revenue             = b.revenue
                                           , a.order_status        = b.order_status
                                           , a.order_creation_date = b.order_creation_date
                                           , a.order_creation_hour = b.order_creation_hour
                                           , a.updated_timestamp   = current_timestamp         
                                                  
                 when not matched then insert(  
                                                   order_code
                                                 , order_creation_date
                                                 , order_creation_hour
                                                 , country
                                                 , sku
                                                 , order_status
                                                 , channel
                                                 , store_name
                                                 , currency
                                                 , qty
                                                 , product_price
                                                 , revenue   
                                       )
                                       values(
                                                   b.order_code
                                                 , b.order_creation_date
                                                 , b.order_creation_hour
                                                 , b.country
                                                 , b.sku
                                                 , b.order_status
                                                 , b.channel
                                                 , b.store_name
                                                 , b.currency
                                                 , b.qty
                                                 , b.product_price
                                                 , b.revenue   
                                       );                                               
 
   end