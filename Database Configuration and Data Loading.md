# Database Configuration and Data Loading

## 1. Overview
This first stage involves setting up the database environment, converting the source files, defining the database schema, and verifying that the records are imported properly.

## 2. Environment and Tools
The following tools were used during this stage:
1. Microsoft Excel: Used to view the original dataset and convert the file format.
2. PostgreSQL 18: The relational database management system storing the project data.
3. pgAdmin 4: Administration platform used to create the database and define the tables.
4. DBeaver: SQL client connected to the database to run queries and manage the workflow.

## 3. Data Preparation and Transformation
The original data was provided in an Excel workbook. Because relational databases import flat structured text more efficiently, the file was converted from Excel format to a standard CSV file. This step prepares the data for quick and clean importation into PostgreSQL without encoding issues.

## 4. Database and Table Architecture
A new database named NashvilleHousingData was created in PostgreSQL. Inside the public schema, a main table named all_data was built to store all incoming records.

The table contains 19 specific attributes:
1. UniqueID: Unique numeric identifier for each transaction
2. ParcelID: Parcel identification code
3. LandUse: Property usage category such as Single Family or Residential Condo
4. PropertyAddress: Physical address of the property
5. SaleDate: Date of property sale
6. SalePrice: Recorded sale price
7. LegalReference: Legal document reference number
8. SoldAsVacant: Status showing if the property was vacant at sale time
9. OwnerName: Full name of the property owner
10. OwnerAddress: Mailing or residential address of the owner
11. Acreage: Land area size in acres
12. TaxDistrict: Designated local tax district
13. LandValue: Assessed market value of the land
14. BuildingValue: Assessed value of the building structures
15. TotalValue: Sum of land and building values
16. YearBuilt: Construction year of the property
17. Bedrooms: Total count of bedrooms
18. FullBath: Count of full bathrooms
19. HalfBath: Count of half bathrooms

    [images/pgadmin_table_columns.png]

![Table Columns](images/pgadmin_table_columns.png)

The SQL definition used to create the table structure:

```sql
CREATE TABLE public.all_data
(
    "UniqueID" integer,
    "ParcelID" character varying(50)[],
    "LandUse" character varying(100)[],
    "PropertyAddress" character varying(255)[],
    "SaleDate" date,
    "SalePrice" numeric,
    "LegalReference" character varying(50)[],
    "SoldAsVacant" character varying(10)[],
    "OwnerName" character varying(255)[],
    "OwnerAddress" character varying(255)[],
    "Acreage" numeric,
    "TaxDistrict" character varying(100)[],
    "LandValue" numeric,
    "BuildingValue" numeric,
    "TotalValue" numeric,
    "YearBuilt" integer,
    "Bedrooms" integer,
    "FullBath" integer,
    "HalfBath" integer
);
```

[images/pgadmin_create_table_sql.png]

## 5. Data Ingestion and Verification
After defining the table, the dataset was imported from the CSV file into PostgreSQL.
To ensure the import succeeded and all rows were loaded without corruption, a verification query was executed:

```sql
SELECT *
FROM all_data;
```

The output confirmed that all rows, exceeding 56000 records, were present and mapped correctly to their columns.

[images/Screenshot%202026-10-10%20175333.png]

## 6. DBeaver Connection and Workspace Setup
To provide an efficient querying environment, DBeaver was linked to the PostgreSQL server using localhost on port 5432. The connection to NashvilleHousingData was tested and confirmed. Running the same retrieval query inside DBeaver verified that the client communicates smoothly with the database and is ready for upcoming data cleaning operations.

[images/dbeaver_query_results.png]
