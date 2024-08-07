Select * From Chinook.dbo.InvoiceLine AS IL
Select * From Chinook.dbo.Invoice AS I
Select * From Chinook.dbo.Artist AS AR
Select * From Chinook.dbo.Track AS T
Select * From Chinook.dbo.Customer AS CU
Select * From Chinook.dbo.Genre AS G
Select * From Chinook.dbo.Employee AS EM
Select * From Chinook.dbo.Album AS AL
Select * From Chinook.dbo.Playlist AS PL
Select * From Chinook.dbo.PlaylistTrack AS PLT
Select * From Chinook.dbo.MediaType AS MT

--1) The top 10 songs that have the most income are created along with the income

SELECT TOP 10 
	T.TrackId, 
	T.Name AS TrackName, 
	SUM(IL.UnitPrice * IL.Quantity) AS Earn
FROM
	InvoiceLine AS IL
JOIN
	Track AS T ON IL.TrackId = T.TrackId
GROUP BY T.TrackId, T.Name
ORDER BY Earn DESC ;

--2) The most popular genre, preferably in terms of the number of songs sold and total revenue

SELECT Top 1  
    G.GenreId, 
    G.Name AS GenreName,  
    SUM(IL.Quantity) AS TotalTracksSold,
    SUM(IL.UnitPrice * IL.Quantity) AS TotalRevenue
FROM 
    Chinook.dbo.Genre AS G
JOIN 
    Chinook.dbo.Track AS T ON G.GenreId = T.GenreId
JOIN 
    Chinook.dbo.InvoiceLine AS IL ON T.TrackId = IL.TrackId

Group BY G.Name, G.GenreId
Order BY TotalTracksSold DESC,
		 TotalRevenue DESC;

--3) Users who haven't made a purchase yet

SELECT
	CU.CustomerId,
	I.Total,
	SUM(IL.Quantity) AS Total_Quantity
FROM
	Chinook.dbo.Invoice AS I

JOIN
	Chinook.dbo.Customer AS CU ON  I.CustomerId = CU.CustomerId 
JOIN
	Chinook.dbo.InvoiceLine AS IL ON  I.InvoiceId = IL.InvoiceId
GROUP BY
	CU.CustomerId,
	IL.Quantity,
	I.Total
ORDER BY I.Total ASC;


--4) Average time of songs in each album
SELECT
	AL.Title,
	T.AlbumId,
	AVG (T.Milliseconds) AS TIME_TOTAL

FROM
	Chinook.dbo.Track AS T

JOIN
	Chinook.dbo.Album AS AL ON  AL.AlbumId = T.AlbumId 

GROUP BY
	AL.Title,
	T.AlbumId

ORDER BY AL.Title DESC;


-- 5) The employee who had the most sales
SELECT TOP 1
    EM.EmployeeId,
    (EM.FirstName + ' ' + EM.LastName) AS Employee_Name,
    SUM(IL.Quantity) AS Quantity_sold
FROM
    Chinook.dbo.Employee AS EM
JOIN
    Chinook.dbo.Customer AS CU ON EM.EmployeeId = CU.SupportRepId
JOIN
    Chinook.dbo.Invoice AS I ON CU.CustomerId = I.CustomerId
JOIN
    Chinook.dbo.InvoiceLine AS IL ON I.InvoiceId = IL.InvoiceId
GROUP BY
    EM.EmployeeId,
    EM.FirstName,
    EM.LastName
ORDER BY
    Quantity_sold DESC;

--6) Users who bought from more than one genre

SELECT 
	 CU.CustomerId,
	(CU.FirstName + ' ' + CU.LastName) AS Customer_Name,
	 COUNT(DISTINCT G.GenreId) AS Genre_Count
	 	 
FROM 
    Chinook.dbo.Customer AS CU

JOIN
    Chinook.dbo.Invoice AS I ON CU.CustomerId = I.CustomerId

JOIN 
    Chinook.dbo.InvoiceLine AS IL ON I.InvoiceId = IL.InvoiceId

JOIN 
    Chinook.dbo.Track AS T ON IL.TrackId = T.TrackId

JOIN 
    Chinook.dbo.Genre AS G ON T.GenreId = G.GenreId

GROUP BY
    CU.CustomerId,
    CU.FirstName,
    CU.LastName
HAVING
    COUNT(DISTINCT G.GenreId) >= 1
ORDER BY
    Genre_Count DESC;

-- 7) Top three tracks by sales revenue for each genre

WITH TrackRevenue AS (
    SELECT
        G.GenreId,
        G.Name AS GenreName,
        T.TrackId,
        T.Name AS TrackName,
        SUM(IL.Quantity * IL.UnitPrice) AS Revenue
    FROM
        Chinook.dbo.Genre AS G
    JOIN
        Chinook.dbo.Track AS T ON G.GenreId = T.GenreId
    JOIN
        Chinook.dbo.InvoiceLine AS IL ON T.TrackId = IL.TrackId
    GROUP BY
        G.GenreId,
        G.Name,
        T.TrackId,
        T.Name
),
RankedTracks AS (
    SELECT
        GenreId,
        GenreName,
        TrackId,
        TrackName,
        Revenue,
        ROW_NUMBER() OVER (PARTITION BY GenreId ORDER BY Revenue DESC) AS Rank
    FROM
        TrackRevenue
)
SELECT
    GenreName,
    TrackName,
    Revenue
FROM
    RankedTracks
WHERE
    Rank <= 3
ORDER BY
    GenreName,
    Rank;

-- 8) Cumulative number of tracks sold each year

WITH Yearly_Sales AS (
    SELECT
        YEAR(I.InvoiceDate) AS Sales_Year,
        SUM(IL.Quantity) AS Tracks_Sold
    FROM
        Chinook.dbo.Invoice AS I
    JOIN
        Chinook.dbo.InvoiceLine AS IL ON I.InvoiceId = IL.InvoiceId
    GROUP BY
        YEAR(I.InvoiceDate)
),
Cumulative_Sales AS (
    SELECT
        Sales_Year,
        Tracks_Sold,
        SUM(Tracks_Sold) OVER (ORDER BY Sales_Year) AS Cumulative_Tracks_Sold
    FROM
        Yearly_Sales
)
SELECT
    Sales_Year,
    Tracks_Sold,
    Cumulative_Tracks_Sold
FROM
    Cumulative_Sales
ORDER BY
    Sales_Year;

-- 9) Customers whose total purchases are above the average total purchases

WITH Customer_Total_Purchases AS (
    SELECT
        CU.CustomerId,
        (CU.FirstName + ' ' + CU.LastName) AS Customer_Name,
        SUM(IL.Quantity * IL.UnitPrice) AS Total_Purchases
    FROM
        Chinook.dbo.Customer AS CU
    JOIN
        Chinook.dbo.Invoice AS I ON CU.CustomerId = I.CustomerId
    JOIN
        Chinook.dbo.InvoiceLine AS IL ON I.InvoiceId = IL.InvoiceId
    GROUP BY
        CU.CustomerId,
        CU.FirstName,
        CU.LastName
),
Average_Total_Purchases AS (
    SELECT
        AVG(Total_Purchases) AS Average_Purchases
    FROM
        Customer_Total_Purchases
)
SELECT
    CTP.CustomerId,
    CTP.Customer_Name,
    CTP.Total_Purchases
FROM
    Customer_Total_Purchases AS CTP
JOIN
    Average_Total_Purchases AS ATP ON CTP.Total_Purchases > ATP.Average_Purchases
ORDER BY
    CTP.Total_Purchases DESC;
