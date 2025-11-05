CREATE PROCEDURE OW_LAO.PROC_ODS_HYBRIS_REFUNDS
 LANGUAGE SQLSCRIPT AS
 BEGIN
       drop table OW_LAO.TMP_HYBRIS_REFUNDS_DEDUP;
     
     create column table OW_LAO.TMP_HYBRIS_REFUNDS_DEDUP as (
          
            select row_number()
                        over(partition by country_Cd
                                        , cart_id
                                        , order_id
                                 order by file_generated_at desc
                        )                                                               dedup
                 , *
              from OW_LAO.RAW_HYBRIS_REFUNDS a
             where 1 = 1
               and not exists(
                          select 1
                            from OW_LAO.ODS_HYBRIS_REFUNDS aa
                           where aa.country_Cd         = a.country_Cd
                             and aa.cart_id            = a.cart_id
                             and aa.order_id           = a.order_id
                             and aa.file_generated_at >= a.file_generated_at
                   ) 
     );
     
     delete from OW_LAO.TMP_HYBRIS_REFUNDS_DEDUP where dedup != 1; 
                                              
     merge into OW_LAO.ODS_HYBRIS_REFUNDS       a
          using OW_LAO.TMP_HYBRIS_REFUNDS_DEDUP b on b.country_Cd   = a.country_Cd
                                                 and b.cart_id      = a.cart_id
                                                 and b.order_id     = a.order_id
           when     matched then update
                                   set a."REFUND_STATUS" = b."REFUND_STATUS"
								     , a."ORDER_DATE" = b."ORDER_DATE"
								     , a."PO_ID" = b."PO_ID"
								     , a."ORDER_TYPE" = b."ORDER_TYPE"
								     , a."TRANSACTION_ID" = b."TRANSACTION_ID"
								     , a."PAYMENT_METHOD_NAME" = b."PAYMENT_METHOD_NAME"
								     , a."PAYMENT_GATEWAY" = b."PAYMENT_GATEWAY"
								     , a."PAYMENT_OPTION_NAME" = b."PAYMENT_OPTION_NAME"
								     , a."PAYMENT_CODE" = b."PAYMENT_CODE"
								     , a."PLAN_ID" = b."PLAN_ID"
								     , a."PROGRAM_TYPE" = b."PROGRAM_TYPE"
								     , a."EMI_CALCULATED_ON" = b."EMI_CALCULATED_ON"
								     , a."INSTALLMENT_AMOUNT" = b."INSTALLMENT_AMOUNT"
								     , a."TENURE_UNIT" = b."TENURE_UNIT"
								     , a."TENURE_VALUE" = b."TENURE_VALUE"
								     , a."TOTAL_AMOUNT" = b."TOTAL_AMOUNT"
								     , a."PG_MESSAGE" = b."PG_MESSAGE"
								     , a."TRANSACTION_AMOUNT" = b."TRANSACTION_AMOUNT"
								     , a."TRANSACTION_CURRENCY" = b."TRANSACTION_CURRENCY"
								     , a."IS_FINANCING" = b."IS_FINANCING"
								     , a."PLATFORM" = b."PLATFORM"
								     , a."ORDER_PROGRAM_TYPE" = b."ORDER_PROGRAM_TYPE"
								     , a."ORDER_CHANNEL_CODE" = b."ORDER_CHANNEL_CODE"
								     , a."STORE_ID" = b."STORE_ID"
								     , a."STORE_NAME" = b."STORE_NAME"
								     , a."STORE_TYPE" = b."STORE_TYPE"
								     , a."CREATED_TIME_UTC" = b."CREATED_TIME_UTC"
								     , a."CREATED_TIME_LOCAL" = b."CREATED_TIME_LOCAL"
								     , a."CREATED_DATE_LOCAL_KEY" = b."CREATED_DATE_LOCAL_KEY"
								     , a."IS_UPGRADE" = b."IS_UPGRADE"
								     , a."IS_TRADE_IN" = b."IS_TRADE_IN"
								     , a."PAYMENT_MODE" = b."PAYMENT_MODE"
								     , a."REFUND_TYPE" = b."REFUND_TYPE"
								     , a."FILE_NAME_FROM_FILE" = b."FILE_NAME_FROM_FILE"
								     , a."LOAD_DATE" = b."LOAD_DATE"
								     , a."FILE_NAME" = b."FILE_NAME"
								     , a."FILE_LAST_MODIFIED_TIME" = b."FILE_LAST_MODIFIED_TIME"
								     , a."FILE_NAME_SHORT" = b."FILE_NAME_SHORT"
								     , a."INSERTED_DATE" = current_timestamp
								     , a."FILE_GENERATED_AT" = b."FILE_GENERATED_AT"
                                     , a."UPDATED_DATETIME" = current_timestamp
           when not matched then insert values(
                                                   b."COUNTRY_CD"
											     , b."CART_ID"
											     , b."REFUND_STATUS"
											     , b."ORDER_DATE"
											     , b."ORDER_ID"
											     , b."PO_ID"
											     , b."ORDER_TYPE"
											     , b."TRANSACTION_ID"
											     , b."PAYMENT_METHOD_NAME"
											     , b."PAYMENT_GATEWAY"
											     , b."PAYMENT_OPTION_NAME"
											     , b."PAYMENT_CODE"
											     , b."PLAN_ID"
											     , b."PROGRAM_TYPE"
											     , b."EMI_CALCULATED_ON"
											     , b."INSTALLMENT_AMOUNT"
											     , b."TENURE_UNIT"
											     , b."TENURE_VALUE"
											     , b."TOTAL_AMOUNT"
											     , b."PG_MESSAGE"
											     , b."TRANSACTION_AMOUNT"
											     , b."TRANSACTION_CURRENCY"
											     , b."IS_FINANCING"
											     , b."PLATFORM"
											     , b."ORDER_PROGRAM_TYPE"
											     , b."ORDER_CHANNEL_CODE"
											     , b."STORE_ID"
											     , b."STORE_NAME"
											     , b."STORE_TYPE"
											     , b."CREATED_TIME_UTC"
											     , b."CREATED_TIME_LOCAL"
											     , b."CREATED_DATE_LOCAL_KEY"
											     , b."IS_UPGRADE"
											     , b."IS_TRADE_IN"
											     , b."PAYMENT_MODE"
											     , b."REFUND_TYPE"
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