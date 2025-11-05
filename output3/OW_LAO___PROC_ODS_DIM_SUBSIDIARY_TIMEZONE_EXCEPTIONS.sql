CREATE PROCEDURE OW_LAO.proc_ods_dim_subsidiary_timezone_exceptions
 LANGUAGE SQLSCRIPT AS
 BEGIN
    
    insert into ow_lao.ods_dim_subsidiary_timezone_exceptions(
															      subsidiary_id            
															    , country                  
															    , timezone                 
															    , daylight_save_time       
															    , timezone_from            
															    , timezone_until           
															    , url                      
															    , request_timestamp        
															)
    
    
    select a.subsidiary_id
         , a.country
         , cast(replace(replace(a.timezone, ':00', ''), '-0', '-') as int) timezone
         , a.daylight_save_time
         , a.daylight_save_time_from
         , a.daylight_save_time_until
         , a.url
         , a.request_timestamp
      from ow_lao.tmp_dim_subsidiary_timezone_exceptions a
     where daylight_save_time = 1
       and not exists(
                select 1
                  from ow_lao.ods_dim_subsidiary_timezone_exceptions aa
                 where aa.subsidiary_id = a.subsidiary_id
                   and aa.country       = a.country
                   and aa.timezone_from = a.daylight_save_time_from
           )   ;
    
    
end