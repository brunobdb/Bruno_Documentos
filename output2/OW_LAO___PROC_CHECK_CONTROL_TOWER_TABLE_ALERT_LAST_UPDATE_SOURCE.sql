CREATE  PROCEDURE OW_LAO.PROC_CHECK_CONTROL_TOWER_TABLE_ALERT_LAST_UPDATE_SOURCE
LANGUAGE SQLSCRIPT
AS
BEGIN
CREATE LOCAL TEMPORARY TABLE #DIMSUBSIDIARY_ALERT_TIMESTAMP_DEFAULT
     AS (      
          SELECT ID
               , SUBSIDIARY
               , COALESCE(TIMEZONE, -3) TIMEZONE
            FROM U_PRJ_ECOM.DIM_SUBSIDIARY
     );
        CREATE LOCAL TEMPORARY TABLE #ODS_SALES_CONTROL_TOWER_TABLE_ALERT_SOURCE_FILTER
     AS (       
       SELECT A.CLIENT_SUBSIDIARY_ID
            , A.SUBSIDIARY
            , A.PO_PLATAFORM_DATASOURCE
            , MAX(CAST(A.PO_DATE ||' '|| COALESCE(A.PO_HOUR, '00:00:00') AS TIMESTAMP)) AS PO_DATETIME
         FROM OW_LAO.ODS_SALES_CONTROL_TOWER_TABLE                           A
         JOIN OW_LAO.ODS_SDSLA_CONTROL_ALERT_SOURCE_FROM_CONTROL_TOWER_TABLE C ON C.PO_PLATAFORM_DATASOURCE = A.PO_PLATAFORM_DATASOURCE
                                                                              AND C.CLIENT_SUBSIDIARY_ID    = A.CLIENT_SUBSIDIARY_ID
                                                                              AND C.SUBSIDIARY              = A.SUBSIDIARY 
     GROUP BY A.CLIENT_SUBSIDIARY_ID
            , A.SUBSIDIARY
            , A.PO_PLATAFORM_DATASOURCE
     ORDER BY PO_DATETIME DESC
     );
    
    select A.PO_DATETIME
             , current_timestamp                                            timezone_brasil
             , add_seconds(
                      add_seconds(current_timestamp, 10800)
                    , timezone * 3600
               )                                                            timezone_local
             , A.CLIENT_SUBSIDIARY_ID
             , A.SUBSIDIARY
             , C.PO_PLATAFORM_DATASOURCE
             , B.TIMEZONE
             , C.GAP_IN_HOUR
             , SECONDS_BETWEEN(
                    PO_DATETIME
                    , add_seconds(
	                          add_seconds(current_timestamp, 10800)
	                        , timezone * 3600
	                    )
               ) /3600                                                      last_order_gap
             , case
                    when SECONDS_BETWEEN(
			                      PO_DATETIME
			                    , add_seconds(
			                              add_seconds(current_timestamp, 10800)
			                            , timezone * 3600
			                        )
			               ) /3600 > C.GAP_IN_HOUR
			         then 'GAP'
			         else 'NO GAP'
			   end                                                           gap_control
          from #ODS_SALES_CONTROL_TOWER_TABLE_ALERT_SOURCE_FILTER             a
          JOIN #DIMSUBSIDIARY_ALERT_TIMESTAMP_DEFAULT                         B ON  B.ID                     = A.CLIENT_SUBSIDIARY_ID
                                                                               AND B.SUBSIDIARY              = A.SUBSIDIARY
          JOIN OW_LAO.ODS_SDSLA_CONTROL_ALERT_SOURCE_FROM_CONTROL_TOWER_TABLE C ON C.PO_PLATAFORM_DATASOURCE = A.PO_PLATAFORM_DATASOURCE
                                                                               AND  C.CLIENT_SUBSIDIARY_ID   = A.CLIENT_SUBSIDIARY_ID
                                                                               AND  C.SUBSIDIARY             = A.SUBSIDIARY
         where 1 = 1
      group by a.PO_DATETIME   
             , A.CLIENT_SUBSIDIARY_ID
             , A.SUBSIDIARY
             , C.PO_PLATAFORM_DATASOURCE
             , B.TIMEZONE
             , C.GAP_IN_HOUR   
        having SECONDS_BETWEEN(
                                  PO_DATETIME
                                , add_seconds(
                                          add_seconds(current_timestamp, 10800)
                                        , timezone * 3600
                                    )
                           ) /3600 > C.GAP_IN_HOUR;	                                                           
                          
END