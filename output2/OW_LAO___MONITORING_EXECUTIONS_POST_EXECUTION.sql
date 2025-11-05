create procedure ow_lao.monitoring_executions_post_execution(
       in _monitoring_execution        int
     , in _monitoring_execution_status int
     , in _execution_post_message      varchar(4000)
)
 as
   begin
   
            update ow_lao.monitoring_executions
               set monitoring_execution_status = _monitoring_execution_status
                 , execution_post_message      = _execution_post_message
                 , ended_at                    = current_timestamp
             where id                     = _monitoring_execution
               and _monitoring_execution != 2 ;
               
            update ow_lao.monitoring_executions
               set monitoring_execution_status = _monitoring_execution_status
                 , execution_post_message      = _execution_post_message
             where id                    = _monitoring_execution
               and _monitoring_execution = 2 ;               
   
     end