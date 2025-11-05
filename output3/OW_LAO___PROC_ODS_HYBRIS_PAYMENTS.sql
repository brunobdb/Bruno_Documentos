CREATE PROCEDURE OW_LAO.PROC_ODS_HYBRIS_PAYMENTS
 LANGUAGE SQLSCRIPT AS
 BEGIN
       drop table OW_LAO.TMP_HYBRIS_PAYMENTS_DEDUP;
     
     create column table OW_LAO.TMP_HYBRIS_PAYMENTS_DEDUP as (
          
            select row_number()
                        over(partition by country_Cd
                                        , cart_id
                                        , attempt_id
                                 order by file_generated_at desc
                        )                                                               dedup
                 , *
              from OW_LAO.RAW_HYBRIS_PAYMENTS a
             where 1 = 1
               and not exists(
                          select 1
                            from OW_LAO.ODS_HYBRIS_PAYMENTS aa
                           where aa.Country_Cd         = a.Country_Cd
                             and aa.Cart_id            = a.Cart_id
                             and aa.attempt_id         = a.attempt_id
                             and aa.file_generated_at >= a.file_generated_at
                   ) 
     );
     
     delete from OW_LAO.TMP_HYBRIS_PAYMENTS_DEDUP where dedup != 1; 
                                              
     merge into OW_LAO.ODS_HYBRIS_PAYMENTS       a
          using OW_LAO.TMP_HYBRIS_PAYMENTS_DEDUP b on b.Country_Cd = a.Country_Cd
                                                  and b.Cart_id    = a.Cart_id
	                                              and b.attempt_id = a.attempt_id
           when     matched then update
                                      set a."DATE_KEY"  = B."DATE_KEY"
					                    , a."PAYMENT_STATUS"    = B."PAYMENT_STATUS"
					                    , a."ORDER_DATE"    = B."ORDER_DATE"
					                    , a."PO_ID" = B."PO_ID"
					                    , a."TRANSACTION_ID"    = B."TRANSACTION_ID"
					                    , a."PAYMENT_METHOD_NAME"   = B."PAYMENT_METHOD_NAME"
					                    , a."PAYMENT_GATEWAY"   = B."PAYMENT_GATEWAY"
					                    , a."PAYMENT_OPTION_NAME"   = B."PAYMENT_OPTION_NAME"
					                    , a."PAYMENT_CODE"  = B."PAYMENT_CODE"
					                    , a."PLAN_ID"   = B."PLAN_ID"
					                    , a."PROGRAM_TYPE"  = B."PROGRAM_TYPE"
					                    , a."EMI_CALCULATED_ON" = B."EMI_CALCULATED_ON"
					                    , a."INSTALLMENT_AMOUNT"    = B."INSTALLMENT_AMOUNT"
					                    , a."TENURE_UNIT"   = B."TENURE_UNIT"
					                    , a."TENURE_VALUE"  = B."TENURE_VALUE"
					                    , a."TOTAL_AMOUNT"  = B."TOTAL_AMOUNT"
					                    , a."PG_MESSAGE"    = B."PG_MESSAGE"
					                    , a."TRANSACTION_CURRENCY"  = B."TRANSACTION_CURRENCY"
					                    , a."PLATFORM"  = B."PLATFORM"
					                    , a."ORDER_CHANNEL_CODE"    = B."ORDER_CHANNEL_CODE"
					                    , a."STORE_ID"  = B."STORE_ID"
					                    , a."STORE_NAME"    = B."STORE_NAME"
					                    , a."STORE_TYPE"    = B."STORE_TYPE"
					                    , a."CREATED_TIME_UTC"  = B."CREATED_TIME_UTC"
					                    , a."CREATED_TIME_LOCAL"    = B."CREATED_TIME_LOCAL"
					                    , a."IS_UPGRADE"    = B."IS_UPGRADE"
					                    , a."IS_TRADE_IN"   = B."IS_TRADE_IN"
					                    , a."BILLING_INFO_ADDRESS_LANDMARK" = B."BILLING_INFO_ADDRESS_LANDMARK"
					                    , a."BILLING_INFO_ALTERNATE_PHONE"  = B."BILLING_INFO_ALTERNATE_PHONE"
					                    , a."BILLING_INFO_BUSINESS_NAME"    = B."BILLING_INFO_BUSINESS_NAME"
					                    , a."BILLING_INFO_CITY" = B."BILLING_INFO_CITY"
					                    , a."BILLING_INFO_COUNTRY"  = B."BILLING_INFO_COUNTRY"
					                    , a."BILLING_INFO_EMAIL"    = B."BILLING_INFO_EMAIL"
					                    , a."BILLING_INFO_FIRST_NAME"   = B."BILLING_INFO_FIRST_NAME"
					                    , a."BILLING_INFO_GSTIN"    = B."BILLING_INFO_GSTIN"
					                    , a."BILLING_INFO_IS_PRIMARY_ADDRESS"   = B."BILLING_INFO_IS_PRIMARY_ADDRESS"
					                    , a."BILLING_INFO_LAST_NAME"    = B."BILLING_INFO_LAST_NAME"
					                    , a."BILLING_INFO_LINE_1"   = B."BILLING_INFO_LINE_1"
					                    , a."BILLING_INFO_LINE_2"   = B."BILLING_INFO_LINE_2"
					                    , a."BILLING_INFO_PHONE"    = B."BILLING_INFO_PHONE"
					                    , a."BILLING_INFO_RELATION" = B."BILLING_INFO_RELATION"
					                    , a."BILLING_INFO_STATE"    = B."BILLING_INFO_STATE"
					                    , a."BILLING_INFO_ZIPCODE"  = B."BILLING_INFO_ZIPCODE"
					                    , a."ORDER_PROGRAM_TYPE"    = B."ORDER_PROGRAM_TYPE"
					                    , a."SHIPPING_INFO_ADDRESS_LANDMARK"    = B."SHIPPING_INFO_ADDRESS_LANDMARK"
					                    , a."SHIPPING_INFO_ALTERNATE_PHONE" = B."SHIPPING_INFO_ALTERNATE_PHONE"
					                    , a."SHIPPING_INFO_CITY"    = B."SHIPPING_INFO_CITY"
					                    , a."SHIPPING_INFO_COUNTRY" = B."SHIPPING_INFO_COUNTRY"
					                    , a."SHIPPING_INFO_EMAIL"   = B."SHIPPING_INFO_EMAIL"
					                    , a."SHIPPING_INFO_FIRST_NAME"  = B."SHIPPING_INFO_FIRST_NAME"
					                    , a."SHIPPING_INFO_IS_PRIMARY_ADDRESS"  = B."SHIPPING_INFO_IS_PRIMARY_ADDRESS"
					                    , a."SHIPPING_INFO_LAST_NAME"   = B."SHIPPING_INFO_LAST_NAME"
					                    , a."SHIPPING_INFO_LINE_1"  = B."SHIPPING_INFO_LINE_1"
					                    , a."SHIPPING_INFO_LINE_2"  = B."SHIPPING_INFO_LINE_2"
					                    , a."SHIPPING_INFO_PHONE"   = B."SHIPPING_INFO_PHONE"
					                    , a."SHIPPING_INFO_RELATION"    = B."SHIPPING_INFO_RELATION"
					                    , a."SHIPPING_INFO_STATE"   = B."SHIPPING_INFO_STATE"
					                    , a."SHIPPING_INFO_ZIPCODE" = B."SHIPPING_INFO_ZIPCODE"
					                    , a."FILE_NAME_FROM_FILE"   = B."FILE_NAME_FROM_FILE"
                                        , a.LOAD_DATE                = b.LOAD_DATE
                                        , a.UPDATED_DATETIME             = current_timestamp
                                        , a.FILE_NAME                = b.FILE_NAME 
                                        , a.FILE_LAST_MODIFIED_TIME  = b.FILE_LAST_MODIFIED_TIME 
                                        , a.FILE_NAME_SHORT          = b.FILE_NAME_SHORT 
                                        , a.file_generated_at        = b.file_generated_at 
           when not matched then insert values(
		                                          B."COUNTRY_CD"
		                                        , B."CART_ID"
		                                        , B."DATE_KEY"
		                                        , B."PAYMENT_STATUS"
		                                        , B."ORDER_DATE"
		                                        , B."PO_ID"
		                                        , B."TRANSACTION_ID"
		                                        , B."PAYMENT_METHOD_NAME"
		                                        , B."PAYMENT_GATEWAY"
		                                        , B."PAYMENT_OPTION_NAME"
		                                        , B."PAYMENT_CODE"
		                                        , B."PLAN_ID"
		                                        , B."PROGRAM_TYPE"
		                                        , B."EMI_CALCULATED_ON"
		                                        , B."INSTALLMENT_AMOUNT"
		                                        , B."TENURE_UNIT"
		                                        , B."TENURE_VALUE"
		                                        , B."TOTAL_AMOUNT"
		                                        , B."PG_MESSAGE"
		                                        , B."TRANSACTION_CURRENCY"
		                                        , B."PLATFORM"
		                                        , B."ORDER_CHANNEL_CODE"
		                                        , B."STORE_ID"
		                                        , B."STORE_NAME"
		                                        , B."STORE_TYPE"
		                                        , B."CREATED_TIME_UTC"
		                                        , B."CREATED_TIME_LOCAL"
		                                        , B."IS_UPGRADE"
		                                        , B."IS_TRADE_IN"
		                                        , B."ATTEMPT_ID"
		                                        , B."BILLING_INFO_ADDRESS_LANDMARK"
		                                        , B."BILLING_INFO_ALTERNATE_PHONE"
		                                        , B."BILLING_INFO_BUSINESS_NAME"
		                                        , B."BILLING_INFO_CITY"
		                                        , B."BILLING_INFO_COUNTRY"
		                                        , B."BILLING_INFO_EMAIL"
		                                        , B."BILLING_INFO_FIRST_NAME"
		                                        , B."BILLING_INFO_GSTIN"
		                                        , B."BILLING_INFO_IS_PRIMARY_ADDRESS"
		                                        , B."BILLING_INFO_LAST_NAME"
		                                        , B."BILLING_INFO_LINE_1"
		                                        , B."BILLING_INFO_LINE_2"
		                                        , B."BILLING_INFO_PHONE"
		                                        , B."BILLING_INFO_RELATION"
		                                        , B."BILLING_INFO_STATE"
		                                        , B."BILLING_INFO_ZIPCODE"
		                                        , B."ORDER_PROGRAM_TYPE"
		                                        , B."SHIPPING_INFO_ADDRESS_LANDMARK"
		                                        , B."SHIPPING_INFO_ALTERNATE_PHONE"
		                                        , B."SHIPPING_INFO_CITY"
		                                        , B."SHIPPING_INFO_COUNTRY"
		                                        , B."SHIPPING_INFO_EMAIL"
		                                        , B."SHIPPING_INFO_FIRST_NAME"
		                                        , B."SHIPPING_INFO_IS_PRIMARY_ADDRESS"
		                                        , B."SHIPPING_INFO_LAST_NAME"
		                                        , B."SHIPPING_INFO_LINE_1"
		                                        , B."SHIPPING_INFO_LINE_2"
		                                        , B."SHIPPING_INFO_PHONE"
		                                        , B."SHIPPING_INFO_RELATION"
		                                        , B."SHIPPING_INFO_STATE"
		                                        , B."SHIPPING_INFO_ZIPCODE"
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