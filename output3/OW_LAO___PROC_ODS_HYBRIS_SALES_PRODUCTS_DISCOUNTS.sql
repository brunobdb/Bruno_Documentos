create procedure ow_lao.proc_ods_hybris_sales_products_discounts
 as
 begin
 
    insert into ow_lao.ods_hybris_sales_products_discounts(
           hybris_sales_id   
         , order_code        
         , product_code      
         , discount_details      
         , discount_name     
         , discount_value    
         , audience_type     
         , biz_type          
         , global_channel    
         , subsidiary        
    )
    
    select a.hybris_sales_id   
	     , a.order_code        
	     , a.product_code      
	     , a.discount_details      
	     , a.discount_name     
	     , a.discount_value    
	     , a.audience_type     
	     , a.biz_type          
	     , a.global_channel    
	     , a.subsidiary        
      from ow_lao.stg_hybris_sales_products_discounts a
     where not exists(
                select 1
                  from ow_lao.ods_hybris_sales_products_discounts aa
                 where aa.hybris_sales_id = a.hybris_sales_id
           );
           
    end