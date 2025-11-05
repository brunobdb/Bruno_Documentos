
CREATE PROCEDURE OW_SEDA_S.PRC_DEAD_INVENTORY_CALCULATION(in weeknum_ref int, in category_ref varchar(10), in account_ref varchar(30)) as
begin
--declare weeknum_ref int;
--declare category_ref varchar(10);
--declare account_ref varchar(30);
--weeknum_ref := 201940;
--category_ref := 'TV';
--account_ref := 'VIA VAREJO';
DELETE FROM OW_SEDA_S.FT_CE_READY fr 
WHERE EXISTS (
	SELECT 1 FROM (
	SELECT fr.* FROM OW_SEDA_S.FT_CE_READY fr 
	INNER JOIN OW_SEDA_S.MAP_CE_STORES ml ON ml.SITE_ID = fr.SITE_ID 
	INNER JOIN OW_SEDA_S.MAP_CE_PRODUCTS mcp ON mcp.ITEM = fr.ITEM 
	WHERE 1=1
		AND fr.WEEKNUM = weeknum_ref
		AND fr."PARAMETER" = 'Dead Inventory'
		AND mcp.CATEGORY_ITEM = category_ref
		AND ml.ACCOUNT = account_ref) s
	WHERE 1=1
		AND fr.SITE_ID = s.SITE_ID
		AND fr.ITEM = s.ITEM
		AND fr.WEEKNUM = s.WEEKNUM
		AND fr."PARAMETER" = s.PARAMETER);
merge into OW_SEDA_S."FT_CE_READY" target
using (
select distinct
'Dead Inventory' as "PARAMETER",
tb1."WEEKNUM",
tb1."SITE_ID",
tb1."ITEM",
"DATA" - 1 as "DATA",
'Dead Inventory Manual' as "REPORT",
current_date as "INPUT_DATE"
,case
	when last_weeknum_sell_out is null then first_weeknum_inventory
	else last_weeknum_sell_out
end as weeknum_to_diff,
days_between(tb5."CALENDAR", tb4."CALENDAR")/7 as difference
from OW_SEDA_S."FT_CE_READY" tb1
inner join OW_SEDA_S."MAP_CE_STORES" tb2 on tb1."SITE_ID" = tb2."SITE_ID"
inner join OW_SEDA_S."MAP_CE_PRODUCTS" tb3 on tb1."ITEM" = tb3."ITEM"
inner join (
	SELECT
		LAG(YEARWEEK, 7) OVER (ORDER BY YEARWEEK) AS weeknum_lag_7,
		YEARWEEK,
		CALENDAR 
	FROM OW_SEDA_S."MAP_CE_CALENDAR" mc 
	WHERE 1=1
		AND "YEAR" BETWEEN 2024 AND 2025
) tb4 on tb1."WEEKNUM" = tb4."YEARWEEK"
left join (
--git last weeknum with sell out
select
max("WEEKNUM") as last_weeknum_sell_out,
"SITE_ID",
"ITEM"
from OW_SEDA_S."FT_CE_READY"
where 1=1
	and "PARAMETER" = 'Sell Out' 
	and "WEEKNUM" <= weeknum_ref
	and "DATA" > 0
group by "SITE_ID", "ITEM") tb_last_sale
on
	tb1."SITE_ID" = tb_last_sale."SITE_ID" and
	tb1."ITEM"    = tb_last_sale."ITEM"
	
left join (
--git first weeknum with inventory
select
min("WEEKNUM") as first_weeknum_inventory,
"SITE_ID",
"ITEM",
max("DATA") as first_inventory
from OW_SEDA_S."FT_CE_READY"
where 1=1
	and "PARAMETER" = 'Inventory' 
	and "WEEKNUM" <= weeknum_ref
	and "DATA" > 0
	
group by "SITE_ID", "ITEM") tb_first_inventory
on
	tb1."SITE_ID" = tb_first_inventory."SITE_ID" and
	tb1."ITEM"    = tb_first_inventory."ITEM"
	
inner join OW_SEDA_S."MAP_CE_CALENDAR" tb5 
on coalesce(last_weeknum_sell_out, first_weeknum_inventory) = tb5."YEARWEEK"
where 
	"PARAMETER" = 'Inventory' and 
	"WEEKNUM" = weeknum_ref and 
	days_between(tb5."CALENDAR", tb4."CALENDAR")/7 + 1 -
	CASE
		WHEN last_weeknum_sell_out IS NOT NULL THEN 1
		ELSE 0
	END
	>=8 and
	"DATA" - 1 > 0 and
	STORE_TYPE = 'Reg. Stores' and
	ACCOUNT = account_ref and
	CATEGORY_ITEM = category_ref
	
) source
on
	source."PARAMETER" = target."PARAMETER" and
	source."WEEKNUM"   = target."WEEKNUM"   and
	source."SITE_ID"   = target."SITE_ID"   and
	source."ITEM"      = target."ITEM" 
WHEN MATCHED THEN UPDATE SET target."DATA" = source."DATA", target."REPORT" = source."REPORT", target."INPUT_DATE" = source."INPUT_DATE"
WHEN NOT MATCHED THEN INSERT VALUES(source."PARAMETER", source."WEEKNUM", source."SITE_ID", source."ITEM", source."DATA", source."REPORT", source."INPUT_DATE");
end;
