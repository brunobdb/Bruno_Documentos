
CREATE procedure ow_lao.proc_monitoring_bi_lao_proccess_hybris_files_sales_validation
 LANGUAGE SQLSCRIPT AS
 
 begin
 
        declare plataform   varchar(255)       = 'hybris';
        declare version     varchar(255)       = 'GPV2';
        declare country     varchar(255) array = array('mx','co','cl','pr');
        declare environment varchar(255)       = 'PRD';
        declare type        varchar(255)       = 'order_delivery';
        declare extension   varchar(255)       = 'txt';
 
 
             drop table ow_lao.temp_monitoring_bi_lao_proccess_hybris_files_sales_validation;
    create column table ow_lao.temp_monitoring_bi_lao_proccess_hybris_files_sales_validation
        as (          
            select id                                                                as id
                 , substring_regexpr('[^_]+' in file_name_short from 1 occurrence 1) as Plataform
                 , substring_regexpr('[^_]+' in file_name_short from 1 occurrence 2) as Version
                 , substring_regexpr('[^_]+' in file_name_short from 1 occurrence 3) as Country
                 , substring_regexpr('[^_]+' in file_name_short from 1 occurrence 4) as Environment
                 , substring_regexpr('[^_]+' in file_name_short from 1 occurrence 5) || '_' ||
                   substring_regexpr('[^_]+' in file_name_short from 1 occurrence 6) as Type
                 , substring_regexpr('[^_]+' in file_name_short from 1 occurrence 7) as start_date
                 , substring_regexpr('[^_]+' in file_name_short from 1 occurrence 8) as final_date
                 , substring_regexpr('[^.]+' in
                    substring_regexpr('[^_]+' in file_name_short from 1 occurrence 9)
                    from 1 occurrence 1)                                             as partition
                 , substring_regexpr('[^.]+' in file_name_short from 1 occurrence 2) as extension
                 , false                                                             as validated
                 , file_name_short                                                   as file_name_short
              from ow_lao.monitoring_bi_lao_proccess_hybris_files_sales
             where validated is null
        );
        
        update ow_lao.temp_monitoring_bi_lao_proccess_hybris_files_sales_validation a
           set validated = true
         where 1 = 1
           and a.plataform   = :plataform   
           and a.version     = :version  
           and a.environment = :environment 
           and a.type        = :type        
           and a.extension   = :extension; 
           
        update ow_lao.temp_monitoring_bi_lao_proccess_hybris_files_sales_validation a
           set validated = false
         where 1 = 1
           and start_date != final_date;       
           
         update ow_lao.monitoring_bi_lao_proccess_hybris_files_sales                 a
            set validated = b.validated
           from ow_lao.monitoring_bi_lao_proccess_hybris_files_sales                 a
           join ow_lao.temp_monitoring_bi_lao_proccess_hybris_files_sales_validation b on b.id = a.id;
           
         insert into ow_lao.monitoring_bi_lao_proccess(
                    origem_nome
                  , processo_nome
                  , referencia
                  , quantidade
         )
            
         select 'ow_lao.monitoring_bi_lao_proccess_hybris_files_sales'  as dataSource
              , 'Control Tower'                                         as proccess
              , a.file_name_short                                       as referencia
              , count(1)                                                as quantity   
           from ow_lao.temp_monitoring_bi_lao_proccess_hybris_files_sales_validation a
          where validated = false
            and not exists(
                      select 1
                        from ow_lao.monitoring_bi_lao_proccess cc
                       where cc.processo_nome = 'Control Tower'
                         and cc.origem_nome   = 'ow_lao.monitoring_bi_lao_proccess_hybris_files_sales'
                         and cc.referencia    = a.file_name_short
                         and cc.status_nome   = 'Em analise'
                )
       group by a.file_name_short;
          
  end