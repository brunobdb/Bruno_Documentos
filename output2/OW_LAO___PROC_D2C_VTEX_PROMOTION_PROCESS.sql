/***********************************************************************************************
ALTER BY : LUCIANO MARIANI
CREATION DATE : 2023-11-14
-- CALL OW_LAO.PROC_D2C_VTEX_PROMOTION_PROCESS
SELECT TOP 1000 * 
FROM OW_LAO.FT_D2C_VTEX_PROMOTION
where status_po not like '%cancek%'
where AMOUNT_DISCOUNT <> 0 order_id = '1375751067957-01'
***********************************************************************************************/
CREATE PROCEDURE OW_LAO.PROC_D2C_VTEX_PROMOTION_PROCESS (
) LANGUAGE SQLSCRIPT
AS
BEGIN
	
	DECLARE p_DATE_INI DATE; 
	DECLARE p_DATE_INICIAL DATE = '2024-07-01'; -- Substitua pela data inicial desejada
	DECLARE P_DATE_FINAL DATE = '2024-08-01'; -- Substitua pela data final desejada
	DECLARE i INT = 0;
    WHILE (p_DATE_INICIAL <= P_DATE_FINAL) DO
        i := i + 1;
		p_DATE_INI := ADD_DAYS(p_DATE_INICIAL, i * 7);
		
		CALL OW_LAO.PROC_D2C_VTEX_PROMOTION( p_DATE_INI,  ADD_DAYS(p_DATE_INI, 7));
	
		SELECT :p_DATE_INI AS p_DATE_INI FROM dummy; 
		
        p_DATE_INICIAL := ADD_DAYS(p_DATE_INICIAL, i * 7);
    END WHILE;
	
END;