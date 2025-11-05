CREATE procedure ow_lao.homolog_proc_ods_sales_payments_grafana_details
    as
BEGIN
	-----------------------------------------------------
	
   truncate table ow_lao.TMP_SALES_PAYMENTS_GRAFANA_DETAILS_HOMOLOG;
      
   insert into ow_lao.TMP_SALES_PAYMENTS_GRAFANA_DETAILS_HOMOLOG
   
        select a.inserted_timestamp                 as insert_timestamp 
			 , cast(add_seconds(to_timestamp(a.order_created_date ), (b.timezone * 60) * 60) as date) 				as po_date 
			 , month(cast(add_seconds(to_timestamp(a.order_created_date ), (b.timezone * 60) * 60) as date))  		as po_month 
			 , year(cast(add_seconds(to_timestamp(a.order_created_date ), (b.timezone * 60) * 60) as date))  		as po_year 
			 , hour(cast(add_seconds(to_timestamp(a.order_created_date ), (b.timezone * 60) * 60) as timestamp)) 	as po_hour                     
             , a.tenant                             as pay_subsidiary 
             , a.pe_code                            as pay_code 
             , a.paymentid                          as pay_id 
			 , cast(add_seconds(to_timestamp(a.pe_time ), (b.timezone * 60) * 60) as date) 							as pay_date 
			 , month(cast(add_seconds(to_timestamp(a.pe_time ), (b.timezone * 60) * 60) as date))  					as pay_month 
			 , year(cast(add_seconds(to_timestamp(a.pe_time ), (b.timezone * 60) * 60) as date))  					as pay_year 
			 , hour(cast(add_seconds(to_timestamp(a.pe_time ), (b.timezone * 60) * 60) as timestamp)) 				as pay_hour                      
             , coalesce(a.pe_status, '')            as pay_status 
             , a.pe_status_detail                   as pay_detail 
             , a.payment_code                       as pay_gateway_code 
             , a.payment_mode                       as payment_type 
             , a.payment_provider                   as pay_gateway 
             , a.pe_amount                          as revenue_local 
             , substring(a.orderid,1,17)            as pay_orderid 
             , c.site                               as pay_storename 
             , a.isbasestore                        as postoretype 
             , a.sales_application                  as po_devicetype 
             , coalesce(a.order_status, '')         as po_status 
             , a.order_type                         as order_status_type 
             , a.order_currency                     as currency 
         	 , cast(add_seconds(to_timestamp(a.order_modified_date ), (b.timezone * 60) * 60) as timestamp) 		as po_order_lastmodifydate              
             , d.affiliate_id                       as postorename 
             , d.global_channel                     as channel 
             , d.biz_type                           as biz_type 
             , d.audience_type                      as audience_type 
             , d.sales_org                          as subsidiary 
             , a.pe_amount                          as pe_amount
             , cast(null as decimal)                as revenu_usd
             , cast(  '' as varchar(255))           as po_orderid 
             , cast(  '' as varchar(255))           as pay_action 
             , cast(  '' as varchar(255))           as pay_result 
             , cast(  '' as varchar(1000))          as pay_description 
             , cast(  '' as varchar(255))           as pay_message 
             , cast(  '' as varchar(255))           as po_internal_status
             , cast(  '' as varchar(255))           as po_payment_type
             , cast(  '' as varchar(255))           as po_paymentprovider
             , cast(  '' as varchar(255))           as payment_card_brand
             , cast(  '' as varchar(255))           as po_status_ct
             , cast(null as varchar(255))           as funnel_status
             , cast(null as varchar(255))           as PAY_GATEWAY_STATUS
             , cast(null as varchar(255))           as PO_PAYMENT_TYPE_STATUS
             , 'GRAFANA_HYBRIS'          			as PO_PLATAFORM_DATASOURCE
             , substring(a.orderid,1,17)            as orderid_log 
             , row_number()
                over(partition by a.tenant
                                , c.site
                                , substring(a.orderid,1,17)
                        order by cast(add_seconds(to_timestamp(a.order_modified_date ), (b.timezone * 60) * 60) as timestamp) desc) as dedup
             , cast(add_seconds(to_timestamp(a.order_modified_date ), (b.timezone * 60) * 60) as timestamp)               as datasource_origin_timestamp
          from ow_lao.raw_grafana_document_payments_details a 
          join u_prj_ecom.dim_subsidiary                    b on lower(b.country_code)        = lower(a.tenant)
          join ow_lao.ods_hybris_sales                      c on substring(c.order_code,1,17) = substring(a.orderid ,1,17)
          join ow_md.sales_channel                          d on lower(d.country)             = lower(b.country) 
                                                             and lower(d.identifier)          = lower(c.site) 
         where not exists(
                    select 1
                      from ow_lao.ods_payment_funnel_homolog aa
                     where substring(a.orderid,1,17) = substring(aa.pay_orderid ,1,17)
                       and a.tenant                  = aa.pay_subsidiary
                       and cast(add_seconds(to_timestamp(a.order_modified_date ), (b.timezone * 60) * 60) as timestamp)    <= aa.datasource_origin_timestamp
               )
     	 and b.order_apply_timezone = 1	
     	 and  cast(a.inserted_timestamp as date) >= '2025-04-13'
      order by cast(add_seconds(to_timestamp(a.order_created_date ), (b.timezone * 60) * 60) as date) ;
      
 ----------------------------------------------------     
      delete 
        from ow_lao.TMP_SALES_PAYMENTS_GRAFANA_DETAILS_HOMOLOG
       where dedup != 1;
 ---------------------------------------------
     
      update ow_lao.TMP_SALES_PAYMENTS_GRAFANA_DETAILS_HOMOLOG a
         set po_internal_status = b.order_status
           , po_payment_type    = b.payment_mode
           , po_paymentprovider = b.payment_provider
           , payment_card_brand = b.payment_mode_creditcardtype
        from ow_lao.TMP_SALES_PAYMENTS_GRAFANA_DETAILS_HOMOLOG a
        join ow_lao.ods_hybris_sales                   b on substring(b.order_code,1,17) = substring(a.pay_orderid ,1,17); 
   
 ----------------------------------------------------            
       
      update ow_lao.TMP_SALES_PAYMENTS_GRAFANA_DETAILS_HOMOLOG a
         set po_orderid      = b.orderid
           , pay_action      = b.action
           , pay_description = b.description
           , pay_message     = b.message
        from ow_lao.TMP_SALES_PAYMENTS_GRAFANA_DETAILS_HOMOLOG        a
        join ow_lao.raw_grafana_document_log_payments_details b on substring(b.orderid ,1,17) = a.orderid_log;    
       
  ----------------------------------------------------     
        
      update ow_lao.TMP_SALES_PAYMENTS_GRAFANA_DETAILS_HOMOLOG a
         set revenu_usd = a.pe_amount / cast(b.exchange_rate as decimal)
        from ow_lao.TMP_SALES_PAYMENTS_GRAFANA_DETAILS_HOMOLOG a
        join ow_lao.ft_ap2_exchange_rate               b on b.valid_from         = add_days(cast(a.po_date as date),-1)
                                                        and lower(b.to_currency) = lower(a.currency);  
 ----------------------------------------------------                                                            
        
      update ow_lao.TMP_SALES_PAYMENTS_GRAFANA_DETAILS_HOMOLOG a
         set po_status_ct = b.status
        from ow_lao.TMP_SALES_PAYMENTS_GRAFANA_DETAILS_HOMOLOG               a
        join ow_lao.dim_ods_sales_control_tower_table_status_mapping b on b.status_origin = a.po_internal_status;
       
 ----------------------------------------------------            
        
      update ow_lao.TMP_SALES_PAYMENTS_GRAFANA_DETAILS_HOMOLOG a
         set funnel_status = b.status
        from ow_lao.TMP_SALES_PAYMENTS_GRAFANA_DETAILS_HOMOLOG a
        join ow_lao.dim_payment_payment_status_mapping_homolog
        													b on b.pay_status      = a.pay_status
                                                        and b.po_status       = a.po_status
                                                        and b.pay_description = a.pay_description
                                                        and a.po_plataform_datasource = b.data_source
       where b.active = true;        
      
 ----------------------------------------------------           
        
     merge into ow_lao.ods_payment_funnel_homolog  a
          using ow_lao.TMP_SALES_PAYMENTS_GRAFANA_DETAILS_HOMOLOG b on substring(b.pay_orderid ,1,17)  = substring(a.pay_orderid ,1,17)
                                                           and b.pay_subsidiary                = a.pay_subsidiary
           when    matched then update  
                                   set a.po_date = b.po_date 
                                     , a.po_month = b.po_month 
                                     , a.po_year = b.po_year 
                                     , a.po_hour = b.po_hour 
                                     , a.pay_subsidiary = b.pay_subsidiary 
                                     , a.pay_code = b.pay_code 
                                     , a.pay_id = b.pay_id 
                                     , a.pay_date = b.pay_date 
                                     , a.pay_month = b.pay_month 
                                     , a.pay_year = b.pay_year 
                                     , a.pay_hour = b.pay_hour 
                                     , a.pay_status = b.pay_status 
                                     , a.pay_detail = b.pay_detail 
                                     , a.pay_gateway_code = b.pay_gateway_code 
                                     , a.payment_type = b.payment_type 
                                     , a.pay_gateway = b.pay_gateway 
                                     , a.revenue_local = b.revenue_local 
                                     , a.pay_orderid = b.pay_orderid 
                                     , a.pay_storename = b.pay_storename 
                                     , a.postoretype = b.postoretype 
                                     , a.po_devicetype = b.po_devicetype 
                                     , a.po_status = b.po_status 
                                     , a.order_status_type = b.order_status_type 
                                     , a.currency = b.currency 
                                     , a.po_order_lastmodifydate = b.po_order_lastmodifydate 
                                     , a.postorename = b.postorename 
                                     , a.channel = b.channel 
                                     , a.biz_type = b.biz_type 
                                     , a.audience_type = b.audience_type 
                                     , a.subsidiary = b.subsidiary 
                                     , a.pe_amount= b.pe_amount
                                     , a.revenu_usd= b.revenu_usd
                                     , a.po_orderid = b.po_orderid 
                                     , a.pay_action = b.pay_action 
                                     , a.pay_result = b.pay_result 
                                     , a.pay_description = b.pay_description 
                                     , a.pay_message = b.pay_message 
                                     , a.po_internal_status= b.po_internal_status
                                     , a.po_payment_type= b.po_payment_type
                                     , a.po_paymentprovider= b.po_paymentprovider
                                     , a.payment_card_brand= b.payment_card_brand
                                     , a.po_status_ct = b.po_status_ct 
                                     , a.funnel_status = b.funnel_status
                                     , a.updated_timestamp = current_timestamp
                                     , a.PAY_GATEWAY_STATUS = b.PAY_GATEWAY_STATUS
									 , a.PO_PAYMENT_TYPE_STATUS = b.PO_PAYMENT_TYPE_STATUS
									 , a.PO_PLATAFORM_DATASOURCE =   b.PO_PLATAFORM_DATASOURCE
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
                                 );               
                                
        
end;