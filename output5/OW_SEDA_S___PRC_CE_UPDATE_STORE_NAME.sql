CREATE PROCEDURE OW_SEDA_S.PRC_CE_UPDATE_STORE_NAME(IN SITE_ID_REF VARCHAR(50)) AS 
BEGIN
UPDATE mcs SET 
STORE_COMPLETE_NAME = 
	case
		when ACCOUNT = CHANNEL then ACCOUNT 
		else ACCOUNT || ' - ' || CHANNEL
	end || 
	ifnull(' - ' || LPAD(mcs.BRANCH_NUMBER,4,'0'),'') ||
	ifnull(' - ' || mcs.SHOPPING_CENTER_STORE,'') || ' - ' ||
	mcs.NOME_DO_MUNICIPIO_STORE || ' - ' || --trim(' ' from substring(mcs.COMPLETE_OFFICIAL_ADDRESS_STORE,locate(mcs.COMPLETE_OFFICIAL_ADDRESS_STORE,',',1,3)+1,locate(mcs.COMPLETE_OFFICIAL_ADDRESS_STORE,',',1,4) - locate(mcs.COMPLETE_OFFICIAL_ADDRESS_STORE,',',1,3) - 1)) || ' - ' ||
	trim(' ' from substring(mcs.COMPLETE_OFFICIAL_ADDRESS_STORE,locate(mcs.COMPLETE_OFFICIAL_ADDRESS_STORE,',',1,2)+1,locate(mcs.COMPLETE_OFFICIAL_ADDRESS_STORE,',',1,3) - locate(mcs.COMPLETE_OFFICIAL_ADDRESS_STORE,',',1,2) - 1)) || ' - ' ||
	mcs.SIGLA_DA_UF_STORE, --trim(' ' from substring(mcs.COMPLETE_OFFICIAL_ADDRESS_STORE,locate(mcs.COMPLETE_OFFICIAL_ADDRESS_STORE,',',1,4)+1,3)),
STORE_SHORT_NAME =
	case
		when ACCOUNT = CHANNEL then '' 
		else CHANNEL || ' - '
	end || 
	ifnull(LPAD(mcs.BRANCH_NUMBER,4,'0') || ' - ','') ||
	ifnull(mcs.SHOPPING_CENTER_STORE || ' - ','') ||
	mcs.NOME_DO_MUNICIPIO_STORE || ' - ' || --trim(' ' from substring(mcs.COMPLETE_OFFICIAL_ADDRESS_STORE,locate(mcs.COMPLETE_OFFICIAL_ADDRESS_STORE,',',1,3)+1,locate(mcs.COMPLETE_OFFICIAL_ADDRESS_STORE,',',1,4) - locate(mcs.COMPLETE_OFFICIAL_ADDRESS_STORE,',',1,3) - 1)) || ' - ' ||
	trim(' ' from substring(mcs.COMPLETE_OFFICIAL_ADDRESS_STORE,locate(mcs.COMPLETE_OFFICIAL_ADDRESS_STORE,',',1,2)+1,locate(mcs.COMPLETE_OFFICIAL_ADDRESS_STORE,',',1,3) - locate(mcs.COMPLETE_OFFICIAL_ADDRESS_STORE,',',1,2) - 1)) || ' - ' ||
	mcs.SIGLA_DA_UF_STORE --trim(' ' from substring(mcs.COMPLETE_OFFICIAL_ADDRESS_STORE,locate(mcs.COMPLETE_OFFICIAL_ADDRESS_STORE,',',1,4)+1,3))
FROM OW_SEDA_S.MAP_CE_STORES mcs 
WHERE 1=1
	AND SITE_ID	= SITE_ID_REF;
END