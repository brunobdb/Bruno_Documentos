CREATE PROCEDURE "OW_SELA"."PROCSNAPSHOTFCST_OLD"
LANGUAGE SQLSCRIPT as
BEGIN
TRUNCATE TABLE "OW_SELA"."FCST_SNAPSHOT";
-- INSERT FORECAST ----------------------------
insert into "OW_SELA"."FCST_SNAPSHOT"
("COMPANYCD",
"COMPANY",
"MARKETNAME",
"PRODUCTTYPE",
"SEGMENT",
"SEGMENT_AGE",
"DCID",
"DC",
"VRESELLER",
"DT_YW",
"START_DT",
"WR",
"WWWMM",
"Sell-in_YW",
"Sell-out_YW",
"Sell-thru_YW",
"EOH_YW",
"EOH_R_YW",
"Sell-thru_Sum_4W",
"Sell-out_Sum_4W")
SELECT
	 "COMPANYCD",
	 "COMPANY",
	 "MARKETNAME",
	 "PRODUCTTYPE",
	 "SEGMENT",
	 "SEGMENT_AGE",
	 "DCID",
	 "DC",
	 "VRESELLER",
	 "YYYYWW",
	 "START_DT",
	 "WR",
	 "WWWMM",
	 "Sell-in_YW",
	 "Sell-out_YW",
	 "Sell-thru_YW",
	 "EOH_YW",
	 "EOH(R)_YW",
	 case when "WR" in('W-8','W-7','W-6') THEN NULL ELSE "Sell-thru_YW" +
	 lag("Sell-thru_YW",1) over (partition by "COMPANYCD","MARKETNAME","DCID","VRESELLER" order by "YYYYWW") +
	 lag("Sell-thru_YW",2) over (partition by "COMPANYCD","MARKETNAME","DCID","VRESELLER" order by "YYYYWW") +
	 lag("Sell-thru_YW",3) over (partition by "COMPANYCD","MARKETNAME","DCID","VRESELLER" order by "YYYYWW") END as "Sell-thru_Avg_4W",
	 case when "WR" in('W-8','W-7','W-6') THEN NULL ELSE "Sell-out_YW" +
	 lag("Sell-out_YW",1) over (partition by "COMPANYCD","MARKETNAME","DCID","VRESELLER" order by "YYYYWW") +
	 lag("Sell-out_YW",2) over (partition by "COMPANYCD","MARKETNAME","DCID","VRESELLER" order by "YYYYWW") +
	 lag("Sell-out_YW",3) over (partition by "COMPANYCD","MARKETNAME","DCID","VRESELLER" order by "YYYYWW") END as "Sell-out_Avg_4W"
FROM "_SYS_BIC"."DLAKE_DMS/DMS_FCST_SUM"
;
--where
--WR IN ('W-0','W1','W2','W3','W4','W5','W6','W7','W8') ;
	 
end;