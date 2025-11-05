CREATE procedure ow_lao.proc_monitoring_bi_lao_proccess_vtex_seda
 LANGUAGE SQLSCRIPT AS
 BEGIN
 
    declare synapcomMaxInserted timestamp = null;
    
    select max(po_source_insert_date) as po_source_insert_date
      into synapcomMaxInserted
      from ow_lao.ods_sales_control_tower_table
     where po_plataform_datasource in ('u_prj_ecom_synapcom.ft_ecom_order', 'u_prj_ecom.ft_ecom_order');    
     
       insert into ow_lao.monitoring_bi_lao_proccess(
                   origem_nome
                 , processo_nome
                 , referencia
                 , quantidade
       )
            
            select 'u_prj_ecom.ods_feed_vtex_ssg_br_shop_sales_order'  as dataSource
                 , 'Control Tower'                                     as proccess
                 , a.order_id                                          as referencia
                 , count(1)                                            as quantity
              from u_prj_ecom.raw_vtex_ssg_br_shop_sales_order a
             where 1 = 1
               and a.creation_timestamp >= add_days(current_date, -30)
               and a.created_at         <= :synapcomMaxInserted
               and not exists(                        
                        select 1
                          from ow_lao.ods_sales_control_tower_table aa
                         where aa.po_orderid = a.order_id
                           and aa.country    = 'Brazil'
                   )
               and not exists(                        
                        select 1
                          from u_prj_ecom_synapcom.ft_ecom_order bb
                         where bb.external_order_id = a.order_id
                   )
               and not exists(
                        select 1
                          from ow_lao.monitoring_bi_lao_proccess cc
                         where cc.processo_nome = 'Control Tower'
                           and cc.origem_nome   = 'u_prj_ecom.ods_feed_vtex_ssg_br_shop_sales_order'
                           and cc.referencia    = a.order_id
                           and cc.status_nome   = 'Em analise'
                   )
          group by a.order_id;        
          
       
       insert into ow_lao.monitoring_bi_lao_proccess(
                   origem_nome
                 , processo_nome
                 , referencia
                 , quantidade
       )
       
            select 'u_prj_ecom.raw_vtex_ssg_br_epp2_sales_order'  as dataSource
                 , 'Control Tower'                                as proccess
                 , a.seller_order_id                              as referencia
                 , count(1)                                       as quantity
              from u_prj_ecom.raw_vtex_ssg_br_epp2_sales_order a
             where 1 = 1
               and a.seller_order_id is not null
               and a.creation_timestamp >= add_days(current_date, -30)
               and a.created_at         <= :synapcomMaxInserted
               and not exists(                        
                        select 1
                          from ow_lao.ods_sales_control_tower_table aa
                         where aa.po_orderid = a.seller_order_id
                           and aa.country    = 'Brazil'
                   ) 
               and not exists(                        
                        select 1
                          from u_prj_ecom_synapcom.ft_ecom_order bb
                         where bb.external_order_id = a.seller_order_id
                   )
               and not exists(
                        select 1
                          from ow_lao.monitoring_bi_lao_proccess cc
                         where cc.processo_nome = 'Control Tower'
                           and cc.origem_nome   = 'u_prj_ecom.raw_vtex_ssg_br_epp2_sales_order'
                           and cc.referencia    = a.seller_order_id
                           and cc.status_nome   = 'Em analise'
                   )    
          group by a.seller_order_id;    
          
   end