
CREATE procedure ow_lao.proc_monitoring_bi_lao_proccess_hybris
 LANGUAGE SQLSCRIPT AS
 BEGIN
 
    declare hybrisSalesMaxInserted timestamp = null;
    
    select max(po_source_insert_date) as po_source_insert_date
      into hybrisSalesMaxInserted
      from ow_lao.ods_sales_control_tower_table
     where po_plataform_datasource in ('ow_lao.ods_hybris_sales');
     
      
       insert into ow_lao.monitoring_bi_lao_proccess(
                   origem_nome
                 , processo_nome
                 , referencia
                 , quantidade
       )         
     
           select 'ow_lao.ods_hybris_sales'  as dataSource
                , 'Control Tower'            as proccess
                , a.order_code               as referencia
                , count(1)                   as quantity     
             from ow_lao.ods_hybris_sales   a
             join u_prj_ecom.dim_subsidiary b on lower(b.country_code) = lower(a.country_cd)
            where 1 = 1
              and a.order_creation_date >= add_days (current_date,-180)
              and a.order_creation_date <= :hybrisSalesMaxInserted
              and not exists(
                    select 1
                      from ow_lao.ods_sales_control_tower_table aa
                     where aa.po_orderid = a.order_code
                       and aa.po_sku     = a.product_code
                       and aa.country    = b.country
                  )
               and not exists(
                        select 1
                          from ow_lao.monitoring_bi_lao_proccess cc
                         where cc.processo_nome = 'Control Tower'
                           and cc.origem_nome   = 'ow_lao.ods_hybris_sales'
                           and cc.referencia    = a.order_code
                           and cc.status_nome   = 'Em analise'
                   )
          group by a.order_code;
                 
  end