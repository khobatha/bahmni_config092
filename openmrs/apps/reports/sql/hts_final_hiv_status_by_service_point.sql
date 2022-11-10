
SELECT  Patient_Identifier, Patient_Name, Age, Gender, age_group, HIV_Testing_Initiation , Testing_History , HIV_Status
FROM (
	(SELECT Id, patientIdentifier AS "Patient_Identifier", patientName AS "Patient_Name", Age, Gender, age_group, 'PITC' AS 'HIV_Testing_Initiation'
				, 'Repeat' AS 'Testing_History' , HIV_Status, current_conc, sort_order
		FROM
						(select distinct patient.patient_id AS Id,
											   patient_identifier.identifier AS patientIdentifier,
											   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
											   floor(datediff(CAST("#endDate#" AS DATE), person.birthdate)/365) AS Age,
											   (select name from concept_name cn where cn.concept_id = 1738 and concept_name_type='FULLY_SPECIFIED') AS HIV_Status,
											   person.gender AS Gender,
											   observed_age_group.name AS age_group,
											   pitc.current_conc,
											   observed_age_group.sort_order AS sort_order

						from obs o
								-- HTS CLIENTS WITH HIV STATUS BY SEX AND AGE
								 INNER JOIN patient ON o.person_id = patient.patient_id 
								 AND o.concept_id = 2165 and o.value_coded = 1738
								 AND patient.voided = 0 AND o.voided = 0
								 AND MONTH(o.obs_datetime) = MONTH(CAST("#endDate#" AS DATE)) 
                            	 AND YEAR(o.obs_datetime) = YEAR(CAST("#endDate#" AS DATE))
								 
								 -- PROVIDER INITIATED TESTING AND COUNSELING
								 Inner Join (
									select distinct os.person_id, CAST(os.date_created as Date) as current_conc 
									from obs os
									INNER JOIN patient ON os.person_id = patient.patient_id
									where os.concept_id = 4228 and os.value_coded = 4227
									AND MONTH(os.obs_datetime) = MONTH(CAST("#endDate#" AS DATE)) 
                            		AND YEAR(os.obs_datetime) = YEAR(CAST("#endDate#" AS DATE))
									AND patient.voided = 0 AND os.voided = 0
								 ) as pitc
								 on o.person_id = pitc.person_id
								 							 
								 -- REPEAT TESTER, HAS A HISTORY OF PREVIOUS TESTING
								 Inner Join (
									select distinct os.person_id, CAST(os.date_created as Date) as current_conc
									from obs os
									INNER JOIN patient ON os.person_id = patient.patient_id
									where os.concept_id = 2137 and os.value_coded = 2146
									AND MONTH(os.obs_datetime) = MONTH(CAST("#endDate#" AS DATE)) 
                            		AND YEAR(os.obs_datetime) = YEAR(CAST("#endDate#" AS DATE))
									AND patient.voided = 0 AND os.voided = 0
								 ) as repeater
								 on o.person_id = repeater.person_id
								 and pitc.current_conc = repeater.current_conc
                                 
								 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
								 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
								 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								 INNER JOIN reporting_age_group AS observed_age_group ON
								  CAST("#endDate#" AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						   WHERE observed_age_group.report_group_name = 'Modified_Ages'
								) AS HTSClients_HIV_Status
		ORDER BY HTSClients_HIV_Status.HIV_Status, HTSClients_HIV_Status.Age)

	UNION ALL

	(SELECT Id, patientIdentifier AS "Patient_Identifier", patientName AS "Patient_Name", Age, Gender, age_group, 'PITC' AS 'HIV_Testing_Initiation'
				, 'Repeat' AS 'Testing_History' , HIV_Status, current_conc, sort_order
		FROM
						(select distinct patient.patient_id AS Id,
											   patient_identifier.identifier AS patientIdentifier,
											   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
											   floor(datediff(CAST("#endDate#" AS DATE), person.birthdate)/365) AS Age,
											   (select name from concept_name cn where cn.concept_id = 1738 and concept_name_type='FULLY_SPECIFIED') AS HIV_Status,
											   person.gender AS Gender,
											   observed_age_group.name AS age_group,
											   pitc.current_conc,
											   observed_age_group.sort_order AS sort_order

						from obs o
								-- HTS CLIENTS WITH HIV STATUS BY SEX AND AGE
								 INNER JOIN patient ON o.person_id = patient.patient_id 
								 AND o.concept_id = 2165 and o.value_coded = 1738
								 AND patient.voided = 0 AND o.voided = 0
								 AND MONTH(o.obs_datetime) = MONTH(CAST("#endDate#" AS DATE)) 
                            	 AND YEAR(o.obs_datetime) = YEAR(CAST("#endDate#" AS DATE))
								 
								 -- PROVIDER INITIATED TESTING AND COUNSELING
								 Inner Join (
									select distinct os.person_id, CAST(os.date_created as Date) as current_conc 
									from obs os
									INNER JOIN patient ON os.person_id = patient.patient_id
									where os.concept_id = 4228 and os.value_coded = 4227
									AND MONTH(os.obs_datetime) = MONTH(CAST("#endDate#" AS DATE)) 
                            		AND YEAR(os.obs_datetime) = YEAR(CAST("#endDate#" AS DATE))
									AND patient.voided = 0 AND os.voided = 0
								 ) as pitc
								 on o.person_id = pitc.person_id
								 							 
								 -- NEW TESTER, DOES NOT HAVE HISTORY OF PREVIOUS TESTING
								 Inner Join (
									select distinct os.person_id, CAST(os.date_created as Date) as current_conc
									from obs os
									INNER JOIN patient ON os.person_id = patient.patient_id
									where os.concept_id = 2137 and os.value_coded = 2147
									AND MONTH(os.obs_datetime) = MONTH(CAST("#endDate#" AS DATE)) 
                            		AND YEAR(os.obs_datetime) = YEAR(CAST("#endDate#" AS DATE))
									AND patient.voided = 0 AND os.voided = 0
								 ) as repeater
								 on o.person_id = repeater.person_id
								 and pitc.current_conc = repeater.current_conc
                                 
								 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
								 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
								 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								 INNER JOIN reporting_age_group AS observed_age_group ON
								  CAST("#endDate#" AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						   WHERE observed_age_group.report_group_name = 'Modified_Ages'
								) AS HTSClients_HIV_Status
		ORDER BY HTSClients_HIV_Status.HIV_Status, HTSClients_HIV_Status.Age)

	UNION ALL
	(SELECT Id, patientIdentifier AS "Patient_Identifier", patientName AS "Patient_Name", Age, Gender, age_group, 'PITC' AS 'HIV_Testing_Initiation'
				, 'Repeat' AS 'Testing_History' , HIV_Status, current_conc, sort_order
		FROM
						(select distinct patient.patient_id AS Id,
											   patient_identifier.identifier AS patientIdentifier,
											   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
											   floor(datediff(CAST("#endDate#" AS DATE), person.birthdate)/365) AS Age,
											   (select name from concept_name cn where cn.concept_id = 1016 and concept_name_type='FULLY_SPECIFIED') AS HIV_Status,
											   person.gender AS Gender,
											   observed_age_group.name AS age_group,
											   pitc.current_conc,
											   observed_age_group.sort_order AS sort_order

						from obs o
								-- HTS CLIENTS WITH HIV STATUS BY SEX AND AGE
								 INNER JOIN patient ON o.person_id = patient.patient_id 
								 AND o.concept_id = 2165 and o.value_coded = 1016
								 AND patient.voided = 0 AND o.voided = 0
								 AND MONTH(o.obs_datetime) = MONTH(CAST("#endDate#" AS DATE)) 
                            	 AND YEAR(o.obs_datetime) = YEAR(CAST("#endDate#" AS DATE))
								 
								 -- PROVIDER INITIATED TESTING AND COUNSELING
								 Inner Join (
									select distinct os.person_id, CAST(os.date_created as Date) as current_conc 
									from obs os
									INNER JOIN patient ON os.person_id = patient.patient_id
									where os.concept_id = 4228 and os.value_coded = 4227
									AND MONTH(os.obs_datetime) = MONTH(CAST("#endDate#" AS DATE)) 
                            		AND YEAR(os.obs_datetime) = YEAR(CAST("#endDate#" AS DATE))
									AND patient.voided = 0 AND os.voided = 0
								 ) as pitc
								 on o.person_id = pitc.person_id
								 							 
								 -- REPEATER, HAS HISTORY OF PREVIOUS TESTING
								 Inner Join (
									select distinct os.person_id, CAST(os.date_created as Date) as current_conc
									from obs os
									INNER JOIN patient ON os.person_id = patient.patient_id
									where os.concept_id = 2137 and os.value_coded = 2146
									AND MONTH(os.obs_datetime) = MONTH(CAST("#endDate#" AS DATE)) 
                            		AND YEAR(os.obs_datetime) = YEAR(CAST("#endDate#" AS DATE))
									AND patient.voided = 0 AND os.voided = 0
								 ) as repeater
								 on o.person_id = repeater.person_id
								 and pitc.current_conc = repeater.current_conc
                                 
								 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
								 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
								 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								 INNER JOIN reporting_age_group AS observed_age_group ON
								  CAST("#endDate#" AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						   WHERE observed_age_group.report_group_name = 'Modified_Ages'
								) AS HTSClients_HIV_Status
		ORDER BY HTSClients_HIV_Status.HIV_Status, HTSClients_HIV_Status.Age)

	UNION ALL

	(SELECT Id, patientIdentifier AS "Patient_Identifier", patientName AS "Patient_Name", Age, Gender, age_group, 'PITC' AS 'HIV_Testing_Initiation'
				, 'Repeat' AS 'Testing_History' , HIV_Status, current_conc, sort_order
		FROM
						(select distinct patient.patient_id AS Id,
											   patient_identifier.identifier AS patientIdentifier,
											   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
											   floor(datediff(CAST("#endDate#" AS DATE), person.birthdate)/365) AS Age,
											   (select name from concept_name cn where cn.concept_id = 1016 and concept_name_type='FULLY_SPECIFIED') AS HIV_Status,
											   person.gender AS Gender,
											   observed_age_group.name AS age_group,
											   pitc.current_conc,
											   observed_age_group.sort_order AS sort_order

						from obs o
								-- HTS CLIENTS WITH HIV STATUS BY SEX AND AGE
								 INNER JOIN patient ON o.person_id = patient.patient_id 
								 AND o.concept_id = 2165 and o.value_coded = 1016
								 AND patient.voided = 0 AND o.voided = 0
								 AND MONTH(o.obs_datetime) = MONTH(CAST("#endDate#" AS DATE)) 
                            	 AND YEAR(o.obs_datetime) = YEAR(CAST("#endDate#" AS DATE))
								 
								 -- PROVIDER INITIATED TESTING AND COUNSELING
								 Inner Join (
									select distinct os.person_id, CAST(os.date_created as Date) as current_conc 
									from obs os
									INNER JOIN patient ON os.person_id = patient.patient_id
									where os.concept_id = 4228 and os.value_coded = 4227
									AND MONTH(os.obs_datetime) = MONTH(CAST("#endDate#" AS DATE)) 
                            		AND YEAR(os.obs_datetime) = YEAR(CAST("#endDate#" AS DATE))
									AND patient.voided = 0 AND os.voided = 0
								 ) as pitc
								 on o.person_id = pitc.person_id
								 							 
								 -- NEW TESTER, DOES NOT HAVE HISTORY OF PREVIOUS TESTING
								 Inner Join (
									select distinct os.person_id, CAST(os.date_created as Date) as current_conc
									from obs os
									INNER JOIN patient ON os.person_id = patient.patient_id
									where os.concept_id = 2137 and os.value_coded = 2147
									AND MONTH(os.obs_datetime) = MONTH(CAST("#endDate#" AS DATE)) 
                            		AND YEAR(os.obs_datetime) = YEAR(CAST("#endDate#" AS DATE))
									AND patient.voided = 0 AND os.voided = 0
								 ) as repeater
								 on o.person_id = repeater.person_id
								 and pitc.current_conc = repeater.current_conc
                                 
								 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
								 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
								 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								 INNER JOIN reporting_age_group AS observed_age_group ON
								  CAST("#endDate#" AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						   WHERE observed_age_group.report_group_name = 'Modified_Ages'
								) AS HTSClients_HIV_Status
		ORDER BY HTSClients_HIV_Status.HIV_Status, HTSClients_HIV_Status.Age)

	UNION ALL

	(SELECT Id, patientIdentifier AS "Patient_Identifier", patientName AS "Patient_Name", Age, Gender, age_group, 'CITC' AS 'HIV_Testing_Initiation'
				, 'Repeat' AS 'Testing_History' , HIV_Status, current_conc, sort_order
		FROM
						(select distinct patient.patient_id AS Id,
											   patient_identifier.identifier AS patientIdentifier,
											   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
											   floor(datediff(CAST("#endDate#" AS DATE), person.birthdate)/365) AS Age,
											   (select name from concept_name cn where cn.concept_id = 1738 and concept_name_type='FULLY_SPECIFIED') AS HIV_Status,
											   person.gender AS Gender,
											   observed_age_group.name AS age_group,
											   pitc.current_conc,
											   observed_age_group.sort_order AS sort_order

						from obs o
								-- HTS CLIENTS WITH HIV STATUS BY SEX AND AGE
								 INNER JOIN patient ON o.person_id = patient.patient_id 
								 AND o.concept_id = 2165 and o.value_coded = 1738
								 AND patient.voided = 0 AND o.voided = 0
								 AND MONTH(o.obs_datetime) = MONTH(CAST("#endDate#" AS DATE)) 
                            	 AND YEAR(o.obs_datetime) = YEAR(CAST("#endDate#" AS DATE))
								 
								 -- CLIENT INITIATED TESTING AND COUNSELING
								 Inner Join (
									select distinct os.person_id, CAST(os.date_created as Date) as current_conc 
									from obs os
									INNER JOIN patient ON os.person_id = patient.patient_id
									where os.concept_id = 4228 and os.value_coded = 4226
									AND MONTH(os.obs_datetime) = MONTH(CAST("#endDate#" AS DATE)) 
                            		AND YEAR(os.obs_datetime) = YEAR(CAST("#endDate#" AS DATE))
									AND patient.voided = 0 AND os.voided = 0
								 ) as pitc
								 on o.person_id = pitc.person_id
								 							 
								 -- REPEAT TESTER, HAS A HISTORY OF PREVIOUS TESTING
								 Inner Join (
									select distinct os.person_id, CAST(os.date_created as Date) as current_conc
									from obs os
									INNER JOIN patient ON os.person_id = patient.patient_id
									where os.concept_id = 2137 and os.value_coded = 2146
									AND MONTH(os.obs_datetime) = MONTH(CAST("#endDate#" AS DATE)) 
                            		AND YEAR(os.obs_datetime) = YEAR(CAST("#endDate#" AS DATE))
									AND patient.voided = 0 AND os.voided = 0
								 ) as repeater
								 on o.person_id = repeater.person_id
								 and pitc.current_conc = repeater.current_conc
                                 
								 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
								 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
								 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								 INNER JOIN reporting_age_group AS observed_age_group ON
								  CAST("#endDate#" AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						   WHERE observed_age_group.report_group_name = 'Modified_Ages'
								) AS HTSClients_HIV_Status
		ORDER BY HTSClients_HIV_Status.HIV_Status, HTSClients_HIV_Status.Age)

	UNION ALL
	(SELECT Id, patientIdentifier AS "Patient_Identifier", patientName AS "Patient_Name", Age, Gender, age_group, 'CITC' AS 'HIV_Testing_Initiation'
				, 'Repeat' AS 'Testing_History' , HIV_Status, current_conc, sort_order
		FROM
						(select distinct patient.patient_id AS Id,
											   patient_identifier.identifier AS patientIdentifier,
											   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
											   floor(datediff(CAST("#endDate#" AS DATE), person.birthdate)/365) AS Age,
											   (select name from concept_name cn where cn.concept_id = 1738 and concept_name_type='FULLY_SPECIFIED') AS HIV_Status,
											   person.gender AS Gender,
											   observed_age_group.name AS age_group,
											   pitc.current_conc,
											   observed_age_group.sort_order AS sort_order

						from obs o
								-- HTS CLIENTS WITH HIV STATUS BY SEX AND AGE
								 INNER JOIN patient ON o.person_id = patient.patient_id 
								 AND o.concept_id = 2165 and o.value_coded = 1738
								 AND patient.voided = 0 AND o.voided = 0
								 AND MONTH(o.obs_datetime) = MONTH(CAST("#endDate#" AS DATE)) 
                            	 AND YEAR(o.obs_datetime) = YEAR(CAST("#endDate#" AS DATE))
								 
								 -- CLIENT INITIATED TESTING AND COUNSELING
								 Inner Join (
									select distinct os.person_id, CAST(os.date_created as Date) as current_conc 
									from obs os
									INNER JOIN patient ON os.person_id = patient.patient_id
									where os.concept_id = 4228 and os.value_coded = 4226
									AND MONTH(os.obs_datetime) = MONTH(CAST("#endDate#" AS DATE)) 
                            		AND YEAR(os.obs_datetime) = YEAR(CAST("#endDate#" AS DATE))
									AND patient.voided = 0 AND os.voided = 0
								 ) as pitc
								 on o.person_id = pitc.person_id
								 							 
								 -- NEW TESTER, DOES NOT HAVE HISTORY OF PREVIOUS TESTING
								 Inner Join (
									select distinct os.person_id, CAST(os.date_created as Date) as current_conc
									from obs os
									INNER JOIN patient ON os.person_id = patient.patient_id
									where os.concept_id = 2137 and os.value_coded = 2147
									AND MONTH(os.obs_datetime) = MONTH(CAST("#endDate#" AS DATE)) 
                            		AND YEAR(os.obs_datetime) = YEAR(CAST("#endDate#" AS DATE))
									AND patient.voided = 0 AND os.voided = 0
								 ) as repeater
								 on o.person_id = repeater.person_id
								 and pitc.current_conc = repeater.current_conc
                                 
								 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
								 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
								 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								 INNER JOIN reporting_age_group AS observed_age_group ON
								  CAST("#endDate#" AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						   WHERE observed_age_group.report_group_name = 'Modified_Ages'
								) AS HTSClients_HIV_Status
		ORDER BY HTSClients_HIV_Status.HIV_Status, HTSClients_HIV_Status.Age)

	UNION ALL

	(SELECT Id, patientIdentifier AS "Patient_Identifier", patientName AS "Patient_Name", Age, Gender, age_group, 'CITC' AS 'HIV_Testing_Initiation'
				, 'Repeat' AS 'Testing_History' , HIV_Status, current_conc, sort_order
		FROM
						(select distinct patient.patient_id AS Id,
											   patient_identifier.identifier AS patientIdentifier,
											   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
											   floor(datediff(CAST("#endDate#" AS DATE), person.birthdate)/365) AS Age,
											   (select name from concept_name cn where cn.concept_id = 1016 and concept_name_type='FULLY_SPECIFIED') AS HIV_Status,
											   person.gender AS Gender,
											   observed_age_group.name AS age_group,
											   pitc.current_conc,
											   observed_age_group.sort_order AS sort_order

						from obs o
								-- HTS CLIENTS WITH HIV STATUS BY SEX AND AGE
								 INNER JOIN patient ON o.person_id = patient.patient_id 
								 AND o.concept_id = 2165 and o.value_coded = 1016
								 AND patient.voided = 0 AND o.voided = 0
								 AND MONTH(o.obs_datetime) = MONTH(CAST("#endDate#" AS DATE)) 
                            	 AND YEAR(o.obs_datetime) = YEAR(CAST("#endDate#" AS DATE))
								 
								 -- CLIENT INITIATED TESTING AND COUNSELING
								 Inner Join (
									select distinct os.person_id, CAST(os.date_created as Date) as current_conc 
									from obs os
									INNER JOIN patient ON os.person_id = patient.patient_id
									where os.concept_id = 4228 and os.value_coded = 4226
									AND MONTH(os.obs_datetime) = MONTH(CAST("#endDate#" AS DATE)) 
                            		AND YEAR(os.obs_datetime) = YEAR(CAST("#endDate#" AS DATE))
									AND patient.voided = 0 AND os.voided = 0
								 ) as pitc
								 on o.person_id = pitc.person_id
								 							 
								 -- REPEATER, DOES NOT HAVE HISTORY OF PREVIOUS TESTING
								 Inner Join (
									select distinct os.person_id, CAST(os.date_created as Date) as current_conc
									from obs os
									INNER JOIN patient ON os.person_id = patient.patient_id
									where os.concept_id = 2137 and os.value_coded = 2146
									AND MONTH(os.obs_datetime) = MONTH(CAST("#endDate#" AS DATE)) 
                            		AND YEAR(os.obs_datetime) = YEAR(CAST("#endDate#" AS DATE))
									AND patient.voided = 0 AND os.voided = 0
								 ) as repeater
								 on o.person_id = repeater.person_id
								 and pitc.current_conc = repeater.current_conc
                                 
								 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
								 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
								 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								 INNER JOIN reporting_age_group AS observed_age_group ON
								  CAST("#endDate#" AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						   WHERE observed_age_group.report_group_name = 'Modified_Ages'
								) AS HTSClients_HIV_Status
		ORDER BY HTSClients_HIV_Status.HIV_Status, HTSClients_HIV_Status.Age)
	UNION ALL

	(SELECT Id, patientIdentifier AS "Patient_Identifier", patientName AS "Patient_Name", Age, Gender, age_group, 'CITC' AS 'HIV_Testing_Initiation'
				, 'Repeat' AS 'Testing_History' , HIV_Status, current_conc, sort_order
		FROM
						(select distinct patient.patient_id AS Id,
											   patient_identifier.identifier AS patientIdentifier,
											   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
											   floor(datediff(CAST("#endDate#" AS DATE), person.birthdate)/365) AS Age,
											   (select name from concept_name cn where cn.concept_id = 1016 and concept_name_type='FULLY_SPECIFIED') AS HIV_Status,
											   person.gender AS Gender,
											   observed_age_group.name AS age_group,
											   pitc.current_conc,
											   observed_age_group.sort_order AS sort_order

						from obs o
								-- HTS CLIENTS WITH HIV STATUS BY SEX AND AGE
								 INNER JOIN patient ON o.person_id = patient.patient_id 
								 AND o.concept_id = 2165 and o.value_coded = 1016
								 AND patient.voided = 0 AND o.voided = 0
								 AND MONTH(o.obs_datetime) = MONTH(CAST("#endDate#" AS DATE)) 
                            	 AND YEAR(o.obs_datetime) = YEAR(CAST("#endDate#" AS DATE))
								 
								 -- CLIENT INITIATED TESTING AND COUNSELING
								 Inner Join (
									select distinct os.person_id, CAST(os.date_created as Date) as current_conc 
									from obs os
									INNER JOIN patient ON os.person_id = patient.patient_id
									where os.concept_id = 4228 and os.value_coded = 4226
									AND MONTH(os.obs_datetime) = MONTH(CAST("#endDate#" AS DATE)) 
                            		AND YEAR(os.obs_datetime) = YEAR(CAST("#endDate#" AS DATE))
									AND patient.voided = 0 AND os.voided = 0
								 ) as pitc
								 on o.person_id = pitc.person_id
								 							 
								 -- NEW TESTER, DOES NOT HAVE HISTORY OF PREVIOUS TESTING
								 Inner Join (
									select distinct os.person_id, CAST(os.date_created as Date) as current_conc
									from obs os
									INNER JOIN patient ON os.person_id = patient.patient_id
									where os.concept_id = 2137 and os.value_coded = 2147
									AND MONTH(os.obs_datetime) = MONTH(CAST("#endDate#" AS DATE)) 
                            		AND YEAR(os.obs_datetime) = YEAR(CAST("#endDate#" AS DATE))
									AND patient.voided = 0 AND os.voided = 0
								 ) as repeater
								 on o.person_id = repeater.person_id
								 and pitc.current_conc = repeater.current_conc
                                 
								 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
								 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
								 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								 INNER JOIN reporting_age_group AS observed_age_group ON
								  CAST("#endDate#" AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
								  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
						   WHERE observed_age_group.report_group_name = 'Modified_Ages'
								) AS HTSClients_HIV_Status
		ORDER BY HTSClients_HIV_Status.HIV_Status, HTSClients_HIV_Status.Age)
	)AS HTS_Status_Detailed

ORDER BY HTS_Status_Detailed.HIV_Testing_Initiation
			, HTS_Status_Detailed.Testing_History
			, HTS_Status_Detailed.sort_order
			, HTS_Status_Detailed.Gender
			, HTS_Status_Detailed.HIV_Status


									