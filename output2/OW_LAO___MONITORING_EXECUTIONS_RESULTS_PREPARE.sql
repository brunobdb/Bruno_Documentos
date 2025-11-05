CREATE procedure ow_lao.monitoring_executions_results_prepare(in _monitoring_execution_result_status int)
  as
    begin
    
            select a.monitoring_parameter
                 , b.monitoring_protocol_type
                 , b.value
              from ow_lao.monitoring_executions_results a
              join ow_lao.monitoring_parameters         b on b.id = a.monitoring_parameter
             where a.monitoring_execution_result_status = _monitoring_execution_result_status
          group by a.monitoring_parameter
                 , b.monitoring_protocol_type
                 , b.value;
            
      end