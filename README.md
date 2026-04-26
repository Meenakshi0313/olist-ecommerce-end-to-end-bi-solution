# 🚀 Olist Marketplace: Strategic Sales & Operational Intelligence Suite


## 📌 Executive Summary

This project delivers a high-fidelity, 5-page Business Intelligence suite designed to optimize the Olist E-Commerce marketplace. By transitioning from standard reporting to **Operational Intelligence**, this suite identifies logistics bottlenecks, seller quality outliers, and product portfolio risks through a modern, SaaS-style dark interface.

---

## 🛠️ Technical Architecture

The foundation of this suite is a high-performance **Star Schema** designed for scalability and DAX efficiency. This structure ensures minimal data redundancy and optimized filter propagation across all five dashboard pages.

1. **Data Modeling (Star Schema)**
   
<details>
<summary>📸 Click here to view the Star Schema Diagram</summary>
![Star Schema Data Model](Olist_Star_Schema_Data_Model.png)
</details>

* **Fact Table:** `v_FactOrderItems` — Stores granular transactional metrics (Price, Freight, Delivery Days).
* **Dimension Tables:** * `v_DimProduct`: Product attributes and categories.
    * `v_DimDate`: Temporal attributes for Time Intelligence.
    * `v_DimSeller`: Geographic and success metrics for platform vendors.
    * `v_DimCustomer`: Demographic and retention data.
* **Optimization:** Strictly utilized **1:Many relationships** to maximize calculation speed and avoid ambiguity in multi-page filtering.


2. **Advanced DAX & Analytical Logic**

This project utilizes complex DAX formulas to move beyond basic aggregation into predictive and descriptive analytics:

* **Monthly Active Customers (MAC):** A dynamic trend line used to measure platform stickiness.
* **SLA Compliance:** Logic calculating the variance between estimated and actual delivery dates to track supply chain reliability.
* **Product Risk Logic:** A custom threshold-based alert system for **Low Rating %**:
    * **Critical (> 20%)**: Muted Coral | **Warning (10-20%)**: Harvest Gold | **Healthy (< 10%)**: Forest Mint.

---

## 🎨 UI/UX Design Philosophy

* **SaaS Interface:** Implemented a unified dark-themed design with customized navigation headers and synchronized slicers for a seamless user experience.
* **Semantic Color Palette:**
    * **Forest Mint (`#66BB6A`)**: Success / Target Achieved.
    * **Harvest Gold**: Caution / Mid-tier Performance.
    * **Muted Coral**: Critical Risk / Action Required.
* **Navigation Hub:** A centralized portal allowing stakeholders to move between different business domains without losing context.

---

## 📊 Analytical Suite Breakdown

<details>
<summary><b>1. Home Page / Navigation Hub (Click to expand)</b></summary>

### 🏠 Navigation Central
The central entry point providing a high-level branding overview and intuitive access to all sub-intelligence modules.
* **Business Case:** Eliminates "Dashboard Fatigue" by providing a clean, intuitive entry point for non-technical users.
* **Key Features:** Interactive grid layout, high-contrast buttons with glow-effects, and a unified SaaS-style brand identity.

![Home Page](Assets/01_Home_Page.png)
</details>

<details>
<summary><b>2. Executive Strategic Suite (Click to expand)</b></summary>

### 📊 "North Star" Metrics & High-Level Growth
* **Business Case:** Provides stakeholders with an immediate pulse on marketplace health, focusing on Revenue, Volume, and Order Quality.
* **Key Features:**
    * **Strategic KPIs:** Real-time tracking of **Total Revenue ($1.11M)** and **Perfect Order Rate (52.60%)**.
    * **Revenue Contribution:** Donut chart breakdown by Price Point (High/Mid/Low Value) to identify volume drivers.
    * **Trend Analysis:** Dual-axis charts comparing Monthly Revenue against Profitability to detect seasonal shifts.

![Executive Suite](Assets/02_Executive_Strategic_Suite.png)
</details>

<details>
<summary><b>3. Logistics & Supply Chain Intelligence (Click to expand)</b></summary>

### 🚚 Operational Efficiency & Fulfillment Reliability
* **Business Case:** Identifies bottlenecks in the "Last Mile" of delivery to reduce customer friction and freight overhead.
* **Key Features:**
    * **SLA Monitoring:** Tracks **SLA Compliance % (93.44%)** and Average Delivery Days (14.02).
    * **Performance Scatter Chart:** Visualizes Freight Cost vs. Delivery Performance to flag expensive/slow routes.
    * **State-Level Analytics:** Identifies specific Brazilian states experiencing the longest logistics delays.

![Logistics Intelligence](Assets/03_Logistics_intelligence.png)
</details>

<details>
<summary><b>4. Ecosystem & Network Dynamics (Click to expand)</b></summary>

### 🌐 Marketplace Health (Sellers & Customers)
* **Business Case:** Monitors the balance between supply (Sellers) and demand (Customers) to ensure platform scalability.
* **Key Features:**
    * **Active Seller Ratio:** Tracks platform engagement with a **31% Active Seller rate**.
    * **Geographic Density:** Bubble map visualizing revenue concentration and identifying under-served regions.
    * **Retention Metrics:** Analysis of **New (93.47%)** vs. **Returning (6.53%)** customer segments.

![Ecosystem Dynamics](Assets/04_Ecosystem_Dynamics.png)
</details>

<details>
<summary><b>5. Product Portfolio Performance (Click to expand)</b></summary>

### 📦 Quality Control & Inventory Intelligence
* **Business Case:** Analyzes the 80/20 rule to find which categories drive value vs. those creating brand risk through poor reviews.
* **Key Features:**
    * **Risk Alert Table:** Custom-formatted table instantly flagging categories with a **Low Rating % above 20%**.
    * **Profitability vs. Satisfaction:** Scatter chart used to isolate "High Risk" categories.
    * **Review Score Distribution:** Histogram showing the volume of 1-5 star ratings across the catalog.

![Product Performance](Assets/05_Product_Performance.png)
</details>

---

## 📈 Key Insights & Business Value

* **Operational Efficiency:** Isolated high-cost logistics routes that were not meeting SLA standards.
* **Growth Strategy:** Identified the **Returning Customer** segment to help marketing teams focus on retention vs. acquisition.
* **Risk Mitigation:** Provided a "High Risk" list of product categories based on poor review scores, allowing for immediate quality control intervention.

---

## 📂 Repository Contents

* 📄 **[View Executive Performance Report (PDF)](Report_and_Dashboard/Olist_E-commerce_Analytics_Dashboard.pdf)**
* 📊 **[Download Power BI Dashboard (.pbix)](Report_and_Dashboard/Olist_E-commerce_Analytics_Dashboard.pbix)**
* 📂 **[View SQL Gold-Layer Transformation Scripts](SQL_Scripts/02_Gold_Reporting_Views.sql)**

---

**Author: Meenakshi Singh | Aspiring Data Analyst**

*Specializing in SQL, Data Modeling, and Business Intelligence.*
