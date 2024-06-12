SELECT 'Label' AS Label, 'Average' AS Average
UNION ALL
SELECT "Average Turn Around Time" AS Label, 
       ROUND((total_turn_around_time / total_results_received), 1) AS Average
FROM (
    SELECT SUM(DATEDIFF(result_date, date_collected)) AS total_turn_around_time, 
           COUNT(*) AS total_results_received
    FROM (
        SELECT DISTINCT patient.patient_id AS Id,
                        patient_identifier.identifier AS patientIdentifier,
                        CONCAT(person_name.given_name, " ", person_name.family_name) AS patientName,
                        FLOOR(DATEDIFF(CAST('#endDate#' AS DATE), person.birthdate) / 365) AS Age,
                        person.gender AS Gender,
                        CAST(o.date_created AS DATE) AS date_collected,
                        observed_age_group.name AS age_group,
                        "Done" AS Test,
                        observed_age_group.sort_order AS sort_order,
                        o.order_id,
                        lab_orders.result_date
        FROM orders o
        INNER JOIN patient ON o.patient_id = patient.patient_id 
        INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
        INNER JOIN person_name ON person.person_id = person_name.person_id
        INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred = 1
        INNER JOIN reporting_age_group AS observed_age_group ON
            CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
            AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
            AND o.concept_id = 5484
        LEFT OUTER JOIN (
            SELECT person_id, 
                   Lab_Order_Number, 
                   lab_order.order_id AS orders_id, 
                   VL_result.order_id, 
                   VL_result.Results, 
                   VL_result.result_date 
            FROM (
                SELECT person_id, 
                       CAST(obs_datetime AS DATE) AS max_observation, 
                       SUBSTRING(CONCAT(obs_datetime, obs_id), 20) AS observation_id, 
                       order_id, 
                       value_text AS Lab_Order_Number
                FROM obs 
                WHERE concept_id = 5498
                  AND CAST(obs_datetime AS DATE) >= CAST('#startDate#' AS DATE)
                  AND CAST(obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
                  AND voided = 0
            ) lab_order
            LEFT OUTER JOIN (
                SELECT pId, 
                       result.order_id, 
                       Results, 
                       CAST(obs_datetime AS DATE) AS result_date
                FROM (
                    SELECT oss.person_id AS pId, 
                           CONCAT(oss.value_numeric, " ", "copies/ml") AS Results, 
                           order_id, 
                           oss.obs_datetime
                    FROM obs oss
                    WHERE oss.concept_id = 5485
                      AND oss.voided = 0
                      AND CAST(oss.obs_datetime AS DATE) >= CAST('#startDate#' AS DATE)
                    UNION
                    SELECT oss.person_id AS pId, 
                           "LDL" AS Results, 
                           order_id, 
                           oss.obs_datetime
                    FROM obs oss
                    WHERE oss.concept_id = 5489
                      AND oss.voided = 0
                      AND CAST(oss.obs_datetime AS DATE) >= CAST('#startDate#' AS DATE)
                ) result
            ) VL_result
            ON lab_order.order_id = VL_result.order_id
        ) lab_orders
        ON o.order_id = lab_orders.orders_id
        WHERE observed_age_group.report_group_name = 'Modified_Ages'
          AND CAST(o.date_created AS DATE) >= CAST('#startDate#' AS DATE)
          AND CAST(o.date_created AS DATE) <= CAST('#endDate#' AS DATE)
    ) AS tests
) AS lab_orders_with_TAT;
