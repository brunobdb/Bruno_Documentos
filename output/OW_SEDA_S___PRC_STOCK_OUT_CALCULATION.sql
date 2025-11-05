
CREATE PROCEDURE OW_SEDA_S.PRC_STOCK_OUT_CALCULATION(in weeknum_ref int, in category_ref varchar(10), in account_ref varchar(30)) as
--do
begin
--declare weeknum_ref int;
--declare category_ref varchar(10);
--declare account_ref varchar(30);
--weeknum_ref := 202301;
--category_ref := 'TV';
--account_ref := 'MAGAZINE LUIZA';
DELETE FROM OW_SEDA_S.FT_CE_READY fr 
WHERE EXISTS (
	SELECT 1 FROM (
	SELECT fr.* FROM OW_SEDA_S.FT_CE_READY fr 
	INNER JOIN OW_SEDA_S.MAP_CE_STORES ml ON ml.SITE_ID = fr.SITE_ID 
	INNER JOIN OW_SEDA_S.MAP_CE_PRODUCTS mcp ON mcp.ITEM = fr.ITEM 
	WHERE 1=1
		AND fr.WEEKNUM = weeknum_ref
		AND fr."PARAMETER" = 'Stock Out'
		AND mcp.CATEGORY_ITEM = category_ref
		AND ml.ACCOUNT = account_ref) s
	WHERE 1=1
		AND fr.SITE_ID = s.SITE_ID
		AND fr.ITEM = s.ITEM
		AND fr.WEEKNUM = s.WEEKNUM
		AND fr."PARAMETER" = s.PARAMETER);
	
merge into OW_SEDA_S."FT_CE_READY" target
using 
(
SELECT distinct
stock_out_0 as "PARAMETER",
"WEEKNUM",
"SITE_ID",
"ITEM",
1 as "DATA",
--"DATA", a, b, c, d, e,
'Stock Out Manual' as "REPORT",
current_date as "INPUT_DATE"
from
(select
tb1."SITE_ID",
tb1."ITEM",
tb1."WEEKNUM",
tb1."DATA",
--ifnull(minus_one_max_week,0) "A",
--ifnull(minus_two_max_week,0) "B",
--ifnull(minus_three_max_week,0) "C",
--ifnull(minus_four_max_week,0) "D",
--ifnull(minus_five_max_week,0) "E",
case 
	when ifnull(tb1."DATA",0) = 0 and ifnull(minus_one_max_week,0) = 0 then 'Stock Out'
	when ifnull(tb1."DATA",0) = 1 and ifnull(minus_one_max_week,0) = 1 and (ifnull(minus_two_max_week,0) > 1 or ifnull(minus_three_max_week,0) > 1 or ifnull(minus_four_max_week,0) > 1 or ifnull(minus_five_max_week,0) > 1) then 'Stock Out'
	else ''
end as stock_out_0,
case 
	when ifnull(minus_one_max_week,0) = 0 and ifnull(minus_two_max_week,0) = 0 then 1
	when ifnull(minus_one_max_week,0) = 1 and ifnull(minus_two_max_week,0) = 1 and (ifnull(minus_three_max_week,0) > 1 or ifnull(minus_four_max_week,0) > 1 or ifnull(minus_five_max_week,0) > 1 or ifnull(minus_six_max_week,0) > 1) then 1
	else 0
end +
case 
	when ifnull(minus_two_max_week,0) = 0 and ifnull(minus_three_max_week,0) = 0 then 1
	when ifnull(minus_two_max_week,0) = 1 and ifnull(minus_three_max_week,0) = 1 and (ifnull(minus_four_max_week,0) > 1 or ifnull(minus_five_max_week,0) > 1 or ifnull(minus_six_max_week,0) > 1 or ifnull(minus_seven_max_week,0) > 1) then 1
	else 0
end +
case 
	when ifnull(minus_three_max_week,0) = 0 and ifnull(minus_four_max_week,0) = 0 then 1
	when ifnull(minus_three_max_week,0) = 1 and ifnull(minus_four_max_week,0) = 1 and (ifnull(minus_five_max_week,0) > 1 or ifnull(minus_six_max_week,0) > 1 or ifnull(minus_seven_max_week,0) > 1 or ifnull(minus_eight_max_week,0) > 1) then 1
	else 0
end +
case 
	when ifnull(minus_four_max_week,0) = 0 and ifnull(minus_five_max_week,0) = 0 then 1
	when ifnull(minus_four_max_week,0) = 1 and ifnull(minus_five_max_week,0) = 1 and (ifnull(minus_six_max_week,0) > 1 or ifnull(minus_seven_max_week,0) > 1 or ifnull(minus_eight_max_week,0) > 1) then 1
	else 0
end as stock_out_count
from 
(
SELECT 
	"PARAMETER",
	weeknum_ref AS WEEKNUM,
	SITE_ID,
	ITEM,
	SUM(CASE WHEN WEEKNUM = weeknum_ref THEN "DATA" ELSE 0 END) "DATA",
	MIN(REPORT) REPORT,
	current_date
FROM OW_SEDA_S.FT_CE_READY fr 
inner join 
	(
	SELECT
		LAG(YEARWEEK, 1) OVER (ORDER BY YEARWEEK) AS weeknum_lag_1,
		LAG(YEARWEEK, 2) OVER (ORDER BY YEARWEEK) AS weeknum_lag_2,
		LAG(YEARWEEK, 3) OVER (ORDER BY YEARWEEK) AS weeknum_lag_3,
		LAG(YEARWEEK, 4) OVER (ORDER BY YEARWEEK) AS weeknum_lag_4,
		LAG(YEARWEEK, 5) OVER (ORDER BY YEARWEEK) AS weeknum_lag_5,
		LAG(YEARWEEK, 6) OVER (ORDER BY YEARWEEK) AS weeknum_lag_6,
		LAG(YEARWEEK, 7) OVER (ORDER BY YEARWEEK) AS weeknum_lag_7,
		LAG(YEARWEEK, 8) OVER (ORDER BY YEARWEEK) AS weeknum_lag_8,
		YEARWEEK
	FROM OW_SEDA_S."MAP_CE_CALENDAR" mc 
	WHERE 1=1
		AND "YEAR" BETWEEN 2024 AND 2025
	) tb2 on weeknum_ref = tb2."YEARWEEK"
WHERE 1=1
	--AND "DATA" = 0
	AND "PARAMETER" = 'Inventory'
	AND fr.WEEKNUM BETWEEN weeknum_lag_4 AND weeknum_ref
GROUP BY 
	"PARAMETER",
	SITE_ID,
	ITEM
)tb1
inner join 
	(
	SELECT
		LAG(YEARWEEK, 1) OVER (ORDER BY YEARWEEK) AS weeknum_lag_1,
		LAG(YEARWEEK, 2) OVER (ORDER BY YEARWEEK) AS weeknum_lag_2,
		LAG(YEARWEEK, 3) OVER (ORDER BY YEARWEEK) AS weeknum_lag_3,
		LAG(YEARWEEK, 4) OVER (ORDER BY YEARWEEK) AS weeknum_lag_4,
		LAG(YEARWEEK, 5) OVER (ORDER BY YEARWEEK) AS weeknum_lag_5,
		LAG(YEARWEEK, 6) OVER (ORDER BY YEARWEEK) AS weeknum_lag_6,
		LAG(YEARWEEK, 7) OVER (ORDER BY YEARWEEK) AS weeknum_lag_7,
		LAG(YEARWEEK, 8) OVER (ORDER BY YEARWEEK) AS weeknum_lag_8,
		YEARWEEK
	FROM OW_SEDA_S."MAP_CE_CALENDAR" mc 
	WHERE 1=1
		AND "YEAR" BETWEEN 2024 AND 2025
	) tb2 on weeknum_ref = tb2."YEARWEEK"
inner join OW_SEDA_S."MAP_CE_STORES" tb3 on tb1."SITE_ID" = tb3."SITE_ID"
inner join OW_SEDA_S."MAP_CE_PRODUCTS" tb4 on tb1."ITEM" = tb4."ITEM"
left join
(select 
"SITE_ID", 
"ITEM", 
"WEEKNUM" as minus_one_week_inventory, 
"DATA" as minus_one_max_week 
from OW_SEDA_S."FT_CE_READY" tb1
where "PARAMETER" = 'Inventory') tb_minus_one
on
	tb1."SITE_ID" = tb_minus_one."SITE_ID" and
	tb1."ITEM" = tb_minus_one."ITEM" and
	tb2.weeknum_lag_1 = tb_minus_one.minus_one_week_inventory
left join
(select 
"SITE_ID", 
"ITEM", 
"WEEKNUM" as minus_two_week_inventory, 
"DATA" as minus_two_max_week 
from OW_SEDA_S."FT_CE_READY" tb1
where "PARAMETER" = 'Inventory') tb_minus_two
on
	tb1."SITE_ID" = tb_minus_two."SITE_ID" and
	tb1."ITEM" = tb_minus_two."ITEM" and
	tb2.weeknum_lag_2 = tb_minus_two.minus_two_week_inventory
	
left join
(select 
"SITE_ID", 
"ITEM", 
"WEEKNUM" as minus_three_week_inventory, 
"DATA" as minus_three_max_week 
from OW_SEDA_S."FT_CE_READY" tb1
where "PARAMETER" = 'Inventory') tb_minus_three
on
	tb1."SITE_ID" = tb_minus_three."SITE_ID" and
	tb1."ITEM" = tb_minus_three."ITEM" and
	tb2.weeknum_lag_3 = tb_minus_three.minus_three_week_inventory
	
left join
(select 
"SITE_ID", 
"ITEM", 
"WEEKNUM" as minus_four_week_inventory, 
"DATA" as minus_four_max_week 
from OW_SEDA_S."FT_CE_READY" tb1
where "PARAMETER" = 'Inventory') tb_minus_four
on
	tb1."SITE_ID" = tb_minus_four."SITE_ID" and
	tb1."ITEM" = tb_minus_four."ITEM" and
	tb2.weeknum_lag_4 = tb_minus_four.minus_four_week_inventory
left join
(select 
"SITE_ID", 
"ITEM", 
"WEEKNUM" as minus_five_week_inventory, 
"DATA" as minus_five_max_week 
from OW_SEDA_S."FT_CE_READY" tb1
where "PARAMETER" = 'Inventory') tb_minus_five
on
	tb1."SITE_ID" = tb_minus_five."SITE_ID" and
	tb1."ITEM" = tb_minus_five."ITEM" and
	tb2.weeknum_lag_5 = tb_minus_five.minus_five_week_inventory
	
left join
(select 
"SITE_ID", 
"ITEM", 
"WEEKNUM" as minus_six_week_inventory, 
"DATA" as minus_six_max_week 
from OW_SEDA_S."FT_CE_READY" tb1
where "PARAMETER" = 'Inventory') tb_minus_six
on
	tb1."SITE_ID" = tb_minus_six."SITE_ID" and
	tb1."ITEM" = tb_minus_six."ITEM" and
	tb2.weeknum_lag_6 = tb_minus_six.minus_six_week_inventory
	
left join
(select 
"SITE_ID", 
"ITEM", 
"WEEKNUM" as minus_seven_week_inventory, 
"DATA" as minus_seven_max_week 
from OW_SEDA_S."FT_CE_READY" tb1
where "PARAMETER" = 'Inventory') tb_minus_seven
on
	tb1."SITE_ID" = tb_minus_seven."SITE_ID" and
	tb1."ITEM" = tb_minus_seven."ITEM" and
	tb2.weeknum_lag_7 = tb_minus_seven.minus_seven_week_inventory
	
left join
(select 
"SITE_ID", 
"ITEM", 
"WEEKNUM" as minus_eight_week_inventory, 
"DATA" as minus_eight_max_week 
from OW_SEDA_S."FT_CE_READY" tb1
where "PARAMETER" = 'Inventory') tb_minus_eight
on
	tb1."SITE_ID" = tb_minus_eight."SITE_ID" and
	tb1."ITEM" = tb_minus_eight."ITEM" and
	tb2.weeknum_lag_8 = tb_minus_eight.minus_eight_week_inventory
where 
	"WEEKNUM" = weeknum_ref and
	"PARAMETER" = 'Inventory'and
	"STORE_TYPE" = 'Reg. Stores' and 
	"DATA" in (0, 1) and
	"ACCOUNT" = account_ref and
	"CATEGORY_ITEM" = category_ref
	
	) tb_stock_out
	
where 1=1
	AND stock_out_0 = 'Stock Out' 
	and stock_out_count <= 4
--	AND tb_stock_out.DATA = 0
) source
on
	source."PARAMETER" = target."PARAMETER" and
	source."WEEKNUM"   = target."WEEKNUM"   and
	source."SITE_ID"   = target."SITE_ID"   and
	source."ITEM"      = target."ITEM" 
WHEN MATCHED THEN UPDATE SET target."DATA" = source."DATA", target."REPORT" = source."REPORT", target."INPUT_DATE" = source."INPUT_DATE"
WHEN NOT MATCHED THEN INSERT VALUES(source."PARAMETER", source."WEEKNUM", source."SITE_ID", source."ITEM", source."DATA", source."REPORT", source."INPUT_DATE");
END;
