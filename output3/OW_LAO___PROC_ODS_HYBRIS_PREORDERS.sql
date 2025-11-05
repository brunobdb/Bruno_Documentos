create PROCEDURE OW_LAO.PROC_ODS_HYBRIS_PREORDERS
 LANGUAGE SQLSCRIPT AS
 BEGIN
      
 
       drop table OW_LAO.TMP_HYBRIS_PREORDERS_DEDUP;
     
     create column table OW_LAO.TMP_HYBRIS_PREORDERS_DEDUP as (
          
            select row_number()
                        over(partition by country_code
                                        , product_code
                                        , catalog_version
                                 order by file_generated_at desc
                        )                                                               dedup
                 , *
              from OW_LAO.RAW_HYBRIS_PREORDERS a
             where 1 = 1
               and not exists(
                          select 1
                            from OW_LAO.ODS_HYBRIS_PREORDERS aa
                           where aa.country_code       = a.country_code
                             and aa.product_code       = a.product_code
                             and aa.catalog_version    = a.catalog_version
                             and aa.file_generated_at >= a.file_generated_at
                   )
     );
     
     delete from OW_LAO.TMP_HYBRIS_PREORDERS_DEDUP where dedup != 1;     
     
     
       update OW_LAO.ODS_HYBRIS_PREORDERS a
          set Preorder_Start_date       = b.Preorder_Start_date
            , Preorder_end_date         = b.Preorder_end_date
            , "UPDATED_DATE"            = current_timestamp
            , "FILE_LAST_MODIFIED_TIME" = b."FILE_LAST_MODIFIED_TIME"
            , "FILE_NAME"               = b."FILE_NAME"
            , "FILE_NAME_SHORT"         = b."FILE_NAME_SHORT" 
            , file_generated_at         = b.file_generated_at
         from OW_LAO.ODS_HYBRIS_PREORDERS       a
         join OW_LAO.TMP_HYBRIS_PREORDERS_DEDUP b on b.country_code      = a.country_code
                                                 and b.product_code      = a.product_code
                                                 and b.catalog_version   = a.catalog_version
                                                 and b.file_generated_at > a.file_generated_at;
                                                 
                                                 
       insert into OW_LAO.ODS_HYBRIS_PREORDERS(   
		       Country_Code
		     , Product_Code
		     , Catalog_Version
		     , Preorder_Start_date
		     , Preorder_end_date
		     , "FILE_LAST_MODIFIED_TIME"
		     , "FILE_NAME"
		     , "FILE_NAME_SHORT"
		     , file_generated_at
       )
     
        select Country_Code
             , Product_Code
             , Catalog_Version
             , Preorder_Start_date
             , Preorder_end_date
             , "FILE_LAST_MODIFIED_TIME"
             , "FILE_NAME"
             , "FILE_NAME_SHORT"
             , file_generated_at
          from OW_LAO.TMP_HYBRIS_PREORDERS_DEDUP a
         where not exists(
                    select 1
                      from OW_LAO.ODS_HYBRIS_PREORDERS aa
                     where aa.country_code    = a.country_code
                       and aa.product_code    = a.product_code
                       and aa.catalog_version = a.catalog_version
               );
                                              
                                              
                                              
   end