CREATE  PROCEDURE PROC_CRAWLING_AP1_IM_PT2_HIST
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
	UNION ALL
	--PRICE_LOCAL_DOWN
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
		0 as price_local_act,
		--AVG(price_local_down) as price_local_down,	
		AVG(TO_DECIMAL(TRIM(price_local_down), 8, 2)) as price_local_down,
		0 as price_local_monthly,
		0 as price_local_months
	FROM (
		SELECT
			CASE WHEN t_cnt/2 = down_row_num THEN 'Y' 
				WHEN t_cnt/2 + 1 = down_row_num THEN 'Y' 
			END as flg, 
			*
		FROM (
			SELECT 
				ROW_NUMBER() OVER (
					PARTITION BY a.pa_model_code,a.pa_brand_nm,a.pa_mktcode,a.pa_mktname,a.pa_model_nm,a.country,a.country_code
					,a.site_nm,a.subsidiary,a.country,a.country_code,a.site_company_name,a.site_nm,a.site_url,a.site_page
					,a.site_position,a.site_price_currency,a.site_rating,a.site_rating_amount,a.site_rating_scale
					,a.refer_date,a.price_unit ORDER BY price_local_down ASC
				) as down_row_num,
				b.t_cnt,
				a.*
			FROM
			(
				SELECT * FROM TF_CRAWLING_AP1_IM_10
				--WHERE price_local_down > 0 
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
				--WHERE price_local_down > 0 
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
			,a.refer_date,a.price_unit, down_row_num
		) g
	)  v
	WHERE  1=1
	--and flg='Y'
	GROUP BY pa_model_code, pa_brand_nm,pa_mktcode,pa_mktname,pa_model_nm
				,subsidiary,country,country_code,site_company_name,site_nm,site_url,site_page,site_position
				,site_price_currency,site_rating,site_rating_amount,site_rating_scale,refer_date,price_unit
	UNION ALL
	--PRICE_LOCAL_MONTHLY
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
		0 as price_local_act,
		0 as price_local_down,
		--AVG(price_local_monthly) as price_local_monthly,
		AVG(TO_DECIMAL(TRIM(price_local_monthly), 8, 2)) as price_local_monthly,	
		0 as price_local_months
	FROM (
		SELECT
			CASE WHEN t_cnt/2 = monthly_row_num THEN 'Y' 
				WHEN t_cnt/2 + 1 = monthly_row_num THEN 'Y' 
			END as flg, 
			*
		FROM (
			SELECT 
				ROW_NUMBER() OVER (
					PARTITION BY a.pa_model_code,a.pa_brand_nm,a.pa_mktcode,a.pa_mktname,a.pa_model_nm,a.country,a.country_code
					,a.site_nm,a.subsidiary,a.country,a.country_code,a.site_company_name,a.site_nm,a.site_url,a.site_page
					,a.site_position,a.site_price_currency,a.site_rating,a.site_rating_amount,a.site_rating_scale
					,a.refer_date,a.price_unit ORDER BY price_local_monthly ASC
				) as monthly_row_num,
				b.t_cnt,
				a.*
			FROM 
			(
				SELECT * FROM TF_CRAWLING_AP1_IM_10
				--WHERE price_local_monthly > 0 
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
				--WHERE price_local_monthly > 0 
				GROUP BY pa_model_code, pa_brand_nm,pa_mktcode,pa_mktname,pa_model_nm
				,subsidiary,country,country_code,site_company_name,site_nm,site_url,site_page,site_position
				,site_price_currency,site_rating,site_rating_amount,site_rating_scale,refer_date,price_unit
				--HAVING COUNT(1) / 2 = 0
				--ORDER BY count(1) desc
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
			,a.refer_date,a.price_unit, monthly_row_num
		) g
	)  v
	WHERE  1=1
	--and flg='Y'
	GROUP BY pa_model_code, pa_brand_nm,pa_mktcode,pa_mktname,pa_model_nm
				,subsidiary,country,country_code,site_company_name,site_nm,site_url,site_page,site_position
				,site_price_currency,site_rating,site_rating_amount,site_rating_scale,refer_date,price_unit
	UNION ALL
	--PRICE_LOCAL_MONTHS
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
		0 as price_local_act,
		0 as price_local_down,
		0 as price_local_monthly,
		--AVG(price_local_months) as price_local_months
		AVG(TO_DECIMAL(TRIM(price_local_months), 8, 2)) as price_local_months
	FROM (
		SELECT
			CASE WHEN t_cnt/2 = months_row_num THEN 'Y' 
				WHEN t_cnt/2 + 1 = months_row_num THEN 'Y' 
			END as flg, 
			*
		FROM (
			SELECT 
				ROW_NUMBER() OVER (
					PARTITION BY a.pa_model_code,a.pa_brand_nm,a.pa_mktcode,a.pa_mktname,a.pa_model_nm,a.country,a.country_code
					,a.site_nm,a.subsidiary,a.country,a.country_code,a.site_company_name,a.site_nm,a.site_url,a.site_page
					,a.site_position,a.site_price_currency,a.site_rating,a.site_rating_amount,a.site_rating_scale
					,a.refer_date,a.price_unit ORDER BY price_local_months ASC
				) as months_row_num,
				b.t_cnt,
				a.*
			FROM
			(
				SELECT * FROM TF_CRAWLING_AP1_IM_10
				--WHERE price_local_months > 0 
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
				-- WHERE price_local_months > 0 
				GROUP BY pa_model_code, pa_brand_nm,pa_mktcode,pa_mktname,pa_model_nm
				,subsidiary,country,country_code,site_company_name,site_nm,site_url,site_page,site_position
				,site_price_currency,site_rating,site_rating_amount,site_rating_scale,refer_date,price_unit
				--HAVING COUNT(1) / 2 = 0
				--ORDER BY count(1) desc
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
			,a.refer_date,a.price_unit, months_row_num
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
--################################
DELETE FROM FT_CRAWLING_ONLINE_PRICE_DISPLAY_SHARE
WHERE 1=1
AND to_char("REFER_DATE", 'YYYY-MM-DD')    BETWEEN to_char(add_days(CURRENT_DATE,-365), 'YYYY-MM-DD') and to_char(add_days(CURRENT_DATE,-16), 'YYYY-MM-DD');
INSERT INTO FT_CRAWLING_ONLINE_PRICE_DISPLAY_SHARE
SELECT * FROM VW_CRAWLING_ONLINE_PRICE_DISPLAY_SHARE;
--################################
DELETE FROM FT_CRAWLING_ONLINE_PRICE
WHERE 1=1
AND to_char("REFER_DATE", 'YYYY-MM-DD')    BETWEEN to_char(add_days(CURRENT_DATE,-365), 'YYYY-MM-DD') and to_char(add_days(CURRENT_DATE,-16), 'YYYY-MM-DD');
INSERT INTO FT_CRAWLING_ONLINE_PRICE
SELECT * FROM TF_CRAWLING_AP1_IM_11;
--################################
DELETE FROM FT_CRAWLING_ONLINE_PRICE_SEGMENT
WHERE 1=1
AND to_char("REFER_DATE", 'YYYY-MM-DD')   BETWEEN to_char(add_days(CURRENT_DATE,-365), 'YYYY-MM-DD') and to_char(add_days(CURRENT_DATE,-16), 'YYYY-MM-DD');
INSERT INTO FT_CRAWLING_ONLINE_PRICE_SEGMENT
SELECT * FROM VW_CRAWLING_ONLINE_PRICE;
--################################
DELETE FROM FT_CRAWLING_ONLINE_PRICE_VS_COMPETITOR
WHERE 1=1
AND to_char("REFER_DATE", 'YYYY-MM-DD')    BETWEEN to_char(add_days(CURRENT_DATE,-365), 'YYYY-MM-DD') and to_char(add_days(CURRENT_DATE,-16), 'YYYY-MM-DD');
INSERT INTO FT_CRAWLING_ONLINE_PRICE_VS_COMPETITOR
SELECT * FROM VW_CRAWLING_ONLINE_PRICE_VS_COMPETITOR;
END;