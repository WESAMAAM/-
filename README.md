## 📚 Table of Contents
- [Project Summary](#-project-summary)
- [Database Configuration and Data Loading](#-database-configuration-and-data-loading)
- [Data Cleaning, Transformation, and Normalization](#-stage-2-data-cleaning-transformation-and-normalization)
- [Exploratory Data Analysis, Feature Engineering, and Business Insights](#-stage-3-exploratory-data-analysis-feature-engineering-and-business-insights)
- [Data Visualization, Interactive Dashboarding, and Executive Presentation](#-stage-4-data-visualization-interactive-dashboarding-and-executive-presentation)
- [Repository Structure and Detailed Documentation](#-repository-structure-and-detailed-documentation)

## Project Architecture
![images](images/Gemini_Generated_Image_a5ozv4a5ozv4a5oz.jpg)

## <a id="-project-summary"></a> Project Summary
Data analysis, exploratory analysis, and business intelligence project on over 56,000 housing transactions in Nashville. Raw spreadsheet records were migrated into PostgreSQL, cleaned and normalized into a relational schema using SQL, analyzed with Python to solve key financial questions, and delivered through an interactive Tableau dashboard and executive presentation.

## <a id="-database-configuration-and-data-loading"></a> Database Configuration and Data Loading
**What Was Done:** Converted the raw Excel dataset to CSV, built the `NashvilleHousingData` database in PostgreSQL 18 via pgAdmin 4, defined a 19-column staging table, and connected DBeaver for SQL operations.

**Final Outcome:** Successfully ingested over 56,000 raw records and automatically standardized sale dates into clean date formats upon import.

![images](images/Screenshot%202026-10-10%20175333.png)

## <a id="-stage-2-data-cleaning-transformation-and-normalization"></a> Stage 2: Data Cleaning, Transformation, and Normalization
**What Was Done:** Populated missing property addresses via self-joins, split composite property and owner addresses into atomic street, city, and state columns, standardized `SoldAsVacant` flags, cleaned `ParcelID` strings with regular expressions, converted land area from acres to square meters, removed initial duplicates, and decomposed the flat table into a normalized 3-table relational schema before dropping the staging table.

**Final Outcome:** Transformed a single unorganized 33MB flat table into a clean, lightweight relational database consisting of `ownerinfo`, `propertyinfo`, and `saleinfo` linked by primary and foreign keys.

![images](images/Screenshot%202026-10-15%20215741.png)

![images](images/Screenshot%202026-10-15%20215856.png)

![images](images/Screenshot%202026-10-15%20220009.png)

![images](images/Screenshot%202026-10-16%20163955.png)

## <a id="-stage-3-exploratory-data-analysis-feature-engineering-and-business-insights"></a> Stage 3: Exploratory Data Analysis, Feature Engineering, and Business Insights
**What Was Done:** Purged 4,000 redundant sales transactions, engineered new analytical features (price tiers, net income margins, profitability status, and 6 architectural age eras), built SQL reporting views, and analyzed market trends using Python.

**Final Outcome and Core Discoveries:**
* **Why 2013 and 2014 Had Negative Returns:** Severe losses from vacant land sales (losing $54.5 million in 2014 alone) and newly constructed post-2009 properties (losing nearly $98 million in 2013 and $96 million in 2014).
* **Population Growth Ruled Out:** Official city statistics showed only a 6.5% population growth over 5 years, proving demographic growth was not the main driver of the profit boom.
* **What Drove the 2015 and 2016 Profit Boom:** Lower assessed baseline costs in 2016 combined with surging demand for developed Single Family homes (which generated $487.5 million in net revenue in 2016), confirming that families are the primary buyer persona.
* **Best Time and Location to Close Deals:** Mid-year summer months (May to July) recorded the highest deal prices ($240,000) and peak monthly profit (nearly $100 million in June 2016), while the Urban Services District generated $492 million in 2016 through high transaction volume.

**Operational Deliverable:** Exported a targeted Excel list of the top 16 repeat VIP buyers (owning 10 or more properties) for Public Relations and Sales outreach.

![images](images/Screenshot%202026-10-20%20152841.png)

![images](images/Screenshot%202026-10-20%20153336.png)

## <a id="-stage-4-data-visualization-interactive-dashboarding-and-executive-presentation"></a> Stage 4: Data Visualization, Interactive Dashboarding, and Executive Presentation
**What Was Done:** Connected Tableau Desktop directly to PostgreSQL in Extract mode, linked the 3 relational tables, built 11 specialized worksheets, assembled a 3-column executive dashboard, and recorded a full strategic presentation in Google Slides.

**Final Outcome:** Delivered a production-ready Tableau Dashboard summarizing key metrics ($201,000 median sale price, $29,000 median net revenue, and 74.89% profitable deals ratio) alongside an Executive Market Analysis Presentation prepared by Wesam Musalli.

![images](images/NREMP_Dashboard.gif)

![images](images/Recording%202026-10-24%20215247.gif)

## <a id="-repository-structure-and-detailed-documentation"></a> Repository Structure and Detailed Documentation
- [Stage 1: Environment Setup and Data Ingestion](https://github.com/WESAMAAM/-/blob/main/Database%20Configuration%20and%20Data%20Loading.md)
- [Stage 2: Data Cleaning and Database Normalization](https://github.com/WESAMAAM/-/blob/main/Data%20Cleaning%20and%20Normalization.md)
- [Stage 3: Exploratory Data Analysis and Business Insights](https://github.com/WESAMAAM/-/blob/main/Exploratory%20Data%20Analysis%2C%20Feature%20Engineering%2C%20and%20Business%20Insights.md)
- [Stage 4: Tableau Dashboard and Executive Presentation](https://github.com/WESAMAAM/-/blob/main/Data%20Visualization%2C%20Interactive%20Dashboarding%2C%20and%20Executive%20Presentation.md)
