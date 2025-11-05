CREATE PROCEDURE  PROC_GSMARENA_MAPPING_1_0
LANGUAGE SQLSCRIPT as
BEGIN
-- Data Clean 
TRUNCATE TABLE ODS_GSM_ARENA_STAGE;
INSERT INTO ODS_GSM_ARENA_STAGE
	  SELECT  
	 	"brand_nm"
	 , "model_code"
	 , "model_nm"
	 , "mktcode"
	 , "mktname"
	 , MAX("width_mm") "width_mm"
	 , MAX("height_mm") "height_mm"
	 , MAX("depth_mm") "depth_mm"
	 , MAX("display_size") "display_size"
	 , MAX("ram_in_mb") "ram_in_mb"
	 , MAX("internal_storage") "internal_storage"
	 , MAX("dual_sim") "dual_sim"
	 , MAX("main_camera_mp") "main_camera_mp"
	 , MAX("front_camera_mp") "front_camera_mp"
	 , MAX("weight_gramm") "weight_gramm"
	 , MAX("resolution_wid") "resolution_wid"
	 , MAX("resolution_hig") "resolution_hig"
	 , MAX("battery_capacity") "battery_capacity"
	--, MAX("availability_date") "availability_date"
	--, MAX("etcstatus") "etcstatus"
	 FROM (
	SELECT distinct "brand" "brand_nm", "modelcode" "model_code", "modelnm" "model_nm","mktcode" "mktcode","mktnm" "mktname"
		, CASE
			WHEN ( UPPER("subcategory") LIKE '%DIMENSION%' AND "displaynm" = 'Dimensions_width_in_MM' ) AND "value" is not null  
				THEN "value"
			WHEN  "displaynm" = 'Dimensions_Width'
				THEN "value"
		  END "width_mm"
		, CASE
			WHEN ( UPPER("subcategory") LIKE '%DIMENSION%' AND "displaynm" = 'Dimensions_height_in_MM')  AND "value" is not null  
				THEN "value"
			WHEN  "displaynm" = 'Dimensions_Length'
				THEN "value"
		  END "height_mm"
		, CASE
			WHEN ( UPPER("subcategory") LIKE '%DIMENSION%' AND "displaynm" = 'Dimensions_depth_in_MM' ) AND "value" is not null  
				THEN "value"
			WHEN  "displaynm" = 'Dimensions_Thickness'
				THEN "value"
		  END "depth_mm"
		, CASE
			WHEN ( UPPER("subcategory") LIKE '%DISPLAY SIZE%' AND "displaynm" = 'Display_Display size' )  THEN "value" 
		  END "display_size"
		, CASE
			WHEN ( UPPER("subcategory") LIKE '%RAM%' AND "displaynm" = 'RAM_RAM Quantity' ) THEN "value" 
		  END "ram_in_mb"
		, CASE
			WHEN ( UPPER("subcategory") LIKE '%INTERNAL%' AND "displaynm" = 'Internal storage' ) THEN "value" 
		  END "internal_storage"
		, CASE
			WHEN ( UPPER("subcategory") LIKE '%DUAL%' AND "displaynm" = 'Cellular_Dual SIM' ) THEN "value" 
		  END "dual_sim"
		, CASE
			WHEN ( UPPER("subcategory") LIKE '%CAMERA%' AND "displaynm" = 'Main camera_Resolution' ) THEN "value" 
		  END "main_camera_mp"
		, CASE
			WHEN ( UPPER("subcategory") LIKE '%FRONT%' AND "displaynm" = 'Front_Resolution' ) THEN "value" 
		  END "front_camera_mp"
		, CASE
			WHEN ( UPPER("subcategory") LIKE '%WEIGHT%' AND "displaynm" = 'Weight_Weight in Grams' ) THEN "value" 
		  END "weight_gramm"
		, CASE
			WHEN ( UPPER("subcategory") LIKE '%RESOLUTION%' AND "displaynm" = 'Resolution_Horizontal' ) THEN "value" 
		  END "resolution_wid"
		, CASE
			WHEN ( UPPER("subcategory") LIKE '%RESOLUTION%' AND "displaynm" = 'Resolution_Vertical' ) THEN "value" 
		  END "resolution_hig"
		, CASE
			WHEN ( UPPER("subcategory") LIKE '%CAPACITY%' AND "displaynm" = 'Battery_Capacity' ) THEN "value" 
		  END "battery_capacity"
	   , CASE
			WHEN ( "displaynm" = 'Availability_Date' ) THEN "value" 
		  END "availability_date"
		  , "etcstatus"
		--, etcnum, etcyn, initby, initdttm
	 FROM ODS_GSM_ARENA_TMP
	 WHERE (
	   ( UPPER("subcategory") LIKE '%DIMENSION%' AND "displaynm" IN ('Dimensions_width_in_MM', 'Dimensions_Width') ) -- Width
	 OR ( UPPER("subcategory") LIKE '%DIMENSION%' AND "displaynm" IN ( 'Dimensions_height_in_MM', 'Dimensions_Length' )) -- Height
	 OR ( UPPER("subcategory") LIKE '%DIMENSION%' AND "displaynm" IN ( 'Dimensions_depth_in_MM', 'Dimensions_Thickness' )) --Thickness
	 OR ( UPPER("subcategory") LIKE '%DISPLAY SIZE%' AND "displaynm" = 'Display_Display size' ) -- Display size
	 OR ( UPPER("subcategory") LIKE '%RAM%' AND "displaynm" = 'RAM_RAM Quantity' ) -- RAM
	 OR ( UPPER("subcategory") LIKE '%INTERNAL%' AND "displaynm" = 'Internal storage' ) -- Internal Storage
	 OR ( UPPER("subcategory") LIKE '%DUAL%' AND "displaynm" = 'Cellular_Dual SIM' ) -- Dual SIM
	 OR ( UPPER("subcategory") LIKE '%CAMERA%' AND "displaynm" = 'Main camera_Resolution' ) -- Rear Camera Resolution
	 OR ( UPPER("subcategory") LIKE '%FRONT%' AND "displaynm" = 'Front_Resolution' ) -- Front Camera Resolution
	 OR ( UPPER("subcategory") LIKE '%WEIGHT%' AND "displaynm" = 'Weight_Weight in Grams' ) -- Weight
	 OR ( UPPER("subcategory") LIKE '%RESOLUTION%' AND "displaynm" = 'Resolution_Horizontal' ) -- Display Resolution Horizontal
	 OR ( UPPER("subcategory") LIKE '%RESOLUTION%' AND "displaynm" = 'Resolution_Vertical' ) -- Display Resolution Vertical
	 OR ( UPPER("subcategory") LIKE '%CAPACITY%' AND "displaynm" = 'Battery_Capacity' ) -- Battery Capacity
	 OR ( "displaynm" = 'Availability_Date' ) -- Battery Capacity
	) --
	--AND  "initdttm" = '20200710'
	AND TO_CHAR(LOAD_DATE, 'YYYY-MM-DD') IN ( SELECT MAX(TO_CHAR(LOAD_DATE, 'YYYY-MM-DD')) FROM "OW_LAO"."ODS_GSM_ARENA_TMP"  )
	GROUP BY "brand", "modelcode", "modelnm","mktcode","mktnm","subcategory","displaynm", "value", "etcstatus"
	) 
	WHERE 1=1
	-- AND UPPER("etcstatus") = 'D' --AND "availability_date" >= '20190101'
	GROUP BY "brand_nm", "model_code", "model_nm","mktcode", "mktname", "etcstatus"
	;
UPDATE ODS_GSM_ARENA_STAGE
 SET
 width_mm = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(width_mm)) FROM 1 OCCURRENCE 1) 
  , height_mm = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(height_mm)) FROM 1 OCCURRENCE 1) 
  , depth_mm = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(depth_mm)) FROM 1 OCCURRENCE 1) 
  , display_size = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(display_size)) FROM 1 OCCURRENCE 1) 
  , ram_in_mb = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(ram_in_mb)) FROM 1 OCCURRENCE 1) 
  , internal_storage =SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(internal_storage)) FROM 1 OCCURRENCE 1) 
  , main_camera_mp = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(main_camera_mp)) FROM 1 OCCURRENCE 1) 
  , front_camera_mp = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(front_camera_mp)) FROM 1 OCCURRENCE 1) 
  , weight_gramm = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(weight_gramm)) FROM 1 OCCURRENCE 1) 
  , resolution_wid = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(resolution_wid)) FROM 1 OCCURRENCE 1) 
  , resolution_hig = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(resolution_hig)) FROM 1 OCCURRENCE 1) 
  , battery_capacity = SUBSTRING_REGEXPR('\d+(\.\d{1,2})?' IN UPPER(TRIM(battery_capacity)) FROM 1 OCCURRENCE 1)
;
INSERT INTO ODS_GSM_ARENA_STAGE
  SELECT  
	 brand_nm
	 , CONCAT(model_code, '_X')
	 , model_nm
	 , mktcode
	 , mktname
	 , ROUND(width_mm, 0, ROUND_HALF_DOWN) width_mm
 	 , ROUND(height_mm, 0, ROUND_HALF_DOWN) height_mm
 	 , ROUND(depth_mm, 0, ROUND_HALF_DOWN) depth_mm
	 , display_size
	 , ram_in_mb
	 , internal_storage
	 , dual_sim
	 , main_camera_mp
	 , front_camera_mp
	 , weight_gramm
	 , resolution_wid
	 , resolution_hig
	 , battery_capacity
FROM ODS_GSM_ARENA_STAGE;
 UPDATE ODS_GSM_ARENA_STAGE
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
 
 UPDATE ODS_GSM_ARENA_STAGE
 SET
 	width_mm = CASE WHEN width_mm is null or width_mm = '' THEN '$' ELSE width_mm END
 	, height_mm =  CASE WHEN height_mm is null or height_mm = '' THEN '$' ELSE height_mm END
 	, depth_mm = CASE WHEN depth_mm is null or depth_mm = '' THEN '$' ELSE depth_mm END 
	, display_size =  CASE WHEN display_size is null or display_size = '' THEN '$' ELSE display_size END 
 	, ram_in_mb =  CASE WHEN ram_in_mb is null or ram_in_mb = '' THEN '$' ELSE ram_in_mb END
 	, internal_storage = CASE WHEN internal_storage is null or internal_storage = '' THEN '$' ELSE internal_storage END
 	, main_camera_mp = CASE WHEN main_camera_mp is null or main_camera_mp = '' THEN '$' ELSE main_camera_mp END
 	, front_camera_mp = CASE WHEN front_camera_mp is null or front_camera_mp = '' THEN '$' ELSE front_camera_mp END
	, weight_gramm = CASE WHEN weight_gramm is null or weight_gramm = '' THEN '$' ELSE weight_gramm END
 	, resolution_wid = CASE WHEN resolution_wid is null or resolution_wid = '' THEN '$' ELSE resolution_wid END
 	, resolution_hig = CASE WHEN resolution_hig is null or resolution_hig = '' THEN '$' ELSE resolution_hig END
	, battery_capacity = CASE WHEN battery_capacity is null or battery_capacity = '' THEN '$' ELSE battery_capacity END
	, dual_sim = CASE WHEN dual_sim is null or dual_sim = '' THEN '$' ELSE dual_sim END
 ;
 
 
TRUNCATE TABLE MP_GSMARENA_MERGE_DATA_MAPPING;
INSERT INTO MP_GSMARENA_MERGE_DATA_MAPPING
SELECT * FROM ODS_GSM_ARENA_STAGE;
TRUNCATE TABLE MP_GSMARENA_MERGE_DATA_MAPPING_KEY;
INSERT INTO MP_GSMARENA_MERGE_DATA_MAPPING_KEY
SELECT 
	brand_nm, 
	model_code,
	model_nm, 
	mktname,
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
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( weight_gramm,'')) as case1,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( display_size,'')) as case2,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_wid,'')) as case3,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_hig,'')) as case4,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( main_camera_mp,'')) as case5,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( front_camera_mp,'')) as case6,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( ram_in_mb,'')) as case7,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( internal_storage,'')) as case8,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( battery_capacity,'')) as case9,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( dual_sim,'')) as case10,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( display_size,'')) as case11,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_wid,'')) as case12,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_hig,'')) as case13,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( main_camera_mp,'')) as case14,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( front_camera_mp,'')) as case15,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( ram_in_mb,'')) as case16,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( internal_storage,'')) as case17,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( battery_capacity,'')) as case18,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( dual_sim,'')) as case19,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'')) as case20,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'')) as case21,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( main_camera_mp,'')) as case22,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( front_camera_mp,'')) as case23,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( ram_in_mb,'')) as case24,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( internal_storage,'')) as case25,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( battery_capacity,'')) as case26,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( dual_sim,'')) as case27,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'')) as case28,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'')) as case29,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'')) as case30,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( ram_in_mb,'')) as case31,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( internal_storage,'')) as case32,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( battery_capacity,'')) as case33,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( dual_sim,'')) as case34,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'')) as case35,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'')) as case36,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'')) as case37,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( internal_storage,'')) as case38,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( battery_capacity,'')) as case39,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( dual_sim,'')) as case40,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'')) as case41,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case42,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case43,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case44,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case45,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case46,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case47,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case48,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case49,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case50,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case51,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case52,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case53,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case54,
	(COALESCE(height_mm,'') || '_' || COALESCE( width_mm,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case55,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( display_size,'')) as case56,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_wid,'')) as case57,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_hig,'')) as case58,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( main_camera_mp,'')) as case59,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( front_camera_mp,'')) as case60,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( ram_in_mb,'')) as case61,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( internal_storage,'')) as case62,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( battery_capacity,'')) as case63,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( dual_sim,'')) as case64,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'')) as case65,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'')) as case66,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( main_camera_mp,'')) as case67,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( front_camera_mp,'')) as case68,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( ram_in_mb,'')) as case69,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( internal_storage,'')) as case70,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( battery_capacity,'')) as case71,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( dual_sim,'')) as case72,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'')) as case73,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'')) as case74,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'')) as case75,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( ram_in_mb,'')) as case76,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( internal_storage,'')) as case77,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( battery_capacity,'')) as case78,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( dual_sim,'')) as case79,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'')) as case80,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'')) as case81,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'')) as case82,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( internal_storage,'')) as case83,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( battery_capacity,'')) as case84,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( dual_sim,'')) as case85,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'')) as case86,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case87,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case88,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case89,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case90,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case91,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case92,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case93,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case94,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case95,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case96,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case97,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case98,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case99,
	(COALESCE(height_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case100,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'')) as case101,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'')) as case102,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( main_camera_mp,'')) as case103,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( front_camera_mp,'')) as case104,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( ram_in_mb,'')) as case105,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( internal_storage,'')) as case106,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( battery_capacity,'')) as case107,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( dual_sim,'')) as case108,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'')) as case109,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'')) as case110,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'')) as case111,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( ram_in_mb,'')) as case112,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( internal_storage,'')) as case113,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( battery_capacity,'')) as case114,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( dual_sim,'')) as case115,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'')) as case116,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'')) as case117,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'')) as case118,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( internal_storage,'')) as case119,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( battery_capacity,'')) as case120,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( dual_sim,'')) as case121,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'')) as case122,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case123,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case124,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case125,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case126,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case127,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case128,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case129,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case130,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case131,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case132,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case133,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case134,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case135,
	(COALESCE(height_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case136,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'')) as case137,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'')) as case138,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'')) as case139,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( ram_in_mb,'')) as case140,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( internal_storage,'')) as case141,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( battery_capacity,'')) as case142,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( dual_sim,'')) as case143,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'')) as case144,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'')) as case145,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'')) as case146,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( internal_storage,'')) as case147,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( battery_capacity,'')) as case148,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( dual_sim,'')) as case149,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'')) as case150,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case151,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case152,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case153,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case154,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case155,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case156,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case157,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case158,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case159,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case160,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case161,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case162,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case163,
	(COALESCE(height_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case164,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'')) as case165,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'')) as case166,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'')) as case167,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( internal_storage,'')) as case168,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( battery_capacity,'')) as case169,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( dual_sim,'')) as case170,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'')) as case171,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case172,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case173,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case174,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case175,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case176,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case177,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case178,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case179,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case180,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case181,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case182,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case183,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case184,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case185,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'')) as case186,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case187,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case188,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case189,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case190,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case191,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case192,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case193,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case194,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case195,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case196,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case197,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case198,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case199,
	(COALESCE(height_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case200,
	(COALESCE(height_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case201,
	(COALESCE(height_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case202,
	(COALESCE(height_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case203,
	(COALESCE(height_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case204,
	(COALESCE(height_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case205,
	(COALESCE(height_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case206,
	(COALESCE(height_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case207,
	(COALESCE(height_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case208,
	(COALESCE(height_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case209,
	(COALESCE(height_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case210,
	(COALESCE(height_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case211,
	(COALESCE(height_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case212,
	(COALESCE(height_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case213,
	(COALESCE(height_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case214,
	(COALESCE(height_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case215,
	(COALESCE(height_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case216,
	(COALESCE(height_mm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case217,
	(COALESCE(height_mm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case218,
	(COALESCE(height_mm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case219,
	(COALESCE(height_mm,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case220,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( display_size,'')) as case221,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_wid,'')) as case222,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_hig,'')) as case223,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( main_camera_mp,'')) as case224,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( front_camera_mp,'')) as case225,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( ram_in_mb,'')) as case226,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( internal_storage,'')) as case227,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( battery_capacity,'')) as case228,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( dual_sim,'')) as case229,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'')) as case230,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'')) as case231,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( main_camera_mp,'')) as case232,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( front_camera_mp,'')) as case233,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( ram_in_mb,'')) as case234,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( internal_storage,'')) as case235,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( battery_capacity,'')) as case236,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( dual_sim,'')) as case237,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'')) as case238,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'')) as case239,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'')) as case240,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( ram_in_mb,'')) as case241,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( internal_storage,'')) as case242,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( battery_capacity,'')) as case243,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( dual_sim,'')) as case244,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'')) as case245,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'')) as case246,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'')) as case247,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( internal_storage,'')) as case248,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( battery_capacity,'')) as case249,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( dual_sim,'')) as case250,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'')) as case251,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case252,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case253,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case254,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case255,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case256,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case257,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case258,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case259,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case260,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case261,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case262,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case263,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case264,
	(COALESCE(width_mm,'') || '_' || COALESCE( depth_mm,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case265,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'')) as case266,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'')) as case267,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( main_camera_mp,'')) as case268,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( front_camera_mp,'')) as case269,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( ram_in_mb,'')) as case270,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( internal_storage,'')) as case271,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( battery_capacity,'')) as case272,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( dual_sim,'')) as case273,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'')) as case274,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'')) as case275,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'')) as case276,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( ram_in_mb,'')) as case277,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( internal_storage,'')) as case278,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( battery_capacity,'')) as case279,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( dual_sim,'')) as case280,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'')) as case281,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'')) as case282,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'')) as case283,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( internal_storage,'')) as case284,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( battery_capacity,'')) as case285,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( dual_sim,'')) as case286,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'')) as case287,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case288,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case289,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case290,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case291,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case292,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case293,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case294,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case295,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case296,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case297,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case298,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case299,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case300,
	(COALESCE(width_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case301,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'')) as case302,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'')) as case303,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'')) as case304,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( ram_in_mb,'')) as case305,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( internal_storage,'')) as case306,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( battery_capacity,'')) as case307,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( dual_sim,'')) as case308,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'')) as case309,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'')) as case310,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'')) as case311,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( internal_storage,'')) as case312,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( battery_capacity,'')) as case313,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( dual_sim,'')) as case314,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'')) as case315,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case316,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case317,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case318,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case319,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case320,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case321,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case322,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case323,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case324,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case325,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case326,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case327,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case328,
	(COALESCE(width_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case329,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'')) as case330,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'')) as case331,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'')) as case332,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( internal_storage,'')) as case333,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( battery_capacity,'')) as case334,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( dual_sim,'')) as case335,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'')) as case336,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case337,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case338,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case339,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case340,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case341,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case342,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case343,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case344,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case345,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case346,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case347,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case348,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case349,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case350,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'')) as case351,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case352,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case353,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case354,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case355,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case356,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case357,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case358,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case359,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case360,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case361,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case362,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case363,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case364,
	(COALESCE(width_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case365,
	(COALESCE(width_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case366,
	(COALESCE(width_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case367,
	(COALESCE(width_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case368,
	(COALESCE(width_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case369,
	(COALESCE(width_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case370,
	(COALESCE(width_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case371,
	(COALESCE(width_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case372,
	(COALESCE(width_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case373,
	(COALESCE(width_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case374,
	(COALESCE(width_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case375,
	(COALESCE(width_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case376,
	(COALESCE(width_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case377,
	(COALESCE(width_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case378,
	(COALESCE(width_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case379,
	(COALESCE(width_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case380,
	(COALESCE(width_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case381,
	(COALESCE(width_mm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case382,
	(COALESCE(width_mm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case383,
	(COALESCE(width_mm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case384,
	(COALESCE(width_mm,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case385,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'')) as case386,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'')) as case387,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( main_camera_mp,'')) as case388,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( front_camera_mp,'')) as case389,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( ram_in_mb,'')) as case390,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( internal_storage,'')) as case391,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( battery_capacity,'')) as case392,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( dual_sim,'')) as case393,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'')) as case394,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'')) as case395,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'')) as case396,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( ram_in_mb,'')) as case397,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( internal_storage,'')) as case398,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( battery_capacity,'')) as case399,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( dual_sim,'')) as case400,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'')) as case401,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'')) as case402,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'')) as case403,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( internal_storage,'')) as case404,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( battery_capacity,'')) as case405,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( dual_sim,'')) as case406,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'')) as case407,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case408,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case409,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case410,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case411,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case412,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case413,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case414,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case415,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case416,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case417,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case418,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case419,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case420,
	(COALESCE(depth_mm,'') || '_' || COALESCE( weight_gramm,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case421,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'')) as case422,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'')) as case423,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'')) as case424,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( ram_in_mb,'')) as case425,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( internal_storage,'')) as case426,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( battery_capacity,'')) as case427,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( dual_sim,'')) as case428,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'')) as case429,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'')) as case430,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'')) as case431,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( internal_storage,'')) as case432,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( battery_capacity,'')) as case433,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( dual_sim,'')) as case434,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'')) as case435,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case436,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case437,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case438,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case439,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case440,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case441,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case442,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case443,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case444,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case445,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case446,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case447,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case448,
	(COALESCE(depth_mm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case449,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'')) as case450,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'')) as case451,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'')) as case452,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( internal_storage,'')) as case453,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( battery_capacity,'')) as case454,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( dual_sim,'')) as case455,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'')) as case456,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case457,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case458,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case459,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case460,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case461,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case462,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case463,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case464,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case465,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case466,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case467,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case468,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case469,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case470,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'')) as case471,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case472,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case473,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case474,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case475,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case476,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case477,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case478,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case479,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case480,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case481,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case482,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case483,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case484,
	(COALESCE(depth_mm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case485,
	(COALESCE(depth_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case486,
	(COALESCE(depth_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case487,
	(COALESCE(depth_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case488,
	(COALESCE(depth_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case489,
	(COALESCE(depth_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case490,
	(COALESCE(depth_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case491,
	(COALESCE(depth_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case492,
	(COALESCE(depth_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case493,
	(COALESCE(depth_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case494,
	(COALESCE(depth_mm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case495,
	(COALESCE(depth_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case496,
	(COALESCE(depth_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case497,
	(COALESCE(depth_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case498,
	(COALESCE(depth_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case499,
	(COALESCE(depth_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case500,
	(COALESCE(depth_mm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case501,
	(COALESCE(depth_mm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case502,
	(COALESCE(depth_mm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case503,
	(COALESCE(depth_mm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case504,
	(COALESCE(depth_mm,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case505,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'')) as case506,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'')) as case507,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'')) as case508,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( ram_in_mb,'')) as case509,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( internal_storage,'')) as case510,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( battery_capacity,'')) as case511,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( dual_sim,'')) as case512,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'')) as case513,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'')) as case514,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'')) as case515,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( internal_storage,'')) as case516,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( battery_capacity,'')) as case517,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( dual_sim,'')) as case518,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'')) as case519,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case520,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case521,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case522,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case523,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case524,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case525,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case526,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case527,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case528,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case529,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case530,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case531,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case532,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( display_size,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case533,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'')) as case534,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'')) as case535,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'')) as case536,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( internal_storage,'')) as case537,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( battery_capacity,'')) as case538,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( dual_sim,'')) as case539,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'')) as case540,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case541,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case542,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case543,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case544,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case545,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case546,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case547,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case548,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case549,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case550,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case551,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case552,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case553,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case554,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'')) as case555,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case556,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case557,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case558,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case559,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case560,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case561,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case562,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case563,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case564,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case565,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case566,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case567,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case568,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case569,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case570,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case571,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case572,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case573,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case574,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case575,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case576,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case577,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case578,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case579,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case580,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case581,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case582,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case583,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case584,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case585,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case586,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case587,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case588,
	(COALESCE(weight_gramm,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case589,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'')) as case590,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'')) as case591,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'')) as case592,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( internal_storage,'')) as case593,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( battery_capacity,'')) as case594,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( dual_sim,'')) as case595,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'')) as case596,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case597,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case598,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case599,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case600,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case601,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case602,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case603,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case604,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case605,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case606,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case607,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case608,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case609,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_wid,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case610,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'')) as case611,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case612,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case613,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case614,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case615,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case616,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case617,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case618,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case619,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case620,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case621,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case622,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case623,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case624,
	(COALESCE(display_size,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case625,
	(COALESCE(display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case626,
	(COALESCE(display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case627,
	(COALESCE(display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case628,
	(COALESCE(display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case629,
	(COALESCE(display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case630,
	(COALESCE(display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case631,
	(COALESCE(display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case632,
	(COALESCE(display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case633,
	(COALESCE(display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case634,
	(COALESCE(display_size,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case635,
	(COALESCE(display_size,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case636,
	(COALESCE(display_size,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case637,
	(COALESCE(display_size,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case638,
	(COALESCE(display_size,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case639,
	(COALESCE(display_size,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case640,
	(COALESCE(display_size,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case641,
	(COALESCE(display_size,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case642,
	(COALESCE(display_size,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case643,
	(COALESCE(display_size,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case644,
	(COALESCE(display_size,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case645,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'')) as case646,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case647,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case648,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case649,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case650,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case651,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case652,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case653,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case654,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case655,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case656,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case657,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case658,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case659,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( resolution_hig,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case660,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case661,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case662,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case663,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case664,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case665,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case666,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case667,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case668,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case669,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case670,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case671,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case672,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case673,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case674,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case675,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case676,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case677,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case678,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case679,
	(COALESCE(resolution_wid,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case680,
	(COALESCE(resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'')) as case681,
	(COALESCE(resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'')) as case682,
	(COALESCE(resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'')) as case683,
	(COALESCE(resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( dual_sim,'')) as case684,
	(COALESCE(resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case685,
	(COALESCE(resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case686,
	(COALESCE(resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case687,
	(COALESCE(resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case688,
	(COALESCE(resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case689,
	(COALESCE(resolution_hig,'') || '_' || COALESCE( main_camera_mp,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case690,
	(COALESCE(resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case691,
	(COALESCE(resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case692,
	(COALESCE(resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case693,
	(COALESCE(resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case694,
	(COALESCE(resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case695,
	(COALESCE(resolution_hig,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case696,
	(COALESCE(resolution_hig,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case697,
	(COALESCE(resolution_hig,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case698,
	(COALESCE(resolution_hig,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case699,
	(COALESCE(resolution_hig,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case700,
	(COALESCE(main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'')) as case701,
	(COALESCE(main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'')) as case702,
	(COALESCE(main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( dual_sim,'')) as case703,
	(COALESCE(main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case704,
	(COALESCE(main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case705,
	(COALESCE(main_camera_mp,'') || '_' || COALESCE( front_camera_mp,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case706,
	(COALESCE(main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case707,
	(COALESCE(main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case708,
	(COALESCE(main_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case709,
	(COALESCE(main_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case710,
	(COALESCE(front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'')) as case711,
	(COALESCE(front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( dual_sim,'')) as case712,
	(COALESCE(front_camera_mp,'') || '_' || COALESCE( ram_in_mb,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case713,
	(COALESCE(front_camera_mp,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case714,
	(COALESCE(ram_in_mb,'') || '_' || COALESCE( internal_storage,'') || '_' || COALESCE( battery_capacity,'') || '_' || COALESCE( dual_sim,'')) as case715
	FROM ODS_GSM_ARENA_STAGE;
/*	
---Tratamento do caractere " + " pois registros assim estão com erro na PROC PT2	
update OW_LAO.MP_GSMARENA_MERGE_DATA_MAPPING_KEY
 set model_nm=replace(model_nm,' + ','+ ')
 where model_nm like '% + %';
 
 update  OW_LAO.MP_GSMARENA_MERGE_DATA_MAPPING
 set model_nm=replace(model_nm,' + ','+ ')
 where model_nm like '% + %';
 */
 
END;