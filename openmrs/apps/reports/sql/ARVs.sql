SELECT Product_Name, Unit_of_Issue,
	 CASE WHEN Product_Name IS NULL THEN 0 ELSE (SUM(CASE WHEN stock_on_hand>0 THEN stock_on_hand ELSE 0 END)) END AS Qty_Stock_on_Hand,
	 CASE WHEN Expiry_Date IS NULL THEN 0 ELSE Expiry_Date END AS Stock_Expiry_Date,
	 CASE WHEN Product_Name IS NULL THEN 0 ELSE (SUM(CASE WHEN Quantity_expired_and_damaged>0 THEN Quantity_expired_and_damaged ELSE 0 END)) END AS Qty_Expired_and_damaged,
     CASE WHEN Product_Name IS NULL THEN 0 ELSE (SUM(CASE WHEN Quantity_Received>0 THEN Quantity_Received ELSE 0 END)) END AS Qty_Received,
     CASE WHEN Product_Name IS NULL THEN 0 ELSE (SUM(CASE WHEN stock_at_last_reporting_period>0 THEN stock_at_last_reporting_period ELSE 0 END)) END AS Qty_stock_at_last_reporting_period
FROM
(

SELECT distinct stock_move.name Product_Name,issue.name Unit_of_Issue,stock_on_hand,Expiry_Date,Quantity_expired_and_damaged,Quantity_Received,stock_at_last_reporting_period
FROM stock_move 
LEFT OUTER JOIN
   ( -- PRODUCT NAME
	select sm.name Product_Name, so.product_packaging ,sm.product_id
	from stock_move sm
	inner join sale_order_line so ON so.product_id = sm.product_id
	WHERE sm.write_date >= CAST('#startDate#' AS DATE)
	AND sm.write_date <= CAST('#endDate#' AS DATE)
	) AS a ON stock_move.product_id = a.product_id
	
LEFT OUTER JOIN
	-- UNIT OF ISSUE
	(
	select pp.name,pp.id
	from product_packaging pp
	)issue ON issue.id = a.product_packaging

LEFT OUTER JOIN
( -- STOCK ON HAND
SELECT qty stock_on_hand,a.product_id
FROM stock_quant a
INNER JOIN
(SELECT product_id,CAST(MAX(write_date) AS TIMESTAMP) maxdate 
		FROM stock_quant 
		WHERE CAST(write_date AS TIMESTAMP) <= CAST('#endDate#' AS DATE)
		group by product_id 
		)latest 
		on latest.product_id = a.product_id
WHERE CAST(a.write_date AS TIMESTAMP) = maxdate
AND a.write_date >= CAST('#startDate#' AS DATE)
AND a.write_date <= CAST('#endDate#' AS DATE)
)on_hand ON stock_move.product_id = on_hand.product_id

LEFT OUTER JOIN
(-- earliest expiry date
select product_id,min(expiry_date) Expiry_Date
FROM stock_pack_operation_lot sp
inner join stock_pack_operation spo on spo.id = operation_id
AND spo.write_date >= CAST('#startDate#' AS DATE)
AND spo.write_date <= CAST('#endDate#' AS DATE)
group by product_id
)expiry ON stock_move.product_id = expiry.product_id

LEFT OUTER JOIN
( -- EXPIRED/DAMAGED 
select product_id,sum(Quantity_Expired) Quantity_expired_and_damaged
FROM
(
	(
	select distinct sp.product_id,sum(qty) as Quantity_Expired
	from stock_pack_operation sp
	inner join stock_pack_operation_lot spo on sp.id = spo.operation_id AND expiry_date < CAST('#endDate#' AS DATE)
	AND sp.write_date >= CAST('#startDate#' AS DATE)
	AND sp.write_date <= CAST('#endDate#' AS DATE)
	group by sp.product_id
	)
UNION ALL
	(
	select distinct ss.product_id,sum(scrap_qty)
	from stock_pack_operation sp
	inner join stock_scrap ss on sp.product_id = ss.product_id
	AND sp.write_date >= CAST('#startDate#' AS DATE)
	AND sp.write_date <= CAST('#endDate#' AS DATE)
	AND ss.write_date >= CAST('#startDate#' AS DATE)
	AND ss.write_date <= CAST('#endDate#' AS DATE)
	GROUP BY ss.product_id
	)
)damaged
group by product_id
)damaged ON stock_move.product_id = damaged.product_id

LEFT OUTER JOIN
(-- QUANTITY RECEIVED
SELECT product_id,qty_received Quantity_Received
FROM purchase_order_line pol
WHERE CAST (write_date AS TIMESTAMP) <= CAST('#endDate#' AS DATE)
AND state = 'purchase'
AND pol.write_date >= CAST('#startDate#' AS DATE)
AND pol.write_date <= CAST('#endDate#' AS DATE)
)received ON stock_move.product_id = received.product_id

LEFT OUTER  JOIN
(-- STOCK BF
select distinct sm.name,sm.product_id,sq.qty stock_at_last_reporting_period
from stock_quant sq
INNER JOIN stock_move sm on sm.product_id = sq.product_id
INNER JOIN
(SELECT distinct product_id,MAX(CAST (create_date AS TIMESTAMP)) maxdate 
		FROM stock_quant
		WHERE CAST(create_date AS TIMESTAMP) <= CAST('#endDate#' AS DATE)
		group by product_id
		)latest 
		on latest.product_id = sq.product_id
WHERE CAST(sq.create_date AS TIMESTAMP) = maxdate
AND sq.write_date >= CAST('#startDate#' AS DATE)
AND sq.write_date <= CAST('#endDate#' AS DATE)
)on_hand_balance ON stock_move.product_id = on_hand_balance.product_id 
GROUP BY stock_move.name, issue.name, on_hand.stock_on_hand, expiry.expiry_date, damaged.quantity_expired_and_damaged,received.quantity_received,on_hand_balance.stock_at_last_reporting_period

UNION ALL
SELECT  'Abacavir 300mg','',0,NULL,0,0,0
UNION ALL
SELECT  'Abacavir/Lamivudine (ABC/3TC) - 600/300mg','',0,NULL,0,0,0
UNION ALL	
SELECT  'Atazanavir 300mg','',0,NULL,0,0,0
UNION ALL	
SELECT  'Atazanavir/Ritonavir (ATV/RIV) - 300/100mg','',0,NULL,0,0,0
UNION ALL
SELECT  'Darunavir 300mg','',0,NULL,0,0,0
UNION ALL	
SELECT  'Darunavir 600mg','',0,NULL,0,0,0
UNION ALL	
SELECT  'Dolutegravir 50mg','',0,NULL,0,0,0
UNION ALL	
SELECT  'Dolutegravir 10mg','',0,NULL,0,0,0
UNION ALL	
SELECT  'Efavirenz 600mg','',0,NULL,0,0,0
UNION ALL	
SELECT  'Etravirine 100mg','',0,NULL,0,0,0
UNION ALL	
SELECT  'Lamivudine (3TC) 150mg','',0,NULL,0,0,0
UNION ALL	
SELECT  'Lopinavir and Ritonavir - 200/50mg','',0,NULL,0,0,0
UNION ALL	
SELECT  'Nevirapine 200mg','',0,NULL,0,0,0
UNION ALL	
SELECT  'Raltegravir 400mg','',0,NULL,0,0,0
UNION ALL	
SELECT  'Ritonavir 100mg','',0,NULL,0,0,0
UNION ALL	
SELECT  'Tenofovir 300mg','',0,NULL,0,0,0
UNION ALL	
SELECT  'TDF-3TC 300/300mg','',0,NULL,0,0,0
UNION ALL	
SELECT  '1j=TDF-3TC-DTG 300/300/50mg (30)','',0,NULL,0,0,0
UNION ALL	
SELECT  '1j=TDF-3TC-DTG 300/300/50mg (90)','',0,NULL,0,0,0
UNION ALL	
SELECT  '1f=TDF-3TC-EFV 300/300/400mg (90)','',0,NULL,0,0,0
UNION ALL	
SELECT  '1f=TDF-3TC-EFV 300/300/400mg (30)','',0,NULL,0,0,0
UNION ALL	
SELECT  '1f=TDF-3TC-EFV 300/300/600mg (30)','',0,NULL,0,0,0
UNION ALL	
SELECT  'Zidovudine 300mg','',0,NULL,0,0,0
UNION ALL	
SELECT  'Zidovudine 10mg/1ml Suspension','',0,NULL,0,0,0
UNION ALL
SELECT  'AZT-3TC 300/150mg','',0,NULL,0,0,0
UNION ALL	
SELECT  '1c=AZT-3TC-NVP 300/150/200mg','',0,NULL,0,0,0


) AS all_agg
GROUP BY Product_Name, Unit_of_Issue, Expiry_Date
ORDER BY CASE WHEN Product_Name='Abacavir 300mg' 								THEN 1
			  WHEN Product_Name='Abacavir/Lamivudine (ABC/3TC) - 600/300mg'		THEN 2
			  WHEN Product_Name='Atazanavir 300mg' 								THEN 3
			  WHEN Product_Name='Atazanavir/Ritonavir (ATV/RIV) - 300/100mg' 	THEN 4
			  WHEN Product_Name='Darunavir 300mg' 								THEN 5
			  WHEN Product_Name='Darunavir 600mg' 								THEN 6
			  WHEN Product_Name='Dolutegravir 50mg' 							THEN 7
			  WHEN Product_Name='Dolutegravir 10mg' 							THEN 8
			  WHEN Product_Name='Efavirenz 600mg' 								THEN 9
			  WHEN Product_Name='Etravirine 100mg' 								THEN 10
			  WHEN Product_Name='Lamivudine (3TC) 150mg' 						THEN 11
			  WHEN Product_Name='Lopinavir and Ritonavir - 200/50mg' 			THEN 12
			  WHEN Product_Name='Nevirapine 200mg' 								THEN 13
			  WHEN Product_Name='Raltegravir 400mg' 							THEN 14
			  WHEN Product_Name='Ritonavir 100mg' 								THEN 15
			  WHEN Product_Name='Tenofovir 300mg' 								THEN 16
			  WHEN Product_Name='TDF-3TC 300/300mg' 							THEN 17
			  WHEN Product_Name='1j=TDF-3TC-DTG 300/300/50mg (30)' 				THEN 18
			  WHEN Product_Name='1j=TDF-3TC-DTG 300/300/50mg (90)' 				THEN 19
			  WHEN Product_Name='1f=TDF-3TC-EFV 300/300/400mg (90)' 			THEN 20
			  WHEN Product_Name='1f=TDF-3TC-EFV 300/300/400mg (30)' 			THEN 21
			  WHEN Product_Name='1f=TDF-3TC-EFV 300/300/600mg (30)' 			THEN 22
			  WHEN Product_Name='Zidovudine 300mg' 								THEN 23
			  WHEN Product_Name='Zidovudine 10mg/1ml Suspension' 				THEN 24
			  WHEN Product_Name='AZT-3TC 300/150mg' 							THEN 25
			  WHEN Product_Name='1c=AZT-3TC-NVP 300/150/200mg' 					THEN 26
		 END;
