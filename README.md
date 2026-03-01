# Healthcare Operations Capacity Analytics System HOCAS
This project is an Advanced SQL Data Analysis Case Study focused on Healthcare Performance and Efficiency. It cleans, integrates, and analyzes data using 30+ analytical queries to quantify KPIs like Patient Refusal Rate, Staff Presence, and service-level Morale correlations for operational optimization.

• Problem Statement
	– Hospitals collect large volumes of data related to patients, services, and staff.
	
	– However, raw hospital data often contains:
		▪ Duplicate patient records
		▪ Inconsistent date formats
		▪ Missing satisfaction values
		▪ Disconnected information across patients, services, and staff tables

	– The objective of this project is to use SQL to:
		▪ Clean and standardize patient data
		▪ Analyze hospital service demand and bed capacity
		▪ Evaluate patient satisfaction
		▪ Study staff availability and attendance
		▪ Identify operational inefficiencies such as overcrowding and understaffing

	– This analysis helps hospital management make data-driven decisions for:
		▪ Resource allocation
		▪ Staff planning
		▪ Service performance improvement

• Project Workflow
	– Data Cleaning & Preparation:
		▪ Removed duplicate patient records using DISTINCT
		▪ Converted arrival and departure dates into proper DATE format
		▪ Handled missing satisfaction values by replacing them with 0
		▪ Calculated patient length of stay (stay days)
		▪ Created cleaned production table tbl_patients
	
• Exploratory Analysis
	– Total patients per service
	– Patient age distribution (Children / Adults / Seniors)
	– Minimum & maximum length of stay
	– Overall and service-wise patient satisfaction
	– Monthly and weekly patient demand

• Service Demand & Bed Utilization:
	– Compared:
		▪ Patients requested
		▪ Patients admitted
		▪ Available beds

	– Calculated:
		▪ Bed utilization ratios
		▪ Admission-to-bed ratios
		▪ Demand vs capacity gaps

	– Identified:
		▪ Overcrowded weeks
		▪ Peak demand weeks per service
		▪ Services with high refusal rates
		
• Staff Performance & Attendance
	– Counted staff by role and service
	– Calculated staff attendance percentages
	– Analyzed staff presence during critical weeks
	– Identified:
		▪ Staff with attendance below 70%
		▪ Doctors with lowest attendance
		▪ Most absent staff members

• Advanced SQL Techniques
	– Used:
		▪ JOIN for cross-table analysis
		▪ CTE (WITH clause) for understaffing detection
		▪ WINDOW FUNCTIONS for:
		• Running totals
		• Ranking busiest weeks
		• Ranking staff attendance
		▪ Built business logic using CASE WHEN
	
• Major Insights
	• Service Demand is Uneven
		– Some services consistently receive more patient requests than others.
		– Insight:
			▪ Hospital resources are not evenly utilized.
			▪ High-demand services risk overcrowding while low-demand services may waste capacity.	
			
	• Overcrowding Exists in Certain Weeks
		– Several weeks show:
			▪ patients_request > available_beds
		– Insight:
			▪ This indicates:
				• Bed shortages
				• Higher refusal rates
				• Pressure on staff and infrastructure
				
	•Patient Satisfaction Varies by Service
		– Patient satisfaction differs significantly across services.
		– Insight:
			▪ Operational efficiency and staff availability likely impact patient experience.

	•Staff Attendance Impacts Service Quality
		–Some staff members have attendance below 70%.
		– Insight:
			▪ Low attendance increases workload on remaining staff and may reduce service quality.

	•High Demand ≠ High Satisfaction
		– Some services with high patient load still show low average satisfaction.
		– Insight:
			▪ High workload without proportional staffing leads to reduced patient experience.
			• Understaffed Services Detected
		– Using demand vs staff ratio, certain services were classified as Understaffed.
		– Insight:
			▪ Staff allocation is not aligned with patient demand.

	• Peak Demand Periods Identified
		– Each service has specific peak weeks with maximum patient requests.
		– Insight:
			▪ These periods need:
			• Extra staffing
			• Better bed management
			• Emergency planning