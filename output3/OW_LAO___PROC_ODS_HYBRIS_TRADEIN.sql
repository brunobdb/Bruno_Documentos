create PROCEDURE OW_LAO.PROC_ODS_HYBRIS_TRADEIN
 LANGUAGE SQLSCRIPT AS
 BEGIN
       drop table OW_LAO.TMP_HYBRIS_TRADEIN_DEDUP;
     
     create column table OW_LAO.TMP_HYBRIS_TRADEIN_DEDUP as (
          
            select row_number()
                        over(partition by country_Cd
                                        , order_id
                                        , line_item_id
                                 order by file_generated_at desc
                        )                                                               dedup
                 , *
              from OW_LAO.RAW_HYBRIS_TRADEIN a
             where 1 = 1
               and not exists(
                          select 1
                            from OW_LAO.ODS_HYBRIS_TRADEIN aa
                           where aa.country_Cd         = a.country_Cd
                             and aa.order_id           = a.order_id
                             and aa.line_item_id       = a.line_item_id
                             and aa.file_generated_at >= a.file_generated_at
                   ) 
     );
     
     delete from OW_LAO.TMP_HYBRIS_TRADEIN_DEDUP where dedup != 1; 
                                              
     merge into OW_LAO.ODS_HYBRIS_TRADEIN       a
          using OW_LAO.TMP_HYBRIS_TRADEIN_DEDUP b on b.country_Cd   = a.country_Cd
                                                 and b.order_id     = a.order_id
                                                 and b.line_item_id = a.line_item_id
           when     matched then update
                                       set a."EXCHANGE_BRAND" = b."EXCHANGE_BRAND"
									     , a."EXCHANGE_CATEGORY" = b."EXCHANGE_CATEGORY"
									     , a."EXCHANGE_IMEI" = b."EXCHANGE_IMEI"
									     , a."EXCHANGE_DEVICE_NAME" = b."EXCHANGE_DEVICE_NAME"
									     , a."EXCHANGE_DATE" = b."EXCHANGE_DATE"
									     , a."EXPECTED_MIN_PRICE" = b."EXPECTED_MIN_PRICE"
									     , a."EXPECTED_MAX_PRICE" = b."EXPECTED_MAX_PRICE"
									     , a."EXCHANGE_CURRENCY" = b."EXCHANGE_CURRENCY"
									     , a."EXCHANGE_STATUS" = b."EXCHANGE_STATUS"
									     , a."ASSURED_MIN_PRICE" = b."ASSURED_MIN_PRICE"
									     , a."OFFERED_MAX_PRICE" = b."OFFERED_MAX_PRICE"
									     , a."ADDITIONAL_OFFER_DISCOUNT" = b."ADDITIONAL_OFFER_DISCOUNT"
									     , a."TOTAL_EXCHANGE_AMOUNT" = b."TOTAL_EXCHANGE_AMOUNT"
									     , a."PARENT_SKU" = b."PARENT_SKU"
									     , a."PARENT_PRODUCT_NAME" = b."PARENT_PRODUCT_NAME"
									     , a."PARENT_PRODUCT_TYPE" = b."PARENT_PRODUCT_TYPE"
									     , a."TAXONOMY_NAME" = b."TAXONOMY_NAME"
									     , a."TAXONOMY_PRODUCT_CATEGORY" = b."TAXONOMY_PRODUCT_CATEGORY"
									     , a."TAXONOMY_PRODUCT_FAMILY" = b."TAXONOMY_PRODUCT_FAMILY"
									     , a."IS_PARENT_FLAGSHIP" = b."IS_PARENT_FLAGSHIP"
									     , a."ORDER_SALE_PRICE" = b."ORDER_SALE_PRICE"
									     , a."LINE_ITEM_SALE_PRICE" = b."LINE_ITEM_SALE_PRICE"
									     , a."LINE_ITEM_STATUS" = b."LINE_ITEM_STATUS"
									     , a."EXCHANGE_TYPE" = b."EXCHANGE_TYPE"
									     , a."EXTERNAL_REFERENCE_ID" = b."EXTERNAL_REFERENCE_ID"
									     , a."MTR_TO_SAMSUNG_AMT" = b."MTR_TO_SAMSUNG_AMT"
									     , a."MTR_TO_SAMSUNG_CURRENCY" = b."MTR_TO_SAMSUNG_CURRENCY"
									     , a."VALUE_AMOUNT" = b."VALUE_AMOUNT"
									     , a."CHARGEBACK_ID" = b."CHARGEBACK_ID"
									     , a."CHARGEBACK_DATE_LOCAL" = b."CHARGEBACK_DATE_LOCAL"
									     , a."CHARGEBACK_DATE_LOCAL_FK" = b."CHARGEBACK_DATE_LOCAL_FK"
									     , a."CHARGEBACK_DATE_UTC" = b."CHARGEBACK_DATE_UTC"
									     , a."CHARGEBACK_DATE_UTC_FK" = b."CHARGEBACK_DATE_UTC_FK"
									     , a."CHARGEBACK_ORDER_STATUS" = b."CHARGEBACK_ORDER_STATUS"
									     , a."CHARGEBACK_AMOUNT" = b."CHARGEBACK_AMOUNT"
									     , a."CHARGEBACK_PAYMENT_METHOD" = b."CHARGEBACK_PAYMENT_METHOD"
									     , a."CHARGEBACK_PAYMENT_OPTION" = b."CHARGEBACK_PAYMENT_OPTION"
									     , a."CHARGEBACK_STATUS" = b."CHARGEBACK_STATUS"
									     , a."CHARGEBACK_CREATED_DATE_LOCAL" = b."CHARGEBACK_CREATED_DATE_LOCAL"
									     , a."CHARGEBACK_CREATED_DATE_UTC" = b."CHARGEBACK_CREATED_DATE_UTC"
									     , a."FULFILLER_ORDER_ID" = b."FULFILLER_ORDER_ID"
									     , a."FULFILLER_RESPONSE_STATUS" = b."FULFILLER_RESPONSE_STATUS"
									     , a."PRODUCT_STATUS" = b."PRODUCT_STATUS"
									     , a."FULFILLER_RESPONSE_DATE" = b."FULFILLER_RESPONSE_DATE"
									     , a."EXCHANGE_FULFILLER_RESPONSE_REASON" = b."EXCHANGE_FULFILLER_RESPONSE_REASON"
									     , a."TAXONOMY_PRODUCT_DIVISION_2_DIGIT" = b."TAXONOMY_PRODUCT_DIVISION_2_DIGIT"
									     , a."ORDER_CHANNEL_CODE" = b."ORDER_CHANNEL_CODE"
									     , a."TRADED_IN_RETURN_RECEIVED_DATE" = b."TRADED_IN_RETURN_RECEIVED_DATE"
									     , a."TRADED_IN_RETURN_COMPLETION_DATE" = b."TRADED_IN_RETURN_COMPLETION_DATE"
									     , a."TRADE_IN_VALUE" = b."TRADE_IN_VALUE"
									     , a."ADDITIONAL_TRADE_IN_DISCOUNT" = b."ADDITIONAL_TRADE_IN_DISCOUNT"
                                         , a."FILE_NAME_FROM_FILE"   = B."FILE_NAME_FROM_FILE"
                                         , a.LOAD_DATE                = b.LOAD_DATE
                                         , a.UPDATED_DATETIME         = current_timestamp
                                         , a.FILE_NAME                = b.FILE_NAME 
                                         , a.FILE_LAST_MODIFIED_TIME  = b.FILE_LAST_MODIFIED_TIME 
                                         , a.FILE_NAME_SHORT          = b.FILE_NAME_SHORT 
                                         , a.file_generated_at        = b.file_generated_at 
           when not matched then insert values(
                                                       b."ORDER_DATE_LOCAL" 
												     , b."COUNTRY_CD" 
												     , b."ORDER_ID" 
												     , b."LINE_ITEM_ID" 
												     , b."EXCHANGE_BRAND" 
												     , b."EXCHANGE_CATEGORY" 
												     , b."EXCHANGE_IMEI" 
												     , b."EXCHANGE_DEVICE_NAME" 
												     , b."EXCHANGE_DATE" 
												     , b."EXPECTED_MIN_PRICE" 
												     , b."EXPECTED_MAX_PRICE" 
												     , b."EXCHANGE_CURRENCY" 
												     , b."EXCHANGE_STATUS" 
												     , b."ASSURED_MIN_PRICE" 
												     , b."OFFERED_MAX_PRICE" 
												     , b."ADDITIONAL_OFFER_DISCOUNT" 
												     , b."TOTAL_EXCHANGE_AMOUNT" 
												     , b."PARENT_SKU" 
												     , b."PARENT_PRODUCT_NAME" 
												     , b."PARENT_PRODUCT_TYPE" 
												     , b."TAXONOMY_NAME" 
												     , b."TAXONOMY_PRODUCT_CATEGORY" 
												     , b."TAXONOMY_PRODUCT_FAMILY" 
												     , b."IS_PARENT_FLAGSHIP" 
												     , b."ORDER_SALE_PRICE" 
												     , b."LINE_ITEM_SALE_PRICE" 
												     , b."LINE_ITEM_STATUS" 
												     , b."EXCHANGE_TYPE" 
												     , b."EXTERNAL_REFERENCE_ID" 
												     , b."MTR_TO_SAMSUNG_AMT" 
												     , b."MTR_TO_SAMSUNG_CURRENCY" 
												     , b."VALUE_AMOUNT" 
												     , b."CHARGEBACK_ID" 
												     , b."CHARGEBACK_DATE_LOCAL" 
												     , b."CHARGEBACK_DATE_LOCAL_FK" 
												     , b."CHARGEBACK_DATE_UTC" 
												     , b."CHARGEBACK_DATE_UTC_FK" 
												     , b."CHARGEBACK_ORDER_STATUS" 
												     , b."CHARGEBACK_AMOUNT" 
												     , b."CHARGEBACK_PAYMENT_METHOD" 
												     , b."CHARGEBACK_PAYMENT_OPTION" 
												     , b."CHARGEBACK_STATUS" 
												     , b."CHARGEBACK_CREATED_DATE_LOCAL" 
												     , b."CHARGEBACK_CREATED_DATE_UTC" 
												     , b."FULFILLER_ORDER_ID" 
												     , b."FULFILLER_RESPONSE_STATUS" 
												     , b."PRODUCT_STATUS" 
												     , b."FULFILLER_RESPONSE_DATE" 
												     , b."EXCHANGE_FULFILLER_RESPONSE_REASON" 
												     , b."TAXONOMY_PRODUCT_DIVISION_2_DIGIT" 
												     , b."ORDER_CHANNEL_CODE" 
												     , b."TRADED_IN_RETURN_RECEIVED_DATE" 
												     , b."TRADED_IN_RETURN_COMPLETION_DATE" 
												     , b."TRADE_IN_VALUE" 
												     , b."ADDITIONAL_TRADE_IN_DISCOUNT" 
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