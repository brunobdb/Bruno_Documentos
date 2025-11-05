CREATE PROCEDURE OW_SEDA_S.PRC_MX_FT_SEDA_EDI_INPUT_RETAILERS(IN WEEKNUM_REF INT) AS
--DO 
BEGIN
	
--DECLARE weeknum_ref INT = 202401;
tmp_generate_scripts = 
select 
distinct 
'call OW_SEDA_S.PRC_MX_FT_SEDA_EDI_INPUT (' || WEEKNUM_REF || ', ''' || account || ''')' stock_out_prc
from OW_SEDA_S.EDI_DATA_RAW r
where 1=1
	and WEEK = WEEKNUM_REF;
exec (select 'do begin ' || string_agg(stock_out_prc, '; ') || '; end;' stock_out_prc from :tmp_generate_scripts);
end;