create PROCEDURE OW_LAO.PROC_ODS_HYBRIS_OFFERS
 LANGUAGE SQLSCRIPT AS
 BEGIN
       drop table OW_LAO.TMP_HYBRIS_OFFERS_DEDUP;
     
     create column table OW_LAO.TMP_HYBRIS_OFFERS_DEDUP as (
          
            select row_number()
                        over(partition by country_Cd
                                        , order_id
                                        , line_item_id
                                        , offer_id
                                 order by file_generated_at desc
                        )                                                               dedup
                 , *
              from OW_LAO.RAW_HYBRIS_OFFERS a
             where 1 = 1
               and not exists(
                          select 1
                            from OW_LAO.ODS_HYBRIS_OFFERS aa
                           where aa.country_Cd         = a.country_Cd
                             and aa.order_id           = a.order_id
                             and aa.line_item_id       = a.line_item_id
                             and aa.offer_id           = a.offer_id
                             and aa.file_generated_at >= a.file_generated_at
                   ) 
     );
     
     delete from OW_LAO.TMP_HYBRIS_OFFERS_DEDUP where dedup != 1; 
                                              
     merge into OW_LAO.ODS_HYBRIS_OFFERS       a
          using OW_LAO.TMP_HYBRIS_OFFERS_DEDUP b on b.country_Cd   = a.country_Cd
                                                and b.order_id     = a.order_id
                                                and b.line_item_id = a.line_item_id
                                                and b.offer_id     = a.offer_id
           when     matched then update
                                   set a."LEVEL" = b."LEVEL"
								     , a."ORDER_ID" = b."ORDER_ID"
								     , a."COUNTRY_CD" = b."COUNTRY_CD"
								     , a."ORDER_TIME_UTC" = b."ORDER_TIME_UTC"
								     , a."ORDER_TIME_LOCAL" = b."ORDER_TIME_LOCAL"
								     , a."EPP_PLAN_NAME" = b."EPP_PLAN_NAME"
								     , a."CUSTOMER_LOGIN_ID" = b."CUSTOMER_LOGIN_ID"
								     , a."CUSTOMER_EMAIL_ID" = b."CUSTOMER_EMAIL_ID"
								     , a."CUSTOMER_MOBILE_NUMBER" = b."CUSTOMER_MOBILE_NUMBER"
								     , a."CUSTOMER_USERID_TYPE" = b."CUSTOMER_USERID_TYPE"
								     , a."PLATFORM" = b."PLATFORM"
								     , a."ORDER_STATUS" = b."ORDER_STATUS"
								     , a."ORDER_FRAUD_STATUS" = b."ORDER_FRAUD_STATUS"
								     , a."LINE_ITEM_STATUS" = b."LINE_ITEM_STATUS"
								     , a."ORDER_CLONED_FROM" = b."ORDER_CLONED_FROM"
								     , a."ORDER_CHANNEL_CODE" = b."ORDER_CHANNEL_CODE"
								     , a."PO_ID" = b."PO_ID"
								     , a."SALES_APP" = b."SALES_APP"
								     , a."LINE_ITEM_ID" = b."LINE_ITEM_ID"
								     , a."SKU_MEMORY" = b."SKU_MEMORY"
								     , a."PRODUCT_FAMILY" = b."PRODUCT_FAMILY"
								     , a."PRODUCT_CATEGORY" = b."PRODUCT_CATEGORY"
								     , a."COLOR" = b."COLOR"
								     , a."PRODUCT_NAME" = b."PRODUCT_NAME"
								     , a."PRODUCT_TYPE" = b."PRODUCT_TYPE"
								     , a."PRODUCT_MODEL_CODE" = b."PRODUCT_MODEL_CODE"
								     , a."PRODUCT_MODEL_NAME" = b."PRODUCT_MODEL_NAME"
								     , a."SHORT_DESCRIPTION" = b."SHORT_DESCRIPTION"
								     , a."LONG_DESCRIPTION" = b."LONG_DESCRIPTION"
								     , a."FAMILY_ID" = b."FAMILY_ID"
								     , a."SKU" = b."SKU"
								     , a."EAN" = b."EAN"
								     , a."IS_ASSURANT_SKU" = b."IS_ASSURANT_SKU"
								     , a."IS_ACCESSORY" = b."IS_ACCESSORY"
								     , a."IS_FINANCING_ELIGIBLE" = b."IS_FINANCING_ELIGIBLE"
								     , a."IS_FLAGSHIP" = b."IS_FLAGSHIP"
								     , a."TXN_SALES_AMOUNT" = b."TXN_SALES_AMOUNT"
								     , a."TXN_SALE_CURRENCY" = b."TXN_SALE_CURRENCY"
								     , a."TXN_OFFER_DISCOUNT_AMOUNT" = b."TXN_OFFER_DISCOUNT_AMOUNT"
								     , a."COUPON_CODE" = b."COUPON_CODE"
								     , a."CAMPAIGN_ID" = b."CAMPAIGN_ID"
								     , a."OFFER_ID" = b."OFFER_ID"
								     , a."OFFER_NAME" = b."OFFER_NAME"
								     , a."OFFER_TYPE" = b."OFFER_TYPE"
								     , a."OFFER_START_DATE" = b."OFFER_START_DATE"
								     , a."OFFER_END_DATE" = b."OFFER_END_DATE"
								     , a."SALES_PITCH" = b."SALES_PITCH"
								     , a."OFFER_STATUS" = b."OFFER_STATUS"
								     , a."COUNTRY_GROUP" = b."COUNTRY_GROUP"
								     , a."PROGRAM_TYPE" = b."PROGRAM_TYPE"
								     , a."STORE_ID" = b."STORE_ID"
								     , a."STORE_NAME" = b."STORE_NAME"
								     , a."STORE_TYPE" = b."STORE_TYPE"
								     , a."ORDER_TYPE" = b."ORDER_TYPE"
								     , a."ORDER_SALE_AMOUNT" = b."ORDER_SALE_AMOUNT"
								     , a."TAXONOMY_PRODUCT_DIVISION_2_DIGIT" = b."TAXONOMY_PRODUCT_DIVISION_2_DIGIT"
                                     , a."FILE_NAME_FROM_FILE" = b."FILE_NAME_FROM_FILE"
                                     , a."LOAD_DATE" = b."LOAD_DATE"
                                     , a."FILE_NAME" = b."FILE_NAME"
                                     , a."FILE_LAST_MODIFIED_TIME" = b."FILE_LAST_MODIFIED_TIME"
                                     , a."FILE_NAME_SHORT" = b."FILE_NAME_SHORT"
                                     , a."FILE_GENERATED_AT" = b."FILE_GENERATED_AT"
                                     , a."UPDATED_DATETIME" = current_timestamp
           when not matched then insert values(
                                                       b."LEVEL"
												     , b."ORDER_ID"
												     , b."COUNTRY_CD"
												     , b."ORDER_TIME_UTC"
												     , b."ORDER_TIME_LOCAL"
												     , b."EPP_PLAN_NAME"
												     , b."CUSTOMER_LOGIN_ID"
												     , b."CUSTOMER_EMAIL_ID"
												     , b."CUSTOMER_MOBILE_NUMBER"
												     , b."CUSTOMER_USERID_TYPE"
												     , b."PLATFORM"
												     , b."ORDER_STATUS"
												     , b."ORDER_FRAUD_STATUS"
												     , b."LINE_ITEM_STATUS"
												     , b."ORDER_CLONED_FROM"
												     , b."ORDER_CHANNEL_CODE"
												     , b."PO_ID"
												     , b."SALES_APP"
												     , b."LINE_ITEM_ID"
												     , b."SKU_MEMORY"
												     , b."PRODUCT_FAMILY"
												     , b."PRODUCT_CATEGORY"
												     , b."COLOR"
												     , b."PRODUCT_NAME"
												     , b."PRODUCT_TYPE"
												     , b."PRODUCT_MODEL_CODE"
												     , b."PRODUCT_MODEL_NAME"
												     , b."SHORT_DESCRIPTION"
												     , b."LONG_DESCRIPTION"
												     , b."FAMILY_ID"
												     , b."SKU"
												     , b."EAN"
												     , b."IS_ASSURANT_SKU"
												     , b."IS_ACCESSORY"
												     , b."IS_FINANCING_ELIGIBLE"
												     , b."IS_FLAGSHIP"
												     , b."TXN_SALES_AMOUNT"
												     , b."TXN_SALE_CURRENCY"
												     , b."TXN_OFFER_DISCOUNT_AMOUNT"
												     , b."COUPON_CODE"
												     , b."CAMPAIGN_ID"
												     , b."OFFER_ID"
												     , b."OFFER_NAME"
												     , b."OFFER_TYPE"
												     , b."OFFER_START_DATE"
												     , b."OFFER_END_DATE"
												     , b."SALES_PITCH"
												     , b."OFFER_STATUS"
												     , b."COUNTRY_GROUP"
												     , b."PROGRAM_TYPE"
												     , b."STORE_ID"
												     , b."STORE_NAME"
												     , b."STORE_TYPE"
												     , b."ORDER_TYPE"
												     , b."ORDER_SALE_AMOUNT"
												     , b."TAXONOMY_PRODUCT_DIVISION_2_DIGIT"
												     , b."FILE_NAME_FROM_FILE"
												     , b."LOAD_DATE"
												     , b."FILE_NAME"
												     , b."FILE_LAST_MODIFIED_TIME"
												     , b."FILE_NAME_SHORT"
												     , current_timestamp
												     , b."FILE_GENERATED_AT"
												     , null
                                         );
                                              
   end