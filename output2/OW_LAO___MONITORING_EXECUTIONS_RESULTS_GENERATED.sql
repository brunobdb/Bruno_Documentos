create procedure ow_lao.monitoring_executions_results_generated
    as
  begin
  
           declare monitoring_execution int;
           
            select ow_lao._SYS_SEQUENCE_123515233_#0_#.nextval
              into monitoring_execution
              from dummy;
              
              
            insert into ow_lao.monitoring_executions(
                   id
                 , monitoring_execution_status
            )
            
            select :monitoring_execution
                 , 1                    -- 'Waiting'
              from dummy;
            insert into ow_lao.monitoring_executions_results (
                   monitoring_execution 
                 , monitoring_parameter 
                 , monitoring_execution_result_status  
            )
  
            select :monitoring_execution
                 , id
                 , 1                    -- 'Waiting'
              from ow_lao.monitoring_parameters
             where active = true;
             
             
            select :monitoring_execution
              from dummy;
            
  end