CREATE procedure ow_lao.monitoring_executions_results_update_default(
       in _execution_result_status   int
     , in _filter_execution_status   int
     , in _monitoring_parameter      int
     , in _execution_result_value    varchar(4000)
 )
 as
    begin
    
            update ow_lao.monitoring_executions_results
               set monitoring_execution_result_status = _execution_result_status
                 , value                              = _execution_result_value
                 , is_ok                              = case _execution_result_status
                                                             when 2
                                                             then true
                                                             else false
                                                         end
                 , ended_at                            = current_timestamp
             where started_at                         <= current_timestamp
               and monitoring_execution_result_status  = _filter_execution_status 
               and monitoring_parameter                = _monitoring_parameter;
    
      end