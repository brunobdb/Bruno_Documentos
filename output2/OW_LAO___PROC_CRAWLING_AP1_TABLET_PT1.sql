CREATE PROCEDURE PROC_CRAWLING_AP1_TABLET_PT1
LANGUAGE SQLSCRIPT as
BEGIN
DECLARE _loopnum INTEGER;
DECLARE _case_str VARCHAR(200);
DECLARE _vp_query VARCHAR(5000);
DECLARE i INTEGER;
/*
Alteração no campo site_price_currency com a regra de Case para os casos do Paraguay e Uruguai - Odilon - 21/10/2020
*/
/*
Update na ODS de Registros maiores que 11 caracteres em WIDTH e HEIGHT, provisorio
*/
delete from 
"OW_LAO"."ODS_CRAWLING_AP1_TABLET_PRODUCT_DETAIL"
where length ("WIDTH")> 11;
delete from 
"OW_LAO"."ODS_CRAWLING_AP1_TABLET_PRODUCT_DETAIL"
where length ("HEIGHT" )> 11;
 
TRUNCATE TABLE OW_LAO.TF_CRAWLING_AP1_TABLET_1;
INSERT INTO OW_LAO.TF_CRAWLING_AP1_TABLET_1
SELECT DISTINCT
SUBSTRING(D."PROD_BRAND",0,99) "brand_nm"
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
,SUBSTRING(case when P."CURRENCY" is  null or  P."CURRENCY" ='' then D."CURRENCY" else P."CURRENCY" end,0,99) "site_price_currency"
, SUBSTRING(R."RATING",0,99) "site_rating"
, SUBSTRING(R."RATING_AMOUNT",0,99) "site_rating_amount"
, SUBSTRING(R."RATING_SCALE",0,99) "site_rating_scale"
, SUBSTRING(P."TODAY_DATE_TIME",0,99) "refer_date"
, SUBSTRING(case when P."POR_VALUE" is null then P."DE_VALUE" when P."POR_VALUE"='' then P."DE_VALUE" else P."POR_VALUE" end,0,16) "price_unit"
, SUBSTRING(D."WIDTH",0,99) "width_mm"
, SUBSTRING(D."HEIGHT",0,99) "height_mm"
, SUBSTRING(D."DEPTH",0,99) "depth_mm"
, SUBSTRING(D."DISPLAY_SIZE",0,99) "display_size"
, SUBSTRING(D."RAM",0,99) "ram_in_mb"
, SUBSTRING(D."CAPA",0,99) "internal_storage"
, SUBSTRING(D."DUAL_SIM",0,99) "dual_sim"
, SUBSTRING(D."CAMERA_REAR_RESO",0,99) "main_camera_mp"
, SUBSTRING(D."CAMERA_FRONT_RESO",0,99) "front_camera_mp"
, SUBSTRING(D."WEIGTH",0,16) "weight_gramm"
, SUBSTRING(D."DISPLAY_HORIZONTAL",0,99) "resolution_wid"
, SUBSTRING(D."DISPLAY_VERTICAL",0,99) "resolution_hig"
, SUBSTRING(D."BATTERY",0,99) "battery_capacity"
, SUBSTRING(P."DE_VALUE",0,16) "retail_price_base"
, SUBSTRING(P."POR_VALUE",0,16) "retail_price_actual"
, null "upfront_base"
, null "monthly_device_actual"
, null "contract_period"
, SUBSTRING(P."TODAY_DATE_TIME",0,99) "crawling_date"
, SUBSTRING(P.AVAILABLE,0,99) "product_available"
, null "process_status"
, null "comment_status"
, SUBSTRING(D.LAST_UPDATE,0,99) "product_update_date"
, NOW() process_datetime
FROM "OW_LAO"."ODS_CRAWLING_AP1_IM_PRODUCT_DAILY_PRICE" P			/*Mudar em Prod*/
INNER JOIN "OW_LAO"."ODS_CRAWLING_AP1_TABLET_PRODUCT_DETAIL" D     /*Mudar em Prod*/
ON P."KEY" = D."KEY"
LEFT JOIN OW_LAO."ODS_CRAWLING_AP1_TABLET_PRODUCT_DETAIL_DAILY" R			/*Criar Job no Pentaho --> select b.* , add_days(CURRENT_DATE,-0) as LOAD_DATE from "IF_RPA_CRAWLING"."ODS_CRAWLING_AP1_TABLET_PRODUCT_DETAIL" b*/
ON P."KEY" = R."KEY"
	AND to_char(P."TODAY_DATE_TIME", 'YYYY-MM-DD') = to_char(R."LOAD_DATE", 'YYYY-MM-DD') 
WHERE 1=1
AND to_char(P."TODAY_DATE_TIME", 'YYYY-MM-DD')  BETWEEN to_char(add_days(CURRENT_DATE,-15), 'YYYY-MM-DD') and  to_char(add_days(CURRENT_DATE,-1), 'YYYY-MM-DD')
--AND P."TODAY_DATE_TIME" > '2020-06-27 00:00' 
--AND to_char(P."TODAY_DATE_TIME", 'YYYY-MM-DD')  < to_char(CURRENT_DATE, 'YYYY-MM-DD')
AND UPPER(TRIM(PRODUCT_TYPE)) = 'TABLET'
;
-- DELETE erros
--> se todos atributos estão nulos ou vazios 
UPDATE OW_LAO.TF_CRAWLING_AP1_TABLET_1
SET
process_status = 'DELETED_BY_PROCESS'
, comment_status = 'No attributes'
WHERE
(width_mm is null or width_mm = '')
AND (height_mm is null or height_mm = '')
AND (depth_mm is null or depth_mm = '')
AND (display_size is null or display_size = '')
AND (ram_in_mb is null or ram_in_mb = '')
AND (internal_storage is null or internal_storage = '')
AND (dual_sim is null or dual_sim = '')
AND (main_camera_mp is null or main_camera_mp = '')
AND (front_camera_mp is null or front_camera_mp = '')
AND (weight_gramm is null or weight_gramm = '')
AND (resolution_wid is null or resolution_wid = '')
AND (resolution_hig is null or resolution_hig = '')
AND (battery_capacity is null or battery_capacity = '')
AND SITE_URL NOT IN (
			SELECT distinct SITE_URL 
			FROM OW_LAO.INPUT_CRAWLING_GSM_ARENA_MAPPING M 
			WHERE 
			MODEL_NM != 'DELETE'  )
;
--> site urls que nao devem ser mapeadas e deve ser excluidas do processamento
MERGE INTO OW_LAO.TF_CRAWLING_AP1_TABLET_1 O
USING (
SELECT * FROM (
SELECT DISTINCT 
  ROW_NUMBER() OVER (PARTITION BY SITE_URL ORDER BY LOAD_DATE desc) AS row_num,
  M.*
FROM "OW_LAO"."INPUT_CRAWLING_GSM_ARENA_MAPPING" M
WHERE 1=1
AND  MODEL_NM = 'DELETE'
) 
WHERE
row_num = 1
) T 
ON TRIM(O.SITE_URL) = TRIM(T.SITE_URL)
WHEN MATCHED THEN 
UPDATE
SET
process_status = 'DELETED_BY_EXCEPTION'
, comment_status = 'Clean'
;
-- Default Convertion
UPDATE OW_LAO.TF_CRAWLING_AP1_TABLET_1
 SET
  site_page = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(site_page)) FROM 1 OCCURRENCE 1) 
  , site_position = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(site_position)) FROM 1 OCCURRENCE 1) 
  , site_rating = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM( REPLACE(site_rating, ',','.'))) FROM 1 OCCURRENCE 1)
  , site_rating_amount = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(site_rating_amount)) FROM 1 OCCURRENCE 1) 
  , site_rating_scale = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(site_rating_scale)) FROM 1 OCCURRENCE 1) 
  , price_unit = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(price_unit)) FROM 1 OCCURRENCE 1) 
  , width_mm = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(width_mm)) FROM 1 OCCURRENCE 1) 
  , height_mm = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(height_mm)) FROM 1 OCCURRENCE 1) 
  , depth_mm = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(depth_mm)) FROM 1 OCCURRENCE 1) 
  , display_size = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(display_size)) FROM 1 OCCURRENCE 1) 
  , ram_in_mb = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(ram_in_mb)) FROM 1 OCCURRENCE 1) 
  , internal_storage =SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(internal_storage)) FROM 1 OCCURRENCE 1) 
  , dual_sim =  CASE WHEN Trim(dual_sim) = 'Y' THEN 'Yes' WHEN Trim(dual_sim) = 'N' THEN 'No' ELSE dual_sim END  
  , main_camera_mp = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(main_camera_mp)) FROM 1 OCCURRENCE 1) 
  , front_camera_mp = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(front_camera_mp)) FROM 1 OCCURRENCE 1) 
  , weight_gramm = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(weight_gramm)) FROM 1 OCCURRENCE 1) 
  , resolution_wid = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(resolution_wid)) FROM 1 OCCURRENCE 1) 
  , resolution_hig = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(resolution_hig)) FROM 1 OCCURRENCE 1) 
  , battery_capacity = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(battery_capacity)) FROM 1 OCCURRENCE 1) 
  , retail_price_base = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(retail_price_base)) FROM 1 OCCURRENCE 1) 
  , retail_price_actual = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(retail_price_actual)) FROM 1 OCCURRENCE 1) 
  ;
-- formata os campos conforme o GSM Arena
 UPDATE OW_LAO.TF_CRAWLING_AP1_TABLET_1
 SET
 	width_mm = TO_DECIMAL(width_mm, 8, 1)
 	, height_mm =  TO_DECIMAL(height_mm, 8, 1) 
 	, depth_mm = TO_DECIMAL(depth_mm, 8, 1) 
	, display_size =  TO_DECIMAL(display_size, 6, 1) 
 	, ram_in_mb =  TO_DECIMAL(ram_in_mb, 16, 1) 
 	, internal_storage = TO_DECIMAL(internal_storage, 8, 0) 
 	, main_camera_mp = TO_DECIMAL(main_camera_mp, 8, 0) 
 	, front_camera_mp = TO_DECIMAL(front_camera_mp, 8, 0)
	, weight_gramm = TO_DECIMAL(weight_gramm, 8, 1)
 	, resolution_wid = TO_DECIMAL(resolution_wid, 8, 0)
 	, resolution_hig = TO_DECIMAL(resolution_hig, 8, 0)
	, battery_capacity = TO_DECIMAL(battery_capacity, 8, 0)
 ;
 
 -- limpeza do campos desc
 UPDATE OW_LAO.TF_CRAWLING_AP1_TABLET_1
 SET 
 model_nm = TRIM(REPLACE(REPLACE(REPLACE(UPPER(model_nm), 'CELULAR', ''), 'SMARTPHONE',''),'SAMSUNG', ''))
 ;
/*
UPDATE OW_LAO.TF_CRAWLING_AP1_TABLET_1
 SET 
 model_desc = TRIM(REPLACE(REPLACE(REPLACE(UPPER(model_desc), 'CELULAR', ''), 'SMARTPHONE',''),'SAMSUNG', ''))
;
*/
 -- se model_nm está vazio ou nulo, inclui parte do site_url no lugar.
 UPDATE OW_LAO.TF_CRAWLING_AP1_TABLET_1
 SET 
 model_nm = CASE WHEN Trim(model_nm) = '' or Trim(model_nm) is null 
 			THEN SUBSTRING(REPLACE(TRIM(site_url),TRIM(site_nm), ''), 1,99)
 			ELSE Trim(model_nm)  END
 ;
-- caso os campos de rating estão nulos colocamos vazio para mapear na query final da pt2
 UPDATE OW_LAO.TF_CRAWLING_AP1_TABLET_1
 SET
	site_rating = COALESCE (site_rating, '') 
	, site_rating_amount = COALESCE (site_rating_amount, '') 
	, site_rating_scale = COALESCE (site_rating_scale, '') 
;
	
UPDATE OW_LAO.TF_CRAWLING_AP1_TABLET_1
 SET
BRAND_NM = CASE 
	WHEN UPPER(TRIM(BRAND_NM)) = 'MOTO' 
		THEN 'MOTOROLA'
	WHEN UPPER(TRIM(BRAND_NM)) IN ('IPHONE', 'XR', 'XS', '8', '11') 
		THEN 'APPLE'
	WHEN UPPER(TRIM(BRAND_NM)) IN ('MI','REDMI', 'XIAOMÍ') 
		THEN 'XIAOMI'
	ELSE TRIM(UPPER(BRAND_NM))
END
;
/*
06/10/2020
Merge para forcar os atributos do GSMArena nas URLs mapeadar manualmente #chupabarone, by Duek powered by Mello 
*/
UPDATE   OW_LAO.TF_CRAWLING_AP1_TABLET_1 O
 SET
O."WIDTH_MM" =T."WIDTH_MM" ,
O."HEIGHT_MM" = T."HEIGHT_MM" ,
O."DEPTH_MM" = T."DEPTH_MM" ,
O."DISPLAY_SIZE" = T."DISPLAY_SIZE" ,
O."RAM_IN_MB" = T."RAM_IN_MB" ,
O."INTERNAL_STORAGE" = T."INTERNAL_STORAGE" ,
O."DUAL_SIM" = T."DUAL_SIM" ,
O."MAIN_CAMERA_MP" = T."MAIN_CAMERA_MP" ,
O."FRONT_CAMERA_MP" = T."FRONT_CAMERA_MP" ,
O."WEIGHT_GRAMM" = T."WEIGHT_GRAMM" ,
O."RESOLUTION_WID" = T."RESOLUTION_WID" ,
O."RESOLUTION_HIG" = T."RESOLUTION_HIG" ,
O."BATTERY_CAPACITY" = T."BATTERY_CAPACITY" ,
O.process_status = 'MAPPED_BY_EXCEPTION'
from 
OW_LAO.TF_CRAWLING_AP1_TABLET_1 O 
inner join 
 (select 
	DISTINCT
	a.SITE_URL,
	C."WIDTH_MM" ,
 C."HEIGHT_MM",
 C."DEPTH_MM",
 C."DISPLAY_SIZE",
C."RAM_IN_MB",
 C."INTERNAL_STORAGE",
 C."DUAL_SIM",
 C."MAIN_CAMERA_MP",
 C."FRONT_CAMERA_MP",
 C."WEIGHT_GRAMM",
 C."RESOLUTION_WID",
 C."RESOLUTION_HIG",
 C."BATTERY_CAPACITY"
FROM OW_LAO.TF_CRAWLING_AP1_TABLET_1 A
INNER JOIN OW_LAO.INPUT_CRAWLING_GSM_ARENA_MAPPING M 
ON a.SITE_URL = M.SITE_URL 
INNER JOIN ( 
SELECT DISTINCT
 max(model_code) model_code, mktcode, mktname, model_nm, brand_nm ,
"WIDTH_MM" ,
 "HEIGHT_MM",
 "DEPTH_MM",
 "DISPLAY_SIZE",
"RAM_IN_MB",
 "INTERNAL_STORAGE",
 "DUAL_SIM",
 "MAIN_CAMERA_MP",
 "FRONT_CAMERA_MP",
 "WEIGHT_GRAMM",
 "RESOLUTION_WID",
 "RESOLUTION_HIG",
 "BATTERY_CAPACITY"
FROM OW_LAO.MP_GSMARENA_MERGE_DATA_MAPPING
WHERE
model_code not like '%_X'
GROUP BY 
mktcode, mktname, model_nm, brand_nm ,
"WIDTH_MM" ,
 "HEIGHT_MM",
 "DEPTH_MM",
 "DISPLAY_SIZE",
"RAM_IN_MB",
 "INTERNAL_STORAGE",
 "DUAL_SIM",
 "MAIN_CAMERA_MP",
 "FRONT_CAMERA_MP",
 "WEIGHT_GRAMM",
 "RESOLUTION_WID",
 "RESOLUTION_HIG",
 "BATTERY_CAPACITY"
) C
ON M.model_nm = C.model_nm
AND A.brand_nm = C.brand_nm 
)T
 ON TRIM(O.SITE_URL) = TRIM(T.SITE_URL)
;
-- Etapa: 1
TRUNCATE TABLE OW_LAO.TF_CRAWLING_AP1_TABLET_2;
INSERT INTO OW_LAO.TF_CRAWLING_AP1_TABLET_2
	SELECT 
		DENSE_RANK() OVER (
			PARTITION BY brand_nm, model_desc
			ORDER BY width_mm, height_mm, depth_mm, display_size, ram_in_mb, internal_storage, dual_sim, main_camera_mp, front_camera_mp, weight_gramm, resolution_wid, resolution_hig, battery_capacity
		) as idxbyrsnmodelnm,
		brand_nm,
		model_desc,
		subsidiary,
		country,
		country_code,
		site_company_name,
		site_nm,
		site_url,
		site_page,
		site_position,
		site_price_currency,
		site_rating,
		site_rating_amount,
		site_rating_scale,
		refer_date,
		price_unit,		
		width_mm,
		height_mm,
		depth_mm,
		display_size,
		ram_in_mb,
		internal_storage,
		dual_sim,
		main_camera_mp,
		front_camera_mp,
		weight_gramm,
		resolution_wid,
		resolution_hig,
		battery_capacity,
		price_local_base,
		price_local_act,
		price_local_down,
		price_local_monthly,
		price_local_months,
		TO_CHAR(current_timestamp, 'YYYY/MM/DD HH24:MI:SS')
	FROM (
		select * from (
			--RSN1
			select 
				UPPER(TRIM(brand_nm)) as brand_nm,
				TRIM(model_desc) as model_desc,
				subsidiary,
				country,
				country_code,
				site_company_name,
				site_nm,
				site_url,
				site_page,
				site_position,
				site_price_currency,
				site_rating,
				site_rating_amount,
				site_rating_scale,
				refer_date,
				price_unit,		
				width_mm,
				height_mm,
				depth_mm,
				display_size,
				ram_in_mb,
				internal_storage,
				dual_sim,
				main_camera_mp,
				front_camera_mp,
				weight_gramm,
				resolution_wid,
				resolution_hig,
				battery_capacity,
				retail_price_base as price_local_base,
				retail_price_actual as price_local_act,
				upfront_base as price_local_down,
				monthly_device_actual as price_local_monthly,
				contract_period as price_local_months,
				crawling_date
			FROM OW_LAO.TF_CRAWLING_AP1_TABLET_1
			WHERE
			process_status is null
			or 
			process_status = 'MAPPED_BY_EXCEPTION'
			) v
		WHERE 1=1
		--AND TO_CHAR(refer_date, 'yyyymm') >= _past_ym
		--AND refer_date - crawling_date < 7
		
	) v
	ORDER BY brand_nm, model_desc, idxbyrsnmodelnm
	;
	
	
-- Etapa: 2
	-- Exclusão de preços menores que 0?
TRUNCATE TABLE OW_LAO.TF_CRAWLING_AP1_TABLET_3;
INSERT INTO OW_LAO.TF_CRAWLING_AP1_TABLET_3
	SELECT
		brand_nm, model_nm, idxbyrsnmodelnm, width_mm, height_mm, depth_mm, display_size, ram_in_mb, internal_storage, dual_sim, main_camera_mp, front_camera_mp, weight_gramm, resolution_wid, resolution_hig, battery_capacity
	FROM OW_LAO.TF_CRAWLING_AP1_TABLET_2
	GROUP BY brand_nm, model_nm, idxbyrsnmodelnm, width_mm, height_mm, depth_mm, display_size, ram_in_mb, internal_storage, dual_sim, main_camera_mp, front_camera_mp, weight_gramm, resolution_wid, resolution_hig, battery_capacity
	ORDER BY brand_nm, model_nm, CAST(idxbyrsnmodelnm as INTEGER);
-- Etapa: 3
TRUNCATE TABLE OW_LAO.TF_CRAWLING_AP1_TABLET_4;
INSERT INTO OW_LAO.TF_CRAWLING_AP1_TABLET_4
SELECT 
	brand_nm,
	model_nm,	
	idxbyrsnmodelnm,
	width_mm,
	height_mm,
	depth_mm,
	display_size,
	ram_in_mb,
	internal_storage,
	dual_sim,
	main_camera_mp,
	front_camera_mp,
	weight_gramm,
	resolution_wid,
	resolution_hig,
	battery_capacity,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'')) as case1,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'')) as case2,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'')) as case3,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'')) as case4,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case5,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case6,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case7,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case8,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case9,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case10,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'')) as case11,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'')) as case12,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'')) as case13,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case14,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case15,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case16,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case17,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case18,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case19,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'')) as case20,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'')) as case21,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case22,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case23,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case24,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case25,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case26,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case27,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'')) as case28,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case29,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case30,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case31,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case32,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case33,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case34,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case35,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case36,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case37,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case38,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case39,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case40,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case41,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case42,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case43,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case44,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case45,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case46,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case47,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case48,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case49,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case50,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case51,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case52,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case53,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case54,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( width_mm as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case55,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'')) as case56,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'')) as case57,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'')) as case58,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case59,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case60,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case61,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case62,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case63,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case64,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'')) as case65,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'')) as case66,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case67,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case68,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case69,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case70,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case71,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case72,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'')) as case73,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case74,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case75,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case76,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case77,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case78,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case79,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case80,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case81,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case82,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case83,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case84,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case85,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case86,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case87,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case88,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case89,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case90,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case91,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case92,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case93,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case94,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case95,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case96,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case97,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case98,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case99,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case100,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'')) as case101,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'')) as case102,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case103,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case104,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case105,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case106,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case107,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case108,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'')) as case109,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case110,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case111,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case112,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case113,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case114,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case115,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case116,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case117,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case118,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case119,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case120,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case121,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case122,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case123,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case124,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case125,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case126,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case127,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case128,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case129,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case130,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case131,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case132,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case133,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case134,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case135,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case136,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'')) as case137,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case138,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case139,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case140,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case141,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case142,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case143,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case144,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case145,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case146,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case147,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case148,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case149,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case150,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case151,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case152,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case153,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case154,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case155,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case156,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case157,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case158,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case159,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case160,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case161,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case162,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case163,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case164,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case165,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case166,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case167,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case168,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case169,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case170,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case171,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case172,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case173,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case174,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case175,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case176,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case177,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case178,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case179,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case180,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case181,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case182,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case183,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case184,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case185,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case186,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case187,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case188,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case189,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case190,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case191,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case192,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case193,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case194,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case195,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case196,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case197,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case198,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case199,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case200,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case201,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case202,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case203,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case204,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case205,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case206,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case207,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case208,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case209,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case210,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case211,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case212,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case213,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case214,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case215,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case216,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case217,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case218,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case219,
	(COALESCE(CAST(height_mm as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case220,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'')) as case221,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'')) as case222,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'')) as case223,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case224,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case225,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case226,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case227,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case228,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case229,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'')) as case230,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'')) as case231,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case232,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case233,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case234,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case235,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case236,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case237,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'')) as case238,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case239,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case240,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case241,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case242,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case243,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case244,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case245,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case246,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case247,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case248,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case249,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case250,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case251,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case252,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case253,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case254,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case255,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case256,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case257,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case258,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case259,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case260,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case261,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case262,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case263,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case264,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( depth_mm as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case265,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'')) as case266,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'')) as case267,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case268,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case269,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case270,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case271,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case272,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case273,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'')) as case274,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case275,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case276,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case277,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case278,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case279,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case280,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case281,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case282,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case283,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case284,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case285,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case286,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case287,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case288,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case289,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case290,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case291,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case292,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case293,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case294,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case295,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case296,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case297,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case298,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case299,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case300,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case301,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'')) as case302,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case303,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case304,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case305,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case306,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case307,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case308,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case309,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case310,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case311,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case312,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case313,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case314,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case315,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case316,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case317,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case318,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case319,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case320,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case321,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case322,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case323,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case324,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case325,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case326,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case327,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case328,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case329,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case330,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case331,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case332,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case333,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case334,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case335,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case336,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case337,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case338,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case339,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case340,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case341,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case342,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case343,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case344,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case345,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case346,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case347,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case348,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case349,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case350,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case351,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case352,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case353,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case354,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case355,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case356,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case357,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case358,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case359,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case360,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case361,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case362,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case363,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case364,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case365,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case366,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case367,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case368,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case369,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case370,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case371,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case372,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case373,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case374,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case375,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case376,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case377,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case378,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case379,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case380,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case381,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case382,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case383,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case384,
	(COALESCE(CAST(width_mm as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case385,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'')) as case386,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'')) as case387,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case388,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case389,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case390,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case391,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case392,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case393,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'')) as case394,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case395,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case396,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case397,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case398,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case399,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case400,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case401,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case402,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case403,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case404,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case405,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case406,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case407,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case408,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case409,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case410,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case411,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case412,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case413,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case414,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case415,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case416,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case417,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case418,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case419,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case420,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( weight_gramm as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case421,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'')) as case422,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case423,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case424,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case425,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case426,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case427,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case428,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case429,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case430,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case431,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case432,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case433,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case434,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case435,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case436,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case437,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case438,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case439,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case440,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case441,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case442,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case443,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case444,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case445,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case446,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case447,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case448,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case449,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case450,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case451,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case452,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case453,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case454,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case455,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case456,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case457,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case458,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case459,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case460,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case461,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case462,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case463,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case464,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case465,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case466,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case467,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case468,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case469,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case470,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case471,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case472,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case473,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case474,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case475,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case476,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case477,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case478,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case479,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case480,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case481,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case482,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case483,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case484,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case485,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case486,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case487,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case488,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case489,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case490,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case491,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case492,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case493,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case494,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case495,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case496,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case497,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case498,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case499,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case500,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case501,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case502,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case503,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case504,
	(COALESCE(CAST(depth_mm as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case505,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'')) as case506,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case507,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case508,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case509,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case510,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case511,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case512,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case513,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case514,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case515,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case516,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case517,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case518,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case519,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case520,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case521,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case522,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case523,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case524,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case525,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case526,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case527,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case528,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case529,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case530,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case531,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case532,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( display_size as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case533,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case534,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case535,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case536,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case537,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case538,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case539,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case540,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case541,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case542,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case543,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case544,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case545,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case546,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case547,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case548,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case549,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case550,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case551,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case552,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case553,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case554,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case555,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case556,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case557,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case558,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case559,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case560,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case561,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case562,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case563,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case564,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case565,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case566,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case567,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case568,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case569,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case570,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case571,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case572,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case573,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case574,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case575,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case576,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case577,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case578,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case579,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case580,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case581,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case582,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case583,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case584,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case585,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case586,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case587,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case588,
	(COALESCE(CAST(weight_gramm as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case589,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'')) as case590,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case591,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case592,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case593,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case594,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case595,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case596,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case597,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case598,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case599,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case600,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case601,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case602,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case603,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case604,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case605,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case606,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case607,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case608,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case609,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_wid as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case610,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case611,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case612,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case613,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case614,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case615,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case616,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case617,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case618,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case619,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case620,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case621,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case622,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case623,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case624,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case625,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case626,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case627,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case628,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case629,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case630,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case631,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case632,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case633,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case634,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case635,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case636,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case637,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case638,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case639,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case640,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case641,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case642,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case643,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case644,
	(COALESCE(CAST(display_size as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case645,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'')) as case646,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case647,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case648,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case649,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case650,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case651,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case652,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case653,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case654,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case655,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case656,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case657,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case658,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case659,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( resolution_hig as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case660,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case661,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case662,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case663,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case664,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case665,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case666,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case667,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case668,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case669,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case670,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case671,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case672,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case673,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case674,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case675,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case676,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case677,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case678,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case679,
	(COALESCE(CAST(resolution_wid as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case680,
	(COALESCE(CAST(resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'')) as case681,
	(COALESCE(CAST(resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case682,
	(COALESCE(CAST(resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case683,
	(COALESCE(CAST(resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case684,
	(COALESCE(CAST(resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case685,
	(COALESCE(CAST(resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case686,
	(COALESCE(CAST(resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case687,
	(COALESCE(CAST(resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case688,
	(COALESCE(CAST(resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case689,
	(COALESCE(CAST(resolution_hig as character varying),'') || '_' || COALESCE(CAST( main_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case690,
	(COALESCE(CAST(resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case691,
	(COALESCE(CAST(resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case692,
	(COALESCE(CAST(resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case693,
	(COALESCE(CAST(resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case694,
	(COALESCE(CAST(resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case695,
	(COALESCE(CAST(resolution_hig as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case696,
	(COALESCE(CAST(resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case697,
	(COALESCE(CAST(resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case698,
	(COALESCE(CAST(resolution_hig as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case699,
	(COALESCE(CAST(resolution_hig as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case700,
	(COALESCE(CAST(main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'')) as case701,
	(COALESCE(CAST(main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case702,
	(COALESCE(CAST(main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case703,
	(COALESCE(CAST(main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case704,
	(COALESCE(CAST(main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case705,
	(COALESCE(CAST(main_camera_mp as character varying),'') || '_' || COALESCE(CAST( front_camera_mp as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case706,
	(COALESCE(CAST(main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case707,
	(COALESCE(CAST(main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case708,
	(COALESCE(CAST(main_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case709,
	(COALESCE(CAST(main_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case710,
	(COALESCE(CAST(front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'')) as case711,
	(COALESCE(CAST(front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case712,
	(COALESCE(CAST(front_camera_mp as character varying),'') || '_' || COALESCE(CAST( ram_in_mb as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case713,
	(COALESCE(CAST(front_camera_mp as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case714,
	(COALESCE(CAST(ram_in_mb as character varying),'') || '_' || COALESCE(CAST( internal_storage as character varying),'') || '_' || COALESCE(CAST( battery_capacity as character varying),'') || '_' || COALESCE(CAST( dual_sim as character varying),'')) as case715
	FROM OW_LAO.TF_CRAWLING_AP1_TABLET_3;	
-- Etapa 4
 
TRUNCATE TABLE OW_LAO.TF_CRAWLING_AP1_TABLET_5;
_loopnum := 715;
i := 1;
	
	FOR i IN 1.._loopnum DO
	_case_str := 'case' || i ;
_vp_query := '
		INSERT INTO OW_LAO.TF_CRAWLING_AP1_TABLET_5
		SELECT'
		|| ' CAST(' || '''' || _case_str || '''' || ' as character varying)' || ' as combine_type,
			COALESCE(CAST(b.model_code as character varying),'''') as model_code,
			COALESCE(CAST(b.model_nm as character varying),'''') as pa_model_nm,
			COALESCE(CAST(b.brand_nm as character varying),'''') as pa_brand_nm,
			COALESCE(CAST(b.mktname as character varying),'''') as pa_mktname,
		a.idxbyrsnmodelnm,
		a.brand_nm,
		a.model_nm,	
		a.width_mm,
		a.height_mm,
		a.depth_mm,
		a.display_size,
		a.ram_in_mb,
		a.internal_storage,
		a.dual_sim,
		a.main_camera_mp,
		a.front_camera_mp,
		a.weight_gramm,
		a.resolution_wid,
		a.resolution_hig,
		a.battery_capacity,
		CONCAT(CONCAT (''('', TRIM( SUBSTRING_REGEXPR(''[^ ]+'' IN  (SUBSTRING_REGEXPR(''[^/]+'' IN trim(lower(replace(replace(b.model_nm,''('',''''),'')'',''''))) FROM 1 OCCURRENCE 1)) FROM 1 OCCURRENCE 1))),'')'' ),
		CONCAT(CONCAT (''('', TRIM( SUBSTRING_REGEXPR(''[^ ]+'' IN  (SUBSTRING_REGEXPR(''[^/]+'' IN trim(lower(replace(replace(b.model_nm,''('',''''),'')'',''''))) FROM 1 OCCURRENCE 1)) FROM 1 OCCURRENCE 2))),'')'' ),
		CONCAT(CONCAT (''('', TRIM( SUBSTRING_REGEXPR(''[^ ]+'' IN  (SUBSTRING_REGEXPR(''[^/]+'' IN trim(lower(replace(replace(b.model_nm,''('',''''),'')'',''''))) FROM 1 OCCURRENCE 1)) FROM 1 OCCURRENCE 3))),'')'' ),
		CONCAT(CONCAT (''('', TRIM( SUBSTRING_REGEXPR(''[^ ]+'' IN  (SUBSTRING_REGEXPR(''[^/]+'' IN trim(lower(replace(replace(replace(replace(b.model_nm,''('',''''),'')'',''''),''"'',''''),''+'',''''))) FROM 1 OCCURRENCE 1)) FROM 1 OCCURRENCE 4))),'')'' ),
		CONCAT(CONCAT (''('', TRIM( SUBSTRING_REGEXPR(''[^,]+'' IN  (SUBSTRING_REGEXPR(''[^/]+'' IN trim(lower(replace(replace(b.model_nm,''('',''''),'')'',''''))) FROM 1 OCCURRENCE 2)) FROM 1 OCCURRENCE 1))),'')'' ),
		CONCAT(CONCAT (''('', TRIM( SUBSTRING_REGEXPR(''[^,]+'' IN  (SUBSTRING_REGEXPR(''[^/]+'' IN trim(lower(replace(replace(b.model_nm,''('',''''),'')'',''''))) FROM 1 OCCURRENCE 2)) FROM 1 OCCURRENCE 2))),'')'' ) 	
			
		FROM (
			SELECT 
				brand_nm,
				model_nm,	
				idxbyrsnmodelnm,
				width_mm,
				height_mm,
				depth_mm,
				display_size,
				ram_in_mb,
				internal_storage,
				dual_sim,
				main_camera_mp,
				front_camera_mp,
				weight_gramm,
				resolution_wid,
				resolution_hig,
				battery_capacity,
				COALESCE(CAST(case' || :i || ' as character varying),'''') as case' || :i || '
				
			FROM OW_LAO.TF_CRAWLING_AP1_TABLET_4
		) a,
		( 
			SELECT
				COALESCE(CAST(model_code as character varying),'''')as model_code,
				COALESCE(CAST(brand_nm as character varying),'''')as brand_nm,
				COALESCE(CAST(mktname as character varying),'''')as mktname,
				COALESCE(CAST(model_nm as character varying),'''')as model_nm,	
				COALESCE(CAST(case' || :i || ' as character varying),'''') as case' || :i || '
			FROM MP_GSMARENA_MERGE_DATA_MAPPING_KEY
		) b
		WHERE a.case' || i || '= b.case' || i || ' AND a.brand_nm = b.brand_nm';
		 EXEC  _vp_query;
		
	END FOR;
END;