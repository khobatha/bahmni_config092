SELECT Product_Name, Unit_of_Issue,
	 CASE WHEN Product_Name IS NULL THEN 0 ELSE (SUM(CASE WHEN qty_stock_on_hand>0 THEN stock_on_hand ELSE 0 END)) END AS Qty_Stock_on_Hand,
	 Expiry_Date,
	 CASE WHEN Product_Name IS NULL THEN 0 ELSE (SUM(CASE WHEN Quantity_expired_and_damaged>0 THEN Quantity_expired_and_damaged ELSE 0 END)) END AS Qty_Expired_and_damaged,
     CASE WHEN Product_Name IS NULL THEN 0 ELSE (SUM(CASE WHEN Quantity_Received>0 THEN Quantity_Received ELSE 0 END)) END AS Qty_Received,
     CASE WHEN Product_Name IS NULL THEN 0 ELSE (SUM(CASE WHEN stock_at_last_reporting_period>0 THEN stock_at_last_reporting_period ELSE 0 END)) END AS Qty_stock_at_last_reporting_period
FROM
(
SELECT 			stock_move.name AS Product_Name,issue.name AS Unit_of_Issue,
				stock_on_hand,Expiry_Date,Quantity_expired_and_damaged,Quantity_Received,
				stock_at_last_reporting_period
FROM stock_move 
LEFT OUTER JOIN
   ( -- PRODUCT NAME
	select sm.name AS Product_Name, so.product_packaging ,sm.product_id
	from stock_move sm
	inner join sale_order_line so ON so.product_id = sm.product_id
	WHERE sm.write_date >= CAST('2022-10-01' AS DATE)
	AND sm.write_date <= CAST('2022-10-31' AS DATE)
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
		WHERE CAST(write_date AS TIMESTAMP) <= CAST('2022-10-31' AS DATE)
		group by product_id 
		)latest 
		on latest.product_id = a.product_id
WHERE CAST(a.write_date AS TIMESTAMP) = maxdate
AND a.write_date >= CAST('2022-10-01' AS DATE)
AND a.write_date <= CAST('2022-10-31' AS DATE)
)on_hand ON stock_move.product_id = on_hand.product_id

LEFT OUTER JOIN
(-- earliest expiry date
select product_id,min(expiry_date) Expiry_Date
FROM stock_pack_operation_lot sp
inner join stock_pack_operation spo on spo.id = operation_id
AND spo.write_date >= CAST('2022-10-01' AS DATE)
AND spo.write_date <= CAST('2022-10-31' AS DATE)
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
	inner join stock_pack_operation_lot spo on sp.id = spo.operation_id AND expiry_date < CAST('2022-10-31' AS DATE)
	AND sp.write_date >= CAST('2022-10-01' AS DATE)
	AND sp.write_date <= CAST('2022-10-31' AS DATE)
	group by sp.product_id
	)
UNION ALL
	(
	select distinct ss.product_id,sum(scrap_qty)
	from stock_pack_operation sp
	inner join stock_scrap ss on sp.product_id = ss.product_id
	AND sp.write_date >= CAST('2022-10-01' AS DATE)
	AND sp.write_date <= CAST('2022-10-31' AS DATE)
	AND ss.write_date >= CAST('2022-10-01' AS DATE)
	AND ss.write_date <= CAST('2022-10-31' AS DATE)
	GROUP BY ss.product_id
	)
)damaged
group by product_id
)damaged ON stock_move.product_id = damaged.product_id

LEFT OUTER JOIN
(-- QUANTITY RECEIVED
SELECT product_id,qty_received Quantity_Received
FROM purchase_order_line pol
WHERE CAST (write_date AS TIMESTAMP) <= CAST('2022-10-31' AS DATE)
AND state = 'purchase'
AND pol.write_date >= CAST('2022-10-01' AS DATE)
AND pol.write_date <= CAST('2022-10-31' AS DATE)
)received ON stock_move.product_id = received.product_id

LEFT OUTER  JOIN
(-- STOCK BF
select distinct sm.name,sm.product_id,sq.qty stock_at_last_reporting_period
from stock_quant sq
INNER JOIN stock_move sm on sm.product_id = sq.product_id
INNER JOIN
(SELECT distinct product_id,MAX(CAST (create_date AS TIMESTAMP)) maxdate 
		FROM stock_quant
		WHERE CAST(create_date AS TIMESTAMP) <= CAST('2022-10-31' AS DATE)
		group by product_id
		) AS latest 
		on latest.product_id = sq.product_id
WHERE CAST(sq.create_date AS TIMESTAMP) = maxdate
AND sq.write_date >= CAST('2022-10-01' AS DATE)
AND sq.write_date <= CAST('2022-10-31' AS DATE)
)on_hand_balance ON stock_move.product_id = on_hand_balance.product_id
GROUP BY stock_move.name




) AS all_agg
GROUP BY Product_Name