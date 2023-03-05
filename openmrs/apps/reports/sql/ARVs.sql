SELECT Product_description, sum(Stock_on_hand) AS "Stock_on_Hand", min(Expiry_Date) AS "Expiry Date", sum(Quantity_expired_and_damaged) AS "Quantity Expired/Damaged", sum(Quantity_Received) AS "Quantity Received"
FROM
(
(SELECT Product_description, Stock_on_hand, Expiry_Date ,damaged.Quantity_expired_and_damaged ,Quantity_Received
FROM
    (SELECT Id, name Product_description,sum(stock_on_hand) Stock_on_hand
        FROM
        (-- STOCK QUANTITY
            SELECT DISTINCT template.id AS Id,SQuatity.qty stock_on_hand ,template.name
            FROM product_template template
            INNER JOIN stock_quant SQuatity ON SQuatity.product_id = template.id
        	AND CAST(SQuatity.write_date AS DATE) >= CAST('#startDate#' AS DATE)
        	AND CAST(SQuatity.write_date AS DATE) <= CAST('#endDate#' AS DATE)
            ) product_name_quant
        GROUP BY product_name_quant.name,product_name_quant.id) AS stock_pro
        LEFT OUTER JOIN
        (-- OLDEST EXPIRY DATE
		SELECT product_id,min(expiry_date) Expiry_Date
        FROM stock_pack_operation_lot sp
        INNER JOIN stock_pack_operation spo on spo.id = operation_id
        AND spo.write_date >= CAST('#startDate#' AS DATE)
        AND spo.write_date <= CAST('#endDate#' AS DATE)
        GROUP BY product_id
        )expiry ON stock_pro.Id = expiry.product_id
LEFT OUTER JOIN
( -- EXPIRED/DAMAGED
SELECT product_id,Quantity_Expired Quantity_expired_and_damaged
FROM
(
    (
    SELECT DISTINCT sp.product_id,sum(qty) AS Quantity_Expired
    FROM stock_pack_operation sp
    INNER JOIN stock_pack_operation_lot spo on sp.id = spo.operation_id AND expiry_date < CAST('#endDate#' AS DATE)
    AND sp.write_date >= CAST('#startDate#' AS DATE)
    AND sp.write_date <= CAST('#endDate#' AS DATE)
    GROUP BY sp.product_id
    )
UNION ALL
    (
    SELECT DISTINCT ss.product_id,sum(scrap_qty)
    FROM stock_pack_operation sp
    INNER JOIN stock_scrap ss ON sp.product_id = ss.product_id
    AND sp.write_date >= CAST('#startDate#' AS DATE)
    AND sp.write_date <= CAST('#endDate#' AS DATE)
    GROUP BY ss.product_id
    )
)damaged

)damaged ON stock_pro.Id = damaged.product_id

LEFT OUTER JOIN
(-- QUANTITY RECEIVED
SELECT product_id,qty_received Quantity_Received
FROM purchase_order_line pol
WHERE CAST (write_date AS TIMESTAMP) <= CAST('#endDate#' AS DATE)
AND state = 'purchase'
AND pol.write_date >= CAST('#startDate#' AS DATE)
AND pol.write_date <= CAST('#endDate#' AS DATE)
)received ON stock_pro.id = received.product_id)

UNION ALL
(
-- ALL PRODUCTS IN DHIS2 ARVS DATASET
SELECT  'Abacavir 300mg',0,CURRENT_DATE,0,0 --1
UNION ALL
SELECT  'ABC-3TC 600/300mg',0,CURRENT_DATE,0,0 --2
UNION ALL	
SELECT  'Atazanavir 300mg',0,CURRENT_DATE,0,0 --3
UNION ALL	
SELECT  'Atazanavir/Ritonavir 300/100mg',0,CURRENT_DATE,0,0 --4
UNION ALL
SELECT  'Darunavir 300mg',0,CURRENT_DATE,0,0 --5
UNION ALL	
SELECT  'Darunavir 600mg',0,CURRENT_DATE,0,0 --6
UNION ALL	
SELECT  'Dolutegravir 50mg',0,CURRENT_DATE,0,0 --7
UNION ALL	
SELECT  'Dolutegravir 10mg',0,CURRENT_DATE,0,0 --8
UNION ALL	
SELECT  'Efavirenz 600mg',0,CURRENT_DATE,0,0 --9
UNION ALL	
SELECT  'Etravirine 100mg',0,CURRENT_DATE,0,0 --10
UNION ALL	
SELECT  'Lamivudine (3TC) 150mg',0,CURRENT_DATE,0,0 --11
UNION ALL	
SELECT  'Lopinavir and Ritonavir - 200/50mg',0,CURRENT_DATE,0,0 --12
UNION ALL	
SELECT  'Nevirapine 200mg',0,CURRENT_DATE,0,0 --13
UNION ALL	
SELECT  'Raltegravir 400mg',0,CURRENT_DATE,0,0 --14
UNION ALL	
SELECT  'Ritonavir 100mg',0,CURRENT_DATE,0,0 --15
UNION ALL	
SELECT  'Tenofovir 300mg',0,CURRENT_DATE,0,0 --16
UNION ALL	
SELECT  'TDF-3TC 300/300mg',0,CURRENT_DATE,0,0 --17
UNION ALL	
SELECT  '1j=TDF-3TC-DTG 300/300/50mg',0,CURRENT_DATE,0,0 --18
UNION ALL	
SELECT  '1j=TDF-3TC-DTG 300/300/50mg (90)',0,CURRENT_DATE,0,0 --19
UNION ALL	
SELECT  '1f=TDF-3TC-EFV 300/300/400mg',0,CURRENT_DATE,0,0 --20
UNION ALL	
SELECT  '1f=TDF-3TC-EFV 300/300/400mg (90)',0,CURRENT_DATE,0,0 --21
UNION ALL	
SELECT  '1f=TDF-3TC-EFV 300/300/600mg',0,CURRENT_DATE,0,0 --22
UNION ALL	
SELECT  'Zidovudine 300mg',0,CURRENT_DATE,0,0 --23
UNION ALL	
SELECT  'Zidovudine 10mg/1ml Suspension',0,CURRENT_DATE,0,0 --24
UNION ALL
SELECT  'AZT-3TC 300/150mg',0,CURRENT_DATE,0,0 --25
UNION ALL	
SELECT  '1c=AZT-3TC-NVP 300/150/200mg',0,CURRENT_DATE,0,0 --26
UNION ALL	
SELECT  'Abacavir 60mg',0,CURRENT_DATE,0,0 --27
UNION ALL	
SELECT  'Abacavir / Lamivudine(ABC/3TC) - 120/60mg',0,CURRENT_DATE,0,0 --28
UNION ALL	
SELECT  'Darunavir 75mg',0,CURRENT_DATE,0,0 --29
UNION ALL	
SELECT  'Efavirenz 200mg',0,CURRENT_DATE,0,0 --30
UNION ALL	
SELECT  'Lopinavir and Ritonavir - 80mg/20ml',0,CURRENT_DATE,0,0 --31
UNION ALL	
SELECT  'Lopinavir and Ritonavir- 40/10mg',0,CURRENT_DATE,0,0 --32
UNION ALL	
SELECT  'Lopinavir and Ritonavir- 100/25mg',0,CURRENT_DATE,0,0 --33
UNION ALL	
SELECT  'Nevirapine mixture 50mg',0,CURRENT_DATE,0,0 --34
UNION ALL	
SELECT  'Nevirapine mixture 50mg/5ml',0,CURRENT_DATE,0,0 --35
UNION ALL	
SELECT  'Raltegravir 100mg',0,CURRENT_DATE,0,0 --36
UNION ALL	
SELECT  'AZT-3TC 60/30mg',0,CURRENT_DATE,0,0 --37
UNION ALL	
SELECT  '4c=AZT-3TC-NVP 60/30/50mg',0,CURRENT_DATE,0,0 --38
)
)AS all_agg
GROUP BY Product_description

 -- MATCH ORDER TO DHIS2 ARVS DATASET
ORDER BY CASE 	  WHEN Product_description='Abacavir 300mg' 			THEN 1 --OK
		  WHEN Product_description='ABC-3TC 600/300mg'					THEN 2 --OK
		  WHEN Product_description='Atazanavir 300mg' 					THEN 3 --OK
		  WHEN Product_description='Atazanavir/Ritonavir 300/100mg' 	THEN 4 --OK
		  WHEN Product_description='Darunavir 300mg' 					THEN 5 --OK
		  WHEN Product_description='Darunavir 600mg' 					THEN 6 --OK
		  WHEN Product_description='Dolutegravir 50mg' 					THEN 7 --OK
		  WHEN Product_description='Dolutegravir 10mg' 					THEN 8 --OK
		  WHEN Product_description='Efavirenz 600mg' 					THEN 9 --OK
		  WHEN Product_description='Etravirine 100mg' 					THEN 10 --OK
		  WHEN Product_description='Lamivudine (3TC) 150mg' 			THEN 11 --OK
		  WHEN Product_description='Lopinavir and Ritonavir - 200/50mg' THEN 12 --OK
		  WHEN Product_description='Nevirapine 200mg' 					THEN 13 --OK
		  WHEN Product_description='Raltegravir 400mg' 					THEN 14 --OK
		  WHEN Product_description='Ritonavir 100mg' 					THEN 15 --OK
		  WHEN Product_description='Tenofovir 300mg' 					THEN 16 --OK
		  WHEN Product_description='TDF-3TC 300/300mg' 					THEN 17 --OK
		  WHEN Product_description='1j=TDF-3TC-DTG 300/300/50mg' 		THEN 18 --OK
		  WHEN Product_description='1j=TDF-3TC-DTG 300/300/50mg (90)' 	THEN 19
		  WHEN Product_description='1f=TDF-3TC-EFV 300/300/400mg' 		THEN 20 --OK
		  WHEN Product_description='1f=TDF-3TC-EFV 300/300/400mg (90)' 	THEN 21
		  WHEN Product_description='1f=TDF-3TC-EFV 300/300/600mg' 		THEN 22 --OK
		  WHEN Product_description='Zidovudine 300mg' 					THEN 23 --OK
		  WHEN Product_description='Zidovudine 10mg/1ml Suspension' 	THEN 24
		  WHEN Product_description='AZT-3TC 300/150mg' 					THEN 25 --OK
		  WHEN Product_description='1c=AZT-3TC-NVP 300/150/200mg' 		THEN 26 --OK
		  WHEN Product_description='Abacavir 60mg' 						THEN 27 --OK
		  WHEN Product_description='Abacavir / Lamivudine(ABC/3TC) - 120/60mg' 		THEN 28 --OK
		  WHEN Product_description='Darunavir 75mg' 								THEN 29 --OK
		  WHEN Product_description='Efavirenz 200mg' 								THEN 30 --OK
		  WHEN Product_description='Lopinavir and Ritonavir - 80mg/20ml' 			THEN 31 --OK
		  WHEN Product_description='Lopinavir and Ritonavir- 40/10mg' 				THEN 32 --OK
		  WHEN Product_description='Lopinavir and Ritonavir- 100/25mg' 				THEN 33 --OK
		  WHEN Product_description='Nevirapine mixture 50mg' 						THEN 34
		  WHEN Product_description='Nevirapine mixture 50mg/5ml' 					THEN 35 --MODIFY DHIS2 DATASET TO STORE ZERO DATA VALUES
		  WHEN Product_description='Raltegravir 100mg' 								THEN 36 --OK
		  WHEN Product_description='AZT-3TC 60/30mg' 								THEN 37 --OK
		  WHEN Product_description='4c=AZT-3TC-NVP 60/30/50mg' 						THEN 38 --OK
	 END;
