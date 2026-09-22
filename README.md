# E-Commerce Return-to-Origin (RTO) Reduction Analysis Dashboard

An end-to-end data analytics project analyzing **16.5K orders** and **₹15.54M in total GMV** using SSMS and Power BI to diagnose operational delivery failures, uncover root-cause risk drivers, and build an executive dashboard.

## Business Problem

The objective was to analyze transaction patterns, logistics timelines, and customer behavior to address high Return-to-Origin (RTO) rates. The project solved key business questions related to:

- Total GMV (**₹15.54M**) and Total RTO Value (**₹1.98M**) across **1.9K RTO orders**
- Overall RTO Rate baseline (**11.5%**)
- Payment mode vulnerability (COD vs. Prepaid)
- High-risk product categories and sizing-sensitive items
- Regional delivery bottlenecks and geographic hotspots
- Customer risk tiering and repeat failure behavior

## Tools Used

- SQL Server Management Studio (SSMS)
- Power BI & DAX Modeling
- Relational Data Modeling (Star Schema & Cross-Filtering)

## Schema

![E-Commerce RTO Analysis Dashboard](Schema.png)

## Project Workflow

1. Extracted and queried raw transactional data using **SSMS (SQL Server Management Studio)**, joining core operational tables (`orders`, `order_status_timeline`, `delivery_attempts`).
2. Loaded raw tables directly into Power BI, establishing proper relational table relationships and data modeling.
3. Created foundational measures in **DAX** to track operational metrics, including:
   - `Total GMV = SUMX('orders', 'orders'[quantity] * 'orders'[unit_price])`
   - `Total Orders = COUNTROWS(DISTINCT('orders'[order_id]))`
   - `Total RTO Orders = CALCULATE(DISTINCTCOUNT('orders'[order_id]), 'order_status_timeline'[rto_status] = "RTO")`
   - `Total RTO Value = CALCULATE([Total GMV], 'order_status_timeline'[rto_status] = "RTO")`
   - `RTO Rate % = DIVIDE([Total RTO Orders], [Total Orders], 0) * 100`
4. Built an interactive dark-mode **Power BI executive dashboard** incorporating conditional heatmapping, matrix tables, and dynamic slicers by state and month.
5. Translated analytical findings into strategic operational recommendations for logistics and checkout guardrails.

## Dashboard

![E-Commerce RTO Analysis Dashboard](Power%20BI%20Dashboard/Dashboard.png)

## Key Insights

- Analyzed **16.5K total orders** representing **₹15.54M in GMV**, resulting in **₹1.98M in total RTO losses** at an overall RTO rate of **11.5%**.
- **Payment Method Risk:** Cash on Delivery (COD) orders suffered an alarmingly high **18.8% RTO rate**, compared to just **3.1%** for Prepaid and Online payment modes.
- **Product Categories:** High-touch categories exhibited the highest return rates, led by **Women's Ethnic Wear (15.4%)** and **Jewellery & Cosmetics (15.1%)**.
- **Geographic Hotspots:** Delivery failures were heavily concentrated in specific regional logistics hubs, led by **Gwalior (22.0% RTO)** and **Asansol (21.3% RTO)**.
- **Customer Segmentation:** **10.14%** of the customer base fell into the **High-Risk** tier, driving a disproportionate volume of repeat delivery failures.

## Business Recommendations

- **Implement COD Guardrails:** Introduce mandatory partial prepaid deposits or OTP verification at checkout for COD orders exceeding ₹2,500.
- **Audit Logistics SLAs:** Restructure courier contracts and fulfillment workflows in top failure regional hubs like Gwalior and Asansol.
- **Automated Risk Flagging:** Integrate real-time customer risk tiering at checkout to automatically restrict serial returners (>40% return rate) to prepaid options only.

## Skills Demonstrated

- Data Extraction & Querying (SSMS)
- Relational Schema Design (Star Schema)
- Core DAX Measures (`SUMX`, `CALCULATE`, `DIVIDE`)
- Executive Dashboard Design & Data Visualization
- Business Analysis & Risk Mitigation Strategy
