CREATE PROCEDURE OW_LAO.PROC_DIM_PRODUCT_MAPPING_LAO
 LANGUAGE SQLSCRIPT AS
 BEGIN
 
 --temporária que inseri dados novos da tabela gscm
	   
 CREATE COLUMN TABLE "OW_LAO"."TMP_DIM_PRODUCT_MAPPING_LAO_GSCM_NEW_ITEM" AS (
SELECT DISTINCT * FROM  (
SELECT 
	
	 
	A.ITEM,
	
 
	CASE 
	WHEN B.PRODUCT_GROUP_TO_BE = 'HHP' THEN A.ATTB09
	WHEN B.PRODUCT_GROUP_TO_BE = 'TV' THEN A.ATTB14 
	WHEN B.PRODUCT_GROUP_TO_BE IN ( 'TABLET', 'NPC') THEN A.ATTB09
	WHEN B.PRODUCT_GROUP_TO_BE IN ('WERABLE', 'WEARABLE','ACCESSORY') THEN A.ATTB04
	WHEN B.PRODUCT_GROUP_TO_BE IN ('AV' , 'MONITOR') THEN A.ATTB15
	ELSE B.PRODUCT_GROUP_TO_BE END  AS PRODUCT,
	 
	B.PRODUCT_CATEGORY,
    CASE
	WHEN b.DIVISION = 'DA' THEN A.ATTB12
	WHEN b.DIVISION = 'VD' AND b.PRODUCT_GROUP_TO_BE = 'HME' THEN 'HME'
	WHEN b.PRODUCT_GROUP_TO_BE = 'HHP' THEN A.ATTB04
	WHEN b.PRODUCT_GROUP_TO_BE = 'TV' THEN A.ATTB15 
	WHEN b.PRODUCT_GROUP_TO_BE IN  ('TABLET', 'NPC', 'WERABLE', 'WEARABLE','ACCESSORY') THEN A.ATTB08
	WHEN b.PRODUCT_GROUP_TO_BE IN  ('AV' , 'MONITOR')  THEN A.ATTB15
	WHEN b.PRODUCT_GROUP_TO_BE = 'TV'   AND  A.ATTB15= 'QLED'    AND  A.ATTB10 = 'NEO QLED'  THEN  A.ATTB10 
    WHEN b.PRODUCT_GROUP_TO_BE = 'TV'   AND  A.ATTB15= 'QLED'    AND  A.ATTB10 IS NULL    AND  A.ATTB08 = 'L'     THEN 'Frame'
    WHEN b.PRODUCT_GROUP_TO_BE = 'TV'   AND  A.ATTB15= 'QLED'    AND  A.ATTB10 IS NULL    AND  A.ATTB08 <> 'L'    THEN 'QLED'
	END AS "PRODUCT_FAMILY",
	B.PRODUCT_GROUP_TO_BE   AS PRODUCT_GROUP,
	B.DIVISION,
	B.BU,
	B."ALL",
	A.ATTB01,
	A.ATTB02,
	A.ATTB03,
	A.ATTB04,
	A.ATTB05,
	A.ATTB06,
	A.ATTB07,
	A.ATTB08,
	A.ATTB09,
	A.ATTB10,
	A.ATTB11 ,
	A.ATTB12,
	A.ATTB13,
	A.ATTB14,
	A.ATTB15,
    'GSCM' AS DATA_SOURCE ,
    A."LOAD_DATE",
    A."LOAD_DATE" AS LAST_UPDATE_DATE,
    row_number()
                    over(partition by A.item  
                             order by A.load_date desc) dedup
	
	
	FROM "OW_LAO"."RAW_DATA_GSCM_ACTUAL_ON_HAND" A
   JOIN  OW_LAO.RAW_LAO_DIM_PRODUCT_MAPPING_APOIO B  ON  B.PRODUCT_GROUP_AS_IS = a.PRODUCT_GRP 
                                                     AND B.PRODUCT_AS_IS       = a.PRODUCT
	                                                 AND B.DATA_SOURCE         = 'GSCM'
	
	WHERE
	-- LEFT (A.item,9)  = 'SM-S938BZ'
---A.ITEM = 'EF-ZS721CBEGWW'
	
	 not exists(
	                  select 1
	                    from "OW_LAO"."DIM_PRODUCT_MAPPING_LAO" C
	                   where LOWER(C.ITEM) = LOWER (A.ITEM)
	                   AND C.DIVISION NOT IN  ('Unmapped')
	             
	            )
	           
	          AND A.ITEM IS NOT NULL
	          AND B.PRODUCT_TO_BE  IS NOT NULL
	 
	          ) 
	         WHERE  dedup = 1
	         AND DIVISION IS NOT NULL 
	       --   and  ITEM = 'RT31DG5220B1CO'  
	         
	         
)	         
 ;
--- Inseri dados novos skus mapeados GSCM
	INSERT INTO "OW_LAO"."DIM_PRODUCT_MAPPING_LAO"(
	
	SELECT DISTINCT 
  a.item,  
  a.PRODUCT, 
  a.PRODUCT_FAMILY,
  CASE WHEN a.PRODUCT_GROUP = 'WERABLE' THEN 'WEARABLE' ELSE a.PRODUCT_GROUP END AS PRODUCT_GROUP,
  a.PRODUCT_CATEGORY,
  a.DIVISION,
  a."BU",
  a."ALL",
  a."ATTB01",
  a. "ATTB02",
  a."ATTB03",
  a."ATTB04",
  a."ATTB05",
  a."ATTB06",
  a."ATTB07",
  a."ATTB08",
  a."ATTB09",
  a."ATTB10",
  a."ATTB11",
  a."ATTB12",
  a."ATTB13",
  a."ATTB14",
  a."ATTB15",
  a."DATA_SOURCE",
  CURRENT_TIMESTAMP AS   LOAD_DATE,
  CURRENT_TIMESTAMP AS LAST_UPDATE_DATE
 
FROM  "OW_LAO"."TMP_DIM_PRODUCT_MAPPING_LAO_GSCM_NEW_ITEM" a 
	WHERE
	 not exists(
	                  select 1
	                    from "OW_LAO"."DIM_PRODUCT_MAPPING_LAO" C
	                   where LOWER(C.ITEM) = LOWER (A.ITEM)
	                     --AND C.DIVISION NOT IN  ('Unmapped')
	             
	            )
	         AND a.DIVISION IS NOT NULL 
)
;
	UPDATE "OW_LAO"."DIM_PRODUCT_MAPPING_LAO" a
	   SET  
 
a."PRODUCT"          =  b."PRODUCT",
a."PRODUCT_FAMILY"   =  b."PRODUCT_FAMILY" ,
a."PRODUCT_GROUP"    =  b."PRODUCT_GROUP" ,
a."PRODUCT_CATEGORY" =  b."PRODUCT_CATEGORY" ,
a."DIVISION"         =  b."DIVISION"   ,
a."DATA_SOURCE"      =  b."DATA_SOURCE"
 
	  FROM  "OW_LAO"."DIM_PRODUCT_MAPPING_LAO"  a
JOIN "OW_LAO"."TMP_DIM_PRODUCT_MAPPING_LAO_GSCM_NEW_ITEM" b
	    ON  LOWER(a.ITEM)   =  LOWER (b.ITEM)
;
---  skus ainda não mapeados da fonte vtex
CREATE COLUMN TABLE "OW_LAO"."TMP_LAO_DIM_PRODUCT_MAPPING_SALES_UNMAPPED_VTEX" AS ( 
SELECT DISTINCT 
a.po_sku AS ITEM,
'VTEX' AS DATA_SOURCE,
'Unmapped' AS DIVISION
FROM OW_LAO.ODS_SALES_CONTROL_TOWER_TABLE a 
WHERE 
  
a.PO_PLATAFORM_DATASOURCE 
NOT IN ('ow_lao.ods_hybris_sales' )
AND CAST (PO_DATE AS DATE) >= '2022-01-01'
AND a.PO_SKU IS NOT NULL 
AND 
	 not exists(
	                  select 1
	                    from "OW_LAO"."DIM_PRODUCT_MAPPING_LAO" aa
	                   where LOWER(aa.ITEM) = LOWER (a.po_sku)
	                 
	              
	            ) 
 )
;
----inseri item ainda não mapeado da fonte vtex na DIM_PRODUCT_MAPPING_LAO
	INSERT INTO "OW_LAO"."DIM_PRODUCT_MAPPING_LAO"(
	
	SELECT DISTINCT 
  a.item,  
'' AS PRODUCT,
'' AS PRODUCT_FAMILY,
'' AS PRODUCT_GROUP,
'' AS PRODUCT_CATEGORY,
a.DIVISION,
'' AS "BU",
                    '' AS "ALL",
                    '' AS "ATTB01",
                    '' AS "ATTB02",
                    '' AS "ATTB03",
                    '' AS "ATTB04",
                    '' AS "ATTB05",
                    '' AS "ATTB06",
                    '' AS "ATTB07",
                    '' AS "ATTB08",
                    '' AS "ATTB09",
                    '' AS "ATTB10",
                    '' AS "ATTB11",
                    '' AS "ATTB12",
                    '' AS "ATTB13",
                    '' AS "ATTB14",
                    '' AS "ATTB15",
                    a."DATA_SOURCE",
                    CURRENT_TIMESTAMP AS   LOAD_DATE,
                    CURRENT_TIMESTAMP AS LAST_UPDATE_DATE
 
FROM "OW_LAO"."TMP_LAO_DIM_PRODUCT_MAPPING_SALES_UNMAPPED_VTEX" a
WHERE
 not exists(
	                  select 1
	                    from "OW_LAO"."DIM_PRODUCT_MAPPING_LAO" aa
	                   where LOWER(aa.ITEM) = LOWER (a.ITEM)
	             
	            )
	            	        
)
;
---  kit ainda não mapeados da fonte vtex
CREATE COLUMN TABLE "OW_LAO"."TMP_LAO_DIM_PRODUCT_MAPPING_SALES_UNMAPPED_VTEX_KIT" AS ( 
SELECT DISTINCT 
a.PO_SKU_KIT  AS ITEM,
'VTEX' AS DATA_SOURCE,
'Unmapped' AS DIVISION
FROM OW_LAO.ODS_SALES_CONTROL_TOWER_TABLE a 
WHERE 
  
 
a.PO_PLATAFORM_DATASOURCE 
NOT IN ('ow_lao.ods_hybris_sales' )
AND CAST (PO_DATE AS DATE) >= '2022-01-01'
AND a.PO_SKU_KIT IS NOT NULL 
AND 
	 not exists(
	                  select 1
	                    from "OW_LAO"."DIM_PRODUCT_MAPPING_LAO" aa
	                   where LOWER(aa.ITEM) = LOWER (a.po_sku)
	                 
	             
	            )   
 )
;
----inseri item (KIT) ainda não mapeado da fonte vtex na DIM_PRODUCT_MAPPING_LAO
	INSERT INTO "OW_LAO"."DIM_PRODUCT_MAPPING_LAO"(
	
	SELECT DISTINCT 
  a.item,  
'' AS PRODUCT,
'' AS PRODUCT_FAMILY,
'' AS PRODUCT_GROUP,
'' AS PRODUCT_CATEGORY,
a.DIVISION,
'' AS "BU",
                    '' AS "ALL",
                    '' AS "ATTB01",
                    '' AS "ATTB02",
                    '' AS "ATTB03",
                    '' AS "ATTB04",
                    '' AS "ATTB05",
                    '' AS "ATTB06",
                    '' AS "ATTB07",
                    '' AS "ATTB08",
                    '' AS "ATTB09",
                    '' AS "ATTB10",
                    '' AS "ATTB11",
                    '' AS "ATTB12",
                    '' AS "ATTB13",
                    '' AS "ATTB14",
                    '' AS "ATTB15",
                    a."DATA_SOURCE",
                    CURRENT_TIMESTAMP AS   LOAD_DATE,
                    CURRENT_TIMESTAMP AS LAST_UPDATE_DATE
 
FROM "OW_LAO"."TMP_LAO_DIM_PRODUCT_MAPPING_SALES_UNMAPPED_VTEX_KIT" a
WHERE
 not exists(
	                  select 1
	                    from "OW_LAO"."DIM_PRODUCT_MAPPING_LAO" aa
	                   where LOWER(aa.ITEM) = LOWER (a.ITEM)
	             
	            )
	            	         
)
;
---  skus ainda não mapeados da fonte hybris
 
CREATE COLUMN TABLE "OW_LAO"."TMP_LAO_DIM_PRODUCT_MAPPING_SALES_UNMAPPED_HYBRIS" AS ( 
SELECT DISTINCT 
a.po_sku AS ITEM, 
'HYBRIS' AS DATA_SOURCE, 
'Unmapped' AS DIVISION
FROM OW_LAO.ODS_SALES_CONTROL_TOWER_TABLE a 
WHERE 
 a.PO_PLATAFORM_DATASOURCE = 'ow_lao.ods_hybris_sales'
 AND CAST (PO_DATE AS DATE) >= '2022-01-01'
 AND a.po_sku IS NOT NULL 
AND 
	 not exists(
	                  select 1
	                    from "OW_LAO"."DIM_PRODUCT_MAPPING_LAO" aa
	                   where LOWER(aa.ITEM) = LOWER (a.po_sku)
	                 
	             
	            )  
	            --AND a.po_sku = 'AA59-00817A'
	       
 )
;
 ----inseri item ainda não mapeado da fonte hybris na DIM_PRODUCT_MAPPING_LAO
	INSERT INTO "OW_LAO"."DIM_PRODUCT_MAPPING_LAO"(
	
	SELECT DISTINCT 
  a.item,  
'' AS PRODUCT,
'' AS PRODUCT_FAMILY,
'' AS PRODUCT_GROUP,
'' AS PRODUCT_CATEGORY,
a.DIVISION,
'' AS "BU",
                    '' AS "ALL",
                    '' AS "ATTB01",
                    '' AS "ATTB02",
                    '' AS "ATTB03",
                    '' AS "ATTB04",
                    '' AS "ATTB05",
                    '' AS "ATTB06",
                    '' AS "ATTB07",
                    '' AS "ATTB08",
                    '' AS "ATTB09",
                    '' AS "ATTB10",
                    '' AS "ATTB11",
                    '' AS "ATTB12",
                    '' AS "ATTB13",
                    '' AS "ATTB14",
                    '' AS "ATTB15",
                    a."DATA_SOURCE",
                    CURRENT_TIMESTAMP AS   LOAD_DATE,
                    CURRENT_TIMESTAMP AS LAST_UPDATE_DATE
 
FROM "OW_LAO"."TMP_LAO_DIM_PRODUCT_MAPPING_SALES_UNMAPPED_HYBRIS" a
WHERE
 not exists(
	                  select 1
	                    from "OW_LAO"."DIM_PRODUCT_MAPPING_LAO" aa
	                   where LOWER(aa.ITEM) = LOWER (a.ITEM)
	             
	            )
	            	          
)
;
 
---  KIT ainda não mapeados da fonte hybris
CREATE COLUMN TABLE "OW_LAO"."TMP_LAO_DIM_PRODUCT_MAPPING_SALES_UNMAPPED_HYBRIS_KIT" AS ( 
SELECT DISTINCT 
a.PO_SKU_KIT  AS ITEM, 
'HYBRIS' AS DATA_SOURCE,
'Unmapped' AS DIVISION
FROM OW_LAO.ODS_SALES_CONTROL_TOWER_TABLE a 
WHERE 
 a.PO_PLATAFORM_DATASOURCE = 'ow_lao.ods_hybris_sales'
 AND CAST (PO_DATE AS DATE) >= '2022-01-01'
 AND a.PO_SKU_KIT IS NOT NULL  
 AND    a.PO_SKU_KIT  = ' ' 
AND 
	 not exists(
	                  select 1
	                    from "OW_LAO"."DIM_PRODUCT_MAPPING_LAO" aa
	                   where LOWER(aa.ITEM) = LOWER (a.po_sku)
	                 
	             
	            )  
 )
;
 ----inseri item ainda não mapeado da fonte hybris na DIM_PRODUCT_MAPPING_LAO
	INSERT INTO "OW_LAO"."DIM_PRODUCT_MAPPING_LAO"(
	
	SELECT DISTINCT 
  a.item,  
'' AS PRODUCT,
'' AS PRODUCT_FAMILY,
'' AS PRODUCT_GROUP,
'' AS PRODUCT_CATEGORY,
a.DIVISION,
'' AS "BU",
                    '' AS "ALL",
                    '' AS "ATTB01",
                    '' AS "ATTB02",
                    '' AS "ATTB03",
                    '' AS "ATTB04",
                    '' AS "ATTB05",
                    '' AS "ATTB06",
                    '' AS "ATTB07",
                    '' AS "ATTB08",
                    '' AS "ATTB09",
                    '' AS "ATTB10",
                    '' AS "ATTB11",
                    '' AS "ATTB12",
                    '' AS "ATTB13",
                    '' AS "ATTB14",
                    '' AS "ATTB15",
                    a."DATA_SOURCE",
                    CURRENT_TIMESTAMP AS   LOAD_DATE,
                    CURRENT_TIMESTAMP AS LAST_UPDATE_DATE
 
FROM "OW_LAO"."TMP_LAO_DIM_PRODUCT_MAPPING_SALES_UNMAPPED_HYBRIS_KIT" a
WHERE
 not exists(
	                  select 1
	                    from "OW_LAO"."DIM_PRODUCT_MAPPING_LAO" aa
	                   where LOWER(aa.ITEM) = LOWER (a.ITEM)
	             
	            )
	            	         
)
;
 
 
 ---Atualiza dados  planilha Minio negócio
    
           CREATE COLUMN TABLE  "OW_LAO"."TMP_LAO_DIM_PRODUCT_MAPPING_TABLE_MINIO" AS (     
SELECT DISTINCT
       UPPER (A.ITEM)    AS ITEM,
    A.PRODUCT_TO_BE AS PRODUCT,
    A.PRODUCT_FAMILY,
    CASE WHEN A.PRODUCT_GROUP_TO_BE = 'WERABLE' THEN 'WEARABLE' ELSE A.PRODUCT_GROUP_TO_BE END AS PRODUCT_GROUP,
    A.PRODUCT_CATEGORY,
    CASE WHEN A.DIVISION = 'Undefined' THEN 'Unmapped' ELSE A.DIVISION END AS DIVISION,
     A.LOAD_DATE,
     CASE WHEN A.DATA_SOURCE IS NULL THEN 'VTEX' ELSE A.DATA_SOURCE END AS DATA_SOURCE,
     A.FILE_NAME
    
    FROM OW_LAO.RAW_LAO_DIM_PRODUCT_MAPPING_APOIO A
    WHERE (   UPPER (A.ITEM)   , A.LOAD_DATE)  IN 
    (   SELECT DISTINCT 
       UPPER(ITEM)   , 
   MAX ( LOAD_DATE )
    FROM OW_LAO.RAW_LAO_DIM_PRODUCT_MAPPING_APOIO 
    WHERE ITEM IS NOT NULL
        GROUP BY 
         UPPER(ITEM) )
         
    -- AND    UPPER(LEFT (A.ITEM,9) = 'AA59-00817A'
--AND UPPER (A.ITEM) = 'EF-ZS721CBEGWW'
  ORDER BY   A.LOAD_DATE DESC 
)
;
---insert itens novos
INSERT INTO "OW_LAO"."DIM_PRODUCT_MAPPING_LAO"(
	
	SELECT DISTINCT 
  a.item,  
  a.PRODUCT,
   a.PRODUCT_FAMILY,
   a.PRODUCT_GROUP,
a.PRODUCT_CATEGORY,
a.DIVISION,
'' AS "BU",
                    '' AS "ALL",
                    '' AS "ATTB01",
                    '' AS "ATTB02",
                    '' AS "ATTB03",
                    '' AS "ATTB04",
                    '' AS "ATTB05",
                    '' AS "ATTB06",
                    '' AS "ATTB07",
                    '' AS "ATTB08",
                    '' AS "ATTB09",
                    '' AS "ATTB10",
                    '' AS "ATTB11",
                    '' AS "ATTB12",
                    '' AS "ATTB13",
                    '' AS "ATTB14",
                    '' AS "ATTB15",
                    a."DATA_SOURCE",
                    a.LOAD_DATE,
                    CURRENT_TIMESTAMP AS LAST_UPDATE_DATE
 
FROM  "OW_LAO"."TMP_LAO_DIM_PRODUCT_MAPPING_TABLE_MINIO" A
WHERE  
 not exists(
	                  select 1
	                    from OW_LAO.DIM_PRODUCT_MAPPING_LAO BB
	                   where  LOWER(BB.ITEM) =  LOWER(A.ITEM)
	             
	            )
 
	            )
;
--- atualiza dados planilha minio
	UPDATE "OW_LAO"."DIM_PRODUCT_MAPPING_LAO" a
	   SET  
 
a."PRODUCT"          =  b."PRODUCT",
a."PRODUCT_FAMILY"   =  b."PRODUCT_FAMILY" ,
a."PRODUCT_GROUP"    =  b."PRODUCT_GROUP" ,
a."PRODUCT_CATEGORY" =  b."PRODUCT_CATEGORY" ,
a."DIVISION"         =  b."DIVISION"   ,
a."DATA_SOURCE"      =  b."DATA_SOURCE"
 
	  FROM  "OW_LAO"."DIM_PRODUCT_MAPPING_LAO"  a
JOIN "OW_LAO"."TMP_LAO_DIM_PRODUCT_MAPPING_TABLE_MINIO" b
	    ON  LOWER(a.ITEM)   =  LOWER (b.ITEM)
;
 ---- Regras mapeamento ----
 
     
CREATE COLUMN TABLE "OW_LAO"."TMP_LAO_DIM_PRODUCT_MAPPING_RULE" AS ( 
 
SELECT  
ITEM,
CASE  WHEN LEFT(ITEM, 4) IN ('GH81','GH82')    THEN 'Display' 
      WHEN LEFT(ITEM, 4) IN ('DA63','DA97','DC64','DC97','DC66')  THEN  'OTHERS'  
      WHEN LEFT(ITEM, 4) IN ('BN59','BN39','BN96','BP59')       THEN 'Remote Control'  
      WHEN LEFT(ITEM, 5) = 'SM-Q5'    THEN  'Ring'  
      WHEN LEFT(ITEM, 6) = 'HW-LS6'       THEN 'Music Frame'  
      ELSE PRODUCT END AS PRODUCT,
 
CASE  WHEN LEFT(ITEM,4) = 'SM-M'  THEN  RIGHT (LEFT(ITEM,5),2) || 'x' --Ajustado 08/11
      WHEN PRODUCT_GROUP     =  'NPC'  THEN  'Notebook'
      WHEN LEFT(ITEM,4) = 'SM-S'  AND PRODUCT_GROUP = 'HHP' THEN    LEFT(PRODUCT_FAMILY,3)
      WHEN LEFT(PRODUCT_FAMILY,1) = 'S'  AND PRODUCT_GROUP    = 'HHP' THEN    LEFT(PRODUCT_FAMILY,3) --Regra Complementar
      WHEN LEFT(PRODUCT_FAMILY,1) = 'S'  AND PRODUCT_CATEGORY = 'HHP' THEN    LEFT(PRODUCT_FAMILY,3) --Regra Complementar
      
      WHEN PRODUCT_GROUP = 'TV'   AND  ATTB15= 'QLED'    AND  ATTB10 = 'NEO QLED'  THEN  ATTB10 
      WHEN PRODUCT_GROUP = 'TV'   AND  ATTB15= 'QLED'    AND  ATTB10 IS NULL    AND  ATTB08 = 'L'     THEN 'Frame'
      WHEN PRODUCT_GROUP = 'TV'   AND  ATTB15= 'QLED'    AND  ATTB10 IS NULL    AND  ATTB08 <> 'L'    THEN 'QLED'
      WHEN LEFT(ITEM, 4) IN ('GH81','GH82')     THEN 'OTHERS'  
      WHEN LEFT(ITEM, 4) IN ('DA63','DA97','DC64','DC97','DC66')  THEN  'OTHERS'  
      WHEN LEFT(ITEM, 4) IN ('BN59','BN39','BN96','BP59')         THEN 'OTHERS'  
      WHEN LEFT(ITEM, 5) = 'SM-Q5'    THEN  'Ring'  
      WHEN LEFT(ITEM, 6) = 'HW-LS6'       THEN 'Music Frame'  
      WHEN LEFT(ITEM, 2) IN ('EB','EP')   THEN 'POWER'  
      WHEN LEFT(ITEM, 2) IN ('EI','EJ','EO','EE')   THEN 'OTHERS'  
      WHEN LEFT(ITEM, 2) = 'EF'   THEN 'CASE'  
      WHEN LEFT(ITEM, 2) = 'GP'   THEN 'ODM_ACC'    
      WHEN LEFT(ITEM, 4) IN ('ET-S','ET-Y')   THEN 'OTHERS'     
      WHEN LEFT(ITEM, 4) = 'ET-F'   THEN 'CASE' 
      ELSE PRODUCT_FAMILY END AS PRODUCT_FAMILY,
 
CASE  WHEN LEFT(ITEM, 4) IN ('GH81','GH82')    THEN 'ACCESSORY'  
      WHEN LEFT(ITEM, 4) IN ('DA63','DA97','DC64','DC97','DC66')  THEN 'ACCESSORY' 
      WHEN LEFT(ITEM, 4) IN ('BN59','BN39','BN96','BP59')         THEN 'ACCESSORY' 
      WHEN LEFT(ITEM, 5) = 'SM-Q5'    THEN 'WEARABLE'  
      WHEN LEFT(ITEM, 6) = 'HW-LS6'       THEN 'AV'  
      WHEN LEFT(ITEM, 2) IN ('EB','EP')   THEN 'ACCESSORY'  
      WHEN LEFT(ITEM, 2) IN ('EI','EJ','EO','EE')   THEN 'ACCESSORY'  
      WHEN LEFT(ITEM, 2) = 'EF'   THEN 'ACCESSORY'  
      WHEN LEFT(ITEM, 2) = 'GP'   THEN 'ACCESSORY'  
      WHEN LEFT(ITEM, 4) IN ('ET-S','ET-Y')   THEN 'ACCESSORY'  
      WHEN LEFT(ITEM, 4) = 'ET-F'   THEN 'ACCESSORY' 
      ELSE PRODUCT_GROUP END AS PRODUCT_GROUP,
   
CASE  WHEN LEFT(ITEM,4)  = 'SM-M'  THEN   'M'
      WHEN PRODUCT_GROUP = 'TV'    AND ATTB03 IS NOT NULL AND ATTB03 NOT IN  ('') THEN   ATTB03   
   --   WHEN PRODUCT_GROUP = 'TV'    AND ATTB03 NOT IN  ('') THEN   ATTB03  
      WHEN PRODUCT_GROUP = 'HHP'   AND ATTB08 IS NOT NULL AND ATTB08 NOT IN  ('')  THEN   ATTB08   
     -- WHEN PRODUCT_GROUP = 'HHP'   AND ATTB08 NOT IN  ('') THEN   ATTB08  
      ELSE  PRODUCT_CATEGORY END AS  PRODUCT_CATEGORY,  
CASE WHEN LEFT(ITEM, 2) = 'F-'       THEN 'Bundle'  
     WHEN LEFT(ITEM, 2) = 'P-'       THEN 'SC+'  
     WHEN LEFT(ITEM, 2) = 'S-'       THEN 'SERVICE'  
     WHEN UPPER(LEFT(ITEM, 8))= 'EVOUCHER' THEN 'SERVICE'  
     WHEN LEFT(ITEM, 4) IN ('GH81','GH82')     THEN 'MX'  
     WHEN LEFT(ITEM, 4) IN ('DA63','DA97','DC64','DC97','DC66') THEN 'DA'  
     WHEN LEFT(ITEM, 4) IN ('BN59','BN39','BN96','BP59')        THEN 'VD'  
     WHEN LEFT(ITEM, 5) = 'SM-Q5'    THEN 'MX'  
     WHEN LEFT(ITEM, 2) = 'MB'       THEN 'Memory'  
     WHEN LEFT(ITEM, 6) = 'HW-LS6'       THEN 'VD'  
     WHEN LEFT(ITEM, 2) IN ('EB','EP')   THEN 'MX'  
     WHEN LEFT(ITEM, 2) IN ('EI','EJ','EO','EE')   THEN 'MX'  
     WHEN LEFT(ITEM, 2) = 'EF'   THEN 'MX'      
     WHEN LEFT(ITEM, 2) = 'GP'   THEN 'MX'          
     WHEN LEFT(ITEM, 4) IN ('ET-S','ET-Y')   THEN 'MX'  
     WHEN LEFT(ITEM, 4) = 'ET-F'   THEN 'MX'  
     ELSE DIVISION END AS DIVISION
 
FROM "OW_LAO"."DIM_PRODUCT_MAPPING_LAO"
--WHERE ITEM = 'EF-ZS721CBEGWW' 
)
;
 UPDATE  "OW_LAO"."DIM_PRODUCT_MAPPING_LAO" A
       set  
            A.PRODUCT          = B.PRODUCT,
            A.PRODUCT_FAMILY   = B.PRODUCT_FAMILY,
            A.PRODUCT_GROUP    = B.PRODUCT_GROUP,
            A.PRODUCT_CATEGORY = B.PRODUCT_CATEGORY,
            A.DIVISION         = B.DIVISION 
   
          
      from "OW_LAO"."DIM_PRODUCT_MAPPING_LAO"   A
      join "OW_LAO"."TMP_LAO_DIM_PRODUCT_MAPPING_RULE" B
        ON  LOWER(a.ITEM)   =  LOWER(b.ITEM)
;
--- atualiza dados planilha minio
	UPDATE "OW_LAO"."DIM_PRODUCT_MAPPING_LAO" a
	   SET  
 
a."PRODUCT"          =  b."PRODUCT",
a."PRODUCT_FAMILY"   =  b."PRODUCT_FAMILY" ,
a."PRODUCT_GROUP"    =  b."PRODUCT_GROUP" ,
a."PRODUCT_CATEGORY" =  b."PRODUCT_CATEGORY" ,
a."DIVISION"         =  b."DIVISION"   ,
a."DATA_SOURCE"      =  b."DATA_SOURCE"
 
	  FROM  "OW_LAO"."DIM_PRODUCT_MAPPING_LAO"  a
JOIN "OW_LAO"."TMP_LAO_DIM_PRODUCT_MAPPING_TABLE_MINIO" b
	    ON  LOWER(a.ITEM)   =  LOWER (b.ITEM)
	    AND CAST (b.LOAD_DATE AS date) >= '2025-06-29'
;
--** Atualiza dados não mapeados com os  9 primeiros caracteres ** 
-- table minio
  CREATE COLUMN TABLE  "OW_LAO"."TMP_LAO_DIM_PRODUCT_MAPPING_TABLE_MINIO_NINE_ITEM" AS (     
SELECT DISTINCT
     LEFT ( UPPER (A.ITEM),9)    AS ITEM,
    A.PRODUCT_TO_BE AS PRODUCT,
    A.PRODUCT_FAMILY,
    CASE WHEN A.PRODUCT_GROUP_TO_BE = 'WERABLE' THEN 'WEARABLE' ELSE A.PRODUCT_GROUP_TO_BE END AS PRODUCT_GROUP,
    A.PRODUCT_CATEGORY,
    CASE WHEN A.DIVISION = 'Undefined' THEN 'Unmapped' ELSE A.DIVISION END AS DIVISION,
     A.LOAD_DATE,
     CASE WHEN A.DATA_SOURCE IS NULL THEN 'VTEX' ELSE A.DATA_SOURCE END AS DATA_SOURCE,
     A.FILE_NAME
    
    FROM OW_LAO.RAW_LAO_DIM_PRODUCT_MAPPING_APOIO A
    WHERE (      LEFT ( UPPER (A.ITEM),9)   , A.LOAD_DATE)  IN 
    (   SELECT DISTINCT 
            LEFT ( UPPER (ITEM),9)   , 
   MAX ( LOAD_DATE )
    FROM OW_LAO.RAW_LAO_DIM_PRODUCT_MAPPING_APOIO 
    WHERE ITEM IS NOT NULL
   
        GROUP BY 
        LEFT ( UPPER (ITEM),9) )
         
--AND    UPPER(LEFT (A.ITEM,9)) = 'QN50Q65CA'
--AND UPPER (A.ITEM) = 'EF-ZS721CBEGWW'
  ORDER BY   A.LOAD_DATE DESC 
)
;
UPDATE  "OW_LAO"."DIM_PRODUCT_MAPPING_LAO" A
       set  
            A.PRODUCT	           =	B.PRODUCT
         ,  A.PRODUCT_FAMILY       =	B.PRODUCT_FAMILY
         ,  A.PRODUCT_GROUP        =	B.PRODUCT_GROUP
         ,  A.PRODUCT_CATEGORY     =	B.PRODUCT_CATEGORY
         ,  A.DIVISION             =	B.DIVISION
         ,  A.DATA_SOURCE          =	B.DATA_SOURCE
          
      from "OW_LAO"."DIM_PRODUCT_MAPPING_LAO"   A
      join  "OW_LAO"."TMP_LAO_DIM_PRODUCT_MAPPING_TABLE_MINIO_NINE_ITEM"  B
      on   LOWER(LEFT (A.ITEM, 9))   =  LOWER(LEFT (B.ITEM, 9))
     WHERE A.DIVISION  = 'Unmapped' 
     ;
-- Produtos não localizados minio
          CREATE COLUMN TABLE  "OW_LAO"."TMP_LAO_DIM_PRODUCT_MAPPING_TABLE_NINE_ITEM_UNMAPPED"  AS 
(
SELECT DISTINCT
     LEFT ( UPPER (A.ITEM),9)    AS ITEM,
    A.PRODUCT,
    A.PRODUCT_FAMILY,
    a.PRODUCT_GROUP,
    A.PRODUCT_CATEGORY,
    A.DIVISION,
    A.LOAD_DATE,
    A.DATA_SOURCE 
      
    
    FROM "OW_LAO"."DIM_PRODUCT_MAPPING_LAO"  A 
    WHERE (  LEFT ( UPPER (A.ITEM),9)   , A.LOAD_DATE)  IN 
    (   SELECT DISTINCT 
            LEFT ( UPPER (ITEM),9)   , 
   MAX ( LOAD_DATE )
    FROM "OW_LAO"."DIM_PRODUCT_MAPPING_LAO"
    WHERE ITEM IS NOT NULL
    AND DIVISION NOT IN ('Unmapped')
    GROUP BY 
        LEFT ( UPPER (ITEM),9) )
        
        AND A.DIVISION NOT IN ('Unmapped')
      
--AND    UPPER(LEFT (A.ITEM,9)) = 'SM-S938BZ'
--AND UPPER (A.ITEM) = 'SM-S938BZTUTPA'
  ORDER BY   A.LOAD_DATE DESC 
 )
;
 
 UPDATE  "OW_LAO"."DIM_PRODUCT_MAPPING_LAO" A
       set  
            A.PRODUCT	           =	B.PRODUCT
         ,  A.PRODUCT_FAMILY       =	B.PRODUCT_FAMILY
         ,  A.PRODUCT_GROUP        =	B.PRODUCT_GROUP
         ,  A.PRODUCT_CATEGORY     =	B.PRODUCT_CATEGORY
         ,  A.DIVISION             =	B.DIVISION
         ,  A.DATA_SOURCE          =	B.DATA_SOURCE
          
      from "OW_LAO"."DIM_PRODUCT_MAPPING_LAO"   A
      join  "OW_LAO"."TMP_LAO_DIM_PRODUCT_MAPPING_TABLE_NINE_ITEM_UNMAPPED" B
      on   LOWER(LEFT (A.ITEM, 9))   =  LOWER(LEFT (B.ITEM, 9))
     WHERE A.DIVISION  = 'Unmapped' 
     ;
     
    
     
      UPDATE  "OW_LAO"."DIM_PRODUCT_MAPPING_LAO" A
       set  
            A.PRODUCT          = NULL,
            A.PRODUCT_FAMILY   = NULL,
            A.PRODUCT_GROUP    = NULL,
            A.PRODUCT_CATEGORY = NULL,
            A.DIVISION         = 'Unmapped',
            a.BU               = NULL,
            a."ALL"            = NULL,
            a.ATTB01           = NULL,
            a.ATTB02           = NULL,
            a.ATTB03           = NULL,
            a.ATTB04           = NULL,
            a.ATTB05           = NULL,
            a.ATTB06           = NULL,
            a.ATTB07           = NULL,
            a.ATTB08           = NULL,
            a.ATTB09           = NULL,
            a.ATTB10           = NULL,
            a.ATTB11           = NULL,
            a.ATTB12           = NULL,
            a.ATTB13           = NULL,
            a.ATTB14           = NULL,
            a.ATTB15           = NULL
            
            
   
          
      from "OW_LAO"."DIM_PRODUCT_MAPPING_LAO"   A
           WHERE A.DIVISION  = 'Unmapped'
 
     
      
 ;
     
DROP TABLE "OW_LAO"."TMP_DIM_PRODUCT_MAPPING_LAO_GSCM_NEW_ITEM" ;
DROP TABLE "OW_LAO"."TMP_LAO_DIM_PRODUCT_MAPPING_SALES_UNMAPPED_VTEX"; 
DROP TABLE "OW_LAO"."TMP_LAO_DIM_PRODUCT_MAPPING_SALES_UNMAPPED_HYBRIS";
DROP TABLE "OW_LAO"."TMP_LAO_DIM_PRODUCT_MAPPING_TABLE_MINIO";
DROP TABLE "OW_LAO"."TMP_LAO_DIM_PRODUCT_MAPPING_TABLE_MINIO_NINE_ITEM";
DROP TABLE "OW_LAO"."TMP_LAO_DIM_PRODUCT_MAPPING_TABLE_NINE_ITEM_UNMAPPED";
DROP TABLE "OW_LAO"."TMP_LAO_DIM_PRODUCT_MAPPING_RULE";
DROP TABLE "OW_LAO"."TMP_LAO_DIM_PRODUCT_MAPPING_SALES_UNMAPPED_HYBRIS_KIT";
DROP TABLE "OW_LAO"."TMP_LAO_DIM_PRODUCT_MAPPING_SALES_UNMAPPED_VTEX_KIT";
end