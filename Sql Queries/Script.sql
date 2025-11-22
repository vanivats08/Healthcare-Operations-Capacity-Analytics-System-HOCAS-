create database DB_Health;
USE DB_Health;
DESC TBL_PATIENTS;
SELECT * FROM TBL_PATIENTS;
SELECT NAME, AGE, COUNT(*) FROM TBL_PATIENTS GROUP BY 1,2 HAVING COUNT(*) >1;

drop table if exists temp_tbl_patients;
create table temp_tbl_patients as select distinct * from TBL_PATIENTS;

update temp_tbl_patients 
	set 
		arrival_date=str_to_date(arrival_date,'%d-%m-%Y'),
        departure_date=str_to_date(departure_date,'%d-%m-%Y');
        
ALTER TABLE temp_tbl_patients
MODIFY COLUMN arrival_date DATE;

ALTER TABLE temp_tbl_patients
MODIFY COLUMN departure_date DATE;

select * from temp_tbl_patients where satisfaction is null;
update temp_tbl_patients set satisfaction=0 where satisfaction is null;

alter table temp_tbl_patients 
	add column staydays int;
    
update temp_tbl_patients set staydays=datediff(departure_date,arrival_date);

drop table if exists tbl_patients;
alter table temp_tbl_patients rename to tbl_patients;

desc tbl_patients;
desc tbl_services_weekly;
desc tbl_staff;
desc tbl_staff_schedule;

# Total Patients per Service:
SELECT service, COUNT(patient_id) AS total_patients FROM tbl_patients GROUP BY service;

# Overall Patient Satisfaction:
SELECT AVG(satisfaction) AS overall_avg_satisfaction FROM tbl_patients;

# Min/Max Length of Stay:
SELECT MIN(staydays) AS shortest_stay_days, MAX(staydays) AS longest_stay_days FROM tbl_patients;

# Patient Age Distribution:
SELECT CASE WHEN age <= 18 THEN 'Children' WHEN age >= 65 THEN 'Senior' ELSE 'Adult' END AS age_group, COUNT(patient_id) AS total_patients FROM tbl_patients GROUP BY age_group;

# Weekly Bed Utilization:
SELECT week, SUM(available_beds) AS total_available_beds,
	SUM(patients_admitted) AS total_admitted 
	FROM tbl_services_weekly 
    GROUP BY week ORDER BY week;

# Refusal Rate by Service:
SELECT service, SUM(patients_refused) AS total_refused_patients 
	FROM tbl_services_weekly 
    GROUP BY service 
    ORDER BY total_refused_patients DESC;
    
# Event Impact on Staff Morale:
SELECT event, AVG(staff_morale) AS avg_staff_morale 
	FROM tbl_services_weekly 
    WHERE event IN ('flu', 'none') GROUP BY event;

# Staff Count by Role and Service:
SELECT service, role, COUNT(staff_id) AS staff_count 
	FROM tbl_staff
    GROUP BY service, role 
    ORDER BY service, staff_count DESC;
    
# Average Staff Presence:
SELECT (CAST(SUM(present) AS REAL) * 100 / COUNT(week)) AS overall_avg_presence_percentage
	FROM tbl_staff_schedule;
    
# Most Absent Staff Member:
SELECT staff_name, COUNT(staff_id) AS total_absences 
	FROM tbl_staff_schedule 
    WHERE present = 0 
    GROUP BY staff_name 
    ORDER BY total_absences DESC LIMIT 1;

# Month-by-Month Patient Requests
SELECT month, SUM(patients_request) AS total_requests
	FROM tbl_services_weekly
    GROUP BY month
    ORDER BY month;
    
#Age Group Satisfaction:
SELECT AVG(satisfaction) AS avg_satisfaction_seniors
	FROM tbl_patients 
    WHERE age >= 65;

# Patient Load vs. Patient Satisfaction:
SELECT T1.week, T1.service, T1.patients_admitted, 
	AVG(T2.satisfaction) AS avg_satisfaction 
		FROM tbl_services_weekly AS T1 
        INNER JOIN tbl_patients AS T2 
			ON T1.service = T2.service 
		GROUP BY T1.week, T1.service, T1.patients_admitted ORDER BY T1.week;

# High Refusals, high Satisfaction:
SELECT T1.service, SUM(T1.patients_refused) AS total_refused,
	AVG(T2.satisfaction) AS avg_satisfaction 
		FROM tbl_services_weekly AS T1 
        INNER JOIN tbl_patients AS T2 
			ON T1.service = T2.service 
		GROUP BY T1.service 
        HAVING AVG(T2.satisfaction) < 90 
        ORDER BY total_refused DESC;
        
# Staff Presence Rate by Role:
SELECT T1.role, (SUM(T2.present)  * 100 / COUNT(T2.week)) 
	AS overall_presence_percentage 
    FROM tbl_staff AS T1 
    INNER JOIN tbl_staff_schedule AS T2
		ON T1.staff_id = T2.staff_id 
	GROUP BY T1.role 
    ORDER BY overall_presence_percentage DESC;
    

# Staff-to-Patient Ratio by Service:
SELECT T1.service, COUNT(T1.staff_id) AS total_staff, COUNT(T2.patient_id) AS total_patients,
 CAST(COUNT(T1.staff_id) AS REAL) / COUNT(T2.patient_id) AS staff_to_patient_ratio 
	FROM tbl_staff AS T1 
    INNER JOIN tbl_patients AS T2
		ON T1.service = T2.service 
	GROUP BY T1.service
    ORDER BY staff_to_patient_ratio DESC;
    
# Average Staff Morale vs. Patient Satisfaction:
SELECT T1.service, AVG(T1.staff_morale) AS avg_staff_morale, 
AVG(T2.satisfaction) AS avg_patient_satisfaction 
	FROM tbl_services_weekly AS T1 
	INNER JOIN tbl_patients AS T2 
		ON T1.service = T2.service
	GROUP BY T1.service;
    
# Staff Absent During a Critical Week:
SELECT T1.staff_name, T1.service 
	FROM tbl_staff AS T1 
    INNER JOIN tbl_staff_schedule AS T2
		ON T1.staff_id = T2.staff_id
	WHERE T2.week = 52 AND T2.present = 0;
    
# Patient Satisfaction for High-Admission Weeks:
SELECT T1.service, AVG(T2.satisfaction) AS avg_satisfaction_full_admission
	FROM tbl_services_weekly AS T1
    INNER JOIN tbl_patients AS T2 
		ON T1.service = T2.service
	WHERE T1.patients_admitted = T1.patients_request
    GROUP BY T1.service;
    
# Top 5 Admission-to-Bed Ratio:
SELECT service, (CAST(SUM(patients_admitted) AS REAL) / SUM(available_beds)) AS admission_to_bed_ratio 
	FROM tbl_services_weekly
    GROUP BY service 
    ORDER BY admission_to_bed_ratio 
    DESC LIMIT 5;
    
# Staff in Services with Low Morale:
SELECT DISTINCT T1.staff_name, T1.service 
	FROM tbl_staff AS T1 
	INNER JOIN tbl_services_weekly AS T2
		ON T1.service = T2.service 
	GROUP BY T1.staff_name, T1.service 
    HAVING AVG(T2.staff_morale) < 75;
        
# Staff in High-Demand Services:
SELECT DISTINCT T1.staff_name, T1.role, T1.service
	FROM tbl_staff AS T1 
    WHERE T1.service = (
		SELECT service 
			FROM tbl_services_weekly
			GROUP BY service 
			ORDER BY SUM(patients_request) 
				DESC LIMIT 1
		);

# Length of Stay for ICU Patients:
SELECT name, staydays
	FROM tbl_patients
    WHERE service = 'ICU'
    ORDER BY staydays 
    DESC;

# Correlation: Staff Morale vs. Bed Utilization:
SELECT service, week, staff_morale, 
(CAST(patients_admitted AS REAL) / available_beds) AS bed_utilization_rate
	FROM tbl_services_weekly 
    ORDER BY service, week;
    
# Nurse Presence in Surgery:
SELECT SUM(T2.present) AS total_nurse_presence_weeks 
	FROM tbl_staff AS T1 INNER JOIN tbl_staff_schedule AS T2 ON T1.staff_id = T2.staff_id 
    WHERE T1.service = 'surgery' AND T1.role = 'nurse';

