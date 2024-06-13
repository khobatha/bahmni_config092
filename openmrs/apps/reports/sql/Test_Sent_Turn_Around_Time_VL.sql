SELECT "Average Turn Around Time" as "Average Turn Around Time",
       round((SUM(turn_around_time)/COUNT(*)), 1) as "Average Turn Around Time"
FROM (
    SELECT datediff(result_date, date_collected) as turn_around_time
    FROM (
        SELECT DISTINCT 
            o.order_id,
            o.date_created as date_collected,
            vl.result_date
        FROM orders o
        INNER JOIN patient ON o.patient_id = patient.patient_id 
        INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
        INNER JOIN person_name ON person.person_id = person_name.person_id
        INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
        INNER JOIN reporting_age_group AS observed_age_group ON
            CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
            AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
        AND o.concept_id = 5484
        LEFT JOIN (
            SELECT 
                lab_order.order_id,
                VL_result.result_date
            FROM (
                SELECT order_id, value_text as Lab_Order_Number
                FROM obs 
                WHERE concept_id = 5498
                AND cast(obs_datetime as date) >= cast('#startDate#' as date)
                AND cast(obs_datetime as date) <= cast('#endDate#' as date)
                AND voided = 0
            ) lab_order
            LEFT JOIN (
                SELECT 
                    result.order_id,
                    cast(obs_datetime as date) as result_date
                FROM obs result
                WHERE (result.concept_id = 5485 OR result.concept_id = 5489)
                AND result.voided = 0
                AND cast(result.obs_datetime as date) >= cast('#startDate#' as date)
            ) VL_result
            ON lab_order.order_id = VL_result.order_id
        ) vl
        ON o.order_id = vl.order_id
        WHERE observed_age_group.report_group_name = 'Modified_Ages'
        AND CAST(o.date_created AS DATE) >= CAST('#startDate#' AS DATE)
        AND CAST(o.date_created AS DATE) <= CAST('#endDate#' AS DATE)
    ) as test
) as final;
