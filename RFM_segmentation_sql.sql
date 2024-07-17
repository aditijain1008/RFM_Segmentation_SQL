
--Overview of the the sales data sample table
select * from rfm1;

--Checking unique values in the relevant columns
Select distinct (STATUS) from rfm1;
Select distinct(YEAR_ID) from rfm1;
Select distinct(PRODUCTLINE) from rfm1;
Select distinct(COUNTRY) from rfm1;
Select distinct(DEALSIZE) from rfm1;
Select distinct(TERRITORY) from rfm1;

--Sales by Product
Select PRODUCTLINE, Round(Sum(SALES),2)
FRom rfm1
group by PRODUCTLINE
order by Sum(SALES) desc ;

--Sales by Year
Select YEAR_ID, Round(Sum(SALES),2) as TotalSales
FRom rfm1
group by YEAR_ID
order by TotalSales desc ;


--Sales by Month
Select MONTH_ID, YEAR_ID, Round(Sum(SALES),2) as TotalSales
FRom rfm1
group by MONTH_ID, YEAR_ID
order by TotalSales desc ;

--Revenue by Deal Size
Select DEALSIZE, Round(Sum(SALES),2) as TotalSales
FRom rfm1
group by DEALSIZE
order by TotalSales desc ;

--Sales and order frequency by year, month and product line


Select PRODUCTLINE, MONTH_ID, YEAR_ID, Round(Sum(SALES),2) as TotalSales, COUNT(ORDERNUMBER) AS Frequency
FRom rfm1
group by PRODUCTLINE, MONTH_ID, YEAR_ID
order by TotalSales desc;

--Best Customers Using RFM Analysis
--Used DATEDIFF() to calculate recency (time between customer last order and most recent date in table)


Select CUSTOMERNAME, Round(Sum(SALES),2) as TotalSales, 
Round(AVG(SALES),2) as AVGSales, 
COUNT(ORDERNUMBER) AS FREQ, MAX(ORDERDATE) AS LATEST,
(select max(orderdate) from rfm1) as maxdatedate,
datediff((Select MAX(ORDERDATE) from rfm1), MAX(ORDERDATE)) as recency
FRom rfm1
group by CUSTOMERNAME

--Pass the above query to a CTE rfm
--Use the NTILE() function split rfm values into 4 buckets
--Pass result to a temp table - rfm_temp


 Create temporary table rfm_temp
 (with rfm as
(Select CUSTOMERNAME, Round(Sum(SALES),2) as TotalSales, 
Round(AVG(SALES),2) as AVGSales, 
COUNT(ORDERNUMBER) AS FREQ, MAX(ORDERDATE) AS LATEST,
(select max(orderdate) from rfm1) as maxdatedate,
datediff((Select MAX(ORDERDATE) from rfm1), MAX(ORDERDATE)) as recency
FRom rfm1
group by CUSTOMERNAME),
--retrieve all columns from rfm CTE then split rfm_ values into 4 buckets
rfm_calc as
(Select r.*,
ntile (4) Over (order by recency desc) as rfm_recency,
ntile (4) Over (order by FREQ) as rfm_frequency,
ntile (4) Over (order by TotalSales) as rfm_monetary
 from rfm r)

--retrieve all columns from rfm-calc CTE 
--derive the rfmsum & concatrfm columns

Select c.*, rfm_recency+rfm_frequency+rfm_monetary as rfmsum, concat(rfm_recency,rfm_frequency,rfm_monetary) as concatrfm
 from rfm_calc c);


--Here is the temp table output:

Select * from rfm_temp;
 

--Segmentation criteria: we will divide it into specific groups for easier analysis.
--Leverage case statements to segment by customer groups


select CUSTOMERNAME, rfm_recency,rfm_frequency,rfm_monetary, concatrfm,
CASE 
WHEN concatrfm IN (111,112,121,122,123,132,211,212,114,141) THEN 'lost_customers' 
	WHEN concatrfm IN (133,134,143,244,334,343,344,144) THEN 'slipping away, cannot lose' 
	WHEN concatrfm IN (311,411,331) THEN 'new_customers'
	WHEN concatrfm IN (222,223,233,322) THEN 'potential_customers'
	WHEN concatrfm IN (323,333,321,422,332,432) THEN 'active'
	WHEN concatrfm IN (433,434,443,444) THEN 'loyal'
END As segment
from rfm_temp;






