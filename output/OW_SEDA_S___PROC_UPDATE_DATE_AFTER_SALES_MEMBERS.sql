CREATE PROCEDURE OW_SEDA_S.PROC_UPDATE_DATE_AFTER_SALES_MEMBERS
LANGUAGE SQLSCRIPT as
BEGIN
UPDATE "OW_SEDA_S"."TMP_DATA_API_AFTER_SALES_DETAIL_MEMBERS" 
SET
  APPROVED_DATE = (CASE WHEN STATUS_NAME_1 = 'approved' 
  				THEN DATE_1 
  			WHEN STATUS_NAME_2 = 'approved' 
  				THEN DATE_2 
  			WHEN STATUS_NAME_3 = 'approved' 
  				THEN DATE_3 
  			WHEN STATUS_NAME_4 = 'approved' 
  				THEN DATE_4 
  			WHEN STATUS_NAME_5 = 'approved' 
  				THEN DATE_5 
  			WHEN STATUS_NAME_6 = 'approved' 
  				THEN DATE_6 
  			WHEN STATUS_NAME_7 = 'approved' 
  				THEN DATE_7 
  			WHEN STATUS_NAME_8 = 'approved' 
  				THEN DATE_8 
  			WHEN STATUS_NAME_9 = 'approved' 
  				THEN DATE_9 
  			WHEN STATUS_NAME_10 = 'approved' 
  				THEN DATE_10
  			WHEN STATUS_NAME_11 = 'approved' 
  				THEN DATE_11
  			WHEN STATUS_NAME_12 = 'approved' 
  				THEN DATE_12
  				ELSE NULL 
  		END),
  AWAITING_DATE = (CASE WHEN STATUS_NAME_1 = 'awaiting' 
  				THEN DATE_1 
  			WHEN STATUS_NAME_2 = 'awaiting' 
  				THEN DATE_2 
  			WHEN STATUS_NAME_3 = 'awaiting' 
  				THEN DATE_3 
  			WHEN STATUS_NAME_4 = 'awaiting' 
  				THEN DATE_4 
  			WHEN STATUS_NAME_5 = 'awaiting' 
  				THEN DATE_5 
  			WHEN STATUS_NAME_6 = 'awaiting' 
  				THEN DATE_6 
  			WHEN STATUS_NAME_7 = 'awaiting' 
  				THEN DATE_7 
  			WHEN STATUS_NAME_8 = 'awaiting' 
  				THEN DATE_8 
  			WHEN STATUS_NAME_9 = 'awaiting' 
  				THEN DATE_9 
  			WHEN STATUS_NAME_10 = 'awaiting' 
  				THEN DATE_10
  			WHEN STATUS_NAME_11 = 'awaiting' 
  				THEN DATE_11
  			WHEN STATUS_NAME_12 = 'awaiting' 
  				THEN DATE_12
  				ELSE NULL 
  		END),
  SHIPPED_DATE = (CASE WHEN STATUS_NAME_1 = 'shipped' 
  				THEN DATE_1 
  			WHEN STATUS_NAME_2 = 'shipped' 
  				THEN DATE_2 
  			WHEN STATUS_NAME_3 = 'shipped' 
  				THEN DATE_3 
  			WHEN STATUS_NAME_4 = 'shipped' 
  				THEN DATE_4 
  			WHEN STATUS_NAME_5 = 'shipped' 
  				THEN DATE_5 
  			WHEN STATUS_NAME_6 = 'shipped' 
  				THEN DATE_6 
  			WHEN STATUS_NAME_7 = 'shipped' 
  				THEN DATE_7 
  			WHEN STATUS_NAME_8 = 'shipped' 
  				THEN DATE_8 
  			WHEN STATUS_NAME_9 = 'shipped' 
  				THEN DATE_9 
  			WHEN STATUS_NAME_10 = 'shipped' 
  				THEN DATE_10
  			WHEN STATUS_NAME_11 = 'shipped' 
  				THEN DATE_11
  			WHEN STATUS_NAME_12 = 'shipped' 
  				THEN DATE_12
  				ELSE NULL 
  		END),
  DELIVERED_DATE = (CASE WHEN STATUS_NAME_1 = 'delivered' 
  				THEN DATE_1 
  			WHEN STATUS_NAME_2 = 'delivered' 
  				THEN DATE_2 
  			WHEN STATUS_NAME_3 = 'delivered' 
  				THEN DATE_3 
  			WHEN STATUS_NAME_4 = 'delivered' 
  				THEN DATE_4 
  			WHEN STATUS_NAME_5 = 'delivered' 
  				THEN DATE_5 
  			WHEN STATUS_NAME_6 = 'delivered' 
  				THEN DATE_6 
  			WHEN STATUS_NAME_7 = 'delivered' 
  				THEN DATE_7 
  			WHEN STATUS_NAME_8 = 'delivered' 
  				THEN DATE_8 
  			WHEN STATUS_NAME_9 = 'delivered' 
  				THEN DATE_9 
  			WHEN STATUS_NAME_10 = 'delivered' 
  				THEN DATE_10
  			WHEN STATUS_NAME_11 = 'delivered' 
  				THEN DATE_11
  			WHEN STATUS_NAME_12 = 'delivered' 
  				THEN DATE_12
  				ELSE NULL 
  		END),
  RECEIVED_DATE = (CASE WHEN STATUS_NAME_1 = 'received' 
  				THEN DATE_1 
  			WHEN STATUS_NAME_2 = 'received' 
  				THEN DATE_2 
  			WHEN STATUS_NAME_3 = 'received' 
  				THEN DATE_3 
  			WHEN STATUS_NAME_4 = 'received' 
  				THEN DATE_4 
  			WHEN STATUS_NAME_5 = 'received' 
  				THEN DATE_5 
  			WHEN STATUS_NAME_6 = 'received' 
  				THEN DATE_6 
  			WHEN STATUS_NAME_7 = 'received' 
  				THEN DATE_7 
  			WHEN STATUS_NAME_8 = 'received' 
  				THEN DATE_8 
  			WHEN STATUS_NAME_9 = 'received' 
  				THEN DATE_9 
  			WHEN STATUS_NAME_10 = 'received' 
  				THEN DATE_10
  			WHEN STATUS_NAME_11 = 'received' 
  				THEN DATE_11
  			WHEN STATUS_NAME_12 = 'received' 
  				THEN DATE_12
  				ELSE NULL 
  		END),
  CANCELED_DATE = (CASE WHEN STATUS_NAME_1 = 'canceled' 
  				THEN DATE_1 
  			WHEN STATUS_NAME_2 = 'canceled' 
  				THEN DATE_2 
  			WHEN STATUS_NAME_3 = 'canceled' 
  				THEN DATE_3 
  			WHEN STATUS_NAME_4 = 'canceled' 
  				THEN DATE_4 
  			WHEN STATUS_NAME_5 = 'canceled' 
  				THEN DATE_5 
  			WHEN STATUS_NAME_6 = 'canceled' 
  				THEN DATE_6 
  			WHEN STATUS_NAME_7 = 'canceled' 
  				THEN DATE_7 
  			WHEN STATUS_NAME_8 = 'canceled' 
  				THEN DATE_8 
  			WHEN STATUS_NAME_9 = 'canceled' 
  				THEN DATE_9 
  			WHEN STATUS_NAME_10 = 'canceled' 
  				THEN DATE_10
  			WHEN STATUS_NAME_11 = 'canceled' 
  				THEN DATE_11
  			WHEN STATUS_NAME_12 = 'canceled' 
  				THEN DATE_12
  				ELSE NULL 
  		END),
  SHIPPING_FAILED_DATE = (CASE WHEN STATUS_NAME_1 = 'shipping_failed' 
  				THEN DATE_1 
  			WHEN STATUS_NAME_2 = 'shipping_failed' 
  				THEN DATE_2 
  			WHEN STATUS_NAME_3 = 'shipping_failed' 
  				THEN DATE_3 
  			WHEN STATUS_NAME_4 = 'shipping_failed' 
  				THEN DATE_4 
  			WHEN STATUS_NAME_5 = 'shipping_failed' 
  				THEN DATE_5 
  			WHEN STATUS_NAME_6 = 'shipping_failed' 
  				THEN DATE_6 
  			WHEN STATUS_NAME_7 = 'shipping_failed' 
  				THEN DATE_7 
  			WHEN STATUS_NAME_8 = 'shipping_failed' 
  				THEN DATE_8 
  			WHEN STATUS_NAME_9 = 'shipping_failed' 
  				THEN DATE_9 
  			WHEN STATUS_NAME_10 = 'shipping_failed' 
  				THEN DATE_10
  			WHEN STATUS_NAME_11 = 'shipping_failed' 
  				THEN DATE_11
  			WHEN STATUS_NAME_12 = 'shipping_failed' 
  				THEN DATE_12
  				ELSE NULL 
  		END)
;
END