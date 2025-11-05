CREATE PROCEDURE OW_LAO.PROC_DIM_UNIQUE_ID
 LANGUAGE SQLSCRIPT AS
 BEGIN
--- HASH GERADO PELO O ETL E CONFIGURA O CAMPO UNIQUE PARA 11 DÍGITOS
 
INSERT INTO   OW_LAO.TMP_DIM_UNIQUE_ID  (
SELECT * FROM(
SELECT 
A.CODE_DOC,
LPAD(RIGHT (A.CODE_DOC,8), 11, '0') AS CODE,
ROW_NUMBER() OVER (PARTITION BY A.UNIQUE_ID ORDER BY A.UNIQUE_ID ASC) AS NUM,
LPAD(A.UNIQUE_ID, 11,'0') AS UNIQUE_ID,
 A.CLIENT_SUBSIDIARY_ID,
CURRENT_TIMESTAMP AS INSERT_DATE,
CURRENT_TIMESTAMP AS LAST_UPDATE
FROM OW_LAO.TMP_DIM_UNIQUE_ID_TF A 
WHERE NOT EXISTS (
                        SELECT 1
                          FROM  OW_LAO.TMP_DIM_UNIQUE_ID AA
                         WHERE AA.CODE_DOC                    =A.CODE_DOC  
                          AND  AA.CLIENT_SUBSIDIARY_ID       = A.CLIENT_SUBSIDIARY_ID
                   )) B
WHERE NOT EXISTS (
                        SELECT 1
                          FROM  OW_LAO.TMP_DIM_UNIQUE_ID BB
                         WHERE BB.UNIQUE_ID                = B.UNIQUE_ID  
                         
                   )
AND B.NUM = 1                   
                   
)
;
--- TRATA POSSÍVEIS DUPLICIDADES E CONFIGURA O CAMPO UNIQUE PARA 11 DÍGITOS
 
INSERT INTO   OW_LAO.TMP_DIM_UNIQUE_ID  (
SELECT * FROM(
SELECT 
A.CODE_DOC,
LPAD(RIGHT (A.CODE_DOC,8), 11, '0') AS CODE,
ROW_NUMBER() OVER (PARTITION BY A.UNIQUE_ID ORDER BY A.UNIQUE_ID ASC) AS NUM,
LPAD (A.UNIQUE_ID, 11,'1') AS UNIQUE_ID,
A.CLIENT_SUBSIDIARY_ID,
CURRENT_TIMESTAMP AS INSERT_DATE,
CURRENT_TIMESTAMP AS LAST_UPDATE
FROM OW_LAO.TMP_DIM_UNIQUE_ID_TF A 
WHERE NOT EXISTS (
                        SELECT 1
                          FROM  OW_LAO.TMP_DIM_UNIQUE_ID AA
                         WHERE AA.CODE_DOC                    =A.CODE_DOC  
                          AND  AA.CLIENT_SUBSIDIARY_ID       = A.CLIENT_SUBSIDIARY_ID
                   )) B
WHERE NOT EXISTS (
                        SELECT 1
                          FROM OW_LAO.TMP_DIM_UNIQUE_ID BB
                         WHERE BB.UNIQUE_ID                = B.UNIQUE_ID  
                         
                   )
AND B.NUM = 1
)
 ;
 
 ---- INSERE OS DADOS NA TABELA DIM
INSERT INTO OW_LAO.DIM_UNIQUE_ID (
SELECT DISTINCT 
A.ORDER_ID,
B.CODE,
B.UNIQUE_ID,
A.CLIENT_SUBSIDIARY_ID,
A.PO_DATE ,
B.INSERT_DATE,
B.LAST_UPDATE
FROM 
OW_LAO.TMP_VTEX_PROFILE A
JOIN OW_LAO.TMP_DIM_UNIQUE_ID B        ON B.CODE_DOC             = COALESCE (A.DOCUMENT,A.CORPORATEDOCUMENT)
                                       AND B.CLIENT_SUBSIDIARY_ID = A.CLIENT_SUBSIDIARY_ID
                                             
WHERE NOT EXISTS (
                        SELECT 1
                          FROM OW_LAO.DIM_UNIQUE_ID  AA
                         WHERE AA.ORDER_ID                    = A.ORDER_ID
                          AND  AA.CLIENT_SUBSIDIARY_ID        = A.CLIENT_SUBSIDIARY_ID
                          
                   )
)
;
---- INSERE DADOS NA CONTROL TOWER
 UPDATE OW_LAO.ODS_SALES_CONTROL_TOWER_TABLE A
           SET A.UNIQUE_ID              = B.UNIQUE_ID
  
          FROM OW_LAO.ODS_SALES_CONTROL_TOWER_TABLE A
          JOIN OW_LAO.DIM_UNIQUE_ID                 B  ON B.ORDER_ID                = A.PO_ORDERID
                                                      AND B.CLIENT_SUBSIDIARY_ID    = A.CLIENT_SUBSIDIARY_ID
                                                                          
         WHERE A.CLIENT_SUBSIDIARY_ID IN (1, 6)
           AND A.PO_DATE >= ADD_DAYS(CURRENT_DATE, -180)
           
         
         ;
END