SELECT patientIdentifier, patientName, Age, Visit_type, Trimester, Estimated_Date_Delivery, High_Risk_Pregnancy, Syphilis_Screening_Results,
		Syphilis_Treatment_Completed, Haemoglobin, HIV_Status_Known_Before_Visit, Final_HIV_Status, Subsequent_HIV_Test_Results , MUAC, TB_Status,
		Iron, Folate, Blood_Group

FROM
(
select patient.patient_id AS Id,
						patient_identifier.identifier AS patientIdentifier,
						concat(person_name.given_name, ' ', person_name.family_name) AS patientName,
						floor(datediff(CAST('#endDate#' AS DATE), person.birthdate)/365) AS Age,
                                                o.encounter_id,
						case 
							when o.value_coded = 4659 then 'First Visit'
							when o.value_coded = 4660 then 'Subsequent Visit'
						else 'N/A' end as Visit_type
from obs o
    -- ANC Clients
     INNER JOIN patient ON o.person_id = patient.patient_id
	    AND patient.voided = 0 AND o.voided = 0
    INNER JOIN person ON person.person_id = patient.patient_id AND person.voided = 0
	INNER JOIN person_name ON person.person_id = person_name.person_id AND person_name.preferred = 1
    INNER JOIN patient_identifier ON patient_identifier.patient_id = person.person_id AND patient_identifier.identifier_type = 3 AND patient_identifier.preferred=1
	where concept_id =4658
    and o.voided = 0
	And CAST(o.obs_datetime AS DATE) >= CAST('#startDate#' AS DATE)
	AND CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
	order by o.person_id
)AS ANC_Clients

left outer join 

(
	-- Trimester for First visit
 select o.person_id, o.encounter_id,
 case
 when o.value_numeric < 12 then "1st Trimester"
 when o.value_numeric > 11 
 and o.value_numeric < 25 then "2nd Trimetser"
 when o.value_numeric > 24 then "3rd Trimester"
else "N/A"
end AS Trimester
from obs o
where o.concept_id = 2423 and o.voided = 0
and CAST(o.obs_datetime AS DATE) >= CAST('#startDate#' AS DATE)
and CAST(o.obs_datetime AS DATE) <= CAST('#endDate#' AS DATE)
and o.voided = 0
-- Group by o.person_id
) Gestational_Period
on ANC_Clients.encounter_id = Gestational_Period.encounter_id

-- EDD
left outer join
	(
	select B.person_id as Id, B.obs_group_id, cast(B.value_datetime as date) AS Estimated_Date_Delivery, B.encounter_id
        from obs B
        inner join 
        (select person_id, max(obs_datetime), SUBSTRING(MAX(CONCAT(obs_datetime, obs_id)), 20) AS observation_id
        from obs where concept_id = 4296
        and obs_datetime <= cast('#endDate#' as date)
        and voided = 0
        group by person_id) as A
        on A.observation_id = B.obs_group_id
        where concept_id = 4627
        and A.observation_id = B.obs_group_id
        and voided = 0	
        -- group by B.person_id
	)edd_date
	on ANC_Clients.encounter_id = edd_date.encounter_id

left outer join

	(
	-- Syphilis Treatment Completed
		select o.person_id,o.encounter_id, 
                case
		when o.value_coded = 4353 then "No Risk"
		when o.value_coded = 4354 then "Age less than 16 years"
		when o.value_coded = 4355 then "Age more than 40 years"
		when o.value_coded = 4356 then "Previous SB or NND"
		when o.value_coded = 4357 then "History 3 or more consecutive spontaneous miscarriages"
		when o.value_coded = 4358 then "Birth Weight< 2500g"
		when o.value_coded = 4359 then "Birth Weight > 4500g"
		when o.value_coded = 4360 then "Previous Hx of Hypertension/pre-eclampsia/eclampsia"
		when o.value_coded = 4361 then "Isoimmunization Rh(-)"
		when o.value_coded = 1050 then "Renal Disease"
		when o.value_coded = 4362 then "Cardiac Disease"
		when o.value_coded = 1048 then "Diabetes"
		when o.value_coded = 4363 then "Known Substance Abuse"
		when o.value_coded = 4364 then "Pelvic Mass"
		when o.value_coded = 4365 then "Other Medical Problems"
		when o.value_coded = 4366 then "Previous Surgery on Reproductive Tract"
		when o.value_coded = 1033 then "Other Answer"
		else "N/A"
		end AS High_Risk_Pregnancy
		from obs o
		where o.concept_id = 4352 and o.voided = 0
		and o.obs_datetime >= CAST('#startDate#' AS DATE)
		and o.obs_datetime <= CAST('#endDate#'AS DATE)
		Group by o.person_id
		) High_Risk_Preg
		on ANC_Clients.encounter_id = High_Risk_Preg.encounter_id

-- Syphilis_Screening_Results
left outer join
	(
		select o.person_id, o.encounter_id,
			case 
				when latest.Syphilis_Coded = 4306 then 'Reactive'
				when latest.Syphilis_Coded = 4307 then 'Non Reactive'
				when latest.Syphilis_Coded = 4308 then 'Not done'
			else '' end as Syphilis_Screening_Results
		from obs o 
		inner join 
				(
				select oss.person_id, MAX(oss.obs_datetime) as max_observation,
				SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_coded)), 20) as Syphilis_Coded
				from obs oss
				where oss.concept_id = 4305 and oss.voided=0
				and oss.obs_datetime <= cast('#endDate#' as date)
				group by oss.person_id
				)latest 
			on latest.person_id = o.person_id
			where o.concept_id = 4305
			and o.voided = 0
			and  o.obs_datetime = max_observation
	) Syphilis_Screening_Res
on Syphilis_Screening_Res.encounter_id = ANC_Clients.encounter_id

left outer join
	(
	-- Syphilis Treatment Completed
	select o.person_id, o.encounter_id,
			case 
				when latest.treatment_Coded = 2146 then "Yes"
				when latest.treatment_Coded = 2147 then "No"
				when latest.treatment_Coded = 1975 then "Not applicable"
			else 'N/A' end as Syphilis_Treatment_Completed
		from obs o 
		inner join 
				(
				select oss.person_id, MAX(oss.obs_datetime) as max_observation,
				SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_coded)), 20) as treatment_Coded
				from obs oss
				where oss.concept_id = 1732 and oss.voided=0
				and oss.obs_datetime <= cast('#endDate#' as date)
				group by oss.person_id
				)latest 
			on latest.person_id = o.person_id
			where concept_id = 1732
			and  o.obs_datetime = max_observation
			and o.voided = 0
		) Syphilis_Treatment_Comp
		on ANC_Clients.encounter_id = Syphilis_Treatment_Comp.encounter_id

-- ANEMIA HAEMOGLOBIN
left outer join
(select o.person_id, Haemoglobin_Anemia as Haemoglobin, o.encounter_id
from obs o 
inner join 
		(
		 select oss.person_id, MAX(oss.obs_datetime) as max_observation,
		 SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_numeric)), 20) as Haemoglobin_Anemia
		 from obs oss
		 where oss.concept_id = 3204 and oss.voided=0
		 and oss.obs_datetime < cast('#endDate#' as date)
		 group by oss.person_id
		)latest 
	on latest.person_id = o.person_id
	where o.concept_id = 3204
	and o.voided = 0
	and  o.obs_datetime = max_observation	
	)Haemoglobin_Anemia
ON ANC_Clients.encounter_id = Haemoglobin_Anemia.encounter_id
 
-- HIV Status Known Before Visit	
left outer join
(
	select distinct o.person_id as Id, o.encounter_id,
			case 
				when o.value_coded = 1016 then 'Negative'
				when o.value_coded = 1738 then 'Positive'
				when o.value_coded = 1739 then 'Unknown'
			else 'N/A' end as HIV_Status_Known_Before_Visit
		from obs o 
		inner join 
				(
				select oss.person_id, MAX(oss.obs_datetime) as max_observation
				from obs oss
				where oss.concept_id = 4427 and oss.voided=0
				and oss.obs_datetime >= cast('#startDate#' as date)
				and oss.obs_datetime <= cast('#endDate#' as date)
				group by oss.person_id
				)latest 
			on latest.person_id = o.person_id
			where concept_id = 4427
			and o.obs_datetime >= cast('#startDate#' as date)
			and o.obs_datetime <= cast('#endDate#' as date)
			and o.voided = 0
			-- group by o.person_id
			-- and o.obs_datetime = max_observation
	) HIV_Status
	on ANC_Clients.encounter_id = HIV_Status.encounter_id

-- Final HIV Status	
left outer join
(
	select distinct o.person_id as Id, o.encounter_id,
			case 
				when o.value_coded = 1016 then 'Negative'
				when o.value_coded = 1738 then 'Positive'
				when o.value_coded = 4321 then 'Declined'
				when o.value_coded = 1975 then 'N/A'
			else '' end as Final_HIV_Status
		from obs o 
		inner join 
				(
				select oss.person_id, MAX(oss.obs_datetime) as max_observation
				from obs oss
				where oss.concept_id = 1740 and oss.voided=0
				and oss.obs_datetime >= cast('#startDate#' as date)
				and oss.obs_datetime <= cast('#endDate#' as date)
				group by oss.person_id
				)latest 
			on latest.person_id = o.person_id
			where concept_id = 1740
			and o.voided = 0
			-- group by o.person_id
			-- and  o.obs_datetime = max_observation
	) F_HIV_Status
	on F_HIV_Status.encounter_id = ANC_Clients.encounter_id

-- Subsequent HIV Test Results

left outer join

	(
		select distinct o.person_id,o.encounter_id,
                case
		when o.value_coded = 1738 then "Positive"
		when o.value_coded = 1016 then "Negative"
        when o.value_coded = 4321 then "Decline"
		when o.value_coded = 1975 then "Not applicable"
		else ""
		end AS Subsequent_HIV_Test_Results
		from obs o
		where o.concept_id = 4325 and o.voided = 0
		and o.obs_datetime >= CAST('#startDate#' AS DATE)
		and o.obs_datetime <= CAST('#endDate#'AS DATE)
		Group by o.person_id
		) Subsequent_HIV_Status
		on ANC_Clients.encounter_id = Subsequent_HIV_Status.encounter_id

-- MUAC
left outer join
(select distinct o.person_id, muac as MUAC, o.encounter_id
from obs o 
inner join 
		(
		 select oss.person_id, MAX(oss.obs_datetime) as max_observation,
		 SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.value_numeric)), 20) as muac
		 from obs oss
		 where oss.concept_id = 2086 and oss.voided=0
		 and oss.obs_datetime < cast('#endDate#' as date)
		 group by oss.person_id
		)latest 
	on latest.person_id = o.person_id
	where concept_id = 2086
	and o.voided = 0
	and  o.obs_datetime = max_observation	
	)muac
ON ANC_Clients.encounter_id = muac.encounter_id


-- TB STATUS
left outer join

(select
       distinct o.person_id,o.encounter_id,
       case
           when value_coded = 3709 then "No Signs"
           when value_coded = 1876 then "TB Suspect"
		   when value_coded = 3639 then "On TB Treatment"
           else ""
       end AS TB_Status
from obs o
inner join
		(
		 select oss.person_id, MAX(oss.obs_datetime) as max_observation,
		 SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.obs_id)), 20) as observation_id
		 from obs oss
		 where oss.concept_id = 3710 and oss.voided=0
		 and cast(oss.obs_datetime as date) <= cast('#endDate#' as date)
		 group by oss.person_id
		)latest
	on latest.person_id = o.person_id
	where concept_id = 3710
	and o.voided = 0
	and  o.obs_datetime = max_observation
	) TBStatus
ON ANC_Clients.encounter_id = TBStatus.encounter_id

-- Iron
left outer join

(select distinct
       o.person_id,o.encounter_id,
       case
           when o.value_coded = 4668 then "Prophylaxis"
           when o.value_coded = 1067 then "On Treatment"
		   when o.value_coded = 4298 then "Not Given"
           else ""
       end AS Iron
from obs o
inner join
		(
		 select oss.person_id, MAX(oss.obs_datetime) as max_observation,
		 SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.obs_id)), 20) as observation_id
		 from obs oss
		 where oss.concept_id = 4299 and oss.voided=0
		and cast(oss.obs_datetime as date) <= cast('#endDate#' as date)
		 group by oss.person_id
		)latest
	on latest.person_id = o.person_id
	where o.concept_id = 	4299
	and o.voided = 0
	and  o.obs_datetime = max_observation
	) Iron
ON ANC_Clients.encounter_id = Iron.encounter_id

-- Folate

left outer join

(select distinct
       o.person_id, o.encounter_id,
       case
           when o.value_coded = 4668 then "Prophylaxis"
           when o.value_coded = 1067 then "On Treatment"
		   when o.value_coded = 4298 then "Not Given"
           else ""
       end AS Folate
from obs o
inner join
		(
		 select oss.person_id, MAX(oss.obs_datetime) as max_observation,
		 SUBSTRING(MAX(CONCAT(oss.obs_datetime, oss.obs_id)), 20) as observation_id
		 from obs oss
		 where oss.concept_id = 4300 and oss.voided=0
		and cast(oss.obs_datetime as date) <= cast('#endDate#' as date)
		 group by oss.person_id
		)latest
	on latest.person_id = o.person_id
	where o.concept_id = 	4300
	and o.voided = 0
	and o.obs_datetime = max_observation
	) Folate
ON ANC_Clients.encounter_id = Folate.encounter_id


left outer join 
	(
	-- Blood Group
		select distinct o.person_id, o.encounter_id,
                case
		when o.value_coded = 4309 then "Blood Group, A+"
		when o.value_coded = 4310 then "Blood Group, A-"
		when o.value_coded = 4311 then "Blood Group, B+"
		when o.value_coded = 4312 then "Blood Group, B-"
		when o.value_coded = 4313 then "Blood Group, O+"
		when o.value_coded = 4314 then "Blood Group, O-"
		when o.value_coded = 4315 then "Blood Group, AB+"
		when o.value_coded = 4316 then "Blood Group, AB-"
		else "N/A"
		end AS Blood_Group
		from obs o
		where o.concept_id = 1179 and o.voided = 0
		and o.obs_datetime >= CAST('#startDate#' AS DATE)
    	and o.obs_datetime <= CAST('#endDate#'AS DATE)
		Group by o.person_id
	) Blood_Group_Status
		on ANC_Clients.encounter_id = Blood_Group_Status.encounter_id
order by 2