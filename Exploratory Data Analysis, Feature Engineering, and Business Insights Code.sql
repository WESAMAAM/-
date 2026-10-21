-- Removing remaining duplicates in saleinfo:

SELECT 
	ROW_NUMBER() OVER (PARTITION BY  "SalePrice", 
									 "SaleDate", 
									 "LegalReference" 
									  ORDER BY "UniqueID") AS row_num,
	*
FROM saleinfo;

--

SELECT *
FROM saleinfo
WHERE "LegalReference" = '20160405-0032679';

-- UPDATE

DELETE 
FROM saleinfo 

WHERE "UniqueID" IN 
	(
	SELECT "UniqueID" 
	FROM 
		( SELECT "UniqueID",
				  row_number() OVER (PARTITION BY "SalePrice", 
									 		      "SaleDate", 
										          "LegalReference"
												   ORDER BY ("UniqueID")) AS row_num
    FROM saleinfo
	)
WHERE row_num > 1
);

-- UPDATE VALIDATION

WITH dd AS 
	(
	SELECT 
		row_number() OVER (PARTITION BY "SalePrice", 
										"SaleDate", 
										"LegalReference" 
										ORDER BY ("UniqueID")) AS row_num,
		*
	FROM saleinfo
	)

SELECT * 
FROM dd

WHERE row_num > 1;

-- SalePrice values (LOW, AVG and HIGH):

SELECT
PERCENTILE_CONT(.25) WITHIN GROUP (ORDER BY "SalePrice") AS LOW_VALUE,
PERCENTILE_CONT(.5) WITHIN GROUP (ORDER BY "SalePrice") AS AVG_VALUE,
PERCENTILE_CONT(.75) WITHIN GROUP (ORDER BY "SalePrice") AS HIGH_VALUE
FROM saleinfo;

-- SalePrice Avg Values:
-- LOW VALUE = 135,000
-- MEDIUM VALUE = 201,000
-- HIGH VALUE = 314,900

--

SELECT *,
CASE WHEN "SalePrice" <= 135000 THEN 'LOW'
	 WHEN "SalePrice" >= 314900 THEN 'HIGH'
	 ELSE 'AVG'
	 END AS SalePrice_Value
FROM saleinfo;

-- UPDATE

ALTER TABLE saleinfo
ADD SalePrice_Value VARCHAR(255);

UPDATE saleinfo
SET SalePrice_Value = CASE WHEN "SalePrice" <= 135000 THEN 'LOW'
						   WHEN "SalePrice" >= 314900 THEN 'HIGH'
	 					   ELSE 'AVG'
						   END;

-- UPDATE VALIDATION 

SELECT *
FROM saleinfo;

-- Net Income:

SELECT 
	*,
	("SalePrice" - "TotalValue") AS Income
FROM saleinfo;

-- UPDATE

ALTER TABLE saleinfo
ADD Income NUMERIC;

UPDATE saleinfo
SET Income = ("SalePrice" - "TotalValue");

-- UPDATE VALIDATION

SELECT
	"SalePrice",
	"saleprice_value",
	"income"
FROM saleinfo;

-- Profitable or Unprofitable:

SELECT 
	*,
	CASE WHEN "income" > 0 THEN 'Profitable'
		 WHEN "income" < 0 THEN 'Unprofitable'
		 END AS status
FROM saleinfo;

-- UPDATE

ALTER TABLE saleinfo
ADD status VARCHAR(255);

UPDATE saleinfo
SET status = CASE WHEN "income" > 0 THEN 'Profitable'
				  WHEN "income" < 0 THEN 'Unprofitable'
		 		  END;

-- UPDATE VALIDATION

SELECT
	"SalePrice",
	"saleprice_value",
	"income",
	"status"
FROM saleinfo;

-- Net revenue per day:

SELECT
    "SaleDate" AS Date,
    SUM("income") AS Net_Revenue
FROM saleinfo

WHERE EXTRACT(YEAR FROM "SaleDate") <> 2019

GROUP BY "SaleDate"

ORDER BY "SaleDate";

-- Net revenue per month:

SELECT
    TO_CHAR("SaleDate", 'YYYY/MM') AS Date,
    SUM("income") AS Net_Revenue
FROM saleinfo

WHERE EXTRACT(YEAR FROM "SaleDate") <> 2019
	 AND "SoldAsVacant" = 'No' -- or 'Yes' as you want
	 
GROUP BY Date

ORDER BY Date;

-- Adding propertyage:

SELECT 
	*,
	CASE WHEN "YearBuilt" < 1900 THEN '90- Very Old'
		 WHEN "YearBuilt" BETWEEN 1900 AND 1949 THEN '49- Old'
		 WHEN "YearBuilt" BETWEEN 1950 AND 1969 THEN '69- Mid-Century'
		 WHEN "YearBuilt" BETWEEN 1970 AND 1999 THEN '99- Relatively Modern'
		 WHEN "YearBuilt" BETWEEN 2000 AND 2009 THEN '09- Modern'
		 WHEN "YearBuilt" > 2009 THEN 'Cur- Very Modern'
		 END AS propertyage
FROM propertyinfo;

-- UPDATE

ALTER TABLE propertyinfo
ADD propertyage VARCHAR(255);

UPDATE propertyinfo
SET propertyage = CASE WHEN "YearBuilt" < 1900 THEN '90- Very Old'
					   WHEN "YearBuilt" BETWEEN 1900 AND 1949 THEN '49- Old'
					   WHEN "YearBuilt" BETWEEN 1950 AND 1969 THEN '69- Mid-Century'
					   WHEN "YearBuilt" BETWEEN 1970 AND 1999 THEN '99- Relatively Modern'
					   WHEN "YearBuilt" BETWEEN 2000 AND 2009 THEN '09- Modern'
					   WHEN "YearBuilt" > 2009 THEN 'Cur- Very Modern'
					   END;

-- UPDATE VALIDATION

SELECT
	"YearBuilt",
	"propertyage"
FROM propertyinfo

ORDER BY RANDOM();

-- Property old:

SELECT 
	"YearBuilt",
	COUNT("YearBuilt")
FROM propertyinfo

GROUP BY "YearBuilt"

ORDER BY "YearBuilt";

-- Our most importent cities:

SELECT DISTINCT
	"propertycityaddress",
	COUNT("propertycityaddress")
FROM propertyinfo

GROUP BY "propertycityaddress";

-- propertyage net revenue over time :

SELECT
	EXTRACT(YEAR FROM "SaleDate") date,
	"LandUse",
	COUNT("LandUse") landuse_count, -- or [COUNT("propertyage") propertyage_count,] if you want
	-- SUM("TotalValue") total_value,
	SUM("income") Net_Revenue

FROM saleinfo

LEFT JOIN propertyinfo USING("UniqueID")

WHERE EXTRACT(YEAR FROM "SaleDate") <> 2019

GROUP BY date,
		 "LandUse"

ORDER BY date;

-- Who our most importent customers?:

CREATE VIEW our_most_importent_customers_17 AS
SELECT 
	o."OwnerName" AS customer,
	o."ownercityaddress" AS customer_city,
	COUNT(o."OwnerName") AS propertyowned,
	MAX(p."LandUse") AS land_type_attract,
	MAX(p."propertyage") AS property_age_attract,
	ROUND(AVG(p."SquareMeters"), 2) AS avg_squaremeters,
	ROUND(AVG(s."SalePrice"), 0) AS avg_deal_price,
	ROUND(AVG(s."income"), 0) AS avg_revenue,
	SUM(s."income") AS all_net_revenue
FROM ownerinfo o
	    
LEFT JOIN saleinfo s USING ("UniqueID")
LEFT JOIN propertyinfo p USING ("UniqueID")
	    
WHERE s."income" IS NOT NULL
	    
GROUP BY o."OwnerName",
		 o."ownercityaddress"
	        
HAVING COUNT(o."OwnerName") >= 10

ORDER BY "propertyowned" DESC;

-- What is the best time to make a deal?:

SELECT
	TO_CHAR("SaleDate", 'YYYY/MM') AS date,
	PERCENTILE_CONT(.5) WITHIN GROUP (ORDER BY "SalePrice") AS avg_deal_price,
	SUM("income") net_revenue
FROM saleinfo

WHERE EXTRACT(YEAR FROM "SaleDate") <> 2019

GROUP BY date;

-- Does different TaxDistricts inflects revenue?:

SELECT
	TO_CHAR("SaleDate", 'YYYY') AS date,
	"TaxDistrict",
	COUNT("UniqueID") AS deals_count,
	PERCENTILE_CONT(.5) WITHIN GROUP (ORDER BY "SalePrice") AS avg_deal_price,
	SUM("income") net_revenue
FROM saleinfo

WHERE EXTRACT(YEAR FROM "SaleDate") <> 2019

GROUP BY "TaxDistrict",
		  date
		  
ORDER BY date;









-- ~WESAM