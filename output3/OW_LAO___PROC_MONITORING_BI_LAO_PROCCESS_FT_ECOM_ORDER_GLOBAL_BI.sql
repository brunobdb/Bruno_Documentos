CREATE procedure ow_lao.proc_monitoring_bi_lao_proccess_ft_ecom_order_global_bi
 LANGUAGE SQLSCRIPT AS
 begin
    declare default_searching_timestamp timestamp = '2024-08-08';
    declare start_searching_timestamp   timestamp = null;
    declare end_searching_timestamp     timestamp = null;
    
    select case 
                when add_days(current_timestamp, -30) < :default_searching_timestamp
                then :default_searching_timestamp
                else add_days(current_timestamp, -30)
            end
         , add_seconds(max(last_update_files), -3600)
      into start_searching_timestamp
         , end_searching_timestamp
      from u_prj_ecom.raw_feed_send_estore;
     
    select a.creation_date
         , a.order_id
         , b.ref_id
         , a.status
         , a.created_at
         , a.updated_at
      from u_prj_ecom.raw_vtex_ssg_br_shop_sales_order      a
      join u_prj_ecom.raw_vtex_ssg_br_shop_sales_order_item b on b.order_id       = a.order_id
 left join OW_LAO.TF_D2C_PO_VTEX_TRADE_IN                   c on c.order_id       = a.order_id
                                                             and c.SKU_ID_BR_SHOP = b.sku_id
                                                             and c.SKU_ID_BR_SHOP = c.TRADE_IN_SKUID
 left join OW_LAO.TF_D2C_PO_VTEX_TRADE_IN                   d on d.order_id       = a.order_id
                                                             and d.SKU_ID_BR_SHOP = b.sku_id
     where 1 = 1
       --and a.order_id = '1445424939729-01'
       and coalesce(a.updated_at, a.created_at) between start_searching_timestamp
                                                    and end_searching_timestamp
       and not exists(
                select 1
                  from u_prj_ecom.raw_vtex_ssg_br_shop_sales_order_item_components bb
                 where bb.order_id = a.order_id
           )
       and not exists(
                select 1
                  from u_prj_ecom.raw_feed_send_estore aa
                 where aa.order_code              = a.order_id
                   and aa.product_code            = b.ref_id
                   and case aa.order_status
                            when 'payment rejected'
                            then 'canceled'
                            else aa.order_status
                         end                      = a.status                                               
           )
       and not exists(
                select 1
                  from u_prj_ecom.raw_feed_send_estore aa
                 where aa.order_code              = a.order_id
                   and aa.product_code            = b.ref_id
                   and aa.order_status            = 'delivered'                                       
           )
           
     union all    
       
    select a.creation_date
         , a.order_id
         , e.ref_id
         , a.status
         , a.created_at
         , a.updated_at
      from u_prj_ecom.raw_vtex_ssg_br_shop_sales_order                 a
      join u_prj_ecom.raw_vtex_ssg_br_shop_sales_order_item            b on b.order_id       = a.order_id
      join u_prj_ecom.raw_vtex_ssg_br_shop_sales_order_item_components e on e.order_id       = a.order_id
                                                                        and e.sku_id         = b.sku_id
 left join OW_LAO.TF_D2C_PO_VTEX_TRADE_IN                              c on c.order_id       = a.order_id
                                                                        and c.SKU_ID_BR_SHOP = b.sku_id
                                                                        and c.SKU_ID_BR_SHOP = c.TRADE_IN_SKUID
 left join OW_LAO.TF_D2C_PO_VTEX_TRADE_IN                              d on d.order_id       = a.order_id
                                                                        and d.SKU_ID_BR_SHOP = b.sku_id
     where coalesce(a.updated_at, a.created_at) between start_searching_timestamp
                                                   and end_searching_timestamp
       --and a.external_order_id = '1444684897281-01'
       and not exists(
                select 1
                  from u_prj_ecom.raw_feed_send_estore aa
                 where aa.order_code              = a.order_id
                   and aa.product_code            = e.ref_id
                   and case aa.order_status
                            when 'payment rejected'
                            then 'canceled'
                            else aa.order_status
                         end                      = a.status 
           )
           
     union all
      
    select a.creation_date
         , a.order_id
         , b.ref_id
         , a.status
         , a.created_at
         , a.updated_at
      from u_prj_ecom.raw_vtex_ssg_br_shop_sales_order      a
      join u_prj_ecom.raw_vtex_ssg_br_shop_sales_order_item b on b.order_id       = a.order_id
     where coalesce(a.updated_at, a.created_at) between start_searching_timestamp
                                                    and end_searching_timestamp
       and not exists(
                select 1
                  from u_prj_ecom.raw_vtex_ssg_br_shop_sales_order_item_components bb
                 where bb.order_id = a.order_id
           )
       and not exists(
                select 1
                  from u_prj_ecom.raw_feed_send_estore aa
                 where aa.order_code              = a.order_id
                   and aa.product_code            = b.ref_id
                                               
           );
      
   end