CREATE procedure ow_lao.proc_monitoring_bi_lao_proccess
 LANGUAGE SQLSCRIPT AS
 BEGIN
 
    call ow_lao.proc_monitoring_bi_lao_proccess_system_reviews;
    call ow_lao.proc_monitoring_bi_lao_proccess_ft_ecom;
    call ow_lao.proc_monitoring_bi_lao_proccess_hybris;
    call ow_lao.proc_monitoring_bi_lao_proccess_sales_order_tracking;
    call ow_lao.proc_monitoring_bi_lao_proccess_depara;
    call ow_lao.proc_monitoring_bi_lao_proccess_globalbi;
    call ow_lao.proc_monitoring_bi_lao_proccess_vtex_seda;
    call ow_lao.proc_monitoring_bi_lao_proccess_hybris_files_sales_validation;
    
  end