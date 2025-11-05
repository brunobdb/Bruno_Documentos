CREATE procedure ow_lao.ods_stockout_vtex_globalbi_seda_generate
    as 
begin
    create local temporary table #stg_stockout_vtex_globalbi_seda
        as (
              select country_cd
                   , store_type
                   , store_name
                   , warehouse
                   , product_code
                   , in_stock_status
                   , max(cast(available_amount as int))   as available_amount
                   , max(cast(reserved_amount as int))    as reserved_amount
                   , max(cast(overselling_amount as int)) as overselling_amount
                   , max(cast(pre_order as int))          as pre_order
                   , max(cast(max_preorder as int))       as max_preorder
                   , max(cast(safety_stock as int))       as safety_stock
                   , sales_status
                   , approval_status
                   , max(cast(net_quantity as int))       as net_quantity
                   , is_status
                   , is_allow_back_order
                   , catalog
                   , time_created
                   , time_modified
                   , overselling_shippingdate
                   , number_of_customer_email_registrations
                   , wrehouse_operator
                   , cast(cast(file_name_generated_date as date) 
                        || ' ' || 
                            cast(file_name_generated_time  as time) as timestamp) as file_name_generated_timestamp
                  from ow_lao.stg_stockout_vtex_globalbi_seda
            group by country_cd
                   , store_type
                   , store_name
                   , warehouse
                   , product_code
                   , in_stock_status
                   , sales_status
                   , approval_status
                   , is_status
                   , is_allow_back_order
                   , catalog
                   , time_created
                   , time_modified
                   , overselling_shippingdate
                   , number_of_customer_email_registrations
                   , wrehouse_operator
                   , cast(cast(file_name_generated_date as date) 
                        || ' ' || 
                            cast(file_name_generated_time  as time) as timestamp) 
        ); 
     merge into ow_lao.ods_stockout_vtex_globalbi       a
          using #stg_stockout_vtex_globalbi_seda        b on b.country_cd        = a.country_cd
                                                         and b.wrehouse_operator = a.wrehouse_operator
                                                         and b.warehouse         = a.warehouse
                                                         and b.product_code      = a.product_code
           when    matched then update  
                                   set a.updated_timestamp                      = current_timestamp
                                     , a.country_cd                             = b.country_cd
                                     , a.store_type                             = b.store_type
                                     , a.store_name                             = b.store_name
                                     , a.warehouse                              = b.warehouse
                                     , a.product_code                           = b.product_code
                                     , a.in_stock_status                        = b.in_stock_status
                                     , a.available_amount                       = b.available_amount
                                     , a.reserved_amount                        = b.reserved_amount
                                     , a.overselling_amount                     = b.overselling_amount
                                     , a.pre_order                              = b.pre_order
                                     , a.max_preorder                           = b.max_preorder
                                     , a.safety_stock                           = b.safety_stock
                                     , a.sales_status                           = b.sales_status
                                     , a.approval_status                        = b.approval_status
                                     , a.net_quantity                           = b.net_quantity
                                     , a.is_status                              = b.is_status
                                     , a.is_allow_back_order                    = b.is_allow_back_order
                                     , a.catalog                                = b.catalog
                                     , a.time_created                           = b.time_created
                                     , a.time_modified                          = b.time_modified
                                     , a.overselling_shippingdate               = b.overselling_shippingdate
                                     , a.number_of_customer_email_registrations = b.number_of_customer_email_registrations
                                     , a.wrehouse_operator                      = b.wrehouse_operator
                                     , a.file_name_generated_timestamp          = b.file_name_generated_timestamp
           when not matched then insert(
                                        country_cd
                                      , store_type
                                      , store_name
                                      , warehouse
                                      , product_code
                                      , in_stock_status
                                      , available_amount
                                      , reserved_amount
                                      , overselling_amount
                                      , pre_order
                                      , max_preorder
                                      , safety_stock
                                      , sales_status
                                      , approval_status
                                      , net_quantity
                                      , is_status
                                      , is_allow_back_order
                                      , catalog
                                      , time_created
                                      , time_modified
                                      , overselling_shippingdate
                                      , number_of_customer_email_registrations
                                      , wrehouse_operator
                                      , file_name_generated_timestamp
                                 )
                                 values(
                                        b.country_cd
                                      , b.store_type
                                      , b.store_name
                                      , b.warehouse
                                      , b.product_code
                                      , b.in_stock_status
                                      , b.available_amount
                                      , b.reserved_amount
                                      , b.overselling_amount
                                      , b.pre_order
                                      , b.max_preorder
                                      , b.safety_stock
                                      , b.sales_status
                                      , b.approval_status
                                      , b.net_quantity
                                      , b.is_status
                                      , b.is_allow_back_order
                                      , b.catalog
                                      , b.time_created
                                      , b.time_modified
                                      , b.overselling_shippingdate
                                      , b.number_of_customer_email_registrations
                                      , b.wrehouse_operator
                                      , b.file_name_generated_timestamp
                                 );     
  end