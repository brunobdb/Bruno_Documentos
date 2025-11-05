CREATE PROCEDURE OW_LAO.proc_ods_lao_premium_products_table_from_gscm_update
LANGUAGE SQLSCRIPT AS
BEGIN
	
drop table OW_LAO.TMP_ods_lao_product_premium_items_GSCM_PREMIUM_MODELS;
    create column table OW_LAO.TMP_ods_lao_product_premium_items_GSCM_PREMIUM_MODELS
        as (
		        select *
		          from OW_LAO.ODS_GSCM_PREMIUM_MODELS
		         where load_date >= add_days(current_date, -1)         
		);
   MERGE INTO OW_LAO.ODS_LAO_PRODUCT_PREMIUM_ITEMS                          O
        USING OW_LAO.TMP_ods_lao_product_premium_items_GSCM_PREMIUM_MODELS  M ON O.ITEM  = M.ITEM
                                                                             AND O.AP2   = M.AP2
                                                                             AND O.PLAN  = M.PLAN
                                                                             AND O.MONTH = M.MONTH
          WHEN MATCHED
          THEN UPDATE 
                  SET O.AP2               = M.AP2 
					, O.PRODUCT_GRP       = M.PRODUCT_GRP 
					, O.PRODUCT           = M.PRODUCT
					, O.ITEM              = M.ITEM
					, O.PLAN              = M.PLAN
					, O.CATEGORY          = M.CATEGORY
					, O."MONTH"           = M."MONTH"
					, O.VALUE             = M.VALUE 
					, O.FILE_ROW_NUMBER   = M.FILE_ROW_NUMBER
					, O.FILE_NAME         = M.FILE_NAME
					, O.UPDATED_TIMESTAMP = CURRENT_TIMESTAMP
          WHEN NOT MATCHED THEN INSERT (
                                         AP2 
                                       , PRODUCT_GRP 
                                       , PRODUCT
                                       , ITEM
                                       , PLAN
                                       , CATEGORY
                                       , "MONTH"
                                       , VALUE 
                                       , FILE_ROW_NUMBER
                                       , FILE_NAME
                                 )
                                VALUES (
                                         M.AP2 
                                       , M.PRODUCT_GRP 
                                       , M.PRODUCT
                                       , M.ITEM
                                       , M.PLAN
                                       , M.CATEGORY
                                       , M."MONTH"
                                       , M.VALUE 
                                       , M.FILE_ROW_NUMBER
                                       , M.FILE_NAME
                                        
                                );
END