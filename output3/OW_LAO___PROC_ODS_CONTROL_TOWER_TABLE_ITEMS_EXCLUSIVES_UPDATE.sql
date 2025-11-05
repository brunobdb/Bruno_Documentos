CREATE PROCEDURE OW_LAO.proc_ods_control_tower_table_items_exclusives_update
 LANGUAGE SQLSCRIPT AS
 BEGIN
    update ow_lao.ods_sales_control_tower_table a
       set ITEM_EXCLUSIVE = 1
      from ow_lao.ods_sales_control_tower_table a
      join OW_LAO.ODS_LAO_PRODUCT_EXCLUSIVES_ITEMS      b on b.ITEM_EXCLUSIVES  = a.po_sku
      														AND b.SUBSIDIARY = a.SUBSIDIARY
      where a.ITEM_EXCLUSIVE = 0
 			AND a.PO_DATE BETWEEN b.DATE_START AND b.DATE_END
 		AND b.ACTIVE = TRUE;
      
   end      