SELECT Completed_TPT_DRVD_COLS_ROWS.AgeGroup
		, Completed_TPT_DRVD_COLS_ROWS.Gender
		, Completed_TPT_DRVD_COLS_ROWS.Total

FROM (

			(SELECT Completed_TPT_DRVD_ROWS.age_group AS 'AgeGroup'
					, Completed_TPT_DRVD_ROWS.Gender
						, IF(Completed_TPT_DRVD_ROWS.Id IS NULL, 0, SUM(IF(Completed_TPT_DRVD_ROWS.Completed_TPT = 'Yes', 1, 0))) as 'Total'
						, Completed_TPT_DRVD_ROWS.sort_order
			FROM (
					SELECT distinct Id, Patient_Identifier, ART_Number, Patient_Name, Age , Gender, TPT_Start_Date, TPT_Completion_Date, age_group,sort_order,'Yes' as Completed_TPT
						FROM
							(
								(SELECT distinct Id, patientIdentifier AS "Patient_Identifier", ART_Number, patientName AS "Patient_Name", Age , Gender, age_group,sort_order
										FROM
														
											(select distinct patient.patient_id AS Id,
												patient_identifier.identifier AS patientIdentifier,
												pi2.identifier AS ART_Number,
												concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
												floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
												person.gender AS Gender,
												observed_age_group.name AS age_group,
												observed_age_group.sort_order AS sort_order


											from obs o
											
													INNER JOIN patient ON o.person_id = patient.patient_id 
													-- ART Clients
													AND o.concept_id = 3753
													AND o.person_id in 
														(
															-- Started TPT in the previous Period
															select distinct ob.person_id 
															from obs ob
															where ob.concept_id = 5401
															and CAST(ob.value_datetime as date) <= CAST('#endDate#' AS DATE)
															and ob.voided = 0
														)

														AND o.person_id in 
														(
															select distinct ob.person_id
															from obs ob
															-- TPT Completed on this period
															where ob.concept_id = 4821
															AND ob.value_datetime >= CAST('#startDate#' AS DATE)
															and ob.value_datetime <= CAST('#endDate#'AS DATE)
															and ob.voided = 0
														)
													INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
													INNER JOIN person_name ON person.person_id = person_name.person_id
													INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
													LEFT JOIN patient_identifier pi2 ON pi2.patient_id = person.person_id AND pi2.identifier_type in (5,12)
													INNER JOIN reporting_age_group AS observed_age_group ON
													CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
													AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
												WHERE observed_age_group.report_group_name = 'Modified_Ages') AS TPT_Clients
										ORDER BY TPT_Clients.Age) As TB_Prev_Numerator

								left outer join 
								(
									Select distinct person_id as pid, TPT_Start_Date
										FROM
										(select distinct o.person_id, cast(value_datetime as date) as TPT_Start_Date
												from obs o
												
												inner join
													(select distinct person_id, max(obs_datetime)as max_observation, SUBSTRING(MAX(CONCAT(obs_datetime, obs_id)), 20) AS observation_id
														from obs where concept_id = 3753
														and voided = 0
														group by person_id) as 6weeks_test
													on 6weeks_test.person_id = o.person_id
													where o.concept_id = 5401
													and cast(o.value_datetime as date) <= cast('#endDate#' as date)
													and cast(o.obs_datetime as date) = cast(max_observation as date)
													and o.voided = 0
													)TPT
								)TPT_Start
								on TPT_Start.pid = TB_Prev_Numerator.Id


								left outer join 
								(
									Select distinct person_id as pid, TPT_Completion_Date
										FROM
										(select distinct o.person_id, cast(value_datetime as date) as TPT_Completion_Date
												from obs o
												
												inner join
													(select distinct person_id, max(obs_datetime)as max_observation, SUBSTRING(MAX(CONCAT(obs_datetime, obs_id)), 20) AS observation_id
														from obs where concept_id = 3753
														and voided = 0
														group by person_id) as 6weeks_test
													on 6weeks_test.person_id = o.person_id
													where o.concept_id = 4821
													and cast(o.value_datetime as date) <= cast('#endDate#' as date)
													and cast(o.obs_datetime as date) = cast(max_observation as date)
													and o.voided = 0
													)TPT
								)TPT_Completion
								on TPT_Completion.pid = TB_Prev_Numerator.Id
						)

			) AS Completed_TPT_DRVD_ROWS

			GROUP BY Completed_TPT_DRVD_ROWS.age_group, Completed_TPT_DRVD_ROWS.Gender
			ORDER BY Completed_TPT_DRVD_ROWS.sort_order)
			
			
	UNION ALL

			(
					SELECT 'Total' AS 'AgeGroup'
							, 'All' AS 'Gender'		
						, IF(Completed_TPT_DRVD_COLS.Id IS NULL, 0, SUM(IF(Completed_TPT_DRVD_COLS.Completed_TPT = 'Yes', 1, 0))) as 'Total'
						, 99 AS sort_order
			FROM (
					SELECT distinct Id, Patient_Identifier, ART_Number, Patient_Name, Age , Gender, TPT_Start_Date, TPT_Completion_Date, age_group,sort_order,'Yes' as Completed_TPT
						FROM
							(
								(SELECT distinct Id, patientIdentifier AS "Patient_Identifier", ART_Number, patientName AS "Patient_Name", Age , Gender, age_group,sort_order
										FROM
														
											(select distinct patient.patient_id AS Id,
												patient_identifier.identifier AS patientIdentifier,
												pi2.identifier AS ART_Number,
												concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
												floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
												person.gender AS Gender,
												observed_age_group.name AS age_group,
												observed_age_group.sort_order AS sort_order


											from obs o
											
													INNER JOIN patient ON o.person_id = patient.patient_id 
													-- ART Clients
													AND o.concept_id = 3753
													AND o.person_id in 
														(
															-- Started TPT in the previous Period
															select distinct ob.person_id 
															from obs ob
															where ob.concept_id = 5401
															and CAST(ob.value_datetime as date) <= CAST('#endDate#' AS DATE)
															and ob.voided = 0
														)

														AND o.person_id in 
														(
															select distinct ob.person_id
															from obs ob
															-- TPT Completed on this period
															where ob.concept_id = 4821
															AND ob.value_datetime >= CAST('#startDate#' AS DATE)
															and ob.value_datetime <= CAST('#endDate#'AS DATE)
															and ob.voided = 0
														)
													INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
													INNER JOIN person_name ON person.person_id = person_name.person_id
													INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
													LEFT JOIN patient_identifier pi2 ON pi2.patient_id = person.person_id AND pi2.identifier_type in (5,12)
													INNER JOIN reporting_age_group AS observed_age_group ON
													CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
													AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
												WHERE observed_age_group.report_group_name = 'Modified_Ages') AS TPT_Clients
										ORDER BY TPT_Clients.Age) As TB_Prev_Numerator

								left outer join 
								(
									Select distinct person_id as pid, TPT_Start_Date
										FROM
										(select distinct o.person_id, cast(value_datetime as date) as TPT_Start_Date
												from obs o
												
												inner join
													(select distinct person_id, max(obs_datetime)as max_observation, SUBSTRING(MAX(CONCAT(obs_datetime, obs_id)), 20) AS observation_id
														from obs where concept_id = 3753
														and voided = 0
														group by person_id) as 6weeks_test
													on 6weeks_test.person_id = o.person_id
													where o.concept_id = 5401
													and cast(o.value_datetime as date) <= cast('#endDate#' as date)
													and cast(o.obs_datetime as date) = cast(max_observation as date)
													and o.voided = 0
													)TPT
								)TPT_Start
								on TPT_Start.pid = TB_Prev_Numerator.Id


								left outer join 
								(
									Select distinct person_id as pid, TPT_Completion_Date
										FROM
										(select distinct o.person_id, cast(value_datetime as date) as TPT_Completion_Date
												from obs o
												
												inner join
													(select distinct person_id, max(obs_datetime)as max_observation, SUBSTRING(MAX(CONCAT(obs_datetime, obs_id)), 20) AS observation_id
														from obs where concept_id = 3753
														and voided = 0
														group by person_id) as 6weeks_test
													on 6weeks_test.person_id = o.person_id
													where o.concept_id = 4821
													and cast(o.value_datetime as date) <= cast('#endDate#' as date)
													and cast(o.obs_datetime as date) = cast(max_observation as date)
													and o.voided = 0
													)TPT
								)TPT_Completion
								on TPT_Completion.pid = TB_Prev_Numerator.Id
						)

			) AS Completed_TPT_DRVD_COLS)
		
	) AS Completed_TPT_DRVD_COLS_ROWS
ORDER BY Completed_TPT_DRVD_COLS_ROWS.sort_order

