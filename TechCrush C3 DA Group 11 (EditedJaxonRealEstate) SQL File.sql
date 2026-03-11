--TECHCRUSH C3 DA GROUP 11 CAPSTONE PROJECT
---JAXON REAL ESTATE SALES & OPERATION ANALYSIS

--1.0 CREATION OF DATABASE & TABLE
---1.1 Creating Database
CREATE DATABASE JaxonRealEstate;
GO

USE JaxonRealEstate;
GO

---1.2 Creating Table
CREATE TABLE JaxonDataset (
	RowID INT IDENTITY (1,1) PRIMARY KEY,
	CustomerID NVARCHAR (15),
	FullName NVARCHAR (30),
	Phone NVARCHAR (20),
	Email NVARCHAR (50),
	Gender VARCHAR (10),
	DateRegistered DATE,
	AgentID NVARCHAR (15),
	AgentName NVARCHAR (30),
	AgencyName NVARCHAR (50),
	AgentPhone NVARCHAR (20),
	AgentEmail NVARCHAR (50),
	OfficeLocation NVARCHAR (50),
	PropertyID NVARCHAR (15),
    PropertyTitle NVARCHAR (50),
	Type NVARCHAR (20),
	Category NVARCHAR (20),
	Price DECIMAL (10,2),
	Size NVARCHAR (10),
	Bedrooms INT,
	Bathrooms INT,
	PropertyLocation NVARCHAR (50),
	Latitude DECIMAL (10,6),
	Longitude DECIMAL (10,6),
	ListedDate DATE,
	Status NVARCHAR (15),
	TransactionID NVARCHAR (15),
	TransactionDate DATE,
	AmountPaid DECIMAL (10,2),
	PaymentMode NVARCHAR (15),
	Remarks NVARCHAR (25)
	);
GO

--2.0 DATA IMPORTATION
---2.1 Loading Data (BULK INSERT)
BULK INSERT JaxonDataset
FROM 'C:\Users\len\Documents\Capstone\JaxonRealEstateDataCSV.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n'
);
GO

---2.2 Checking Import Success
----Total Row Count of JaxonDataset
SELECT COUNT(*) 
FROM JaxonDataset;
GO

----Displaying First 50 Rows
SELECT TOP 50 *
FROM JaxonDataset;
GO

--3.0 DATA CLEANING & PREPROCESSING
---3.1 Checking for Missing Values
----On Price Column
SELECT COUNT(*) AS ZeroPrice
FROM JaxonDataset
WHERE Price = 0;

----On AmountPaid Column
SELECT COUNT(*) AS ZeroAmountPaid
FROM JaxonDataset
WHERE AmountPaid = 0;
GO

---3.2 Converting 0 Back to NULL
----On Price Column
UPDATE JaxonDataset
SET Price = NULL
WHERE Price = 0;

----On AmountPaid Column
UPDATE JaxonDataset
SET AmountPaid = NULL
WHERE AmountPaid = 0;
GO

---3.3 Rechecking Missing Values
----Where Price and AmountPaid are Missing
SELECT COUNT(*) AS BothMissing
FROM JaxonDataset
WHERE Price IS NULL
AND AmountPaid IS NULL;

----Where Price is missing but AmountPaid exists
SELECT COUNT(*) AS CanBeFilledP
FROM JaxonDataset
WHERE Price IS NULL
AND AmountPaid IS NOT NULL;

----Where AmountPaid is missing but Price exists
SELECT COUNT(*) AS CanBeFilledAP
FROM JaxonDataset
WHERE AmountPaid IS NULL
AND Price IS NOT NULL;
GO

---3.4 Handling Missing Values using corresponding values on Price & AmountPaid Columns
----Filling Missing Prices using AmountPaid
UPDATE JaxonDataset
SET Price = AmountPaid
WHERE Price IS NULL
AND AmountPaid IS NOT NULL;

----Filling Missing AmountPaid using Price
UPDATE JaxonDataset
SET AmountPaid = Price
WHERE AmountPaid IS NULL
AND TransactionID IS NOT NULL
AND Price IS NOT NULL;

----Remaining Missing Values (Confirmation of Cleaning so far)
SELECT
    SUM(CASE WHEN Price IS NULL THEN 1 ELSE 0 END) AS MissingPrice,
    SUM(CASE WHEN AmountPaid IS NULL THEN 1 ELSE 0 END) AS MissingAmountPaid,
    SUM(CASE WHEN Price IS NULL AND AmountPaid IS NULL THEN 1 ELSE 0 END) AS BothMissing
FROM JaxonDataset;
GO

---3.5 Handling Missing Price Values using Median by PropertyLocation + PropertyTitle
----Calculating Median by PropertyLocation + PropertyTitle
SELECT DISTINCT
    PropertyLocation,
    PropertyTitle,
    PERCENTILE_CONT(0.5) 
    WITHIN GROUP (ORDER BY Price)
    OVER (PARTITION BY PropertyLocation, PropertyTitle) AS MedianPrice
FROM JaxonDataset
WHERE Price IS NOT NULL;

----Filling Missing Prices with Medians by PropertyLocation + PropertyTitle
UPDATE d
SET Price = m.MedianPrice
FROM JaxonDataset d
JOIN (
    SELECT DISTINCT
        PropertyLocation,
        PropertyTitle,
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY Price)
        OVER (PARTITION BY PropertyLocation, PropertyTitle) AS MedianPrice
    FROM JaxonDataset
    WHERE Price IS NOT NULL
) m
ON d.PropertyLocation = m.PropertyLocation
AND d.PropertyTitle = m.PropertyTitle
WHERE d.Price IS NULL;

----Confirming if all Prices are Filled
SELECT COUNT(*) AS RemainingMissingPrices
FROM JaxonDataset
WHERE Price IS NULL;

----Viewing Remaining Missing Prices
SELECT *
FROM JaxonDataset
WHERE Price IS NULL;
GO

---3.6 Handling Remaining Missing Price Values using Median by PropertyTitle
----Calculating Median by PropertyTitle
SELECT DISTINCT
    PropertyTitle,
    PERCENTILE_CONT(0.5) 
    WITHIN GROUP (ORDER BY Price)
    OVER (PARTITION BY PropertyTitle) AS MedianPrice
FROM JaxonDataset
WHERE Price IS NOT NULL;

----Filling Remaining Missing Prices with Median by PropertyTitle
UPDATE d
SET Price = m.MedianPrice
FROM JaxonDataset d
JOIN (
    SELECT DISTINCT
        PropertyTitle,
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY Price)
        OVER (PARTITION BY PropertyTitle) AS MedianPrice
    FROM JaxonDataset
    WHERE Price IS NOT NULL
) m
ON d.PropertyTitle = m.PropertyTitle
WHERE d.Price IS NULL;

----Confirming if all Prices are Filled
SELECT COUNT(*) AS RemainingMissingPricesTotal
FROM JaxonDataset
WHERE Price IS NULL;
GO

---3.7 Viewing Cleaned Dataset
SELECT TOP 50 *
FROM JaxonDataset;
GO

--4.0 DATA NORMALIZATION (3NF)
---4.1 Creating Customers View
CREATE VIEW Customers_View AS
SELECT DISTINCT
    CustomerID,
    FullName,
    Phone,
    Email,
    Gender,
    DateRegistered
FROM JaxonDataset;
GO
----Checking Customers View
SELECT * FROM Customers_View;
GO

---4.2 Creating Agents View
CREATE VIEW Agents_View AS
SELECT DISTINCT
    AgentID,
    AgentName,
    AgencyName,
    AgentPhone,
    AgentEmail,
    OfficeLocation
FROM JaxonDataset;
GO

----Checking Agents View
SELECT * FROM Agents_View;
GO

---4.3 Creating Properties View
CREATE VIEW Properties_View AS
SELECT DISTINCT
    PropertyID,
    PropertyTitle,
    Type,
    Category,
    Price,
    Size,
    Bedrooms,
    Bathrooms,
    PropertyLocation,
    Latitude,
    Longitude,
    ListedDate,
    Status
FROM JaxonDataset;
GO

----Checking Properties View
SELECT * FROM Properties_View;
GO

---4.4 Creating Transactions View
CREATE VIEW Transactions_View AS
SELECT
    TransactionID,
    CustomerID,
    AgentID,
    PropertyID,
    TransactionDate,
    AmountPaid,
    PaymentMode,
    Remarks
FROM JaxonDataset
WHERE TransactionID IS NOT NULL;
GO

----Checking Transactions View
SELECT * FROM Transactions_View;
GO

---4.5 Verifying Created Views
SELECT COUNT(*) FROM Customers_View;
SELECT COUNT(*) FROM Agents_View;
SELECT COUNT(*) FROM Properties_View;
SELECT COUNT(*) FROM Transactions_View;
GO

--5.0 DATASET EXPORTATION
--- Exported Each View to its CSV file