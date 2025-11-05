CREATE PROCEDURE OW_LAO.PROC_FT_D2C_NERP_CELLO_LEAD_TIME_RETURN_PENDING_KPI
 LANGUAGE SQLSCRIPT AS
 BEGIN
	drop table OW_LAO.FT_D2C_NERP_CELLO_LEAD_TIME_RETURN_PENDING_KPI;
	
	create column table OW_LAO.FT_D2C_NERP_CELLO_LEAD_TIME_RETURN_PENDING_KPI as
	(
	
	
	    select h.subsidiary                                                     as "Subsidiary"
	         , d.return_type                                                    as "Return_type"
	         , days_between(b.pick_up_date          , now()) - i.total_gi_iod   as "Pending_Day_vs_Tg_LT"
	         , days_between(b.delivery_creation_date, now())                    as "Pending_Day_vs_RDO"
	         , days_between(b.pick_up_date          , now())                    as "Pending_Day_vs_Collect"
	         , cast(b.delivery_creation_date as date)                           as "Date_RDO"
	         , cast(b.pick_up_date           as date)                           as "Date_Collect"
	         , b.delivery_no                                                    as "RDO"
	         , z.division                                                       as "Div"
	         , z.product_1                                                      as "Product"
	         , z.sku                                                            as "SKU"
	         , cast(c.item_qty as decimal)                                      as "QTY"
	         , a.plant                                                          as "Plant"
	         , j.origin                                                         as "Plant_Desc"
	         , b.s_carrier_name                                                 as "Carrier"
	         , b.shipto_state                                                   as "Region"
	         , b.shipto_city                                                    as "City"
	         , i.total_gi_iod                                                   as "Target_LT"
	      from "OW_SEDA_S".CELLO_DELIVERY_INBOUND                                            b 
	      join "OW_SEDA_S".CELLO_DELIVERY_INBOUND_ITEM                                       c on c.delivery_no        = b.delivery_no
	      join "OW_LAO".AUX_CELLO_DELIVERY_INBOUND_ORDER_TYPE                                d on d.order_type         = b.order_type  
	 left join "OW_SEDA_S".ODS_NERP_ZLLEJ50090_OUTBOUND_TRACKING                             a on a.delivery_no        = b.delivery_ref_no 
	 left join OW_MD.DIM_PLANT                                                               g on g.plant_code         = a.plant
	 left join OW_MD."DIM_SUBSIDIARY"                                                        h on h.sales_org          = a.sales_org
	 left join OW_MD.DIM_LEAD_TIME_UF                                                        i on i.destination        = b.shipto_state
	                                                                                          and i.sur_key_subsidiary = h.sur_key_subsidiary
	 left join OW_MD.DIM_PLANT                                                               j on j.plant_code         = a.plant
	                                                                                          and j.sur_key_subsidiary = h.sur_key_subsidiary
	 left join OW_MD.DIM_PRODUCT                                                             z on z.sku                = c.item_cd
	     where 1 = 1              
	       and b.ship_type_cd in ('P3', 'P4')  
	       and d.return_type  = 'pick up'
	       and b.pick_up_date is not null
	       and b.gr_date      is null       
	       
	       
	     union all
	     
	     
	    select h.subsidiary                                                     as "Subsidiary"
	         , d.return_type                                                    as "Return_type"
	         , days_between(a."2ND_GI_DATE"         , now()) - i.total_gi_iod   as "Pending_Day_vs_Tg_LT"
	         , days_between(b.delivery_creation_date, now())                    as "Pending_Day_vs_RDO"
	         , days_between(a."2ND_GI_DATE"         , now())                    as "Pending_Day_vs_Collect"
	         , cast(b.delivery_creation_date as date)                           as "Date_RDO"
	         , cast(a."2ND_GI_DATE"          as date)                           as "Date_Collect"
	         , b.delivery_no                                                    as "RDO"
	         , z.division                                                       as "Div"
	         , z.product_1                                                      as "Product"
	         , z.sku                                                            as "SKU"
	         , cast(c.item_qty as decimal)                                      as "QTY"
	         , a.plant                                                          as "Plant"
	         , j.origin                                                         as "Plant_Desc"
	         , b.s_carrier_name                                                 as "Carrier"
	         , b.shipto_state                                                   as "Region"
	         , b.shipto_city                                                    as "City"
	         , i.total_gi_iod                                                   as "Target_LT"
	      from "OW_SEDA_S".CELLO_DELIVERY_INBOUND                                            b 
	      join "OW_SEDA_S".CELLO_DELIVERY_INBOUND_ITEM                                       c on c.delivery_no        = b.delivery_no
	      join "OW_LAO".AUX_CELLO_DELIVERY_INBOUND_ORDER_TYPE                                d on d.order_type         = b.order_type  
	 left join "OW_SEDA_S".ODS_NERP_ZLLEJ50090_OUTBOUND_TRACKING                             a on a.delivery_no        = b.delivery_ref_no 
	 left join OW_MD.DIM_PLANT                                                               g on g.plant_code         = a.plant
	 left join OW_MD."DIM_SUBSIDIARY"                                                        h on h.sales_org          = a.sales_org
	 left join OW_MD.DIM_LEAD_TIME_UF                                                        i on i.destination        = b.shipto_state
	                                                                                          and i.sur_key_subsidiary = h.sur_key_subsidiary
	 left join OW_MD.DIM_PLANT                                                               j on j.plant_code         = a.plant
	                                                                                          and j.sur_key_subsidiary = h.sur_key_subsidiary
	 left join OW_MD.DIM_PRODUCT                                                             z on z.sku                = c.item_cd
	     where 1 = 1              
	       and b.ship_type_cd in ('P3', 'P4')  
	       and d.return_type  = 'SIT'
	       and b.out_iod_date is null            
	       
	       
	     union all
	     
	     
	    select h.subsidiary                                                     as "Subsidiary"
	         , d.return_type                                                    as "Return_type"
	         , null                                                             as "Pending_Day_vs_Tg_LT"
	         , days_between(b.delivery_creation_date, now())                    as "Pending_Day_vs_RDO"
	         , null                                                             as "Pending_Day_vs_Collect"
	         , cast(b.delivery_creation_date as date)                           as "Date_RDO"
	         , null                                                             as "Date_Collect"
	         , b.delivery_no                                                    as "RDO"
	         , z.division                                                       as "Div"
	         , z.product_1                                                      as "Product"
	         , z.sku                                                            as "SKU"
	         , cast(c.item_qty as decimal)                                      as "QTY"
	         , a.plant                                                          as "Plant"
	         , j.origin                                                         as "Plant_Desc"
	         , b.s_carrier_name                                                 as "Carrier"
	         , b.shipto_state                                                   as "Region"
	         , b.shipto_city                                                    as "City"
	         , i.total_gi_iod                                                   as "Target_LT"
	      from "OW_SEDA_S".CELLO_DELIVERY_INBOUND                                            b 
	      join "OW_SEDA_S".CELLO_DELIVERY_INBOUND_ITEM                                       c on c.delivery_no        = b.delivery_no
	      join "OW_LAO".AUX_CELLO_DELIVERY_INBOUND_ORDER_TYPE                                d on d.order_type         = b.order_type  
	 left join "OW_SEDA_S".ODS_NERP_ZLLEJ50090_OUTBOUND_TRACKING                             a on a.delivery_no        = b.delivery_ref_no 
	 left join OW_MD.DIM_PLANT                                                               g on g.plant_code         = a.plant
	 left join OW_MD."DIM_SUBSIDIARY"                                                        h on h.sales_org          = a.sales_org
	 left join OW_MD.DIM_LEAD_TIME_UF                                                        i on i.destination        = b.shipto_state
	                                                                                          and i.sur_key_subsidiary = h.sur_key_subsidiary
	 left join OW_MD.DIM_PLANT                                                               j on j.plant_code         = a.plant
	                                                                                          and j.sur_key_subsidiary = h.sur_key_subsidiary
	 left join OW_MD.DIM_PRODUCT                                                             z on z.sku                = c.item_cd
	     where 1 = 1              
	       and b.ship_type_cd in ('P3', 'P4')  
	       and d.return_type  = 'Correios => Post'
	       and b.out_iod_date is null   
	       
	       );
	       
    end