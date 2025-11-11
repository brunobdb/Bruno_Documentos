-- CREATE OR REPLACE PROCEDURE ow_lao.proc_monitoring_bi_lao_proccess_raw_vtex_ssg_br_shop_sales_global_bi()
-- LANGUAGE PLvSQL AS $$
-- DECLARE
--     default_searching_timestamp TIMESTAMP := TIMESTAMP '2024-08-01 00:00:00';
--     start_searching_timestamp   TIMESTAMP := NULL;
--     end_searching_timestamp     TIMESTAMP := NULL;
-- BEGIN
--     SELECT CASE 
--                 WHEN TIMESTAMPADD(DAY, -3, CURRENT_TIMESTAMP) < default_searching_timestamp
--                 THEN default_searching_timestamp
--                 ELSE TIMESTAMPADD(DAY, -3, CURRENT_TIMESTAMP)
--            END AS start_ts
--          , TIMESTAMPADD(SECOND, -3600, MAX(last_update_files)) AS end_ts
--       INTO start_searching_timestamp
--          , end_searching_timestamp
--       FROM u_prj_ecom.raw_feed_send_estore;
-- 
--     SELECT a.creation_date
--          , a.order_id
--          , b.ref_id
--          , a.status
--          , a.created_at
--          , a.updated_at
--       FROM u_prj_ecom.raw_vtex_ssg_br_shop_sales_order      a
--       JOIN u_prj_ecom.raw_vtex_ssg_br_shop_sales_order_item b ON b.order_id       = a.order_id
--  LEFT JOIN OW_LAO.TF_D2C_PO_VTEX_TRADE_IN                   c ON c.order_id       = a.order_id
--                                                               AND c.SKU_ID_BR_SHOP = b.sku_id
--                                                               AND c.SKU_ID_BR_SHOP = c.TRADE_IN_SKUID
--  LEFT JOIN OW_LAO.TF_D2C_PO_VTEX_TRADE_IN                   d ON d.order_id       = a.order_id
--                                                               AND d.SKU_ID_BR_SHOP = b.sku_id
--      WHERE COALESCE(a.updated_at, a.created_at) BETWEEN start_searching_timestamp
--                                                    AND end_searching_timestamp
--        AND NOT EXISTS(
--                 SELECT 1
--                   FROM u_prj_ecom.raw_vtex_ssg_br_shop_sales_order_item_components bb
--                  WHERE bb.order_id = a.order_id
--            )
--        AND NOT EXISTS(
--                 SELECT 1
--                   FROM u_prj_ecom.raw_feed_send_estore aa
--                  WHERE aa.order_code   = a.order_id
--                    AND aa.product_code = b.ref_id
--                    AND CASE aa.order_status
--                             WHEN 'payment rejected' THEN 'canceled'
--                             ELSE aa.order_status
--                        END = a.status                                                
--            )
--        AND NOT EXISTS(
--                 SELECT 1
--                   FROM u_prj_ecom.raw_feed_send_estore aa
--                  WHERE aa.order_code   = a.order_id
--                    AND aa.product_code = b.ref_id
--                    AND CASE aa.order_status
--                             WHEN 'payment rejected' THEN 'cancel'
--                             ELSE aa.order_status
--                        END = a.status                                                
--            )
--        AND NOT EXISTS(
--                 SELECT 1
--                   FROM u_prj_ecom.raw_feed_send_estore aa
--                  WHERE aa.order_code   = a.order_id
--                    AND aa.product_code = b.ref_id
--                    AND aa.order_status = 'canceled'
--                    AND a.status        = 'cancel'
--            )           
--        AND NOT EXISTS(
--                 SELECT 1
--                   FROM u_prj_ecom.raw_feed_send_estore aa
--                  WHERE aa.order_code   = a.order_id
--                    AND aa.product_code = b.ref_id
--                    AND aa.order_status = 'delivered'                                       
--            )
--     UNION ALL    
--     SELECT a.creation_date
--          , a.order_id
--          , e.ref_id
--          , a.status
--          , a.created_at
--          , a.updated_at
--       FROM u_prj_ecom.raw_vtex_ssg_br_shop_sales_order                 a
--       JOIN u_prj_ecom.raw_vtex_ssg_br_shop_sales_order_item            b ON b.order_id       = a.order_id
--       JOIN u_prj_ecom.raw_vtex_ssg_br_shop_sales_order_item_components e ON e.order_id       = a.order_id
--                                                                          AND e.sku_id         = b.sku_id
--  LEFT JOIN OW_LAO.TF_D2C_PO_VTEX_TRADE_IN                              c ON c.order_id       = a.order_id
--                                                                          AND c.SKU_ID_BR_SHOP = b.sku_id
--                                                                          AND c.SKU_ID_BR_SHOP = c.TRADE_IN_SKUID
--  LEFT JOIN OW_LAO.TF_D2C_PO_VTEX_TRADE_IN                              d ON d.order_id       = a.order_id
--                                                                          AND d.SKU_ID_BR_SHOP = b.sku_id
--      WHERE COALESCE(a.updated_at, a.created_at) BETWEEN start_searching_timestamp
--                                                    AND end_searching_timestamp
--        AND NOT EXISTS(
--                 SELECT 1
--                   FROM u_prj_ecom.raw_feed_send_estore aa
--                  WHERE aa.order_code   = a.order_id
--                    AND aa.product_code = e.ref_id
--                    AND CASE aa.order_status
--                             WHEN 'payment rejected' THEN 'canceled'
--                             ELSE aa.order_status
--                        END = a.status 
--            )
--        AND NOT EXISTS(
--                 SELECT 1
--                   FROM u_prj_ecom.raw_feed_send_estore aa
--                  WHERE aa.order_code   = a.order_id
--                    AND aa.product_code = e.ref_id
--                    AND aa.order_status = 'canceled'
--                    AND a.status        = 'cancel'
--            )           
--        AND NOT EXISTS(
--                 SELECT 1
--                   FROM u_prj_ecom.raw_feed_send_estore aa
--                  WHERE aa.order_code   = a.order_id
--                    AND aa.product_code = e.ref_id
--                    AND aa.order_status = 'delivered'                                       
--            )
--     UNION ALL
--     SELECT a.creation_date
--          , a.order_id
--          , b.ref_id
--          , a.status
--          , a.created_at
--          , a.updated_at
--       FROM u_prj_ecom.raw_vtex_ssg_br_shop_sales_order      a
--       JOIN u_prj_ecom.raw_vtex_ssg_br_shop_sales_order_item b ON b.order_id       = a.order_id
--      WHERE COALESCE(a.updated_at, a.created_at) BETWEEN start_searching_timestamp
--                                                    AND end_searching_timestamp
--        AND NOT EXISTS(
--                 SELECT 1
--                   FROM u_prj_ecom.raw_vtex_ssg_br_shop_sales_order_item_components bb
--                  WHERE bb.order_id = a.order_id
--            )
--        AND NOT EXISTS(
--                 SELECT 1
--                   FROM u_prj_ecom.raw_feed_send_estore aa
--                  WHERE aa.order_code   = a.order_id
--                    AND aa.product_code = b.ref_id
--            );
-- END;
-- $$;
-- ERROR: Severity: ROLLBACK, Message: PL/vSQL parser failed at 136.13 of source string: syntax error, unexpected ;, expecting INTO, Sqlstate: 42601, Position: 6664, Routine: error, File: /data/jenkins/workspace/RE-ReleaseBuilds/RE-Nibbler/server/vertica/Proc/PLvSQL/Parser.cpp, Line: 177, Error Code: 10448, 
CREATE OR REPLACE PROCEDURE ow_lao.proc_monitoring_bi_lao_proccess_raw_vtex_ssg_br_shop_sales_global_bi()
LANGUAGE PLvSQL AS $$
DECLARE
    default_searching_timestamp TIMESTAMP := TIMESTAMP '2024-08-01 00:00:00';
    start_searching_timestamp   TIMESTAMP := NULL;
    end_searching_timestamp     TIMESTAMP := NULL;
BEGIN
    SELECT CASE 
                WHEN TIMESTAMPADD(DAY, -3, CURRENT_TIMESTAMP) < default_searching_timestamp
                THEN default_searching_timestamp
                ELSE TIMESTAMPADD(DAY, -3, CURRENT_TIMESTAMP)
           END AS start_ts
         , TIMESTAMPADD(SECOND, -3600, MAX(last_update_files)) AS end_ts
      INTO start_searching_timestamp
         , end_searching_timestamp
      FROM u_prj_ecom.raw_feed_send_estore;

    -- Prepare temp result table
    PERFORM CREATE LOCAL TEMP TABLE LTT_MONITORING_VTEX ON COMMIT PRESERVE ROWS AS
      SELECT a.creation_date
           , a.order_id
           , b.ref_id
           , a.status
           , a.created_at
           , a.updated_at
        FROM u_prj_ecom.raw_vtex_ssg_br_shop_sales_order      a
        JOIN u_prj_ecom.raw_vtex_ssg_br_shop_sales_order_item b ON b.order_id       = a.order_id
   LEFT JOIN OW_LAO.TF_D2C_PO_VTEX_TRADE_IN                   c ON c.order_id       = a.order_id
                                                                AND c.SKU_ID_BR_SHOP = b.sku_id
                                                                AND c.SKU_ID_BR_SHOP = c.TRADE_IN_SKUID
   LEFT JOIN OW_LAO.TF_D2C_PO_VTEX_TRADE_IN                   d ON d.order_id       = a.order_id
                                                                AND d.SKU_ID_BR_SHOP = b.sku_id
       WHERE 1=0; -- structure only

    -- Populate temp result table
    PERFORM INSERT INTO LTT_MONITORING_VTEX
    SELECT a.creation_date
         , a.order_id
         , b.ref_id
         , a.status
         , a.created_at
         , a.updated_at
      FROM u_prj_ecom.raw_vtex_ssg_br_shop_sales_order      a
      JOIN u_prj_ecom.raw_vtex_ssg_br_shop_sales_order_item b ON b.order_id       = a.order_id
 LEFT JOIN OW_LAO.TF_D2C_PO_VTEX_TRADE_IN                   c ON c.order_id       = a.order_id
                                                              AND c.SKU_ID_BR_SHOP = b.sku_id
                                                              AND c.SKU_ID_BR_SHOP = c.TRADE_IN_SKUID
 LEFT JOIN OW_LAO.TF_D2C_PO_VTEX_TRADE_IN                   d ON d.order_id       = a.order_id
                                                              AND d.SKU_ID_BR_SHOP = b.sku_id
     WHERE COALESCE(a.updated_at, a.created_at) BETWEEN start_searching_timestamp
                                                   AND end_searching_timestamp
       AND NOT EXISTS(
                SELECT 1
                  FROM u_prj_ecom.raw_vtex_ssg_br_shop_sales_order_item_components bb
                 WHERE bb.order_id = a.order_id
           )
       AND NOT EXISTS(
                SELECT 1
                  FROM u_prj_ecom.raw_feed_send_estore aa
                 WHERE aa.order_code   = a.order_id
                   AND aa.product_code = b.ref_id
                   AND CASE aa.order_status
                            WHEN 'payment rejected' THEN 'canceled'
                            ELSE aa.order_status
                       END = a.status                                                
           )
       AND NOT EXISTS(
                SELECT 1
                  FROM u_prj_ecom.raw_feed_send_estore aa
                 WHERE aa.order_code   = a.order_id
                   AND aa.product_code = b.ref_id
                   AND CASE aa.order_status
                            WHEN 'payment rejected' THEN 'cancel'
                            ELSE aa.order_status
                       END = a.status                                                
           )
       AND NOT EXISTS(
                SELECT 1
                  FROM u_prj_ecom.raw_feed_send_estore aa
                 WHERE aa.order_code   = a.order_id
                   AND aa.product_code = b.ref_id
                   AND aa.order_status = 'canceled'
                   AND a.status        = 'cancel'
           )           
       AND NOT EXISTS(
                SELECT 1
                  FROM u_prj_ecom.raw_feed_send_estore aa
                 WHERE aa.order_code   = a.order_id
                   AND aa.product_code = b.ref_id
                   AND aa.order_status = 'delivered'                                       
           )
    UNION ALL    
    SELECT a.creation_date
         , a.order_id
         , e.ref_id
         , a.status
         , a.created_at
         , a.updated_at
      FROM u_prj_ecom.raw_vtex_ssg_br_shop_sales_order                 a
      JOIN u_prj_ecom.raw_vtex_ssg_br_shop_sales_order_item            b ON b.order_id       = a.order_id
      JOIN u_prj_ecom.raw_vtex_ssg_br_shop_sales_order_item_components e ON e.order_id       = a.order_id
                                                                         AND e.sku_id         = b.sku_id
 LEFT JOIN OW_LAO.TF_D2C_PO_VTEX_TRADE_IN                              c ON c.order_id       = a.order_id
                                                                         AND c.SKU_ID_BR_SHOP = b.sku_id
                                                                         AND c.SKU_ID_BR_SHOP = c.TRADE_IN_SKUID
 LEFT JOIN OW_LAO.TF_D2C_PO_VTEX_TRADE_IN                              d ON d.order_id       = a.order_id
                                                                         AND d.SKU_ID_BR_SHOP = b.sku_id
     WHERE COALESCE(a.updated_at, a.created_at) BETWEEN start_searching_timestamp
                                                   AND end_searching_timestamp
       AND NOT EXISTS(
                SELECT 1
                  FROM u_prj_ecom.raw_feed_send_estore aa
                 WHERE aa.order_code   = a.order_id
                   AND aa.product_code = e.ref_id
                   AND CASE aa.order_status
                            WHEN 'payment rejected' THEN 'canceled'
                            ELSE aa.order_status
                       END = a.status 
           )
       AND NOT EXISTS(
                SELECT 1
                  FROM u_prj_ecom.raw_feed_send_estore aa
                 WHERE aa.order_code   = a.order_id
                   AND aa.product_code = e.ref_id
                   AND aa.order_status = 'canceled'
                   AND a.status        = 'cancel'
           )           
       AND NOT EXISTS(
                SELECT 1
                  FROM u_prj_ecom.raw_feed_send_estore aa
                 WHERE aa.order_code   = a.order_id
                   AND aa.product_code = e.ref_id
                   AND aa.order_status = 'delivered'                                       
           )
    UNION ALL
    SELECT a.creation_date
         , a.order_id
         , b.ref_id
         , a.status
         , a.created_at
         , a.updated_at
      FROM u_prj_ecom.raw_vtex_ssg_br_shop_sales_order      a
      JOIN u_prj_ecom.raw_vtex_ssg_br_shop_sales_order_item b ON b.order_id       = a.order_id
     WHERE COALESCE(a.updated_at, a.created_at) BETWEEN start_searching_timestamp
                                                   AND end_searching_timestamp
       AND NOT EXISTS(
                SELECT 1
                  FROM u_prj_ecom.raw_vtex_ssg_br_shop_sales_order_item_components bb
                 WHERE bb.order_id = a.order_id
           )
       AND NOT EXISTS(
                SELECT 1
                  FROM u_prj_ecom.raw_feed_send_estore aa
                 WHERE aa.order_code   = a.order_id
                   AND aa.product_code = b.ref_id
           );
END;
$$;

-- CALL ow_lao.proc_monitoring_bi_lao_proccess_raw_vtex_ssg_br_shop_sales_global_bi();
-- ERROR: Severity: ERROR, Message: Relation "u_prj_ecom.raw_feed_send_estore" does not exist, Sqlstate: 42V01, Where: PL/vSQL procedure proc_monitoring_bi_lao_proccess_raw_vtex_ssg_br_shop_sales_global_bi line 7 at static SQL, Routine: throwRelationDoesNotExist, File: /data/jenkins/workspace/RE-ReleaseBuilds/RE-Nibbler/server/vertica/Catalog/CatalogLookup.cpp, Line: 4341, Error Code: 4568, 
-- CALL ow_lao.proc_monitoring_bi_lao_proccess_raw_vtex_ssg_br_shop_sales_global_bi();
-- ERROR: Severity: ERROR, Message: Relation "u_prj_ecom.raw_feed_send_estore" does not exist, Sqlstate: 42V01, Where: PL/vSQL procedure proc_monitoring_bi_lao_proccess_raw_vtex_ssg_br_shop_sales_global_bi line 7 at static SQL, Routine: throwRelationDoesNotExist, File: /data/jenkins/workspace/RE-ReleaseBuilds/RE-Nibbler/server/vertica/Catalog/CatalogLookup.cpp, Line: 4341, Error Code: 4568, 
