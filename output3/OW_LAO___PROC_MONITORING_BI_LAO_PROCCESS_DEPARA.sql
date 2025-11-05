CREATE procedure ow_lao.proc_monitoring_bi_lao_proccess_depara
 LANGUAGE SQLSCRIPT AS
 BEGIN
       insert into ow_lao.monitoring_bi_lao_proccess(
                   origem_nome
                 , processo_nome
                 , referencia
                 , quantidade
       )
                  
        select 'ow_md.sales_channel'          as dataSource
             , 'Control Tower'                as proccess
             , a.po_orderid                   as referencia
             , count(1)                       as quantity    
          from ow_lao.ods_sales_control_tower_table a
         where a.channel is null
           and po_source_insert_date > '20240501'
           and not exists(
                     select 1
                       from ow_lao.monitoring_bi_lao_proccess cc
                      where cc.processo_nome = 'Control Tower'
                        and cc.origem_nome   = 'ow_md.sales_channel'
                        and cc.referencia    = a.po_orderid
                        and cc.status_nome   = 'Em analise'
               )
      group by a.po_orderid;
      
       insert into ow_lao.monitoring_bi_lao_proccess(
                   origem_nome
                 , processo_nome
                 , referencia
                 ,OBSERVACAO 
                 , quantidade
       )      
         
        select 'ow_lao.dim_ods_sales_control_tower_table_status_mapping' as dataSource
             , 'Control Tower'                                           as proccess
             , a.po_internal_status                                      as referencia
             ,'Realize o mapeamento de STATUS_ORIGIN: "' || a.po_internal_status || '" na tabela ow_lao.dim_ods_sales_control_tower_table_status_mapping' AS observacao
             , count(1)                                                  as quantity    
          from ow_lao.ods_sales_control_tower_table a
         where a.po_status is null 
           and a.po_internal_status is not null
           and not exists(
                     select 1
                       from ow_lao.monitoring_bi_lao_proccess cc
                      where cc.processo_nome = 'Control Tower'
                        and cc.origem_nome   = 'ow_lao.dim_ods_sales_control_tower_table_status_mapping'
                        and cc.referencia    = a.po_internal_status
                        and cc.status_nome   = 'Em analise'
               )
      group by a.po_internal_status;
      
       insert into ow_lao.monitoring_bi_lao_proccess(
                   origem_nome
                 , processo_nome
                 , referencia
                 , quantidade
       )      
         
        select 'ow_lao.ft_ap2_exchange_rate'  as dataSource
             , 'Control Tower'                as proccess
             , a.po_orderid                   as referencia
             , count(1)                       as quantity    
          from ow_lao.ods_sales_control_tower_table a
         where a.po_totalprice_usd is null
           and a.po_totalprice_local is not null     
           and not exists(
                     select 1
                       from ow_lao.monitoring_bi_lao_proccess cc
                      where cc.processo_nome = 'Control Tower'
                        and cc.origem_nome   = 'ow_lao.ft_ap2_exchange_rate'
                        and cc.referencia    = a.po_orderid
                        and cc.status_nome   = 'Em analise'
               )
      group by a.po_orderid;
      
       insert into ow_lao.monitoring_bi_lao_proccess(
                   origem_nome
                 , processo_nome
                 , referencia
                 , quantidade
       )           
         
        select 'ow_lao.dim_product_mapping_lao'  as dataSource
             , 'Control Tower'                   as proccess
             , left(a.po_sku, 1000)              as referencia
             , count(1)                          as quantity    
          from ow_lao.ods_sales_control_tower_table a
         where division is null   
           and a.po_source_insert_date >= '20220101' 
           and not exists(
                     select 1
                       from ow_lao.monitoring_bi_lao_proccess cc
                      where cc.processo_nome = 'Control Tower'
                        and cc.origem_nome   = 'ow_lao.dim_product_mapping_lao'
                        and cc.referencia    = left(a.po_sku, 1000)
                        and cc.status_nome   = 'Em analise'
               )
      group by a.po_sku;
         
 end