CREATE procedure ow_lao.proc_ods_sales_control_tower_sales_check_datasource
language sqlscript as
begin
    -- dataset de ecommerce_orders
    with ecommerce_orders as ( 
        select 
            max(coalesce(po_source_last_update_date, po_source_insert_date)) as last_data,
            'ods_sales_control_tower_table' as origin,
            case 
                when subsidiary like 'SELA%' then 'SELA' 
                else subsidiary 
            end as subsidiary,
            case 
                when cast(po_source_last_update_date as date) = current_date then 'OK'
                when subsidiary like 'SELA%' 
                and cast(po_source_last_update_date as date) >= add_days(current_date, -1) then 'OK'
                when country = 'Uruguay'
                and cast(po_source_last_update_date as date) >= add_days(current_date, -10) then 'OK'
                else 'NOT OK'
            end as status,
            country
        from ow_lao.ods_sales_control_tower_table
        where po_plataform_datasource not in ('ow_lao.ods_global_bi_sales', 'u_prj_ecom_synapcom.ft_ecom_order')
          and (subsidiary, country, po_source_last_update_date) in (
              select 
                  subsidiary, 
                  country,
                  max(po_source_last_update_date) as po_source_last_update_date
              from ow_lao.ods_sales_control_tower_table
              where cast(po_source_last_update_date as date) between add_days(current_date, -10) and current_date
              group by subsidiary, country
          )
        group by po_source_last_update_date, subsidiary, country
        order by subsidiary, country
    ), 
    -- dataset de complementary_data
    complementary_data as (
        select 
            max(nerp_last_update_date) as sales_order_tracking_timestamp,
            case
                when seconds_between(max(nerp_last_update_date), current_timestamp) / 60 <= 60 then 'OK'
                else 'NOT OK'
            end as sales_order_tracking_status,
            max(nerp_outbound_last_update_date) as outbound_timestamp,
            case
                when seconds_between(max(nerp_outbound_last_update_date), current_timestamp) / 60 <= 60 then 'OK'
                else 'NOT OK'
            end as outbound_status,
            max(ebi_last_update_date) as global_bi_timestamp,
            case
                when seconds_between(max(ebi_last_update_date), current_timestamp) / 60 <= 1440 then 'OK'
                else 'NOT OK'
            end as global_bi_status,
            max(po_source_payment_last_update_date) as payment_timestamp,
            case
                when seconds_between(max(po_source_payment_last_update_date), current_timestamp) / 60 <= 60 then 'OK'
                else 'NOT OK'
            end as payment_status,
            null as country, -- placeholder para alinhar os campos
            null as subsidiary -- placeholder para alinhar os campos
        from ow_lao.ods_sales_control_tower_table
    )   
    -- união dos dados com o campo country incluído
    select 
        map(element_number, 
            1, 'sales order tracking',
            2, 'outbound',
            3, 'global bi files',
            4, 'payments'
        ) as origin,
        map(element_number, 
            1, sales_order_tracking_status,
            2, outbound_status,
            3, global_bi_status,
            4, payment_status
        ) as status,
        map(element_number, 
            1, sales_order_tracking_timestamp,
            2, outbound_timestamp,
            3, global_bi_timestamp,
            4, payment_timestamp
        ) as last_data,
        country, -- adicionado para alinhar os campos
        subsidiary -- adicionado null para alinhar a estrutura
    from complementary_data
    cross join series_generate_integer(1, 1, 5) 
    union all
    select 
        origin,
        status,
        last_data,
        country,
        subsidiary
    from ecommerce_orders;
end