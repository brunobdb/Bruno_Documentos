CREATE  procedure ow_lao.proc_division_nerp_control_tower_status
 language sqlscript as
 begin
 
 ---order  **  'payment rejected'  
    create column table ow_lao.temp_division_nerp_control_tower_status
        as (         
        
            select distinct 
            po_orderid,
            division,
            po_status ,
            case 
	        when po_status = 'Cancelled' 
	        then 'payment rejected' 
	        else po_internal_status
	        end as po_internal_status , 
            so_date
             
         from ow_lao.ods_sales_control_tower_table 
         where  po_status = 'Cancelled'    
         and    client_subsidiary_id = 6   
         and    cast (po_date  as date ) between cast(add_days(now(), -180) as date) 
	                                 and cast(add_days(now(),  -0) as date)
        );                                       
                                                 
 
    
    update ow_lao.ods_sales_control_tower_table   a
       set a.po_internal_status       = b.po_internal_status
       
      from ow_lao.ods_sales_control_tower_table   a 
      join ow_lao.temp_division_nerp_control_tower_status        b on  b.po_orderid  = a.po_orderid
        and   a.client_subsidiary_id = 6
     ;  
    
     drop table ow_lao.temp_division_nerp_control_tower_status;
    
    
     ---order  localizadas no nerp **  'so_date localizados' 
    create column table ow_lao.temp_division_nerp_control_tower_status
        as (         
        
            select distinct 
            po_orderid,
            division,
            po_status,
            case 
	        when  po_status  =  'Cancelled' 
	        then  'canceled'
	        else po_internal_status 
	        end as po_internal_status , 
            so_date
             
         from  ow_lao.ods_sales_control_tower_table 
         where   so_date is not null 
         and   po_status  =  'Cancelled'  
         and   client_subsidiary_id = 6 
         and   po_orderid NOT IN (SELECT DISTINCT a.po_orderid FROM ow_lao.ods_sales_control_tower_table a 
         WHERE a.DIVISION IN ('Bundle','SC+','SERVICE') )
         and    cast (po_date  as date ) between cast(add_days(now(), -180) as date) 
	                                 and cast(add_days(now(),  -0) as date)
        );                                       
                                                 
 
    
    update ow_lao.ods_sales_control_tower_table  a
       set a.po_internal_status       = b.po_internal_status
       
      from ow_lao.ods_sales_control_tower_table a 
      join  ow_lao.temp_division_nerp_control_tower_status         b on  b.po_orderid  = a.po_orderid
      and a.client_subsidiary_id = 6
     ;  
    
     drop table ow_lao.temp_division_nerp_control_tower_status;
    
    
         ---order  division sc+ , bundles, services ' 
    create column table ow_lao.temp_division_nerp_control_tower_status
        as (         
        
            select distinct 
            po_orderid,
            division,
            po_status ,
            case 
	        when po_internal_status =  'payment rejected'
	        then 'canceled' 
	        when po_internal_status =  'canceled'
	        then 'canceled'
	        else   po_internal_status  
	        end as po_internal_status , 
            so_date
             
         from ow_lao.ods_sales_control_tower_table  
         where division in   ('Bundle','SC+','SERVICE')
          and  po_status = 'Cancelled'
          and  client_subsidiary_id = 6 
          and  cast (po_date  as date ) between cast(add_days(now(), -180) as date) 
	                                 and cast(add_days(now(),  -0) as date)
        );                                       
                                                 
 
    
    update ow_lao.ods_sales_control_tower_table  a
       set a.po_internal_status        = b.po_internal_status
       
      from ow_lao.ods_sales_control_tower_table  a 
      join ow_lao.temp_division_nerp_control_tower_status          b on  b.po_orderid  = a.po_orderid
      and a.client_subsidiary_id = 6
     ;  
    
     drop table ow_lao.temp_division_nerp_control_tower_status;
    
    
  end