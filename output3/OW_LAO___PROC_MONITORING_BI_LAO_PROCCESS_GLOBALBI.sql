
CREATE procedure ow_lao.proc_monitoring_bi_lao_proccess_globalbi
 LANGUAGE SQLSCRIPT AS
 BEGIN
    
       insert into ow_lao.monitoring_bi_lao_proccess(
                   origem_nome
                 , processo_nome
                 , referencia
                 , quantidade
       )   
           select 'ow_lao.ods_global_bi_sales'  as dataSource
                , 'Control Tower'               as proccess
                , a.po_id                       as referencia
                , count(1)                      as quantity    
             from ow_lao.ods_global_bi_sales a
            where a.sku is not null
              and a.sku not in ('8886419318200,0')
              and a.order_date >= '20240501'
              and not exists(
                        select 1
                          from ow_lao.ods_sales_control_tower_table aa
                         where aa.po_orderid = a.po_id
                           and aa.po_sku     = a.sku
                           and aa.country    = a.country
                   ) 
               and not exists(
                        select 1
                          from ow_lao.monitoring_bi_lao_proccess cc
                         where cc.processo_nome = 'Control Tower'
                           and cc.origem_nome   = 'ow_lao.ods_global_bi_sales'
                           and cc.referencia    = a.po_id
                           and cc.status_nome   = 'Em analise'
                   )
         group by a.po_id;                           
           
    end