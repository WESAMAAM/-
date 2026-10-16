-- Fixing PropertyAddress NULLS:

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

WHERE a."PropertyAddress" IS NULL;

--UPDATE

UPDATE all_data
	SET "PropertyAddress" = b."PropertyAddress"
FROM all_data b
	WHERE all_data."ParcelID"  = b."ParcelID"
	AND all_data."UniqueID" <> b."UniqueID"
	AND all_data."PropertyAddress" IS NULL;

-- UPDATE VLIIDATION

SELECT 
	"PropertyAddress"
FROM all_data

	WHERE "PropertyAddress" IS NULL;
	
-- Breaking out PropertyAddress to Multible Columns:
	
SELECT
	"PropertyAddress",
	SPLIT_PART("PropertyAddress", ',', 1) AS StreetAddress,
	SPLIT_PART("PropertyAddress", ',', 2) AS CityAddress
FROM all_data;

-- UPDATE

ALTER TABLE all_data
ADD  StreetAddress VARCHAR(255);

UPDATE all_data
SET StreetAddress = SPLIT_PART("PropertyAddress", ',', 1);

ALTER TABLE all_data
ADD  CityAddress VARCHAR(255);

UPDATE all_data
SET CityAddress = SPLIT_PART("PropertyAddress", ',', 2);

ALTER TABLE all_data
DROP COLUMN "PropertyAddress";

-- UPDATE VALIDATION

SELECT 
	"streetaddress",
	"cityaddress"
FROM all_data;

-- Breaking Out OwnerAddress to Multible Columns:

SELECT 
	"OwnerAddress",
	SPLIT_PART("OwnerAddress", ',', 1) AS OwnerStreetAddress,
	SPLIT_PART("OwnerAddress", ',', 2) AS OwnerCityAddress,
	SPLIT_PART("OwnerAddress", ',', 3) AS OwnerStateAddress
FROM all_data;

-- UPDATE

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

-- UPDATE VALIDATION

SELECT
"ownerstreetaddress",
"ownercityaddress",
"ownerstateaddress"
FROM all_data;

-- Standardizing SoldAsVacant:

SELECT DISTINCT
	"SoldAsVacant",
	COUNT("SoldAsVacant") AS count
FROM all_data

GROUP BY "SoldAsVacant"

ORDER BY count DESC;

--

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

-- UPDATE 

UPDATE all_data
SET "SoldAsVacant" = CASE WHEN "SoldAsVacant" = 'Y' THEN 'Yes'
						  WHEN "SoldAsVacant" = 'N' THEN 'No'
		   			      ELSE "SoldAsVacant"
						  END;
						  
-- UPDATE VALIDATION
						  
SELECT DISTINCT
	"SoldAsVacant",
	COUNT("SoldAsVacant") AS count
FROM all_data

GROUP BY "SoldAsVacant"

ORDER BY count DESC;

-- Removing Duplicates:

WITH dd AS 
	(
	SELECT 
		row_number() OVER (PARTITION BY "ParcelID", 
										"SaleDate", 
										"LegalReference", 
										"OwnerName" 
										ORDER BY ("UniqueID")) AS row_num,
		*
	FROM all_data
	)

SELECT * -- You can easly delete duplicates if you say 'DELETE' insted of 'SELECT' here, without '*' if you are using SSMS, in the 'UPDATE' stage
FROM dd

WHERE row_num > 1;

-- UPDATE -- But unfortunally, in DBeaver you cant, you should say the following:

DELETE 
FROM all_data

WHERE "UniqueID" IN 
	(
	SELECT "UniqueID" 
	FROM 
		( SELECT "UniqueID",
				  row_number() OVER (PARTITION BY "ParcelID", 
									 		      "SaleDate", 
										          "LegalReference", 
										          "OwnerName" 
												   ORDER BY ("UniqueID")) AS row_num
    FROM all_data
	)
WHERE row_num > 1;
)

-- UPDATE VALIDATION

WITH dd AS 
	(
	SELECT 
		row_number() OVER (PARTITION BY "ParcelID", 
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

-- Standardizing ParcelID:

SELECT 
	REGEXP_REPLACE("ParcelID", '[ \.]', '', 'g') AS ParcelID
FROM all_data;

-- UPDATE

UPDATE all_data
SET "ParcelID" = REGEXP_REPLACE("ParcelID", '[ \.]', '', 'g');

-- UPDATE VALIDATION

SELECT
	"ParcelID"
FROM all_data;

-- Acreage to SquareMeters

SELECT
	ROUND("Acreage" * 4046.86, 2) AS SquareMeters
FROM all_data;

-- UPDATE

UPDATE all_data
SET "Acreage" = ROUND("Acreage" * 4046.86, 2);

ALTER TABLE all_data
RENAME COLUMN "Acreage" TO "SquareMeters";

-- UPDATE VALIDATION

SELECT 
	"SquareMeters"
FROM all_data;

-- CREATE TABLES:

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

ALTER TABLE all_data
RENAME COLUMN "streetaddress" TO "propertystreetaddress";

ALTER TABLE all_data
RENAME COLUMN "cityaddress" TO "propertycityaddress";

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

-- VALIDATION 

SELECT *
FROM ownerinfo;

SELECT *
FROM propertyinfo;

SELECT *
FROM saleinfo;

-- And finally delete the main table:

DROP TABLE all_data









-- ~WESAM