
CREATE procedure ow_lao.proc_monitoring_bi_lao_proccess_sales_order_tracking
 LANGUAGE SQLSCRIPT AS
 BEGIN
  
    declare synapcomMaxInserted          timestamp = null;
    declare salesOrderTrackingDaysFilter int       =  -5;
    
    select max(po_source_insert_date) as po_source_insert_date
      into synapcomMaxInserted
      from ow_lao.ods_sales_control_tower_table
     where po_plataform_datasource in ('u_prj_ecom_synapcom.ft_ecom_order', 'u_prj_ecom.ft_ecom_order');    
  
             drop table ow_lao.temp_ods_sales_control_tower_table_nerp_update_monitoring_filter;     
    create column table ow_lao.temp_ods_sales_control_tower_table_nerp_update_monitoring_filter
        as ( 
                select distinct
                       row_number() over() as id
                     , a.customer_po
                     , a.sales_document
                     , a.material
                     , a.sales_org
                     , a.load_date
                  from ow_lao.ods_nerp_zrsdd6a120_sales_order_tracking a
                 where 1 = 0
              order by load_date desc
        );  
        
                
           insert into ow_lao.temp_ods_sales_control_tower_table_nerp_update_monitoring_filter(
                       id
                     , customer_po
                     , sales_document
                     , material
                     , sales_org
                     , load_date
           )
           
                select distinct
                       row_number() over() as id
                     , a.customer_po
                     , a.sales_document
                     , a.material
                     , a.sales_org
                     , a.load_date
                  from ow_lao.ods_nerp_zrsdd6a120_sales_order_tracking a
                 where cast(a.so_create_on as date)   >= add_days(current_date, :salesOrderTrackingDaysFilter)
                   and a.sales_org               = '8201'
                   and a.sales_doc_type          = 'YS10'
                   and a.last_modification_file <= :synapcomMaxInserted
              order by load_date desc;       
        
             drop table ow_lao.temp_ods_sales_control_tower_table_nerp_update_monitoring_filter_delete;     
    create column table ow_lao.temp_ods_sales_control_tower_table_nerp_update_monitoring_filter_delete
        as ( 
                select c.*
                  from ow_lao.ods_sales_control_tower_table                                    a 
                  join ow_md.dim_subsidiary                                                    b on lower(b.country) = lower(a.country)
                  join ow_lao.temp_ods_sales_control_tower_table_nerp_update_monitoring_filter c on c.customer_po = a.po_sequence_orderid
                                                                                                and c.sales_org   = b.sales_org
                                                                                                
                 union all
                 
                select c.*
                  from ow_lao.ods_sales_control_tower_table                                    a 
                  join ow_md.dim_subsidiary                                                    b on lower(b.country) = lower(a.country)
                  join ow_lao.temp_ods_sales_control_tower_table_nerp_update_monitoring_filter c on c.sales_document = a.po_ordersid
                                                                                                and c.sales_org      = b.sales_org  
                                                                                                
                 union all
                 
                select c.*
                  from ow_lao.ods_sales_control_tower_table                                    a 
                  join ow_md.dim_subsidiary                                                    b on lower(b.country) = lower(a.country)
                  join ow_lao.temp_ods_sales_control_tower_table_nerp_update_monitoring_filter c on c.customer_po    = a.po_orderid
                                                                                                and c.sales_org      = b.sales_org                                                                                                                
        );           
 
        delete
          from ow_lao.temp_ods_sales_control_tower_table_nerp_update_monitoring_filter a
         where id in (select distinct id from ow_lao.temp_ods_sales_control_tower_table_nerp_update_monitoring_filter_delete);    
       insert into ow_lao.monitoring_bi_lao_proccess(
                   origem_nome
                 , processo_nome
                 , referencia
                 , quantidade
       )
       
            select 'ow_lao.ods_nerp_zrsdd6a120_sales_order_tracking' as origem_nome
                 , 'Control Tower'                                   as processo_nome
                 , concat(
                    concat(
                        concat('customer_po: ', customer_po)
                       , 'sales_document: ')
                     , sales_document)                               as referencia
                 , count(1)                                          as quantidade
              from ow_lao.temp_ods_sales_control_tower_table_nerp_update_monitoring_filter
             where not exists(
                        select 1
                          from ow_lao.monitoring_bi_lao_proccess cc
                         where cc.processo_nome = 'Control Tower'
                           and cc.origem_nome   = 'ow_lao.ods_nerp_zrsdd6a120_sales_order_tracking'
                           and cc.status_nome   = 'Em analise'
                           and cc.referencia    = concat(
                                                    concat(
                                                        concat('customer_po: ', customer_po)
                                                       , 'sales_document: ')
                                                     , sales_document)
                                                   )
          group by concat(
                    concat(
                        concat('customer_po: ', customer_po)
                       , 'sales_document: ')
                     , sales_document);
     end