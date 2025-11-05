
CREATE procedure ow_lao.proc_monitoring_bi_lao_proccess_system_reviews_nerp
LANGUAGE SQLSCRIPT AS
BEGIN
	-- Separa os campos CUSTOMER_PO e SALES_DOCUMENT para 
	DROP TABLE 			OW_LAO.temp_ods_sales_control_tower_table_nerp_update_monitoring_filter_2;
	CREATE COLUMN TABLE OW_LAO.temp_ods_sales_control_tower_table_nerp_update_monitoring_filter_2 
	AS (
			SELECT row_number() over() as id,
				   SUBSTRING( 
				   SUBSTRING(REFERENCIA,LOCATE(REFERENCIA,': ' )+2,20),  
				     	1,
				     	LOCATE(SUBSTRING(REFERENCIA,LOCATE(REFERENCIA,': ' )+2,20),'sa')-1) 	AS CUSTOMER_PO,   		
				   SUBSTRING(REFERENCIA,LOCATE(REFERENCIA,'sales_document: ') + 16,10)  		AS SALES_DOCUMENT
		      FROM OW_LAO.MONITORING_BI_LAO_PROCCESS
			 WHERE ORIGEM_NOME = 'ow_lao.ods_nerp_zrsdd6a120_sales_order_tracking'
		  ORDER BY CUSTOMER_PO
	);
	DROP TABLE OW_LAO.TEMP_ODS_SALES_CONTROL_TOWER_TABLE_NERP_UPDATE_MONITORING_FILTER_DELETE_2;     
	CREATE COLUMN TABLE OW_LAO.TEMP_ODS_SALES_CONTROL_TOWER_TABLE_NERP_UPDATE_MONITORING_FILTER_DELETE_2
	    AS ( 
	            SELECT C.*
	              FROM OW_LAO.ODS_SALES_CONTROL_TOWER_TABLE                                      A 
	              JOIN OW_MD.DIM_SUBSIDIARY                                                      B ON LOWER(B.COUNTRY) 	= LOWER(A.COUNTRY)
	              JOIN OW_LAO.TEMP_ODS_SALES_CONTROL_TOWER_TABLE_NERP_UPDATE_MONITORING_FILTER_2 C ON C.CUSTOMER_PO 	= A.PO_SEQUENCE_ORDERID
	                                                                                               AND '8201'   		= B.SALES_ORG                                                       
	             UNION ALL
	             
	            SELECT C.*
	              FROM OW_LAO.ODS_SALES_CONTROL_TOWER_TABLE                                      A 
	              JOIN OW_MD.DIM_SUBSIDIARY                                                      B ON LOWER(B.COUNTRY) 	= LOWER(A.COUNTRY)
	              JOIN OW_LAO.TEMP_ODS_SALES_CONTROL_TOWER_TABLE_NERP_UPDATE_MONITORING_FILTER_2 C ON C.SALES_DOCUMENT 	= A.PO_ORDERSID
	                                                                                    		   AND '8201'      		= B.SALES_ORG  
	             UNION ALL
	             
	            SELECT C.*
	              FROM OW_LAO.ODS_SALES_CONTROL_TOWER_TABLE                                      A 
	              JOIN OW_MD.DIM_SUBSIDIARY                                                      B ON LOWER(B.COUNTRY) 	= LOWER(A.COUNTRY)
	              JOIN OW_LAO.TEMP_ODS_SALES_CONTROL_TOWER_TABLE_NERP_UPDATE_MONITORING_FILTER_2 C ON C.CUSTOMER_PO    	= A.PO_ORDERID
	                                                                                               AND '8201'      		= B.SALES_ORG                                                                                                                
	    );      
   
	DELETE
	FROM OW_LAO.TEMP_ODS_SALES_CONTROL_TOWER_TABLE_NERP_UPDATE_MONITORING_FILTER_2 A
	WHERE ID NOT IN (SELECT DISTINCT ID FROM OW_LAO.TEMP_ODS_SALES_CONTROL_TOWER_TABLE_NERP_UPDATE_MONITORING_FILTER_DELETE_2);      
	UPDATE OW_LAO.MONITORING_BI_LAO_PROCCESS A 
	   SET A.STATUS_NOME         = 'Corrigido pelo sistema',
	       A.OBSERVACAO        = 'Pedido foi importado posteriormente',
	       A.UPDATED_TIMESTAMP = CURRENT_TIMESTAMP
	  FROM OW_LAO.MONITORING_BI_LAO_PROCCESS 								  A 
	  JOIN TEMP_ODS_SALES_CONTROL_TOWER_TABLE_NERP_UPDATE_MONITORING_FILTER_2 B ON 'customer_po: ' || B.CUSTOMER_PO || 'sales_document: ' || B.SALES_DOCUMENT = A.REFERENCIA 
	 WHERE A.ORIGEM_NOME = 'ow_lao.ods_nerp_zrsdd6a120_sales_order_tracking'
		   AND A.STATUS_NOME =  'Em analise';
END;	
	
	
 
