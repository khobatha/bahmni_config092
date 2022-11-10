SELECT Drug,	   
 CASE WHEN Drug IS NULL THEN 0 ELSE (SUM(CASE WHEN qty_dispensed_units>0 THEN qty_dispensed_units ELSE 0 END)) END AS Units_Dispensed_this_Month , 
 CASE WHEN Drug IS NULL THEN 0 ELSE (SUM(CASE WHEN qty_stock_on_hand>0 THEN qty_stock_on_hand ELSE 0 END)) END AS Stock_on_hand
FROM

(
SELECT sm.name as Drug,CAST(sum(sol.qty_delivered) AS INTEGER) as qty_dispensed_units,
CAST(sum(stock_on_hand) AS INTEGER)  as qty_stock_on_hand
FROM stock_move sm
LEFT OUTER JOIN sale_order_line sol ON  sm.product_id = sol.product_id AND sol.state = 'sale'
LEFT OUTER JOIN purchase_order_line pol ON sm.product_id = pol.product_id AND sol.state = 'purchase'
LEFT OUTER JOIN
-- stock on hand this month end
( SELECT qty stock_on_hand,a.product_id
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
)stock ON sm.product_id = stock.product_id

GROUP BY sm.name

UNION ALL
SELECT  'Abacavir 300mg',0,0
UNION ALL
SELECT  'Abacavir/Lamivudine (ABC/3TC) - 600/300mg',0,0
UNION ALL	
SELECT  'Atazanavir 300mg',0,0
UNION ALL	
SELECT  'Atazanavir/Ritonavir (ATV/RIV) - 300/100mg',0,0
UNION ALL
SELECT  'Darunavir 300mg',0,0
UNION ALL	
SELECT  'Darunavir 600mg',0,0
UNION ALL	
SELECT  'Dolutegravir 50mg',0,0
UNION ALL	
SELECT  'Dolutegravir 10mg',0,0
UNION ALL	
SELECT  'Efavirenz 600mg',0,0
UNION ALL	
SELECT  'Etravirine 100mg',0,0
UNION ALL	
SELECT  'Lamivudine (3TC) 150mg',0,0
UNION ALL	
SELECT  'Lopinavir and Ritonavir - 200/50mg',0,0
UNION ALL	
SELECT  'Nevirapine 200mg',0,0
UNION ALL	
SELECT  'Raltegravir 400mg',0,0
UNION ALL	
SELECT  'Ritonavir 100mg',0,0
UNION ALL	
SELECT  'Tenofovir 300mg',0,0
UNION ALL	
SELECT  'TDF-3TC 300/300mg',0,0
UNION ALL	
SELECT  '1j=TDF-3TC-DTG 300/300/50mg (30)',0,0
UNION ALL	
SELECT  '1j=TDF-3TC-DTG 300/300/50mg (90)',0,0
UNION ALL	
SELECT  '1f=TDF-3TC-EFV 300/300/400mg (90)',0,0
UNION ALL	
SELECT  '1f=TDF-3TC-EFV 300/300/400mg (30)',0,0
UNION ALL	
SELECT  '1f=TDF-3TC-EFV 300/300/600mg (30)',0,0
UNION ALL	
SELECT  'Zidovudine 300mg',0,0
UNION ALL	
SELECT  'Zidovudine 10mg/1ml Suspension',0,0
UNION ALL
SELECT  'AZT-3TC 300/150mg',0,0
UNION ALL	
SELECT  '1c=AZT-3TC-NVP 300/150/200mg',0,0

) as all_agg
GROUP by Drug
ORDER BY CASE WHEN Drug='Abacavir 300mg' 								THEN 1
			  WHEN Drug='Abacavir/Lamivudine (ABC/3TC) - 600/300mg'		THEN 2
			  WHEN Drug='Atazanavir 300mg' 								THEN 3
			  WHEN Drug='Atazanavir/Ritonavir (ATV/RIV) - 300/100mg' 	THEN 4
			  WHEN Drug='Darunavir 300mg' 								THEN 5
			  WHEN Drug='Darunavir 600mg' 								THEN 6
			  WHEN Drug='Dolutegravir 50mg' 							THEN 7
			  WHEN Drug='Dolutegravir 10mg' 							THEN 8
			  WHEN Drug='Efavirenz 600mg' 								THEN 9
			  WHEN Drug='Etravirine 100mg' 								THEN 10
			  WHEN Drug='Lamivudine (3TC) 150mg' 						THEN 11
			  WHEN Drug='Lopinavir and Ritonavir - 200/50mg' 			THEN 12
			  WHEN Drug='Nevirapine 200mg' 								THEN 13
			  WHEN Drug='Raltegravir 400mg' 							THEN 14
			  WHEN Drug='Ritonavir 100mg' 								THEN 15
			  WHEN Drug='Tenofovir 300mg' 								THEN 16
			  WHEN Drug='TDF-3TC 300/300mg' 							THEN 17
			  WHEN Drug='1j=TDF-3TC-DTG 300/300/50mg (30)' 				THEN 18
			  WHEN Drug='1j=TDF-3TC-DTG 300/300/50mg (90)' 				THEN 19
			  WHEN Drug='1f=TDF-3TC-EFV 300/300/400mg (90)' 			THEN 20
			  WHEN Drug='1f=TDF-3TC-EFV 300/300/400mg (30)' 			THEN 21
			  WHEN Drug='1f=TDF-3TC-EFV 300/300/600mg (30)' 			THEN 22
			  WHEN Drug='Zidovudine 300mg' 								THEN 23
			  WHEN Drug='Zidovudine 10mg/1ml Suspension' 				THEN 24
			  WHEN Drug='AZT-3TC 300/150mg' 							THEN 25
			  WHEN Drug='1c=AZT-3TC-NVP 300/150/200mg' 					THEN 26
		 END;

