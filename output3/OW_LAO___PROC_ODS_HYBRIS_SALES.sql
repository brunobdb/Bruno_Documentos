CREATE PROCEDURE OW_LAO.PROC_ODS_HYBRIS_SALES
 LANGUAGE SQLSCRIPT AS
 BEGIN
      drop table OW_LAO.TMP_HYBRIS_SALES_DEDUP;
      drop table OW_LAO.TMP_HYBRIS_SALES_VOUCHER_CODE_AGG;   
      drop table OW_LAO.TMP_HYBRIS_SALES_AGG_DEDUP;
      
      
    insert into OW_LAO.RAW_HYBRIS_SALES_MONITORING
    
    select *
         , false
      from OW_LAO.RAW_HYBRIS_SALES
     where ow_lao.isnumeric(substring(replace(order_entry_quantity, '.00', ''),0,60)) = 0
     
     union all
                 
    select *
         , false
      from OW_LAO.RAW_HYBRIS_SALES
     where ow_lao.isnumeric(substring(replace(order_entry_unit_price, '.00', ''),0,60)) = 0;
     
     
    delete
      from OW_LAO.RAW_HYBRIS_SALES
     where ow_lao.isnumeric(substring(replace(order_entry_quantity, '.00', ''),0,60)) = 0;
     
    delete
      from OW_LAO.RAW_HYBRIS_SALES
     where ow_lao.isnumeric(substring(replace(order_entry_unit_price, '.00', ''),0,60)) = 0;  
     
    delete
      from OW_LAO.RAW_HYBRIS_SALES
     where product_code is null;     
   
    insert into ow_lao.monitoring_bi_lao_proccess_hybris_files_sales(
           file_name
         , file_name_short
         , load_date
         , file_last_modified_time
         , file_generated_at
         , rows_quantity
    )
    
    select file_name
         , file_name_short
         , load_date
         , file_last_modified_time
         , file_generated_at
         , count(1)                 as rows_quantity
      from ow_lao.raw_hybris_sales
  group by file_name
         , file_name_short
         , load_date
         , file_last_modified_time
         , file_generated_at;        
    
    create column table OW_LAO.TMP_HYBRIS_SALES_DEDUP as (
            select row_number()
                        over(partition by country_cd
                                        , order_code
                                        , product_code
                                        , voucer_code
                                 order by file_generated_at desc
                        )                                                               dedup
                 , *
                 , CAST(0 AS INT) AS CRP
              from OW_LAO.RAW_HYBRIS_SALES a
             where 1 = 1
               and order_code not in ('CL230527-89889817', 'CL230625-99532769')
               and not exists(
                          select 1
                            from OW_LAO.ODS_HYBRIS_SALES aa
                           where aa.country_cd         = a.country_cd
                             and aa.order_code         = a.order_code
                             and aa.product_code       = a.product_code
                             and aa.file_generated_at >= a.file_generated_at
                   )
               --and id in (100979, 100977, 1293029, 1293030)
               --and order_code in ('PE230701-01689294')  
               --and product_code = 'SM-A346MZKFLTP' 
     );
 -------------------CRP(COUPON)---------------------   
------VOUCHER----------19/12/2024
	
	----Mapeamento de TODOS os coupon(MAIOR QUE 3 digitos)
UPDATE
	OW_LAO.TMP_HYBRIS_SALES_DEDUP a
SET
	CRP = 2
FROM
	OW_LAO.TMP_HYBRIS_SALES_DEDUP a
JOIN u_prj_ecom.dim_subsidiary      b ON lower(b.country_code) =  lower(a.country_cd)
JOIN OW_LAO.DIM_LAO_CRP_CS_VOUCHER_COUPON c ON
	 lower(c.VOUCHER_COUPON) = lower (a.VOUCER_CODE) 
		AND c.SUBSIDIARY = b.SUBSIDIARY
	WHERE a.CRP = 0
		AND LENGTH(c.VOUCHER_COUPON) > 3;
	
--------Mapeamento dos COUPON parciais com "-" antes/depois do coupon
UPDATE
	OW_LAO.TMP_HYBRIS_SALES_DEDUP a
SET
	CRP = 2	 
FROM
	OW_LAO.TMP_HYBRIS_SALES_DEDUP a
JOIN u_prj_ecom.dim_subsidiary      b ON lower(b.country_code) =  lower(a.country_cd)
JOIN OW_LAO.DIM_LAO_CRP_CS_VOUCHER_COUPON c ON
	        	 LOCATE (a.VOUCER_CODE, '-' || c.VOUCHER_COUPON || '-') > 0
	        	 --locate(a.coupon, '-' || b.coupon || '-') > 0
	        	 AND c.SUBSIDIARY = b.SUBSIDIARY
	        	WHERE a.CRP = 0
	        AND LENGTH(c.VOUCHER_COUPON) = 3;
-----
UPDATE
	OW_LAO.TMP_HYBRIS_SALES_DEDUP a
SET
	CRP = 2	 
FROM
	OW_LAO.TMP_HYBRIS_SALES_DEDUP a
JOIN u_prj_ecom.dim_subsidiary      b ON lower(b.country_code) =  lower(a.country_cd)
JOIN OW_LAO.DIM_LAO_CRP_CS_VOUCHER_COUPON c ON
					  	locate(a.VOUCER_CODE, c.VOUCHER_COUPON || '-') = 1
	        	 AND c.SUBSIDIARY = b.SUBSIDIARY
	        	WHERE a.CRP = 0
	        AND LENGTH(c.VOUCHER_COUPON) = 3;
	       
-----
UPDATE
	OW_LAO.TMP_HYBRIS_SALES_DEDUP a
SET
	CRP = 2	 
FROM
	OW_LAO.TMP_HYBRIS_SALES_DEDUP a
JOIN u_prj_ecom.dim_subsidiary      b ON lower(b.country_code) =  lower(a.country_cd)
JOIN OW_LAO.DIM_LAO_CRP_CS_VOUCHER_COUPON c ON
					  	locate(a.VOUCER_CODE, '-' || c.VOUCHER_COUPON) > 0
                             and 
                             --length(a.VOUCER_CODE) = locate(a.VOUCER_CODE, c.VOUCHER_COUPON) + (length(c.VOUCHER_COUPON) - 1)
                             right(a.VOUCER_CODE,4) = '-' || c.VOUCHER_COUPON
	        	 AND c.SUBSIDIARY = b.SUBSIDIARY
	        	WHERE a.CRP = 0
	        AND LENGTH(c.VOUCHER_COUPON) = 3;	       	        
-----------------------------------------------------------     
     delete from OW_LAO.TMP_HYBRIS_SALES_DEDUP where dedup != 1;
    
          
     
  
     create column table OW_LAO.TMP_HYBRIS_SALES_VOUCHER_CODE_AGG as (
  
               select country_cd    
                    , site  
                    , sales_application 
                    , order_code    
                    , order_status  
                    , order_creation_date   
                    , order_total_price 
                    , order_total_tax   
                    , max(order_entry_no)                 as order_entry_no    
                    , order_currency    
                    , product_code  
                    , product_name  
                    , order_entry_total_price   
                    , order_entry_unit_price    
                    , order_entry_discounted_price  
                    , order_entry_cancelled_price   
                    , order_entry_returns_price 
                    , order_entry_sit_retruns_price 
                    , order_entry_quantity  
                    , ean   
                    , string_agg(voucer_code, '||')      as voucer_code   
                    , payment_mode  
                    , payment_transaction_code  
                    , shipping_method   
                    , customer_type 
                    , replace(sales_order, '.00', '')    as sales_order   
                    , sent_to_gerp  
                    , replace(delivery_order, '.00', '') as delivery_order    
                    , order_refund_date 
                    , return_order  
                    , return_reason 
                    , return_sales_order    
                    , return_delivery_order 
                    , order_entry_returns_date  
                    , oder_entry_replacement_date   
                    , order_entry_cancel_date   
                    , cancel_reason 
                    , added_services    
                    , upgrade_from  
                    , order_entry_total_tax 
                    , tradein_eligible  
                    , smc_eligible  
                    , locale    
                    , payment_provider  
                    , store_type    
                    , upgrade_eligible  
                    , payment_generic_data  
                    , payment_mode_creditcardtype   
                    , payment_date  
                    , requested_delivery_date   
                    , shipping_date 
                    , gerp_delivery_date    
                    , second_gi_date    
                    , store_id  
                    , store_name    
                    , exchange_brand    
                    , trade_in_discount 
                    , exchange_model    
                    , guid  
                    , marketing_preference  
                    , is_email_subscription_options 
                    , agent_login_id    
                    , agent_name    
                    , carrier_name  
                    , carrier_plan  
                    , external_service_type 
                    , gscm_site_id  
                    , access_code   
                    , fully_cancelled   
                    , device_type
                    , max(crp)						   AS crp
                    , max(load_date)                   as load_date
                    , max(file_name)                   as file_name
                    , max(file_last_modified_time)     as file_last_modified_time
                    , max(file_name_short)             as file_name_short
                    , max(file_generated_at)           as file_generated_at
                from OW_LAO.TMP_HYBRIS_SALES_DEDUP
               --where order_code in ('MX230711-04379977')
            group by country_cd    
                    , site  
                    , sales_application 
                    , order_code    
                    , order_status  
                    , order_creation_date   
                    , order_total_price 
                    , order_total_tax   
                    , order_currency    
                    , product_code  
                    , product_name  
                    , order_entry_total_price   
                    , order_entry_unit_price    
                    , order_entry_discounted_price  
                    , order_entry_cancelled_price   
                    , order_entry_returns_price 
                    , order_entry_sit_retruns_price 
                    , order_entry_quantity  
                    , ean   
                    , payment_mode  
                    , payment_transaction_code  
                    , shipping_method   
                    , customer_type 
                    , replace(sales_order, '.00', '')   
                    , sent_to_gerp  
                    , replace(delivery_order, '.00', '')    
                    , order_refund_date 
                    , return_order  
                    , return_reason 
                    , return_sales_order    
                    , return_delivery_order 
                    , order_entry_returns_date  
                    , oder_entry_replacement_date   
                    , order_entry_cancel_date   
                    , cancel_reason 
                    , added_services    
                    , upgrade_from  
                    , order_entry_total_tax 
                    , tradein_eligible  
                    , smc_eligible  
                    , locale    
                    , payment_provider  
                    , store_type    
                    , upgrade_eligible  
                    , payment_generic_data  
                    , payment_mode_creditcardtype   
                    , payment_date  
                    , requested_delivery_date   
                    , shipping_date 
                    , gerp_delivery_date    
                    , second_gi_date    
                    , store_id  
                    , store_name    
                    , exchange_brand    
                    , trade_in_discount 
                    , exchange_model    
                    , guid  
                    , marketing_preference  
                    , is_email_subscription_options 
                    , agent_login_id    
                    , agent_name    
                    , carrier_name  
                    , carrier_plan  
                    , external_service_type 
                    , gscm_site_id  
                    , access_code   
                    , fully_cancelled   
                    , device_type
                     
        );
        
        
     create column table OW_LAO.TMP_HYBRIS_SALES_AGG_DEDUP as (
     
               select row_number()
                        over(partition by country_cd
                                        , order_code
                                        , product_code
                                 order by file_generated_at desc
                        )                                                               dedup
                 , *
                from OW_LAO.TMP_HYBRIS_SALES_VOUCHER_CODE_AGG
     
     );       
     
     
     delete from OW_LAO.TMP_HYBRIS_SALES_AGG_DEDUP where dedup != 1;
          
    
               update OW_LAO.ODS_HYBRIS_SALES a
                  set site                          = b.site  
                    , sales_application             = b.sales_application 
                    , order_status                  = b.order_status  
                    , order_creation_date           = b.order_creation_date   
                    , order_total_price             = b.order_total_price 
                    , order_total_tax               = b.order_total_tax   
                    , order_entry_no                = b.order_entry_no    
                    , order_currency                = b.order_currency   
                    , product_name                  = b.product_name  
                    , order_entry_total_price       = b.order_entry_total_price   
                    , order_entry_unit_price        = b.order_entry_unit_price    
                    , order_entry_discounted_price  = b.order_entry_discounted_price  
                    , order_entry_cancelled_price   = b.order_entry_cancelled_price   
                    , order_entry_returns_price     = b.order_entry_returns_price 
                    , order_entry_sit_retruns_price = b.order_entry_sit_retruns_price 
                    , order_entry_quantity          = b.order_entry_quantity  
                    , ean                           = b.ean   
                    , voucer_code                   = b.voucer_code   
                    , payment_mode                  = b.payment_mode  
                    , payment_transaction_code      = b.payment_transaction_code  
                    , shipping_method               = b.shipping_method   
                    , customer_type                 = b.customer_type 
                    , sales_order                   = b.sales_order
                    , sent_to_gerp                  = b.sent_to_gerp  
                    , delivery_order                = b.delivery_order
                    , order_refund_date             = b.order_refund_date 
                    , return_order                  = b.return_order  
                    , return_reason                 = b.return_reason 
                    , return_sales_order            = b.return_sales_order    
                    , return_delivery_order         = b.return_delivery_order 
                    , order_entry_returns_date      = b.order_entry_returns_date  
                    , oder_entry_replacement_date   = b.oder_entry_replacement_date   
                    , order_entry_cancel_date       = b.order_entry_cancel_date   
                    , cancel_reason                 = b.cancel_reason 
                    , added_services                = b.added_services    
                    , upgrade_from                  = b.upgrade_from  
                    , order_entry_total_tax         = b.order_entry_total_tax 
                    , tradein_eligible              = b.tradein_eligible  
                    , smc_eligible                  = b.smc_eligible  
                    , locale                        = b.locale    
                    , payment_provider              = b.payment_provider  
                    , store_type                    = b.store_type    
                    , upgrade_eligible              = b.upgrade_eligible  
                    , payment_generic_data          = b.payment_generic_data  
                    , payment_mode_creditcardtype   = b.payment_mode_creditcardtype   
                    , payment_date                  = b.payment_date  
                    , requested_delivery_date       = b.requested_delivery_date   
                    , shipping_date                 = b.shipping_date 
                    , gerp_delivery_date            = b.gerp_delivery_date    
                    , second_gi_date                = b.second_gi_date    
                    , store_id                      = b.store_id  
                    , store_name                    = b.store_name    
                    , exchange_brand                = b.exchange_brand    
                    , trade_in_discount             = b.trade_in_discount 
                    , exchange_model                = b.exchange_model    
                    , guid                          = b.guid  
                    , marketing_preference          = b.marketing_preference  
                    , is_email_subscription_options = b.is_email_subscription_options 
                    , agent_login_id                = b.agent_login_id    
                    , agent_name                    = b.agent_name    
                    , carrier_name                  = b.carrier_name  
                    , carrier_plan                  = b.carrier_plan  
                    , external_service_type         = b.external_service_type 
                    , gscm_site_id                  = b.gscm_site_id  
                    , access_code                   = b.access_code   
                    , fully_cancelled               = b.fully_cancelled   
                    , device_type                   = b.device_type   
                    , crp                           = b.crp 
                    , load_date                     = b.load_date 
                    , file_name                     = b.file_name 
                    , file_last_modified_time       = b.file_last_modified_time 
                    , file_name_short               = b.file_name_short   
                    , file_generated_at             = b.file_generated_at
                    , updated_datetime              = current_timestamp
                 from OW_LAO.ODS_HYBRIS_SALES           a
                 join OW_LAO.TMP_HYBRIS_SALES_AGG_DEDUP b on b.country_cd        = a.country_cd
                                                         and b.order_code        = a.order_code
                                                         and b.product_code      = a.product_code
                                                         and b.file_generated_at > a.file_generated_at;
              
    insert into OW_LAO.ODS_HYBRIS_SALES(
                      country_cd    
                    , site  
                    , sales_application 
                    , order_code    
                    , order_status  
                    , order_creation_date   
                    , order_total_price 
                    , order_total_tax   
                    , order_entry_no    
                    , order_currency    
                    , product_code  
                    , product_name  
                    , order_entry_total_price   
                    , order_entry_unit_price    
                    , order_entry_discounted_price  
                    , order_entry_cancelled_price   
                    , order_entry_returns_price 
                    , order_entry_sit_retruns_price 
                    , order_entry_quantity  
                    , ean   
                    , voucer_code   
                    , payment_mode  
                    , payment_transaction_code  
                    , shipping_method   
                    , customer_type 
                    , sales_order   
                    , sent_to_gerp  
                    , delivery_order    
                    , order_refund_date 
                    , return_order  
                    , return_reason 
                    , return_sales_order    
                    , return_delivery_order 
                    , order_entry_returns_date  
                    , oder_entry_replacement_date   
                    , order_entry_cancel_date   
                    , cancel_reason 
                    , added_services    
                    , upgrade_from  
                    , order_entry_total_tax 
                    , tradein_eligible  
                    , smc_eligible  
                    , locale    
                    , payment_provider  
                    , store_type    
                    , upgrade_eligible  
                    , payment_generic_data  
                    , payment_mode_creditcardtype   
                    , payment_date  
                    , requested_delivery_date   
                    , shipping_date 
                    , gerp_delivery_date    
                    , second_gi_date    
                    , store_id  
                    , store_name    
                    , exchange_brand    
                    , trade_in_discount 
                    , exchange_model    
                    , guid  
                    , marketing_preference  
                    , is_email_subscription_options 
                    , agent_login_id    
                    , agent_name    
                    , carrier_name  
                    , carrier_plan  
                    , external_service_type 
                    , gscm_site_id  
                    , access_code   
                    , fully_cancelled   
                    , device_type
                    , crp
                    , load_date 
                    , file_name 
                    , file_last_modified_time 
                    , file_name_short
                    , file_generated_at
    )                           
    
               select country_cd    
                    , site  
                    , sales_application 
                    , order_code    
                    , order_status  
                    , order_creation_date   
                    , order_total_price 
                    , order_total_tax   
                    , order_entry_no    
                    , order_currency    
                    , product_code  
                    , product_name  
                    , order_entry_total_price   
                    , order_entry_unit_price    
                    , order_entry_discounted_price  
                    , order_entry_cancelled_price   
                    , order_entry_returns_price 
                    , order_entry_sit_retruns_price 
                    , order_entry_quantity  
                    , ean   
                    , voucer_code   
                    , payment_mode  
                    , payment_transaction_code  
                    , shipping_method   
                    , customer_type 
                    , sales_order   
                    , sent_to_gerp  
                    , delivery_order    
                    , order_refund_date 
                    , return_order  
                    , return_reason 
                    , return_sales_order    
                    , return_delivery_order 
                    , order_entry_returns_date  
                    , oder_entry_replacement_date   
                    , order_entry_cancel_date   
                    , cancel_reason 
                    , added_services    
                    , upgrade_from  
                    , order_entry_total_tax 
                    , tradein_eligible  
                    , smc_eligible  
                    , locale    
                    , payment_provider  
                    , store_type    
                    , upgrade_eligible  
                    , payment_generic_data  
                    , payment_mode_creditcardtype   
                    , payment_date  
                    , requested_delivery_date   
                    , shipping_date 
                    , gerp_delivery_date    
                    , second_gi_date    
                    , store_id  
                    , store_name    
                    , exchange_brand    
                    , trade_in_discount 
                    , exchange_model    
                    , guid  
                    , marketing_preference  
                    , is_email_subscription_options 
                    , agent_login_id    
                    , agent_name    
                    , carrier_name  
                    , carrier_plan  
                    , external_service_type 
                    , gscm_site_id  
                    , access_code   
                    , fully_cancelled   
                    , device_type 
                    , crp
                    , load_date 
                    , file_name 
                    , file_last_modified_time 
                    , file_name_short   
                    , file_generated_at
                 from OW_LAO.TMP_HYBRIS_SALES_AGG_DEDUP a
                where not exists(
                            select 1
                              from OW_LAO.ODS_HYBRIS_SALES aa
                             where aa.country_cd        = a.country_cd
                               and aa.order_code        = a.order_code
                               and aa.product_code      = a.product_code
                      );      end