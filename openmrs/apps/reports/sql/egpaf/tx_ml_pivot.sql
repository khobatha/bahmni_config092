SELECT Total_Aggregated_TxML.AgeGroup
		, Total_Aggregated_TxML.TOUT_M
		, Total_Aggregated_TxML.TOUT_F
		, Total_Aggregated_TxML.STOPPED_M
		, Total_Aggregated_TxML.STOPPED_F
		, Total_Aggregated_TxML.IIT_LT_3_M
		, Total_Aggregated_TxML.IIT_LT_3_F
		, Total_Aggregated_TxML.IIT_3to5_M
		, Total_Aggregated_TxML.IIT_3to5_F	
		, Total_Aggregated_TxML.IIT_GT_6_M
		, Total_Aggregated_TxML.IIT_GT_6_F		
		, Total_Aggregated_TxML.DIED_M
		, Total_Aggregated_TxML.DIED_F
		, Total_Aggregated_TxML.Total

FROM (
			(SELECT TX_ML_DETAILS.age_group AS 'AgeGroup'
					, IF(TX_ML_DETAILS.Id IS NULL, 0, SUM(IF(TX_ML_DETAILS.Outcome = 'TOUT' AND TX_ML_DETAILS.Gender = 'M', 1, 0))) AS TOUT_M
					, IF(TX_ML_DETAILS.Id IS NULL, 0, SUM(IF(TX_ML_DETAILS.Outcome = 'TOUT' AND TX_ML_DETAILS.Gender = 'F', 1, 0))) AS TOUT_F
					, IF(TX_ML_DETAILS.Id IS NULL, 0, SUM(IF(TX_ML_DETAILS.Outcome = 'STOPPED' AND TX_ML_DETAILS.Gender = 'M', 1, 0))) AS STOPPED_M
					, IF(TX_ML_DETAILS.Id IS NULL, 0, SUM(IF(TX_ML_DETAILS.Outcome = 'STOPPED' AND TX_ML_DETAILS.Gender = 'F', 1, 0))) AS STOPPED_F
					, IF(TX_ML_DETAILS.Id IS NULL, 0, SUM(IF(TX_ML_DETAILS.Outcome = 'IIT<3m' AND TX_ML_DETAILS.Gender = 'M', 1, 0))) AS IIT_LT_3_M
					, IF(TX_ML_DETAILS.Id IS NULL, 0, SUM(IF(TX_ML_DETAILS.Outcome = 'IIT<3m' AND TX_ML_DETAILS.Gender = 'F', 1, 0))) AS IIT_LT_3_F
					, IF(TX_ML_DETAILS.Id IS NULL, 0, SUM(IF(TX_ML_DETAILS.Outcome = 'IIT3-5m' AND TX_ML_DETAILS.Gender = 'M', 1, 0))) AS IIT_3to5_M
					, IF(TX_ML_DETAILS.Id IS NULL, 0, SUM(IF(TX_ML_DETAILS.Outcome = 'IIT3-5m' AND TX_ML_DETAILS.Gender = 'F', 1, 0))) AS IIT_3to5_F
					, IF(TX_ML_DETAILS.Id IS NULL, 0, SUM(IF(TX_ML_DETAILS.Outcome = 'IIT6+m' AND TX_ML_DETAILS.Gender = 'M', 1, 0))) AS IIT_GT_6_M
					, IF(TX_ML_DETAILS.Id IS NULL, 0, SUM(IF(TX_ML_DETAILS.Outcome = 'IIT6+m' AND TX_ML_DETAILS.Gender = 'F', 1, 0))) AS IIT_GT_6_F
					, IF(TX_ML_DETAILS.Id IS NULL, 0, SUM(IF(TX_ML_DETAILS.Outcome = 'DIED' AND TX_ML_DETAILS.Gender = 'M', 1, 0))) AS DIED_M
					, IF(TX_ML_DETAILS.Id IS NULL, 0, SUM(IF(TX_ML_DETAILS.Outcome = 'DIED' AND TX_ML_DETAILS.Gender = 'F', 1, 0))) AS DIED_F
					, IF(TX_ML_DETAILS.Id IS NULL, 0, SUM(1)) as 'Total'
					, TX_ML_DETAILS.sort_order
					
			FROM (			
						SELECT Id, patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age, Gender, age_group, Outcome, sort_order
						FROM
						(
								(SELECT Id, patientIdentifier, patientName, Age, Gender, age_group, 'DIED' AS Outcome, sort_order
			FROM
							(select obs_ml_clients.person_id AS Id,
												   patient_identifier.identifier AS patientIdentifier,
												   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
												   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
												   person.gender AS Gender,
												   observed_age_group.name AS age_group,
												   observed_age_group.sort_order AS sort_order
								from
								(
										select o.person_id
										from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND patient.voided = 0 AND o.voided = 0
												 AND o.person_id in (
														select person_id
														from 
															(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
															 from obs oss
															 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
															 and oss.obs_datetime < cast('#startDate#' as DATE)
															 group by p.person_id
															 having datediff(CAST(DATE_ADD(CAST('#startDate#' AS DATE), INTERVAL -1 DAY) AS DATE), latest_follow_up) < 29) as On_ART_Beginning_Quarter
												 )
												 AND o.person_id in (
													select person_id
													from 
														(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
														 from obs oss
														 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
														 and oss.obs_datetime <= cast('#endDate#' as DATE)
														 group by p.person_id
														 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
												 )
												 INNER JOIN patient_identifier ON patient_identifier.patient_id = patient.patient_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
										group by patient.patient_id
										UNION
										select o.person_id
										from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND patient.voided = 0 AND o.voided = 0
												 AND o.concept_id = 2249 and cast(o.value_datetime as date) >= cast('#startDate#' as DATE) and cast(o.value_datetime as date) <= cast('#endDate#' as DATE)
												 AND o.person_id in (
													select person_id
													from 
														(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
														 from obs oss
														 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
														 and oss.obs_datetime <= cast('#endDate#' as DATE)
														 group by p.person_id
														 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
												 )
												 INNER JOIN patient_identifier ON patient_identifier.patient_id = patient.patient_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
										group by patient.patient_id
								) as obs_ml_clients
								INNER JOIN person ON person.person_id = obs_ml_clients.person_id AND person.voided = 0
								INNER JOIN person_name ON person.person_id = person_name.person_id
								INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								INNER JOIN reporting_age_group AS observed_age_group ON
								CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
								WHERE observed_age_group.report_group_name = 'Modified_Ages'
									 AND obs_ml_clients.person_id in (
											select person_id 
											from person 
											where death_date <= CAST('#endDate#' AS DATE)
											and dead = 1
									 )
							    GROUP BY obs_ml_clients.person_id
							   ) AS TxMLClients
							  ORDER BY TxMLClients.Age)
							  
			UNION

			(SELECT Id, patientIdentifier, patientName, Age, Gender, age_group, 'TOUT' AS Outcome, sort_order
			FROM
							(select obs_ml_clients.person_id AS Id,
												   patient_identifier.identifier AS patientIdentifier,
												   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
												   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
												   person.gender AS Gender,
												   observed_age_group.name AS age_group,
												   observed_age_group.sort_order AS sort_order
								from
								(
										select o.person_id
										from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND patient.voided = 0 AND o.voided = 0
												 AND o.person_id in (
														select person_id
														from 
															(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
															 from obs oss
															 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
															 and oss.obs_datetime < cast('#startDate#' as DATE)
															 group by p.person_id
															 having datediff(CAST(DATE_ADD(CAST('#startDate#' AS DATE), INTERVAL -1 DAY) AS DATE), latest_follow_up) < 29) as On_ART_Beginning_Quarter
												 )
												 AND o.person_id in (
													select person_id
													from 
														(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
														 from obs oss
														 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
														 and oss.obs_datetime <= cast('#endDate#' as DATE)
														 group by p.person_id
														 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
												 )
												 INNER JOIN patient_identifier ON patient_identifier.patient_id = patient.patient_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
										group by patient.patient_id
										UNION
										select o.person_id
										from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND patient.voided = 0 AND o.voided = 0
												 AND o.concept_id = 2249 and cast(o.value_datetime as date) >= cast('#startDate#' as DATE) and cast(o.value_datetime as date) <= cast('#endDate#' as DATE)
												 AND o.person_id in (
													select person_id
													from 
														(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
														 from obs oss
														 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
														 and oss.obs_datetime <= cast('#endDate#' as DATE)
														 group by p.person_id
														 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
												 )
												 INNER JOIN patient_identifier ON patient_identifier.patient_id = patient.patient_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
										group by patient.patient_id
								) as obs_ml_clients
								INNER JOIN person ON person.person_id = obs_ml_clients.person_id AND person.voided = 0
								INNER JOIN person_name ON person.person_id = person_name.person_id
								INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								INNER JOIN reporting_age_group AS observed_age_group ON
								CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
								WHERE observed_age_group.report_group_name = 'Modified_Ages'
									 -- Transfered Out to Another Site
									 AND obs_ml_clients.person_id in (
											select distinct os.person_id 
											from obs os
											where os.concept_id = 4155 and os.value_coded = 2146
											AND os.obs_datetime <= CAST('#endDate#' AS DATE)						
									 )
									 -- NOT DEAD
									 AND obs_ml_clients.person_id not in (
											select person_id 
											from person 
											where death_date <= CAST('#endDate#' AS DATE)
											and dead = 1
									 )
							    GROUP BY obs_ml_clients.person_id

							   ) AS TxRttClients
							  ORDER BY TxRttClients.Age)		  

			UNION

			(SELECT Id, patientIdentifier, patientName, Age, Gender, age_group, 'STOPPED' AS Outcome, sort_order
			FROM
							(select obs_ml_clients.person_id AS Id,
												   patient_identifier.identifier AS patientIdentifier,
												   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
												   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
												   person.gender AS Gender,
												   observed_age_group.name AS age_group,
												   observed_age_group.sort_order AS sort_order
								from
								(
										select o.person_id
										from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND patient.voided = 0 AND o.voided = 0
												 AND o.person_id in (
														select person_id
														from 
															(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
															 from obs oss
															 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
															 and oss.obs_datetime < cast('#startDate#' as DATE)
															 group by p.person_id
															 having datediff(CAST(DATE_ADD(CAST('#startDate#' AS DATE), INTERVAL -1 DAY) AS DATE), latest_follow_up) < 29) as On_ART_Beginning_Quarter
												 )
												 AND o.person_id in (
													select person_id
													from 
														(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
														 from obs oss
														 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
														 and oss.obs_datetime <= cast('#endDate#' as DATE)
														 group by p.person_id
														 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
												 )
												 INNER JOIN patient_identifier ON patient_identifier.patient_id = patient.patient_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
										group by patient.patient_id
										UNION
										select o.person_id
										from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND patient.voided = 0 AND o.voided = 0
												 AND o.concept_id = 2249 and cast(o.value_datetime as date) >= cast('#startDate#' as DATE) and cast(o.value_datetime as date) <= cast('#endDate#' as DATE)
												 AND o.person_id in (
													select person_id
													from 
														(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
														 from obs oss
														 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
														 and oss.obs_datetime <= cast('#endDate#' as DATE)
														 group by p.person_id
														 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
												 )
												 INNER JOIN patient_identifier ON patient_identifier.patient_id = patient.patient_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
										group by patient.patient_id
								) as obs_ml_clients
								INNER JOIN person ON person.person_id = obs_ml_clients.person_id AND person.voided = 0
								INNER JOIN person_name ON person.person_id = person_name.person_id
								INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								INNER JOIN reporting_age_group AS observed_age_group ON
								CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
								WHERE observed_age_group.report_group_name = 'Modified_Ages'
									 -- ART TREATMENT INTERRUPTION/REFUSED OR STOPPED
									 AND obs_ml_clients.person_id in (
											select distinct os.person_id 
											from obs os
											where os.concept_id = 3701 
											AND os.value_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)						
									 )
							    GROUP BY obs_ml_clients.person_id
							   ) AS TxMLClients
							  ORDER BY TxMLClients.Age)

			UNION

			(SELECT Id, patientIdentifier, patientName, Age, Gender, age_group, 'IIT<3m' AS Outcome, sort_order
			FROM
							(select obs_ml_clients.person_id AS Id,
												   patient_identifier.identifier AS patientIdentifier,
												   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
												   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
												   person.gender AS Gender,
												   observed_age_group.name AS age_group,
												   observed_age_group.sort_order AS sort_order
								from
								(
										select o.person_id
										from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND patient.voided = 0 AND o.voided = 0
												 AND o.person_id in (
														select person_id
														from 
															(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
															 from obs oss
															 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
															 and oss.obs_datetime < cast('#startDate#' as DATE)
															 group by p.person_id
															 having datediff(CAST(DATE_ADD(CAST('#startDate#' AS DATE), INTERVAL -1 DAY) AS DATE), latest_follow_up) < 29) as On_ART_Beginning_Quarter
												 )
												 AND o.person_id in (
													select person_id
													from 
														(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
														 from obs oss
														 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
														 and oss.obs_datetime <= cast('#endDate#' as DATE)
														 group by p.person_id
														 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
												 )
												 INNER JOIN patient_identifier ON patient_identifier.patient_id = patient.patient_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
										group by patient.patient_id
										UNION
										select o.person_id
										from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND patient.voided = 0 AND o.voided = 0
												 AND o.concept_id = 2249 and cast(o.value_datetime as date) >= cast('#startDate#' as DATE) and cast(o.value_datetime as date) <= cast('#endDate#' as DATE)
												 AND o.person_id in (
													select person_id
													from 
														(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
														 from obs oss
														 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
														 and oss.obs_datetime <= cast('#endDate#' as DATE)
														 group by p.person_id
														 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
												 )
												 INNER JOIN patient_identifier ON patient_identifier.patient_id = patient.patient_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
										group by patient.patient_id
								) as obs_ml_clients
								INNER JOIN person ON person.person_id = obs_ml_clients.person_id AND person.voided = 0
								INNER JOIN person_name ON person.person_id = person_name.person_id
								INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								INNER JOIN reporting_age_group AS observed_age_group ON
								CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
								WHERE observed_age_group.report_group_name = 'Modified_Ages'
									 -- INITIATED ON ART LESS THAN 3 MONTHS AGO
									 AND obs_ml_clients.person_id in (
											select distinct os.person_id 
											from obs os
											where os.concept_id = 2249
											AND datediff(CAST('#endDate#' AS DATE), os.value_datetime) BETWEEN 0 AND 90						
									 )
									 -- NOT Transfered Out to Another Site
									 AND obs_ml_clients.person_id not in (
											select distinct os.person_id 
											from obs os
											where os.concept_id = 4155 and os.value_coded = 2146
											AND os.obs_datetime <= CAST('#endDate#' AS DATE)						
									 )
									 -- NOT DEAD
									 AND obs_ml_clients.person_id not in (
											select person_id 
											from person 
											where death_date <= CAST('#endDate#' AS DATE)
											and dead = 1
									 )
							    GROUP BY obs_ml_clients.person_id
							   ) AS TxMLClients
							  ORDER BY TxMLClients.Age)
					  
			UNION

			(SELECT Id, patientIdentifier, patientName, Age, Gender, age_group, 'IIT3-5m' AS Outcome, sort_order
			FROM
							(select obs_ml_clients.person_id AS Id,
												   patient_identifier.identifier AS patientIdentifier,
												   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
												   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
												   person.gender AS Gender,
												   observed_age_group.name AS age_group,
												   observed_age_group.sort_order AS sort_order
								from
								(
										select o.person_id
										from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND patient.voided = 0 AND o.voided = 0
												 AND o.person_id in (
														select person_id
														from 
															(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
															 from obs oss
															 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
															 and oss.obs_datetime < cast('#startDate#' as DATE)
															 group by p.person_id
															 having datediff(CAST(DATE_ADD(CAST('#startDate#' AS DATE), INTERVAL -1 DAY) AS DATE), latest_follow_up) < 29) as On_ART_Beginning_Quarter
												 )
												 AND o.person_id in (
													select person_id
													from 
														(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
														 from obs oss
														 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
														 and oss.obs_datetime <= cast('#endDate#' as DATE)
														 group by p.person_id
														 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
												 )
												 INNER JOIN patient_identifier ON patient_identifier.patient_id = patient.patient_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
										group by patient.patient_id
										UNION
										select o.person_id
										from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND patient.voided = 0 AND o.voided = 0
												 AND o.concept_id = 2249 and cast(o.value_datetime as date) >= cast('#startDate#' as DATE) and cast(o.value_datetime as date) <= cast('#endDate#' as DATE)
												 AND o.person_id in (
													select person_id
													from 
														(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
														 from obs oss
														 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
														 and oss.obs_datetime <= cast('#endDate#' as DATE)
														 group by p.person_id
														 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
												 )
												 INNER JOIN patient_identifier ON patient_identifier.patient_id = patient.patient_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
										group by patient.patient_id
								) as obs_ml_clients
								INNER JOIN person ON person.person_id = obs_ml_clients.person_id AND person.voided = 0
								INNER JOIN person_name ON person.person_id = person_name.person_id
								INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								INNER JOIN reporting_age_group AS observed_age_group ON
								CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
								WHERE observed_age_group.report_group_name = 'Modified_Ages'
									 -- INITIATED ON ART 3-5 MONTHS AGO
									 AND obs_ml_clients.person_id in (
											select distinct os.person_id 
											from obs os
											where os.concept_id = 2249
											AND datediff(CAST('#endDate#' AS DATE), os.value_datetime) BETWEEN 89 AND 180							
									 )
									 -- NOT Transfered Out to Another Site
									 AND obs_ml_clients.person_id not in (
											select distinct os.person_id 
											from obs os
											where os.concept_id = 4155 and os.value_coded = 2146
											AND os.obs_datetime <= CAST('#endDate#' AS DATE)						
									 )
									 -- NOT DEAD
									 AND obs_ml_clients.person_id not in (
											select person_id 
											from person 
											where death_date <= CAST('#endDate#' AS DATE)
											and dead = 1
									 )
							    GROUP BY obs_ml_clients.person_id
							   ) AS TxMLClients
							  ORDER BY TxMLClients.Age)

			UNION 

			(SELECT Id, patientIdentifier, patientName, Age, Gender, age_group, 'IIT6+m' AS Outcome, sort_order
			FROM
							(select obs_ml_clients.person_id AS Id,
												   patient_identifier.identifier AS patientIdentifier,
												   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
												   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
												   person.gender AS Gender,
												   observed_age_group.name AS age_group,
												   observed_age_group.sort_order AS sort_order
								from
								(
										select o.person_id
										from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND patient.voided = 0 AND o.voided = 0
												 AND o.person_id in (
														select person_id
														from 
															(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
															 from obs oss
															 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
															 and oss.obs_datetime < cast('#startDate#' as DATE)
															 group by p.person_id
															 having datediff(CAST(DATE_ADD(CAST('#startDate#' AS DATE), INTERVAL -1 DAY) AS DATE), latest_follow_up) < 29) as On_ART_Beginning_Quarter
												 )
												 AND o.person_id in (
													select person_id
													from 
														(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
														 from obs oss
														 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
														 and oss.obs_datetime <= cast('#endDate#' as DATE)
														 group by p.person_id
														 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
												 )
												 INNER JOIN patient_identifier ON patient_identifier.patient_id = patient.patient_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
										group by patient.patient_id
										UNION
										select o.person_id
										from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND patient.voided = 0 AND o.voided = 0
												 AND o.concept_id = 2249 and cast(o.value_datetime as date) >= cast('#startDate#' as DATE) and cast(o.value_datetime as date) <= cast('#endDate#' as DATE)
												 AND o.person_id in (
													select person_id
													from 
														(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
														 from obs oss
														 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
														 and oss.obs_datetime <= cast('#endDate#' as DATE)
														 group by p.person_id
														 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
												 )
												 INNER JOIN patient_identifier ON patient_identifier.patient_id = patient.patient_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
										group by patient.patient_id
								) as obs_ml_clients
								INNER JOIN person ON person.person_id = obs_ml_clients.person_id AND person.voided = 0
								INNER JOIN person_name ON person.person_id = person_name.person_id
								INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								INNER JOIN reporting_age_group AS observed_age_group ON
								CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
								WHERE observed_age_group.report_group_name = 'Modified_Ages'
									 -- INITIATED ON ART 6+ MONTHS AGO
									 AND obs_ml_clients.person_id in (
											select distinct os.person_id 
											from obs os
											where os.concept_id = 2249
											AND datediff(CAST('#endDate#' AS DATE), os.value_datetime) >= 180						
									 )
									 -- NOT Transfered Out to Another Site
									 AND obs_ml_clients.person_id not in (
											select distinct os.person_id 
											from obs os
											where os.concept_id = 4155 and os.value_coded = 2146
											AND os.obs_datetime <= CAST('#endDate#' AS DATE)						
									 )
									 -- NOT DEAD
									 AND obs_ml_clients.person_id not in (
											select person_id 
											from person 
											where death_date <= CAST('#endDate#' AS DATE)
											and dead = 1
									 )
							    GROUP BY obs_ml_clients.person_id
							   ) AS TxMLClients
							  ORDER BY TxMLClients.Age)		
						) AS treatment_mortality_and_loss
						GROUP BY treatment_mortality_and_loss.Id
				) AS TX_ML_DETAILS
				GROUP BY TX_ML_DETAILS.age_group
				ORDER BY TX_ML_DETAILS.sort_order)


			UNION ALL


			(SELECT 'Total' AS AgeGroup
					, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Outcome = 'TOUT' AND Totals.Gender = 'M', 1, 0))) AS TOUT_M
					, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Outcome = 'TOUT' AND Totals.Gender = 'F', 1, 0))) AS TOUT_F
					, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Outcome = 'STOPPED' AND Totals.Gender = 'M', 1, 0))) AS STOPPED_M
					, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Outcome = 'STOPPED' AND Totals.Gender = 'F', 1, 0))) AS STOPPED_F
					, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Outcome = 'IIT<3m' AND Totals.Gender = 'M', 1, 0))) AS IIT_LT_3_M
					, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Outcome = 'IIT<3m' AND Totals.Gender = 'F', 1, 0))) AS IIT_LT_3_F
					, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Outcome = 'IIT3-5m' AND Totals.Gender = 'M', 1, 0))) AS IIT_3to5_M
					, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Outcome = 'IIT3-5m' AND Totals.Gender = 'F', 1, 0))) AS IIT_3to5_F
					, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Outcome = 'IIT6+m' AND Totals.Gender = 'M', 1, 0))) AS IIT_GT_6_M
					, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Outcome = 'IIT6+m' AND Totals.Gender = 'F', 1, 0))) AS IIT_GT_6_F
					, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Outcome = 'DIED' AND Totals.Gender = 'M', 1, 0))) AS DIED_M
					, IF(Totals.Id IS NULL, 0, SUM(IF(Totals.Outcome = 'DIED' AND Totals.Gender = 'F', 1, 0))) AS DIED_F
					, IF(Totals.Id IS NULL, 0, SUM(1)) as 'Total'
					, 99 AS 'sort_order'
					
			FROM

					(SELECT  Total_TxML.Id
								, Total_TxML.Gender
								, Total_TxML.Outcome
							
					FROM
					(
						SELECT Id, patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age, Gender, age_group, Outcome, sort_order
						FROM
						(
								(SELECT Id, patientIdentifier, patientName, Age, Gender, age_group, 'DIED' AS Outcome, sort_order
			FROM
							(select obs_ml_clients.person_id AS Id,
												   patient_identifier.identifier AS patientIdentifier,
												   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
												   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
												   person.gender AS Gender,
												   observed_age_group.name AS age_group,
												   observed_age_group.sort_order AS sort_order
								from
								(
										select o.person_id
										from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND patient.voided = 0 AND o.voided = 0
												 AND o.person_id in (
														select person_id
														from 
															(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
															 from obs oss
															 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
															 and oss.obs_datetime < cast('#startDate#' as DATE)
															 group by p.person_id
															 having datediff(CAST(DATE_ADD(CAST('#startDate#' AS DATE), INTERVAL -1 DAY) AS DATE), latest_follow_up) < 29) as On_ART_Beginning_Quarter
												 )
												 AND o.person_id in (
													select person_id
													from 
														(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
														 from obs oss
														 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
														 and oss.obs_datetime <= cast('#endDate#' as DATE)
														 group by p.person_id
														 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
												 )
												 INNER JOIN patient_identifier ON patient_identifier.patient_id = patient.patient_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
										group by patient.patient_id
										UNION
										select o.person_id
										from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND patient.voided = 0 AND o.voided = 0
												 AND o.concept_id = 2249 and cast(o.value_datetime as date) >= cast('#startDate#' as DATE) and cast(o.value_datetime as date) <= cast('#endDate#' as DATE)
												 AND o.person_id in (
													select person_id
													from 
														(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
														 from obs oss
														 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
														 and oss.obs_datetime <= cast('#endDate#' as DATE)
														 group by p.person_id
														 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
												 )
												 INNER JOIN patient_identifier ON patient_identifier.patient_id = patient.patient_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
										group by patient.patient_id
								) as obs_ml_clients
								INNER JOIN person ON person.person_id = obs_ml_clients.person_id AND person.voided = 0
								INNER JOIN person_name ON person.person_id = person_name.person_id
								INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								INNER JOIN reporting_age_group AS observed_age_group ON
								CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
								WHERE observed_age_group.report_group_name = 'Modified_Ages'
									 AND obs_ml_clients.person_id in (
											select person_id 
											from person 
											where death_date <= CAST('#endDate#' AS DATE)
											and dead = 1
									 )
							    GROUP BY obs_ml_clients.person_id
							   ) AS TxMLClients
							  ORDER BY TxMLClients.Age)
							  
			UNION

			(SELECT Id, patientIdentifier, patientName, Age, Gender, age_group, 'TOUT' AS Outcome, sort_order
			FROM
							(select obs_ml_clients.person_id AS Id,
												   patient_identifier.identifier AS patientIdentifier,
												   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
												   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
												   person.gender AS Gender,
												   observed_age_group.name AS age_group,
												   observed_age_group.sort_order AS sort_order
								from
								(
										select o.person_id
										from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND patient.voided = 0 AND o.voided = 0
												 AND o.person_id in (
														select person_id
														from 
															(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
															 from obs oss
															 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
															 and oss.obs_datetime < cast('#startDate#' as DATE)
															 group by p.person_id
															 having datediff(CAST(DATE_ADD(CAST('#startDate#' AS DATE), INTERVAL -1 DAY) AS DATE), latest_follow_up) < 29) as On_ART_Beginning_Quarter
												 )
												 AND o.person_id in (
													select person_id
													from 
														(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
														 from obs oss
														 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
														 and oss.obs_datetime <= cast('#endDate#' as DATE)
														 group by p.person_id
														 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
												 )
												 INNER JOIN patient_identifier ON patient_identifier.patient_id = patient.patient_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
										group by patient.patient_id
										UNION
										select o.person_id
										from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND patient.voided = 0 AND o.voided = 0
												 AND o.concept_id = 2249 and cast(o.value_datetime as date) >= cast('#startDate#' as DATE) and cast(o.value_datetime as date) <= cast('#endDate#' as DATE)
												 AND o.person_id in (
													select person_id
													from 
														(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
														 from obs oss
														 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
														 and oss.obs_datetime <= cast('#endDate#' as DATE)
														 group by p.person_id
														 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
												 )
												 INNER JOIN patient_identifier ON patient_identifier.patient_id = patient.patient_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
										group by patient.patient_id
								) as obs_ml_clients
								INNER JOIN person ON person.person_id = obs_ml_clients.person_id AND person.voided = 0
								INNER JOIN person_name ON person.person_id = person_name.person_id
								INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								INNER JOIN reporting_age_group AS observed_age_group ON
								CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
								WHERE observed_age_group.report_group_name = 'Modified_Ages'
									 -- Transfered Out to Another Site
									 AND obs_ml_clients.person_id in (
											select distinct os.person_id 
											from obs os
											where os.concept_id = 4155 and os.value_coded = 2146
											AND os.obs_datetime <= CAST('#endDate#' AS DATE)						
									 )
									 -- NOT DEAD
									 AND obs_ml_clients.person_id not in (
											select person_id 
											from person 
											where death_date <= CAST('#endDate#' AS DATE)
											and dead = 1
									 )
							    GROUP BY obs_ml_clients.person_id

							   ) AS TxRttClients
							  ORDER BY TxRttClients.Age)		  

			UNION

			(SELECT Id, patientIdentifier, patientName, Age, Gender, age_group, 'STOPPED' AS Outcome, sort_order
			FROM
							(select obs_ml_clients.person_id AS Id,
												   patient_identifier.identifier AS patientIdentifier,
												   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
												   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
												   person.gender AS Gender,
												   observed_age_group.name AS age_group,
												   observed_age_group.sort_order AS sort_order
								from
								(
										select o.person_id
										from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND patient.voided = 0 AND o.voided = 0
												 AND o.person_id in (
														select person_id
														from 
															(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
															 from obs oss
															 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
															 and oss.obs_datetime < cast('#startDate#' as DATE)
															 group by p.person_id
															 having datediff(CAST(DATE_ADD(CAST('#startDate#' AS DATE), INTERVAL -1 DAY) AS DATE), latest_follow_up) < 29) as On_ART_Beginning_Quarter
												 )
												 AND o.person_id in (
													select person_id
													from 
														(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
														 from obs oss
														 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
														 and oss.obs_datetime <= cast('#endDate#' as DATE)
														 group by p.person_id
														 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
												 )
												 INNER JOIN patient_identifier ON patient_identifier.patient_id = patient.patient_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
										group by patient.patient_id
										UNION
										select o.person_id
										from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND patient.voided = 0 AND o.voided = 0
												 AND o.concept_id = 2249 and cast(o.value_datetime as date) >= cast('#startDate#' as DATE) and cast(o.value_datetime as date) <= cast('#endDate#' as DATE)
												 AND o.person_id in (
													select person_id
													from 
														(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
														 from obs oss
														 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
														 and oss.obs_datetime <= cast('#endDate#' as DATE)
														 group by p.person_id
														 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
												 )
												 INNER JOIN patient_identifier ON patient_identifier.patient_id = patient.patient_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
										group by patient.patient_id
								) as obs_ml_clients
								INNER JOIN person ON person.person_id = obs_ml_clients.person_id AND person.voided = 0
								INNER JOIN person_name ON person.person_id = person_name.person_id
								INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								INNER JOIN reporting_age_group AS observed_age_group ON
								CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
								WHERE observed_age_group.report_group_name = 'Modified_Ages'
									 -- ART TREATMENT INTERRUPTION/REFUSED OR STOPPED
									 AND obs_ml_clients.person_id in (
											select distinct os.person_id 
											from obs os
											where os.concept_id = 3701 
											AND os.value_datetime BETWEEN CAST('#startDate#' AS DATE) AND CAST('#endDate#' AS DATE)						
									 )
							    GROUP BY obs_ml_clients.person_id
							   ) AS TxMLClients
							  ORDER BY TxMLClients.Age)

			UNION

			(SELECT Id, patientIdentifier, patientName, Age, Gender, age_group, 'IIT<3m' AS Outcome, sort_order
			FROM
							(select obs_ml_clients.person_id AS Id,
												   patient_identifier.identifier AS patientIdentifier,
												   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
												   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
												   person.gender AS Gender,
												   observed_age_group.name AS age_group,
												   observed_age_group.sort_order AS sort_order
								from
								(
										select o.person_id
										from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND patient.voided = 0 AND o.voided = 0
												 AND o.person_id in (
														select person_id
														from 
															(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
															 from obs oss
															 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
															 and oss.obs_datetime < cast('#startDate#' as DATE)
															 group by p.person_id
															 having datediff(CAST(DATE_ADD(CAST('#startDate#' AS DATE), INTERVAL -1 DAY) AS DATE), latest_follow_up) < 29) as On_ART_Beginning_Quarter
												 )
												 AND o.person_id in (
													select person_id
													from 
														(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
														 from obs oss
														 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
														 and oss.obs_datetime <= cast('#endDate#' as DATE)
														 group by p.person_id
														 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
												 )
												 INNER JOIN patient_identifier ON patient_identifier.patient_id = patient.patient_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
										group by patient.patient_id
										UNION
										select o.person_id
										from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND patient.voided = 0 AND o.voided = 0
												 AND o.concept_id = 2249 and cast(o.value_datetime as date) >= cast('#startDate#' as DATE) and cast(o.value_datetime as date) <= cast('#endDate#' as DATE)
												 AND o.person_id in (
													select person_id
													from 
														(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
														 from obs oss
														 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
														 and oss.obs_datetime <= cast('#endDate#' as DATE)
														 group by p.person_id
														 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
												 )
												 INNER JOIN patient_identifier ON patient_identifier.patient_id = patient.patient_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
										group by patient.patient_id
								) as obs_ml_clients
								INNER JOIN person ON person.person_id = obs_ml_clients.person_id AND person.voided = 0
								INNER JOIN person_name ON person.person_id = person_name.person_id
								INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								INNER JOIN reporting_age_group AS observed_age_group ON
								CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
								WHERE observed_age_group.report_group_name = 'Modified_Ages'
									 -- INITIATED ON ART LESS THAN 3 MONTHS AGO
									 AND obs_ml_clients.person_id in (
											select distinct os.person_id 
											from obs os
											where os.concept_id = 2249
											AND datediff(CAST('#endDate#' AS DATE), os.value_datetime) BETWEEN 0 AND 90						
									 )
									 -- NOT Transfered Out to Another Site
									 AND obs_ml_clients.person_id not in (
											select distinct os.person_id 
											from obs os
											where os.concept_id = 4155 and os.value_coded = 2146
											AND os.obs_datetime <= CAST('#endDate#' AS DATE)						
									 )
									 -- NOT DEAD
									 AND obs_ml_clients.person_id not in (
											select person_id 
											from person 
											where death_date <= CAST('#endDate#' AS DATE)
											and dead = 1
									 )
							    GROUP BY obs_ml_clients.person_id
							   ) AS TxMLClients
							  ORDER BY TxMLClients.Age)
					  
			UNION

			(SELECT Id, patientIdentifier, patientName, Age, Gender, age_group, 'IIT3-5m' AS Outcome, sort_order
			FROM
							(select obs_ml_clients.person_id AS Id,
												   patient_identifier.identifier AS patientIdentifier,
												   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
												   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
												   person.gender AS Gender,
												   observed_age_group.name AS age_group,
												   observed_age_group.sort_order AS sort_order
								from
								(
										select o.person_id
										from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND patient.voided = 0 AND o.voided = 0
												 AND o.person_id in (
														select person_id
														from 
															(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
															 from obs oss
															 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
															 and oss.obs_datetime < cast('#startDate#' as DATE)
															 group by p.person_id
															 having datediff(CAST(DATE_ADD(CAST('#startDate#' AS DATE), INTERVAL -1 DAY) AS DATE), latest_follow_up) < 29) as On_ART_Beginning_Quarter
												 )
												 AND o.person_id in (
													select person_id
													from 
														(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
														 from obs oss
														 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
														 and oss.obs_datetime <= cast('#endDate#' as DATE)
														 group by p.person_id
														 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
												 )
												 INNER JOIN patient_identifier ON patient_identifier.patient_id = patient.patient_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
										group by patient.patient_id
										UNION
										select o.person_id
										from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND patient.voided = 0 AND o.voided = 0
												 AND o.concept_id = 2249 and cast(o.value_datetime as date) >= cast('#startDate#' as DATE) and cast(o.value_datetime as date) <= cast('#endDate#' as DATE)
												 AND o.person_id in (
													select person_id
													from 
														(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
														 from obs oss
														 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
														 and oss.obs_datetime <= cast('#endDate#' as DATE)
														 group by p.person_id
														 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
												 )
												 INNER JOIN patient_identifier ON patient_identifier.patient_id = patient.patient_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
										group by patient.patient_id
								) as obs_ml_clients
								INNER JOIN person ON person.person_id = obs_ml_clients.person_id AND person.voided = 0
								INNER JOIN person_name ON person.person_id = person_name.person_id
								INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								INNER JOIN reporting_age_group AS observed_age_group ON
								CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
								WHERE observed_age_group.report_group_name = 'Modified_Ages'
									 -- INITIATED ON ART 3-5 MONTHS AGO
									 AND obs_ml_clients.person_id in (
											select distinct os.person_id 
											from obs os
											where os.concept_id = 2249
											AND datediff(CAST('#endDate#' AS DATE), os.value_datetime) BETWEEN 89 AND 180							
									 )
									 -- NOT Transfered Out to Another Site
									 AND obs_ml_clients.person_id not in (
											select distinct os.person_id 
											from obs os
											where os.concept_id = 4155 and os.value_coded = 2146
											AND os.obs_datetime <= CAST('#endDate#' AS DATE)						
									 )
									 -- NOT DEAD
									 AND obs_ml_clients.person_id not in (
											select person_id 
											from person 
											where death_date <= CAST('#endDate#' AS DATE)
											and dead = 1
									 )
							    GROUP BY obs_ml_clients.person_id
							   ) AS TxMLClients
							  ORDER BY TxMLClients.Age)

			UNION 

			(SELECT Id, patientIdentifier, patientName, Age, Gender, age_group, 'IIT6+m' AS Outcome, sort_order
			FROM
							(select obs_ml_clients.person_id AS Id,
												   patient_identifier.identifier AS patientIdentifier,
												   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
												   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
												   person.gender AS Gender,
												   observed_age_group.name AS age_group,
												   observed_age_group.sort_order AS sort_order
								from
								(
										select o.person_id
										from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND patient.voided = 0 AND o.voided = 0
												 AND o.person_id in (
														select person_id
														from 
															(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
															 from obs oss
															 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
															 and oss.obs_datetime < cast('#startDate#' as DATE)
															 group by p.person_id
															 having datediff(CAST(DATE_ADD(CAST('#startDate#' AS DATE), INTERVAL -1 DAY) AS DATE), latest_follow_up) < 29) as On_ART_Beginning_Quarter
												 )
												 AND o.person_id in (
													select person_id
													from 
														(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
														 from obs oss
														 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
														 and oss.obs_datetime <= cast('#endDate#' as DATE)
														 group by p.person_id
														 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
												 )
												 INNER JOIN patient_identifier ON patient_identifier.patient_id = patient.patient_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
										group by patient.patient_id
										UNION
										select o.person_id
										from obs o
												 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND patient.voided = 0 AND o.voided = 0
												 AND o.concept_id = 2249 and cast(o.value_datetime as date) >= cast('#startDate#' as DATE) and cast(o.value_datetime as date) <= cast('#endDate#' as DATE)
												 AND o.person_id in (
													select person_id
													from 
														(select oss.person_id, MAX(oss.obs_datetime) as max_observation, SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_datetime)), 20) AS latest_follow_up
														 from obs oss
														 inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
														 and oss.obs_datetime <= cast('#endDate#' as DATE)
														 group by p.person_id
														 having datediff(CAST('#endDate#' AS DATE), latest_follow_up) > 28) as Missed_Greater_Than_28Days
												 )
												 INNER JOIN patient_identifier ON patient_identifier.patient_id = patient.patient_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
										group by patient.patient_id
								) as obs_ml_clients
								INNER JOIN person ON person.person_id = obs_ml_clients.person_id AND person.voided = 0
								INNER JOIN person_name ON person.person_id = person_name.person_id
								INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								INNER JOIN reporting_age_group AS observed_age_group ON
								CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
								WHERE observed_age_group.report_group_name = 'Modified_Ages'
									 -- INITIATED ON ART 6+ MONTHS AGO
									 AND obs_ml_clients.person_id in (
											select distinct os.person_id 
											from obs os
											where os.concept_id = 2249
											AND datediff(CAST('#endDate#' AS DATE), os.value_datetime) >= 180						
									 )
									 -- NOT Transfered Out to Another Site
									 AND obs_ml_clients.person_id not in (
											select distinct os.person_id 
											from obs os
											where os.concept_id = 4155 and os.value_coded = 2146
											AND os.obs_datetime <= CAST('#endDate#' AS DATE)						
									 )
									 -- NOT DEAD
									 AND obs_ml_clients.person_id not in (
											select person_id 
											from person 
											where death_date <= CAST('#endDate#' AS DATE)
											and dead = 1
									 )
							    GROUP BY obs_ml_clients.person_id
							   ) AS TxMLClients
							  ORDER BY TxMLClients.Age)	
							
						) AS treatment_mortality_and_loss
						GROUP BY treatment_mortality_and_loss.Id						
					) AS Total_TxML
			  ) AS Totals)
) AS Total_Aggregated_TxML
ORDER BY Total_Aggregated_TxML.sort_order