CREATE PROCEDURE ow_md.proc_ods_sales_channels
 LANGUAGE SQLSCRIPT AS
 BEGIN
		  
	      	     drop table ow_md.temp_input_sales_channels_dedup;
	    
	    create column table ow_md.temp_input_sales_channels_dedup
	        as (
	
			      select a.plataform_type
			           , coalesce(a.plataform_account, '')  as plataform_account
			           , coalesce(a.identifier       , '')  as identifier       
			           , coalesce(a.has_store_id     , '')  as has_store_id     
			           , coalesce(a.sales_channel    , '')  as sales_channel    
			           , coalesce(a.affiliate_id     , '')  as affiliate_id     
			           , a.channel
			           , a.sub_channel
			           , a.partner_level
			           , a.global_channel
			           , a.global_channel_ebi
			           , a.biz_type
			           , a.biz_type_ebi
			           , a.audience_type
			           , a.audience_type_ebi
			           , a.sales_org
			           , a.business_area
			           , a.company_code
			           , a.country
			           , a.country_code
			           , a.currency
			           , a.file_name
			           , a.last_modification_file
			           , a.load_timestamp
			           , row_number()
			                over(partition by a.plataform_type
			                                , a.plataform_account
			                                , a.identifier    
			                                , a.has_store_id   
			                                , a.sales_channel    
			                                , a.affiliate_id     
			                         order by load_timestamp desc
			                     )                                   dedup
			        from ow_md.input_sales_channels a
			       where a.load_timestamp > (select coalesce(max(load_timestamp), '1900-01-01') from ow_md.ods_sales_channels)
            );
	    
	    delete from ow_md.temp_input_sales_channels_dedup where dedup != 1;
	    
	    
     merge into ow_md.ods_sales_channels              a
          using ow_md.temp_input_sales_channels_dedup b on a.plataform_type    = b.plataform_type
                                                       and a.plataform_account = b.plataform_account
                                                       and a.identifier        = b.identifier       
                                                       and a.has_store_id      = b.has_store_id     
                                                       and a.sales_channel     = b.sales_channel    
                                                       and a.affiliate_id      = b.affiliate_id     
            when   matched then update  
                                   set a.channel                = b.channel
						           , a.sub_channel            = b.sub_channel
						           , a.partner_level          = b.partner_level
						           , a.global_channel         = b.global_channel
						           , a.global_channel_ebi     = b.global_channel_ebi
						           , a.biz_type               = b.biz_type
						           , a.biz_type_ebi           = b.biz_type_ebi
						           , a.audience_type          = b.audience_type
						           , a.audience_type_ebi      = b.audience_type_ebi
						           , a.sales_org              = b.sales_org
						           , a.business_area          = b.business_area
						           , a.company_code           = b.company_code
						           , a.country                = b.country
						           , a.country_code           = b.country_code
						           , a.currency               = b.currency
						           , a.file_name              = b.file_name
						           , a.last_modification_file = b.last_modification_file
						           , a.load_timestamp         = b.load_timestamp
						           , a.updated_date           = current_timestamp
          when not matched then insert(    
                                         plataform_type 
						               , plataform_account 
						               , identifier 
						               , has_store_id 
						               , sales_channel 
						               , affiliate_id 
						               , channel 
						               , sub_channel 
						               , partner_level 
						               , global_channel 
						               , global_channel_ebi 
						               , biz_type 
						               , biz_type_ebi 
						               , audience_type 
						               , audience_type_ebi 
						               , sales_org 
						               , business_area 
						               , company_code 
						               , country 
						               , country_code 
						               , currency 
						               , file_name 
						               , last_modification_file 
						               , load_timestamp 
                                    )  
                                 values(      
                                             b.plataform_type
								           , b.plataform_account
								           , b.identifier       
								           , b.has_store_id     
								           , b.sales_channel    
								           , b.affiliate_id     
								           , b.channel
								           , b.sub_channel
								           , b.partner_level
								           , b.global_channel
								           , b.global_channel_ebi
								           , b.biz_type
								           , b.biz_type_ebi
								           , b.audience_type
								           , b.audience_type_ebi
								           , b.sales_org
								           , b.business_area
								           , b.company_code
								           , b.country
								           , b.country_code
								           , b.currency
								           , b.file_name
								           , b.last_modification_file
								           , b.load_timestamp
                                      );  
                                      
end