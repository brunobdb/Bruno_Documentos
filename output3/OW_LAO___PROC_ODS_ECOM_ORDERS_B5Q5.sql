CREATE PROCEDURE OW_LAO.PROC_ODS_ECOM_ORDERS_B5Q5
 LANGUAGE SQLSCRIPT AS
 BEGIN
	 
--Drop PROCEDURE OW_LAO.PROC_ODS_ECOM_ORDERS_B5Q5
	 
INSERT INTO "OW_LAO"."ODS_ECOM_ORDERS_B5Q5"
SELECT 
"SUB" ,
"Order Nr.",
"Creation Date" ,
"SITE" ,
"Order Status" ,
"Product ID" ,
"B5Q5 SKU" ,
"Product QTY" ,
"Price per Unit USD",
"Total Amount USD" ,
"Promotion Code" ,
"Trade in" ,
"Trade up" ,
"SC+" ,
"MODEL" ,
"MEMORY_STORAGE" ,
"COLOR" ,
"CHANNEL" ,
"BIZTYPE" ,
"AUDIENCE_TYPE" ,
"Partner Level" ,
"STATUS",
"Exclusive Model?" ,
"Day of PreOrder" ,
"YEAR" ,
Load_Date ,
Last_Update,
"FILE_NAME"
   FROM  "OW_LAO"."ODS_ECOM_ORDERS_B5Q5_HYBRIS" HY
	 WHERE  1=1
	   AND HY."Order Nr." IS NOT NULL
	   AND HY."Order Nr."  NOT IN (SELECT DISTINCT "Order Nr." FROM  "OW_LAO"."ODS_ECOM_ORDERS_B5Q5" sog WHERE sog."Order Nr." = HY."Order Nr."  )
	   ;
	   
	  	
	  UPDATE "OW_LAO"."ODS_ECOM_ORDERS_B5Q5"  so
	   SET  
so."SITE"= tmp."SITE",
so."Order Status" =tmp."Order Status",
so."B5Q5 SKU" = tmp."B5Q5 SKU",
so."Promotion Code"= tmp."Promotion Code",
so."Trade in"  = tmp."Trade in" ,
so."Trade up"  = tmp."Trade up" ,
so."SC+"  = tmp."SC+",
so."MODEL"   = tmp."MODEL" ,
so."MEMORY_STORAGE"   = tmp."MEMORY_STORAGE" ,
so."COLOR"  = tmp."COLOR",
so."CHANNEL"  = tmp."CHANNEL",
so."BIZTYPE"  = tmp."BIZTYPE",
so."AUDIENCE_TYPE"  = tmp."AUDIENCE_TYPE",
so."Partner Level"  = tmp."Partner Level",
so."STATUS"  = tmp."STATUS",
so."Exclusive Model?"  = tmp."Exclusive Model?",
so."Day of PreOrder"  = tmp."Day of PreOrder",
so."YEAR"  = tmp."YEAR",
so.Last_Update  = tmp.Last_Update,
so."FILE_NAME"  = tmp."FILE_NAME"
	  FROM "OW_LAO"."ODS_ECOM_ORDERS_B5Q5"  so
	  INNER JOIN (
	  SELECT
		   DISTINCT
"SUB" ,
"Order Nr.",
"Product ID",
"SITE",
"Order Status" ,
"B5Q5 SKU" ,
"Promotion Code",
"Trade in"   ,
"Trade up"   ,
"SC+"  ,
"MODEL" ,
"MEMORY_STORAGE",
"COLOR",
"CHANNEL",
"BIZTYPE",
"AUDIENCE_TYPE",
"Partner Level",
"STATUS",
"Exclusive Model?",
"Day of PreOrder",
"YEAR",
Last_Update,
"FILE_NAME"
	  
	  FROM   "OW_LAO"."ODS_ECOM_ORDERS_B5Q5_HYBRIS" 
	  WHERE 1=1) AS tmp
	    ON so."Order Nr." = tmp."Order Nr." AND so."Product ID" = tmp."Product ID" AND so."SUB" = tmp."SUB"  AND so."Order Status" <> tmp."Order Status"
	    
;
  	
	  UPDATE "OW_LAO"."ODS_ECOM_ORDERS_B5Q5"  so
	   SET  
so."SITE"= tmp."SITE",
so."Order Status" =tmp."Order Status",
so."B5Q5 SKU" = tmp."B5Q5 SKU",
so."Promotion Code"= tmp."Promotion Code",
so."Trade in"  = tmp."Trade in" ,
so."Trade up"  = tmp."Trade up" ,
so."SC+"  = tmp."SC+",
so."MODEL"   = tmp."MODEL" ,
so."MEMORY_STORAGE"   = tmp."MEMORY_STORAGE" ,
so."COLOR"  = tmp."COLOR",
so."CHANNEL"  = tmp."CHANNEL",
so."BIZTYPE"  = tmp."BIZTYPE",
so."AUDIENCE_TYPE"  = tmp."AUDIENCE_TYPE",
so."Partner Level"  = tmp."Partner Level",
so."STATUS"  = tmp."STATUS",
so."Exclusive Model?"  = tmp."Exclusive Model?",
so."Day of PreOrder"  = tmp."Day of PreOrder",
so."YEAR"  = tmp."YEAR",
so.Last_Update  = tmp.Last_Update,
so."FILE_NAME"  = tmp."FILE_NAME"
	  FROM "OW_LAO"."ODS_ECOM_ORDERS_B5Q5"  so
	  INNER JOIN (
	  SELECT
		   DISTINCT
"SUB" ,
"Order Nr.",
"Product ID",
"SITE",
"Order Status" ,
"B5Q5 SKU" ,
"Promotion Code",
"Trade in"   ,
"Trade up"   ,
"SC+"  ,
"MODEL" ,
"MEMORY_STORAGE",
"COLOR",
"CHANNEL",
"BIZTYPE",
"AUDIENCE_TYPE",
"Partner Level",
"STATUS",
"Exclusive Model?",
"Day of PreOrder",
"YEAR",
Last_Update,
"FILE_NAME"
	  
	  FROM   "OW_LAO"."ODS_ECOM_ORDERS_B5Q5_HYBRIS" 
	  WHERE 1=1) AS tmp
	    ON so."Order Nr." = tmp."Order Nr." AND so."Product ID" = tmp."Product ID" AND so."SUB" = tmp."SUB"  AND so."STATUS" <> tmp."STATUS"
	    
;
INSERT INTO "OW_LAO"."ODS_ECOM_ORDERS_B5Q5"
SELECT 
"SUB" ,
"Order Nr.",
"Creation Date" ,
"SITE" ,
"Order Status" ,
"Product ID" ,
"B5Q5 SKU" ,
"Product QTY" ,
"Price per Unit USD",
"Total Amount USD" ,
"Promotion Code" ,
"Trade in" ,
"Trade up" ,
"SC+" ,
"MODEL" ,
"MEMORY_STORAGE" ,
"COLOR" ,
"CHANNEL" ,
"BIZTYPE" ,
"AUDIENCE_TYPE" ,
"Partner Level" ,
"STATUS",
"Exclusive Model?" ,
"Day of PreOrder" ,
"YEAR" ,
Load_Date ,
Last_Update,
NULL AS "FILE_NAME"
   FROM  "OW_LAO"."VIEW_ECOM_ORDERS_B5Q5_VTEX" VW
	 WHERE  1=1
	   AND VW."Order Nr." IS NOT NULL
	   AND VW."Order Nr."  NOT IN (SELECT DISTINCT "Order Nr." FROM "OW_LAO"."ODS_ECOM_ORDERS_B5Q5" sog WHERE sog."Order Nr." = VW."Order Nr."  )
	   ;
	   
	  	
	  UPDATE "OW_LAO"."ODS_ECOM_ORDERS_B5Q5"  so
	   SET  
so."SITE"= tmp."SITE",
so."Order Status" =tmp."Order Status",
so."B5Q5 SKU" = tmp."B5Q5 SKU",
so."Promotion Code"= tmp."Promotion Code",
so."Trade in"  = tmp."Trade in" ,
so."Trade up"  = tmp."Trade up" ,
so."SC+"  = tmp."SC+",
so."MODEL"   = tmp."MODEL" ,
so."MEMORY_STORAGE"   = tmp."MEMORY_STORAGE" ,
so."COLOR"  = tmp."COLOR",
so."CHANNEL"  = tmp."CHANNEL",
so."BIZTYPE"  = tmp."BIZTYPE",
so."AUDIENCE_TYPE"  = tmp."AUDIENCE_TYPE",
so."Partner Level"  = tmp."Partner Level",
so."STATUS"  = tmp."STATUS",
so."Exclusive Model?"  = tmp."Exclusive Model?",
so."Day of PreOrder"  = tmp."Day of PreOrder",
so."YEAR"  = tmp."YEAR",
so.Last_Update  = tmp.Last_Update
	  FROM "OW_LAO"."ODS_ECOM_ORDERS_B5Q5"  so
	  INNER JOIN (
	  SELECT
		   DISTINCT
"SUB" ,
"Order Nr.",
"Product ID",
"SITE",
"Order Status" ,
"B5Q5 SKU" ,
"Promotion Code",
"Trade in"   ,
"Trade up"   ,
"SC+"  ,
"MODEL" ,
"MEMORY_STORAGE",
"COLOR",
"CHANNEL",
"BIZTYPE",
"AUDIENCE_TYPE",
"Partner Level",
"STATUS",
"Exclusive Model?",
"Day of PreOrder",
"YEAR",
Last_Update
	  
	  FROM   "OW_LAO"."VIEW_ECOM_ORDERS_B5Q5_VTEX"
	  WHERE 1=1) AS tmp
	    ON so."Order Nr." = tmp."Order Nr." AND so."Product ID" = tmp."Product ID" AND so."SUB" = tmp."SUB" AND so."Order Status" <> tmp."Order Status"
;	    
  UPDATE "OW_LAO"."ODS_ECOM_ORDERS_B5Q5"  so
	   SET  
so."SITE"= tmp."SITE",
so."Order Status" =tmp."Order Status",
so."B5Q5 SKU" = tmp."B5Q5 SKU",
so."Promotion Code"= tmp."Promotion Code",
so."Trade in"  = tmp."Trade in" ,
so."Trade up"  = tmp."Trade up" ,
so."SC+"  = tmp."SC+",
so."MODEL"   = tmp."MODEL" ,
so."MEMORY_STORAGE"   = tmp."MEMORY_STORAGE" ,
so."COLOR"  = tmp."COLOR",
so."CHANNEL"  = tmp."CHANNEL",
so."BIZTYPE"  = tmp."BIZTYPE",
so."AUDIENCE_TYPE"  = tmp."AUDIENCE_TYPE",
so."Partner Level"  = tmp."Partner Level",
so."STATUS"  = tmp."STATUS",
so."Exclusive Model?"  = tmp."Exclusive Model?",
so."Day of PreOrder"  = tmp."Day of PreOrder",
so."YEAR"  = tmp."YEAR",
so.Last_Update  = tmp.Last_Update
	  FROM "OW_LAO"."ODS_ECOM_ORDERS_B5Q5"  so
	  INNER JOIN (
	  SELECT
		   DISTINCT
"SUB" ,
"Order Nr.",
"Product ID",
"SITE",
"Order Status" ,
"B5Q5 SKU" ,
"Promotion Code",
"Trade in"   ,
"Trade up"   ,
"SC+"  ,
"MODEL" ,
"MEMORY_STORAGE",
"COLOR",
"CHANNEL",
"BIZTYPE",
"AUDIENCE_TYPE",
"Partner Level",
"STATUS",
"Exclusive Model?",
"Day of PreOrder",
"YEAR",
Last_Update
	  
	  FROM   "OW_LAO"."VIEW_ECOM_ORDERS_B5Q5_VTEX"
	  WHERE 1=1) AS tmp
	    ON so."Order Nr." = tmp."Order Nr." AND so."Product ID" = tmp."Product ID" AND so."SUB" = tmp."SUB" AND so."STATUS" <> tmp."STATUS"
;	    
END