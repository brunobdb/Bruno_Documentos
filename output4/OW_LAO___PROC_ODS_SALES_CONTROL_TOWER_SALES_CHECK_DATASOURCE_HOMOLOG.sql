CREATE PROCEDURE OW_LAO.PROC_ODS_SALES_CONTROL_TOWER_SALES_CHECK_DATASOURCE_HOMOLOG()
LANGUAGE SQLSCRIPT AS
BEGIN
    -- Dataset de ecommerce_orders
    WITH ecommerce_orders AS ( 
        SELECT 
            MAX(COALESCE(po_source_last_update_date, po_source_insert_date)) AS last_data,
            'ods_sales_control_tower_table' AS origin,
            CASE 
                WHEN subsidiary LIKE 'SELA%' THEN 'SELA' 
                ELSE subsidiary 
            END AS subsidiary ,
            CASE 
                WHEN CAST(po_source_last_update_date AS DATE) = CURRENT_DATE THEN 'OK'
                ELSE 'NOT OK'
            END AS status,
            country
        FROM ow_lao.ods_sales_control_tower_table
        WHERE po_plataform_datasource NOT IN ('ow_lao.ods_global_bi_sales', 'u_prj_ecom_synapcom.ft_ecom_order')
          AND (subsidiary, country, po_source_last_update_date) IN (
              SELECT 
                  subsidiary, 
                  country,
                  MAX(po_source_last_update_date) AS po_source_last_update_date
              FROM ow_lao.ods_sales_control_tower_table
              WHERE CAST(po_source_last_update_date AS DATE) BETWEEN ADD_DAYS(CURRENT_DATE, -10) AND CURRENT_DATE
              GROUP BY subsidiary, country
          )
        GROUP BY po_source_last_update_date, subsidiary, country
        ORDER BY subsidiary, country
    ), 
    -- Dataset de complementary_data
    complementary_data AS (
        SELECT 
            MAX(nerp_last_update_date) AS sales_order_tracking_timestamp,
            CASE
                WHEN SECONDS_BETWEEN(MAX(nerp_last_update_date), CURRENT_TIMESTAMP) / 60 <= 120 THEN 'OK'
                ELSE 'NOT OK'
            END AS sales_order_tracking_status,
            MAX(nerp_outbound_last_update_date) AS outbound_timestamp,
            CASE
                WHEN SECONDS_BETWEEN(MAX(nerp_outbound_last_update_date), CURRENT_TIMESTAMP) / 60 <= 60 THEN 'OK'
                ELSE 'NOT OK'
            END AS outbound_status,
            MAX(ebi_last_update_date) AS global_bi_timestamp,
            CASE
                WHEN SECONDS_BETWEEN(MAX(ebi_last_update_date), CURRENT_TIMESTAMP) / 60 <= 1440 THEN 'OK'
                ELSE 'NOT OK'
            END AS global_bi_status,
            MAX(po_source_payment_last_update_date) AS payment_timestamp,
            CASE
                WHEN SECONDS_BETWEEN(MAX(po_source_payment_last_update_date), CURRENT_TIMESTAMP) / 60 <= 60 THEN 'OK'
                ELSE 'NOT OK'
            END AS payment_status,
            NULL AS country  ,
            NULL AS subsidiary 
        FROM OW_LAO.ODS_SALES_CONTROL_TOWER_TABLE
    )   
    -- União dos dados com o campo country incluído
    SELECT 
        MAP(element_number, 
            1, 'Sales Order Tracking',
            2, 'Outbound',
            3, 'Global BI Files',
            4, 'Payments'
        ) AS origin,
        MAP(element_number, 
            1, sales_order_tracking_status,
            2, outbound_status,
            3, global_bi_status,
            4, payment_status
        ) AS status,
        MAP(element_number, 
            1, sales_order_tracking_timestamp,
            2, outbound_timestamp,
            3, global_bi_timestamp,
            4, payment_timestamp
        ) AS last_data,
        country -- Incluído para alinhar os campos
    FROM complementary_data
    CROSS JOIN SERIES_GENERATE_INTEGER(1, 1, 5) 
    UNION ALL
    SELECT 
        origin,
        status,
        last_data,
        country
    FROM ecommerce_orders;
END
