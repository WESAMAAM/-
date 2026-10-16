# Stage 2: Data Cleaning, Transformation, and Normalization

## Overview
This stage focuses entirely on cleaning, standardizing, and restructuring the data within PostgreSQL using DBeaver. Every operation follows a safe and clear process: exploratory inspection, formula testing, executing database updates, and validating the final output. At the conclusion of this stage, the monolithic dataset is decomposed into three properly normalized relational tables.

1. Populating Missing Property Addresses
Some records in the dataset were missing values in the PropertyAddress field. Since properties with the exact same ParcelID share the identical street address, missing values can be retrieved from other transactions sharing the same parcel identifier.

## Exploratory Query and Self Join
To detect matching addresses from duplicate parcel records, a self join was created between rows sharing the same ParcelID but with different UniqueID values:

```sql
SELECT 
    a."UniqueID",
    a."ParcelID",
    a."PropertyAddress" AS PropertyAddress_Null,
    b."PropertyAddress"
FROM all_data a
JOIN all_data b 
    ON a."ParcelID" = b."ParcelID"
    AND a."UniqueID" <> b."UniqueID"
WHERE a."PropertyAddress" IS NULL
```

![images](images/Screenshot%202026-10-12%20185457.png)

## Testing Replacement with COALESCE
Before modifying the table, the COALESCE function was tested to confirm that the address from table b successfully fills the empty space in table a:

```sql
SELECT 
    a."UniqueID",
    a."ParcelID",
    a."PropertyAddress" AS a_PropertyAddress_Null,
    b."PropertyAddress" AS b_PropertyAddress,
    COALESCE(a."PropertyAddress", b."PropertyAddress") AS PropertyAddress
FROM all_data a
JOIN all_data b 
    ON a."ParcelID" = b."ParcelID"
    AND a."UniqueID" <> b."UniqueID"
WHERE a."PropertyAddress" IS NULL
```

![images](images/Screenshot%202026-10-12%20190206.png)

## Applying the Update
An UPDATE statement using the FROM clause was executed to populate all null values across the table:

```sql
UPDATE all_data
SET "PropertyAddress" = b."PropertyAddress"
FROM all_data b
WHERE all_data."ParcelID" = b."ParcelID"
AND all_data."UniqueID" <> b."UniqueID"
AND all_data."PropertyAddress" IS NULL;
```

## Verification
A validation query was run to confirm that no null addresses remained:

```sql
SELECT "PropertyAddress"
FROM all_data
WHERE "PropertyAddress" IS NULL
```

Validation Result: The query returned an empty grid with zero rows, verifying that all missing property addresses were resolved.

![images](images/Screenshot%202026-10-12%20192521.png)

2. Breaking PropertyAddress into Individual Columns
The original PropertyAddress column held composite text combining street address and city name separated by a comma (for example, 1808 FOX CHASE DR, GOODLETTSVILLE).

![images](images/Screenshot%202026-10-12%20193200.png)

## Testing Extraction with SPLIT_PART
The SPLIT_PART function was tested to ensure proper extraction of the street name and city name:

```sql
SELECT
    "PropertyAddress",
    SPLIT_PART("PropertyAddress", ',', 1) AS StreetAddress,
    SPLIT_PART("PropertyAddress", ',', 2) AS CityAddress
FROM all_data;
```

![images](images/Screenshot%202026-10-12%20193814.png)

## Updating Table Structure and Ingesting Values
Two new columns were added to the table. After populating both columns, the original composite column was removed:

```sql
ALTER TABLE all_data
ADD StreetAddress VARCHAR(255);

UPDATE all_data
SET StreetAddress = SPLIT_PART("PropertyAddress", ',', 1);

ALTER TABLE all_data
ADD CityAddress VARCHAR(255);

UPDATE all_data
SET CityAddress = SPLIT_PART("PropertyAddress", ',', 2);

ALTER TABLE all_data
DROP COLUMN "PropertyAddress";
```

Execution Statistics: 56465 rows updated in 0.841 seconds.

## Verification

```sql
SELECT 
    "streetaddress",
    "cityaddress"
FROM all_data
```

Validation Result: The records show clear and distinct street names and city names in their own columns.

![images](images/Screenshot%202026-10-12%20221832.png)

3. Breaking OwnerAddress into Individual Columns
The OwnerAddress column contained three distinct elements separated by commas: street address, city, and state code TN (for example, 203 UTLEY DR, GOODLETTSVILLE, TN).

![images](images/Screenshot%202026-10-13%20164222.png)

## Testing Extraction with SPLIT_PART
The three parts were tested using SPLIT_PART with positions 1, 2, and 3:

```sql
SELECT
    "OwnerAddress",
    SPLIT_PART("OwnerAddress", ',', 1) AS OwnerStreetAddress,
    SPLIT_PART("OwnerAddress", ',', 2) AS OwnerCityAddress,
    SPLIT_PART("OwnerAddress", ',', 3) AS OwnerStateAddress
FROM all_data;
```

## Updating Table Structure and Ingesting Values
Three dedicated columns were created, populated, and the original column was dropped:

```sql
ALTER TABLE all_data
ADD OwnerStreetAddress VARCHAR(255);

UPDATE all_data
SET OwnerStreetAddress = SPLIT_PART("OwnerAddress", ',', 1);

ALTER TABLE all_data
ADD OwnerCityAddress VARCHAR(255);

UPDATE all_data
SET OwnerCityAddress = SPLIT_PART("OwnerAddress", ',', 2);

ALTER TABLE all_data
ADD OwnerStateAddress VARCHAR(255);

UPDATE all_data
SET OwnerStateAddress = SPLIT_PART("OwnerAddress", ',', 3);

ALTER TABLE all_data
DROP COLUMN "OwnerAddress";
```

![images](images/Screenshot%202026-10-13%20170224.png)

## Verification

```sql
SELECT 
    "ownerstreetaddress",
    "ownercityaddress",
    "ownerstateaddress"
FROM all_data
```

Validation Result: The table now stores owner street, city, and state as atomic attributes.

![images](images/Screenshot%202026-10-13%20170320.png)

4. Standardizing SoldAsVacant Field
Initial examination of the SoldAsVacant field showed four different values representing the same two concepts:

```sql
SELECT DISTINCT
    "SoldAsVacant",
    COUNT("SoldAsVacant") AS count
FROM all_data
GROUP BY "SoldAsVacant"
ORDER BY count DESC;
```

Initial Counts:

1- No: 51392 records

2- Yes: 4622 records

3- N: 399 records

4- Y: 52 records

![images](images/Screenshot%202026-10-13%20171235.png)

## Testing Standardization using CASE and CTE
A conditional CASE expression was tested inside a Common Table Expression to ensure correct conversion:

```sql
WITH sav AS
(
    SELECT
        CASE WHEN "SoldAsVacant" = 'Y' THEN 'Yes'
             WHEN "SoldAsVacant" = 'N' THEN 'No'
             ELSE "SoldAsVacant"
        END
    FROM all_data
)
SELECT DISTINCT
    "SoldAsVacant",
    COUNT("SoldAsVacant") AS count
FROM sav
GROUP BY "SoldAsVacant"
ORDER BY count DESC;
```

Expected Output Confirmed:

1- No: 51791 records

2- Yes: 4674 records

![images](images/Screenshot%202026-10-13%20172337.png)

## Applying the Update

```sql
UPDATE all_data
SET "SoldAsVacant" = CASE WHEN "SoldAsVacant" = 'Y' THEN 'Yes'
                          WHEN "SoldAsVacant" = 'N' THEN 'No'
                          ELSE "SoldAsVacant"
                     END;
```

## Verification

```sql
SELECT DISTINCT
    "SoldAsVacant",
    COUNT("SoldAsVacant") AS count
FROM all_data
GROUP BY "SoldAsVacant"
ORDER BY count DESC;
```

Validation Result: The column contains exclusively two uniform values: No (51791) and Yes (4674).

![images](images/Screenshot%202026-10-13%20173137.png)

5. Detecting and Removing Duplicate Records
Duplicate records were identified by examining key shared attributes: ParcelID, SaleDate, LegalReference, and OwnerName.

## Identifying Duplicates using Window Functions
The ROW_NUMBER window function assigned sequential numbers to rows within each partition. Any row number greater than 1 indicated a duplicate:

```sql
SELECT
    ROW_NUMBER() OVER (PARTITION BY "ParcelID",
                                    "SaleDate",
                                    "LegalReference",
                                    "OwnerName"
                        ORDER BY ("UniqueID")) AS row_num,
    *
FROM all_data;
```

![images](images/Screenshot%202026-10-14%20153908.png)

## Filtering Duplicate Records with a CTE

```sql
WITH dd AS
(
    SELECT
        ROW_NUMBER() OVER (PARTITION BY "ParcelID",
                                        "SaleDate",
                                        "LegalReference",
                                        "OwnerName"
                            ORDER BY ("UniqueID")) AS row_num,
        *
    FROM all_data
)
SELECT *
FROM dd
WHERE row_num > 1;
```

Observation: Exactly 104 duplicate rows were detected.

![images](images/Screenshot%202026-10-14%20154139.png)

## Deleting Duplicates in PostgreSQL
While Microsoft SQL Server permits deleting directly through a CTE, PostgreSQL requires targeting records through a subquery referencing the unique identifier:

```sql
DELETE
FROM all_data
WHERE "UniqueID" IN
(
    SELECT "UniqueID"
    FROM
    (
        SELECT "UniqueID",
               ROW_NUMBER() OVER (PARTITION BY "ParcelID",
                                               "SaleDate",
                                               "LegalReference",
                                               "OwnerName"
                                   ORDER BY ("UniqueID")) AS row_num
        FROM all_data
    )
    WHERE row_num > 1
);
```

Execution Statistics: 104 duplicate rows deleted in 1.14 seconds.

![images](images/Screenshot%202026-10-14%20160558.png)

## Verification
Revisiting the duplicate detection CTE returned zero rows, verifying that all redundant records were removed.

![images](images/Screenshot%202026-10-14%20160807.png)

6. Standardizing ParcelID Format
The original ParcelID values contained inconsistent blank spaces and decimal points (for example, 092 06 0 036.00 and 161 06 0A 065.00).

![images](images/Screenshot%202026-10-15%20203954.png)

## Testing and Applying Regular Expression Cleaning
The REGEXP_REPLACE function was applied using the pattern [ .] with the global flag g to remove every period and space:

```sql
SELECT
    REGEXP_REPLACE("ParcelID", '[ \.]', '', 'g') AS ParcelID
FROM all_data;

UPDATE all_data
SET "ParcelID" = REGEXP_REPLACE("ParcelID", '[ \.]', '', 'g');
```

## Verification

```sql
SELECT
    "ParcelID"
FROM all_data
```

Validation Result: All parcel identifiers now appear as consistent alphanumeric strings (such as 093052B02400 and 093061F21000).

![images](images/Screenshot%202026-10-15%20204339.png)

7. Converting Land Area from Acres to Square Meters
The dataset recorded land area in US acres under the Acreage column.

![images](images/Screenshot%202026-10-15%20212109.png)

## Converting and Renaming
To adopt metric units, the values were multiplied by 4046.86 and rounded to two decimal places. The column was subsequently renamed to SquareMeters:

```sql
SELECT 
    ROUND("Acreage" * 4046.86, 2) AS SquareMeters
FROM all_data;

UPDATE all_data
SET "Acreage" = ROUND("Acreage" * 4046.86, 2);

ALTER TABLE all_data
RENAME COLUMN "Acreage" TO "SquareMeters";
```

## Verification

```sql
SELECT
    "SquareMeters"
FROM all_data;
```

Validation Result: The property areas now reflect metric values rounded to two decimal points (such as 3156.55 and 1375.93).

![images](images/Screenshot%202026-10-15%20212912.png)

8. Database Normalization and Final Schema Design
To transform the flat table structure into a relational model, the data was separated into three distinct entities linked by primary and foreign keys.

## Clarifying Column Names
To distinguish property locations from owner mailing addresses, the property address columns were renamed:

```sql
ALTER TABLE all_data
RENAME COLUMN "streetaddress" TO "propertystreetaddress";

ALTER TABLE all_data
RENAME COLUMN "cityaddress" TO "propertycityaddress";
```

## Creating Relational Tables
Three tables were constructed:

OwnerInfo: Contains owner identity and mailing addresses. UniqueID serves as the Primary Key.

PropertyInfo: Contains physical attributes, construction year, square meters, room counts, and property location. References UniqueID as a Foreign Key.

Saleinfo: Contains sales prices, transaction dates, tax districts, and assessment values. References UniqueID as a Foreign Key.

```sql
CREATE TABLE OwnerInfo AS 
SELECT	
	"UniqueID",
	"ParcelID",
	"OwnerName",
	"ownerstreetaddress",
	"ownercityaddress",
	"ownerstateaddress"
FROM all_data;

ALTER TABLE ownerinfo 
ADD PRIMARY KEY ("UniqueID");

CREATE TABLE PropertyInfo AS
SELECT 
	"UniqueID",
	"ParcelID",
	"YearBuilt",
	"SquareMeters",
	"LandUse",
	"propertystreetaddress",
	"propertycityaddress",
	"Bedrooms",
	"FullBath",
	"HalfBath"
FROM all_data;

ALTER TABLE propertyinfo
ADD FOREIGN KEY ("UniqueID") REFERENCES ownerinfo ("UniqueID");

CREATE TABLE Saleinfo AS
SELECT
	"UniqueID",
	"ParcelID",
	"LegalReference",
	"TaxDistrict",
	"SoldAsVacant",
	"SaleDate",
	"LandValue",
	"BuildingValue",
	"TotalValue",
	"SalePrice"
FROM all_data;

ALTER TABLE saleinfo
ADD FOREIGN KEY ("UniqueID") REFERENCES ownerinfo ("UniqueID");
```

## Verifying Normalized Tables
Each new table was queried to ensure data integrity and proper key linkage:

![images](images/Screenshot%202026-10-16%20163955.png)

![images](images/Screenshot%202026-10-15%20215741.png)

![images](images/Screenshot%202026-10-15%20215856.png)

![images](images/Screenshot%202026-10-15%20220009.png)

## Removing the Staging Table
With all data safely stored in the three relational tables, the original staging table was deleted to optimize storage:

```sql
DROP TABLE all_data;
```

Execution Statistics: Staging table dropped in 0.017 seconds. The database navigator now cleanly lists the three normalized tables: ownerinfo, propertyinfo, and saleinfo.

![images](images/Screenshot%202026-10-15%20220530.png)
