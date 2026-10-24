# Stage 4: Data Visualization, Interactive Dashboarding, and Executive Presentation

## Overview
The final stage transforms the cleaned database and analytical findings into visual business intelligence assets. By connecting PostgreSQL directly to Tableau Desktop, individual worksheets were engineered and combined into an executive dashboard. Finally, the insights and strategic recommendations were compiled into an executive report and recorded presentation delivered via Google Slides.

## 1. Connecting PostgreSQL to Tableau Desktop
To visualize the normalized tables, Tableau Desktop was linked directly to the local PostgreSQL server using the verified connection parameters from DBeaver:

- Server Host: localhost
- Port: 5432
- Database Name: NashvilleHousingData
- Authentication: postgres user credentials

![images](images/Screenshot%202026-10-21%20221430.png)

![images](images/Screenshot%202026-10-21%20221920.png)

## 2. Data Modeling and Extract Configuration in Tableau
Inside the Tableau Data Source environment, a relational data model was constructed to unite the three normalized tables without data duplication:

- Primary Logical Table: saleinfo was placed as the core central table.
-  Relational Links: ownerinfo and propertyinfo were linked to saleinfo through shared Unique ID relationships.
- Extract Mode: The connection was switched from Live to Extract mode to store a local snapshot in memory, ensuring fast rendering for complex calculations and filters.
- Data Integrity Verification: The preview confirmed 52777 cleaned transaction rows across 13 fields in the sales table.

![images](images/Screenshot%202026-10-22%20230807.png)

# 3. Developing Core Worksheets and Visual Components
## 3.1 Key Performance Indicator Cards and Market Proportions
To provide immediate executive context, two headline metric cards and three proportional pie charts were built:

- Median Sale Price Card: Displays the overall median property price of 201000 dollars.
- Median Net Revenue Card: Displays the median profit margin of 29000 dollars per transaction.
- Deals Profitability Ratio: Shows that 74.89 percent of transactions were profitable while 25.11 percent were unprofitable.
- Properties by Price Tier: Validates the statistical quartile segmentation with 49.35 percent in the average tier, 25.05 percent in the high tier, and 25.60 percent in the low tier.
- Vacant Properties Sold: Illustrates that vacant land sales represented only 4.77 percent of total volume compared to 95.23 percent for developed properties.

![images](images/Screenshot%202026-10-23%20004829.png)

![images](images/Screenshot%202026-10-23%20004854.png)

![images](images/Screenshot%202026-10-23%20004709.png)

![images](images/Screenshot%202026-10-23%20004740.png)

![images](images/Screenshot%202026-10-23%20004804.png)

## 3.2 Temporal Trends and Financial Trajectories
Four chronological line charts were created to track financial performance across time:

- Net Income Trend: A monthly trajectory featuring a zero dollar reference line, highlighting the shift from an early low of minus 16 million dollars in 2013 to a record peak of 98 million dollars in mid 2016.
- Average Sale Price Trend: Tracks the monthly median sale price climbing steadily from 147 thousand dollars in early 2013 to 240 thousand dollars in mid 2016.
- Net Income by Property Age: A quarterly breakdown across construction eras, demonstrating how Mid Century and Old homes drove massive returns while Very Modern properties recovered from early losses to become profitable in 2016.
- Net Income by Tax District: A quarterly comparison showing the Urban Services District surging to a 200 million dollar quarterly peak in 2016, far ahead of all other districts.

![images](images/Screenshot%202026-10-23%20002641.png)

![images](images/Screenshot%202026-10-23%20002712.png)

![images](images/Screenshot%202026-10-23%20002745.png)

![images](images/Screenshot%202026-10-23%20002813.png)

## 3.3 Transaction Volume and Land Use Distribution
Two structural charts were engineered to analyze market capacity and buyer preferences:

- Sales Volume versus Total Value: A dual axis chart combining monthly transaction count bars (reaching up to 1800 deals) with a total sales value line (surpassing 550 million dollars).
- Property Volume Distribution by Land Use: A monthly stacked bar chart proving the consistent dominance of Single Family homes and Residential Condos across all seasons.

![images](images/Screenshot%202026-10-23%20002848.png)

![images](images/Screenshot%202026-10-23%20002922.png)

## 4. The Final Integrated Tableau Dashboard
All eleven worksheets were assembled into a cohesive executive dashboard titled Nashville Real Estate Market Performance (2013 to 2016). The layout follows a structured three column visual hierarchy:

- Left Column (Executive Summary and Ratios): Houses the headline KPI cards for Median Sale Price (201000 dollars) and Median Net Revenue (29000 dollars), stacked above the three proportional breakdown charts.
- Center Column (Performance Trajectories): Displays the four primary time series charts aligned vertically to allow direct comparison of net income, deal prices, building age performance, and tax district growth across the same timeline.
- Right Column (Market Volume and Structure): Features the stacked land use volume distribution on top and the dual axis sales volume versus total value chart at the bottom.

<img width="1924" height="1144" alt="NREMP_Dashboard" src="https://github.com/user-attachments/assets/9c1cd478-e80b-48b4-8d5c-2348538af046" />

## 5. Executive Report and Recorded Presentation
To bridge technical analysis with business decision making, a comprehensive executive presentation titled Our Performance In The Past 3 Years (2013 to 2016): An Executive Market Analysis was created in Google Slides and recorded by Wesam Musalli.

- The presentation walks stakeholders through the entire analytical narrative:
- Explaining the root causes behind the 2013 and 2014 revenue deficit (vacant land losses and post 2009 modern property markdowns).
- Disproving the population growth hypothesis using official demographic records.
- Demonstrating how capital cost reductions and single family home demand fueled the 2015 and 2016 profit boom.
- Providing actionable recommendations on summer deal timing, urban district focus, and VIP client outreach.

![images](images/Recording%202026-10-24%20215247.gif)

![Watch the Recorded Executive Presentation Video]()
