/************************************************************
 *********************** CREATE TABLES ***********************
 ************************************************************/
CREATE TABLE Date (
    InvoiceDate DATETIME PRIMARY KEY NOT NULL,
    Date DATE NOT NULL, -- Date without time
    Year INT NOT NULL,
    Month INT NOT NULL,
    Day INT NOT NULL,
    Hour INT NOT NULL,
    DayOfWeek NVARCHAR(20) NOT NULL,
    Season NVARCHAR(20) NOT NULL,
    TimeOfDay NVARCHAR(20) NOT NULL -- Morning, Afternoon, etc
); 

CREATE TABLE InvoiceMetrics (
    CustomerID NVARCHAR(10),
    InvoiceNo NVARCHAR(10),
    InvoiceDate DATETIME,
    PurchaseInterval INT,
    TicketSize DECIMAL(18, 2),
    BasketSize INT,
    Country NVARCHAR(MAX)
);

CREATE TABLE RFM (
    CustomerID NVARCHAR(10),
    Recency INT,
    Frequency INT,
    Monetary DECIMAL(18, 2),
    RScore INT,
    FScore INT,
    MScore INT,
    RFMScore NVARCHAR(10), 
    Segment NVARCHAR(MAX)
);

CREATE TABLE Country (
    Name NVARCHAR(MAX) NOT NULL,
    Code NVARCHAR(2) PRIMARY KEY NOT NULL,
    Region NVARCHAR(MAX) NOT NULL
);

GO 



/************************************************************
 **************** PROCEDURE: InsertIntoDateTable ************
 ************************************************************
 Description   : Populates the Date table with detailed date, time, and
                 seasonal information extracted from the Transactions table.
 Inputs        : Data from the Transactions table (InvoiceDate field).
 Outputs       : Populates the Date table.
 ************************************************************/
CREATE OR ALTER PROCEDURE InsertIntoDateTable AS
BEGIN
    -- Enable atomic transactions for the procedure
    BEGIN TRANSACTION;

    -- Clear existing rows from the Date table
    TRUNCATE TABLE Date;

    -- Populate the Date table with updated data
    INSERT INTO Date (
        InvoiceDate, 
        [Date], 
        [Year], 
        [Month], 
        [Day], 
        [Hour], 
        DayOfWeek, 
        Season, 
        TimeOfDay
    )
    SELECT DISTINCT
        InvoiceDate,
        CAST(InvoiceDate AS DATE) AS [Date], -- Extract the date without time
        YEAR(InvoiceDate) AS [Year],
        MONTH(InvoiceDate) AS [Month],
        DAY(InvoiceDate) AS [Day],
        DATEPART(HOUR, InvoiceDate) AS [Hour],
        DATENAME(WEEKDAY, InvoiceDate) AS DayOfWeek,

        -- Determine the season based on the month
        CASE 
            WHEN MONTH(InvoiceDate) IN (3, 4, 5) THEN 'Spring'
            WHEN MONTH(InvoiceDate) IN (6, 7, 8) THEN 'Summer'
            WHEN MONTH(InvoiceDate) IN (9, 10, 11) THEN 'Fall'
            ELSE 'Winter'
        END AS Season,

        -- Categorize time of day
        CASE 
            WHEN DATEPART(HOUR, InvoiceDate) BETWEEN 6 AND 11 THEN 'Morning'
            WHEN DATEPART(HOUR, InvoiceDate) BETWEEN 12 AND 17 THEN 'Afternoon'
            WHEN DATEPART(HOUR, InvoiceDate) BETWEEN 18 AND 23 THEN 'Evening'
            ELSE 'Night'
        END AS TimeOfDay
    FROM Transactions;

    -- Commit the transaction to make changes permanent
    COMMIT TRANSACTION;

    -- Print confirmation message
    PRINT 'Data successfully inserted into the Date table.';
END;
GO

EXEC InsertIntoDateTable;

GO

/************************************************************
 *************** PROCEDURE: InsertIntoInvoiceMetrics ********
 ************************************************************
 Description   : Inserts invoice metrics including purchase intervals,
                 ticket size, and basket size into the InvoiceMetrics table.
 Inputs        : None directly; operates on data from Transactions.
 Outputs       : Populates the InvoiceMetrics table.
 ************************************************************/
CREATE OR ALTER PROCEDURE InsertIntoInvoiceMetrics AS
BEGIN
    -- Enable atomic transactions for the procedure
    BEGIN TRANSACTION;

    -- Clear existing rows from the InvoiceMetrics table
    TRUNCATE TABLE InvoiceMetrics;

    -- Define a CTE to calculate revenue metrics for each invoice
    WITH Revenue AS 
    (
        SELECT
            CustomerID,
            InvoiceNo,
            SUM(Quantity * UnitPrice) AS TicketSize, -- Total revenue per invoice
            SUM(Quantity) AS BasketSize              -- Total quantity per invoice
        FROM Transactions
        GROUP BY CustomerID, InvoiceNo
    )

    -- Insert calculated metrics into the InvoiceMetrics table
    INSERT INTO InvoiceMetrics (CustomerID, InvoiceNo, InvoiceDate, PurchaseInterval, TicketSize, BasketSize, Country)
    SELECT 
        T.CustomerID,
        T.InvoiceNo,
        T.InvoiceDate,

        -- Calculate Purchase Interval (days since the last invoice for the customer)
        DATEDIFF(
            DAY, 
            LAG(T.InvoiceDate) OVER (PARTITION BY T.CustomerID ORDER BY T.InvoiceDate), 
            T.InvoiceDate
        ) AS PurchaseInterval,

        R.TicketSize, 
        R.BasketSize,
        T.Country
    FROM 
        (
            SELECT DISTINCT 
                CustomerID, 
                InvoiceNo, 
                InvoiceDate, 
                Country
            FROM Transactions
        ) T
    
    JOIN 
        Revenue R 
        ON T.InvoiceNo = R.InvoiceNo

    -- Commit the transaction to make changes permanent
    COMMIT TRANSACTION;

    -- Provide feedback
    PRINT 'InvoiceMetrics table updated successfully.';
END;
GO

EXEC InsertIntoInvoiceMetrics;

GO

/************************************************************
 *********************** INSERT INTO Country ****************
 ************************************************************/
INSERT INTO Country (Name, Code, Region) VALUES
('United Kingdom', 'UK', 'Europe'),
('France', 'FR', 'Europe'),
('Australia', 'AU', 'Oceania'),
('Netherlands', 'NL', 'Europe'),
('Germany', 'DE', 'Europe'),
('Norway', 'NO', 'Europe'),
('EIRE', 'IE', 'Europe'),
('Switzerland', 'CH', 'Europe'),
('Spain', 'ES', 'Europe'),
('Poland', 'PL', 'Europe'),
('Portugal', 'PT', 'Europe'),
('Italy', 'IT', 'Europe'),
('Belgium', 'BE', 'Europe'),
('Lithuania', 'LT', 'Europe'),
('Japan', 'JP', 'Asia'),
('Iceland', 'IS', 'Europe'),
('Channel Islands', 'CI', 'Europe'),
('Denmark', 'DK', 'Europe'),
('Cyprus', 'CY', 'Europe'),
('Sweden', 'SE', 'Europe'),
('Austria', 'AT', 'Europe'),
('Israel', 'IL', 'Middle East'),
('Finland', 'FI', 'Europe'),
('Bahrain', 'BH', 'Middle East'),
('Greece', 'GR', 'Europe'),
('Hong Kong', 'HK', 'Asia'),
('Singapore', 'SG', 'Asia'),
('Lebanon', 'LB', 'Middle East'),
('United Arab Emirates', 'AE', 'Middle East'),
('Saudi Arabia', 'SA', 'Middle East'),
('Czech Republic', 'CZ', 'Europe'),
('Canada', 'CA', 'North America'),
('Brazil', 'BR', 'South America'),
('USA', 'US', 'North America'),
('European Community', 'EU', 'Europe'),
('Malta', 'MT', 'Europe'),
('RSA', 'ZA', 'Africa');

GO


/************************************************************
 ******************* DATABASE EXPLORATION *******************
 ************************************************************/
SELECT TOP 10 *
FROM [Date]; 

SELECT TOP 10 *
FROM [Holidays]; 

SELECT TOP 10 *
FROM [Country]; 

SELECT TOP 10 *
FROM [Transactions]; 

SELECT COUNT(*) AS Total_Rows 
FROM Transactions;

SELECT TOP 10 *
FROM [InvoiceMetrics]; 


/************************************************************
 *************** Finding patterns in cancellations **********
 ************************************************************/
SELECT COUNT(DISTINCT InvoiceNo) AS 'Cancelled Transactions Count'
FROM Transactions
WHERE Quantity < 0; 

WITH InvoiceSummary AS (
    SELECT 
        InvoiceNo, 
        CustomerID, 
        InvoiceDate,
        
        -- Total revenue for the invoice (positive for purchases, negative for cancellations)
        SUM(Quantity * UnitPrice) AS Revenue, 
        
        -- Create a hash of the items in the invoice to identify unique item combinations
        HASHBYTES(
            'SHA2_256', 
            STRING_AGG(CAST(StockCode AS VARCHAR(MAX)), ', ') 
            WITHIN GROUP (ORDER BY CAST(StockCode AS VARCHAR(MAX))) -- Ensure the same hash for variant orders in each combination 
        ) AS ItemsHash
    FROM 
        Transactions
    GROUP BY 
        InvoiceNo, CustomerID, InvoiceDate
)
SELECT 
    T2.CustomerID, T2.InvoiceDate, T2.InvoiceNo, T2.Revenue, 
    T1.InvoiceDate AS Cancelled_InvoiceDate, 
    T1.InvoiceNo AS Cancelled_InvoiceNo, 
    T1.Revenue AS Cancelled_Revenue
    
FROM 
    InvoiceSummary T1
JOIN 
    InvoiceSummary T2 
    ON 
        -- Match on revenue being the negative of each other 
        T1.Revenue = -T2.Revenue 
        
        -- Ensure the first invoice is cancelled to avoid repetitions
        AND T1.Revenue < 0 
        
        -- Match invoices from the same customer
        AND T1.CustomerID = T2.CustomerID 
        
        -- Ensure the same set of items were involved
        AND T1.ItemsHash = T2.ItemsHash
ORDER BY 
    T1.Revenue ASC;

