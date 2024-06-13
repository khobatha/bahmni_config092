SELECT 
    "Average Turn Around Time" as "Metric", 
    ROUND(AVG(TurnAroundTime), 1) as "Average Turn Around Time"
FROM
(
    SELECT 
        datediff(result_date, date_collected) as TurnAroundTime
    FROM
    (
        SELECT 
            o.patient_id AS Id,
            o.order_id,
            CAST(o.date_created AS DATE) as date_collected,
            CAST(obs.obs_datetime AS DATE) as result_date
        FROM 
            orders o
            INNER JOIN patient ON o.patient_id = patient.patient_id 
            INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
            INNER JOIN person_name ON person.person_id = person_name.person_id
            INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id 
                AND patient_identifier.identifier_type = 3 
                AND patient_identifier.preferred = 1
            INNER JOIN reporting_age_group AS observed_age_group ON
                CAST('#endDate#' AS DATE) BETWEEN 
                    DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY)
                AND 
                    DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY)
            INNER JOIN obs ON obs.order_id = o.order_id
        WHERE 
            observed_age_group.report_group_name = 'Modified_Ages'
            AND CAST(o.date_created AS DATE) >= CAST('#startDate#' AS DATE)
            AND CAST(o.date_created AS DATE) <= CAST('#endDate#' AS DATE)
            AND o.concept_id = 5484
            AND obs.concept_id IN (5485, 5489)
            AND obs.voided = 0
            AND CAST(obs.obs_datetime AS DATE) >= CAST('#startDate#' AS DATE)
            AND CAST(obs.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
    ) AS lab_orders_with_TAT
) AS average_turn_around_time
