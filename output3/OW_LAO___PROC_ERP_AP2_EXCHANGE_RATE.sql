CREATE procedure OW_LAO.PROC_ERP_AP2_EXCHANGE_RATE
as
 begin
 
        declare load_date_newest      date;
        declare load_date_not_exists  boolean;
          
        --drop table #ods_erp_exchange_rate_temp;
        --drop table #ods_erp_exchange_rate_default;
        --drop table #ods_erp_exchange_rate_last_valid_from_value;
        
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
          from dummy                       a
     left join ow_lao.ft_ap2_exchange_rate b on b.load_date = :load_date_newest
         limit 1;
          
          if :load_date_not_exists = false
            then
                  
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
                     
                 delete from #ods_erp_exchange_rate_temp where dedup != 1;
                 
                  merge into ow_lao.ft_ap2_exchange_rate a
                       using #ods_erp_exchange_rate_temp b on b.from_currency = a.from_currency
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
              
          end if;             
          
          
          
        create local temporary table #ods_erp_exchange_rate_default
             (        
                     valid_from    date
                   , from_currency varchar(255)
                   , to_currency   varchar(255)
                   , exchange_rate decimal      default 0.00
            );
         
          insert into #ods_erp_exchange_rate_default
          
               select YYYYMMDD                          as valid_from
                    , "From currency"                   as from_currency
                    , "To-currency"                     as to_currency
                    , cast(0.00 as decimal)             as exchange_rate
                 from ow_md.dim_calendar           a
                 join ow_lao.ods_erp_exchange_rate b on 1 = 1
                where a.YYYYMMDD between add_days(current_date, -30)
                                     and current_date
                  and b."Exchange Rate Type" = 'M'
                  and b."Exchange Rate" is not null
                  and not exists(
                                select 1
                                  from ow_lao.ft_ap2_exchange_rate aa
                                 where aa.valid_from    = a.YYYYMMDD
                                   and aa.from_currency = b."From currency"
                                   and aa.to_currency   = b."To-currency"
                           )
             group by a.YYYYMMDD
                    , b."From currency"
                    , b."To-currency"; 
                
               
                insert into #ods_erp_exchange_rate_default
                
               select YYYYMMDD                          as valid_from
                    , from_currency                     as from_currency
                    , to_currency                       as to_currency
                    , cast(0.00 as decimal)             as exchange_rate
                 from ow_md.dim_calendar          a
                 join ow_lao.ft_ap2_exchange_rate b on 1 = 1
                where a.YYYYMMDD between add_days(current_date, -30)
                                     and current_date
                  and not exists(
                                select 1
                                  from #ods_erp_exchange_rate_default aa
                                 where aa.valid_from    = a.YYYYMMDD
                                   and aa.from_currency = b.from_currency
                                   and aa.to_currency   = b.to_currency
                           )
                  and not exists(
                                select 1
                                  from ow_lao.ft_ap2_exchange_rate aa
                                 where aa.valid_from    = a.YYYYMMDD
                                   and aa.from_currency = b.from_currency
                                   and aa.to_currency   = b.to_currency
                           )
             group by a.YYYYMMDD
                    , b.from_currency
                    , b.to_currency;                
        
                
                
        create local temporary table #ods_erp_exchange_rate_last_valid_from_value
             (        
                     valid_from    date
                   , from_currency varchar(255)
                   , to_currency   varchar(255)
                   , exchange_rate decimal      default 0.00
            );      
        
                insert into #ods_erp_exchange_rate_last_valid_from_value
                
                select max(to_varchar(to_date(add_days(b.valid_from, -1)), 'YYYY-MM-DD')) as valid_from
                     , a.from_currency
                     , a.to_currency
                     , 0.00
                  from #ods_erp_exchange_rate_default a
                  join ow_lao.ft_ap2_exchange_rate    b on b.from_currency = a.from_currency
                                                       and b.to_currency   = a.to_currency
              group by a.from_currency
                     , a.to_currency;                                                        
        
                update #ods_erp_exchange_rate_default               a
                   set exchange_rate = c.exchange_rate
                  from #ods_erp_exchange_rate_default               a
                  join #ods_erp_exchange_rate_last_valid_from_value b on b.from_currency = a.from_currency
                                                                     and b.to_currency   = a.to_currency
                  join ow_lao.ft_ap2_exchange_rate                  c on c.from_currency = a.from_currency
                                                                     and c.to_currency   = a.to_currency
                                                                     and c.valid_from    = b.valid_from;
                                                                     
                                                                     
                insert into ow_lao.ft_ap2_exchange_rate(
                       from_currency
                     , to_currency
                     , valid_from
                     , exchange_rate
                     , process_status
                     , comment_status
                )
                
                select from_currency
                     , to_currency
                     , valid_from
                     , exchange_rate
                     , 'ADJUSTMENT'     as process_status
                     , 'Null on GERP'   as comment_status
                  from #ods_erp_exchange_rate_default;          
 
   end