CREATE procedure ow_lao.proc_ods_orders_visuar
as
begin
                    drop table ow_lao.tmp_proc_ods_orders_visuar;
           create column table ow_lao.tmp_proc_ods_orders_visuar
               as (
                        select fecha_de_emision_del_movimiento 
                             , codigo_de_formulario 
                             , formulario 
                             , numero 
                             , razon_social 
                             , tipo_de_producto 
                             , descripcion 
                             , codigo_de_producto 
                             , descripcion_producto 
                             , cantidad_real 
                             , monto_sin_impuestos 
                             , abs(total_bonificado)                as total_bonificado 
                             , condicion_de_pago 
                             , canal_de_venta_kd 
                             , canal_de_venta_com
                             , a.formulario_origen
                             , a.nro_origen
                             , case a.formulario 
                                    when 'FACTURA'
                                    then 'Approved'
                                    when 'NOTA DE CRÉDITO'
                                    then 'returned'
                                    else null                        
                                end                                 as status     
                             , case upper(left(codigo_de_producto, 2))
                                    when 'SA'
                                    then substring(
                                            codigo_de_producto
                                           , 3
                                           , length(codigo_de_producto))    
                                     else codigo_de_producto
                                end                                 as reference_code
                              , cast(right(fecha_de_emision_del_movimiento, 4)
                                        || substring(fecha_de_emision_del_movimiento, 4,2)
                                        || left(fecha_de_emision_del_movimiento, 2)
                                  as date)                          as fecha_de_emision_del_movimiento_formated
                              , row_number()
                                    over(partition by a.codigo_de_formulario
                                                    , a.codigo_de_producto
                                                    , a.numero
                                             order by a.load_timestamp desc
                                    )                                as dedup
                          from ow_lao.raw_orders_visuar a
                         where 1 = 1 
                           and a.canal_de_venta_kd      in ('ONLINE-MELI', 'ONLINE-Market Place')     
                           and a.canal_de_venta_com not in ('TIENDA OFICIAL OSTER MELI', 'TIENDA OFICIAL SMARTLIFE MELI')               
               );
               
           delete from ow_lao.tmp_proc_ods_orders_visuar where dedup != 1;
           insert into ow_lao.ods_orders_visuar(
                       fecha_de_emision_del_movimiento 
                     , codigo_de_formulario 
                     , formulario 
                     , numero 
                     , razon_social 
                     , tipo_de_producto 
                     , descripcion 
                     , codigo_de_producto 
                     , descripcion_producto 
                     , cantidad_real 
                     , monto_sin_impuestos 
                     , total_bonificado 
                     , condicion_de_pago 
                     , canal_de_venta_kd 
                     , canal_de_venta_com
                     , status     
                     , reference_code
                     , fecha_de_emision_del_movimiento_formated
           )
        
                select fecha_de_emision_del_movimiento 
                     , codigo_de_formulario 
                     , formulario 
                     , numero 
                     , razon_social 
                     , tipo_de_producto 
                     , descripcion 
                     , codigo_de_producto 
                     , descripcion_producto 
                     , cantidad_real 
                     , monto_sin_impuestos 
                     , abs(total_bonificado)                as total_bonificado 
                     , condicion_de_pago 
                     , canal_de_venta_kd 
                     , canal_de_venta_com
                     , a.status                             as status     
                     , case upper(left(codigo_de_producto, 2))
                            when 'SA'
                            then substring(
                                    codigo_de_producto
                                   , 3
                                   , length(codigo_de_producto))    
                             else codigo_de_producto
                        end                                 as reference_code
                     , fecha_de_emision_del_movimiento_formated
                  from ow_lao.tmp_proc_ods_orders_visuar a
                 where a.formulario = 'FACTURA' 
                   and a.canal_de_venta_kd      in ('ONLINE-MELI', 'ONLINE-Market Place')     
                   and a.canal_de_venta_com not in ('TIENDA OFICIAL OSTER MELI', 'TIENDA OFICIAL SMARTLIFE MELI') 
                   and not exists(
                            select 1
                              from ow_lao.ods_orders_visuar aa
                             where aa.codigo_de_formulario = a.codigo_de_formulario
                               and aa.codigo_de_producto   = a.codigo_de_producto
                               and aa.numero               = a.numero
                       );
                       
                update ow_lao.ods_orders_visuar a
                   set status            = 'returned'
                     , updated_timestamp = current_timestamp
                  from ow_lao.ods_orders_visuar          a
                  join ow_lao.tmp_proc_ods_orders_visuar b on b.formulario_origen  = a.codigo_de_formulario
                                                          and b.codigo_de_producto = a.codigo_de_producto
                                                          and b.nro_origen         = a.numero
                 where b.formulario = 'NOTA DE CRÉDITO' 
                   and a.canal_de_venta_kd      in ('ONLINE-MELI', 'ONLINE-Market Place')     
                   and a.canal_de_venta_com not in ('TIENDA OFICIAL OSTER MELI', 'TIENDA OFICIAL SMARTLIFE MELI') 
                   and a.status    != 'returned';
                 
           insert into ow_lao.ods_orders_visuar(
                       fecha_de_emision_del_movimiento 
                     , codigo_de_formulario 
                     , formulario 
                     , numero 
                     , razon_social 
                     , tipo_de_producto 
                     , descripcion 
                     , codigo_de_producto 
                     , descripcion_producto 
                     , cantidad_real 
                     , monto_sin_impuestos 
                     , total_bonificado 
                     , condicion_de_pago 
                     , canal_de_venta_kd 
                     , canal_de_venta_com
                     , status     
                     , reference_code
                     , fecha_de_emision_del_movimiento_formated
           )
        
                select fecha_de_emision_del_movimiento 
                     , codigo_de_formulario 
                     , formulario 
                     , numero 
                     , razon_social 
                     , tipo_de_producto 
                     , descripcion 
                     , codigo_de_producto 
                     , descripcion_producto 
                     , cantidad_real 
                     , monto_sin_impuestos 
                     , abs(total_bonificado)                as total_bonificado 
                     , condicion_de_pago 
                     , canal_de_venta_kd 
                     , canal_de_venta_com
                     , status                               as status     
                     , case upper(left(codigo_de_producto, 2))
                            when 'SA'
                            then substring(
                                    codigo_de_producto
                                   , 3
                                   , length(codigo_de_producto))    
                             else codigo_de_producto
                        end                                 as reference_code
                     , fecha_de_emision_del_movimiento_formated
                  from ow_lao.tmp_proc_ods_orders_visuar a
                 where formulario = 'NOTA DE CRÉDITO'  
                   and a.canal_de_venta_kd      in ('ONLINE-MELI', 'ONLINE-Market Place')     
                   and a.canal_de_venta_com not in ('TIENDA OFICIAL OSTER MELI', 'TIENDA OFICIAL SMARTLIFE MELI') 
                   and not exists(
                            select 1
                              from ow_lao.ods_orders_visuar aa
                             where aa.codigo_de_formulario = a.codigo_de_formulario
                               and aa.codigo_de_producto   = a.codigo_de_producto
                               and aa.numero               = a.numero
                       );                 
                       
    end