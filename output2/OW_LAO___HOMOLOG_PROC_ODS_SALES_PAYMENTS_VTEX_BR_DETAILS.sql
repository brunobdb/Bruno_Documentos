CREATE PROCEDURE OW_LAO.HOMOLOG_PROC_ODS_SALES_PAYMENTS_VTEX_BR_DETAILS
			AS
			BEGIN
			
			TRUNCATE TABLE OW_LAO.TMP_SALES_PAYMENTS_VTEX_BR_DETAILS_HOMOLOG;
	
INSERT INTO OW_LAO.TMP_SALES_PAYMENTS_VTEX_BR_DETAILS_HOMOLOG
SELECT DISTINCT
    NULL AS ID,
    CURRENT_TIMESTAMP AS INSERT_TIMESTAMP,
    CURRENT_TIMESTAMP AS UPDATED_TIMESTAMP,
    CAST(A.PO_DATE AS DATE) AS PO_DATE,
    A.PODATE_MONTH AS PO_MONTH,
    A.PODATE_YEAR AS PO_YEAR,
    CAST(LEFT(A.PO_HOUR, 2) AS INT) AS PO_HOUR,
    A.SUBSIDIARY AS PAY_SUBSIDIARY,
    C.KEY_TRANSACTION_ID AS PAY_CODE,
    C.PAYMENT_ID AS PAY_ID,
    CAST(A.PO_DATE AS DATE) AS PAY_DATE, 
    A.PODATE_MONTH AS PAY_MONTH,
    A.PODATE_YEAR AS PAY_YEAR,
    CAST(LEFT(A.PO_HOUR, 2) AS INT) AS PAY_HOUR,
    C.STATUS AS PAY_STATUS,
    A.PO_PAYMENT_REMARK AS PAY_DETAIL,
    C."SOURCE" AS PAY_GATEWAY_CODE, 
    A.PAYMENT_TYPE,
    C."SOURCE"             AS PAY_GATEWAY,
    CAST(NULL AS DECIMAL)  AS REVENUE_LOCAL,
    A.PO_ORDERID AS PAY_ORDERID,
    LOWER(A.PO_STORENAME) AS PAY_STORENAME,
    CAST(NULL AS VARCHAR(255)) AS POSTORETYPE,
    A.PO_DEVICETYPE,
    COALESCE(A.PO_INTERNAL_STATUS, 'incomplete') AS PO_STATUS,
    CAST(NULL AS VARCHAR(255)) AS ORDER_STATUS_TYPE,
    A.CURRENCY,
    C."DATE"       AS PO_ORDER_LASTMODIFYDATE,
    A.PO_STORENAME AS POSTORENAME,
    A.CHANNEL,
    A.BIZ_TYPE,
    A.AUDIENCE_TYPE,
    A.SUBSIDIARY ,
    CAST(NULL AS DECIMAL)  AS PE_AMOUNT,
    CAST(NULL AS DECIMAL)  AS REVENU_USD,
    A.PO_ORDERID, 
    CAST(NULL AS VARCHAR(255)) AS PAY_ACTION,
    CAST(NULL AS VARCHAR(255)) AS PAY_RESULT,
    CAST(NULL AS VARCHAR(255)) AS PAY_DESCRIPTION,
    C.MESSAGE AS PAY_MESSAGE,
    COALESCE(A.PO_INTERNAL_STATUS, 'incomplete') AS PO_INTERNAL_STATUS, 
    A.PAYMENT_TYPE AS PO_PAYMENT_TYPE,
    C."SOURCE" AS PO_PAYMENTPROVIDER,
    A.PAYMENT_CARD_BRAND AS PAYMENT_CARD_BRAND,
    A.PO_STATUS AS PO_STATUS_CT,
    CAST(NULL AS VARCHAR(255)) AS FUNNEL_STATUS,
    cast(null as varchar(255))           as PAY_GATEWAY_STATUS,
    cast(null as varchar(255))           as PO_PAYMENT_TYPE_STATUS,
    'VTEX_BR'				             as PO_PLATAFORM_DATASOURCE,
    C."DATE" AS DATASOURCE_ORIGIN_TIMESTAMP,
    ROW_NUMBER() OVER (
               PARTITION BY C.KEY_TRANSACTION_ID, B.ORDER_ID
               ORDER BY C."DATE" DESC,B.VALUE DESC ) AS DEDUP
FROM OW_LAO.ODS_SALES_CONTROL_TOWER_TABLE A
JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER_PAYMENT B ON B.ORDER_ID = A.PO_ORDERID 
JOIN OW_LAO.RAW_VTEX_PAYMENTS C ON C.KEY_TRANSACTION_ID = B.TRANSACTION_ID
                               AND C.PAYMENT_ID         = B.PAYMENT_ID 
WHERE A.CLIENT_SUBSIDIARY_ID = 6
  AND A.PO_PLATAFORM_DATASOURCE = 'u_prj_ecom.raw_vtex_ssg_br_shop_sales_order'
  AND CAST(A.PO_DATE AS DATE) >= '2025-04-13'
  --AND PO_ORDERID = '1520309640844-01'
  AND NOT EXISTS (
      SELECT 1
      FROM OW_LAO.ODS_PAYMENT_FUNNEL_HOMOLOG AA
      WHERE A.PO_ORDERID = AA.PO_ORDERID
        AND A.SUBSIDIARY = AA.SUBSIDIARY
        AND COALESCE(A.PO_INTERNAL_STATUS, 'incomplete') = COALESCE(AA.PO_INTERNAL_STATUS, 'incomplete')
  )
--- ORDER BY dedup DESC;
  
  ----last update for payments br
  ;
  
  DELETE 
        FROM OW_LAO.TMP_SALES_PAYMENTS_VTEX_BR_DETAILS_HOMOLOG
       WHERE DEDUP != 1 
  ;
 
 -----Update sales payments 
		UPDATE OW_LAO.TMP_SALES_PAYMENTS_VTEX_BR_DETAILS_HOMOLOG A
	SET A.REVENUE_LOCAL = B.VALUE  / 100 ,
	    A.PE_AMOUNT     = B.VALUE  / 100 
		FROM OW_LAO.TMP_SALES_PAYMENTS_VTEX_BR_DETAILS_HOMOLOG A
        JOIN U_PRJ_ECOM.RAW_VTEX_SSG_BR_SHOP_SALES_ORDER_PAYMENT B ON B.ORDER_ID = A.PAY_ORDERID 
 ; 
 
 -----Update sales payments usd
		UPDATE OW_LAO.TMP_SALES_PAYMENTS_VTEX_BR_DETAILS_HOMOLOG A
         SET REVENU_USD = A.PE_AMOUNT / CAST(B.EXCHANGE_RATE AS DECIMAL)
		FROM OW_LAO.TMP_SALES_PAYMENTS_VTEX_BR_DETAILS_HOMOLOG A
        JOIN OW_LAO.FT_AP2_EXCHANGE_RATE               B ON B.VALID_FROM         =  ADD_DAYS(CAST(A.PO_DATE AS DATE),-1)
                                                        AND LOWER(B.TO_CURRENCY) =  LOWER(A.CURRENCY)
 ;  
 --------Update sales payments vtex br status
		UPDATE OW_LAO.TMP_SALES_PAYMENTS_VTEX_BR_DETAILS_HOMOLOG A
	SET A.FUNNEL_STATUS = B.STATUS
		FROM OW_LAO.TMP_SALES_PAYMENTS_VTEX_BR_DETAILS_HOMOLOG A
		JOIN ow_lao.dim_payment_payment_status_mapping_homolog B ON A.PO_INTERNAL_STATUS = B.PO_STATUS
                                               			 AND A.PAY_STATUS = B.STATUS 
                                               			 AND A.PO_PLATAFORM_DATASOURCE = B.DATA_SOURCE
 ; 
---------------Update ODS_PAYMENT_FUNNEL for VTEX BR Payments 
        merge into 
        	 ow_lao.ODS_PAYMENT_FUNNEL_HOMOLOG a
			using ow_lao.TMP_SALES_PAYMENTS_VTEX_BR_DETAILS_HOMOLOG b on b.pay_orderid    = a.pay_orderid
														     and b.pay_subsidiary = a.pay_subsidiary
				when matched then update 
					set   a.po_date 					= b.po_date 
						, a.po_month 					= b.po_month 
						, a.po_year 					= b.po_year 
						, a.po_hour 					= b.po_hour 
						, a.pay_subsidiary 				= b.pay_subsidiary 
						, a.pay_code 					= b.pay_code 
						, a.pay_id 						= b.pay_id 
						, a.pay_date 					= b.pay_date 
						, a.pay_month 					= b.pay_month 
						, a.pay_year 					= b.pay_year 
						, a.pay_hour 					= b.pay_hour 
						, a.pay_status 					= b.pay_status 
						, a.pay_detail 					= b.pay_detail 
						, a.pay_gateway_code			= b.pay_gateway_code 
						, a.payment_type 				= b.payment_type 
						, a.pay_gateway 				= b.pay_gateway 
						, a.revenue_local 				= b.revenue_local 
						, a.pay_orderid 				= b.pay_orderid 
						, a.pay_storename 				= b.pay_storename 
						, a.postoretype 				= b.postoretype 
						, a.po_devicetype 				= b.po_devicetype 
						, a.po_status 					= b.po_status 
						, a.order_status_type 			= b.order_status_type 
						, a.currency 					= b.currency 
						, a.po_order_lastmodifydate 	= b.po_order_lastmodifydate 
						, a.postorename 				= b.postorename 
						, a.channel 					= b.channel 
						, a.biz_type 					= b.biz_type 
						, a.audience_type 				= b.audience_type 
						, a.subsidiary 					= b.subsidiary 
						, a.pe_amount					= b.pe_amount
						, a.revenu_usd					= b.revenu_usd
						, a.po_orderid 					= b.po_orderid 
						, a.pay_action 					= b.pay_action 
						, a.pay_result 					= b.pay_result 
						, a.pay_description 			= b.pay_description 
						, a.pay_message 				= b.pay_message 
						, a.po_internal_status			= b.po_internal_status
						, a.po_payment_type				= b.po_payment_type
						, a.po_paymentprovider			= b.po_paymentprovider
						, a.payment_card_brand			= b.payment_card_brand
						, a.po_status_ct 				= b.po_status_ct 
						, a.funnel_status 				= b.funnel_status
						, a.PAY_GATEWAY_STATUS 			= b.PAY_GATEWAY_STATUS
						, a.PO_PAYMENT_TYPE_STATUS 		= b.PO_PAYMENT_TYPE_STATUS
						, a.PO_PLATAFORM_DATASOURCE 			= b.PO_PLATAFORM_DATASOURCE
						, a.updated_timestamp 			= current_timestamp
						, a.datasource_origin_timestamp = b.datasource_origin_timestamp
						when not matched then insert(
							po_date 
							, po_month 
							, po_year 
							, po_hour 
							, pay_subsidiary 
							, pay_code 
							, pay_id 
							, pay_date 
							, pay_month 
							, pay_year 
							, pay_hour 
							, pay_status 
							, pay_detail 
							, pay_gateway_code 
							, payment_type 
							, pay_gateway 
							, revenue_local 
							, pay_orderid 
							, pay_storename 
							, postoretype 
							, po_devicetype 
							, po_status 
							, order_status_type 
							, currency 
							, po_order_lastmodifydate 
							, postorename 
							, channel 
							, biz_type 
							, audience_type 
							, subsidiary 
							, pe_amount
							, revenu_usd
							, po_orderid 
							, pay_action 
							, pay_result 
							, pay_description 
							, pay_message 
							, po_internal_status
							, po_payment_type
							, po_paymentprovider
							, payment_card_brand
							, po_status_ct 
							, funnel_status 
					        , PAY_GATEWAY_STATUS
						 	, PO_PAYMENT_TYPE_STATUS
						 	, PO_PLATAFORM_DATASOURCE	
							, datasource_origin_timestamp
							)
							values(
							b.po_date 
							, b.po_month 
							, b.po_year 
							, b.po_hour 
							, b.pay_subsidiary 
							, b.pay_code 
							, b.pay_id 
							, b.pay_date 
							, b.pay_month 
							, b.pay_year 
							, b.pay_hour 
							, b.pay_status 
							, b.pay_detail 
							, b.pay_gateway_code 
							, b.payment_type 
							, b.pay_gateway 
							, b.revenue_local 
							, b.pay_orderid 
							, b.pay_storename 
							, b.postoretype 
							, b.po_devicetype 
							, b.po_status 
							, b.order_status_type 
							, b.currency 
							, b.po_order_lastmodifydate 
							, b.postorename 
							, b.channel 
							, b.biz_type 
							, b.audience_type 
							, b.subsidiary 
							, b.pe_amount
							, b.revenu_usd
							, b.po_orderid 
							, b.pay_action 
							, b.pay_result 
							, b.pay_description 
							, b.pay_message 
							, b.po_internal_status
							, b.po_payment_type
							, b.po_paymentprovider
							, b.payment_card_brand
							, b.po_status_ct 
							, b.funnel_status 
					        , b.PAY_GATEWAY_STATUS
						 	, b.PO_PAYMENT_TYPE_STATUS
							, b.PO_PLATAFORM_DATASOURCE
							, b.datasource_origin_timestamp 
							)
; 
							end;