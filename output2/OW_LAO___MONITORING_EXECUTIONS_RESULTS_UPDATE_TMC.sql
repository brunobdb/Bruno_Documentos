CREATE procedure ow_lao.monitoring_executions_results_update_tmc(
       in _execution_result_status   int
     , in _monitoring_parameter      int
     , in _tmc_api_result_status varchar(255)
     , in _tmc_timestamp         varchar(1000)
 )
 as
    begin
    
        declare tmc_reponse_formated   varchar(1000) = '';
        
        select case coalesce(_tmc_timestamp, 'null')
                    when 'null'
                    then _tmc_api_result_status
                    else coalesce(_tmc_api_result_status || char(10), '') ||
                         coalesce(        
                                to_varchar(
                                    add_seconds(
                                            cast(_tmc_timestamp as timestamp) 
                                          , 3600 * -3
                                    ), 'YYYY-MM-DD HH24:MI:SS'
                                ), ''
                          )          
                end                                               as tmc_timestamp_formated
         into tmc_reponse_formated
         from dummy;            
    
            update ow_lao.monitoring_executions_results
               set monitoring_execution_result_status = 2       -- Success
                 , value    = :tmc_reponse_formated
                 , is_ok    = true
                 , ended_at = current_timestamp
             where started_at                         <= current_timestamp
               and monitoring_execution_result_status  = _execution_result_status 
               and monitoring_parameter                =  _monitoring_parameter
               and _tmc_api_result_status              = 'execution_successful';
    
            update ow_lao.monitoring_executions_results
               set monitoring_execution_result_status = 3       -- Failure
                 , value    = :tmc_reponse_formated
                 , is_ok    = false
                 , ended_at = current_timestamp
             where started_at                         <= current_timestamp
               and monitoring_execution_result_status  = _execution_result_status 
               and monitoring_parameter                = _monitoring_parameter  
               and _tmc_api_result_status              not in ('execution_successful', 'executing', 'dispatching', 'Waiting');
    
            update ow_lao.monitoring_executions_results
               set monitoring_execution_result_status = 4       -- Executing
                 , value    = :tmc_reponse_formated
                 , is_ok    = true
                 , ended_at = current_timestamp
             where started_at                         <= current_timestamp
               and monitoring_execution_result_status  = _execution_result_status 
               and monitoring_parameter                = _monitoring_parameter  
               and _tmc_api_result_status             in ('executing', 'dispatching', 'Waiting');
    
      end