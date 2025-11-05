CREATE PROCEDURE OW_LAO.PROC_ODS_CONTROL_TOWER_TABLE_UPDATE_PREMIUM_MODELS_WEEKLY_REPROCESS
LANGUAGE SQLSCRIPT AS
begin
      
    declare plan_previous int; 
    declare plan_last int; 
   
   select cast(max(PLAN) as int) - 1  
        ,cast(max(PLAN) as int)
     into plan_previous
        , plan_last
     from OW_LAO.ODS_LAO_Product_PREMIUM_items;
    
    ---DROP TABLE #ODS_GSCM_PREMIUM_MODELS_PREPAPRE_CONTROL_TOWER_UPDATE ;
        create local temporary table #ODS_GSCM_PREMIUM_MODELS_PREPAPRE_CONTROL_TOWER_UPDATE 
            as (
                SELECT *, 0 as MONTH_NUMBER, 0 as YEAR_NUMBER
                  FROM OW_LAO.ODS_GSCM_PREMIUM_MODELS a
                where 1 = 0
        );
    
           insert into #ODS_GSCM_PREMIUM_MODELS_PREPAPRE_CONTROL_TOWER_UPDATE 
                SELECT *, CASE 
                            WHEN "MONTH" = 'Jan' THEN 1
                            WHEN "MONTH" = 'Feb' THEN 2
                            WHEN "MONTH" = 'Mar' THEN 3
                            WHEN "MONTH" = 'Apr' THEN 4
                            WHEN "MONTH" = 'May' THEN 5
                            WHEN "MONTH" = 'Jun' THEN 6
                            WHEN "MONTH" = 'Jul' THEN 7
                            WHEN "MONTH" = 'Aug' THEN 8
                            WHEN "MONTH" = 'Sep' THEN 9
                            WHEN "MONTH" = 'Oct' THEN 10
                            WHEN "MONTH" = 'Nov' THEN 11
                            WHEN "MONTH" = 'Dec' THEN 12
                        end as month_NUMBER
                     , LEFT(PLAN, 4) as YEAR_NUMBER
                  FROM OW_LAO.ODS_GSCM_PREMIUM_MODELS a
                 where a.plan = :plan_last
                   and CASE 
                            WHEN "MONTH" = 'Jan' THEN 1
                            WHEN "MONTH" = 'Feb' THEN 2
                            WHEN "MONTH" = 'Mar' THEN 3
                            WHEN "MONTH" = 'Apr' THEN 4
                            WHEN "MONTH" = 'May' THEN 5
                            WHEN "MONTH" = 'Jun' THEN 6
                            WHEN "MONTH" = 'Jul' THEN 7
                            WHEN "MONTH" = 'Aug' THEN 8
                            WHEN "MONTH" = 'Sep' THEN 9
                            WHEN "MONTH" = 'Oct' THEN 10
                            WHEN "MONTH" = 'Nov' THEN 11
                            WHEN "MONTH" = 'Dec' THEN 12
                        end <= month(CURRENT_DATE)
                   and not exists(
                            SELECT * 
                             FROM OW_LAO.ODS_LAO_Product_PREMIUM_items aa
                            WHERE 1 = 1
                              and aa.ITEM = a.item
                              and aa.ap2  = a.AP2 
                              AND aa.PLAN = :plan_previous
                       )
                   order by ap2, item;    
    
              
            ---  SELECT * 
	update ow_lao.ods_sales_control_tower_table a
     set premiumproduct = 1
from ow_lao.ods_sales_control_tower_table a
	JOIN #ODS_GSCM_PREMIUM_MODELS_PREPAPRE_CONTROL_TOWER_UPDATE b ON 
						b.MONTH_NUMBER = a.PODATE_MONTH
						AND b.ITEM = a.PO_SKU 
						AND a.SUBSIDIARY = b.AP2
						AND b.YEAR_NUMBER = a.PODATE_YEAR
	where 
	 a.premiumproduct != 1
			AND 
			CAST (PO_DATE AS DATE) >= '2023-06-12';
       
  END