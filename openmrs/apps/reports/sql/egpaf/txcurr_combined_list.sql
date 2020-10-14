(SELECT  patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age, Gender, age_group, 'Initiated' AS 'Program_Status', sort_order
FROM
                (select distinct patient.patient_id AS Id,
									   patient_identifier.identifier AS patientIdentifier,
									   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
									   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
									   person.gender AS Gender,
									   observed_age_group.name AS age_group,
									   observed_age_group.sort_order AS sort_order

                from obs o
						-- CLIENTS NEWLY INITIATED ON ART
						 INNER JOIN patient ON o.person_id = patient.patient_id 
						 AND (o.concept_id = 2249 

						AND MONTH(o.value_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
						AND YEAR(o.value_datetime) = YEAR(CAST('#endDate#' AS DATE))
						 )
						 AND patient.voided = 0 AND o.voided = 0
						 AND o.person_id not in (
							select distinct os.person_id from obs os
							where os.concept_id = 3634 
							AND os.value_coded = 2095 
							AND MONTH(os.obs_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
							AND YEAR(os.obs_datetime) = YEAR(CAST('#endDate#' AS DATE))
						 )	
						 
						 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
						 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
						 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
						 INNER JOIN reporting_age_group AS observed_age_group ON
						  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
						  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
                   WHERE observed_age_group.report_group_name = 'Modified_Ages') AS Newly_Initiated_ART_Clients
ORDER BY Newly_Initiated_ART_Clients.Age)

UNION

(SELECT patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age, Gender, age_group, 'Seen' AS 'Program_Status', sort_order
FROM (

select distinct patient.patient_id AS Id,
                                   patient_identifier.identifier AS patientIdentifier,
                                   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
                                   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
                                   person.gender AS Gender,
                                   observed_age_group.name AS age_group,
								   observed_age_group.sort_order AS sort_order
        from obs o
								-- CLIENTS SEEN FOR ART
                                 INNER JOIN patient ON o.person_id = patient.patient_id
                                 AND (o.concept_id = 3843 AND o.value_coded = 3841 OR o.value_coded = 3842)
								 AND MONTH(o.obs_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
								 AND YEAR(o.obs_datetime) = YEAR(CAST('#endDate#' AS DATE))
                                 AND patient.voided = 0 AND o.voided = 0
                                 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
                                 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
                                 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
								 INNER JOIN reporting_age_group AS observed_age_group ON
									  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
									  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
           WHERE observed_age_group.report_group_name = 'Modified_Ages'

) AS Clients_Seen

WHERE Clients_Seen.Id not in (
		select distinct patient.patient_id AS Id
		from obs o
				-- CLIENTS NEWLY INITIATED ON ART
				 INNER JOIN patient ON o.person_id = patient.patient_id
				 AND (o.concept_id = 2249 
											AND MONTH(o.value_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
											AND YEAR(o.value_datetime) = YEAR(CAST('#endDate#' AS DATE))
						)		
				 AND patient.voided = 0 AND o.voided = 0

							)
AND Clients_Seen.Id not in (
							select distinct(o.person_id)
							from obs o
							where o.person_id in (
									-- FOLLOW UPS
										select firstquery.person_id
										from
										(
										select oss.person_id, SUBSTRING(MAX(CONCAT(oss.value_datetime, oss.obs_id)), 20) AS observation_id, CAST(max(oss.value_datetime) AS DATE) as latest_followup_obs
										from obs oss
													where oss.voided=0 
													and oss.concept_id=3752 
													and CAST(oss.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
													and CAST(oss.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
													group by oss.person_id) firstquery
										inner join (
													select os.person_id,datediff(CAST(max(os.value_datetime) AS DATE), CAST('#endDate#' AS DATE)) as last_ap
													from obs os
													where concept_id = 3752
													and CAST(os.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
													group by os.person_id
													having last_ap < 0
										) secondquery
										on firstquery.person_id = secondquery.person_id
							) and o.person_id in (
									-- TOUTS
									select distinct(person_id)
									from
									(
										select os.person_id, CAST(max(os.value_datetime) AS DATE) as latest_transferout
										from obs os
										where os.concept_id=2266
										group by os.person_id
										having latest_transferout <= CAST('#endDate#' AS DATE)
									) as TOUTS
							)
							
							
		)

AND Clients_Seen.Id not in 
					(
						select distinct(o.person_id)
						from obs o
						where o.person_id in (
								-- FOLLOW UPS
											select firstquery.person_id
											from
											(
											select oss.person_id, SUBSTRING(MAX(CONCAT(oss.value_datetime, oss.obs_id)), 20) AS observation_id, CAST(max(oss.value_datetime) AS DATE) as latest_followup_obs
											from obs oss
														where oss.voided=0 
														and oss.concept_id=3752 
														and CAST(oss.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
														and CAST(oss.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
														group by oss.person_id) firstquery
											inner join (
														select os.person_id,datediff(CAST(max(os.value_datetime) AS DATE), CAST('#endDate#' AS DATE)) as last_ap
														from obs os
														where concept_id = 3752
														and CAST(os.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
														group by os.person_id
														having last_ap < 0
											) secondquery
											on firstquery.person_id = secondquery.person_id
						)
						and o.person_id in (
								-- Death
											select distinct p.person_id
											from person p
											where dead = 1
											and death_date <= CAST('#endDate#' AS DATE)		
						)
					)

ORDER BY Clients_Seen.Age)

UNION


-- INCLUDE MISSED APPOINTMENTS WITHIN 28 DAYS ACCORDING TO THE NEW PEPFAR GUIDELINE
(SELECT patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age, Gender, age_group, 'MissedWithin28Days' AS 'Program_Status', sort_order
FROM
                (select distinct patient.patient_id AS Id,
									   patient_identifier.identifier AS patientIdentifier,
									   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
									   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
									   person.gender AS Gender,
									   observed_age_group.name AS age_group,
									   observed_age_group.sort_order AS sort_order

                from obs o
						-- PATIENTS WHO HAVE NOT RECEIVED ARV's WITHIN 4 WEEKS (i.e. 28 days) OF THIER LAST MISSED DRUG PICK-UP
						 inner join patient on o.person_id = patient.patient_id
						 and patient.voided = 0 AND o.voided = 0
						 and o.concept_id = 3752
						 and o.obs_id in (
								select os.obs_id
								from obs os
								where os.concept_id=3752
								and os.obs_id in (
									select observation_id
									from
										(select SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.obs_id)), 20) AS observation_id, max(oss.obs_datetime)
										from obs oss 
											inner join person p on oss.person_id=p.person_id and oss.concept_id = 3752 and oss.voided=0
											and oss.value_datetime <= cast('#endDate#' as date)
										group by p.person_id) as latest_followup_obs
								)
								and os.value_datetime < cast('#endDate#' as date)
								and datediff(cast('#endDate#' as date), os.value_datetime) between 0 and 28
						 )
						 
				and o.person_id not in (
							select distinct os.person_id
							from obs os
							where (os.concept_id = 3843 AND os.value_coded = 3841 OR os.value_coded = 3842)
							AND MONTH(os.obs_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
							AND YEAR(os.obs_datetime) = YEAR(CAST('#endDate#' AS DATE))
							)
							
				and o.person_id not in (
							select distinct person_id
							from obs 
							where concept_id = 2249
							AND MONTH(obs_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
							AND YEAR(obs_datetime) = YEAR(CAST('#endDate#' AS DATE))
							)

				and o.person_id not in (
							select distinct(o.person_id)
							from obs o
							where o.person_id in (
							-- TOUTS
									select distinct person_id
											from
											(
												select os.person_id, CAST(max(os.value_datetime) AS DATE) as latest_transferout
												from obs os
												where os.concept_id=2266
												group by os.person_id
												having latest_transferout <= CAST('#endDate#' AS DATE)
											) as TOUTS
										
											 where TOUTS.person_id not in
												 (
													 select oss.person_id
													 from obs oss
													 where concept_id = 3843
													 and CAST(oss.obs_datetime AS DATE) > latest_transferout
													 and CAST(oss.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
												 )
						   
										)
							and o.person_id not in(
										select distinct os.person_id
										from obs os
										where (os.concept_id = 3843 AND os.value_coded = 3841 OR os.value_coded = 3842)
										AND MONTH(os.obs_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
										AND YEAR(os.obs_datetime) = YEAR(CAST('#endDate#' AS DATE))
							)
										)					

						 and o.person_id not in (
									select person_id 
									from person 
									where death_date <= cast('#endDate#' as date)
									and dead = 1
						 )
						 
						 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
						 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
						 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1						 
						 INNER JOIN reporting_age_group AS observed_age_group ON
						 CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
						 AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
                   WHERE 	observed_age_group.report_group_name = 'Modified_Ages'
				   and o.person_id not in (
							-- HAVE TO FIND A BETTER SOLUTION FOR THIS INNER QUERY (STORED PROC OR STORED FUNCTION)
						    select patient.patient_id
										from obs os
												-- CAME IN PREVIOUS 1 MONTH AND WAS GIVEN (2, 3, 4, 5, 6 MONHTS SUPPLY OF DRUGS)
												 INNER JOIN patient ON os.person_id = patient.patient_id
												  AND MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH)) and YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH))
												  AND patient.voided = 0 AND os.voided = 0 
												  AND (os.concept_id = 4174 and (os.value_coded = 4176 or os.value_coded = 4177 or os.value_coded = 4245 or os.value_coded = 4246 or os.value_coded = 4247)))
						    AND 
							o.person_id not in (
							select patient.patient_id
											from obs os
											-- CAME IN PREVIOUS 2 MONTHS AND WAS GIVEN (3, 4, 5, 6 MONHTS SUPPLY OF DRUGS)
											 INNER JOIN patient ON os.person_id = patient.patient_id 
												 AND MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH)) 
												 AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH)) 
												 AND patient.voided = 0 AND os.voided = 0
												 AND os.concept_id = 4174 and (os.value_coded = 4177 or os.value_coded = 4245 or os.value_coded = 4246 or os.value_coded = 4247))

						    AND
							o.person_id not in (						  
							select patient.patient_id
											from obs os
											-- CAME IN PREVIOUS 3 MONTHS AND WAS GIVEN (4, 5, 6 MONHTS SUPPLY OF DRUGS)
											 INNER JOIN patient ON os.person_id = patient.patient_id 
												 AND MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH)) 
												 AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH)) 
												 AND patient.voided = 0 AND os.voided = 0 
												 AND os.concept_id = 4174 and (os.value_coded = 4245 or os.value_coded = 4246 or os.value_coded = 4247))

							AND
							o.person_id not in (
							select patient.patient_id

											from obs os
											-- CAME IN PREVIOUS 4 MONTHS AND WAS GIVEN (5, 6 MONHTS SUPPLY OF DRUGS)
											 INNER JOIN patient ON os.person_id = patient.patient_id 
												 AND MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -4 MONTH)) 
												 AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -4 MONTH)) 
												 AND patient.voided = 0 AND os.voided = 0 
												 AND os.concept_id = 4174 and (os.value_coded = 4246 or os.value_coded = 4247))
							AND
							o.person_id not in (
							select patient.patient_id

											from obs os
											-- CAME IN PREVIOUS 5 MONTHS AND WAS GIVEN (6 MONHTS SUPPLY OF DRUGS)
											 INNER JOIN patient ON os.person_id = patient.patient_id 
												 AND MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -5 MONTH)) 
												 AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -5 MONTH)) 
												 AND patient.voided = 0 AND os.voided = 0 
												 AND os.concept_id = 4174 and os.value_coded = 4247)
									
							AND
							o.person_id not in (
							select patient.patient_id
											from obs o
											 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH)) 
												 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH)) 
												 AND patient.voided = 0 AND o.voided = 0 
												 AND o.concept_id = 4174 and o.value_coded = 4175
												 AND o.person_id in (
													select distinct os.person_id from obs os
													where 
														MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH)) 
														AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH))
														AND os.concept_id = 3752 AND DATEDIFF(os.value_datetime, CAST('#endDate#' AS DATE)) BETWEEN 0 AND 28			
											))
							AND
							o.person_id not in (
											select patient.patient_id
											from obs o
											 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH)) 
												 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH)) 
												 AND patient.voided = 0 AND o.voided = 0 
												 AND o.concept_id = 4174 and o.value_coded = 4176
												 AND o.person_id in (
													select distinct os.person_id 
													from obs os
													where 
														MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH)) 
														AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH))
														AND os.concept_id = 3752 AND DATEDIFF(os.value_datetime, CAST('#endDate#' AS DATE)) BETWEEN 0 AND 28
															
											))
							AND
							o.person_id not in (
							select distinct patient.patient_id AS Id
											from obs o
											 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH)) 
												 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH)) 
												 AND patient.voided = 0 AND o.voided = 0 
												 AND o.concept_id = 4174 and o.value_coded = 4177
												 AND o.person_id in (
													select distinct os.person_id from obs os
													where 
														MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH)) 
														AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH))
														AND os.concept_id = 3752 AND DATEDIFF(os.value_datetime, CAST('#endDate#' AS DATE)) BETWEEN 0 AND 28
											))
							AND
							o.person_id not in (
							select distinct patient.patient_id
											from obs o
											 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -4 MONTH)) 
												 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -4 MONTH)) 
												 AND patient.voided = 0 AND o.voided = 0 
												 AND o.concept_id = 4174 and o.value_coded = 4245
												 AND o.person_id in (
													select distinct os.person_id from obs os
													where 
														MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -4 MONTH)) 
														AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -4 MONTH))
														AND os.concept_id = 3752 AND DATEDIFF(os.value_datetime, CAST('#endDate#' AS DATE)) BETWEEN 0 AND 28
															
											))
							AND
							o.person_id not in (
							select distinct patient.patient_id AS Id
											from obs o
											 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -5 MONTH)) 
												 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -5 MONTH)) 
												 AND patient.voided = 0 AND o.voided = 0 
												 AND o.concept_id = 4174 and o.value_coded = 4246
												 AND o.person_id in (
													select distinct os.person_id from obs os
													where 
														MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -5 MONTH)) 
														AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -5 MONTH))
														AND os.concept_id = 3752 AND DATEDIFF(os.value_datetime, CAST('#endDate#' AS DATE)) BETWEEN 0 AND 28
															
											))
							AND
							o.person_id not in (
							select distinct patient.patient_id
											from obs o
											 INNER JOIN patient ON o.person_id = patient.patient_id
												 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -6 MONTH)) 
												 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -6 MONTH)) 
												 AND patient.voided = 0 AND o.voided = 0 
												 AND o.concept_id = 4174 and o.value_coded = 4247
												 AND o.person_id in (
													select distinct os.person_id from obs os
													where 
														MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -6 MONTH)) 
														AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -6 MONTH))
														AND os.concept_id = 3752 AND DATEDIFF(os.value_datetime, CAST('#endDate#' AS DATE)) BETWEEN 0 AND 28
											))
				   ) AS TwentyEightDayDefaulters
				   order by 3)
				   
		   

UNION

(SELECT patientIdentifier AS "Patient Identifier", patientName AS "Patient Name", Age, Gender, age_group, 'Seen_Prev_Months' AS 'Program_Status', sort_order
FROM (
(select distinct patient.patient_id AS Id,
                                   patient_identifier.identifier AS patientIdentifier,
                                   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
                                   floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
                                   person.gender AS Gender,
                                   observed_age_group.name AS age_group,
								   observed_age_group.sort_order AS sort_order

        from obs o
				-- CAME IN PREVIOUS 1 MONTH AND WAS GIVEN (2, 3, 4, 5, 6 MONHTS SUPPLY OF DRUGS)
                 INNER JOIN patient ON o.person_id = patient.patient_id 
				  AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH)) and YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH)) AND patient.voided = 0 AND o.voided = 0 
				  AND (o.concept_id = 4174 and (o.value_coded = 4176 or o.value_coded = 4177 or o.value_coded = 4245 or o.value_coded = 4246 or o.value_coded = 4247))
                 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
				 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
				 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
                 INNER JOIN reporting_age_group AS observed_age_group ON
						  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
						  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
           WHERE observed_age_group.report_group_name = 'Modified_Ages'
		   and o.person_id not in (
						select distinct(person_id)
						from
								(
								select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
												from obs os
												where os.concept_id=3843
												and os.obs_datetime <= CAST('#endDate#' AS DATE)
												group by os.person_id
												
								) as visit
						where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
						AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
						and latest_visit > CAST(o.obs_datetime AS DATE) 
						and latest_visit <= CAST('#endDate#' AS DATE)
					))

UNION

(select distinct patient.patient_id AS Id,
                                   patient_identifier.identifier AS patientIdentifier,
                                   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
                                   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
                                   person.gender AS Gender,
                                   observed_age_group.name AS age_group,
								   observed_age_group.sort_order AS sort_order

                from obs o
				-- CAME IN PREVIOUS 2 MONTHS AND WAS GIVEN (3, 4, 5, 6 MONHTS SUPPLY OF DRUGS)
                 INNER JOIN patient ON o.person_id = patient.patient_id 
					 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH)) 
					 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH)) 
					 AND patient.voided = 0 AND o.voided = 0 
					 AND o.concept_id = 4174 and (o.value_coded = 4177 or o.value_coded = 4245 or o.value_coded = 4246 or o.value_coded = 4247)
					 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
					 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
					 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
					 INNER JOIN reporting_age_group AS observed_age_group ON
							  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
							  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
           WHERE observed_age_group.report_group_name = 'Modified_Ages'
		   		   and o.person_id not in (
						select distinct(person_id)
						from
								(
								select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
												from obs os
												where os.concept_id=3843
												and os.obs_datetime <= CAST('#endDate#' AS DATE)
												group by os.person_id
												
								) as visit
						where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
						AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
						and latest_visit > CAST(o.obs_datetime AS DATE) 
						and latest_visit <= CAST('#endDate#' AS DATE)
					))
	   
UNION

(select distinct patient.patient_id AS Id,
                                   patient_identifier.identifier AS patientIdentifier,
                                   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
                                   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
                                   person.gender AS Gender,
                                   observed_age_group.name AS age_group,
								   observed_age_group.sort_order AS sort_order

                from obs o
				-- CAME IN PREVIOUS 3 MONTHS AND WAS GIVEN (4, 5, 6 MONHTS SUPPLY OF DRUGS)
                 INNER JOIN patient ON o.person_id = patient.patient_id 
					 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH)) 
					 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH)) 
					 AND patient.voided = 0 AND o.voided = 0 
					 AND o.concept_id = 4174 and (o.value_coded = 4245 or o.value_coded = 4246 or o.value_coded = 4247)
					 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0			 
					 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
					 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
					 INNER JOIN reporting_age_group AS observed_age_group ON
							  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
							  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
           WHERE observed_age_group.report_group_name = 'Modified_Ages'
		   		   and o.person_id not in (
						select distinct(person_id)
						from
								(
								select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
												from obs os
												where os.concept_id=3843
												and os.obs_datetime <= CAST('#endDate#' AS DATE)
												group by os.person_id
												
								) as visit
						where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
						AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
						and latest_visit > CAST(o.obs_datetime AS DATE) 
						and latest_visit <= CAST('#endDate#' AS DATE)
					))

UNION

(select distinct patient.patient_id AS Id,
                                   patient_identifier.identifier AS patientIdentifier,
                                   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
                                   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
                                   person.gender AS Gender,
                                   observed_age_group.name AS age_group,
								   observed_age_group.sort_order AS sort_order

                from obs o
				-- CAME IN PREVIOUS 4 MONTHS AND WAS GIVEN (5, 6 MONHTS SUPPLY OF DRUGS)
                 INNER JOIN patient ON o.person_id = patient.patient_id 
					 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -4 MONTH)) 
					 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -4 MONTH)) 
					 AND patient.voided = 0 AND o.voided = 0 
					 AND o.concept_id = 4174 and (o.value_coded = 4246 or o.value_coded = 4247)
					 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
					 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
					 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
					 INNER JOIN reporting_age_group AS observed_age_group ON
							  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
							  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
           WHERE observed_age_group.report_group_name = 'Modified_Ages'
		   		   and o.person_id not in (
						select distinct(person_id)
						from
								(
								select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
												from obs os
												where os.concept_id=3843
												and os.obs_datetime <= CAST('#endDate#' AS DATE)
												group by os.person_id
												
								) as visit
						where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
						AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
						and latest_visit > CAST(o.obs_datetime AS DATE) 
						and latest_visit <= CAST('#endDate#' AS DATE)
					))



UNION

(select distinct patient.patient_id AS Id,
                                   patient_identifier.identifier AS patientIdentifier,
                                   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
                                   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
                                   person.gender AS Gender,
                                   observed_age_group.name AS age_group,
								   observed_age_group.sort_order AS sort_order

                from obs o
				-- CAME IN PREVIOUS 5 MONTHS AND WAS GIVEN (6 MONHTS SUPPLY OF DRUGS)
                 INNER JOIN patient ON o.person_id = patient.patient_id 
					 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -5 MONTH)) 
					 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -5 MONTH)) 
					 AND patient.voided = 0 AND o.voided = 0 
					 AND o.concept_id = 4174 and o.value_coded = 4247
					 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
					 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
					 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
					 INNER JOIN reporting_age_group AS observed_age_group ON
							  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
							  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
           WHERE observed_age_group.report_group_name = 'Modified_Ages'
		   		   and o.person_id not in (
						select distinct(person_id)
						from
								(
								select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
												from obs os
												where os.concept_id=3843
												and os.obs_datetime <= CAST('#endDate#' AS DATE)
												group by os.person_id
												
								) as visit
						where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
						AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
						and latest_visit > CAST(o.obs_datetime AS DATE) 
						and latest_visit <= CAST('#endDate#' AS DATE)
					))
		

UNION

(select distinct patient.patient_id AS Id,
                                   patient_identifier.identifier AS patientIdentifier,
                                   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
                                   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
                                   person.gender AS Gender,
                                   observed_age_group.name AS age_group,
								   observed_age_group.sort_order AS sort_order

                from obs o
                 INNER JOIN patient ON o.person_id = patient.patient_id
					 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH)) 
					 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH)) 
					 AND patient.voided = 0 AND o.voided = 0 
					 AND o.concept_id = 4174 and o.value_coded = 4175
					 AND o.person_id in (
						select distinct os.person_id from obs os
						where 
							MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH)) 
							AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -1 MONTH))
							AND os.concept_id = 3752 AND DATEDIFF(os.value_datetime, CAST('#endDate#' AS DATE)) BETWEEN 0 AND 28	
					 )
					 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
					 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
					 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
					 INNER JOIN reporting_age_group AS observed_age_group ON
							  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
							  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
           WHERE observed_age_group.report_group_name = 'Modified_Ages'
		   		   and o.person_id not in (
						select distinct(person_id)
						from
								(
								select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
												from obs os
												where os.concept_id=3843
												and os.obs_datetime <= CAST('#endDate#' AS DATE)
												group by os.person_id
												
								) as visit
						where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
						AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
						and latest_visit > CAST(o.obs_datetime AS DATE) 
						and latest_visit <= CAST('#endDate#' AS DATE)
					))


UNION

(select distinct patient.patient_id AS Id,
                                   patient_identifier.identifier AS patientIdentifier,
                                   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
                                   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
                                   person.gender AS Gender,
                                   observed_age_group.name AS age_group,
								   observed_age_group.sort_order AS sort_order

                from obs o
                 INNER JOIN patient ON o.person_id = patient.patient_id
					 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH)) 
					 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH)) 
					 AND patient.voided = 0 AND o.voided = 0 
					 AND o.concept_id = 4174 and o.value_coded = 4176
					 AND o.person_id in (
						select distinct os.person_id from obs os
						where 
							MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH)) 
							AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -2 MONTH))
							AND os.concept_id = 3752 AND DATEDIFF(os.value_datetime, CAST('#endDate#' AS DATE)) BETWEEN 0 AND 28
								
					 )
					 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
					 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
					 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
					 INNER JOIN reporting_age_group AS observed_age_group ON
							  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
							  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
           WHERE observed_age_group.report_group_name = 'Modified_Ages'
		   		   and o.person_id not in (
						select distinct(person_id)
						from
								(
								select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
												from obs os
												where os.concept_id=3843
												and os.obs_datetime <= CAST('#endDate#' AS DATE)
												group by os.person_id
												
								) as visit
						where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
						AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
						and latest_visit > CAST(o.obs_datetime AS DATE) 
						and latest_visit <= CAST('#endDate#' AS DATE)
					))
		   
UNION

(select distinct patient.patient_id AS Id,
                                   patient_identifier.identifier AS patientIdentifier,
                                   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
                                   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
                                   person.gender AS Gender,
                                   observed_age_group.name AS age_group,
								   observed_age_group.sort_order AS sort_order

                from obs o
                 INNER JOIN patient ON o.person_id = patient.patient_id
					 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH)) 
					 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH)) 
					 AND patient.voided = 0 AND o.voided = 0 
					 AND o.concept_id = 4174 and o.value_coded = 4177
					 AND o.person_id in (
						select distinct os.person_id from obs os
						where 
							MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH)) 
							AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -3 MONTH))
							AND os.concept_id = 3752 AND DATEDIFF(os.value_datetime, CAST('#endDate#' AS DATE)) BETWEEN 0 AND 28
								
					 )
					 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
					 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
					 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
					 INNER JOIN reporting_age_group AS observed_age_group ON
							  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
							  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
           WHERE observed_age_group.report_group_name = 'Modified_Ages'
		   		   and o.person_id not in (
						select distinct(person_id)
						from
								(
								select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
												from obs os
												where os.concept_id=3843
												and os.obs_datetime <= CAST('#endDate#' AS DATE)
												group by os.person_id
												
								) as visit
						where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
						AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
						and latest_visit > CAST(o.obs_datetime AS DATE) 
						and latest_visit <= CAST('#endDate#' AS DATE)
					))
		   
UNION

(select distinct patient.patient_id AS Id,
                                   patient_identifier.identifier AS patientIdentifier,
                                   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
                                   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
                                   person.gender AS Gender,
                                   observed_age_group.name AS age_group,
								   observed_age_group.sort_order AS sort_order

                from obs o
                 INNER JOIN patient ON o.person_id = patient.patient_id
					 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -4 MONTH)) 
					 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -4 MONTH)) 
					 AND patient.voided = 0 AND o.voided = 0 
					 AND o.concept_id = 4174 and o.value_coded = 4245
					 AND o.person_id in (
						select distinct os.person_id from obs os
						where 
							MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -4 MONTH)) 
							AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -4 MONTH))
							AND os.concept_id = 3752 AND DATEDIFF(os.value_datetime, CAST('#endDate#' AS DATE)) BETWEEN 0 AND 28
								
					 )
					 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
					 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
					 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
					 INNER JOIN reporting_age_group AS observed_age_group ON
							  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
							  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
           WHERE observed_age_group.report_group_name = 'Modified_Ages'
		   		   and o.person_id not in (
						select distinct(person_id)
						from
								(
								select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
												from obs os
												where os.concept_id=3843
												and os.obs_datetime <= CAST('#endDate#' AS DATE)
												group by os.person_id
												
								) as visit
						where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
						AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
						and latest_visit > CAST(o.obs_datetime AS DATE) 
						and latest_visit <= CAST('#endDate#' AS DATE)
					))



UNION

(select distinct patient.patient_id AS Id,
                                   patient_identifier.identifier AS patientIdentifier,
                                   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
                                   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
                                   person.gender AS Gender,
                                   observed_age_group.name AS age_group,
								   observed_age_group.sort_order AS sort_order

                from obs o
                 INNER JOIN patient ON o.person_id = patient.patient_id
					 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -5 MONTH)) 
					 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -5 MONTH)) 
					 AND patient.voided = 0 AND o.voided = 0 
					 AND o.concept_id = 4174 and o.value_coded = 4246
					 AND o.person_id in (
						select distinct os.person_id from obs os
						where 
							MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -5 MONTH)) 
							AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -5 MONTH))
							AND os.concept_id = 3752 AND DATEDIFF(os.value_datetime, CAST('#endDate#' AS DATE)) BETWEEN 0 AND 28	
					 )
					 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
					 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
					 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
					 INNER JOIN reporting_age_group AS observed_age_group ON
							  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
							  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
           WHERE observed_age_group.report_group_name = 'Modified_Ages'
		   		   and o.person_id not in (
						select distinct(person_id)
						from
								(
								select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
												from obs os
												where os.concept_id=3843
												and os.obs_datetime <= CAST('#endDate#' AS DATE)
												group by os.person_id
												
								) as visit
						where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
						AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
						and latest_visit > CAST(o.obs_datetime AS DATE) 
						and latest_visit <= CAST('#endDate#' AS DATE)
					))



UNION

(select distinct patient.patient_id AS Id,
                                   patient_identifier.identifier AS patientIdentifier,
                                   concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
                                   floor(datediff(o.obs_datetime, person.birthdate)/365) AS Age,
                                   person.gender AS Gender,
                                   observed_age_group.name AS age_group,
								   observed_age_group.sort_order AS sort_order

                from obs o
                 INNER JOIN patient ON o.person_id = patient.patient_id
					 AND MONTH(o.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -6 MONTH)) 
					 AND YEAR(o.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -6 MONTH)) 
					 AND patient.voided = 0 AND o.voided = 0 
					 AND o.concept_id = 4174 and o.value_coded = 4247
					 AND o.person_id in (
						select distinct os.person_id from obs os
						where 
							MONTH(os.obs_datetime) = MONTH(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -6 MONTH)) 
							AND YEAR(os.obs_datetime) = YEAR(DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -6 MONTH))
							AND os.concept_id = 3752 AND DATEDIFF(os.value_datetime, CAST('#endDate#' AS DATE)) BETWEEN 0 AND 28
					 )
					 INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0				 
					 INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
					 INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
					 INNER JOIN reporting_age_group AS observed_age_group ON
							  CAST('#endDate#' AS DATE) BETWEEN (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.min_years YEAR), INTERVAL observed_age_group.min_days DAY))
							  AND (DATE_ADD(DATE_ADD(person.birthdate, INTERVAL observed_age_group.max_years YEAR), INTERVAL observed_age_group.max_days DAY))
           WHERE observed_age_group.report_group_name = 'Modified_Ages'	
		   		   and o.person_id not in (
						select distinct(person_id)
						from
								(
								select os.person_id, cast(max(os.obs_datetime) as date) as latest_visit
												from obs os
												where os.concept_id=3843
												and os.obs_datetime <= CAST('#endDate#' AS DATE)
												group by os.person_id
												
								) as visit
						where CAST(o.obs_datetime AS DATE) >= DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
						AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
						and latest_visit > CAST(o.obs_datetime AS DATE) 
						and latest_visit <= CAST('#endDate#' AS DATE)
					))	   
		   
) AS ARTCurrent_PrevMonths
 
WHERE ARTCurrent_PrevMonths.Id not in (
				SELECT os.person_id 
				FROM obs os
				WHERE (os.concept_id = 3843 AND os.value_coded = 3841 OR os.value_coded = 3842)
				AND MONTH(os.obs_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
				AND YEAR(os.obs_datetime) = YEAR(CAST('#endDate#' AS DATE))
										)
and ARTCurrent_PrevMonths.Id not in (
	           select distinct patient.patient_id AS Id
	           from obs oss
	                       -- CLIENTS NEWLY INITIATED ON ART
				INNER JOIN patient ON oss.person_id = patient.patient_id													
				AND (oss.concept_id = 2249 
				AND MONTH(oss.value_datetime) = MONTH(CAST('#endDate#' AS DATE)) 
				AND YEAR(oss.value_datetime) = YEAR(CAST('#endDate#' AS DATE))
				)
				AND patient.voided = 0 AND oss.voided = 0)
AND ARTCurrent_PrevMonths.Id not in (
									select distinct(o.person_id)
									from obs o
									where o.person_id in (
											-- FOLLOW UPS
												select firstquery.person_id
												from
												(
												select oss.person_id, SUBSTRING(MAX(CONCAT(oss.value_datetime, oss.obs_id)), 20) AS observation_id, max(oss.value_datetime) as latest_followup_obs
												from obs oss
															where oss.voided=0 
															and oss.concept_id=3752 
															and oss.obs_datetime <= CAST('#endDate#' AS DATE)
															and oss.obs_datetime > DATE_ADD(CAST('#endDate#' AS DATE), INTERVAL -7 MONTH)
															group by oss.person_id) firstquery
												inner join (
															select os.person_id,datediff(max(os.value_datetime), CAST('#endDate#' AS DATE)) as last_ap
															from obs os
															where concept_id = 3752
															and os.obs_datetime <= CAST('#endDate#' AS DATE)
															group by os.person_id
															having last_ap < 0
												) secondquery
												on firstquery.person_id = secondquery.person_id
									) and o.person_id in (
											-- TOUTS
											select distinct(person_id)
											from
											(
												select os.person_id, max(os.value_datetime) as latest_transferout
												from obs os
												where os.concept_id=2266
												group by os.person_id
												having latest_transferout <= CAST('#endDate#' AS DATE)
											) as TOUTS
									)
		)
AND ARTCurrent_PrevMonths.Id not in (
						-- Death
									select distinct p.person_id
									from person p
									where dead = 1
									and death_date <= CAST('#endDate#' AS DATE)		
										)
order by 3
)

