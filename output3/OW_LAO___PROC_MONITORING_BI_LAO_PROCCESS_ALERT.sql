CREATE PROCEDURE OW_LAO.PROC_MONITORING_BI_LAO_PROCCESS_ALERT(
	IN CONSULTA NVARCHAR(40)
) LANGUAGE SQLSCRIPT AS
BEGIN
	IF :CONSULTA = 'LIST_FILES' THEN	
	BEGIN
		/*-------------------------------------------------------------------------------------------------*/	
		-- Recolhe os itens a serem processados
		TRUNCATE TABLE OW_LAO.TMP_MONITORING_BI_LAO_PROCCESS_ID;
		INSERT INTO OW_LAO.TMP_MONITORING_BI_LAO_PROCCESS_ID 
		SELECT 
			ID_PROCESS,
			NUMBER_OF_REPETITIONS 
		FROM 
			OW_LAO.DIM_MONITORING_BI_LAO_PROCCESS_ALERT
		WHERE 
			STATUS = 'ACTIVE'
			AND (
				PROCESS_NAME NOT IN('HYBRIS SALES - CONTROL TOWER','HYBRIS SALES - ODS_HYBRIS_SALES')  
				AND NEXT_CHECK BETWEEN ADD_SECONDS(CURRENT_TIMESTAMP, ((60 * 1.5)*-1)) AND ADD_SECONDS(CURRENT_TIMESTAMP, 60 * 4)
			)
			-- Os processos de Hybris, devem ser verificados entre as 8 até as 22
			OR (
				PROCESS_NAME IN('HYBRIS SALES - CONTROL TOWER','HYBRIS SALES - ODS_HYBRIS_SALES') 
				AND NEXT_CHECK BETWEEN ADD_SECONDS(CURRENT_TIMESTAMP, ((60 * 1.5)*-1)) AND ADD_SECONDS(CURRENT_TIMESTAMP, 60 * 4)
				AND HOUR(NEXT_CHECK) BETWEEN 8 AND 22 
			)
		;	
		/*-------------------------------------------------------------------------------------------------*/	
		-- Atualiza a tabela dim com a informação da ultima execução e proxima
		UPDATE 
			OW_LAO.DIM_MONITORING_BI_LAO_PROCCESS_ALERT A
		SET
			NUMBER_OF_REPETITIONS 	= CEIL(SECONDS_BETWEEN(START_TIME, CURRENT_TIMESTAMP) / B.TIME_SECONDS / ABS(A.TIME_SCHEDULER )),
			LAST_CHECK 				= ADD_SECONDS(A.START_TIME, (ABS(A.TIME_SCHEDULER) * B.TIME_SECONDS) * CEIL(SECONDS_BETWEEN(START_TIME, CURRENT_TIMESTAMP) / B.TIME_SECONDS / ABS(A.TIME_SCHEDULER )-1)),
			NEXT_CHECK 				= ADD_SECONDS(A.START_TIME, (ABS(A.TIME_SCHEDULER) * B.TIME_SECONDS) * CEIL(SECONDS_BETWEEN(START_TIME, CURRENT_TIMESTAMP) / B.TIME_SECONDS / ABS(A.TIME_SCHEDULER ))) 	
		FROM 
			OW_LAO.DIM_MONITORING_BI_LAO_PROCCESS_ALERT A
		JOIN
			OW_LAO.TIME_DEFINITION B ON A.TIME_FORMAT = B.TIME_FORMAT
		WHERE 
			A.STATUS = 'ACTIVE';
		/*-------------------------------------------------------------------------------------------------*/	
		-- Lista as pastas que serão lidas no Job do Talend de acordo com o agendamento
		SELECT 
			ID_PROCESS,
			FOLDER_PATH,
		 	SEARCH_FILEMASK,
			TIME_CHECK, 
			TIME_FORMAT
		FROM 
			OW_LAO.DIM_MONITORING_BI_LAO_PROCCESS_ALERT A		
		WHERE 
			SOURCE_TYPE = 'MinIO'
			AND STATUS = 'ACTIVE'
			AND ID_PROCESS IN(SELECT ID_PROCESS FROM OW_LAO.TMP_MONITORING_BI_LAO_PROCCESS_ID);
	END;
	/*-------------------------------------------------------------------------------------------------*/	
	ELSEIF :CONSULTA = 'ALERT_DATA_SOURCER' THEN		
	BEGIN
		DECLARE V_ID_EXECUTION INT;
		/*-------------------------------------------------------------------------------------------------*/	
		-- Conta a quantidade de arquivos recebidos no file server
		TRUNCATE TABLE OW_LAO.TMP_MONITORING_BI_LAO_PROCCESS_ALERT;
		--	
		INSERT INTO OW_LAO.TMP_MONITORING_BI_LAO_PROCCESS_ALERT
		SELECT
			A.ID_PROCESS,
			COUNT(*)								AS PO_QTY
		FROM 
			OW_LAO.RAW_FILES_MINIO 						A
		JOIN
			OW_LAO.DIM_MONITORING_BI_LAO_PROCCESS_ALERT	B ON A.ID_PROCESS = B.ID_PROCESS 
		WHERE 
			B.STATUS = 'ACTIVE'
			AND B.SOURCE_TYPE = 'MinIO'
			AND A.ID_PROCESS IN(SELECT ID_PROCESS FROM OW_LAO.TMP_MONITORING_BI_LAO_PROCCESS_ID)
			AND LAST_MODIFIED_DATE >= ADD_SECONDS(CURRENT_TIMESTAMP, CASE WHEN TIME_FORMAT = 'dd' THEN TIME_CHECK * 86400 WHEN TIME_FORMAT = 'HH' THEN TIME_CHECK * 3600 WHEN TIME_FORMAT = 'mm'	THEN TIME_CHECK * 60 WHEN TIME_FORMAT = 'ss' THEN TIME_CHECK END)	
		GROUP BY
			A.ID_PROCESS
		/*-------------------------------------------------------------------------------------------------*/	
		-- Retorna apenas os arquivos que estão com tamanho zero
		UNION ALL 
		SELECT
			A.ID_PROCESS,
			SUM(FILE_SIZE)								AS PO_QTY
		FROM 
			OW_LAO.RAW_FILES_MINIO 						A
		JOIN
			OW_LAO.DIM_MONITORING_BI_LAO_PROCCESS_ALERT	B ON A.ID_PROCESS = B.ID_PROCESS 
		WHERE 
			B.STATUS = 'ACTIVE'
			AND B.SOURCE_TYPE = 'MinIO'
			AND A.FILE_SIZE = 0 
			AND A.ID_PROCESS IN(SELECT ID_PROCESS FROM OW_LAO.TMP_MONITORING_BI_LAO_PROCCESS_ID)
			AND LAST_MODIFIED_DATE >= ADD_SECONDS(CURRENT_TIMESTAMP, CASE WHEN TIME_FORMAT = 'dd' THEN TIME_CHECK * 86400 WHEN TIME_FORMAT = 'HH' THEN TIME_CHECK * 3600 WHEN TIME_FORMAT = 'mm'	THEN TIME_CHECK * 60 WHEN TIME_FORMAT = 'ss' THEN TIME_CHECK END)	
		GROUP BY
			A.ID_PROCESS;			
		/*-------------------------------------------------------------------------------------------------*/					
		--Criação da tabela temporaria retornando o monitoramento.		
		CREATE LOCAL TEMPORARY TABLE #MONITORING_FILES_TABLES AS (
			/*-------------------------------------------------------------------------------------------------*/			
			-- Retorna o status da quantidade de arquivos recebidos no file server nas pastas mapeadas marcadas como ACTIVE		
			SELECT 
				A.ID_PROCESS,
				A.ALIAS,
				A.PROCESS_NAME,
				A.SOURCE_TYPE,
				A.SUBSIDIARY,
				A.DATA_SOURCE,
				'Check in ' || A.TIME_FORMAT || ': ' || TIME_CHECK AS PERIOD_CHECK, 
				A.LINK_MINIO,
				A.SEARCH_FILEMASK,
				ADD_SECONDS(CURRENT_TIMESTAMP, CASE WHEN A.TIME_FORMAT = 'dd' THEN A.TIME_CHECK * 86400 WHEN A.TIME_FORMAT = 'HH' THEN A.TIME_CHECK * 3600 WHEN A.TIME_FORMAT = 'mm'THEN A.TIME_CHECK * 60 WHEN A.TIME_FORMAT = 'ss'THEN A.TIME_CHECK END ) AS "CHECK_PERIOD_START",
				CURRENT_TIMESTAMP AS "CHECK_PERIOD_END",
				IFNULL(B.PO_QTY,0) AS PO_QTY,
				C.NUMBER_OF_CHECK
			FROM 
				OW_LAO.DIM_MONITORING_BI_LAO_PROCCESS_ALERT A
			LEFT JOIN
				OW_LAO.TMP_MONITORING_BI_LAO_PROCCESS_ALERT B ON A.ID_PROCESS = B.ID_PROCESS
			JOIN 
				OW_LAO.TMP_MONITORING_BI_LAO_PROCCESS_ID 	C ON A.ID_PROCESS = C.ID_PROCESS			
			WHERE 
				A.SOURCE_TYPE = 'MinIO'
				AND A.STATUS = 'ACTIVE'			
			UNION ALL
			/*-------------------------------------------------------------------------------------------------*/				
			-- Retorna o status da quantidade de pedidos recebidos do data source HANA 		
			-- Verifica Control Tower: PO_PLATAFORM_DATASOURCE = 'ow_lao.ods_hybris_sales'
			SELECT 
				A.ID_PROCESS,
				A.ALIAS,
				A.PROCESS_NAME,
				A.SOURCE_TYPE,
				A.SUBSIDIARY,
				A.DATA_SOURCE,
				'Check in ' || A.TIME_FORMAT || ': ' || TIME_CHECK AS PERIOD_CHECK, 
				A.LINK_MINIO,
				A.SEARCH_FILEMASK,
				ADD_SECONDS(CURRENT_TIMESTAMP,  CASE WHEN A.TIME_FORMAT = 'dd' THEN A.TIME_CHECK * 86400 WHEN A.TIME_FORMAT = 'HH' THEN A.TIME_CHECK * 3600 WHEN A.TIME_FORMAT = 'mm'THEN A.TIME_CHECK * 60 WHEN A.TIME_FORMAT = 'ss'THEN A.TIME_CHECK END ) 	AS "CHECK_PERIOD_START",
				CURRENT_TIMESTAMP AS "CHECK_PERIOD_END",
				IFNULL(B.PO_QTY,0) AS PO_QTY,
				C.NUMBER_OF_CHECK
			FROM 
				OW_LAO.DIM_MONITORING_BI_LAO_PROCCESS_ALERT	A
			LEFT JOIN(
				SELECT 
					A.SUBSIDIARY,
					COUNT(*)		AS PO_QTY
				FROM 
					OW_LAO.DIM_MONITORING_BI_LAO_PROCCESS_ALERT	A
				LEFT JOIN 		
					OW_LAO.ODS_SALES_CONTROL_TOWER_TABLE 		B
				ON 
					A.SUBSIDIARY =  B.SUBSIDIARY
				WHERE 
					A.DATA_SOURCE =  'CONTROL TOWER OW_LAO.ODS_HYBRIS_SALES'
					AND B.PO_PLATAFORM_DATASOURCE = 'ow_lao.ods_hybris_sales'
					AND IFNULL(B.PO_SOURCE_LAST_UPDATE_DATE, B.PO_SOURCE_INSERT_DATE) >= ADD_SECONDS(CURRENT_TIMESTAMP, CASE WHEN A.TIME_FORMAT = 'dd' THEN A.TIME_CHECK * 86400 WHEN A.TIME_FORMAT = 'HH' THEN A.TIME_CHECK * 3600 WHEN A.TIME_FORMAT = 'mm'THEN A.TIME_CHECK * 60 WHEN A.TIME_FORMAT = 'ss'THEN A.TIME_CHECK END ) 
				GROUP BY 
					A.SUBSIDIARY
			) B ON A.SUBSIDIARY = B.SUBSIDIARY 
			JOIN 
				OW_LAO.TMP_MONITORING_BI_LAO_PROCCESS_ID 	C ON A.ID_PROCESS = C.ID_PROCESS	
			WHERE	
				A.DATA_SOURCE =  'CONTROL TOWER OW_LAO.ODS_HYBRIS_SALES'		
			UNION ALL
			/*-------------------------------------------------------------------------------------------------*/
			-- Retorna o status da quantidade de pedidos recebidos do data source HANA 				
			-- Verifica ODS_HYBRIS_SALES SAP_HANA	
			SELECT 
				A.ID_PROCESS,
				A.ALIAS,
				A.PROCESS_NAME,
				A.SOURCE_TYPE,
				A.SUBSIDIARY,
				A.DATA_SOURCE,
				'Check in ' || A.TIME_FORMAT || ': ' || TIME_CHECK AS PERIOD_CHECK, 
				A.LINK_MINIO,
				A.SEARCH_FILEMASK,
				ADD_SECONDS(CURRENT_TIMESTAMP,  CASE WHEN A.TIME_FORMAT = 'dd' THEN A.TIME_CHECK * 86400 WHEN A.TIME_FORMAT = 'HH' THEN A.TIME_CHECK * 3600 WHEN A.TIME_FORMAT = 'mm'THEN A.TIME_CHECK * 60 WHEN A.TIME_FORMAT = 'ss'THEN A.TIME_CHECK END ) 	AS "CHECK_PERIOD_START",
				CURRENT_TIMESTAMP AS "CHECK_PERIOD_END",
				IFNULL(B.PO_QTY,0) AS PO_QTY,
				C.NUMBER_OF_CHECK				
			FROM 
				OW_LAO.DIM_MONITORING_BI_LAO_PROCCESS_ALERT	A
			LEFT JOIN(
				SELECT
					C.SUBSIDIARY,
					COUNT(*)		AS PO_QTY
				FROM 
					OW_LAO.ODS_HYBRIS_SALES 					A 
				JOIN 		
					OW_MD.DIM_SUBSIDIARY						B ON UPPER(A.COUNTRY_CD) = UPPER(B.COUNTRY_REGION)
				JOIN 
					OW_LAO.DIM_MONITORING_BI_LAO_PROCCESS_ALERT	C ON C.SUBSIDIARY = B.SUBSIDIARY
				WHERE 
					C.DATA_SOURCE =  'ODS_HYBRIS_SALES'	
					AND IFNULL(A.UPDATED_DATETIME, A.INSERTED_DATE) >= ADD_SECONDS(CURRENT_TIMESTAMP, CASE WHEN C.TIME_FORMAT = 'dd' THEN C.TIME_CHECK * 86400 WHEN C.TIME_FORMAT = 'HH' THEN C.TIME_CHECK * 3600 WHEN C.TIME_FORMAT = 'mm'THEN C.TIME_CHECK * 60 WHEN C.TIME_FORMAT = 'ss'THEN C.TIME_CHECK END)	
				GROUP BY 
					C.SUBSIDIARY
			) B ON A.SUBSIDIARY = B.SUBSIDIARY 
			JOIN 
				OW_LAO.TMP_MONITORING_BI_LAO_PROCCESS_ID 	C ON A.ID_PROCESS = C.ID_PROCESS				
			WHERE	
				A.DATA_SOURCE =  'ODS_HYBRIS_SALES'
		);
		/*-------------------------------------------------------------------------------------------------*/
		-- Retorno da ultima execução	
		SELECT 
			IFNULL(MAX(ID_EXECUTION),0) +1 
		INTO
			V_ID_EXECUTION
		FROM 
			OW_LAO.ODS_MONITORING_BI_LAO_PROCCESS_ALERT;
		/*-------------------------------------------------------------------------------------------------*/
		--Retorno dos dados	
		SELECT 
			*,
			:V_ID_EXECUTION AS ID_EXECUTION 
		FROM 
			#MONITORING_FILES_TABLES;
	END;
	ELSEIF :CONSULTA = 'ALERT_COMPARE_ORIGEM_DESTINATION' THEN		
	BEGIN
		/*-------------------------------------------------------------------------------------------------*/
		--Retorna pedidos da control tower	
		CREATE LOCAL TEMPORARY TABLE #TMP_PO_QTY_CONTROL_TOWER AS (
		    SELECT 
		        SUBSIDIARY,
		        PO_DATE,
		        DAYOFMONTH(PO_DATE) 							AS "DAY",
		        LEFT(PO_HOUR, 2) || ':00:00' 					AS "HOUR",
		        COUNT(DISTINCT PO_ORDERID) 						AS TOTAL_ORDERS
		    FROM 
		    	OW_LAO.VIEW_ORDERS_GOVERNANCE_LAO 
		    WHERE 
		    	DATA_SOURCE = 'OW_LAO.ODS_SALES_CONTROL_TOWER_TABLE'
		    	AND PO_DATE >= ADD_DAYS(CURRENT_DATE,-1) 
                AND TO_TIMESTAMP( PO_DATE ||' ' || LEFT(PO_HOUR, 2) || ':00:00') 
		    	<= ADD_SECONDS(CURRENT_TIMESTAMP ,-7200) --teste Alinne
		    GROUP BY 
		        SUBSIDIARY,
		        PO_DATE,
		        DAYOFMONTH(PO_DATE),
		        LEFT(PO_HOUR, 2) || ':00:00'
		        HAVING COUNT(DISTINCT PO_ORDERID) > 0
		);
		/*-------------------------------------------------------------------------------------------------*/
		--Retorna pedidos da origem
		CREATE LOCAL TEMPORARY TABLE #TMP_PO_QTY_ORIGEM AS (
		    SELECT 
		        SUBSIDIARY,
		        PO_DATE,
		        DAYOFMONTH(PO_DATE) 							AS "DAY",
		        LEFT(PO_HOUR, 2) || ':00:00' 					AS "HOUR",
		        COUNT(DISTINCT PO_ORDERID) 						AS TOTAL_ORDERS
		    FROM 
		    	OW_LAO.VIEW_ORDERS_GOVERNANCE_LAO 
		    WHERE 
		    	DATA_SOURCE <> 'OW_LAO.ODS_SALES_CONTROL_TOWER_TABLE'
		    	AND PO_DATE >= ADD_DAYS(CURRENT_DATE,-1) 
		    	AND TO_TIMESTAMP( PO_DATE ||' ' || LEFT(PO_HOUR, 2) || ':00:00') 
		    	<= ADD_SECONDS(CURRENT_TIMESTAMP ,-7200) --teste Alinne
		    GROUP BY 
		        SUBSIDIARY,
		        PO_DATE,
		        DAYOFMONTH(PO_DATE),
				LEFT(PO_HOUR, 2) || ':00:00'
			    HAVING COUNT(DISTINCT PO_ORDERID) > 0
		);
		/*-------------------------------------------------------------------------------------------------*/
		--Join entre origem e destino(Control Tower)
		CREATE LOCAL TEMPORARY TABLE #TMP_PO_QTY_FINAL AS (
			SELECT DISTINCT 
			    A.SUBSIDIARY,
			    A.PO_DATE,
			    A."DAY",
			    A.HOUR,
			    IFNULL(A.TOTAL_ORDERS,0) 		AS "PO_QTY_ORIGEM",
			    IFNULL(B.TOTAL_ORDERS,0) 		AS "PO_QTY_CONTROL_TOWER",
			    CASE 
			        WHEN IFNULL(B.TOTAL_ORDERS,0) > 0 AND IFNULL(A.TOTAL_ORDERS,0) > 0  
			        THEN ( IFNULL(B.TOTAL_ORDERS,0) / IFNULL(A.TOTAL_ORDERS,0) ) * 100
			        ELSE 0
			    END AS "ORDER_RATIO"
			FROM 
				#TMP_PO_QTY_ORIGEM A
			LEFT JOIN 
			 	#TMP_PO_QTY_CONTROL_TOWER B
			ON 
				A.SUBSIDIARY 	= B.SUBSIDIARY
				AND A."DAY" 	= B."DAY"
				AND A."HOUR" 	= B."HOUR"	
				
				WHERE B.TOTAL_ORDERS > 0
				
			ORDER BY 
				SUBSIDIARY,
				A."HOUR" DESC
		);
	
		/*-------------------------------------------------------------------------------------------------*/
-- teste Alinne - adicionado para verificar a atualização 26/11/2024
 DELETE FROM OW_LAO.ODS_MONITORING_BI_LAO_PROCCESS_ALERT_CONTROL_TOWER_X_ORIGEM
  WHERE PO_DATE = CURRENT_DATE;
	
	
		/*-------------------------------------------------------------------------------------------------*/
		--Atualização da tabela final ODS comparação origem / destino
		MERGE INTO 
		 	OW_LAO.ODS_MONITORING_BI_LAO_PROCCESS_ALERT_CONTROL_TOWER_X_ORIGEM	AS A
		USING 
			#TMP_PO_QTY_FINAL 	AS B 
		ON 
			A.SUBSIDIARY 		= B.SUBSIDIARY
			AND A.PO_DATE 		= B.PO_DATE
			AND A."DAY" 		= B."DAY"
			AND A."HOUR" 		= B."HOUR"	
		WHEN MATCHED THEN UPDATE SET 
			A.PO_QTY_ORIGEM 		= B.PO_QTY_ORIGEM,  
			A.PO_QTY_CONTROL_TOWER 	= B.PO_QTY_CONTROL_TOWER,
			A.ORDER_RATIO			= B.ORDER_RATIO
		 WHEN NOT MATCHED THEN INSERT(
		 	SUBSIDIARY,
		 	PO_DATE,
		 	"DAY",
		 	"HOUR",
		 	PO_QTY_ORIGEM,
		 	PO_QTY_CONTROL_TOWER,
		 	ORDER_RATIO
		 )
		 VALUES (
		 	B.SUBSIDIARY,
		 	B.PO_DATE,
		 	B."DAY",
		 	B."HOUR",
		 	B.PO_QTY_ORIGEM,
		 	B.PO_QTY_CONTROL_TOWER,
		 	B.ORDER_RATIO
		);
		/*-------------------------------------------------------------------------------------------------*/
		--Drop #tables
		DROP TABLE #TMP_PO_QTY_ORIGEM;	
		DROP TABLE #TMP_PO_QTY_CONTROL_TOWER;
		DROP TABLE #TMP_PO_QTY_FINAL; 
		/*-------------------------------------------------------------------------------------------------*/
		--Retorno dos dados.
		SELECT 
			*
		FROM 
			OW_LAO.ODS_MONITORING_BI_LAO_PROCCESS_ALERT_CONTROL_TOWER_X_ORIGEM
		WHERE 
			PO_DATE >= ADD_DAYS(CURRENT_DATE,-1) ;
	END;	
	ELSE
		SELECT 'Procedimento não declaro' AS CONSULTA FROM DUMMY;		
	END IF;
END;