CREATE PROCEDURE PROC_CRAWLING_AP1_WM_PT1
LANGUAGE SQLSCRIPT as
BEGIN
TRUNCATE TABLE TF_CRAWLING_AP1_WM_1;
INSERT INTO TF_CRAWLING_AP1_WM_1
SELECT DISTINCT
TRIM(UPPER(SUBSTRING(D."PROD_BRAND",0,99))) "brand_nm"
, SUBSTRING(D."MODEL",0,99) "model_nm"
, SUBSTRING(D."DESC",0,99) "model_desc"
, SUBSTRING(P."SUB",0,99) "subsidiary"
, SUBSTRING(D."COUNTRY",0,99) "country"
, SUBSTRING(D."COUNTRY",0,99) "country_code"
, SUBSTRING(D."COMPANY_NAME",0,99) "site_company_name"
, SUBSTRING(P."SITE",0,99) "site_nm"
, SUBSTRING(D."PROD_HREF",0,499) "site_url"
, SUBSTRING(P."PAGE_NUMBER",0,99) "site_page"
, SUBSTRING(P."POSITION",0,99) "site_position"	
, SUBSTRING(D."CURRENCY",0,99) "site_price_currency"
, SUBSTRING(DW."RATING",0,99) "site_rating"
, SUBSTRING(DW."RATING_AMOUNT",0,99) "site_rating_amount"
, SUBSTRING(DW."RATING_SCALE",0,99) "site_rating_scale"
, SUBSTRING(P."TODAY_DATE_TIME",0,99) "refer_date"
, SUBSTRING(P."POR_VALUE",0,16) "price_unit"
, SUBSTRING(D."MODEL2",0,99) MODEL2
, SUBSTRING(D."REF",0,99)  REF
, SUBSTRING(D."REF2",0,99)  REF2
, SUBSTRING(P."DE_VALUE",0,16) "retail_price_base"
, SUBSTRING(P."POR_VALUE",0,16) "retail_price_actual"
, SUBSTRING(P."TODAY_DATE_TIME",0,99) "crawling_date"
, SUBSTRING(P.AVAILABLE,0,99) "product_available"
, null "process_status"
, null "comment_status"
, SUBSTRING(D.LAST_UPDATE,0,99) "product_update_date"
, NOW() process_datetime
FROM "ODS_CRAWLING_AP1_IM_PRODUCT_DAILY_PRICE" P
INNER JOIN "ODS_CRAWLING_AP1_WM_PRODUCT_DETAIL" D ON P."KEY" = D."KEY"
LEFT JOIN "ODS_CRAWLING_AP1_WM_PRODUCT_DETAIL_DAILY" DW ON P."KEY" = DW."KEY" AND to_char(P."TODAY_DATE_TIME", 'YYYY-MM-DD') = to_char(DW."LOAD_DATE", 'YYYY-MM-DD')
WHERE 1=1
AND P."TODAY_DATE_TIME" > '2020-06-27 00:00' 
AND to_char(P."TODAY_DATE_TIME", 'YYYY-MM-DD')  < to_char(CURRENT_DATE, 'YYYY-MM-DD')
AND UPPER(TRIM(PRODUCT_TYPE)) = 'WM'
;
--Codigo Provisorio para corrigir o Problema de Captura de Preço de LiverPool Mexico -- BRUNO ODILON 15/03/2021
		
update "OW_LAO"."TF_CRAWLING_AP1_WM_1" ORIG
set  ORIG."RETAIL_PRICE_ACTUAL"=DEST."NEW_LIVER_ACT", ORIG."PRICE_UNIT"=DEST."NEW_LIVER_UNIT"
from "OW_LAO"."TF_CRAWLING_AP1_WM_1" ORIG
inner join (
select
"LIVER_URL" 
,"LIVER_RETAIL_PRICE_BASE","LIVER_RETAIL_PRICE_ACTUAL","LIVER_UNIT_LEGTH","LIVER_ACT_LEGTH","LIVER_PRICE_UNIT"
,case when TO_INTEGER("LIVER_ACT_LEGTH")>=TO_INTEGER( avg(length("RETAIL_PRICE_ACTUAL"))+1) then "LIVER_RETAIL_PRICE_BASE" else "LIVER_RETAIL_PRICE_ACTUAL" end as "NEW_LIVER_ACT"
,case when TO_INTEGER("LIVER_UNIT_LEGTH")>=TO_INTEGER( avg(length ("PRICE_UNIT"))+1) then "LIVER_RETAIL_PRICE_BASE" else "LIVER_PRICE_UNIT" end as "NEW_LIVER_UNIT"
from "OW_LAO"."TF_CRAWLING_AP1_WM_1" MX
		inner join (
					select 
					"SITE_URL" as "LIVER_URL" 
					,length (PRICE_UNIT) as "LIVER_UNIT_LEGTH",PRICE_UNIT as "LIVER_PRICE_UNIT"
					,length (RETAIL_PRICE_BASE) as "LIVER_BASE_LEGTH",RETAIL_PRICE_BASE as "LIVER_RETAIL_PRICE_BASE"
					,length (RETAIL_PRICE_ACTUAL) as "LIVER_ACT_LEGTH",RETAIL_PRICE_ACTUAL as "LIVER_RETAIL_PRICE_ACTUAL"
							from "OW_LAO"."TF_CRAWLING_AP1_WM_1"
							where  "SITE_URL" like '%liverpoo%.mx%'
							AND 
					                ( 
					                PRICE_UNIT != '0.0'
					                AND PRICE_UNIT != '0.0'
					                AND PRICE_UNIT != '0'
					                AND TRIM(PRICE_UNIT) != '' 
					                AND RETAIL_PRICE_ACTUAL != '0.0'
					                AND RETAIL_PRICE_ACTUAL != '0.0'
					                AND RETAIL_PRICE_ACTUAL != '0'
					                AND TRIM(RETAIL_PRICE_ACTUAL) != '' 
					                )
							group by "SITE_URL" ,"PRICE_UNIT","RETAIL_PRICE_BASE" ,"RETAIL_PRICE_ACTUAL"
							order by 2 desc 	
 						)LIVER 
 on 1=1
 where  
 1=1
 and "COUNTRY"='MX'
 	AND  
					                ( 
					                PRICE_UNIT != '0.0'
					                AND PRICE_UNIT != '0.0'
					                AND PRICE_UNIT != '0'
					                AND TRIM(PRICE_UNIT) != '' 
					                AND RETAIL_PRICE_ACTUAL != '0.0'
					                AND RETAIL_PRICE_ACTUAL != '0.0'
					                AND RETAIL_PRICE_ACTUAL != '0'
					                AND TRIM(RETAIL_PRICE_ACTUAL) != '' 
					                )              
					                
group by   
 "LIVER_URL" ,"LIVER_RETAIL_PRICE_BASE","LIVER_RETAIL_PRICE_ACTUAL","LIVER_UNIT_LEGTH","LIVER_ACT_LEGTH","LIVER_PRICE_UNIT"
)DEST on  DEST."LIVER_URL" =ORIG."SITE_URL"
;
----FIM do CODIGO PROVISORIO 
 -- se model_nm está vazio ou nulo, inclui parte do site_url no lugar.
 UPDATE TF_CRAWLING_AP1_WM_1
 SET 
 model_nm = CASE WHEN Trim(model_nm) = '' or Trim(model_nm) is null 
 			THEN SUBSTRING(REPLACE(TRIM(site_url),TRIM(site_nm), ''), 1,99)
 			ELSE Trim(model_nm) END
 ;
-- caso os campos de rating estão nulos colocamos vazio para mapear na query final da pt2
 UPDATE TF_CRAWLING_AP1_WM_1
 SET
	site_rating = COALESCE(site_rating, '') 
	, site_rating_amount = COALESCE(site_rating_amount, '') 
	, site_rating_scale = COALESCE(site_rating_scale, '') 
;
UPDATE TF_CRAWLING_AP1_WM_1
SET
 site_rating = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM( REPLACE(site_rating, ',','.'))) FROM 1 OCCURRENCE 1)
, site_rating_amount = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(site_rating_amount)) FROM 1 OCCURRENCE 1) 
, site_rating_scale = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(site_rating_scale)) FROM 1 OCCURRENCE 1) 
, price_unit = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(price_unit)) FROM 1 OCCURRENCE 1) 
, retail_price_base = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(retail_price_base)) FROM 1 OCCURRENCE 1) 
, retail_price_actual = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(retail_price_actual)) FROM 1 OCCURRENCE 1) 
;  
/*
UPDATE TF_CRAWLING_AP1_WM_1
SET
process_status = 'DELETED'
, comment_status = 'DELETED_BY_PROCESS: Brand is empty or null'
WHERE
BRAND_NM is null or TRIM(BRAND_NM) = ''
;
*/
TRUNCATE TABLE TF_CRAWLING_AP1_WM_2;
INSERT INTO TF_CRAWLING_AP1_WM_2
SELECT
	UPPER(TRIM(INITCAP(brand_nm))) brand_nm,
	' ' as mktcode,
	' ' as mktname,
	model_nm as model_nm,
	subsidiary,
	country,
	country_code,
	UPPER(TRIM(site_company_name)) site_company_name,
	site_nm,
	site_url,
	site_page,
	site_position,
	site_price_currency,
	CASE WHEN TRIM(site_rating) = '' THEN null else TO_DECIMAL(site_rating, 8,1 ) End site_rating , 
	CASE WHEN TRIM(site_rating_amount) = '' THEN null else TO_DECIMAL(site_rating_amount, 8,0 ) End site_rating_amount , 
	CASE WHEN TRIM(site_rating_scale) = '' THEN null else TO_DECIMAL(site_rating_scale, 8,0 ) End site_rating_scale ,
	TO_TIMESTAMP(refer_date, 'YYYY-MM-DD HH24:MI') refer_date,
	ROUND(MAX(retail_price_actual),2) price_unit,
	ROUND(MAX(retail_price_base),2) as price_local_base,
	ROUND(MAX(retail_price_actual),2) as price_local_act,
	'Y' as update_flg,
	current_timestamp
	FROM TF_CRAWLING_AP1_WM_1
	WHERE
	process_status is null
GROUP BY 
	UPPER(TRIM(INITCAP(brand_nm))),
	model_nm,
	subsidiary,
	country,
	country_code,
	UPPER(TRIM(site_company_name)),
	site_nm,
	site_url,
	site_page,
	site_position,
	site_price_currency,
	CASE WHEN TRIM(site_rating) = '' THEN null else TO_DECIMAL(site_rating, 8,1 ) End , 
	CASE WHEN TRIM(site_rating_amount) = '' THEN null else TO_DECIMAL(site_rating_amount, 8,0 ) End  , 
	CASE WHEN TRIM(site_rating_scale) = '' THEN null else TO_DECIMAL(site_rating_scale, 8,0 ) End ,
	TO_TIMESTAMP(refer_date, 'YYYY-MM-DD HH24:MI') 
;
--POPULAR A TABELA DE INPUT E REALIZAR O MAPEAMENTO AUTOMÁTICO
CALL PROC_CRAWLING_AP1_WM_SITE_MAPPING_MERGE_AUTOMATIC;
 TRUNCATE TABLE FT_CRAWLING_AP1_WM_DISPLAY_SHARE;
 
 INSERT INTO FT_CRAWLING_AP1_WM_DISPLAY_SHARE
 SELECT * 
 FROM VW_CRAWLING_AP1_WM_DISPLAY_SHARE
 ;
 
 TRUNCATE TABLE FT_CRAWLING_AP1_WM_SEGMENT;
 /*Campo "GFK_BrandList" adicionado por causa do Jira SDSMS-1097 criado pelo e.koeke */  
 INSERT INTO FT_CRAWLING_AP1_WM_SEGMENT                         
     SELECT A.* 
, NULL REFER_WEEK
, NULL REFER_WEEK_T
, NULL REFER_YEAR,
  CASE WHEN B.GFK_BRAND_WM IS NULL THEN 
            'NO'
       ELSE 'YES'
  END AS "GFK_BrandList"
 FROM "OW_LAO".VW_CRAWLING_AP1_WM_SEGMENT A
	LEFT JOIN "OW_LAO"."DIM_GFK_BRAND_WM" B ON (TRIM(A."UPPER(BRAND_NM)")= TRIM(B.GFK_BRAND_WM));
 
 UPDATE OW_LAO.FT_CRAWLING_AP1_WM_SEGMENT F
SET
REFER_WEEK = (SELECT DISTINCT YYYYWW FROM OW_MD.DIM_CALENDAR D WHERE to_char(F.REFER_DATE,'YYYY-MM-DD') = to_char(D.YYYYMMDD,'YYYY-MM-DD'))
, REFER_WEEK_T = ( SELECT DISTINCT 'W' || RIGHT(YYYYWW,2) FROM OW_MD.DIM_CALENDAR D WHERE to_char(F.REFER_DATE,'YYYY-MM-DD') = to_char(D.YYYYMMDD,'YYYY-MM-DD'))
, REFER_YEAR = ( SELECT DISTINCT  YYYY FROM OW_MD.DIM_CALENDAR D WHERE to_char(F.REFER_DATE,'YYYY-MM-DD') = to_char(D.YYYYMMDD,'YYYY-MM-DD'))
WHERE 
REFER_WEEK is null;
update
"OW_LAO"."FT_CRAWLING_AP1_WM_SEGMENT"
set "SITE_RATING" = "SITE_RATING" /1000000000000
where length ("SITE_RATING" )> 11;
 
 
END;