CREATE procedure ow_lao.proc_monitoring_bi_lao_proccess_vtex_seda_global_bi
 LANGUAGE SQLSCRIPT AS
 BEGIN
 
    declare timestamp_filter timestamp    = null;
    declare proccess         varchar(255) = 'GlobalBI';
    
     select add_seconds(current_timestamp, -3600) 
       into timestamp_filter
       from dummy;
            
            select 'u_prj_ecom.ods_feed_vtex_ssg_br_shop_sales_order'  as dataSource
                 , :proccess                                           as proccess
                 , a.order_id                                          as referencia
                 , count(1)                                            as quantity
              from u_prj_ecom.raw_vtex_ssg_br_shop_sales_order a
             where 1 = 1
               and a.creation_timestamp >= add_days(current_date, -30)
               and a.creation_timestamp >= '20240715'
               and a.created_at         <= :timestamp_filter
               and not exists(                        
                        select 1
                          from u_prj_ecom_synapcom.ft_ecom_order bb
                         where bb.external_order_id = a.order_id
                   )
               and not exists(
                        select 1
                          from ow_lao.monitoring_bi_lao_proccess cc
                         where cc.processo_nome = :proccess
                           and cc.origem_nome   = 'u_prj_ecom.ods_feed_vtex_ssg_br_shop_sales_order'
                           and cc.referencia    = a.order_id
                           and cc.status_nome   = 'Em analise'
                   )
          group by a.order_id
          
             union all
       
            select 'u_prj_ecom.raw_vtex_ssg_br_epp2_sales_order'  as dataSource
                 , proccess                                       as proccess
                 , a.seller_order_id                              as referencia
                 , count(1)                                       as quantity
              from u_prj_ecom.raw_vtex_ssg_br_epp2_sales_order a
             where 1 = 1
               and a.creation_timestamp >= add_days(current_date, -30)
               and a.creation_timestamp >= '20240715'
               and a.created_at         <= :timestamp_filter
               and not exists(                        
                        select 1
                          from u_prj_ecom_synapcom.ft_ecom_order bb
                         where bb.external_order_id = a.seller_order_id
                   )
               and not exists(
                        select 1
                          from ow_lao.monitoring_bi_lao_proccess cc
                         where cc.processo_nome = :proccess
                           and cc.origem_nome   = 'u_prj_ecom.raw_vtex_ssg_br_epp2_sales_order'
                           and cc.referencia    = a.seller_order_id
                           and cc.status_nome   = 'Em analise'
                   )    
          group by a.seller_order_id;    
          
   end