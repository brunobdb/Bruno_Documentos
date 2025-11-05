CREATE PROCEDURE OW_SEDA_S.PRC_CE_MANAGEMENT_INFORMATION (IN SELECTED_SPMON VARCHAR(8)) AS 
BEGIN
	
DELETE FROM OW_SEDA_S.FT_CE_MANAGEMENT_INFORMATION WHERE SPMON = SELECTED_SPMON;
INSERT INTO OW_SEDA_S.FT_CE_MANAGEMENT_INFORMATION
select
	 g.cp_usd_sem_reversoes,
	 g.cp_usd cp_usd_com_reversoes,
	 g.inventory_elimination_usd,
	 g.hq_profit_usd,
	 g.c_op cp_operational_usd,
	 g.hq_op hq_operational_profit_usd,
	 g.non_op_income_loss non_operational_income_loss,
	 g.admin_expense,
	 g.sales_admin_expense_s_coop sales_admin_expense_sem_coop,
	 g.gm gross_margin,
	 g.cogs,
	 g.cogs_unit,
	 g.material_cost_unit,
	 g.base,
	 g.spmon,
	 g.quarter,
	 g.month,
	 g.division_description,
	 g.category,
	 g.line segmento_01,
	 g.sub_line segmento_02,
	 g.old_line ano_de_lancamento,
	 g.inch inches_btus_kgs,
	 g.serie,
	 g.hd technology_color,
	 g.smart,
	 g.qf_litros_3d litragem_quente_frio,
	 g.premium,
	 coalesce(case
		 when g.line in ('DUMMY','Others') then 'DUMMY'
		 when g.product is null then 'DUMMY'
		 when g.category = 'Ultrassom' then g.line
		 else p.set_unico end, h.linha, 'DUMMY') set_unico,
	 g.customer_name,
	 g.censo,
	 case
		 	--when upper(g.division_description) = 'DA' and upper(g.category) = 'AC' then coalesce(mmk.manager_rac, m.gerente_ac)
			--when upper(g.division_description) = 'DA' then coalesce(mmk.manager_wg, m.gerente_wg)
			--when upper(g.division_description) = 'AV' then coalesce(mmk.manager_av, m.gerente_ctv)
			when upper(g.division_description) = 'DA' and upper(g.category) = 'AC' and g.LINE = 'RAC' then upper(coalesce(mck.KAM_01, m.gerente_ac))
			when upper(g.division_description) = 'DA' and upper(g.category) = 'AC' and g.LINE <> 'RAC' then upper(coalesce(mck.KAM_01, m.gerente_sac))
			when upper(g.division_description) = 'DA' then upper(coalesce(mck.KAM_01, m.gerente_wg))
			when upper(g.division_description) IN ('AV', 'MON') then upper(coalesce(mck.KAM_01, m.gerente_ctv))
			else null
		end kam,
	 CASE
	 		--when upper(g.division_description) = 'DA' and upper(g.category) = 'AC' then coalesce(mmk.sr_manager_rac, m.sr_manager_ac)
	 		--when upper(g.division_description) = 'DA' then coalesce(mmk.sr_manager_wg, m.sr_manager_wg)
			--when upper(g.division_description) = 'AV' then coalesce(mmk.sr_manager_av, m.sr_manager_ctv)
			when upper(g.division_description) = 'DA' and upper(g.category) = 'AC' and g.LINE = 'RAC' then upper(m.sr_manager_ac)
			when upper(g.division_description) = 'DA' and upper(g.category) = 'AC' and g.LINE <> 'RAC' then upper(m.sr_manager_ac)
	 		when upper(g.division_description) = 'DA' then upper(coalesce(mck.SR_KAM, m.sr_manager_wg))
			when upper(g.division_description) IN ('AV', 'MON') then upper(coalesce(mck.SR_KAM, m.sr_manager_ctv))
			else null
	 end sr_kam,
	 CASE 
		when upper(g.division_description) = 'DA' and upper(g.category) = 'AC' and g.LINE = 'RAC' then upper(COALESCE(g.ap1, m.AP1_RAC))
		when upper(g.division_description) = 'DA' and upper(g.category) = 'AC' and g.LINE <> 'RAC' then upper(COALESCE(g.ap1, m.AP1_SAC))
	 	ELSE COALESCE(g.ap1, m.AP1_AV) 
	 END AP1,
	 g.online,
	 g.product sku,
	 g.customer customer_code,
	 g.bill_to_party bill_to_party_code,
	 g.payer payer_code,
	 g.ship_to_party ship_to_code,
	 g.division,
	 case
	 		when upper(g.division_description) in ('DA','AV') then m.client_type_tv_da
			when upper(g.division_description) = 'MON' then m.client_type_mon
			else null
	 end client_type,
	 case
	 		when upper(g.division_description) = 'HME' then m.cidade
			else null
	 end cidade,
	 case
	 		when upper(g.division_description) = 'HME' then m.uf
			else null
	 end uf,
	 coalesce(g.s_rrp,0) s_rrp,
	 coalesce(g.delear_disc,0) dealer_discount,
	 coalesce(g.s_return_amt,0) return_amount,
	 g.usd net_sales_usd,
	 g.gross_usd gross_sales_usd,
	 g.gross_usd_wo_icms_inc gross_sales_usd_sem_icms,
	 coalesce(g.accessory,0) accessory,
	 g.qty net_sales_qty,
	 g.net_sales_brl,
	 g.gross_brl gross_sales_brl,
	 g.gross_brl_wo_icms_inc gross_sales_brl_sem_icms,
	 case 
	 	when upper(g.division_description) in ('HME') then coalesce(g.s_sales_allowance,0) + coalesce(g.s_rebate,0) + coalesce(g.s_cash_discount,0) + coalesce(g.s_price_protection,0) + coalesce(g.s_co_op,0)
	 	else g.sales_deduction_total 
	 end sales_deduction_total,
	 case when upper(g.division_description) in ('HME') then coalesce(g.s_sales_allowance,0) else g.sales_allowance end sales_allowance,
	 g.rebate_tob,
	 case when upper(g.division_description) in ('HME') then coalesce(g.s_rebate,0) else g.rebate_sell_out end rebate_sell_out,
	 case when upper(g.division_description) in ('HME') then coalesce(g.s_cash_discount,0) else g.cach_discount end cash_discount,
	 case when upper(g.division_description) in ('HME') then coalesce(g.s_price_protection,0) else g.price_protection end price_protection,
	 case when upper(g.division_description) in ('HME') then coalesce(g.s_co_op,0) else g.coop_sa end coop_sa,
	 case when upper(g.division_description) in ('HME') then 0 else g.coop_tob end coop_tob,
	 CASE 
	 	WHEN COALESCE(mcp.TECHNOLOGY_ITEM, p.HD_FHD) IN ('QLED 8K', 'Neo QLED 8K') THEN '8K'
		WHEN COALESCE(mcp.TECHNOLOGY_ITEM, p.HD_FHD) IN ('Neo QLED') THEN 'Neo QLED'
		WHEN COALESCE(mcp.TECHNOLOGY_ITEM, p.HD_FHD) IN ('Lifestyle TV') THEN 'Lifestyle'
		ELSE COALESCE(mcp.TECHNOLOGY_ITEM, p.HD_FHD)
	END TECHNOLOGY_ITEM,
	 mcp."Q80+",
	 CASE 
		WHEN g.category = 'CTV' AND COALESCE(mcp.INCHES_ITEM, CASE WHEN length(ltrim(RIGHT(LEFT(g.product,4),2),' +-.0123456789')) = 0 THEN RIGHT(LEFT(g.product,4),2) END) = 32 THEN '32"'
		WHEN g.category = 'CTV' AND COALESCE(mcp.INCHES_ITEM, CASE WHEN length(ltrim(RIGHT(LEFT(g.product,4),2),' +-.0123456789')) = 0 THEN RIGHT(LEFT(g.product,4),2) END) BETWEEN 40 AND 46 THEN '40" - 43"'
		WHEN g.category = 'CTV' AND COALESCE(mcp.INCHES_ITEM, CASE WHEN length(ltrim(RIGHT(LEFT(g.product,4),2),' +-.0123456789')) = 0 THEN RIGHT(LEFT(g.product,4),2) END) BETWEEN 48 AND 50 THEN '50"'
		WHEN g.category = 'CTV' AND COALESCE(mcp.INCHES_ITEM, CASE WHEN length(ltrim(RIGHT(LEFT(g.product,4),2),' +-.0123456789')) = 0 THEN RIGHT(LEFT(g.product,4),2) END) BETWEEN 55 AND 60 THEN '55" - 60"'
		WHEN g.category = 'CTV' AND COALESCE(mcp.INCHES_ITEM, CASE WHEN length(ltrim(RIGHT(LEFT(g.product,4),2),' +-.0123456789')) = 0 THEN RIGHT(LEFT(g.product,4),2) END) BETWEEN 65 AND 70 THEN '65" - 70"'
		WHEN g.category = 'CTV' AND COALESCE(mcp.INCHES_ITEM, CASE WHEN length(ltrim(RIGHT(LEFT(g.product,4),2),' +-.0123456789')) = 0 THEN RIGHT(LEFT(g.product,4),2) END) = 75 THEN '75"'
		WHEN g.category = 'CTV' AND COALESCE(mcp.INCHES_ITEM, CASE WHEN length(ltrim(RIGHT(LEFT(g.product,4),2),' +-.0123456789')) = 0 THEN RIGHT(LEFT(g.product,4),2) END) >= 80 THEN '>=80"'
	END INCH_RANGE_ITEM,
	to_int(RIGHT(g.spmon, 3)) month_number,
	CASE 
		WHEN g.CENSO IN ('B2W', 'LASA') THEN 'B2W+LASA'
		WHEN g.CENSO IN ('Carrefour', 'Carrefour.com', 'CBD', 'Wal Mart') THEN 'MM'
		WHEN g.CENSO IN ('Girafa', 'Kabum', 'Mercado Livre', 'Amazon') THEN 'Pure Players'
		WHEN g.CENSO IN ('Angeloni','Armazem Mateus','Benchimol','Eletromar','Eletrozema','Estrela','Novalar','Novo Mundo','Formosa','Infostore','Lider','Mir','Sol','Supermercados DB','TV Lar','Miami','Fujioka','G Barbosa','Gazin','Havan','Ferreira Costa','Imperio dos Eletros','Lojas Sipolatti','Millena','N Claudino','Nagem','Claudino','Polo do Eletro','Solar Magazine','Tecno Ind','Berlanda','Condor','Deltasul','Global','Koerich','Lojas Becker','Lojas Colombo','Mad Herval','Mercado Moveis','Quero-Quero', 'Lojas Cem') THEN 'Regionais'
		WHEN g.CENSO IN ('Allied', 'Mixtel', 'Golden', 'All Nations', 'Satelital', 'Ingram', 'Agis', 'RCELL', 'Bel Micro', 'Mazer', 'Microsens', 'SND', 'Scansource') THEN 'Distributors'
		WHEN g.CENSO IN ('Synapcom - B2B2C', 'Synapcom - Loja', 'Synapcom - Marketplace', 'Synapcom EPP', 'Magazine Luiza SSG Store') THEN 'E-Store'
		WHEN g.CENSO IN ('Via Varejo') THEN 'Via'
		WHEN g.CENSO IN ('Magazine Luiza', 'Magazine Luiza.com') THEN 'Magalu'
		WHEN g.CENSO IN ('Fast') THEN 'Fast'
	END aggregated_censo,
	CASE 
		WHEN g.CENSO IN ('Fujioka', 'Nagem', 'Armazem Mateus', 'Angeloni', 'G Barbosa', 'Havan', 'Gazin', 'Benchimol', 'Novo Mundo') THEN g.CENSO
		ELSE COALESCE(g.ap1, m.AP1_AV)
	END AP1_2022,
	mcp.TV_SQUADS
from (SELECT * FROM OW_SEDA_S.ODS_CE_MANAGEMENT_INFORMATION WHERE SPMON = SELECTED_SPMON) g
left join OW_SEDA_S.MAP_CE_CUSTOMER m on g.ship_to_party = m.ship_to_party
--left join OW_SEDA_S.MAP_CE_MBO_KAM mmk on g.ship_to_party = mmk.ship_to and LEFT(g.spmon,4) || g.quarter = mmk.yearquarter
left join (SELECT * FROM OW_SEDA_S.MAP_CE_KAM WHERE QUARTER_REF = '2023Q3') mck on
	CASE 
		WHEN g.CATEGORY = 'AC' THEN g.CATEGORY 
		WHEN g.CATEGORY IN ('CTV', 'AV') THEN 'VD'
		WHEN g.CATEGORY IN ('REF', 'WM', 'VC') THEN 'HA'
		WHEN g.DIVISION_DESCRIPTION = 'MON' THEN 'EBT' 
	END = mck.DIVISION 
		AND
	CASE 
		WHEN g.CATEGORY = 'AC' THEN CASE WHEN g.line = 'RAC' THEN g.line ELSE 'SAC' END
		WHEN g.DIVISION_DESCRIPTION = 'MON' THEN 'MON' 
		ELSE g.CATEGORY
	END = mck.CATEGORY
		AND 
	g.censo LIKE CASE WHEN g.CENSO = 'Carrefour.com' THEN mck.censo ELSE mck.censo || '%' END
left join OW_SEDA_S.MAP_CE_MANAGEMENT_PRODUCTS p on g.product = p.product
left join (
	--#DISTRIBUI OS ITENS HME SEM SET UNICO
select
	 *
	from ( select
	 f.customer,
	 f.material,
	 m.linha,
	 max(spmon) spmon,
	 row_number() over (partition by f.customer order by sum(s_sales_qty) desc, max(spmon) desc) row_num
		from OW_SEDA_S.ODS_CONTROLLING_FORMAT_ACTUAL f
		inner join OW_SEDA_S.MAP_CE_MANAGEMENT_PRODUCTS m on f.material = m.product
		where 1=1
		and business_unit = 'CE'
		and prod_g = 'HME'
		and exists (select *
			from OW_SEDA_S.MAP_CE_MANAGEMENT_PRODUCTS m
			where f.material = m.product
			and category = 'Ultrassom')
		group by f.customer, f.material, m.linha ) t
	where t.row_num = 1 ) h on g.customer = h.customer
--# Pegas as informacoes de Inch, Technology e Q80+
LEFT JOIN OW_SEDA_S.MAP_CE_PRODUCTS mcp ON g.product = mcp.ITEM 
	WHERE LEFT(g.SPMON,4) >= 2018;
END;