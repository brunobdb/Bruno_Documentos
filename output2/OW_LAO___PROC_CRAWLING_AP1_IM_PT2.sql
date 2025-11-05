CREATE PROCEDURE PROC_CRAWLING_AP1_IM_PT2
LANGUAGE SQLSCRIPT as
BEGIN
-- Etapa 5
	TRUNCATE TABLE TF_CRAWLING_AP1_IM_6;
					
	INSERT INTO TF_CRAWLING_AP1_IM_6
	SELECT 
	model_nm as rsn_modelnm,
	CAST(idxbyrsnmodelnm as INTEGER) as idxbyrsnmodelnm,
	model_code,
	pa_model_nm,
	cnt as mapping_cnt,
	mapping_point,
	ROUND((CAST(mapping_point as NUMERIC)/ 90869 ) * 100,2) as p_percent,
	fix_ranking 
FROM (
	SELECT 
		a.*,
		ROW_NUMBER() OVER (PARTITION BY model_nm,idxbyrsnmodelnm ORDER BY regex_rank DESC, compare_value ASC, mapping_point DESC, cnt DESC, model_code ASC) as fix_ranking
	FROM (
	SELECT 
		model_nm,
		idxbyrsnmodelnm,
		model_code,
		pa_model_nm, 
		pa_mktname,		
		cnt,
		mapping_point,
		rsnNm_compare,
		paNm_compare,
		CASE WHEN rsnNm_compare =  paNm_compare
		THEN 1 ELSE 2 
		END as compare_value
		, regex_rank
	FROM  (	
	SELECT
			/*
			RSN 마케팅과 통합모델DB 마케팅명이 같을 시 우선순위 높게 책정
			예) RSN model_nm : "Samsung Galaxy J2 Pro (2018) 16GB"
			통합DB mktname : "Galaxy J2 Pro (2018)"
			RSN model_nm 문자열 변환 : "galaxy j2 pro"
			통합DB mktname 문자열 변환 : "galaxy j2 pro"
						
			trim(
			split_part(	
			lower((regexp_matches(
			SUBSTR(model_nm, 1, POSITION(trim((regexp_matches(model_nm , '[0-9]GB'))[1]) in model_nm))
		, ' .* ', 'g'))[1])
		,'(',1)
		) as rsnNm_compare,
		*/
		--trim(lower(model_nm)) as rsnNm_compare, -- substituindo temporariamente o comando acima "comentado"
		SUBSTRING_REGEXPR('[A-Z][0-9][0-9]' IN trim(UPPER(model_nm)) FROM 1 OCCURRENCE 1) as rsnNm_compare, -- substituindo temporariamente o comando acima "comentado"
		--trim(lower(split_part(pa_mktname,'(',1))) as paNm_compare,
		--SUBSTRING_REGEXPR('[^(]+' IN trim(lower(pa_mktname)) FROM 1 OCCURRENCE 1)  as paNm_compare, -- split string - sustintuindo a condição acima "comentada"
		SUBSTRING_REGEXPR('[A-Z][0-9][0-9]' IN trim(UPPER(pa_mktname)) FROM 1 OCCURRENCE 1) as paNm_compare, -- subtituição para pegar parte do model code
		model_nm,						
		idxbyrsnmodelnm,
		model_code,
		pa_model_nm, 
		pa_mktname,		
		COUNT(model_code) as cnt
		,SUM(
			CASE WHEN combine_type = 'case1' THEN 9087 ELSE 0 END + 							
			CASE WHEN combine_type = 'case5' THEN 18174 ELSE 0 END + 
			CASE WHEN combine_type = 'case6' THEN 18174 ELSE 0 END + 
			CASE WHEN combine_type = 'case7' THEN 18174 ELSE 0 END + 
			CASE WHEN combine_type = 'case8' THEN 18174 ELSE 0 END + 
			CASE WHEN combine_type = 'case14' THEN 699 ELSE 0 END + 
			CASE WHEN combine_type = 'case15' THEN 699 ELSE 0 END + 
			CASE WHEN combine_type = 'case16' THEN 699 ELSE 0 END + 
			CASE WHEN combine_type = 'case17' THEN 699 ELSE 0 END + 
			CASE WHEN combine_type = 'case59' THEN 699 ELSE 0 END + 
			CASE WHEN combine_type = 'case60' THEN 699 ELSE 0 END + 
			CASE WHEN combine_type = 'case61' THEN 699 ELSE 0 END + 
			CASE WHEN combine_type = 'case62' THEN 699 ELSE 0 END + 
			CASE WHEN combine_type = 'case224' THEN 699 ELSE 0 END + 
			CASE WHEN combine_type = 'case225' THEN 699 ELSE 0 END + 
			CASE WHEN combine_type = 'case226' THEN 699 ELSE 0 END + 
			CASE WHEN combine_type = 'case227' THEN 699 ELSE 0 END + 
			CASE WHEN combine_type like 'case%' THEN 1 ELSE 0 END 
		) as mapping_point
		/*
			SDSLA (a.duek)
			Divide as partes do texto do GSM Arena e compara com a descrição do produto no Crawling (MODEL_CODE),
			cada parte tem uma pontuação
		*/
		,
		( 
		 ( CASE
			WHEN trim(lower(replace(model_nm,' ',''))) LIKE_REGEXPR( trim(pa_model_nm_regex_1) )
			THEN 5
			ELSE 0
		 END )
		 +
		 ( CASE
			WHEN trim(lower(replace(model_nm,' ',''))) LIKE_REGEXPR( trim(pa_model_nm_regex_2) )
			THEN 10
			ELSE 0
		END ) 
		 +
		 ( CASE
			WHEN trim(lower(replace(model_nm,' ',''))) LIKE_REGEXPR( trim(pa_model_nm_regex_3) )
			THEN 10
			ELSE 0
		 END )
		 +
		 ( CASE
			WHEN trim(lower(replace(model_nm,' ',''))) LIKE_REGEXPR( trim(pa_model_nm_regex_4) )
			THEN 5
			ELSE 0
		END ) 
		+
		 ( CASE
			WHEN SUBSTRING_REGEXPR('\b\d{1}(g)\b' IN replace(lower(model_nm),' ','' )) LIKE_REGEXPR( trim(pa_model_nm_regex_5) )
			THEN 1
			ELSE 0
		END )
		 +
		 ( CASE
			WHEN  trim(lower(replace(model_nm,' ',''))) LIKE_REGEXPR( trim(pa_model_nm_regex_6) )
			THEN 3
			ELSE 0
		END ) 
		) regex_rank
	FROM TF_CRAWLING_AP1_IM_5			
	--WHERE model_nm = 'Huawei P Smart+ 2019 (Huawei Maimang 8) 128GB' 
	GROUP BY model_nm, idxbyrsnmodelnm, model_code, pa_model_nm, pa_mktname, pa_model_nm_regex_1, pa_model_nm_regex_2, pa_model_nm_regex_3, pa_model_nm_regex_4,pa_model_nm_regex_5 ,pa_model_nm_regex_6
	) v
ORDER BY model_nm, idxbyrsnmodelnm, model_code, pa_model_nm, pa_mktname		
) a		
ORDER BY model_nm, idxbyrsnmodelnm,fix_ranking 
) v
--WHERE mapping_point >= 210;
WHERE mapping_point >= 0
;
-- Etapa 6
TRUNCATE TABLE TF_CRAWLING_AP1_IM_7;
	INSERT INTO TF_CRAWLING_AP1_IM_7
	SELECT 
		rsn_modelnm,
		idxbyrsnmodelnm,
		model_code,
		phonearena_modelnm,
		mapping_cnt,
		mapping_point,
		p_percent,
		mp_agv,
		final_ranking
	FROM  (
		--평균값 및 매핑포인터로 랭킹 구함
		SELECT *, ROW_NUMBER() OVER(PARTITION BY rsn_modelnm ORDER BY mp_agv DESC, mapping_point DESC) as final_ranking 
		FROM (
			--모델, 매핑모델별 평균값 구함
			/*
			SELECT *, ROUND(AVG(mapping_point) OVER(PARTITION BY rsn_modelnm, phonearena_modelnm),1) as mp_agv FROM CVP.mp_gui_price_phonearena_mapping_rank_data
			WHERE fix_ranking=1
			ORDER BY rsn_modelnm, idxbyrsnmodelnm, phonearena_modelnm
			*/
			--20190708 phonearena 모델명 중복으로 phonearena_modelnm -> model_code로 변경
			SELECT *
			, ROUND(AVG(mapping_point) OVER(PARTITION BY rsn_modelnm, model_code),1) as mp_agv
			FROM 
			TF_CRAWLING_AP1_IM_6
			WHERE fix_ranking=1
			ORDER BY rsn_modelnm, idxbyrsnmodelnm, model_code
		) v
		ORDER BY rsn_modelnm, idxbyrsnmodelnm
	) b ;
		
-- Etapa 7
TRUNCATE TABLE TF_CRAWLING_AP1_IM_8;
INSERT INTO TF_CRAWLING_AP1_IM_8
SELECT 
	b.model_code as pa_model_code,
	c.brand_nm as pa_brand_nm,
	--20190617 Dual SIM 삭제 및 모델네임 통합건
	c.mktcode as pa_mktcode,
	c.mktname as pa_mktname,
	c.model_nm as pa_model_nm,
	a.*	
FROM TF_CRAWLING_AP1_IM_2 a
INNER JOIN TF_CRAWLING_AP1_IM_7 b
--20190611 모델명 통일 삭제
--on a.model_nm = b.rsn_modelnm
ON a.model_nm = b.rsn_modelnm AND a.idxbyrsnmodelnm = b.idxbyrsnmodelnm
INNER JOIN MP_GSMARENA_MERGE_DATA_MAPPING c
ON b.model_code = c.model_code
AND a.BRAND_NM = c.BRAND_NM  
;
/* --Devido a geração de duplicidades, essa parte do código foi comentada
-- Regra de exceção
INSERT INTO TF_CRAWLING_AP1_IM_8
SELECT 
	C.model_code as pa_model_code,
	C.brand_nm as pa_brand_nm,
	C.mktcode as pa_mktcode,
	C.mktname as pa_mktname,
	C.model_nm as pa_model_nm,
	a.*
FROM TF_CRAWLING_AP1_IM_2 A
INNER JOIN OW_LAO.INPUT_CRAWLING_GSM_ARENA_MAPPING M 
ON a.SITE_URL = M.SITE_URL 
INNER JOIN ( 
SELECT DISTINCT max(model_code) model_code, mktcode, mktname, model_nm, brand_nm 
FROM MP_GSMARENA_MERGE_DATA_MAPPING
WHERE
model_code not like '%_X'
GROUP BY mktcode, mktname, model_nm, brand_nm 
) C
ON M.model_nm = C.model_nm
AND A.brand_nm = C.brand_nm  
;
*/
UPDATE TF_CRAWLING_AP1_IM_1
SET
process_status = 'MAPPED_BY_PROCESS'
, comment_status = 'Adjust attibrutes (Round)'
WHERE
SITE_URL IN (
SELECT 
	DISTINCT
	SITE_URL
FROM TF_CRAWLING_AP1_IM_8 
WHERE
pa_model_code like '%_X'
) 
;
UPDATE TF_CRAWLING_AP1_IM_1
SET
process_status = 'MAPPED_BY_PROCESS'
, comment_status = 'Default Process'
WHERE
SITE_URL IN (
SELECT 
	DISTINCT
	SITE_URL
FROM TF_CRAWLING_AP1_IM_8 
WHERE
pa_model_code not like '%_X'
) 
AND process_status is null
;
UPDATE TF_CRAWLING_AP1_IM_1
SET
process_status = 'NOT_MAPPED_BY_PROCESS'
WHERE
SITE_URL IN (
SELECT DISTINCT F.SITE_URL 
FROM TF_CRAWLING_AP1_IM_1 F
LEFT JOIN TF_CRAWLING_AP1_IM_8 T 
ON F.SITE_URL = T.SITE_URL 
WHERE
T.SITE_URL is null AND F.PROCESS_STATUS is null
);
-- Etapa 8
TRUNCATE TABLE TF_CRAWLING_AP1_IM_9;
INSERT INTO TF_CRAWLING_AP1_IM_9
	SELECT * FROM TF_CRAWLING_AP1_IM_8;
  
MERGE INTO TF_CRAWLING_AP1_IM_9 O
USING MP_GSMARENA_MERGE_DATA_A_MINMODELCODE M 
ON replace(O.pa_brand_nm,' ','')=M.trim_brand_nm
  and replace(O.pa_mktname,' ','')=M.trim_mktname
  and replace(O.pa_model_nm,' ','')=M.trim_model_nm
WHEN MATCHED THEN UPDATE 
SET O.pa_model_code=M.min_model_code
   ,O.pa_mktcode=M.min_mktcode;
TRUNCATE TABLE TF_CRAWLING_AP1_IM_10;
INSERT INTO TF_CRAWLING_AP1_IM_10
SELECT * FROM TF_CRAWLING_AP1_IM_9;
MERGE INTO TF_CRAWLING_AP1_IM_10 O
USING (
	SELECT min(pa_model_code) as pa_model_code, pa_mktcode, pa_brand_nm, pa_model_nm, COUNT(1) FROM 
		(SELECT distinct pa_model_code, pa_mktcode, pa_brand_nm, pa_model_nm FROM TF_CRAWLING_AP1_IM_10) v
	GROUP BY pa_mktcode, pa_brand_nm, pa_model_nm
	HAVING COUNT(1) > 1
	ORDER BY COUNT(1) DESC
) k
ON o.pa_mktcode = k.pa_mktcode 
AND o.pa_brand_nm = k.pa_brand_nm 
AND o.pa_model_nm = k.pa_model_nm
WHEN MATCHED THEN UPDATE 
SET pa_model_code = k.pa_model_code;
-- Etapa 9
TRUNCATE TABLE TF_CRAWLING_AP1_IM_11;
-- TO_TIMESTAMP ('2010-01-11 13:30:00', 'YYYY-MM-DD HH24:MI:SS') 
INSERT INTO TF_CRAWLING_AP1_IM_11
SELECT
	pa_model_code as model_code,
	UPPER(TRIM(INITCAP(pa_brand_nm))) brand_nm,
	pa_mktcode as mktcode,
	pa_mktname as mktname,
	pa_model_nm as model_nm,
	subsidiary,
	country,
	country_code,
	UPPER(TRIM(site_company_name)) site_company_name,
	site_nm,
	site_url,
	site_page,
	site_position,
	site_price_currency,
	CASE WHEN site_rating = '' THEN null else TO_DECIMAL(site_rating, 8,1 ) End site_rating , 
	CASE WHEN site_rating_amount = '' THEN null else TO_DECIMAL(site_rating_amount, 8,0 ) End site_rating_amount , 
	CASE WHEN site_rating_scale = '' THEN null else TO_DECIMAL(site_rating_scale, 8,0 ) End site_rating_scale ,
	TO_TIMESTAMP(refer_date, 'YYYY-MM-DD HH24:MI') refer_date,
	price_unit,
	ROUND(MAX(price_local_base),2) as price_local_base,
	ROUND(MAX(price_local_act),2) as price_local_act,
	ROUND(MAX(price_local_down),2) as price_local_down,
	ROUND(MAX(price_local_monthly),2) as price_local_monthly,
	ROUND(MAX(price_local_months),2) as price_local_months,
	'Y' as update_flg,
	current_timestamp
FROM (
	/*
		짝수
		1,2 일 경우 1,2을 추출하여 평균 도출
		1,2,3,4 일 경우 2,3을 추출하여 평균 도출
		1,2,3,4,5,6 일 경우 3,4을 추출하여 평균 도출
		SDSLA (a.duek): a clausula " flg='Y' " de cada Union (abaixo) foi comentada e o 2º bloco do UNION também foi comentado, pesquisar por : " 홀수 "
	*/
	--PRICE_LOCAL_BASE
	SELECT
		pa_model_code,
		pa_brand_nm,
		pa_mktcode,
		pa_mktname,
		pa_model_nm,
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
		--AVG(price_local_base) as price_local_base,
		AVG(TO_DECIMAL(TRIM(price_local_base), 8, 2)) as price_local_base,
		0 as price_local_act,
		0 as price_local_down,
		0 as price_local_monthly,
		0 as price_local_months
	FROM (
		SELECT
			CASE WHEN t_cnt/2 = base_row_num THEN 'Y' 
				WHEN t_cnt/2 + 1 = base_row_num THEN 'Y' 
			END as flg, 
			*
		FROM (
			SELECT 
				ROW_NUMBER() OVER (
					PARTITION BY a.pa_model_code,a.pa_brand_nm,a.pa_mktcode,a.pa_mktname,a.pa_model_nm,a.country,a.country_code
					,a.site_nm,a.subsidiary,a.country,a.country_code,a.site_company_name,a.site_nm,a.site_url,a.site_page
					,a.site_position,a.site_price_currency,a.site_rating,a.site_rating_amount,a.site_rating_scale
					,a.refer_date,a.price_unit ORDER BY price_local_base ASC
				) as base_row_num,
				b.t_cnt,
				a.*
			FROM
			(
				SELECT * FROM TF_CRAWLING_AP1_IM_10
				--WHERE price_local_base > 0 
			) a,					
			(
				SELECT 
					pa_model_code,
					pa_brand_nm,
					pa_mktcode,
					pa_mktname,
					pa_model_nm,		
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
					count(1) as t_cnt
				FROM TF_CRAWLING_AP1_IM_10
				--WHERE price_local_base > 0 
				GROUP BY pa_model_code, pa_brand_nm,pa_mktcode,pa_mktname,pa_model_nm
				,subsidiary,country,country_code,site_company_name,site_nm,site_url,site_page,site_position
				,site_price_currency,site_rating,site_rating_amount,site_rating_scale,refer_date,price_unit
				--HAVING COUNT(1) / 2 = 0
			) b
			WHERE  1 = 1
			AND a.pa_model_code = b.pa_model_code
			AND a.pa_brand_nm = b.pa_brand_nm
			AND a.pa_mktcode = b.pa_mktcode
			AND a.pa_mktname = b.pa_mktname
			AND a.pa_model_nm = b.pa_model_nm
			AND a.subsidiary = b.subsidiary
			AND a.country = b.country 
			AND a.country_code = b.country_code 
			AND a.site_company_name = b.site_company_name 
			AND a.site_nm = b.site_nm 
			AND a.site_url = b.site_url 
			AND a.site_page = b.site_page 
			AND a.site_position = b.site_position 
			AND a.site_price_currency = b.site_price_currency 
			AND a.site_rating = b.site_rating 
			AND a.site_rating_amount = b.site_rating_amount 
			AND a.site_rating_scale = b.site_rating_scale 
			AND a.refer_date = b.refer_date
			AND a.price_unit = b.price_unit
			ORDER BY b.t_cnt, a.pa_model_code, a.pa_brand_nm,a.pa_mktcode,a.pa_mktname,a.pa_model_nm
			,a.subsidiary,a.country,a.country_code,a.site_company_name,a.site_nm,a.site_url,a.site_page
			,a.site_position,a.site_price_currency,a.site_rating,a.site_rating_amount,a.site_rating_scale
			,a.refer_date,a.price_unit, base_row_num
		) g
	)  v
	WHERE 1=1
	--and flg='Y'
	GROUP BY pa_model_code, pa_brand_nm,pa_mktcode,pa_mktname,pa_model_nm
				,subsidiary,country,country_code,site_company_name,site_nm,site_url,site_page,site_position
				,site_price_currency,site_rating,site_rating_amount,site_rating_scale,refer_date,price_unit
	UNION ALL
	--PRICE_LOCAL_ACT
	SELECT
		pa_model_code,
		pa_brand_nm,
		pa_mktcode,
		pa_mktname,
		pa_model_nm,
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
		0 as price_local_base,
		--AVG(price_local_act) as price_local_act,
		AVG(TO_DECIMAL(TRIM(price_local_act), 8, 2)) as price_local_act,
		0 as price_local_down,
		0 as price_local_monthly,
		0 as price_local_months
	FROM (
		SELECT
			CASE WHEN t_cnt/2 = act_row_num THEN 'Y' 
				WHEN t_cnt/2 + 1 = act_row_num THEN 'Y' 
			END as flg, 
			*
		FROM (
			SELECT 
				ROW_NUMBER() OVER (
					PARTITION BY a.pa_model_code,a.pa_brand_nm,a.pa_mktcode,a.pa_mktname,a.pa_model_nm,a.country,a.country_code
					,a.site_nm,a.subsidiary,a.country,a.country_code,a.site_company_name,a.site_nm,a.site_url,a.site_page
					,a.site_position,a.site_price_currency,a.site_rating,a.site_rating_amount,a.site_rating_scale
					,a.refer_date,a.price_unit ORDER BY price_local_act ASC
				) as act_row_num,
				b.t_cnt,
				a.*
			FROM
			(
				SELECT * FROM TF_CRAWLING_AP1_IM_10
				--WHERE price_local_act > 0 
			) a,			
			(
				SELECT 
					pa_model_code,
					pa_brand_nm,
					pa_mktcode,
					pa_mktname,
					pa_model_nm,		
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
					count(1) as t_cnt
				FROM TF_CRAWLING_AP1_IM_10
				--WHERE price_local_act > 0 
				GROUP BY pa_model_code, pa_brand_nm,pa_mktcode,pa_mktname,pa_model_nm
				,subsidiary,country,country_code,site_company_name,site_nm,site_url,site_page,site_position
				,site_price_currency,site_rating,site_rating_amount,site_rating_scale,refer_date,price_unit
				----HAVING COUNT(1) / 2 = 0
			) b
			WHERE  1 = 1
			AND a.pa_model_code = b.pa_model_code
			AND a.pa_brand_nm = b.pa_brand_nm
			AND a.pa_mktcode = b.pa_mktcode
			AND a.pa_mktname = b.pa_mktname
			AND a.pa_model_nm = b.pa_model_nm
			AND a.subsidiary = b.subsidiary
			AND a.country = b.country 
			AND a.country_code = b.country_code 
			AND a.site_company_name = b.site_company_name 
			AND a.site_nm = b.site_nm 
			AND a.site_url = b.site_url 
			AND a.site_page = b.site_page 
			AND a.site_position = b.site_position 
			AND a.site_price_currency = b.site_price_currency 
			AND a.site_rating = b.site_rating 
			AND a.site_rating_amount = b.site_rating_amount 
			AND a.site_rating_scale = b.site_rating_scale 
			AND a.refer_date = b.refer_date
			AND a.price_unit = b.price_unit
			ORDER BY b.t_cnt, a.pa_model_code, a.pa_brand_nm,a.pa_mktcode,a.pa_mktname,a.pa_model_nm
			,a.subsidiary,a.country,a.country_code,a.site_company_name,a.site_nm,a.site_url,a.site_page
			,a.site_position,a.site_price_currency,a.site_rating,a.site_rating_amount,a.site_rating_scale
			,a.refer_date,a.price_unit, act_row_num
		) g
	)  v
	WHERE  1=1
	--and flg='Y'
	GROUP BY pa_model_code, pa_brand_nm,pa_mktcode,pa_mktname,pa_model_nm
				,subsidiary,country,country_code,site_company_name,site_nm,site_url,site_page,site_position
				,site_price_currency,site_rating,site_rating_amount,site_rating_scale,refer_date,price_unit
) s 
GROUP BY pa_model_code, pa_brand_nm,pa_mktcode,pa_mktname,pa_model_nm,
				subsidiary,country,country_code,site_company_name,site_nm,site_url,site_page,site_position
				,site_price_currency,site_rating,site_rating_amount,site_rating_scale,refer_date,price_unit
;
-- Etapa 10
TRUNCATE TABLE TF_CRAWLING_AP1_IM_12;
insert into TF_CRAWLING_AP1_IM_12
(
"MODEL_CODE",
"BRAND_NM",
"MKTCODE",
"MKTNAME",
"MODEL_NM",
"SUBSIDIARY",
"COUNTRY",
"COUNTRY_CODE",
"SITE_COMPANY_NAME",
"SITE_NM",
"SITE_URL",
"SITE_PAGE",
"SITE_POSITION",
"SITE_PRICE_CURRENCY",
"SITE_RATING",
"SITE_RATING_AMOUNT",
"SITE_RATING_SCALE",
"REFER_DATE",
"PRICE_UNIT",
"PRICE_LOCAL_BASE",
"PRICE_LOCAL_ACT",
"PRICE_LOCAL_DOWN",
"PRICE_LOCAL_MONTHLY",
"PRICE_LOCAL_MONTHS",
"UPDATE_FLG",
"PROCESS_DATETIME",
"FROM_CURRENCY",
"TO_CURRENCY",
"VALID_FROM",
"EXCHANGE_RATE",
"MKT_SEGMENT",
"PRICE_UNIT_USD",
"PRICE_LOCAL_BASE_USD",
"PRICE_LOCAL_ACT_USD",
"PRICE_LOCAL_DOWN_USD",
"PRICE_LOCAL_MONTHLY_USD",
"PRICE_LOCAL_MONTHS_USD",
"VENDOR",
"MEDIAN_UNIT_PRICE_USD",
"REFER_WEEK",
"REFER_WEEK_T",
"REFER_YEAR"
)
select 
VW_PRICE."MODEL_CODE",
VW_PRICE."BRAND_NM",
VW_PRICE."MKTCODE",
VW_PRICE."MKTNAME",
VW_PRICE."MODEL_NM",
VW_PRICE."SUBSIDIARY",
VW_PRICE."COUNTRY",
VW_PRICE."COUNTRY_CODE",
VW_PRICE."SITE_COMPANY_NAME",
VW_PRICE."SITE_NM",
VW_PRICE."SITE_URL",
VW_PRICE."SITE_PAGE",
VW_PRICE."SITE_POSITION",
VW_PRICE."SITE_PRICE_CURRENCY",
VW_PRICE."SITE_RATING",
VW_PRICE."SITE_RATING_AMOUNT",
VW_PRICE."SITE_RATING_SCALE",
VW_PRICE."REFER_DATE",
VW_PRICE."PRICE_UNIT",
VW_PRICE."PRICE_LOCAL_BASE",
VW_PRICE."PRICE_LOCAL_ACT",
VW_PRICE."PRICE_LOCAL_DOWN",
VW_PRICE."PRICE_LOCAL_MONTHLY",
VW_PRICE."PRICE_LOCAL_MONTHS",
VW_PRICE."UPDATE_FLG",
VW_PRICE."PROCESS_DATETIME",
VW_PRICE."FROM_CURRENCY",
VW_PRICE."TO_CURRENCY",
VW_PRICE."VALID_FROM",
VW_PRICE."EXCHANGE_RATE",
VW_PRICE."MKT_SEGMENT",
VW_PRICE."PRICE_UNIT_USD",
VW_PRICE."PRICE_LOCAL_BASE_USD",
VW_PRICE."PRICE_LOCAL_ACT_USD",
VW_PRICE."PRICE_LOCAL_DOWN_USD",
VW_PRICE."PRICE_LOCAL_MONTHLY_USD",
VW_PRICE."PRICE_LOCAL_MONTHS_USD",
UPPER(VENDOR.VENDOR),
MEDIAN.MEDIAN,
NULL REFER_WEEK,
NULL REFER_WEEK_T,
NULL REFER_YEAR
FROM VW_CRAWLING_ONLINE_PRICE VW_PRICE
left join (
select count(1), PROD_HREF, VENDOR
from "OW_LAO"."ODS_CRAWLING_AP1_IM_PRODUCT_DETAIL"
where VENDOR !='' and VENDOR is not null 
group by PROD_HREF, VENDOR 
having count(1) =1
)VENDOR on VENDOR.PROD_HREF=VW_PRICE.SITE_URL
left join 
(
select round(median(PRICE_UNIT_USD),2) as "MEDIAN",COUNTRY,MKTNAME
from "OW_LAO"."VW_CRAWLING_ONLINE_PRICE" 
group by COUNTRY,MKTNAME
) MEDIAN on MEDIAN.COUNTRY= VW_PRICE."COUNTRY" and MEDIAN.MKTNAME=VW_PRICE."MKTNAME";
--################################CARGA DAS FATOS################################
--################################
DELETE FROM FT_CRAWLING_ONLINE_PRICE_DISPLAY_SHARE
WHERE 1=1
AND to_char("REFER_DATE", 'YYYY-MM-DD')  BETWEEN to_char(add_days(CURRENT_DATE,-20), 'YYYY-MM-DD') and  to_char(CURRENT_DATE, 'YYYY-MM-DD');
INSERT INTO FT_CRAWLING_ONLINE_PRICE_DISPLAY_SHARE
SELECT *
, NULL REFER_WEEK
, NULL REFER_WEEK_T
, NULL REFER_YEAR
FROM VW_CRAWLING_ONLINE_PRICE_DISPLAY_SHARE;
UPDATE OW_LAO.FT_CRAWLING_ONLINE_PRICE_DISPLAY_SHARE F
SET
REFER_WEEK = (SELECT DISTINCT YYYYWW FROM OW_MD.DIM_CALENDAR D WHERE to_char(F.REFER_DATE,'YYYY-MM-DD') = to_char(D.YYYYMMDD,'YYYY-MM-DD'))
, REFER_WEEK_T = ( SELECT DISTINCT 'W' || RIGHT(YYYYWW,2) FROM OW_MD.DIM_CALENDAR D WHERE to_char(F.REFER_DATE,'YYYY-MM-DD') = to_char(D.YYYYMMDD,'YYYY-MM-DD'))
, REFER_YEAR = ( SELECT DISTINCT  YYYY FROM OW_MD.DIM_CALENDAR D WHERE to_char(F.REFER_DATE,'YYYY-MM-DD') = to_char(D.YYYYMMDD,'YYYY-MM-DD'))
WHERE 
REFER_WEEK is null;
--################################
/*
DELETE FROM FT_CRAWLING_ONLINE_PRICE
WHERE 1=1
AND to_char("REFER_DATE", 'YYYY-MM-DD')  BETWEEN to_char(add_days(CURRENT_DATE,-15), 'YYYY-MM-DD') and  to_char(CURRENT_DATE, 'YYYY-MM-DD');
INSERT INTO FT_CRAWLING_ONLINE_PRICE
SELECT * FROM TF_CRAWLING_AP1_IM_11;
*/
--################################
delete FROM FT_CRAWLING_ONLINE_PRICE_SEGMENT
WHERE 1=1
AND to_char("REFER_DATE", 'YYYY-MM-DD')  BETWEEN to_char(add_days(CURRENT_DATE,-20), 'YYYY-MM-DD') and  to_char(CURRENT_DATE, 'YYYY-MM-DD');
--AND "MKTNAME" IS NOT NULL ;
INSERT INTO FT_CRAWLING_ONLINE_PRICE_SEGMENT
SELECT 
"MODEL_CODE",
"BRAND_NM",
"MKTCODE",
"MKTNAME",
"MODEL_NM",
"SUBSIDIARY",
"COUNTRY",
"COUNTRY_CODE",
"SITE_COMPANY_NAME",
"SITE_NM",
"SITE_URL",
"SITE_PAGE",
"SITE_POSITION",
"SITE_PRICE_CURRENCY",
"SITE_RATING",
"SITE_RATING_AMOUNT",
"SITE_RATING_SCALE",
"REFER_DATE",
"PRICE_UNIT",
"PRICE_LOCAL_BASE",
"PRICE_LOCAL_ACT",
"PRICE_LOCAL_DOWN",
"PRICE_LOCAL_MONTHLY",
"PRICE_LOCAL_MONTHS",
"UPDATE_FLG",
"PROCESS_DATETIME",
"FROM_CURRENCY",
"TO_CURRENCY",
"VALID_FROM",
"EXCHANGE_RATE",
"MKT_SEGMENT",
"PRICE_UNIT_USD",
"PRICE_LOCAL_BASE_USD",
"PRICE_LOCAL_ACT_USD",
"PRICE_LOCAL_DOWN_USD",
"PRICE_LOCAL_MONTHLY_USD",
"PRICE_LOCAL_MONTHS_USD",
"VENDOR",
"MEDIAN_UNIT_PRICE_USD",
"REFER_WEEK",
"REFER_WEEK_T",
"REFER_YEAR",
NULL AS "MODEL_DESC",
0 AS "FLAG_MAP_MKTNAME"
 FROM TF_CRAWLING_AP1_IM_12;
UPDATE OW_LAO.FT_CRAWLING_ONLINE_PRICE_SEGMENT F
SET
REFER_WEEK = (SELECT DISTINCT YYYYWW FROM OW_MD.DIM_CALENDAR D WHERE to_char(F.REFER_DATE,'YYYY-MM-DD') = to_char(D.YYYYMMDD,'YYYY-MM-DD'))
, REFER_WEEK_T = ( SELECT DISTINCT 'W' || RIGHT(YYYYWW,2) FROM OW_MD.DIM_CALENDAR D WHERE to_char(F.REFER_DATE,'YYYY-MM-DD') = to_char(D.YYYYMMDD,'YYYY-MM-DD'))
, REFER_YEAR = ( SELECT DISTINCT  YYYY FROM OW_MD.DIM_CALENDAR D WHERE to_char(F.REFER_DATE,'YYYY-MM-DD') = to_char(D.YYYYMMDD,'YYYY-MM-DD'))
WHERE 
REFER_WEEK is null;
/*Utilizando MODEL_NM e BRAND_NM que foram mapeados anteriormente para mapear casos com MKTNAME null*/
	 UPDATE OW_LAO.FT_CRAWLING_ONLINE_PRICE_SEGMENT O 
SET O.MKTNAME = T.MKTNAME,
    O.FLAG_MAP_MKTNAME = 1
FROM OW_LAO.FT_CRAWLING_ONLINE_PRICE_SEGMENT  O 
INNER JOIN 
 ( SELECT DISTINCT 
	     MODEL_NM,
		 BRAND_NM,
		 MKTNAME 
		FROM "OW_LAO"."FT_CRAWLING_ONLINE_PRICE_SEGMENT" 
		LEFT JOIN "OW_LAO"."ODS_CRAWLING_AP1_IM_PRODUCT_DETAIL" ON UPPER(MODEL_NM)= UPPER(MODEL) 
		WHERE MKTNAME IS NOT NULL ORDER BY 1 DESC) T 
ON UPPER(O.MODEL_NM) = UPPER(T.MODEL_NM) AND UPPER(O.BRAND_NM) = UPPER(T.BRAND_NM) 
WHERE O.MKTNAME IS NULL;  
/*Tabela auxiliar para cruzar BRAND_NM e LIKE entre MODEL_DESC */
 TRUNCATE TABLE OW_LAO.TF_AUX_IM_CRAWLING_ONLINE_PRICE_SEGMENT_1; 
INSERT INTO OW_LAO.TF_AUX_IM_CRAWLING_ONLINE_PRICE_SEGMENT_1  (
SELECT BRAND_NM_ORIGEM, MODEL_DESC_ORIGEM, MKTNAME_ORIGEM, BRAND_NM, MKTNAME, ROW_NUM FROM (
		SELECT A.BRAND_NM AS BRAND_NM_ORIGEM, A.MODEL_DESC AS MODEL_DESC_ORIGEM, A.MKTNAME AS MKTNAME_ORIGEM, B.BRAND_NM, B.MKTNAME 
		, ROW_NUMBER() OVER (PARTITION BY A.BRAND_NM, A.MODEL_DESC, A.MKTNAME, B.BRAND_NM ORDER BY LENGTH(B.MKTNAME) DESC) as ROW_NUM
		FROM 
			(SELECT DISTINCT BRAND_NM, MODEL_DESC, MKTNAME
				FROM OW_LAO."FT_CRAWLING_ONLINE_PRICE_SEGMENT"       -- SUBSTITUIR POR FT_CRAWLING_ONLINE_PRICE_SEGMENT
			WHERE MKTNAME IS NULL AND (UPPER(BRAND_NM) IS NOT NULL AND UPPER(BRAND_NM) <>'')
				AND (UPPER(MODEL_DESC) IS NOT NULL AND UPPER(MODEL_DESC) <>'')
				AND BRAND_NM  IN (SELECT DISTINCT BRAND_NM FROM OW_LAO.MP_GSMARENA_MERGE_DATA_MAPPING_KEY)
			order by BRAND_NM ASC, MODEL_DESC DESC, MKTNAME DESC) A
		LEFT JOIN 
			(SELECT DISTINCT BRAND_NM, MKTNAME 
				FROM OW_LAO.MP_GSMARENA_MERGE_DATA_MAPPING_KEY 
			WHERE (UPPER(BRAND_NM) IS NOT NULL AND UPPER(BRAND_NM) <>'')
			order by BRAND_NM ASC, MKTNAME DESC) B 	
	  ON UPPER(A.BRAND_NM) = UPPER(B.BRAND_NM)   AND UPPER(A.MODEL_DESC) LIKE '%'||UPPER(B.MKTNAME)||'%'
ORDER BY  BRAND_NM_ORIGEM ASC, A.MODEL_DESC DESC, MKTNAME DESC ) C WHERE C.ROW_NUM = 1 AND C.MKTNAME IS NOT NULL and LENGTH(C.MKTNAME)>2
--ORDER BY BRAND_NM_ORIGEM, MODEL_DESC, MKTNAME_ORIGEM, BRAND_NM,LENGTH(MKTNAME)DESC
);
UPDATE OW_LAO."FT_CRAWLING_ONLINE_PRICE_SEGMENT" O       -- SUBSTITUIR POR FT_CRAWLING_ONLINE_PRICE_SEGMENT
	SET O.MKTNAME = T.MKTNAME,
    	O.FLAG_MAP_MKTNAME = 1
FROM OW_LAO.FT_CRAWLING_ONLINE_PRICE_SEGMENT  O       -- SUBSTITUIR POR FT_CRAWLING_ONLINE_PRICE_SEGMENT
INNER JOIN 
 (SELECT BRAND_NM_ORIGEM, MODEL_DESC_ORIGEM, MKTNAME_ORIGEM, BRAND_NM, MKTNAME, ROW_NUM
		FROM OW_LAO.TF_AUX_IM_CRAWLING_ONLINE_PRICE_SEGMENT_1) T     -- SUBSTITUIR POR TF_AUX_IM_CRAWLING_ONLINE_PRICE_SEGMENT_1
     ON UPPER(O.BRAND_NM)   = UPPER(T.BRAND_NM_ORIGEM) 
   AND  UPPER(O.MODEL_DESC) = UPPER(T.MODEL_DESC_ORIGEM)
WHERE O.MKTNAME IS NULL;  
/*Tabela auxiliar para cruzar BRAND_NM e LIKE entre MODEL_NM */
TRUNCATE TABLE OW_LAO.TF_AUX_IM_CRAWLING_ONLINE_PRICE_SEGMENT_2;
INSERT INTO OW_LAO.TF_AUX_IM_CRAWLING_ONLINE_PRICE_SEGMENT_2  (
 SELECT BRAND_NM_ORIGEM, MODEL_NM_ORIGEM, MKTNAME_ORIGEM, BRAND_NM, MKTNAME, ROW_NUM FROM (
		SELECT A.BRAND_NM AS BRAND_NM_ORIGEM, A.MODEL_NM as MODEL_NM_ORIGEM, A.MKTNAME AS MKTNAME_ORIGEM, B.BRAND_NM, B.MKTNAME 
		, ROW_NUMBER() OVER (PARTITION BY A.BRAND_NM, A.MODEL_NM, A.MKTNAME, B.BRAND_NM ORDER BY LENGTH(B.MKTNAME) DESC) as ROW_NUM
		FROM 
			(SELECT DISTINCT BRAND_NM, MODEL_NM, MKTNAME
				FROM OW_LAO."FT_CRAWLING_ONLINE_PRICE_SEGMENT"       -- SUBSTITUIR POR FT_CRAWLING_ONLINE_PRICE_SEGMENT
			WHERE MKTNAME IS NULL AND (UPPER(BRAND_NM) IS NOT NULL AND UPPER(BRAND_NM) <>'')
				AND (UPPER(MODEL_NM) IS NOT NULL AND UPPER(MODEL_NM) <>'')
				
				AND BRAND_NM  IN (SELECT DISTINCT BRAND_NM FROM OW_LAO.MP_GSMARENA_MERGE_DATA_MAPPING_KEY)
			order by BRAND_NM ASC, MODEL_NM DESC, MKTNAME DESC) A
		LEFT JOIN 
			(SELECT DISTINCT BRAND_NM, MKTNAME 
				FROM OW_LAO.MP_GSMARENA_MERGE_DATA_MAPPING_KEY 
			WHERE (UPPER(BRAND_NM) IS NOT NULL AND UPPER(BRAND_NM) <>'')
			order by BRAND_NM ASC, MKTNAME DESC) B 		
	  ON UPPER(A.BRAND_NM) = UPPER(B.BRAND_NM)   AND REPLACE(REPLACE(UPPER(A.MODEL_NM),'-',' '),'%',' ') LIKE '%'||UPPER(B.MKTNAME)||'%'
ORDER BY  BRAND_NM_ORIGEM ASC, A.MODEL_NM DESC, MKTNAME DESC )  C WHERE C.ROW_NUM = 1 AND C.MKTNAME IS NOT NULL and LENGTH(C.MKTNAME)>2
--ORDER BY BRAND_NM_ORIGEM, MODEL_NM_ORIGEM, MKTNAME_ORIGEM, BRAND_NM,LENGTH(MKTNAME)DESC
);
 UPDATE OW_LAO."FT_CRAWLING_ONLINE_PRICE_SEGMENT" O       -- SUBSTITUIR POR FT_CRAWLING_ONLINE_PRICE_SEGMENT 
SET O.MKTNAME = T.MKTNAME,
	O.FLAG_MAP_MKTNAME = 1
FROM OW_LAO.FT_CRAWLING_ONLINE_PRICE_SEGMENT  O       -- SUBSTITUIR POR FT_CRAWLING_ONLINE_PRICE_SEGMENT
INNER JOIN 
 (SELECT BRAND_NM_ORIGEM, MODEL_NM_ORIGEM, MKTNAME_ORIGEM, BRAND_NM, MKTNAME, ROW_NUM
FROM OW_LAO.TF_AUX_IM_CRAWLING_ONLINE_PRICE_SEGMENT_2) T     -- SUBSTITUIR POR TF_AUX_IM_CRAWLING_ONLINE_PRICE_SEGMENT_2
     ON UPPER(O.BRAND_NM)   = UPPER(T.BRAND_NM_ORIGEM) 
   AND  UPPER(O.MODEL_NM)   = UPPER(T.MODEL_NM_ORIGEM)
WHERE O.MKTNAME IS NULL; 
--################################
--Carga dos dados da DisplayShare  na Segment - Chamado SDSMS-2112
/*
delete from 
"OW_LAO"."FT_CRAWLING_ONLINE_PRICE_SEGMENT"
where MKTNAME is null 
AND  
to_date(to_char("REFER_DATE", 'YYYY-MM-DD'), 'YYYY-MM-DD')  = to_date(to_char(add_days(CURRENT_DATE,-1), 'YYYY-MM-DD') , 'YYYY-MM-DD');
insert into   "OW_LAO"."FT_CRAWLING_ONLINE_PRICE_SEGMENT" (
"MODEL_CODE",
"BRAND_NM",
"MKTCODE",
"MKTNAME",
"MODEL_NM",
"SUBSIDIARY",
"COUNTRY",
"COUNTRY_CODE",
"SITE_COMPANY_NAME",
"SITE_NM",
"SITE_URL",
"SITE_PAGE",
"SITE_POSITION",
"SITE_PRICE_CURRENCY",
"SITE_RATING",
"SITE_RATING_AMOUNT",
"SITE_RATING_SCALE",
"REFER_DATE",
"PRICE_UNIT",
"PRICE_LOCAL_BASE",
"PRICE_LOCAL_ACT",
"PRICE_LOCAL_DOWN",
"PRICE_LOCAL_MONTHLY",
"PRICE_LOCAL_MONTHS",
"UPDATE_FLG",
"PROCESS_DATETIME",
"FROM_CURRENCY",
"TO_CURRENCY",
"VALID_FROM",
"EXCHANGE_RATE",
"MKT_SEGMENT",
"PRICE_UNIT_USD",
"PRICE_LOCAL_BASE_USD",
"PRICE_LOCAL_ACT_USD",
"PRICE_LOCAL_DOWN_USD",
"PRICE_LOCAL_MONTHLY_USD",
"PRICE_LOCAL_MONTHS_USD",
"VENDOR",
"MEDIAN_UNIT_PRICE_USD",
"REFER_WEEK",
"REFER_WEEK_T",
"REFER_YEAR")
select 
null as "MODEL_CODE",
FT_SHARE."BRAND_NM",
null as "MKTCODE",
null as "MKTNAME",
FT_SHARE."MODEL_NM",
FT_SHARE."SUBSIDIARY",
FT_SHARE."COUNTRY",
FT_SHARE."COUNTRY_CODE",
FT_SHARE."SITE_COMPANY_NAME",
FT_SHARE."SITE_NM",
FT_SHARE."SITE_URL",
FT_SHARE."SITE_PAGE",
FT_SHARE."SITE_POSITION",
FT_SHARE."SITE_PRICE_CURRENCY",
SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM( REPLACE(FT_SHARE."SITE_RATING", ',','.'))) FROM 1 OCCURRENCE 1) as "SITE_RATING",
SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM( REPLACE(FT_SHARE."SITE_RATING_AMOUNT", ',','.'))) FROM 1 OCCURRENCE 1) as  "SITE_RATING_AMOUNT",
SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM( REPLACE(FT_SHARE."SITE_RATING_SCALE", ',','.'))) FROM 1 OCCURRENCE 1) as  "SITE_RATING_SCALE",
FT_SHARE."REFER_DATE",
FT_SHARE."PRICE_UNIT",
FT_SHARE."PRICE_LOCAL_BASE",
FT_SHARE."PRICE_LOCAL_ACT",
null as "PRICE_LOCAL_DOWN",
null as "PRICE_LOCAL_MONTHLY",
null as "PRICE_LOCAL_MONTHS",
null as "UPDATE_FLG",
FT_SHARE."PROCESS_DATETIME",
FT_SHARE."FROM_CURRENCY",
FT_SHARE."TO_CURRENCY",
FT_SHARE."VALID_FROM",
FT_SHARE."EXCHANGE_RATE",
FT_SHARE."MKT_SEGMENT",
FT_SHARE."PRICE_UNIT_USD",
FT_SHARE."PRICE_LOCAL_BASE_USD",
FT_SHARE."PRICE_LOCAL_ACT_USD",
null as "PRICE_LOCAL_DOWN_USD",
null as "PRICE_LOCAL_MONTHLY_USD",
null as "PRICE_LOCAL_MONTHS_USD",
null as "VENDOR",
null as"MEDIAN_UNIT_PRICE_USD",
 "REFER_WEEK",
"REFER_WEEK_T",
"REFER_YEAR"
 from "OW_LAO"."FT_CRAWLING_ONLINE_PRICE_DISPLAY_SHARE" FT_SHARE
where to_date(to_char(FT_SHARE."REFER_DATE", 'YYYY-MM-DD'), 'YYYY-MM-DD')  = to_date(to_char(add_days(CURRENT_DATE,-1), 'YYYY-MM-DD') , 'YYYY-MM-DD')
and SITE_URL not in ( 
select SITE_URL
from "OW_LAO"."FT_CRAWLING_ONLINE_PRICE_SEGMENT"
where 
to_date(to_char("REFER_DATE", 'YYYY-MM-DD'), 'YYYY-MM-DD')  = to_date(to_char(add_days(CURRENT_DATE,-1), 'YYYY-MM-DD') , 'YYYY-MM-DD')
)
;
*/
--################################
 
 
 
/*
01/10/2020
Update da Base SEgment para carregar o Model Desc -  Chamado SDSMS-2112*/
/*
UPDATE   "OW_LAO"."FT_CRAWLING_ONLINE_PRICE_SEGMENT" O
 SET
O."MODEL_DESC" =T."DESC" 
from 
 "OW_LAO"."FT_CRAWLING_ONLINE_PRICE_SEGMENT"  O 
inner join 
 (select "DESC",PROD_HREF from "OW_LAO"."ODS_CRAWLING_AP1_IM_PRODUCT_DETAIL")T
 ON TRIM(O.SITE_URL) = TRIM(T.PROD_HREF)
 where 
 to_char("REFER_DATE", 'YYYY-MM-DD')  BETWEEN to_char(add_days(CURRENT_DATE,-15), 'YYYY-MM-DD') and  to_char(CURRENT_DATE, 'YYYY-MM-DD')
;
 
 */
 
--################################
--Comentado por conta do Chamado SDSMS-707
/*DELETE FROM FT_CRAWLING_ONLINE_PRICE_VS_COMPETITOR
WHERE 1=1
AND to_char("REFER_DATE", 'YYYY-MM-DD')  BETWEEN to_char(add_days(CURRENT_DATE,-15), 'YYYY-MM-DD') and  to_char(CURRENT_DATE, 'YYYY-MM-DD');
insert into  "OW_LAO"."FT_CRAWLING_ONLINE_PRICE_VS_COMPETITOR"
(
"SUBSIDIARY",
"COUNTRY_CODE",
"BRAND_NM",
"MKTNAME",
"MODEL_NM",
"SITE_COMPANY_NAME",
"SITE_RATING",
"SITE_RATING_AMOUNT",
"SITE_RATING_SCALE",
"SITE_PAGE",
"SITE_POSITION",
"PRICE_UNIT_USD",
"PRICE_LOCAL_BASE_USD",
"PRICE_LOCAL_ACT_USD",
"PRICE_LOCAL_DOWN_USD",
"PRICE_LOCAL_MONTHLY_USD",
"PRICE_LOCAL_MONTHS_USD",
"MKT_SEGMENT",
"COMPETITOR_BRAND_NM",
"COMPETITOR_MKTNAME",
"COMPETITOR_MODEL_NM",
"COMPETITOR_SITE_RATING",
"COMPETITOR_RATING_AMOUNT",
"COMPETITOR_SITE_PAGE",
"COMPETITOR_SITE_POSITION",
"COMPETITOR_PRICE_UNIT_USD",
"COMPETITOR_PRICE_LOCAL_BASE_USD",
"COMPETITOR_PRICE_LOCAL_ACT_USD",
"COMPETITOR_PRICE_LOCAL_DOWN_USD",
"COMPETITOR_PRICE_LOCAL_MONTHLY_USD",
"COMPETITOR_PRICE_LOCAL_MONTHS_USD",
"REFER_DATE",
"PRICE_LOCAL_BASE",
"PRICE_LOCAL_ACT",
"PRICE_LOCAL_DOWN",
"PRICE_LOCAL_MONTHLY",
"PRICE_LOCAL_MONTHS",
"SITE_URL",
"COMPETITOR_PRICE_LOCAL_BASE",
"COMPETITOR_PRICE_LOCAL_ACT",
"COMPETITOR_PRICE_LOCAL_DOWN",
"COMPETITOR_PRICE_LOCAL_MONTHLY",
"COMPETITOR_PRICE_LOCAL_MONTHS",
"COMPETITOR_SITE_URL",
"PROCESS_DATETIME",
"VENDOR",
"COMPETITOR_VENDOR"
)
select 
"SUBSIDIARY",
"COUNTRY_CODE",
"BRAND_NM",
"MKTNAME",
"MODEL_NM",
"SITE_COMPANY_NAME",
"SITE_RATING",
"SITE_RATING_AMOUNT",
"SITE_RATING_SCALE",
"SITE_PAGE",
"SITE_POSITION",
"PRICE_UNIT_USD",
"PRICE_LOCAL_BASE_USD",
"PRICE_LOCAL_ACT_USD",
"PRICE_LOCAL_DOWN_USD",
"PRICE_LOCAL_MONTHLY_USD",
"PRICE_LOCAL_MONTHS_USD",
"MKT_SEGMENT",
"COMPETITOR_BRAND_NM",
"COMPETITOR_MKTNAME",
"COMPETITOR_MODEL_NM",
"COMPETITOR_SITE_RATING",
"COMPETITOR_RATING_AMOUNT",
"COMPETITOR_SITE_PAGE",
"COMPETITOR_SITE_POSITION",
"COMPETITOR_PRICE_UNIT_USD",
"COMPETITOR_PRICE_LOCAL_BASE_USD",
"COMPETITOR_PRICE_LOCAL_ACT_USD",
"COMPETITOR_PRICE_LOCAL_DOWN_USD",
"COMPETITOR_PRICE_LOCAL_MONTHLY_USD",
"COMPETITOR_PRICE_LOCAL_MONTHS_USD",
"REFER_DATE",
"PRICE_LOCAL_BASE",
"PRICE_LOCAL_ACT",
"PRICE_LOCAL_DOWN",
"PRICE_LOCAL_MONTHLY",
"PRICE_LOCAL_MONTHS",
"SITE_URL",
"COMPETITOR_PRICE_LOCAL_BASE",
"COMPETITOR_PRICE_LOCAL_ACT",
"COMPETITOR_PRICE_LOCAL_DOWN",
"COMPETITOR_PRICE_LOCAL_MONTHLY",
"COMPETITOR_PRICE_LOCAL_MONTHS",
"COMPETITOR_SITE_URL",
"PROCESS_DATETIME",
"VENDOR",
"COMPETITOR_VENDOR"
 from "OW_LAO"."VW_CRAWLING_ONLINE_PRICE_VS_COMPETITOR" ;
*/
END;