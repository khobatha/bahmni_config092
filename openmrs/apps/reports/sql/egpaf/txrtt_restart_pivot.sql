SELECT Total_Aggregated_TxCurr.AgeGroup
		, Total_Aggregated_TxCurr.Tx_RTT_ITT_less3months_Males AS "Tx_RTT ITT < 3months_Males"
		, Total_Aggregated_TxCurr.Tx_RTT_ITT_less3months_Females AS "Tx_RTT ITT < 3months_Females"
		, Total_Aggregated_TxCurr.Tx_RTT_ITT_3to5months_Males AS "Tx_RTT ITT 3-5months_Male"
		, Total_Aggregated_TxCurr.Tx_RTT_ITT_3to5months_Females AS "Tx_RTT ITT 3-5months_Females"
		, Total_Aggregated_TxCurr.Tx_RTT_ITT_6plusmonths_Males AS "Tx_RTT ITT 6+months_Males"
		, Total_Aggregated_TxCurr.Tx_RTT_ITT_6plusmonths_Females AS "Tx_RTT ITT 6+months_Females"
		, Total_Aggregated_TxCurr.Total

FROM (

	(SELECT TXCURR_DETAILS.age_group AS 'AgeGroup'
			, IF(TXCURR_DETAILS.Id IS NULL, 0, SUM(IF(TXCURR_DETAILS.Program_Status = 'Tx_RTT ITT <3 months' AND TXCURR_DETAILS.Gender = 'M', 1, 0))) AS Tx_RTT_ITT_less3months_Males
			, IF(TXCURR_DETAILS.Id IS NULL, 0, SUM(IF(TXCURR_DETAILS.Program_Status = 'Tx_RTT ITT <3 months' AND TXCURR_DETAILS.Gender = 'F', 1, 0))) AS Tx_RTT_ITT_less3months_Females
			, IF(TXCURR_DETAILS.Id IS NULL, 0, SUM(IF(TXCURR_DETAILS.Program_Status = 'Tx_RTT ITT 3 - 5months' AND TXCURR_DETAILS.Gender = 'M', 1, 0))) AS Tx_RTT_ITT_3to5months_Males
			, IF(TXCURR_DETAILS.Id IS NULL, 0, SUM(IF(TXCURR_DETAILS.Program_Status = 'Tx_RTT ITT 3 - 5months' AND TXCURR_DETAILS.Gender = 'F', 1, 0))) AS Tx_RTT_ITT_3to5months_Females
			, IF(TXCURR_DETAILS.Id IS NULL, 0, SUM(IF(TXCURR_DETAILS.Program_Status = 'Tx_RTT ITT 6+ months' AND TXCURR_DETAILS.Gender = 'M', 1, 0))) AS Tx_RTT_ITT_6plusmonths_Males
			, IF(TXCURR_DETAILS.Id IS NULL, 0, SUM(IF(TXCURR_DETAILS.Program_Status = 'Tx_RTT ITT 6+ months' AND TXCURR_DETAILS.Gender = 'F', 1, 0))) AS Tx_RTT_ITT_6plusmonths_Females
			, IF(TXCURR_DETAILS.Id IS NULL, 0, SUM(1)) as 'Total'
			, TXCURR_DETAILS.sort_order
			
	FROM (


			(SELECT distinct Id, patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age, Gender, age_group, Program_Status, sort_order
			FROM
                (Select distinct patient.patient_id AS Id,
						patient_identifier.identifier AS patientIdentifier,
						p.identifier as ART_Number,
						concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
						floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
						observed_age_group.name AS age_group,
						person.gender AS Gender,
						"Tx_RTT ITT <3 months" as "Program_Status",
						observed_age_group.sort_order AS sort_order
from obs o
-- Clients that returned after 0 -  3 months
						INNER JOIN patient ON o.person_id = patient.patient_id 
						 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
						INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
						INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
						AND o.voided=0
						INNER JOIN reporting_age_group AS observed_age_group ON
						CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
						AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						LEFT OUTER JOIN patient_identifier p ON p.patient_id = person.person_id AND p.identifier_type = 5
						WHERE observed_age_group.report_group_name = 'Modified_Ages' 
						AND patient.voided = 0 AND o.voided = 0
						AND o.person_id in (
							select person_id
							from 
								(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
								 from obs oss
								 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
								 and oss.obs_datetime < cast('#startDate#' as DATE)
								 group by p.person_id
								 having datediff(CAST(DATE_ADD(CAST('#startDate#' AS DATE), INTERVAL -1 DAY) AS DATE), latest_follow_up) BETWEEN 29 and 90) as Missed_Greater_Than_28Days
						 )

						 -- Client Seen: As either patient OR Treatment Buddy
						 AND (						 
								 o.person_id in (
										select distinct os.person_id
										from obs os
										where (os.concept_id = 3843 AND os.value_coded = 3841 OR os.value_coded = 3842)
										AND CAST(os.obs_datetime AS DATE) >= CAST('#startDate#' AS DATE)
										AND CAST(os.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								 )
								 
								 -- Client Seen and Date Restarted picked 
								 OR o.person_id in (
										select distinct os.person_id
										from obs os
										where os.concept_id = 3708 
										AND CAST(os.obs_datetime AS DATE) >= CAST('#startDate#' AS DATE)
										AND CAST(os.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								 )
						 )
						 -- Still on treatment at the end of the reporting period
						 AND o.person_id in (
							select person_id
							from 
								(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
								 from obs oss
								 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
								 and oss.obs_datetime >= cast('#startDate#' as DATE) and oss.obs_datetime <= cast('#endDate#' as DATE)
								 group by p.person_id
								 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) <= 28) as Still_On_Treatment_End_Period
						 )
						 
						 -- Transfered Out to Another Site during thier latest encounter before the start date
						 AND o.person_id not in (
							select person_id
							from 
								(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_coded)), 20) AS last_obs_tout
								 from obs oss
								 inner join person p on oss.person_id=p.person_id and oss.concept_id = 4155 and oss.voided=0
								 and oss.obs_datetime < cast('#startDate#' as DATE)
								 group by p.person_id
								 having last_obs_tout = 2146) as Transfered_Out_In_Last_Encounter
						 )
						 
						-- NOT Transfered In from another Site
						 AND o.person_id not in (
								select os.person_id 
								from obs os
								where os.concept_id = 2253 
								AND CAST(os.obs_datetime AS DATE) >= CAST('#startDate#' AS DATE)
								AND CAST(os.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								AND os.voided = 0					
						 )						 
						 
						 AND o.person_id not in (
									select person_id 
									from person 
									where death_date <= CAST('#endDate#' AS DATE)
									and dead = 1
						 )
        UNION

        Select distinct patient.patient_id AS Id,
						patient_identifier.identifier AS patientIdentifier,
						p.identifier as ART_Number,
						concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
						floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
						observed_age_group.name AS age_group,
						person.gender AS Gender,
						"Tx_RTT ITT 3 - 5months" as "Program_Status",
						observed_age_group.sort_order AS sort_order
from obs o
-- Clients that returned after 3 - 5 months
						INNER JOIN patient ON o.person_id = patient.patient_id 
						 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
						INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
						INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
						AND o.voided=0
						INNER JOIN reporting_age_group AS observed_age_group ON
						CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
						AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						LEFT OUTER JOIN patient_identifier p ON p.patient_id = person.person_id AND p.identifier_type = 5
						WHERE observed_age_group.report_group_name = 'Modified_Ages' 
						AND patient.voided = 0 AND o.voided = 0
						AND o.person_id in (
							select person_id
							from 
								(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
								 from obs oss
								 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
								 and oss.obs_datetime < cast('#startDate#' as DATE)
								 group by p.person_id
								 having datediff(CAST(DATE_ADD(CAST('#startDate#' AS DATE), INTERVAL -1 DAY) AS DATE), latest_follow_up) BETWEEN 89 and 180) as Missed_Between_89_and_180Days
						 )

						 -- Client Seen: As either patient OR Treatment Buddy
						 AND (						 
								 o.person_id in (
										select distinct os.person_id
										from obs os
										where (os.concept_id = 3843 AND os.value_coded = 3841 OR os.value_coded = 3842)
										AND CAST(os.obs_datetime AS DATE) >= CAST('#startDate#' AS DATE)
										AND CAST(os.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								 )
								 
								 -- Client Seen and Date Restarted picked 
								 OR o.person_id in (
										select distinct os.person_id
										from obs os
										where os.concept_id = 3708 
										AND CAST(os.obs_datetime AS DATE) >= CAST('#startDate#' AS DATE)
										AND CAST(os.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								 )
						 )
						 -- Still on treatment at the end of the reporting period
						 AND o.person_id in (
							select person_id
							from 
								(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
								 from obs oss
								 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
								 and oss.obs_datetime >= cast('#startDate#' as DATE) and oss.obs_datetime <= cast('#endDate#' as DATE)
								 group by p.person_id
								 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) <= 28) as Still_On_Treatment_End_Period
						 )
						 
						 -- Transfered Out to Another Site during thier latest encounter before the start date
						 AND o.person_id not in (
							select person_id
							from 
								(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_coded)), 20) AS last_obs_tout
								 from obs oss
								 inner join person p on oss.person_id=p.person_id and oss.concept_id = 4155 and oss.voided=0
								 and oss.obs_datetime < cast('#startDate#' as DATE)
								 group by p.person_id
								 having last_obs_tout = 2146) as Transfered_Out_In_Last_Encounter
						 )
						 
						-- NOT Transfered In from another Site
						 AND o.person_id not in (
								select os.person_id 
								from obs os
								where os.concept_id = 2253 
								AND CAST(os.obs_datetime AS DATE) >= CAST('#startDate#' AS DATE)
								AND CAST(os.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								AND os.voided = 0					
						 )						 
						 
						 AND o.person_id not in (
									select person_id 
									from person 
									where death_date <= CAST('#endDate#' AS DATE)
									and dead = 1
						 )
        UNION

           Select distinct patient.patient_id AS Id,
						patient_identifier.identifier AS patientIdentifier,
						p.identifier as ART_Number,
						concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
						floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
						observed_age_group.name AS age_group,
						person.gender AS Gender,
						"Tx_RTT ITT 6+ months" as "Program_Status",
						observed_age_group.sort_order AS sort_order
from obs o
-- Clients that returned after 6+ months
						INNER JOIN patient ON o.person_id = patient.patient_id 
						 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
						INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
						INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
						AND o.voided=0
						INNER JOIN reporting_age_group AS observed_age_group ON
						CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
						AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						LEFT OUTER JOIN patient_identifier p ON p.patient_id = person.person_id AND p.identifier_type = 5
						WHERE observed_age_group.report_group_name = 'Modified_Ages' 
						AND patient.voided = 0 AND o.voided = 0
						AND o.person_id in (
							select person_id
							from 
								(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
								 from obs oss
								 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
								 and oss.obs_datetime < cast('#startDate#' as DATE)
								 group by p.person_id
								 having datediff(CAST(DATE_ADD(CAST('#startDate#' AS DATE), INTERVAL -1 DAY) AS DATE), latest_follow_up) >= 180) as Missed_Greater_Than_180Days
						 )

						 -- Client Seen: As either patient OR Treatment Buddy
						 AND (						 
								 o.person_id in (
										select distinct os.person_id
										from obs os
										where (os.concept_id = 3843 AND os.value_coded = 3841 OR os.value_coded = 3842)
										AND CAST(os.obs_datetime AS DATE) >= CAST('#startDate#' AS DATE)
										AND CAST(os.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								 )
								 
								 -- Client Seen and Date Restarted picked 
								 OR o.person_id in (
										select distinct os.person_id
										from obs os
										where os.concept_id = 3708 
										AND CAST(os.obs_datetime AS DATE) >= CAST('#startDate#' AS DATE)
										AND CAST(os.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								 )
						 )
						 -- Still on treatment at the end of the reporting period
						 AND o.person_id in (
							select person_id
							from 
								(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
								 from obs oss
								 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
								 and oss.obs_datetime >= cast('#startDate#' as DATE) and oss.obs_datetime <= cast('#endDate#' as DATE)
								 group by p.person_id
								 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) <= 28) as Still_On_Treatment_End_Period
						 )
						 
						 -- Transfered Out to Another Site during thier latest encounter before the start date
						 AND o.person_id not in (
							select person_id
							from 
								(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_coded)), 20) AS last_obs_tout
								 from obs oss
								 inner join person p on oss.person_id=p.person_id and oss.concept_id = 4155 and oss.voided=0
								 and oss.obs_datetime < cast('#startDate#' as DATE)
								 group by p.person_id
								 having last_obs_tout = 2146) as Transfered_Out_In_Last_Encounter
						 )
						 
						-- NOT Transfered In from another Site
						 AND o.person_id not in (
								select os.person_id 
								from obs os
								where os.concept_id = 2253 
								AND CAST(os.obs_datetime AS DATE) >= CAST('#startDate#' AS DATE)
								AND CAST(os.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								AND os.voided = 0					
						 )						 
						 
						 AND o.person_id not in (
									select person_id 
									from person 
									where death_date <= CAST('#endDate#' AS DATE)
									and dead = 1
						 )) AS TX_RTT)




	
	) AS TXCURR_DETAILS

	GROUP BY TXCURR_DETAILS.age_group
	ORDER BY TXCURR_DETAILS.sort_order)
	
	
UNION ALL


(SELECT 'Total' AS AgeGroup
		, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Program_Status = 'Tx_RTT ITT <3 months' AND Totals.Gender = 'M', 1, 0))) AS Tx_RTT_ITT_less3months_Males
		, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Program_Status = 'Tx_RTT ITT <3 months' AND Totals.Gender = 'F', 1, 0))) AS Tx_RTT_ITT_less3months_Females
		, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Program_Status = 'Tx_RTT ITT 3 - 5months' AND Totals.Gender = 'M', 1, 0))) AS Tx_RTT_ITT_3to5months_Males
		, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Program_Status = 'Tx_RTT ITT 3 - 5months' AND Totals.Gender = 'F', 1, 0))) AS Tx_RTT_ITT_3to5months_Females
		, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Program_Status = 'Tx_RTT ITT 6+ months' AND Totals.Gender = 'M', 1, 0))) AS Tx_RTT_ITT_6plusmonths_Males
		, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Program_Status = 'Tx_RTT ITT 6+ months' AND Totals.Gender = 'F', 1, 0))) AS Tx_RTT_ITT_6plusmonths_Females
		, IF(Totals.Id IS NULL, 0, SUM(1)) as 'Total'
		, 99 AS 'sort_order'
		
FROM

		(SELECT  Total_TxCurr.Id
					, Total_TxCurr.Gender
					, Total_TxCurr.Program_Status
				
		FROM (


			(SELECT distinct Id, patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age, Gender, age_group, Program_Status, sort_order
			FROM
                (Select distinct patient.patient_id AS Id,
						patient_identifier.identifier AS patientIdentifier,
						p.identifier as ART_Number,
						concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
						floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
						observed_age_group.name AS age_group,
						person.gender AS Gender,
						"Tx_RTT ITT <3 months" as "Program_Status",
						observed_age_group.sort_order AS sort_order
from obs o
-- Clients that returned after 0 -  3 months
						INNER JOIN patient ON o.person_id = patient.patient_id 
						 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
						INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
						INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
						AND o.voided=0
						INNER JOIN reporting_age_group AS observed_age_group ON
						CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
						AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						LEFT OUTER JOIN patient_identifier p ON p.patient_id = person.person_id AND p.identifier_type = 5
						WHERE observed_age_group.report_group_name = 'Modified_Ages' 
						AND patient.voided = 0 AND o.voided = 0
						AND o.person_id in (
							select person_id
							from 
								(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
								 from obs oss
								 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
								 and oss.obs_datetime < cast('#startDate#' as DATE)
								 group by p.person_id
								 having datediff(CAST(DATE_ADD(CAST('#startDate#' AS DATE), INTERVAL -1 DAY) AS DATE), latest_follow_up) BETWEEN 29 and 90) as Missed_Greater_Than_28Days
						 )

						 -- Client Seen: As either patient OR Treatment Buddy
						 AND (						 
								 o.person_id in (
										select distinct os.person_id
										from obs os
										where (os.concept_id = 3843 AND os.value_coded = 3841 OR os.value_coded = 3842)
										AND CAST(os.obs_datetime AS DATE) >= CAST('#startDate#' AS DATE)
										AND CAST(os.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								 )
								 
								 -- Client Seen and Date Restarted picked 
								 OR o.person_id in (
										select distinct os.person_id
										from obs os
										where os.concept_id = 3708 
										AND CAST(os.obs_datetime AS DATE) >= CAST('#startDate#' AS DATE)
										AND CAST(os.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								 )
						 )
						 -- Still on treatment at the end of the reporting period
						 AND o.person_id in (
							select person_id
							from 
								(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
								 from obs oss
								 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
								 and oss.obs_datetime >= cast('#startDate#' as DATE) and oss.obs_datetime <= cast('#endDate#' as DATE)
								 group by p.person_id
								 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) <= 28) as Still_On_Treatment_End_Period
						 )
						 
						 -- Transfered Out to Another Site during thier latest encounter before the start date
						 AND o.person_id not in (
							select person_id
							from 
								(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_coded)), 20) AS last_obs_tout
								 from obs oss
								 inner join person p on oss.person_id=p.person_id and oss.concept_id = 4155 and oss.voided=0
								 and oss.obs_datetime < cast('#startDate#' as DATE)
								 group by p.person_id
								 having last_obs_tout = 2146) as Transfered_Out_In_Last_Encounter
						 )
						 
						-- NOT Transfered In from another Site
						 AND o.person_id not in (
								select os.person_id 
								from obs os
								where os.concept_id = 2253 
								AND CAST(os.obs_datetime AS DATE) >= CAST('#startDate#' AS DATE)
								AND CAST(os.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								AND os.voided = 0					
						 )						 
						 
						 AND o.person_id not in (
									select person_id 
									from person 
									where death_date <= CAST('#endDate#' AS DATE)
									and dead = 1
						 )
        UNION

        Select distinct patient.patient_id AS Id,
						patient_identifier.identifier AS patientIdentifier,
						p.identifier as ART_Number,
						concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
						floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
						observed_age_group.name AS age_group,
						person.gender AS Gender,
						"Tx_RTT ITT 3 - 5months" as "Program_Status",
						observed_age_group.sort_order AS sort_order
from obs o
-- Clients that returned after 3 - 5 months
						INNER JOIN patient ON o.person_id = patient.patient_id 
						 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
						INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
						INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
						AND o.voided=0
						INNER JOIN reporting_age_group AS observed_age_group ON
						CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
						AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						LEFT OUTER JOIN patient_identifier p ON p.patient_id = person.person_id AND p.identifier_type = 5
						WHERE observed_age_group.report_group_name = 'Modified_Ages' 
						AND patient.voided = 0 AND o.voided = 0
						AND o.person_id in (
							select person_id
							from 
								(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
								 from obs oss
								 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
								 and oss.obs_datetime < cast('#startDate#' as DATE)
								 group by p.person_id
								 having datediff(CAST(DATE_ADD(CAST('#startDate#' AS DATE), INTERVAL -1 DAY) AS DATE), latest_follow_up) BETWEEN 89 and 180) as Missed_Between_89_and_180Days
						 )

						 -- Client Seen: As either patient OR Treatment Buddy
						 AND (						 
								 o.person_id in (
										select distinct os.person_id
										from obs os
										where (os.concept_id = 3843 AND os.value_coded = 3841 OR os.value_coded = 3842)
										AND CAST(os.obs_datetime AS DATE) >= CAST('#startDate#' AS DATE)
										AND CAST(os.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								 )
								 
								 -- Client Seen and Date Restarted picked 
								 OR o.person_id in (
										select distinct os.person_id
										from obs os
										where os.concept_id = 3708 
										AND CAST(os.obs_datetime AS DATE) >= CAST('#startDate#' AS DATE)
										AND CAST(os.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								 )
						 )
						 -- Still on treatment at the end of the reporting period
						 AND o.person_id in (
							select person_id
							from 
								(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
								 from obs oss
								 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
								 and oss.obs_datetime >= cast('#startDate#' as DATE) and oss.obs_datetime <= cast('#endDate#' as DATE)
								 group by p.person_id
								 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) <= 28) as Still_On_Treatment_End_Period
						 )
						 
						 -- Transfered Out to Another Site during thier latest encounter before the start date
						 AND o.person_id not in (
							select person_id
							from 
								(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_coded)), 20) AS last_obs_tout
								 from obs oss
								 inner join person p on oss.person_id=p.person_id and oss.concept_id = 4155 and oss.voided=0
								 and oss.obs_datetime < cast('#startDate#' as DATE)
								 group by p.person_id
								 having last_obs_tout = 2146) as Transfered_Out_In_Last_Encounter
						 )
						 
						-- NOT Transfered In from another Site
						 AND o.person_id not in (
								select os.person_id 
								from obs os
								where os.concept_id = 2253 
								AND CAST(os.obs_datetime AS DATE) >= CAST('#startDate#' AS DATE)
								AND CAST(os.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								AND os.voided = 0					
						 )						 
						 
						 AND o.person_id not in (
									select person_id 
									from person 
									where death_date <= CAST('#endDate#' AS DATE)
									and dead = 1
						 )
        UNION

           Select distinct patient.patient_id AS Id,
						patient_identifier.identifier AS patientIdentifier,
						p.identifier as ART_Number,
						concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
						floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
						observed_age_group.name AS age_group,
						person.gender AS Gender,
						"Tx_RTT ITT 6+ months" as "Program_Status",
						observed_age_group.sort_order AS sort_order
from obs o
-- Clients that returned after 6+ months
						INNER JOIN patient ON o.person_id = patient.patient_id 
						 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
						INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
						INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
						AND o.voided=0
						INNER JOIN reporting_age_group AS observed_age_group ON
						CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
						AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						LEFT OUTER JOIN patient_identifier p ON p.patient_id = person.person_id AND p.identifier_type = 5
						WHERE observed_age_group.report_group_name = 'Modified_Ages' 
						AND patient.voided = 0 AND o.voided = 0
						AND o.person_id in (
							select person_id
							from 
								(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
								 from obs oss
								 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
								 and oss.obs_datetime < cast('#startDate#' as DATE)
								 group by p.person_id
								 having datediff(CAST(DATE_ADD(CAST('#startDate#' AS DATE), INTERVAL -1 DAY) AS DATE), latest_follow_up) >= 180) as Missed_Greater_Than_180Days
						 )

						 -- Client Seen: As either patient OR Treatment Buddy
						 AND (						 
								 o.person_id in (
										select distinct os.person_id
										from obs os
										where (os.concept_id = 3843 AND os.value_coded = 3841 OR os.value_coded = 3842)
										AND CAST(os.obs_datetime AS DATE) >= CAST('#startDate#' AS DATE)
										AND CAST(os.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								 )
								 
								 -- Client Seen and Date Restarted picked 
								 OR o.person_id in (
										select distinct os.person_id
										from obs os
										where os.concept_id = 3708 
										AND CAST(os.obs_datetime AS DATE) >= CAST('#startDate#' AS DATE)
										AND CAST(os.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								 )
						 )
						 -- Still on treatment at the end of the reporting period
						 AND o.person_id in (
							select person_id
							from 
								(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
								 from obs oss
								 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
								 and oss.obs_datetime >= cast('#startDate#' as DATE) and oss.obs_datetime <= cast('#endDate#' as DATE)
								 group by p.person_id
								 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) <= 28) as Still_On_Treatment_End_Period
						 )
						 
						 -- Transfered Out to Another Site during thier latest encounter before the start date
						 AND o.person_id not in (
							select person_id
							from 
								(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_coded)), 20) AS last_obs_tout
								 from obs oss
								 inner join person p on oss.person_id=p.person_id and oss.concept_id = 4155 and oss.voided=0
								 and oss.obs_datetime < cast('#startDate#' as DATE)
								 group by p.person_id
								 having last_obs_tout = 2146) as Transfered_Out_In_Last_Encounter
						 )
						 
						-- NOT Transfered In from another Site
						 AND o.person_id not in (
								select os.person_id 
								from obs os
								where os.concept_id = 2253 
								AND CAST(os.obs_datetime AS DATE) >= CAST('#startDate#' AS DATE)
								AND CAST(os.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
								AND os.voided = 0					
						 )						 
						 
						 AND o.person_id not in (
									select person_id 
									from person 
									where death_date <= CAST('#endDate#' AS DATE)
									and dead = 1
						 )) AS TX_RTT)		

		
		) AS Total_TxCurr
  ) AS Totals
 )
) AS Total_Aggregated_TxCurr
ORDER BY Total_Aggregated_TxCurr.sort_order