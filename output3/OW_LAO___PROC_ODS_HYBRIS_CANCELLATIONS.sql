create PROCEDURE OW_LAO.PROC_ODS_HYBRIS_CANCELLATIONS
 LANGUAGE SQLSCRIPT AS
 BEGIN
       drop table OW_LAO.TMP_HYBRIS_CANCELLATIONS_DEDUP;
     
     create column table OW_LAO.TMP_HYBRIS_CANCELLATIONS_DEDUP as (
          
            select row_number()
                        over(partition by country_Cd
                                        , cart_id
                                        , line_item_id
                                 order by file_generated_at desc
                        )                                                               dedup
                 , *
              from OW_LAO.RAW_HYBRIS_CANCELLATIONS a
             where 1 = 1
               and not exists(
                          select 1
                            from OW_LAO.ODS_HYBRIS_CANCELLATIONS aa
                           where aa.Country_Cd         = a.Country_Cd
                             and aa.Cart_id            = a.Cart_id
                             and aa.line_item_id       = a.line_item_id
                             and aa.file_generated_at >= a.file_generated_at
                   ) 
     );
     
     delete from OW_LAO.TMP_HYBRIS_CANCELLATIONS_DEDUP where dedup != 1; 
                                              
     merge into OW_LAO.ODS_HYBRIS_CANCELLATIONS       a
          using OW_LAO.TMP_HYBRIS_CANCELLATIONS_DEDUP b on b.Country_Cd   = a.Country_Cd
                                                       and b.Cart_id      = a.Cart_id
                                                       and b.line_item_id = a.line_item_id
           when     matched then update
                                   set a."CANCELLATION_DATE" = b."CANCELLATION_DATE"
								     , a."ORDER_DATE_LOCAL" = b."ORDER_DATE_LOCAL"
								     , a."PO_ID" = b."PO_ID"
								     , a."CANCELLATION_STATUS" = b."CANCELLATION_STATUS"
								     , a."CANCELLATION_REASON_CODE" = b."CANCELLATION_REASON_CODE"
								     , a."CANCELLATION_TYPE" = b."CANCELLATION_TYPE"
								     , a."CANCELLATION_REASON" = b."CANCELLATION_REASON"
								     , a."QUANTITY" = b."QUANTITY"
								     , a."SUBTOTAL_AMOUNT" = b."SUBTOTAL_AMOUNT"
								     , a."TAXES" = b."TAXES"
								     , a."SALES_PRICE_LOCAL" = b."SALES_PRICE_LOCAL"
								     , a."UNIT_SALES_PRICE" = b."UNIT_SALES_PRICE"
								     , a."LINE_ITEM_QUANTITY" = b."LINE_ITEM_QUANTITY"
								     , a."TAXONOMY_NAME" = b."TAXONOMY_NAME"
								     , a."TAXONOMY_PRODUCT_CATEGORY" = b."TAXONOMY_PRODUCT_CATEGORY"
								     , a."TAXONOMY_PRODUCT_FAMILY" = b."TAXONOMY_PRODUCT_FAMILY"
								     , a."PRODUCT_NAME" = b."PRODUCT_NAME"
								     , a."PRODUCT_TYPE" = b."PRODUCT_TYPE"
								     , a."PRODUCT_MODEL_CODE" = b."PRODUCT_MODEL_CODE"
								     , a."PRODUCT_MODEL_NAME" = b."PRODUCT_MODEL_NAME"
								     , a."FAMILY_ID" = b."FAMILY_ID"
								     , a."SKU" = b."SKU"
								     , a."EAN" = b."EAN"
								     , a."ORDER_CHANNEL_CODE" = b."ORDER_CHANNEL_CODE"
								     , a."PROGRAM_TYPE" = b."PROGRAM_TYPE"
								     , a."STORE_ID" = b."STORE_ID"
								     , a."STORE_NAME" = b."STORE_NAME"
								     , a."CART_TYPE" = b."CART_TYPE"
								     , a."CANCELLED_BY_AGENT" = b."CANCELLED_BY_AGENT"
								     , a."CANCELLATION_ID" = b."CANCELLATION_ID"
								     , a."TAXONOMY_PRODUCT_DIVISION" = b."TAXONOMY_PRODUCT_DIVISION"
								     , a."FILE_NAME_FROM_FILE" = b."FILE_NAME_FROM_FILE"
								     , a."LOAD_DATE" = b."LOAD_DATE"
								     , a."FILE_NAME" = b."FILE_NAME"
								     , a."FILE_LAST_MODIFIED_TIME" = b."FILE_LAST_MODIFIED_TIME"
								     , a."FILE_NAME_SHORT" = b."FILE_NAME_SHORT"
								     , a."FILE_GENERATED_AT" = b."FILE_GENERATED_AT"
								     , a."UPDATED_DATETIME" = current_timestamp
           when not matched then insert values(
										       b."LINE_ITEM_ID"
										     , b."COUNTRY_CD"
										     , b."CANCELLATION_DATE"
										     , b."ORDER_DATE_LOCAL"
										     , b."PO_ID"
										     , b."CANCELLATION_STATUS"
										     , b."CANCELLATION_REASON_CODE"
										     , b."CANCELLATION_TYPE"
										     , b."CANCELLATION_REASON"
										     , b."QUANTITY"
										     , b."SUBTOTAL_AMOUNT"
										     , b."TAXES"
										     , b."SALES_PRICE_LOCAL"
										     , b."UNIT_SALES_PRICE"
										     , b."LINE_ITEM_QUANTITY"
										     , b."TAXONOMY_NAME"
										     , b."TAXONOMY_PRODUCT_CATEGORY"
										     , b."TAXONOMY_PRODUCT_FAMILY"
										     , b."PRODUCT_NAME"
										     , b."PRODUCT_TYPE"
										     , b."PRODUCT_MODEL_CODE"
										     , b."PRODUCT_MODEL_NAME"
										     , b."FAMILY_ID"
										     , b."SKU"
										     , b."EAN"
										     , b."ORDER_CHANNEL_CODE"
										     , b."PROGRAM_TYPE"
										     , b."STORE_ID"
										     , b."STORE_NAME"
										     , b."CART_TYPE"
										     , b."CANCELLED_BY_AGENT"
										     , b."CANCELLATION_ID"
										     , b."CART_ID"
										     , b."TAXONOMY_PRODUCT_DIVISION"
										     , b."FILE_NAME_FROM_FILE"
										     , b."LOAD_DATE"
										     , b."FILE_NAME"
										     , b."FILE_LAST_MODIFIED_TIME"
										     , b."FILE_NAME_SHORT"
										     , null
										     , b."FILE_GENERATED_AT"
                                             , NULL
                                         );
                                              
   end