create PROCEDURE OW_LAO.PROC_ODS_HYBRIS_RETURNS
 LANGUAGE SQLSCRIPT AS
 BEGIN
       drop table OW_LAO.TMP_HYBRIS_RETURNS_DEDUP;
     
     create column table OW_LAO.TMP_HYBRIS_RETURNS_DEDUP as (
          
            select row_number()
                        over(partition by country_cd
                                        , line_item_id
                                 order by file_generated_at desc
                        )                                                               dedup
                 , *
              from OW_LAO.RAW_HYBRIS_RETURNS a
             where 1 = 1
               and not exists(
                          select 1
                            from OW_LAO.ODS_HYBRIS_RETURNS aa
                           where aa.country_cd         = a.country_cd
                             and aa.line_item_id       = a.line_item_id
                             and aa.file_generated_at >= a.file_generated_at
                   ) 
     );
     
     delete from OW_LAO.TMP_HYBRIS_RETURNS_DEDUP where dedup != 1; 
                                              
     merge into OW_LAO.ODS_HYBRIS_RETURNS       a
          using OW_LAO.TMP_HYBRIS_RETURNS_DEDUP b on b.country_cd   = a.country_cd
                                                 and b.line_item_id = a.line_item_id
           when     matched then update
                                      set  a."LINE_ITEM_ID" = b."LINE_ITEM_ID"
									     , a."COUNTRY_CD" = b."COUNTRY_CD"
									     , a."PO_ID" = b."PO_ID"
									     , a."ORDER_DATE_LOCAL" = b."ORDER_DATE_LOCAL"
									     , a."ORDER_DATE_TIME_LOCAL" = b."ORDER_DATE_TIME_LOCAL"
									     , a."RETURN_DATE_TIME_UTC" = b."RETURN_DATE_TIME_UTC"
									     , a."RETURN_DATE_TIME_LOCAL" = b."RETURN_DATE_TIME_LOCAL"
									     , a."SKU" = b."SKU"
									     , a."EAN" = b."EAN"
									     , a."PRODUCT_NAME" = b."PRODUCT_NAME"
									     , a."PRODUCT_TYPE" = b."PRODUCT_TYPE"
									     , a."TAXONOMY_PRODUCT_CATEGORY" = b."TAXONOMY_PRODUCT_CATEGORY"
									     , a."TAXONOMY_PRODUCT_FAMILY" = b."TAXONOMY_PRODUCT_FAMILY"
									     , a."SUBTOTAL_PRICE" = b."SUBTOTAL_PRICE"
									     , a."TAXES" = b."TAXES"
									     , a."UNIT_SALES_PRICE" = b."UNIT_SALES_PRICE"
									     , a."ORDER_QUANTITY" = b."ORDER_QUANTITY"
									     , a."RETURN_QUANTITY" = b."RETURN_QUANTITY"
									     , a."REFUND_AMOUNT" = b."REFUND_AMOUNT"
									     , a."REFUND_CURRENCY" = b."REFUND_CURRENCY"
									     , a."RETURN_STATUS" = b."RETURN_STATUS"
									     , a."REASON_CODE" = b."REASON_CODE"
									     , a."RETURN_REASON_TEXT" = b."RETURN_REASON_TEXT"
									     , a."RETURN_DO_ID" = b."RETURN_DO_ID"
									     , a."RETURN_CARRIER_STATUS" = b."RETURN_CARRIER_STATUS"
									     , a."RETURN_TRACKING_NUMBER" = b."RETURN_TRACKING_NUMBER"
									     , a."RSO_ID" = b."RSO_ID"
									     , a."RMA_NUMBER" = b."RMA_NUMBER"
									     , a."DAYS_LAPSED_FOR_RETURN_INITIATE" = b."DAYS_LAPSED_FOR_RETURN_INITIATE"
									     , a."RETURN_SUCCESS_DATE_LOCAL" = b."RETURN_SUCCESS_DATE_LOCAL"
									     , a."INITIATE_TO_SUCCESS_DAYS" = b."INITIATE_TO_SUCCESS_DAYS"
									     , a."RETURN_TYPE" = b."RETURN_TYPE"
                                         , a."FILE_NAME_FROM_FILE"    = B."FILE_NAME_FROM_FILE"
                                         , a.LOAD_DATE                = b.LOAD_DATE
                                         , a.UPDATED_DATETIME         = current_timestamp
                                         , a.FILE_NAME                = b.FILE_NAME 
                                         , a.FILE_LAST_MODIFIED_TIME  = b.FILE_LAST_MODIFIED_TIME 
                                         , a.FILE_NAME_SHORT          = b.FILE_NAME_SHORT 
                                         , a.file_generated_at        = b.file_generated_at 
           when not matched then insert values(
                                                   b."LINE_ITEM_ID"
											     , b."COUNTRY_CD"
											     , b."PO_ID"
											     , b."ORDER_DATE_LOCAL"
											     , b."ORDER_DATE_TIME_LOCAL"
											     , b."RETURN_DATE_TIME_UTC"
											     , b."RETURN_DATE_TIME_LOCAL"
											     , b."SKU"
											     , b."EAN"
											     , b."PRODUCT_NAME"
											     , b."PRODUCT_TYPE"
											     , b."TAXONOMY_PRODUCT_CATEGORY"
											     , b."TAXONOMY_PRODUCT_FAMILY"
											     , b."SUBTOTAL_PRICE"
											     , b."TAXES"
											     , b."UNIT_SALES_PRICE"
											     , b."ORDER_QUANTITY"
											     , b."RETURN_QUANTITY"
											     , b."REFUND_AMOUNT"
											     , b."REFUND_CURRENCY"
											     , b."RETURN_STATUS"
											     , b."REASON_CODE"
											     , b."RETURN_REASON_TEXT"
											     , b."RETURN_DO_ID"
											     , b."RETURN_CARRIER_STATUS"
											     , b."RETURN_TRACKING_NUMBER"
											     , b."RSO_ID"
											     , b."RMA_NUMBER"
											     , b."DAYS_LAPSED_FOR_RETURN_INITIATE"
											     , b."RETURN_SUCCESS_DATE_LOCAL"
											     , b."INITIATE_TO_SUCCESS_DAYS"
											     , b."RETURN_TYPE"
                                                 , B."FILE_NAME_FROM_FILE"
                                                 , B."LOAD_DATE"
                                                 , B."FILE_NAME"
                                                 , B."FILE_LAST_MODIFIED_TIME"
                                                 , B."FILE_NAME_SHORT"
                                                 , B."LOAD_DATE"
                                                 , B."FILE_GENERATED_AT"
                                                 , NULL
                                         );
                                              
   end