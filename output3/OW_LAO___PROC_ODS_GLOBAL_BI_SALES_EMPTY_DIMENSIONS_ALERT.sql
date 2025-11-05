CREATE PROCEDURE OW_LAO.proc_ods_global_bi_sales_empty_dimensions_alert
 LANGUAGE SQLSCRIPT AS
     begin 
  
    create local temporary table #ods_global_bi_sales_dimensions 
        as (
                select distinct  
                       country
                     , device_type
                     , channel
                     , site
                     , biz_type
                  from ow_lao.ods_global_bi_sales
                 where order_date >= add_days(current_date, -10)
                   and site is not null 
                   and device_type is not null
                   and region = 'Latin America'
        );
            
    select a.country
         , a.device_type
         , a.channel
         , a.site
         , a.biz_type
         , count(b.po_id)         quantity
      from #ods_global_bi_sales_dimensions a
 left join ow_lao.ods_global_bi_sales      b on b.country     = a.country      
                                            and b.device_type = a.device_type 
                                            and b.channel     = a.channel 
                                            and b.site        = a.site
                                            and b.biz_type    = a.biz_type   
                                            and b.order_date >= add_days(current_date, -5)
  group by a.country
         , a.device_type
         , a.channel
         , a.site
         , a.biz_type
    having count(b.po_id) = 0;
    
  end