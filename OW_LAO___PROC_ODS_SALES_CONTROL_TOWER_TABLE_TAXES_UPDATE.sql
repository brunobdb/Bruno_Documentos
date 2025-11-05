CREATE OR REPLACE PROCEDURE ow_lao.proc_ods_sales_control_tower_table_taxes_update()
 LANGUAGE PLvSQL AS $$
BEGIN
        PERFORM UPDATE ow_lao.ods_sales_control_tower_table a
           SET net_revenue        = a.po_totalprice_usd   - (a.po_totalprice_usd   * b.tax_value)
             , net_revenue_local  = a.po_totalprice_local - (a.po_totalprice_local * b.tax_value)
          FROM ow_lao.aux_sales_control_tower_table_taxes b
         WHERE b.subsidiary_id                     = a.client_subsidiary_id
           AND b.sku_division                      = a.division
           AND b.sku_product_group                 = a.product_group 
           AND b.sku_minimun_value_local_currency <= a.po_totalprice_local
           AND b.sku_divisions_all                 = false
           AND b.sku_product_group_all             = false   
           AND (a.net_revenue_local IS NULL OR a.net_revenue = 0)
           AND a.po_plataform_datasource <> 'ow_lao.ods_global_bi_sales';

        PERFORM UPDATE ow_lao.ods_sales_control_tower_table a
           SET net_revenue        = a.po_totalprice_usd   - (a.po_totalprice_usd   * b.tax_value)
             , net_revenue_local  = a.po_totalprice_local - (a.po_totalprice_local * b.tax_value)  
          FROM ow_lao.aux_sales_control_tower_table_taxes b
         WHERE b.subsidiary_id                     = a.client_subsidiary_id
           AND b.sku_division                      = a.division
           AND b.sku_product_group                 = a.product_group 
           AND b.sku_minimun_value_local_currency <= a.po_totalprice_local
           AND b.sku_divisions_all                 = false
           AND b.sku_product_group_all             = true  
           AND (a.net_revenue_local IS NULL OR a.net_revenue = 0)
           AND a.po_plataform_datasource <> 'ow_lao.ods_global_bi_sales';
         
        PERFORM UPDATE ow_lao.ods_sales_control_tower_table a
           SET net_revenue        = a.po_totalprice_usd   - (a.po_totalprice_usd   * b.tax_value)
             , net_revenue_local  = a.po_totalprice_local - (a.po_totalprice_local * b.tax_value)  
          FROM ow_lao.aux_sales_control_tower_table_taxes b
         WHERE b.subsidiary_id                     = a.client_subsidiary_id
           AND b.sku_division                      = 'Unmaped'
           AND b.sku_minimun_value_local_currency <= a.po_totalprice_local
           AND b.sku_divisions_all                 = false
           AND a.division                          IS NULL
           AND (a.net_revenue_local IS NULL OR a.net_revenue = 0)
           AND a.po_plataform_datasource <> 'ow_lao.ods_global_bi_sales';

        PERFORM UPDATE ow_lao.ods_sales_control_tower_table a
           SET net_revenue        = a.po_totalprice_usd   - (a.po_totalprice_usd   * b.tax_value)
             , net_revenue_local  = a.po_totalprice_local - (a.po_totalprice_local * b.tax_value)           
          FROM ow_lao.aux_sales_control_tower_table_taxes b
         WHERE b.subsidiary_id                     = a.client_subsidiary_id
           AND b.sku_minimun_value_local_currency <= a.po_totalprice_local
           AND b.sku_divisions_all                 = true
           AND (a.net_revenue_local IS NULL OR a.net_revenue = 0)
           AND a.po_plataform_datasource <> 'ow_lao.ods_global_bi_sales';
         
         
        PERFORM UPDATE ow_lao.ods_sales_control_tower_table a
           SET net_revenue        = a.po_totalprice_usd
             , net_revenue_local  = a.po_totalprice_local
         WHERE  (a.net_revenue_local IS NULL OR a.net_revenue = 0)
           AND a.po_plataform_datasource <> 'ow_lao.ods_global_bi_sales';
     
END;
$$;

-- CALL ow_lao.proc_ods_sales_control_tower_table_taxes_update();