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


# Count tbl_patients by service
SELECT service, COUNT(*) AS total_patients
FROM tbl_patients
GROUP BY service;

# Find minimum and maximum ages
SELECT MIN(age) AS youngest, MAX(age) AS oldest
FROM tbl_patients;

# Service-wise average age
SELECT service, AVG(age) AS avg_age
FROM tbl_patients
GROUP BY service;

# Weeks where bed capacity < patient requests
SELECT *
FROM tbl_services_weekly
WHERE patients_request > available_beds;

# tbl_staff count by role
SELECT role, COUNT(*) AS total_staff
FROM tbl_staff
GROUP BY role;
# Distinct services offered
SELECT DISTINCT service
FROM tbl_staff;

# tbl_staff attendance summary
SELECT present, COUNT(*) AS count_days
FROM tbl_staff_schedule
GROUP BY present;

# Weeks with 100% attendance for a tbl_staff member
SELECT week
FROM tbl_staff_schedule
WHERE staff_id = 'STF-5ca26577' AND present = 1;

# Longest patient stay
SELECT name, DATEDIFF(departure_date, arrival_date) AS length_of_stay
FROM tbl_patients
ORDER BY length_of_stay DESC
LIMIT 1;

# Satisfaction score distribution
SELECT satisfaction,
       COUNT(*) AS total_patients
FROM tbl_patients
GROUP BY satisfaction;

# Weekly bed availability summary
SELECT week, service, available_beds
FROM tbl_services_weekly
ORDER BY available_beds ASC;

# tbl_patients linked with tbl_staff providing same service
SELECT p.name AS patient, p.service, s.staff_name, s.role
FROM tbl_patients p
JOIN tbl_staff s ON p.service = s.service;

# tbl_staff attendance count
SELECT sc.week, sc.service,
       COUNT(CASE WHEN sc.present = 1 THEN 1 END) AS present_staff
FROM tbl_staff_schedule sc
GROUP BY sc.week, sc.service;

# Weekly tbl_staff attendance per service
SELECT sc.week, sc.service,
       COUNT(CASE WHEN sc.present = 1 THEN 1 END) AS present_staff
FROM tbl_staff_schedule sc
GROUP BY sc.week, sc.service;

# Average patient satisfaction by tbl_staff service
SELECT s.service, AVG(p.satisfaction) AS avg_satisfaction
FROM tbl_staff s
JOIN tbl_patients p USING (service)
GROUP BY s.service;

# Service demand vs number of tbl_staff
SELECT sw.service,
       SUM(sw.patients_request) AS total_requests,
       COUNT(s.staff_id) AS total_staff
FROM tbl_services_weekly sw
JOIN tbl_staff s USING (service)
GROUP BY sw.service;

# tbl_patients request per bed ratio
SELECT week, service,
       (patients_request / available_beds) AS request_bed_ratio
FROM tbl_services_weekly;

# tbl_staff working the most weeks
SELECT s.staff_name,
       COUNT(sc.week) AS weeks_recorded
FROM tbl_staff s
JOIN tbl_staff_schedule sc USING (staff_id)
GROUP BY s.staff_name
ORDER BY weeks_recorded DESC;

# tbl_staff attendance %
SELECT s.staff_name,
       AVG(sc.present)*100 AS attendance_percentage
FROM tbl_staff s
JOIN tbl_staff_schedule sc USING (staff_id)
GROUP BY s.staff_name;

# Most common patient service
SELECT p.service, COUNT(*) AS count_patients,
       COUNT(s.staff_id) AS available_staff
FROM tbl_patients p
JOIN tbl_staff s USING (service)
GROUP BY p.service
ORDER BY count_patients DESC;

# Find mismatch: services with no tbl_staff
SELECT DISTINCT sw.service
FROM tbl_services_weekly sw
LEFT JOIN tbl_staff s USING (service)
WHERE s.staff_id IS NULL;

# Find mismatch: tbl_staff services with no tbl_patients
SELECT DISTINCT s.service
FROM tbl_staff s
LEFT JOIN tbl_patients p USING (service)
WHERE p.patient_id IS NULL;

# Peak demand week per service
SELECT sw.service, sw.week, sw.patients_request
FROM tbl_services_weekly sw
JOIN (
    SELECT service, MAX(patients_request) AS max_req
    FROM tbl_services_weekly
    GROUP BY service
) x ON sw.service = x.service
   AND sw.patients_request = x.max_req;

# Doctors with lowest attendance
SELECT s.staff_name,
       SUM(sc.present) AS total_days_present
FROM tbl_staff s
JOIN tbl_staff_schedule sc USING (staff_id)
WHERE s.role = 'doctor'
GROUP BY s.staff_name
ORDER BY total_days_present ASC;

# tbl_patients served per tbl_staff (per service)
SELECT p.service,
       COUNT(p.patient_id) / COUNT(DISTINCT s.staff_id) AS patients_per_staff
FROM tbl_patients p
JOIN tbl_staff s USING (service)
GROUP BY p.service;

# Service bed utilization
SELECT service,
       SUM(patients_request) AS total_requests,
       SUM(available_beds) AS total_beds,
       SUM(patients_request) / SUM(available_beds) AS utilization_ratio
FROM tbl_services_weekly
GROUP BY service;

# Window function: running weekly demand
SELECT service, week,
       patients_request,
       SUM(patients_request) OVER(PARTITION BY service ORDER BY week) AS running_total
FROM tbl_services_weekly;

# Ranked tbl_staff by attendance (dense_rank)
SELECT staff_name, total_days,
       DENSE_RANK() OVER (ORDER BY total_days DESC) AS attendance_rank
FROM (
    SELECT s.staff_name,
           SUM(sc.present) AS total_days
    FROM tbl_staff s
    JOIN tbl_staff_schedule sc USING (staff_id)
    GROUP BY s.staff_name
) x;

# Identify understaffed services
WITH staff_counts AS (
    SELECT service, COUNT(*) AS total_staff
    FROM tbl_staff
    GROUP BY service
)
SELECT sw.service, sw.week, sw.patients_request, sc.total_staff,
CASE
    WHEN sw.patients_request > sc.total_staff*5 THEN 'Understaffed'
    ELSE 'Adequately Staffed'
END AS staffing_status
FROM tbl_services_weekly sw
JOIN staff_counts sc USING (service);

# Difference between demand & capacity
SELECT week, service,
       patients_request, available_beds,
       (patients_request - available_beds) AS shortage
FROM tbl_services_weekly;

# overcrowded weeks
WITH crowd AS (
    SELECT week, service,
           patients_request, available_beds,
           patients_request - available_beds AS diff
    FROM tbl_services_weekly
)
SELECT *
FROM crowd
WHERE diff > 0;

# Top 3 busiest weeks per service
SELECT *
FROM (
    SELECT service, week, patients_request,
           DENSE_RANK() OVER(PARTITION BY service ORDER BY patients_request DESC) AS rnk
    FROM tbl_services_weekly
) x
WHERE rnk <= 3;

# Weighted satisfaction by stay length
SELECT name, service, satisfaction,
       DATEDIFF(departure_date, arrival_date) AS stay_days,
       satisfaction * DATEDIFF(departure_date, arrival_date) AS weighted_score
FROM tbl_patients;

# Monthly bed utilization
SELECT month, service,
       SUM(patients_request) AS total_req,
       SUM(available_beds) AS total_beds,
       SUM(patients_request)/SUM(available_beds)*100 AS utilization_percent
FROM tbl_services_weekly
GROUP BY month, service;

# Identify tbl_staff with <70% attendance
SELECT s.staff_name,
       AVG(present)*100 AS attendance_percent
FROM tbl_staff s
JOIN tbl_staff_schedule sc USING (staff_id)
GROUP BY staff_name
HAVING attendance_percent < 70;
