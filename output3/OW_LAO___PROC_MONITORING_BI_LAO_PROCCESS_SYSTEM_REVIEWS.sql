CREATE procedure ow_lao.proc_monitoring_bi_lao_proccess_system_reviews
 LANGUAGE SQLSCRIPT AS
BEGIN		
			/*Atualização automatica do processo Orders*/ 	
            update ow_lao.monitoring_bi_lao_proccess    a
		       set status_nome       = 'Corrigido pelo sistema'
		         , observacao        = 'Pedido foi importado posteriormente'
		         , updated_timestamp = current_timestamp
		      from ow_lao.monitoring_bi_lao_proccess    a   
		      join ow_lao.ods_sales_control_tower_table b on b.po_orderid = a.referencia  
		     where status_nome = 'Em analise'
		       and a.origem_nome in (
		                          'u_prj_ecom.ods_feed_vtex_ssg_br_shop_sales_order'
		                        , 'u_prj_ecom_synapcom.ft_ecom_order'
		                        , 'u_prj_ecom.ft_ecom_order'
		                        , 'u_prj_ecom.raw_vtex_ssg_br_epp2_sales_order'
		                        ,'u_prj_ecom_synapcom.ft_ecom_order bundle'
		           );
			/*Atualização automatica do processo Orders para ods_hybris_sales*/   			  
			UPDATE OW_LAO.MONITORING_BI_LAO_PROCCESS
			   SET STATUS_NOME       = 'Corrigido pelo sistema',
			       OBSERVACAO        = 'Pedido foi importado posteriormente',
			       UPDATED_TIMESTAMP = current_timestamp
			  FROM OW_LAO.MONITORING_BI_LAO_PROCCESS
			 WHERE ORIGEM_NOME = 'ow_lao.ods_hybris_sales' 
			   AND STATUS_NOME = 'Em analise'
			   AND REFERENCIA IN (
					 SELECT DISTINCT A.ORDER_CODE
			           FROM OW_LAO.ODS_HYBRIS_SALES   A
			           JOIN U_PRJ_ECOM.DIM_SUBSIDIARY B ON LOWER(B.COUNTRY_CODE) = LOWER(A.COUNTRY_CD)
			           JOIN OW_LAO.ODS_SALES_CONTROL_TOWER_TABLE AA
			             ON AA.PO_ORDERID = A.ORDER_CODE
			    	    AND AA.PO_SKU     = A.PRODUCT_CODE
			    	    AND AA.COUNTRY    = B.COUNTRY 
			    );			  		          
			    
			/*Atualização automatica do processo Orders para Nerp*/  
			CALL ow_lao.proc_monitoring_bi_lao_proccess_system_reviews_nerp;			    
			    
			    
--			/*Atualização automatica do processo Status*/ 		          
			UPDATE OW_LAO.MONITORING_BI_LAO_PROCCESS A
			   SET status_nome 			= 'Corrigido pelo sistema', 					 
				   observacao			= 'Mapeamento foi preenchido posteriormente', 	 
				   updated_timestamp	=  current_timestamp		
			  FROM OW_LAO.MONITORING_BI_LAO_PROCCESS 	A
			 WHERE A.STATUS_NOME = 'Em analise'
			   AND A.ORIGEM_NOME = 'ow_lao.dim_ods_sales_control_tower_table_status_mapping'
			   AND EXISTS ( 
				   SELECT 1
				   FROM OW_LAO.ODS_SALES_CONTROL_TOWER_TABLE B WHERE 
				   A.REFERENCIA = B.PO_INTERNAL_STATUS
				   AND  B.PO_STATUS IS NOT NULL
			   );	
			
			/*Atualização automatica do processo Sales Channels*/  
			UPDATE OW_LAO.MONITORING_BI_LAO_PROCCESS A
			   SET A.status_nome 		= 'Corrigido pelo sistema', 					 
				   A.observacao			= 'Mapeamento foi preenchido posteriormente', 	 
				   A.updated_timestamp	=  current_timestamp		
			  FROM OW_LAO.MONITORING_BI_LAO_PROCCESS 	A
			  JOIN OW_LAO.ODS_SALES_CONTROL_TOWER_TABLE B ON A.REFERENCIA = B.PO_ORDERID 
		     WHERE A.STATUS_NOME = 'Em analise'
			   AND A.ORIGEM_NOME = 'ow_md.sales_channel'	
			   AND B.CHANNEL IS NOT NULL;	
			  
			/*Atualização automatica do processo Sales Channels -- Adciona descrição para os pedidos que precisam ser mapeados*/   
			UPDATE 	OW_LAO.MONITORING_BI_LAO_PROCCESS A
			   SET 	OBSERVACAO = 
			  		CASE 
				   		WHEN PO_STORENAME IS NULL THEN 'Realize o mapeamento de COUNTRY:' || B.COUNTRY || ' na tabela ow_md.sales_channel'
				   		WHEN PO_STORENAME IS NOT NULL THEN 'Realize o mapeamento de COUNTRY:' || B.COUNTRY || ' e PO_STORENAME:' || B.PO_STORENAME || ' na tabela ow_md.sales_channel'
				    END,
					UPDATED_TIMESTAMP = current_timestamp 
			  FROM 	OW_LAO.MONITORING_BI_LAO_PROCCESS 		A
			  JOIN	OW_LAO.ODS_SALES_CONTROL_TOWER_TABLE 	B
				ON 	A.REFERENCIA = B.PO_ORDERID
			 WHERE  A.ORIGEM_NOME = 'ow_md.sales_channel'
			   AND 	A.STATUS_NOME = 'Em analise'
			   AND 	A.OBSERVACAO IS NULL
			   AND 	B.CHANNEL IS NULL; 			  
			/*Atualização automatica do processo Produto Category*/   
			UPDATE OW_LAO.MONITORING_BI_LAO_PROCCESS A
			   SET status_nome 			= 'Corrigido pelo sistema', 					 
				   observacao			= 'Produto foi mapeado posteriormente', 	 
				   updated_timestamp	=  current_timestamp
			  FROM OW_LAO.MONITORING_BI_LAO_PROCCESS A
			 WHERE ORIGEM_NOME = 'ow_lao.dim_product_mapping_lao'
			   AND STATUS_NOME	= 'Em analise'
			   AND EXISTS (
				   SELECT 1
				     FROM OW_LAO.ODS_SALES_CONTROL_TOWER_TABLE B
				    WHERE B.DIVISION IS NOT NULL  
				      AND B.PO_SOURCE_INSERT_DATE >= '20220101'
				      AND A.REFERENCIA = LEFT(B.PO_SKU, 1000) 
			);   
			/*Atualização automatica do processo Produto Category -- Adciona descrição para os pedidos que precisam ser mapeados*/   
			UPDATE OW_LAO.MONITORING_BI_LAO_PROCCESS A
			   SET OBSERVACAO = 'Realize o mapeamento do produto na tabela ow_lao.dim_product_mapping_lao',
				   UPDATED_TIMESTAMP = current_timestamp 
			  FROM OW_LAO.MONITORING_BI_LAO_PROCCESS 		A
			  JOIN OW_LAO.ODS_SALES_CONTROL_TOWER_TABLE 	B ON A.REFERENCIA = LEFT(B.PO_SKU,1000)
			 WHERE A.ORIGEM_NOME = 'ow_lao.dim_product_mapping_lao'
			   AND A.STATUS_NOME = 'Em analise'
			   AND A.OBSERVACAO IS NULL
			   AND B.PO_SOURCE_INSERT_DATE >= '20220101' 
			   AND B.DIVISION IS NULL;
			/*Atualização automatica do processo ow_lao.ods_global_bi_sales*/ 
			UPDATE 	OW_LAO.MONITORING_BI_LAO_PROCCESS 					A
			   SET  A.STATUS_NOME       	= 'Corrigido pelo sistema',
			    	A.OBSERVACAO      		= 'Pedido foi importado posteriormente',
			    	A.UPDATED_TIMESTAMP  	= current_timestamp
			  FROM	OW_LAO.MONITORING_BI_LAO_PROCCESS 					A
			 WHERE 	ORIGEM_NOME = 'ow_lao.ods_global_bi_sales'
			   AND 	STATUS_NOME = 'Em analise'
			   AND 	EXISTS (
			   			SELECT 	1
					  	  FROM 	OW_LAO.ODS_GLOBAL_BI_SALES 				B
					  	  JOIN 	OW_LAO.ODS_SALES_CONTROL_TOWER_TABLE 	C 	ON B.PO_ID = C.PO_ORDERID AND  B.SKU = C.PO_SKU AND B.COUNTRY = C.COUNTRY 	
					  	 WHERE 	A.REFERENCIA = B.PO_ID
					       AND 	B.SKU IS NOT NULL
					);
END;