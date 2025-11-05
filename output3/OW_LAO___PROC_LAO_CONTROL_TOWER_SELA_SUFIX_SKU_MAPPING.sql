CREATE PROCEDURE OW_LAO.PROC_LAO_CONTROL_TOWER_SELA_SUFIX_SKU_MAPPING
LANGUAGE SQLSCRIPT AS
    BEGIN 
 
 CREATE LOCAL TEMPORARY TABLE #TMP_CONTROL_TOWER_SELA_SUFIX_SKU_MAPPING 
     AS(
 
  SELECT DISTINCT 
            subsidiary
            ,country
            ,po_storename
            ,biz_type
            ,biz_type_ebi_hq
            ,SKU_MAPPING
            FROM (
        SELECT DISTINCT
                a.SUBSIDIARY
               ,a.COUNTRY 
               ,a.PO_STORENAME
               ,a.BIZ_TYPE
               ,a.BIZ_TYPE_EBI_HQ
               ,a.PO_SKU
               ,substring(
                             a.PO_SKU
                           , locate(a.PO_SKU, '-', -1)
                           , length(a.PO_SKU)
                   )                                    as SKU_MAPPING
          from ow_lao.ODS_SALES_CONTROL_TOWER_TABLE a
         WHERE client_subsidiary_id in (7,8,9,10,11,12,13,14,15,16,17,18,19)
             AND LENGTH (substring(a.PO_SKU, locate(a.PO_SKU, '-', -1), length(a.PO_SKU))) >=3
             AND substring(a.PO_SKU, locate(a.PO_SKU, '-', -1), length(a.PO_SKU)) NOT like '%/%'      
             AND a.PO_SKU LIKE '%-%'
             and po_sitecode not in ('samsungpy', 'samsungpyepp', 'samsunguy', 'samsunguyb2b2c')
             and substring(a.PO_SKU, locate(a.PO_SKU, '-', -1) - 3, 1) != '+'
             and substring(a.PO_SKU, locate(a.PO_SKU, '-', -1) - 2, 2) not in ('SM', 'VG')
             and locate(a.PO_SKU, '-', -1) > 3
                       AND NOT EXISTS (
                                     SELECT 1 
                                       FROM OW_MD.SALES_CHANNEL aa
                                      WHERE lower(aa.country)    = lower(a.country)
                                        and lower(aa.identifier) = lower(a.po_sitecode)
                                        and aa.sku_mapping       = substring(
                                                                                 a.po_sku
                                                                              , locate(a.po_sku, '-', -1)
                                                                              , length(a.po_sku)
                                                                   ) 
                             )
                         AND NOT EXISTS (SELECT 1 FROM ow_lao.DIM_LAO_CRP_CS_STORENAME ab
                                    WHERE ab.sku_mapping = substring(a.PO_SKU,locate(PO_SKU, '-', -1),length(PO_SKU)))
             AND NOT EXISTS (SELECT 1 FROM OW_LAO.TMP_VL_CONTROL_TOWER_SKU_SUFIX_MAPPING_LAO ac
                                    WHERE ac.sku_mapping = substring(a.PO_SKU,locate(PO_SKU, '-', -1),length(PO_SKU))
                                          AND ac.status_lao = 'NO'))
                                          WHERE SKU_MAPPING NOT IN ('-85','-70','-60','-DOx2','-DOx3','-gift','-Gift','-GIFT','-gratis','-promo','-s23')
  );
    
                    
           SELECT * FROM #TMP_CONTROL_TOWER_SELA_SUFIX_SKU_MAPPING;
                                
             END