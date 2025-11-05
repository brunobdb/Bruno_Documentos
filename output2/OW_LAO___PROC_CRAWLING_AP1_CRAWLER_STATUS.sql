create procedure OW_LAO.PROC_CRAWLING_AP1_CRAWLER_STATUS (date_selected int)
language SQLScript
as
begin
select A.KEY, A.COMPANY_NAME, A.SUB, A.PRODUCT_TYPE , B.TOTAL_PROD, B.TOTAL_SITE, A.URL from (
	select * FROM OW_LAO.CRAWLER_PROCESS_LIST
	where process_name like '%PRICE%'
	and should_run = true
) as A LEFT JOIN (
	select * from OW_LAO.CRAWLER_STATUS
	where start_time = add_days(current_date, :date_selected)
	and TOTAL_PROD != 0
	and TOTAL_PROD IS NOT NULL 
	and TOTAL_PROD != '0'
	and TOTAL_PROD != -1
) AS B ON A.KEY = B.KEY_PROCESS
ORDER BY A.COMPANY_NAME, A.SUB, A.PRODUCT_TYPE,B.TOTAL_PROD;
End