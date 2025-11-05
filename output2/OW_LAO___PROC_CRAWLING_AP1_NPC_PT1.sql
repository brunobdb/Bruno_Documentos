CREATE PROCEDURE PROC_CRAWLING_AP1_NPC_PT1
LANGUAGE SQLSCRIPT as
BEGIN
-- TRUNCA A TABELA FATO TF_CRAWLING_AP1_NPC_1
TRUNCATE TABLE TF_CRAWLING_AP1_NPC_1;
/*
 A partir das tabelas Abaixo inserimos informações na tabela fato TF_CRAWLING_AP1_NPC_1:  
OW_LAO."ODS_CRAWLING_AP1_IM_PRODUCT_DAILY_PRICE" P
OW_LAO.ODS_CRAWLING_AP1_NPC_PRODUCT_DETAIL D
                "ODS_CRAWLING_AP1_NPC_PRODUCT_DETAIL_DAILY" DT
*/
INSERT INTO TF_CRAWLING_AP1_NPC_1
SELECT DISTINCT
TRIM(UPPER(SUBSTRING(D."PROD_BRAND",0,99))) "brand_nm"
, SUBSTRING(D."MODEL",0,99) "model_nm"
, SUBSTRING(D."DESC",0,99) "model_desc"
, SUBSTRING(P."SUB",0,99) "subsidiary"
, SUBSTRING(D."COUNTRY",0,99) "country"
, SUBSTRING(D."COUNTRY",0,99) "country_code"
, SUBSTRING(D."COMPANY_NAME",0,99) "site_company_name"
, D."VENDOR" "vendor"
, SUBSTRING(P."SITE",0,99) "site_nm"
, SUBSTRING(D."PROD_HREF",0,499) "site_url"
, SUBSTRING(P."PAGE_NUMBER",0,99) "site_page"
, SUBSTRING(P."POSITION",0,99) "site_position"	
, SUBSTRING(D."CURRENCY",0,99) "site_price_currency"
, SUBSTRING(DT."RATING",0,99) "site_rating"
, SUBSTRING(DT."RATING_AMOUNT",0,99) "site_rating_amount"
, SUBSTRING(DT."RATING_SCALE",0,99) "site_rating_scale"
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
,P.INITIAL_URL "initial_url"
FROM OW_LAO."ODS_CRAWLING_AP1_IM_PRODUCT_DAILY_PRICE" P		
INNER JOIN OW_LAO.ODS_CRAWLING_AP1_NPC_PRODUCT_DETAIL D
ON P."KEY" = D."KEY"
INNER JOIN "ODS_CRAWLING_AP1_NPC_PRODUCT_DETAIL_DAILY" DT
ON P."KEY" = DT."KEY" AND to_char(P."TODAY_DATE_TIME", 'YYYY-MM-DD') = to_char(DT."LOAD_DATE", 'YYYY-MM-DD')
WHERE 1=1
--AND P."TODAY_DATE_TIME" > '2020-07-16' 00:00' 
AND P."TODAY_DATE_TIME" > '2020-06-27 00:00' 
--AND to_char(P."TODAY_DATE_TIME", 'YYYY-MM-DD') > to_char(ADD_DAYS(CURRENT_DATE,-16), 'YYYY-MM-DD') 
AND to_char(P."TODAY_DATE_TIME", 'YYYY-MM-DD')  < to_char(CURRENT_DATE, 'YYYY-MM-DD')
AND UPPER(TRIM(PRODUCT_TYPE)) = 'NPC'
;
 -- se model_nm está vazio ou nulo, inclui parte do site_url no lugar.
 UPDATE TF_CRAWLING_AP1_NPC_1
 SET 
 "model_nm" = CASE WHEN Trim("model_nm") = '' or Trim("model_nm") is null 
 			THEN SUBSTRING(REPLACE(TRIM("site_url"),TRIM("site_nm"), ''), 1,99)
 			ELSE Trim("model_nm") END
 ;
-- caso os campos de rating estão nulos colocamos vazio para mapear na query final da pt2
 UPDATE TF_CRAWLING_AP1_NPC_1
 SET
	"site_rating" = COALESCE("site_rating", '') 
	, "site_rating_amount" = COALESCE("site_rating_amount", '') 
	, "site_rating_scale" = COALESCE("site_rating_scale", '') 
;
UPDATE TF_CRAWLING_AP1_NPC_1
SET
 "site_rating" = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM( REPLACE("site_rating", ',','.'))) FROM 1 OCCURRENCE 1)
, "site_rating_amount" = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM("site_rating_amount")) FROM 1 OCCURRENCE 1) 
, "site_rating_scale" = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM("site_rating_scale")) FROM 1 OCCURRENCE 1) 
, "price_unit" = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM("price_unit")) FROM 1 OCCURRENCE 1) 
, "retail_price_base" = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM("retail_price_base")) FROM 1 OCCURRENCE 1) 
, "retail_price_actual" = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM("retail_price_actual")) FROM 1 OCCURRENCE 1) 
;  
/*
UPDATE TF_CRAWLING_AP1_NPC_1
SET
process_status = 'DELETED'
, comment_status = 'DELETED_BY_PROCESS: Brand is empty or null'
WHERE
BRAND_NM is null or TRIM(BRAND_NM) = ''
;
*/
-- TRUNCA A TABELA FATO TF_CRAWLING_AP1_NPC_2
TRUNCATE TABLE TF_CRAWLING_AP1_NPC_2;
/*
 A partir do agrupamento de algumas colunas da tabela fato TF_CRAWLING_AP1_NPC_1
 criamos a tabela fato: TF_CRAWLING_AP1_NPC_2
*/
INSERT INTO TF_CRAWLING_AP1_NPC_2
SELECT
	UPPER(TRIM(INITCAP("brand_nm"))) "brand_nm",
	' ' as "mktcode",
	' ' as "mktname",
	"model_nm" as "model_nm",
	"subsidiary",
	"country",
	"country_code",
	UPPER(TRIM("site_company_name")) "site_company_name",
	"vendor",
	"site_nm",
	"site_url",
	"site_page",
	"site_position",
	"site_price_currency",
	CASE WHEN TRIM("site_rating") = '' THEN null else TO_DECIMAL("site_rating", 8,1 ) End "site_rating" , 
	CASE WHEN TRIM("site_rating_amount") = '' THEN null else TO_DECIMAL("site_rating_amount", 8,0 ) End "site_rating_amount" , 
	CASE WHEN TRIM("site_rating_scale") = '' THEN null else TO_DECIMAL("site_rating_scale", 8,0 ) End "site_rating_scale" ,
	TO_TIMESTAMP("refer_date", 'YYYY-MM-DD HH24:MI') "refer_date",
	ROUND(MAX("retail_price_actual"),2) "price_unit",
	ROUND(MAX("retail_price_base"),2) as "price_local_base",
	ROUND(MAX("retail_price_actual"),2) as "price_local_act",
	'Y' as "update_flg",
	current_timestamp,
	"initial_url"
	FROM TF_CRAWLING_AP1_NPC_1
	WHERE
	"process_status" is null
GROUP BY 
	UPPER(TRIM(INITCAP("brand_nm"))),
	"model_nm",
	"subsidiary",
	"country",
	"country_code",
	UPPER(TRIM("site_company_name")),
	"vendor",
	"site_nm",
	"site_url",
	"site_page",
	"site_position",
	"site_price_currency",
	CASE WHEN TRIM("site_rating") = '' THEN null else TO_DECIMAL("site_rating", 8,1 ) End , 
	CASE WHEN TRIM("site_rating_amount") = '' THEN null else TO_DECIMAL("site_rating_amount", 8,0 ) End  , 
	CASE WHEN TRIM("site_rating_scale") = '' THEN null else TO_DECIMAL("site_rating_scale", 8,0 ) End ,
	TO_TIMESTAMP("refer_date", 'YYYY-MM-DD HH24:MI'),
	"initial_url" 
;
--POPULAR A TABELA DE INPUT E REALIZAR O MAPEAMENTO AUTOMÁTICO
CALL PROC_CRAWLING_AP1_NPC_SITE_MAPPING_MERGE_AUTOMATIC;
-- Trunca a Tabela fato FT_CRAWLING_AP1_NPC_SEGMENT
 TRUNCATE TABLE FT_CRAWLING_AP1_NPC_SEGMENT;
-- Insere dados na tablea fato FT_CRAWLING_AP1_NPC_SEGMENT a partir da View VW_CRAWLING_AP1_NPC_SEGMENT
 INSERT INTO FT_CRAWLING_AP1_NPC_SEGMENT
 SELECT *, NULL REFER_WEEK
, NULL REFER_WEEK_T
, NULL REFER_YEAR 
,NULL as MODEL_DESC
 FROM VW_CRAWLING_AP1_NPC_SEGMENT
 ;
/*
01/10/2020
Update da Base SEgment para carregar o Model Desc -  Chamado SDSMS-2112*/
UPDATE   "OW_LAO"."FT_CRAWLING_AP1_NPC_SEGMENT" O
 SET
O."MODEL_DESC" =T."DESC" 
from 
 "OW_LAO"."FT_CRAWLING_AP1_NPC_SEGMENT"  O 
inner join 
 (
 
 select "DESC",PROD_HREF from "OW_LAO"."ODS_CRAWLING_AP1_NPC_PRODUCT_DETAIL"
 )T
 ON TRIM(O.SITE_URL) = TRIM(T.PROD_HREF)
 --where 
 --to_char("REFER_DATE", 'YYYY-MM-DD')  BETWEEN to_char(add_days('2021-05-12',-0), 'YYYY-MM-DD') and  to_char(add_days('2021-09-08',-0), 'YYYY-MM-DD')
;
UPDATE OW_LAO.FT_CRAWLING_AP1_NPC_SEGMENT F
SET
REFER_WEEK = (SELECT DISTINCT YYYYWW FROM OW_MD.DIM_CALENDAR D WHERE to_char(F.REFER_DATE,'YYYY-MM-DD') = to_char(D.YYYYMMDD,'YYYY-MM-DD'))
, REFER_WEEK_T = ( SELECT DISTINCT 'W' || RIGHT(YYYYWW,2) FROM OW_MD.DIM_CALENDAR D WHERE to_char(F.REFER_DATE,'YYYY-MM-DD') = to_char(D.YYYYMMDD,'YYYY-MM-DD'))
, REFER_YEAR = ( SELECT DISTINCT  YYYY FROM OW_MD.DIM_CALENDAR D WHERE to_char(F.REFER_DATE,'YYYY-MM-DD') = to_char(D.YYYYMMDD,'YYYY-MM-DD'))
WHERE 
REFER_WEEK is null;
END;