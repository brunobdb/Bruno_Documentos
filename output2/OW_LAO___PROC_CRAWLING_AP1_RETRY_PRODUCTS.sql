create procedure OW_LAO.PROC_CRAWLING_AP1_RETRY_PRODUCTS()
as
begin
update OW_LAO.CRAWLER_PROCESS_LIST
set last_run_date = add_days(current_date,-1)
where key in (  select key from VM_CRAWLING_MONITORING_EXTRACT_NULL
				where key not in (
					select key from VM_CRAWLING_MONITORING_PRICE_EXECUTION_QUEUE
				)
);
end;