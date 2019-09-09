create database Global_Superstore_V2;

/****** Landing Table ******/

CREATE TABLE Global_SuperStore_Data (
    Row_ID int,
    Order_ID varchar(255),
    Order_Date date,
    Ship_Date date,
    Ship_Mode varchar(255),
    Customer_ID varchar(20),
    Customer_Name varchar(255),
    Segment varchar(200),
    Postal_Code varchar(20) NOT NULL DEFAULT 'N/A',
    City varchar(255),
    State varchar(255),
    Country varchar(255),
    Market varchar(255),
    Product_ID varchar(255),
    Category varchar(255),
    Sub_Category varchar(255),
    Product_Name varchar(255),
    Sales float(10,2),
    Quantity int,
    Discount float,
    Profit float(10,2),
    Shipping_Cost float(10,2),
    Order_Priority varchar(255)
);

SELECT * FROM Global_SuperStore_Data;

/****** Activity 1 - Main Tables ******/

SELECT * FROM CUSTOMER_PERSONAL_INFO;

CREATE TABLE CUSTOMER_PERSONAL_INFO (Primary key(Customer_ID)) AS 
	SELECT DISTINCT
        Customer_ID,
        SUBSTRING_INDEX(Customer_Name, ' ', 1) AS First_Name,
        SUBSTRING_INDEX(Customer_Name, ' ', -1) AS Last_Name,
        Segment
	FROM Global_SuperStore_Data;
    
CREATE TABLE SHIPMENT_ADDRESS (Address_ID INT AUTO_INCREMENT,PRIMARY KEY(Address_ID)) AS 
	SELECT DISTINCT
        Order_ID,
        COALESCE(NULLIF(Postal_Code,''), 'N/A') AS Postal_Code,
        City,
        State,
        Country,
        Market
	FROM Global_SuperStore_Data;
    
SELECT * FROM PRODUCT_DESCRIPTION;

CREATE TABLE PRODUCT_DESCRIPTION (Primary key(Product_ID)) AS 
	SELECT distinct
        Product_ID,
		Product_Name,
		Category,
        Sub_Category
	FROM Global_SuperStore_Data;
    
CREATE TABLE PRODUCT_ORDERS AS 
	SELECT
        Global_SuperStore_Data.Order_ID,
        Global_SuperStore_Data.Order_Date,
        Global_SuperStore_Data.Order_Priority,
        Global_SuperStore_Data.Customer_ID,
        Global_SuperStore_Data.Ship_Date,
        Global_SuperStore_Data.Ship_Mode,
        Global_SuperStore_Data.Product_ID,
        Shipment_address.Address_ID,
        Global_SuperStore_Data.Quantity,
        Global_SuperStore_Data.Shipping_Cost,
        Global_SuperStore_Data.Sales,
        Global_SuperStore_Data.Discount,
        Global_SuperStore_Data.Profit
	FROM Global_SuperStore_Data, Shipment_address
    WHERE
    Global_SuperStore_Data.Order_ID = shipment_address.Order_ID;

/****** Activity 2.1 - Product Sales ******/

SELECT * FROM PRODUCT_SALES;

CREATE TABLE PRODUCT_SALES (Sales_ID INT AUTO_INCREMENT, PRIMARY KEY(Sales_ID)) AS 
	SELECT
        Order_ID,
        Quantity,
        Shipping_Cost,
        Sales,
        Discount,
        Profit
	FROM PRODUCT_ORDERS; 
 
/****** Activity 2.2 - Temp Tables ******/

CREATE TABLE CUSTOMER_PERSONAL_INFO_PERIODIC AS 
	SELECT DISTINCT
        Customer_ID,
        SUBSTRING_INDEX(Customer_Name, ' ', 1) AS First_Name,
        SUBSTRING_INDEX(Customer_Name, ' ', -1) AS Last_Name,
        Segment
	FROM Global_SuperStore_Data;

SELECT * FROM shipment_address;

CREATE TABLE SHIPMENT_ADDRESS_PERIODIC AS 
	SELECT DISTINCT
        Address_ID,
        Order_ID,
        COALESCE(NULLIF(Postal_Code,''), 'N/A') AS Postal_Code,
        City,
        State,
        Country,
        Market
	FROM SHIPMENT_ADDRESS;
    
CREATE TABLE PRODUCT_DESCRIPTION_PERIODIC AS 
	SELECT
        Product_ID,
		Product_Name,
		Category,
        Sub_Category
	FROM Global_SuperStore_Data;

CREATE TABLE PRODUCT_ORDERS_PERIODIC AS 
	SELECT
        Order_ID,
        Order_Date,
        Order_Priority,
        Customer_ID,
        Ship_Date,
        Ship_Mode,
        Product_ID,
        Address_ID
	FROM PRODUCT_ORDERS;

/****** Alter Temp Tables ******/

SELECT * FROM PRODUCT_ORDERS_PERIODIC;

ALTER TABLE CUSTOMER_PERSONAL_INFO_PERIODIC
  ADD Last_Update_Date timestamp default current_timestamp,
  ADD Action VARCHAR(2) default 'C',
  ADD Active VARCHAR(2) default 'Y'
    AFTER Segment;

ALTER TABLE PRODUCT_ORDERS_PERIODIC
  ADD Last_Update_Date timestamp default current_timestamp,
  ADD Action VARCHAR(2) default 'C',
  ADD Active VARCHAR(2) default 'Y'
    AFTER Address_ID;
    
ALTER TABLE PRODUCT_DESCRIPTION_PERIODIC
  ADD Last_Update_Date timestamp default current_timestamp,
  ADD Action VARCHAR(2) default 'C',
  ADD Active VARCHAR(2) default 'Y'
    AFTER Sub_Category;

ALTER TABLE SHIPMENT_ADDRESS_PERIODIC
  ADD Last_Update_Date timestamp default current_timestamp,
  ADD Action VARCHAR(2) default 'C',
  ADD Active VARCHAR(2) default 'Y'
    AFTER Market;

/****** Inserting Updated Values to Tables - Versioning******/

UPDATE PRODUCT_DESCRIPTION_PERIODIC
SET Active = 'N'
WHERE Product_ID='TEC-PH-3148';
INSERT INTO PRODUCT_DESCRIPTION_PERIODIC 
VALUES ('TEC-PH-3148','Samsung J6','Technology','Phones','Y',current_timestamp(),'U');

SELECT * FROM PRODUCT_DESCRIPTION_PERIODIC WHERE Product_ID = 'TEC-PH-5816';

UPDATE PRODUCT_ORDERS_PERIODIC
SET Active = 'N'
WHERE Order_ID ='US-2015-SW20245140-42061';
INSERT INTO PRODUCT_ORDERS_PERIODIC
VALUES ('US-2015-SW20245140-42061','2014-12-05','High','JR-162107',
'2014-12-06','Second Class','FUR-CH-5379','26341','Y',current_timestamp(),'U');

SELECT * FROM PRODUCT_ORDERS_PERIODIC WHERE Order_ID ='US-2015-SW20245140-42061';

SET SQL_SAFE_UPDATES = 0;
set global sql_mode='';
set global sql_mode='STRICT_TRANS_TABLES';

/****** Act 3 - Hierarchy Tables ******/
CREATE TABLE SHIPMENT_ADDRESS_TEMP (Temp_Id varchar(10)) AS 
	SELECT DISTINCT City FROM SHIPMENT_ADDRESS
	UNION ALL
	SELECT DISTINCT State FROM SHIPMENT_ADDRESS
    UNION ALL
    SELECT DISTINCT Country FROM SHIPMENT_ADDRESS
    UNION ALL
    SELECT DISTINCT Market FROM SHIPMENT_ADDRESS;
SELECT @i:=0;
UPDATE SHIPMENT_ADDRESS_TEMP set Temp_Id = @i:=@i+1;
ALTER TABLE SHIPMENT_ADDRESS_TEMP CHANGE `City` `Address` varchar(255);
  
select * from shipment_address_temp;

SELECT @j:=0;
UPDATE SHIPMENT_ADDRESS_TEMP set Temp_Id = CONCAT("C-",@j:=@j+1) WHERE Temp_Id <= (select count(distinct city) from shipment_address);

SELECT @k:=0;
UPDATE SHIPMENT_ADDRESS_TEMP set Temp_Id = CONCAT("S-",@k:=@k+1) WHERE SUBSTRING_INDEX(Temp_Id, '-' , -1) > (select count(distinct city) from shipment_address)
AND SUBSTRING_INDEX(Temp_Id,'-', -1) <= (select count(distinct city) +  count(distinct state) from shipment_address);

SELECT @l:=0;
UPDATE SHIPMENT_ADDRESS_TEMP set Temp_Id = CONCAT("CO-",@l:=@l+1) WHERE SUBSTRING_INDEX(Temp_Id,'-', -1) > (select count(distinct city) +  count(distinct state) from shipment_address)
AND SUBSTRING_INDEX(Temp_Id,'-', -1) <= (select count(distinct city)+ count(distinct state) + count(distinct country) from shipment_address);

SELECT @n:=0;
UPDATE SHIPMENT_ADDRESS_TEMP set Temp_Id = CONCAT("M-",@n:=@n+1) WHERE SUBSTRING_INDEX(Temp_Id,'-', -1) > (select count(distinct city)+ count(distinct state) + count(distinct country) from shipment_address);

select * from SHIPMENT_ADDRESS_TEMP;
select count(distinct city) from shipment_address;
select count(distinct city) from shipment_address;

CREATE TABLE SHIPMENT_ADDRESS_HT (Address_ID varchar(20)) AS
	SELECT distinct shipment_address.city, shipment_address_temp.temp_id FROM shipment_address LEFT JOIN shipment_address_temp ON 
	shipment_address.state = shipment_address_temp.Address where shipment_address_temp.temp_id LIKE 's%' 
    UNION ALL
    SELECT DISTINCT shipment_address.state, shipment_address_temp.temp_id FROM shipment_address, shipment_address_temp WHERE shipment_address_temp.temp_Id LIKE 'co%' 
	AND shipment_address.country = shipment_address_temp.Address
    UNION ALL
    SELECT DISTINCT shipment_address.country, shipment_address_temp.temp_id FROM shipment_address, shipment_address_temp WHERE shipment_address_temp.temp_Id LIKE 'm%' 
	AND shipment_address.market = shipment_address_temp.Address
    UNION ALL
    SELECT DISTINCT shipment_address.market, shipment_address_temp.temp_id FROM shipment_address, shipment_address_temp WHERE shipment_address.market = shipment_address_temp.Address;
SELECT @i:=0;
UPDATE SHIPMENT_ADDRESS_HT set Address_ID = @i:=@i+1;
ALTER TABLE SHIPMENT_ADDRESS_HT CHANGE `temp_id` `Parent_ID` varchar(255);
ALTER TABLE SHIPMENT_ADDRESS_HT CHANGE `city` `Address` varchar(255);

ALTER TABLE SHIPMENT_ADDRESS_HT
  ADD Last_Update_Date timestamp default current_timestamp,
  ADD Action VARCHAR(2) default 'C',
  ADD Active VARCHAR(2) default 'Y';
  
ALTER TABLE SHIPMENT_ADDRESS_HT
ADD Level int;
  
SELECT * FROM SHIPMENT_ADDRESS_HT;
  
SELECT @j:=0;
UPDATE SHIPMENT_ADDRESS_HT set Address_ID = CONCAT("C-",@j:=@j+1), Level = 0 WHERE Address_ID <= (select count(distinct city) from shipment_address);

SELECT @k:=0;
UPDATE SHIPMENT_ADDRESS_HT set Address_ID = CONCAT("S-",@k:=@k+1), Level = 1 WHERE SUBSTRING_INDEX(Address_ID, '-' , -1) > (select count(distinct city) from shipment_address)
AND SUBSTRING_INDEX(Address_ID,'-', -1) <= (select count(distinct city) +  count(distinct state) from shipment_address);

SELECT @l:=0;
UPDATE SHIPMENT_ADDRESS_HT set Address_ID = CONCAT("CO-",@l:=@l+1), Level = 2 WHERE SUBSTRING_INDEX(Address_ID,'-', -1) > (select count(distinct city) +  count(distinct state) from shipment_address)
AND SUBSTRING_INDEX(Address_ID,'-', -1) <= (select count(distinct city)+ count(distinct state) + count(distinct country) from shipment_address);

SELECT @n:=0;
UPDATE SHIPMENT_ADDRESS_HT set Address_ID = CONCAT("M-",@n:=@n+1), Level = 3 WHERE SUBSTRING_INDEX(Address_ID,'-', -1) > (select count(distinct city)+ count(distinct state) + count(distinct country) from shipment_address);

UPDATE SHIPMENT_ADDRESS_HT set Parent_ID = "null" WHERE SUBSTRING_INDEX(Address_ID,'-', 1) = 'M';

SELECT * FROM PRODUCT_DESCRIPTION_TEMP;

CREATE TABLE PRODUCT_DESCRIPTION_TEMP (Temp_Id varchar(10)) AS 
	SELECT DISTINCT Product_Name FROM PRODUCT_DESCRIPTION
	UNION ALL
	SELECT DISTINCT Sub_Category FROM PRODUCT_DESCRIPTION
    UNION ALL
    SELECT DISTINCT Category FROM PRODUCT_DESCRIPTION;
SELECT @i:=0;
UPDATE PRODUCT_DESCRIPTION_TEMP set Temp_Id = @i:=@i+1;
ALTER TABLE PRODUCT_DESCRIPTION_TEMP CHANGE `Product_Name` `Product` varchar(255);

SELECT @j:=0;
UPDATE PRODUCT_DESCRIPTION_TEMP set Temp_Id = CONCAT("P-",@j:=@j+1) WHERE Temp_Id <= (select count(distinct product_name) from product_description);

SELECT @k:=0;
UPDATE PRODUCT_DESCRIPTION_TEMP set Temp_Id = CONCAT("SC-",@k:=@k+1) WHERE SUBSTRING_INDEX(Temp_Id, '-' , -1) > (select count(distinct product_name) from product_description)
AND SUBSTRING_INDEX(Temp_Id,'-', -1) <= (select count(distinct product_name) +  count(distinct sub_category) from product_description);

SELECT @l:=0;
UPDATE PRODUCT_DESCRIPTION_TEMP set Temp_Id = CONCAT("C-",@l:=@l+1) WHERE SUBSTRING_INDEX(Temp_Id,'-', -1) > (select count(distinct product_name) +  count(distinct sub_category) from product_description)
AND SUBSTRING_INDEX(Temp_Id,'-', -1) <= (select count(distinct product_name)+ count(distinct sub_category) + count(distinct category) from product_description);

ALTER TABLE PRODUCT_DESCRIPTION_TEMP
  ADD Last_Update_Date timestamp default current_timestamp,
  ADD Action VARCHAR(2) default 'C',
  ADD Active VARCHAR(2) default 'Y';
  
  CREATE TABLE PRODUCT_DESCRIPTION_HT (Product_ID varchar(20)) AS
	SELECT distinct product_description.product_Name, product_description_temp.temp_id FROM product_description, product_description_temp WHERE
	product_description.sub_category = product_description_temp.product AND product_description_temp.temp_id LIKE 'sc%' 
    UNION ALL
    SELECT DISTINCT product_description.sub_category, product_description_temp.temp_id FROM product_description, product_description_temp WHERE product_description_temp.temp_Id LIKE 'c%' 
	AND product_description.category = product_description_temp.product
    UNION ALL
    SELECT DISTINCT product_description.category, product_description_temp.temp_id FROM product_description, product_description_temp WHERE product_description.category = product_description_temp.product;
SELECT @i:=0;
UPDATE PRODUCT_DESCRIPTION_HT set Product_ID = @i:=@i+1;
ALTER TABLE PRODUCT_DESCRIPTION_HT CHANGE `temp_id` `Parent_ID` varchar(255);
ALTER TABLE PRODUCT_DESCRIPTION_HT CHANGE `product_Name` `Product` varchar(255);

ALTER TABLE PRODUCT_DESCRIPTION_HT
  ADD Last_Update_Date timestamp default current_timestamp,
  ADD Action VARCHAR(2) default 'C',
  ADD Active VARCHAR(2) default 'Y',
  ADD Level int;
  
SELECT @j:=0;
UPDATE PRODUCT_DESCRIPTION_HT set Product_ID = CONCAT("P-",@j:=@j+1), Level=0 WHERE Product_ID <= (select count(distinct product_name) from product_description);

SELECT @k:=0;
UPDATE PRODUCT_DESCRIPTION_HT set Product_ID = CONCAT("SC-",@k:=@k+1), Level=1 WHERE SUBSTRING_INDEX(Product_ID, '-' , -1) > (select count(distinct product_name) from product_description)
AND SUBSTRING_INDEX(Product_ID,'-', -1) <= (select count(distinct product_name) +  count(distinct sub_category) from product_description);

SELECT @l:=0;
UPDATE PRODUCT_DESCRIPTION_HT set Product_ID = CONCAT("C-",@l:=@l+1), Level=2 WHERE SUBSTRING_INDEX(Product_ID,'-', -1) > (select count(distinct product_name) +  count(distinct sub_category) from product_description)
AND SUBSTRING_INDEX(Product_ID,'-', -1) <= (select count(distinct product_name)+ count(distinct sub_category) + count(distinct category) from product_description);

UPDATE PRODUCT_DESCRIPTION_HT set Parent_ID = "null" WHERE SUBSTRING_INDEX(Product_ID,'-', 1) = 'C';

SELECT * FROM product_description_ht;

select Address_ID, Parent_ID, Level from shipment_address_ht where Level = 3;
select * from shipment_address_grain;
SELECT * FROM temp1;

/*Grain for Shipment Address*/
DROP PROCEDURE IF EXISTS create_grain;
DELIMITER //
CREATE PROCEDURE create_grain(IN number_level int)
BEGIN
	DECLARE levels int;
    SET levels = 1;
    
    create table temp2 as
		select Address_ID, Parent_ID, Level from shipment_address_ht where Level = levels-1;
        
		 WHILE levels < number_level-1 DO
			drop table if exists temp1;
			create table temp1 as 
				select Address_ID, Parent_ID, Level from shipment_address_ht where Level = levels;
			
            drop table if exists shipment_address_grain;
			create table shipment_address_grain as 
				select * from temp2
				union
				select temp2.Address_ID, temp1.Parent_ID, temp1.Level from temp1, temp2 where temp1.Level = levels and temp1.Address_ID = temp2.Parent_ID;

			drop table if exists temp2;
            CREATE TABLE temp2 SELECT * FROM shipment_address_grain;
            
			set levels = levels + 1;
    
		END WHILE;
        
        SET SQL_SAFE_UPDATES = 0;
        SET levels = number_level-1;
		while levels > 0 do
			UPDATE shipment_address_grain set Level=levels WHERE Level = levels-1;
            set levels = levels - 1;
		end while;    
        
        ALTER TABLE shipment_address_grain CHANGE `Address_ID` `Lowest_Node` varchar(255);
		ALTER TABLE shipment_address_grain CHANGE `Parent_ID` `Top_Most` varchar(255);

        drop table temp2;
        drop table temp1;
        
END //
DELIMITER ;

/*Grain for Product*/
CALL create_grain((SELECT count(distinct level) from shipment_address_ht));
select * from product_description_grain;

SELECT count(distinct level) from temp2;
select * from shipment_address_ht;
select * from temp1;
select * from temp2;
select * from grain;
select temp2.Address_ID, temp1.Parent_ID from temp1, temp2 where temp1.Level = 1 and temp1.Address_ID = temp2.Parent_ID;

create table temp2 as
select Address_ID, Parent_ID, Level from shipment_address_ht where Level = 0;

create table temp1 as 
select Address_ID, Parent_ID, Level from shipment_address_ht where Level = 1;

Create table grain as 
		select * from temp2
		union
		select temp2.Address_ID, temp1.Parent_ID, temp1.Level from temp1, temp2 where temp2.Level = 1 and temp1.Address_ID = temp2.Parent_ID;
        
drop table temp2;

select * from PRODUCT_ORDERS;


DROP TABLE IF EXISTS time_dimension;
CREATE TABLE time_dimension(
		ID                 INTEGER PRIMARY KEY,  -- year*10000+month*100+day
        DB_Date                 DATE NOT NULL,
        Day_Desc				VARCHAR(50),
        Week_Desc				VARCHAR(50),
        Month_Desc				VARCHAR(50),
        Quarter_Desc			VARCHAR(50),
        Semi_Annual_Desc		VARCHAR(50),
        Year_Desc   			VARCHAR(50)
 
) Engine=MyISAM;

/*Time Dimension */
DROP PROCEDURE IF EXISTS fill_date_dimension;
DELIMITER //
CREATE PROCEDURE fill_date_dimension(IN startdate DATE,IN stopdate DATE)
BEGIN
    DECLARE currentdate DATE;
    SET currentdate = startdate;
    WHILE currentdate < stopdate DO
        INSERT INTO time_dimension VALUES (
                        YEAR(currentdate)*10000+MONTH(currentdate)*100 + DAY(currentdate),
                        currentdate,
                        DATE_FORMAT(currentdate,'%M %d %Y'),
						DATE_FORMAT(currentdate, 'Week %V of %X'),
                        DATE_FORMAT(currentdate, '%M %Y'),
                        CONCAT('Quarter ',CAST(QUARTER(currentdate) AS CHAR(1)),DATE_FORMAT(currentdate, ' of %Y')),
                        CASE QUARTER(currentdate) 
							WHEN 1 THEN CONCAT('1st Half of ', DATE_FORMAT(currentdate,'%Y')) 
							WHEN 2 THEN CONCAT('1st Half of ', DATE_FORMAT(currentdate,'%Y'))  
							WHEN 3 THEN CONCAT('2nd Half of ', DATE_FORMAT(currentdate,'%Y')) 
							WHEN 4 THEN CONCAT('2nd Half of ', DATE_FORMAT(currentdate,'%Y')) 
                        END,
                        DATE_FORMAT(currentdate,'Year %Y')
                        );
        SET currentdate = ADDDATE(currentdate,INTERVAL 1 DAY);
    END WHILE;
END
//
DELIMITER ;

CALL fill_date_dimension('2014-01-01','2016-01-01');
OPTIMIZE TABLE time_dimension;

select * from time_dimension;

DROP TABLE IF EXISTS date_temp;
CREATE TABLE date_temp AS
	SELECT Day_Desc, DB_Date FROM time_dimension
    UNION ALL
    SELECT DISTINCT Week_Desc, DB_Date FROM time_dimension
    UNION ALL
    SELECT DISTINCT Month_Desc, DB_Date FROM time_dimension
    UNION ALL
    SELECT DISTINCT Quarter_Desc, DB_Date FROM time_dimension
    UNION ALL
    SELECT DISTINCT Semi_Annual_Desc, DB_Date FROM time_dimension
    UNION ALL
    SELECT DISTINCT Year_Desc, DB_Date FROM time_dimension;

ALTER TABLE date_temp CHANGE `Day_Desc` `Date_Desc` varchar(255);

DROP TABLE IF EXISTS time_temp;
CREATE TABLE Time_temp(Temp_ID VARCHAR(10)) AS 
	SELECT Day_Desc FROM time_dimension
    UNION ALL
    SELECT DISTINCT Week_Desc FROM time_dimension
    UNION ALL
    SELECT DISTINCT Month_Desc FROM time_dimension
    UNION ALL
    SELECT DISTINCT Quarter_Desc FROM time_dimension
    UNION ALL
    SELECT DISTINCT Semi_Annual_Desc FROM time_dimension
    UNION ALL
    SELECT DISTINCT Year_Desc FROM time_dimension;

SELECT @a:=0;
UPDATE Time_temp set Temp_ID = @a:=@a+1;
ALTER TABLE Time_temp CHANGE `Day_Desc` `Time_Desc` varchar(255);

SELECT @b:=0;
UPDATE Time_temp 
	SET Temp_ID = CONCAT("D-", @b:=@b+1)
    WHERE Temp_ID <= (SELECT COUNT(Day_Desc) FROM time_dimension);

SELECT @c:=0;
UPDATE Time_temp 
	SET Temp_ID = CONCAT("W-", @c:=@c+1)
    WHERE SUBSTRING_INDEX(Temp_ID, '-', -1) > (SELECT COUNT(Day_Desc) FROM time_dimension)
	AND SUBSTRING_INDEX(Temp_ID, '-', -1) <= ((SELECT COUNT(Day_Desc) + COUNT(DISTINCT Week_Desc) FROM time_dimension));

SELECT @d:=0;
UPDATE Time_temp 
	SET Temp_ID = CONCAT("M-", @d:=@d+1)
    WHERE SUBSTRING_INDEX(Temp_ID, '-', -1) > (SELECT COUNT(Day_Desc) + COUNT(DISTINCT Week_Desc) FROM time_dimension)
	AND SUBSTRING_INDEX(Temp_ID, '-', -1) <= (SELECT COUNT(Day_Desc) + COUNT(DISTINCT Week_Desc) + COUNT(DISTINCT Month_Desc) FROM time_dimension);

SELECT @e:=0;
UPDATE Time_temp 
	SET Temp_ID = CONCAT("Q-", @e:=@e+1)
    WHERE SUBSTRING_INDEX(Temp_ID, '-', -1) > (SELECT COUNT(Day_Desc) + COUNT(DISTINCT Week_Desc) + COUNT(DISTINCT Month_Desc) FROM time_dimension)
	AND SUBSTRING_INDEX(Temp_ID, '-', -1) <= (SELECT COUNT(Day_Desc) + COUNT(DISTINCT Week_Desc) + COUNT(DISTINCT Month_Desc) + COUNT(DISTINCT Quarter_Desc) FROM time_dimension);

SELECT @f:=0;
UPDATE Time_temp 
	SET Temp_ID = CONCAT("SA-", @f:=@f+1)
	WHERE SUBSTRING_INDEX(Temp_ID, '-', -1) > (SELECT COUNT(Day_Desc) + COUNT(DISTINCT Week_Desc) + COUNT(DISTINCT Month_Desc) + COUNT(DISTINCT Quarter_Desc) FROM time_dimension)
	AND SUBSTRING_INDEX(Temp_ID, '-', -1) <= (SELECT COUNT(Day_Desc) + COUNT(DISTINCT Week_Desc) + COUNT(DISTINCT Month_Desc) + COUNT(DISTINCT Quarter_Desc) + COUNT(DISTINCT Semi_Annual_Desc) FROM time_dimension);

SELECT @g:=0;
UPDATE Time_temp 
	SET Temp_ID = CONCAT("Y-",@g:=@g+1)
	WHERE SUBSTRING_INDEX(Temp_ID,'-', -1) > (select COUNT(Day_Desc) + COUNT(DISTINCT Week_Desc) + COUNT(DISTINCT Month_Desc) + COUNT(DISTINCT Quarter_Desc) + COUNT(DISTINCT Semi_Annual_Desc) from time_dimension);

DROP TABLE IF EXISTS Date_Final_Temp;
CREATE TABLE Date_Final_Temp AS
	SELECT * FROM time_temp
	LEFT JOIN date_temp ON time_temp.Time_Desc = date_temp.Date_Desc
	UNION
	SELECT * FROM time_temp
	RIGHT JOIN date_temp ON time_temp.Time_Desc = date_temp.Date_Desc;
    
ALTER TABLE Date_Final_Temp DROP COLUMN Date_Desc;

DROP TABLE IF EXISTS Time_HT;
CREATE TABLE Time_HT(Table_ID INT, Time_ID VARCHAR(10), Level INT) AS
	SELECT DISTINCT time_dimension.DB_Date, Date_Final_Temp.Temp_ID, time_dimension.Day_Desc FROM Date_Final_Temp LEFT JOIN time_dimension ON 
	time_dimension.Week_Desc = Date_Final_Temp.Time_Desc where Date_Final_Temp.Temp_ID LIKE 'W%'
    UNION ALL
    SELECT DISTINCT time_dimension.DB_Date, Date_Final_Temp.Temp_ID, time_dimension.Day_Desc FROM Date_Final_Temp LEFT JOIN time_dimension ON 
	time_dimension.Month_Desc = Date_Final_Temp.Time_Desc where Date_Final_Temp.Temp_ID LIKE 'M%'
    UNION ALL
	SELECT DISTINCT time_dimension.DB_Date, Date_Final_Temp.Temp_ID, time_dimension.Week_Desc from Date_Final_Temp LEFT JOIN time_dimension ON
    time_dimension.Quarter_Desc = Date_Final_Temp.Time_Desc WHERE Date_Final_Temp.Temp_ID LIKE 'Q%'
    UNION ALL
    SELECT DISTINCT time_dimension.DB_Date, Date_Final_Temp.Temp_ID, time_dimension.Month_Desc FROM Date_Final_Temp LEFT JOIN time_dimension ON
    time_dimension.Quarter_Desc = Date_Final_Temp.Time_Desc WHERE Date_Final_Temp.Temp_ID LIKE 'Q%'
    UNION ALL
    SELECT DISTINCT time_dimension.DB_Date, Date_Final_Temp.Temp_ID, time_dimension.Quarter_Desc FROM Date_Final_Temp LEFT JOIN time_dimension ON
    time_dimension.Semi_Annual_Desc = Date_Final_Temp.Time_Desc WHERE Date_Final_Temp.Temp_ID LIKE 'S%'
    UNION ALL
    SELECT DISTINCT time_dimension.DB_Date, Date_Final_Temp.Temp_ID, time_dimension.Semi_Annual_Desc FROM Date_Final_Temp LEFT JOIN time_dimension ON
    time_dimension.Year_Desc = Date_Final_Temp.Time_Desc WHERE Date_Final_Temp.Temp_ID LIKE 'Y%'
    UNION ALL
    SELECT DISTINCT time_dimension.DB_Date, Date_Final_Temp.Temp_ID, time_dimension.Year_Desc FROM Date_Final_Temp,time_dimension
    WHERE time_dimension.Year_Desc = Date_Final_Temp.Time_Desc;

SELECT @i:=0;
UPDATE time_ht set Table_ID = @i:=@i+1;
UPDATE time_ht set Temp_ID = NULL WHERE Table_ID > 4380;

SELECT @a:=0;
UPDATE Time_ht set Time_ID = @a:=@a+1;

SELECT @b:=0;
UPDATE Time_ht 
	SET Level = 0
    WHERE Time_ID <= (SELECT COUNT(Day_Desc) FROM time_dimension);

SELECT @c:=0;
UPDATE Time_ht 
	SET Level = 0
    WHERE SUBSTRING_INDEX(Time_ID, '-', -1) > (SELECT COUNT(Day_Desc) FROM time_dimension)
	AND SUBSTRING_INDEX(Time_ID, '-', -1) <= ((SELECT COUNT(Day_Desc) + COUNT(Day_Desc) FROM time_dimension));

SELECT @d:=0;
UPDATE Time_ht 
	SET Level = 1
    WHERE SUBSTRING_INDEX(Time_ID, '-', -1) > (SELECT COUNT(Day_Desc) + COUNT(Day_Desc) FROM time_dimension)
	AND SUBSTRING_INDEX(Time_ID, '-', -1) <= ((SELECT COUNT(Day_Desc) + COUNT(Day_Desc) + COUNT(Week_Desc) FROM time_dimension));

SELECT @e:=0;
UPDATE Time_ht 
	SET Level = 1
    WHERE SUBSTRING_INDEX(Time_ID, '-', -1) > (SELECT COUNT(Day_Desc) + COUNT(Day_Desc) + COUNT(Week_Desc) FROM time_dimension)
	AND SUBSTRING_INDEX(Time_ID, '-', -1) <= (SELECT COUNT(Day_Desc) + COUNT(Day_Desc) + COUNT(Week_Desc) + COUNT(Month_Desc) FROM time_dimension);

SELECT @f:=0;
UPDATE Time_ht
	SET Level = 2
    WHERE SUBSTRING_INDEX(Time_ID, '-', -1) > (SELECT COUNT(Day_Desc) + COUNT(Day_Desc) + COUNT(Week_Desc) + COUNT(Month_Desc) FROM time_dimension)
	AND SUBSTRING_INDEX(Time_ID, '-', -1) <= (SELECT COUNT(Day_Desc) + COUNT(Day_Desc) + COUNT(Week_Desc) + COUNT(Month_Desc) + COUNT(Quarter_Desc) FROM time_dimension);

SELECT @g:=0;
UPDATE Time_ht
	SET Level = 3
	WHERE SUBSTRING_INDEX(Time_ID, '-', -1) > (SELECT COUNT(Day_Desc) + COUNT(Day_Desc) + COUNT(Week_Desc) + COUNT(Month_Desc) + COUNT(Quarter_Desc) FROM time_dimension)
	AND SUBSTRING_INDEX(Time_ID, '-', -1) <= (SELECT COUNT(Day_Desc) + COUNT(Day_Desc) + COUNT(Week_Desc) + COUNT(Month_Desc) + COUNT(Quarter_Desc) + COUNT(Semi_Annual_Desc) FROM time_dimension);

SELECT @h:=0;
UPDATE Time_ht 
	SET Level = 4
	WHERE SUBSTRING_INDEX(Time_ID,'-', -1) > (select COUNT(Day_Desc) + COUNT(Day_Desc) + COUNT(Week_Desc) + COUNT(Month_Desc) + COUNT(Quarter_Desc) + COUNT(Semi_Annual_Desc) from time_dimension);

ALTER TABLE time_ht CHANGE `temp_id` `Parent_ID` varchar(255);
ALTER TABLE time_ht CHANGE `DB_DATE` `Date_Stamp` varchar(255);
ALTER TABLE time_ht DROP COLUMN Time_ID;

DROP TABLE IF EXISTS DATE_HT;
CREATE TABLE DATE_HT AS
	SELECT * FROM time_ht
	LEFT JOIN date_final_temp ON time_ht.Day_Desc = date_final_temp.Time_Desc
    ORDER BY time_ht.Table_ID;

ALTER TABLE DATE_HT DROP COLUMN Time_Desc;
ALTER TABLE DATE_HT DROP COLUMN DB_Date;
ALTER TABLE date_ht CHANGE `temp_id` `Date_ID` varchar(255);
ALTER TABLE Date_HT
  ADD Last_Update_Date timestamp default current_timestamp,
  ADD Action VARCHAR(2) default 'C',
  ADD Active VARCHAR(2) default 'Y';
  
/*Time Grain*/
-- GRAIN TABLE

DROP PROCEDURE IF EXISTS create_time_grain;
DELIMITER //
CREATE PROCEDURE create_time_grain(IN number_level int)
BEGIN
	DECLARE levels int;
    SET levels = 1;
    
    create table temp2 as
		select Date_ID, Parent_ID, Level from date_ht where Level = levels-1;
        
		 WHILE levels < number_level-1 DO
			drop table if exists temp1;
			create table temp1 as 
				select Date_ID, Parent_ID, Level from date_ht where Level = levels;
			
            drop table if exists time_grain;
			create table time_grain as 
				select * from temp2
				union
				select temp2.Date_ID, temp1.Parent_ID, temp1.Level from temp1, temp2 where temp1.Level = levels and temp1.Date_ID = temp2.Parent_ID;

			drop table if exists temp2;
            CREATE TABLE temp2 SELECT * FROM time_grain;
			set levels = levels + 1;
		END WHILE;
        
        SET SQL_SAFE_UPDATES = 0;
        SET levels = number_level-1;
		while levels > 0 do
			UPDATE time_grain set Level=levels WHERE Level = levels-1;
            set levels = levels - 1;
		end while;    
        
        ALTER TABLE time_grain CHANGE `Date_ID` `Lowest_Node` varchar(255);
		ALTER TABLE time_grain CHANGE `Parent_ID` `Top_Most` varchar(255);

        drop table temp2;
        drop table temp1;
        
END //
DELIMITER ;
CALL create_time_grain((SELECT count(distinct level) from date_ht));

select * from date_ht;

/****************** DIMENSIONS *********************/
select * from customer_personal_info_periodic;
select * from product_description_periodic where Product_ID = 'TEC-PH-3148';
select * from global_superstore_data;
select * from product_description_ht;
select * from product_description_periodic;
select * from time_ht;
SELECT * FROM product_sales;

-- 1 Customer --
CREATE TABLE customer_dimension (Mapping_ID varchar(20)) AS
	SELECT G.Order_ID, A.* FROM customer_personal_info_periodic A, global_superstore_data G WHERE A.Customer_ID = G.Customer_ID;
SELECT @j:=0;
UPDATE customer_dimension set Mapping_ID = CONCAT("TCus-",@j:=@j+1);
select * from customer_dimension;

-- 2 Product --
CREATE TABLE product_dimension (Mapping_ID varchar(20)) AS
	SELECT G.Order_ID, A.* FROM product_description_ht A, global_superstore_data G WHERE A.Level = 0 AND A.Product = G.Product_Name;
SELECT @j:=0;
UPDATE product_dimension set Mapping_ID = CONCAT("TProd-",@j:=@j+1);
select * from product_dimension;

-- 3 Shipment Address --
CREATE TABLE shipment_address_dimension (Mapping_ID varchar(20)) AS
	SELECT G.Order_ID, S.Postal_Code, A.* FROM shipment_address_ht A, global_superstore_data G, shipment_address S WHERE A.Level = 0 AND A.Address = G.City AND S.Order_ID = G.Order_ID;
SELECT @j:=0;
UPDATE shipment_address_dimension set Mapping_ID = CONCAT("TAdd-",@j:=@j+1);
select * from shipment_address_dimension;

-- 4 Order Date --
CREATE TABLE order_date_dimension (Mapping_ID varchar(20)) AS
	SELECT G.Order_ID, A.Date_Stamp, A.Day_Desc, A.Parent_ID, A.Level FROM time_ht A, global_superstore_data G WHERE A.Level = 0 AND SUBSTRING_INDEX(A.Parent_ID,'-', 1) = 'M' AND A.Date_Stamp = G.Order_Date;
SELECT @j:=0;
UPDATE order_date_dimension set Mapping_ID = CONCAT("TODate-",@j:=@j+1);
select * from order_date_dimension;

-- 5 Shipment Date --
CREATE TABLE shipment_date_dimension (Mapping_ID varchar(20)) AS
	SELECT G.Order_ID, A.Date_Stamp, A.Day_Desc, A.Parent_ID, A.Level FROM time_ht A, global_superstore_data G WHERE A.Level = 0 AND SUBSTRING_INDEX(A.Parent_ID,'-', 1) = 'M' AND A.Date_Stamp = G.Ship_Date;
SELECT @j:=0;
UPDATE shipment_date_dimension set Mapping_ID = CONCAT("TSDate-",@j:=@j+1);
select * from shipment_date_dimension;

-- mapping table --
CREATE TABLE mapping_table AS
	SELECT DISTINCT(Z.Order_ID), A.Customer_ID, B.Product_ID, C.Address_ID, D.Date_Stamp AS 'Order_Date', E.Date_Stamp AS 'Ship_Date'
			FROM product_orders Z, customer_dimension A, product_dimension B, shipment_address_dimension C, order_date_dimension D, shipment_date_dimension E
			WHERE Z.Order_ID = A.Order_ID AND Z.Order_ID = B.Order_ID AND Z.Order_ID = C.Order_ID AND Z.Order_ID = D.Order_ID AND Z.Order_ID = E.Order_ID;
            
-- pre fact table --
CREATE TABLE prefactable_orders (Row_ID varchar(20))AS
	SELECT A.*, B.Quantity, B.Shipping_Cost, B.Sales, B.Discount, B.Profit
	FROM mapping_table A,
	(SELECT G.Order_ID, A.Product_ID, G.Ship_Mode, G.Order_Priority, G.Quantity, G.Shipping_Cost, G.Sales, G.Discount, G.Profit FROM 
	product_description_ht A, global_superstore_data G WHERE A.Level = 0 AND A.Product = G.Product_Name) B
	WHERE A.Order_ID = B.Order_ID AND A.Product_ID = B.Product_ID;
SELECT @j:=0;
UPDATE prefactable_orders set Row_ID = CONCAT("GS-",@j:=@j+1);
select * from prefactable_orders;

-- fact table --
CREATE TABLE factable_orders (Row_ID varchar(20)) AS
	SELECT distinct PF.Order_ID, PF.Order_Date, PF.Ship_Date,
	PF.Customer_ID, CD.First_Name, CD.Last_Name, CD.Segment,
	PF.Address_ID, AD.Postal_Code, AD.Address as 'Address', AHT.Address as 'Address_Parent',
	PF.Product_ID, PD.Product as 'Product Description', PHT.Product as 'Product_Parent',
	PF.Quantity, PF.Shipping_Cost, PF.Sales, PF.Discount, PF.Profit
	FROM prefactable_orders PF, product_dimension PD, customer_dimension CD, shipment_address_dimension AD, product_description_ht PHT, shipment_address_ht AHT
	WHERE PF.Product_ID = PD.Product_ID AND PF.Order_ID = PD.Order_ID AND PD.Parent_ID = PHT.Product_ID
	AND PF.Customer_ID = CD.Customer_ID AND PF.Order_ID = CD.Order_ID
	AND PF.Address_ID = AD.Address_ID AND PF.Order_ID = AD.Order_ID AND AD.Parent_ID = AHT.Address_ID;
SELECT @j:=0;
UPDATE factable_orders set Row_ID = CONCAT("GS-",@j:=@j+1);
select * from factable_orders;

select * from shipment_address;
select distinct * from shipment_address WHERE Market = 'USCA' AND Country = 'United States';

/*********** Data Mart **********/
-- Sales Data Mart

DROP TABLE IF EXISTS sales_mv;
CREATE TABLE sales_mv(
	Month VARCHAR(150),
    Total_Sales FLOAT
);

INSERT INTO sales_mv
	SELECT MONTHNAME(order_date),
    AVG(sales)
    FROM factable_orders
    GROUP BY MONTHNAME(order_date)
    ORDER BY MONTH(order_date) ASC;
    
select * from sales_mv;

-- Refresh Procedure
DROP PROCEDURE IF EXISTS refresh_sales_mv;

DELIMITER $$
CREATE PROCEDURE refresh_sales_mv(
	OUT rc INT
)
BEGIN
	TRUNCATE TABLE sales_mv;
    
    INSERT INTO sales_mv
		SELECT MONTHNAME(order_date),
		AVG(sales)
		FROM factable_orders
		GROUP BY MONTHNAME(order_date)
		ORDER BY MONTH(order_date) ASC;
        
	SET rc = 0;
END;
$$

DELIMITER ;

INSERT INTO factable_orders VALUES
(	'GS-101',
	'IN-2014-KA1652592-41642',
    '2014-01-01', -- Order date
    '2014-01-04',
    'KK-1652592',
    'Mickey',
    'Mouse',
    'Consumer',
    'C-80',
    'Christchurch',
    'Canterbury',
    'P-95',
    'Samsung Headset, with Caller ID',
    'Phones',
    4,
    18.93,
    1000, -- Sales
    0,
    20.4
);

CALL refresh_sales_mv(@rc);
select * from sales_mv;
    
-- Products Data Mart

DROP TABLE IF EXISTS products_mv;
CREATE TABLE products_mv(
	Product VARCHAR(150),
    Quantity INT
);

INSERT INTO products_mv
	SELECT product_parent,
    AVG(Quantity)
    FROM factable_orders
    GROUP BY product_parent
    ORDER BY AVG(Quantity) ASC;
    
select * from products_mv;

-- Refresh Procedure
DROP PROCEDURE IF EXISTS refresh_products_mv;

DELIMITER $$
CREATE PROCEDURE refresh_products_mv(
	OUT rc INT
)
BEGIN
	TRUNCATE TABLE products_mv;
    
    INSERT INTO products_mv
		SELECT product_parent,
    AVG(Quantity)
    FROM factable_orders
    GROUP BY product_parent
    ORDER BY AVG(Quantity) ASC;
        
	SET rc = 0;
END;
$$

DELIMITER ;

INSERT INTO factable_orders VALUES
(	'GS-101',
	'IN-2014-KA1652592-41642',
    '2014-01-01', 
    '2014-01-04',
    'KK-1652592',
    'Mickey',
    'Mouse',
    'Consumer',
    'C-80',
    'Christchurch',
    'Canterbury',
    'P-95',
    'Smead Lockers, Industrial',
    'Storage', -- Product Parent
    10, -- Quantity
    18.93,
    1000,
    0,
    20.4
);

CALL refresh_products_mv(@rc);
select * from products_mv;

-- Customers Data Mart

DROP TABLE IF EXISTS customers_mv;
CREATE TABLE customers_mv(
	Segment VARCHAR(150),
    Total_Sales INT
);

INSERT INTO customers_mv
	SELECT Segment,
    AVG(Sales)
    FROM factable_orders
    GROUP BY Segment
    ORDER BY AVG(Sales) ASC;
    
select * from customers_mv;

-- Refresh Procedure
DROP PROCEDURE IF EXISTS refresh_products_mv;

DELIMITER $$
CREATE PROCEDURE refresh_customers_mv(
	OUT rc INT
)
BEGIN
	TRUNCATE TABLE customers_mv;
    
    INSERT INTO customers_mv
		SELECT Segment,
		AVG(Sales)
		FROM factable_orders
		GROUP BY Segment
		ORDER BY AVG(Sales) ASC;
        
	SET rc = 0;
END;
$$

DELIMITER ;

INSERT INTO factable_orders VALUES
(	'GS-101',
	'IN-2014-KA1652592-41642',
    '2014-01-01', 
    '2014-01-04',
    'KK-1652592',
    'Mickey',
    'Mouse',
    'Corporate', -- Segment
    'C-80',
    'Christchurch',
    'Canterbury',
    'P-95',
    'Smead Lockers, Industrial',
    'Storage', 
    10, 
    18.93,
    15000, -- sales
    0,
    20.4
);

CALL refresh_customers_mv(@rc);
select * from customers_mv;

-- !!! delete the added dummy values
 DELETE FROM factable_orders WHERE Order_Id = 'IN-2014-KA1652592-41642';
 
 select * from factable_orders;
 
 select * from product_description_ht
 
select A.Parent_ID, A.Product, B.Product_ID as Parent_ID, B.Product as Parent from product_description_ht A, product_description_ht B WHERE A.Parent_ID = 'C-1' AND A.Parent_ID = B.Product_ID 

select A.Product_ID, A.Product, B.Product_ID as Parent_ID, B.Product as Parent, C.Product_ID as Parent_Parent_ID, C.Product as Parent_Parent from product_description_ht A, product_description_ht B, product_description_ht C WHERE A.Parent_ID = B.Product_ID AND B.Parent_ID = C.Product_ID AND C.Product_ID = 'C-1'

select C.Product_ID as Parentest_ID, C.Product as Parentest, B.Product_ID as Parent_ID, B.Product as Parent, A.Product_ID, A.Product 
from product_description_ht A, product_description_ht B, product_description_ht C 
WHERE A.Parent_ID = B.Product_ID AND B.Parent_ID = C.Product_ID AND C.Product_ID = 'C-1'

-- TOP 3 LOC PER MONTH IN TERMS OF SALES

select * from factable_orders;

SELECT MONTHNAME(Order_Date) AS Month,
	Address_Parent AS Location,
    SUM(sales) AS Sales
    FROM factable_orders
    -- GROUP BY MONTHNAME(Order_date)
    GROUP BY Location
    ORDER BY MONTH(order_date), Location;


SELECT yes.month, yes.location, yes.sales FROM (
SELECT MONTH(Order_Date) AS Month_Num,
	MONTHNAME(Order_Date) AS Month,
	Address_Parent AS Location,
    SUM(sales) AS Sales,
    row_number() OVER (PARTITION BY MONTHNAME(Order_date) ORDER BY SUM(Sales) DESC) as rownum
    FROM factable_orders
    -- GROUP BY MONTHNAME(Order_date)
    GROUP BY Location
    ORDER BY SUM(Sales) DESC
    ) yes
    WHERE rownum <=3
    -- GROUP BY yes.Month
    ORDER BY yes.Month_Num, yes.rownum;
    
    SELECT
		Address_Parent as Location,
        SUM(Sales) as Sales
	FROM factable_orders
    WHERE Month(order_date) BETWEEN 1 and 12
    Group by Address_Parent
    Order by 2 DESC
    limit 10
