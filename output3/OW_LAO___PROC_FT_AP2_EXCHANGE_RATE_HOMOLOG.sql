create procedure ow_lao.proc_ft_ap2_exchange_rate_homolog
as
 begin
 
        declare load_date_newest      date;
        declare load_date_not_exists  boolean;
        
        select max(a.load_date)
          into load_date_newest
          from ow_lao.ods_erp_exchange_rate a
         where "Exchange Rate Type" = 'M';
         
        
        select case
                    when b.load_date is null
                    then false
                    else true
                end
          into load_date_not_exists
          from dummy                               a
     left join ow_lao.ft_ap2_exchange_rate_homolog b on b.load_date = :load_date_newest
         limit 1;
          
          if :load_date_not_exists = false
            then
          
		          drop table #ods_erp_exchange_rate_temp;
		          drop table #ods_erp_exchange_rate_null_fix;
		          
		        create local temporary table #ods_erp_exchange_rate_temp 
		            as (
		            
		                  select "From currency"                    as from_currency
							   , "To-currency"                      as to_currency
							   , REPLACE("Valid from"  , '.','-')   as valid_from
							   , REPLACE("Exchange Rate", ',','')   as exchange_rate
							   , LOAD_DATE
		                       , cast(null as nvarchar(256))        as process_status
		                       , cast(null as nvarchar(256))        as comment_status
		                       , cast(null as int)                  as dedup				
							from ow_lao.ods_erp_exchange_rate
						   where 1 = 0
		            );
		            
		            
		         insert into #ods_erp_exchange_rate_temp 
		              select distinct
		                     "From currency"                    as from_currency
		                   , "To-currency"                      as to_currency
		                   , replace("Valid from"  , '.','-')   as valid_from
		                   , replace("Exchange Rate", ',','')   as exchange_rate
		                   , load_date                          as load_date
		                   , null                               as process_status
		                   , null                               as comment_status  
		                   , row_number() 
		                           over(partition by "From currency"
		                                           , "To-currency"
		                                           , REPLACE("Valid from", '.','-') 
                                            order by load_date desc
                                   )                            as dedup
		                from ow_lao.ods_erp_exchange_rate
		               where "Exchange Rate Type" = 'M'
		                 and "Exchange Rate" is not null
		                 and load_date = :load_date_newest;		         
		         
		         create local temporary table #ods_erp_exchange_rate_null_fix
		           as (
		                 select a."From currency"
		                      , a."To-currency"
		                      , a."Valid from"
		                      , cast(null as nvarchar(5000)) as valid_from_next_not_null_value
		                      , cast(null as LONGDATE      ) as load_date_next_not_null_value
		                   from ow_lao.ods_erp_exchange_rate a
		                  where 1 = 0
		                  limit 1
		           );
		           
		         insert into #ods_erp_exchange_rate_null_fix
                      select a."From currency"
                           , a."To-currency"
                           , a."Valid from"
                           , min(cast(replace(b."Valid from"  , '.','-') as date))  as valid_from_next_not_null_value
                           , min(b.load_date)                                       as load_date_next_not_null_value
                        from ow_lao.ods_erp_exchange_rate a
                        join ow_lao.ods_erp_exchange_rate b on b."From currency" = a."From currency"
                                                           and b."To-currency"   = a."To-currency"
                                                           and cast(replace(b."Valid from"  , '.','-') as date)    
                                                               > cast(replace(a."Valid from"  , '.','-') as date)
                       where a."Exchange Rate" is null
                         and b."Exchange Rate" is not null
                         and b."Exchange Rate Type" = 'M'
                         and a.load_date = :load_date_newest
                         and not exists(
                                select 1
                                  from #ods_erp_exchange_rate_temp aa
                                 where aa.from_currency = a."From currency"
                                   and aa.to_currency   = a."To-currency"
                                   and aa.valid_from    = replace(a."Valid from"  , '.','-')                            
                             )
                    group by a."From currency"
                           , a."To-currency"
                           , a."Valid from"
                    order by a."From currency"
                           , a."To-currency"
                           , a."Valid from";
                           
                 insert into #ods_erp_exchange_rate_null_fix
                      select a."From currency"
                           , a."To-currency"
                           , a."Valid from"
                           , max(cast(replace(b."Valid from"  , '.','-') as date))  as valid_from_next_not_null_value
                           , max(b.load_date)                                       as load_date_next_not_null_value
                        from ow_lao.ods_erp_exchange_rate a
                        join ow_lao.ods_erp_exchange_rate b on b."From currency" = a."From currency"
                                                           and b."To-currency"   = a."To-currency"
                                                           and cast(replace(b."Valid from"  , '.','-') as date)    
                                                               < cast(replace(a."Valid from"  , '.','-') as date)
                       where a."Exchange Rate" is null
                         and b."Exchange Rate" is not null
                         and b."Exchange Rate Type" = 'M'
                         and a.load_date = :load_date_newest
                         and not exists(
                                select 1
                                  from #ods_erp_exchange_rate_temp aa
                                 where aa.from_currency = a."From currency"
                                   and aa.to_currency   = a."To-currency"
                                   and aa.valid_from    = replace(a."Valid from"  , '.','-')                            
                             )
                         and not exists(
                                select 1
                                  from #ods_erp_exchange_rate_null_fix aa
                                 where aa."From currency" = a."From currency"
                                   and aa."To-currency"   = a."To-currency"
                                   and aa."Valid from"    = a."Valid from"
                             )
                    group by a."From currency"
                           , a."To-currency"
                           , a."Valid from"
                    order by a."From currency"
                           , a."To-currency"
                           , a."Valid from";  
                           
                 insert into #ods_erp_exchange_rate_null_fix
                      select a."From currency"
                           , a."To-currency"
                           , to_varchar(add_days(current_date, -1), 'YYYY.MM.DD')   as "Valid from"
                           , max(cast(replace(a."Valid from"  , '.','-') as date))  as valid_from_next_not_null_value
                           , max(a.load_date)                                       as load_date_next_not_null_value
                        from ow_lao.ods_erp_exchange_rate a
                       where a."Exchange Rate" is not null
                         and a."Exchange Rate Type" = 'M'
                         and not exists(
	                             select 1
	                               from #ods_erp_exchange_rate_temp aa
	                              where aa.from_currency = a."From currency"
	                                and aa.to_currency   = a."To-currency"
	                                and aa.valid_from    = add_days(current_date, -1)                      
                             )
                    group by a."From currency"
                           , a."To-currency";                                              		         
		           
		           
                 insert into #ods_erp_exchange_rate_temp 
                      select distinct
                             a."From currency"                    as from_currency
                           , a."To-currency"                      as to_currency
                           , replace(b."Valid from"  , '.','-')   as valid_from
                           , replace(a."Exchange Rate", ',','')   as exchange_rate
                           , a.load_date                          as load_date
                           , 'ADJUSTMENT'                         as process_status
                           , 'Null on GERP'                       as comment_status  
                           , row_number() 
                                   over(partition by b."From currency"
                                                   , b."To-currency"
                                                   , REPLACE(b."Valid from", '.','-') 
                                            order by a.load_date desc
                                   )                            as dedup
                        from ow_lao.ods_erp_exchange_rate    a
                        join #ods_erp_exchange_rate_null_fix b on b."From currency"                = a."From currency"
                                                              and b."To-currency"                  = a."To-currency"
                                                              and b.valid_from_next_not_null_value = cast(replace(a."Valid from"  , '.','-') as date)
                                                              and b.load_date_next_not_null_value  = a.load_date
                       where a."Exchange Rate Type" = 'M'
                         and a."Exchange Rate" is not null
                    order by a."From currency"
                           , a."To-currency"
                           , replace(b."Valid from"  , '.','-');
                         
                 delete from #ods_erp_exchange_rate_temp where dedup != 1;
                 
                  merge into ow_lao.ft_ap2_exchange_rate_homolog a
                       using #ods_erp_exchange_rate_temp         b on b.from_currency = a.from_currency
                                                                  and b.to_currency   = a.to_currency
                                                                  and b.valid_from    = a.valid_from
                        when    matched then update  
                                                set a.load_date         = b.load_date
                                                  , a.exchange_rate     = b.exchange_rate  
                                                  , a.process_status    = b.process_status
                                                  , a.comment_status    = b.comment_status
                                                  , a.updated_timestamp = current_timestamp
                                                  
                       when not matched then insert(  
                                                       from_currency
                                                     , to_currency
                                                     , valid_from
                                                     , load_date
                                                     , exchange_rate
                                                     , process_status
                                                     , comment_status
                                             )
                                             values(
                                                       b.from_currency
                                                     , b.to_currency
                                                     , b.valid_from
                                                     , b.load_date
                                                     , b.exchange_rate
                                                     , b.process_status
                                                     , b.comment_status
                                             );
		         
		         
		         select *
		           from #ods_erp_exchange_rate_temp;
		           
		         select * 
		           from #ods_erp_exchange_rate_null_fix;
	          
          else
            select 'Not new data to import' as message
              from dummy;
            return;
          end if;	          
 
   end