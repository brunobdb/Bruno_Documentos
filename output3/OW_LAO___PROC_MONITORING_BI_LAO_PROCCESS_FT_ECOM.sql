
CREATE procedure ow_lao.proc_monitoring_bi_lao_proccess_ft_ecom
 LANGUAGE SQLSCRIPT AS
 BEGIN
    declare poMaxInserted         timestamp = null;
    declare poSynapcomMaxInserted timestamp = null;
    
    select max(po_source_insert_date) as po_source_insert_date
      into poSynapcomMaxInserted
      from ow_lao.ods_sales_control_tower_table
     where po_plataform_datasource in ('u_prj_ecom_synapcom.ft_ecom_order');  
     
    select max(po_source_insert_date) as po_source_insert_date
      into poMaxInserted
      from ow_lao.ods_sales_control_tower_table
     where po_plataform_datasource in ('u_prj_ecom.ft_ecom_order');    
       insert into ow_lao.monitoring_bi_lao_proccess(
                   origem_nome
                 , processo_nome
                 , referencia
                 , quantidade
       )
 
            select 'u_prj_ecom_synapcom.ft_ecom_order'  as dataSource
                 , 'Control Tower'                      as proccess
                 , a.external_order_id                  as referencia
                 , count(1)                             as quantity
              from u_prj_ecom_synapcom.ft_ecom_order                       a
              join u_prj_ecom_synapcom.ft_ecom_order_item                  b on b.order_id = a.id
              join u_prj_ecom.dim_subsidiary                               c on c.id       = a.subsidiary_id
             where 1 = 1
               and a.creation_date >= add_days(current_date, -180)
               and a.insert_date   <= :poSynapcomMaxInserted
               and not exists(                        
                        select 1
                          from ow_lao.ods_sales_control_tower_table aa
                         where aa.po_orderid            = a.external_order_id
                           and aa.po_sku                = b.reference_code
                           and aa.country               = c.country
                   )
               and not exists(
                        select 1
                          from u_prj_ecom_synapcom.ft_ecom_order_kit_component bb
                         where bb.item_id = b.id
                   )
               and not exists(
                        select 1
                          from ow_lao.monitoring_bi_lao_proccess cc
                         where cc.processo_nome = 'Control Tower'
                           and cc.origem_nome   = 'u_prj_ecom_synapcom.ft_ecom_order'
                           and cc.referencia    = a.external_order_id
                           and cc.status_nome   = 'Em analise'
                   )
          group by a.external_order_id;
        
       insert into ow_lao.monitoring_bi_lao_proccess(
                   origem_nome
                 , processo_nome
                 , referencia
                 , quantidade
       )
          
            select 'u_prj_ecom_synapcom.ft_ecom_order bundle'   as dataSource
                 , 'Control Tower'                              as proccess
                 , a.external_order_id                          as referencia
                 , count(1)                                     as quantity
              from u_prj_ecom_synapcom.ft_ecom_order                       a
              join u_prj_ecom_synapcom.ft_ecom_order_item                  b on b.order_id = a.id
              join u_prj_ecom.dim_subsidiary                               c on c.id       = a.subsidiary_id
              join u_prj_ecom_synapcom.ft_ecom_order_kit_component         d on d.item_id  = b.id
             where 1 = 1
               and a.creation_date >= add_days(current_date, -180)
               and a.insert_date   <= :poSynapcomMaxInserted
               and not exists(                        
                        select 1
                          from ow_lao.ods_sales_control_tower_table aa
                         where aa.po_orderid                  = a.external_order_id
                           and aa.po_sku                      = d.reference_code
                           and aa.country                     = c.country
                           and aa.po_sku_kit                  = b.reference_code
                   )
               and not exists(
                        select 1
                          from ow_lao.monitoring_bi_lao_proccess cc
                         where cc.processo_nome = 'Control Tower'
                           and cc.origem_nome   = 'u_prj_ecom_synapcom.ft_ecom_order'
                           and cc.referencia    = a.external_order_id
                           and cc.status_nome   = 'Em analise'
                   )
          group by a.external_order_id;
          
       insert into ow_lao.monitoring_bi_lao_proccess(
                   origem_nome
                 , processo_nome
                 , referencia
                 , quantidade
       )
            select 'u_prj_ecom.ft_ecom_order'   as dataSource
                 , 'Control Tower'              as proccess
                 , a.external_order_id          as referencia
                 , count(1)                     as quantity
              from u_prj_ecom.ft_ecom_order                       a
              join u_prj_ecom.ft_ecom_order_item                  b on b.order_id = a.id
              join u_prj_ecom.dim_subsidiary                      c on c.id       = a.subsidiary_id
             where 1 = 1
               and a.creation_date >= add_days(current_date, -180)
               and a.insert_date   <= :poMaxInserted
               and a.subsidiary_id != 6
               and not exists(                        
                        select 1
                          from ow_lao.ods_sales_control_tower_table aa
                         where aa.po_orderid            = a.external_order_id
                           and aa.po_sku                = b.reference_code
                           and aa.country               = c.country
                   )
               and not exists(
                        select 1
                          from u_prj_ecom_synapcom.ft_ecom_order_kit_component bb
                         where bb.item_id = b.id
                   )
               and not exists(
                        select 1
                          from ow_lao.monitoring_bi_lao_proccess cc
                         where cc.processo_nome = 'Control Tower'
                           and cc.origem_nome   = 'u_prj_ecom.ft_ecom_order'
                           and cc.referencia    = a.external_order_id
                           and cc.status_nome   = 'Em analise'
                   )
          group by a.external_order_id;          
          
   end