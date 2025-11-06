CREATE OR REPLACE PROCEDURE OW_LAO.proc_ods_sales_control_tower_table()
LANGUAGE PLvSQL AS $$
BEGIN
    PERFORM CALL OW_LAO.PROC_ODS_SALES_CONTROL_TOWER_TABLE_RAW_VTEX_SSG();
    PERFORM CALL OW_LAO.PROC_ODS_SALES_CONTROL_TOWER_TABLE_U_PRJ_ECOM();
    PERFORM CALL OW_LAO.PROC_ODS_SALES_CONTROL_TOWER_TABLE_OW_LAO_ODS_HYBRIS_SALES(); 
    PERFORM CALL OW_LAO.PROC_ODS_SALES_CONTROL_TOWER_TABLE_NERP_UPDATE(); 
    PERFORM CALL OW_LAO.PROC_ODS_SALES_CONTROL_TOWER_TABLE_NERP_OUTBOUND_UPDATE();
    PERFORM CALL OW_LAO.PROC_ODS_SALES_CONTROL_TOWER_TABLE_GLOBALBI_UPDATE(); 
    PERFORM CALL OW_LAO.PROC_ODS_SALES_CONTROL_TOWER_TABLE_PREMIUM_MODELS_UPDATE(); 
    PERFORM CALL OW_LAO.PROC_ODS_SALES_CONTROL_TOWER_TABLE_DOLAR_VALUES_UPDATE();
    PERFORM CALL OW_LAO.PROC_ODS_SALES_CONTROL_TOWER_TABLE_DIM_PRODUCT_MAPPING_LAO_UPDATE();
    PERFORM CALL OW_LAO.PROC_ODS_SALES_CONTROL_TOWER_TABLE_TAXES_UPDATE();
    PERFORM CALL OW_LAO.PROC_ODS_SALES_CONTROL_TOWER_TABLE_OW_LAO_ODS_HYBRIS_PAYMENTS();
    PERFORM CALL OW_LAO.PROC_ODS_SALES_CONTROL_TOWER_TABLE_NERP_STATUS_CANCELED();
    PERFORM CALL OW_LAO.PROC_ODS_SALES_CONTROL_TOWER_TABLE_PARTNER_LEVEL();    
    PERFORM CALL OW_LAO.PROC_ODS_SALES_CONTROL_TOWER_TABLE_ELEGIBLE();
    PERFORM CALL OW_LAO.PROC_ODS_CONTROL_TOWER_TABLE_ITEMS_EXCLUSIVES_UPDATE();
END;
$$;

-- CALL OW_LAO.proc_ods_sales_control_tower_table();
-- ERROR: Severity: ERROR, Message: Relation "ow_md.dim_product" does not exist, Sqlstate: 42V01, Where: PL/vSQL procedure proc_ods_sales_control_tower_table_raw_vtex_ssg_br_shop line 7 at static SQL PL/vSQL procedure PROC_ODS_SALES_CONTROL_TOWER_TABLE_RAW_VTEX_SSG line 3 at static SQL PL/vSQL procedure proc_ods_sales_control_tower_table line 3 at static SQL, Routine: throwRelationDoesNotExist, File: /data/jenkins/workspace/RE-ReleaseBuilds/RE-Nibbler/server/vertica/Catalog/CatalogLookup.cpp, Line: 4341, Error Code: 4568, 
-- CALL OW_LAO.proc_ods_sales_control_tower_table();
-- ERROR: Severity: ERROR, Message: Relation "ow_md.dim_product" does not exist, Sqlstate: 42V01, Where: PL/vSQL procedure proc_ods_sales_control_tower_table_raw_vtex_ssg_br_shop line 7 at static SQL PL/vSQL procedure PROC_ODS_SALES_CONTROL_TOWER_TABLE_RAW_VTEX_SSG line 3 at static SQL PL/vSQL procedure proc_ods_sales_control_tower_table line 3 at static SQL, Routine: throwRelationDoesNotExist, File: /data/jenkins/workspace/RE-ReleaseBuilds/RE-Nibbler/server/vertica/Catalog/CatalogLookup.cpp, Line: 4341, Error Code: 4568, 
