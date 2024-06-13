SELECT "Average Turn Around Time" as "Average Turn Around Time"
FROM (
    SELECT 
        round((SUM(datediff(result_date, date_collected))/COUNT(*)), 1) as "Average Turn Around Time"
    FROM (
        SELECT 
            datediff(result_date, date_collected) as turn_around_time
        FROM (
            SELECT DISTINCT 
                patient.patient_id AS Id,
                patient_identifier.identifier AS patientIdentifier,
                concat(person_name.given_name, " ", person_name.family_name) AS patientName,
                floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
                person.gender AS Gender,
                cast(o.date_created as date) as date_collected,
                observed_age_group.name AS age_group,
                "Done" AS Test,
                observed_age_group.sort_order AS sort_order,
                order_id
            FROM orders o
            INNER JOIN patient ON o.patient_id = patient.patient_id 
            INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
            INNER JOIN person_name ON person.person_id = person_name.person_id
            INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
            INNER JOIN reporting_age_group AS observed_age_group ON
                CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
                AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
            AND o.concept_id = 5484
            WHERE observed_age_group.report_group_name = 'Modified_Ages'
            AND CAST(o.date_created AS DATE) >= CAST('#startDate#' AS DATE)
            AND CAST(o.date_created AS DATE) <= CAST('#endDate#' AS DATE)
        ) as test
        LEFT JOIN (
            SELECT 
                person_id, 
                Lab_Order_Number, 
                lab_order.order_id as orders_id, 
                VL_result.order_id, 
                VL_result.Results, 
                result_date 
            FROM (
                SELECT 
                    person_id, 
                    cast(obs_datetime as date) as max_observation, 
                    SUBSTRING(CONCAT(obs_datetime, obs_id), 20) AS observation_id, 
                    order_id, 
                    value_text as Lab_Order_Number
                FROM obs 
                WHERE concept_id = 5498
                AND cast(obs_datetime as date) >= cast('#startDate#' as date)
                AND cast(obs_datetime as date) <= cast('#endDate#' as date)
                AND voided = 0
            ) lab_order
            LEFT JOIN (
                SELECT 
                    pId, 
                    result.order_id, 
                    Results, 
                    cast(obs_datetime as date) as result_date
                FROM (
                    SELECT 
                        oss.person_id as pId, 
                        concat(oss.value_numeric, " ", "copies/ml") as Results, 
                        order_id, 
                        oss.obs_datetime
                    FROM obs oss
                    WHERE oss.concept_id = 5485
                    AND oss.voided = 0
                    AND cast(oss.obs_datetime as date) >= cast('#startDate#' as date)
                    UNION
                    SELECT 
                        oss.person_id as pId, 
                        "LDL" as Results, 
                        order_id, 
                        oss.obs_datetime
                    FROM obs oss
                    WHERE oss.concept_id = 5489
                    AND oss.voided = 0
                    AND cast(oss.obs_datetime as date) >= cast('#startDate#' as date)
                ) result
            ) VL_result
            ON lab_order.order_id = VL_result.order_id
        ) lab_orders
        ON test.order_id = lab_orders.orders_id
    ) tests
) lab_orders_with_TAT;
