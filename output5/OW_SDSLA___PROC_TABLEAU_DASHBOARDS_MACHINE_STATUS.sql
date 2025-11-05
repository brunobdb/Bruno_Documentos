CREATE PROCEDURE OW_SDSLA.PROC_TABLEAU_DASHBOARDS_MACHINE_STATUS(IN p_machine_ip NVARCHAR(50), p_user_os NVARCHAR(755))
LANGUAGE SQLSCRIPT
AS
BEGIN
    -- Verifica se o IP já existe na tabela
    IF EXISTS (SELECT 1 FROM OW_SDSLA.RAW_TABLEAU_DASHBOARDS_MACHINE_STATUS WHERE machine_ip = p_machine_ip) THEN
        -- Atualiza a última verificação se o IP já estiver registrado
        UPDATE OW_SDSLA.RAW_TABLEAU_DASHBOARDS_MACHINE_STATUS
        SET last_check = CURRENT_TIMESTAMP
        WHERE machine_ip = p_machine_ip 
       		  AND user_os = p_user_os;
    ELSE
        -- Insere um novo registro se o IP não existir
        INSERT INTO OW_SDSLA.RAW_TABLEAU_DASHBOARDS_MACHINE_STATUS (machine_ip, user_os, last_check)
        VALUES (p_machine_ip, p_user_os, CURRENT_TIMESTAMP);
    END IF;
END;