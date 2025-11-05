CREATE procedure ow_lao.monitoring_executions_results_update_jenkins(
       in _execution_result_status   int
     , in _monitoring_parameter      int
     , in _jenkins_api_result_status varchar(255)
     , in _jenkins_timestamp_fix     varchar(1000)
     , in _jenkins_inProgress        varchar(255)
 )
 as
    begin
    
            update ow_lao.monitoring_executions_results
               set monitoring_execution_result_status = 2       -- Success
                 , value    = _jenkins_timestamp_fix
                 , is_ok    = true
                 , ended_at = current_timestamp
             where started_at                         <= current_timestamp
               and monitoring_execution_result_status  = _execution_result_status 
               and monitoring_parameter                =  _monitoring_parameter
               and _jenkins_api_result_status         != 'FAILURE'
               and _jenkins_inProgress                != 'true';
    
            update ow_lao.monitoring_executions_results
               set monitoring_execution_result_status = 3       -- Failure
                 , value    = _jenkins_timestamp_fix
                 , is_ok    = false
                 , ended_at = current_timestamp
             where started_at                         <= current_timestamp
               and monitoring_execution_result_status  = _execution_result_status 
               and monitoring_parameter                = _monitoring_parameter  
               and _jenkins_api_result_status          = 'FAILURE'
               and _jenkins_inProgress                != 'true';
    
            update ow_lao.monitoring_executions_results
               set monitoring_execution_result_status = 4       -- Executing
                 , value    = _jenkins_timestamp_fix
                 , is_ok    = true
                 , ended_at = current_timestamp
             where started_at                         <= current_timestamp
               and monitoring_execution_result_status  = _execution_result_status 
               and monitoring_parameter                = _monitoring_parameter  
               --and _jenkins_api_result_status          = 'null'
               and _jenkins_inProgress                 = 'true';
    
      end