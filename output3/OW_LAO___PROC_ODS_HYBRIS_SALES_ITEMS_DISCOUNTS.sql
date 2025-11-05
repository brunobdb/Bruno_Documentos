create procedure ow_lao.proc_ods_hybris_sales_items_discounts
as
 begin
        declare loop_end     int;        
        declare loop_count   int = 1;
        
	    declare discountInitial   varchar(0255) = '<MDV<';
	    declare discountEnd       varchar(0255) = '>VDM>';    
	    declare discountDetails   varchar(3000);
	    declare discountSeparator varchar(0001) = '|';
	    declare discountInitialSize         int = length(:discountInitial);
	    declare discountEndSize             int = length(:discountEnd);
	
	    declare discountDetailCount         int = 1;
	    declare discountDetailEnd           int = 2;
	    declare order_id                    varchar(0255);
	    declare sku                         varchar(0255);
	    declare discount_detail             varchar(3000);        
 
        raw_hybris_sales_prepare = select id
                                        , order_code 
                                        , product_code
                                        , trade_in_discount
                                        , row_number() over() as row_id
                                     from ow_lao.raw_hybris_sales_homolog
                                    where trade_in_discount != '[]';
                                           
                                           
        select max(row_id)
          into loop_end
          from :raw_hybris_sales_prepare;   
          
         while :loop_count <= :loop_end
            do
            
            discountDetailCount = 1;
         
            select order_code 
                 , product_code
                 , trade_in_discount 
              into order_id
                 , sku
                 , discountDetails
              from :raw_hybris_sales_prepare 
             where row_id = :loop_count;
            
            loop_count = :loop_count + 1;            
            
		    if locate(:discountDetails, :discountSeparator) = 0
		       then
		            discounts_details =  select :order_id                                as order_id
		                                      , :sku                                     as sku
		                                      , 1                                        as discount_detail_id
                                              , replace(
                                                 replace(
                                                  substring(:discountDetails
                                                           , :discountInitialSize + 2
                                                           , length(:discountDetails) 
                                                             - (:discountInitialSize 
                                                                + :discountEndSize + 2
                                                               )
                                                  )
                                                 , '[<', '<')
                                                 , '>]'
                                                , '>')                                   as discount_detail
		                                   from dummy;		       
		       else          
		            discounts_details =  select :order_id                            as order_id
									          , :sku                                 as sku
									          , a.id                                 as discount_detail_id
									          , substring(a.output_split
									                     , :discountInitialSize + 1
									                     , length(a.output_split) 
									                       - (:discountInitialSize 
									                          + :discountEndSize)
									            )                                    as discount_detail
									       from "U_R_BOJART"."SPLIT_STRING_ID"(replace(replace(:discountDetails, '[<', '<'), '>]', '>'), :discountSeparator) as a;
               end if;
							       
		    select max(discount_detail_id)
		      into discountDetailEnd
		      from :discounts_details;
		
		     while :discountDetailCount <= :discountDetailEnd
		        do
		             select a.order_id
		                  , a.sku
		                  , a.discount_detail
		               into order_id
		                  , sku
		                  , discount_detail
		               from :Discounts_Details a
		              where discount_detail_id = :discountDetailCount;  
		
		            discountDetailCount = :discountDetailCount + 1;
		              
		            
		            insert into u_r_bojart.ods_hybris_sales_items_discounts(
		                   order_id
		                 , sku
		                 , discount_name
		                 , discount_value
		            )
		            select :order_id            as order_id
		                 , :sku                 as sku
                         , max( case a.id
                                     when 6
                                     then a.output_split
                                     else null
                                 end
                           )                   as discount_name
                         , max( case a.id
                                     when 3
                                     then a.output_split
                                     else null
                                 end
                           )                   as discount_value
		              from "U_R_BOJART"."SPLIT_STRING_ID"(:discount_detail, '#') a
                     where a.id in (3, 6);
		               
		       end while;
         
           end while;
   end