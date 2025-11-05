create procedure ow_lao.ods_sales_control_tower_table_ods_sela_custom_orders_items_update
    as
 begin
 
      --drop table #ods_sales_control_tower_table_ods_sela_custom_orders_items_update_prepare;
    create local temporary table #ods_sales_control_tower_table_ods_sela_custom_orders_items_update_prepare
        as (
                select a.subsidiary_id    as client_subsidiary_id
                     , a.account          as po_sitecode
                     , a.order_id         as po_orderid
                     , a.code             as po_sku
                     , a.delivered_date   as nerp_billingdate
                     , a.invoice_date     as so_date
                     , a.delivered_date   as do_date
                     , a.delivered_date   as billing_date_local
                  from ow_lao.ods_sela_custom_orders_items a
                 where 1 = 1
                   and (a.delivered_date is not null or a.invoice_date is not null)
        );   
        
        
        update ow_lao.ods_sales_control_tower_table a
           set nerp_billingdate   = b.nerp_billingdate
             , so_date            = b.so_date
             , do_date            = b.do_date
             , billing_date_local = b.billing_date_local
          from ow_lao.ods_sales_control_tower_table a
          join #ods_sales_control_tower_table_ods_sela_custom_orders_items_update_prepare b on b.po_orderid           = a.po_orderid
                                                                                           and b.po_sku               = a.po_sku
                                                                                           and b.client_subsidiary_id = a.client_subsidiary_id
                                                                                           and b.po_sitecode          = a.po_sitecode;                                                                                        
 end