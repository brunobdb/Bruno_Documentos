CREATE OR REPLACE PROCEDURE OW_LAO.PROC_ODS_SALES_CONTROL_TOWER_TABLE_RAW_VTEX_SSG()
LANGUAGE PLvSQL AS $$
BEGIN
    PERFORM CALL OW_LAO.proc_ods_sales_control_tower_table_raw_vtex_ssg_br_shop();
    PERFORM CALL OW_LAO.PROC_ODS_SALES_CONTROL_TOWER_TABLE_RAW_VTEX_SSG_AR_SALES_ORDER();
    PERFORM CALL OW_LAO.PROC_ODS_SALES_CONTROL_TOWER_TABLE_RAW_VTEX_SSG_AR_SMB_SALES_ORDER();
    PERFORM CALL OW_LAO.PROC_ODS_SALES_CONTROL_TOWER_TABLE_RAW_VTEX_SSG_PY_SALES_ORDER();
    PERFORM CALL OW_LAO.PROC_ODS_SALES_CONTROL_TOWER_TABLE_RAW_VTEX_SSG_UY_SALES_ORDER();
END;
$$;

-- CALL OW_LAO.PROC_ODS_SALES_CONTROL_TOWER_TABLE_RAW_VTEX_SSG();
-- ERROR: Severity: ERROR, Message: Relation "ow_md.dim_product" does not exist, Sqlstate: 42V01, Where: PL/vSQL procedure proc_ods_sales_control_tower_table_raw_vtex_ssg_br_shop line 7 at static SQL PL/vSQL procedure PROC_ODS_SALES_CONTROL_TOWER_TABLE_RAW_VTEX_SSG line 3 at static SQL, Routine: throwRelationDoesNotExist, File: /data/jenkins/workspace/RE-ReleaseBuilds/RE-Nibbler/server/vertica/Catalog/CatalogLookup.cpp, Line: 4341, Error Code: 4568, 
-- CALL OW_LAO.PROC_ODS_SALES_CONTROL_TOWER_TABLE_RAW_VTEX_SSG();
-- ERROR: Severity: ERROR, Message: Relation "ow_md.dim_product" does not exist, Sqlstate: 42V01, Where: PL/vSQL procedure proc_ods_sales_control_tower_table_raw_vtex_ssg_br_shop line 7 at static SQL PL/vSQL procedure PROC_ODS_SALES_CONTROL_TOWER_TABLE_RAW_VTEX_SSG line 3 at static SQL, Routine: throwRelationDoesNotExist, File: /data/jenkins/workspace/RE-ReleaseBuilds/RE-Nibbler/server/vertica/Catalog/CatalogLookup.cpp, Line: 4341, Error Code: 4568, 
