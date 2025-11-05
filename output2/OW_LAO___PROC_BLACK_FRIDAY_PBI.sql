CREATE PROCEDURE OW_LAO.PROC_BLACK_FRIDAY_PBI(
	IN CONSULTA 		NVARCHAR(40),
	IN RANGE_START 		TIMESTAMP,
	IN RANGE_END 		TIMESTAMP	
) LANGUAGE SQLSCRIPT AS
BEGIN
	IF :CONSULTA = 'F_SALES' THEN
	BEGIN
        SELECT 
            CASE 
                WHEN SUBSIDIARY LIKE 'SEASA%' 	THEN 'SEASA' 
                WHEN SUBSIDIARY LIKE 'SELA%' 	THEN 'SELA'
                ELSE SUBSIDIARY
            END 									AS SUBSIDIARY,                                 
            COUNTRY, 						
--            :RANGE_START,
            DAYS_BETWEEN(:RANGE_START, PO_DATE) + 1 AS CAMPAIGN_DAY,
            PODATE_YEAR,
            PODATE_MONTH,
            RIGHT(ISOWEEK(TO_DATE(PO_DATE)),3) 		AS PO_WEEK,
            TO_DATE(PO_DATE) 						AS PO_DATE,			
            HOUR(PO_HOUR) 							AS PO_HOUR,
            TO_TIMESTAMP(TO_NVARCHAR(TO_DATE(PO_DATE) || ' ' || LEFT(PO_HOUR,2))) AS PO_DATETIME, 
            CHANNEL,
            BIZ_TYPE,
            AUDIENCE_TYPE,
            UPPER(PO_STORENAME)						AS PO_STORENAME,   
            DIVISION 								AS PO_DIVISION,
            UPPER(PRODUCT_CATEGORY)					AS PRODUCT_CATEGORY, 
            PRODUCT_GROUP 							AS PO_PRODUCTGROUP,
            PRODUCT 								AS PO_PRODNAME,
            UPPER(PRODUCT_FAMILY)					AS PRODUCT_FAMILY,
            UPPER(PO_SKU)							AS PO_SKU,
            PO_STATUS, 								   
            PAYMENT_TYPE,
            PO_PAYMENTPROVIDER,
            CASE 
	            WHEN PO_DEVICETYPE IN ('Web','WebMobile')	THEN 'Website'
	            WHEN PO_DEVICETYPE IN ('MOBILEAPP') 		THEN 'App'
	        END AS "PO_DEVICETYPE",                              
            SUM(PO_QTY)								AS PO_QTY,
            SUM(NET_REVENUE) 						AS PO_TOTALPRICE_USD	  
        FROM 
            OW_LAO.ODS_SALES_CONTROL_TOWER_TABLE 
        WHERE 
            TO_DATE(PO_DATE) BETWEEN :RANGE_START AND :RANGE_END
            AND PO_STATUS  <> 'Incomplete'
        GROUP BY 
            CASE 
                WHEN SUBSIDIARY LIKE 'SEASA%' 	THEN 'SEASA' 
                WHEN SUBSIDIARY LIKE 'SELA%' 	THEN 'SELA'
                ELSE SUBSIDIARY
            END,                                 
            COUNTRY, 						
            DAYS_BETWEEN(:RANGE_START, PO_DATE) + 1,
            PO_DATE,
            PODATE_YEAR,
            PODATE_MONTH,
            RIGHT(ISOWEEK(TO_DATE(PO_DATE)),3),
            TO_DATE(PO_DATE),			
            HOUR(PO_HOUR),
            TO_TIMESTAMP(TO_NVARCHAR(TO_DATE(PO_DATE) || ' ' || LEFT(PO_HOUR,2))), 
            CHANNEL,
            BIZ_TYPE,
            AUDIENCE_TYPE,
            UPPER(PO_STORENAME),   
            DIVISION,
            UPPER(PRODUCT_CATEGORY), 
            PRODUCT_GROUP,
            PRODUCT,
            UPPER(PRODUCT_FAMILY),
            UPPER(PO_SKU),
            PO_STATUS, 								   
            PAYMENT_TYPE,
            PO_PAYMENTPROVIDER,
            CASE 
	            WHEN PO_DEVICETYPE IN ('Web','WebMobile')	THEN 'Website'
	            WHEN PO_DEVICETYPE IN ('MOBILEAPP') 		THEN 'App'
	        END;
	END;
	ELSE
	BEGIN
		SELECT 'Procedimento não declaro' AS CONSULTA FROM DUMMY;
	END;
END IF;
END