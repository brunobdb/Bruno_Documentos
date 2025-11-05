CREATE PROCEDURE OW_LAO.PROC_ODS_HYBRIS_REWARDS
 LANGUAGE SQLSCRIPT AS
 BEGIN
      
 
       drop table OW_LAO.TMP_HYBRIS_REWARDS_DEDUP;
     
     create column table OW_LAO.TMP_HYBRIS_REWARDS_DEDUP as (
          
            select row_number()
                        over(partition by Country_Cd
                                        , Order_Code
                                        , Product_Code
                                        , Site
                                 order by file_generated_at desc
                        )                                                            as dedup
                 , *
                 , case Rewards_Amount
                        when 'null'
                        then 0
                        else cast(Rewards_Amount as numeric(15))
                    end                                                              as Rewards_Amount_Fix
              from OW_LAO.RAW_HYBRIS_REWARDS a
             where 1 = 1
               and not exists(
                          select 1
                            from OW_LAO.ODS_HYBRIS_REWARDS aa
                           where aa.Country_Cd         = a.Country_Cd
                             and aa.Order_Code         = a.Order_Code
                             and aa.Product_Code       = a.Product_Code
                             and aa.Site               = a.Site
                             and aa.file_generated_at >= a.file_generated_at
                   )
     );
     
     delete from OW_LAO.TMP_HYBRIS_REWARDS_DEDUP where dedup != 1; 
                                              
     merge into OW_LAO.ODS_HYBRIS_REWARDS       a
          using OW_LAO.TMP_HYBRIS_REWARDS_DEDUP b on b.Country_Cd        = a.Country_Cd
			                                     and b.Order_Code        = a.Order_Code
			                                     and b.Product_Code      = a.Product_Code
				                                 and b.Site              = a.Site
				                                 and b.file_generated_at > a.file_generated_at
           when     matched then update
                                    set a.Order_Status             = b.Order_Status  
                                      , a.Estimated_Accrued_Amount = b.Estimated_Accrued_Amount  
                                      , a.Rewards_Amount           = b.Rewards_Amount_Fix    
                                      , a.Spend_Points             = b.Spend_Points  
                                      , a.LOAD_DATE                = b.LOAD_DATE 
                                      , a.UPDATED_DATE             = current_timestamp
                                      , a.FILE_NAME                = b.FILE_NAME 
                                      , a.FILE_LAST_MODIFIED_TIME  = b.FILE_LAST_MODIFIED_TIME 
                                      , a.FILE_NAME_SHORT          = b.FILE_NAME_SHORT 
                                      , a.file_generated_at        = b.file_generated_at 
           when not matched then insert values(
									          b.Country_Cd    
									        , b.Order_Code    
									        , b.Order_Creation_Date_Local 
									        , b.Product_Code  
									        , b.Customer_Type 
									        , b.Store_Type    
									        , b.Site  
									        , b.Sales_Application 
									        , b.Order_Status  
									        , b.Estimated_Accrued_Amount  
									        , b.Rewards_Amount_Fix    
									        , b.Spend_Points  
									        , b.LOAD_DATE 
									        , null
									        , b.FILE_NAME 
									        , b.FILE_LAST_MODIFIED_TIME 
									        , b.FILE_NAME_SHORT 
									        , b.file_generated_at 
                                         );
                                              
   end