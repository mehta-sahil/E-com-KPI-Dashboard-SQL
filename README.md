# E-com KPI Dashboard (SQL)

**KPI definitions, trend analysis, and dashboard-ready SQL queries

This project analyzes Walmart retail sales transaction data using SQL to extract key business insights.  
The focus is on defining **KPIs**, performing **trend analysis**, and generating **dashboard-ready query outputs** that could be integrated into BI tools (e.g., Tableau, PowerBI, Excel).

---

## Dataset
- **Source:** Walmart Sales Data (CSV format)  
- **Rows:** ~1,000+ transaction records  
- **Columns:**
  - `Invoice ID` – transaction identifier  
  - `Branch` – store branch (A, B, C)  
  - `City` – location of the branch  
  - `Customer type` – Member or Normal  
  - `Gender` – Male or Female  
  - `Product line` – product category (e.g., Health and beauty, Electronics)  
  - `Unit price` – price per unit  
  - `Quantity` – number of units purchased  
  - `Tax 5%` – VAT applied  
  - `Total` – invoice amount (including tax)  
  - `Date` – transaction date  
  - `Time` – transaction time  
  - `Payment` – payment method (Cash, Credit card, Ewallet)  
  - `cogs` – cost of goods sold  
  - `gross margin percentage`  
  - `gross income` – profit per transaction  
  - `Rating` – customer satisfaction rating  

---

## Key KPIs Defined
1. **Total Revenue** – sum of `Total`  
2. **Total Units Sold** – sum of `Quantity`  
3. **Average Transaction Value (ATV)** – avg `Total`  
4. **Revenue by Branch** – store-level comparison  
5. **Top Product Lines by Revenue**  
6. **Payment Method Distribution**  
7. **Revenue by Customer Type (Member vs Normal)**  
8. **Gender-based Sales Contribution**  
9. **Gross Profit Analysis**  
10. **Customer Ratings Insights**

---
