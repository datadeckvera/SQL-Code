/*

Cleaning Data in SQL Queries

Skills Used: Convert Data Type, Populate Data, Case Statements, Delete Columns, Alter Table, Update Table,
Remove Duplicates, JOIN, ISNULL, SUBSTRING, CHARINDEX, PARSENAME, DISTINCT, ROW_NUMBER, PARTITION BY

*/

SELECT *
FROM NashvilleHousing

-------------------------------------------------------------------------------------------------

-- Standardize Date Format in 'SaleDate' Field

--- change from DateTime to Date format
SELECT SaleDate, CONVERT(DATE, SaleDate)
FROM NashvilleHousing

ALTER TABLE NashvilleHousing 
ADD SaleDateConverted DATE;

UPDATE NashvilleHousing 
SET SaleDateConverted = CONVERT(DATE, SaleDate)

--- check that the converted field matches the previous SaleDate field
SELECT SaleDateConverted, CONVERT(DATE, SaleDate)
FROM NashvilleHousing



-------------------------------------------------------------------------------------------------

-- Populate 'PropertyAddress' Data

--- find null rows

SELECT *
FROM NashvilleHousing
WHERE PropertyAddress IS NULL

--- populate address with reference point data
---- each ParcelID is unique to its PropertyAddress, so use IDs to populate missing addresses
------ order by ParcelID to note the relationship between this field and PropertyAddress

SELECT *
FROM NashvilleHousing
ORDER BY ParcelID

--- code logic; 
---- for ParcelIDs that have PropertyAddress data, find rows where the PropertyAddress field is null
----- and populate the null fields with the known PropertyAddress data for that ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM NashvilleHousing AS a
JOIN NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]  --prevents joining exact same rows to each other
WHERE a.PropertyAddress IS NULL --see only the previously null PropertyAddress rows

------ now populate the null PropertyAddress rows with the output from b.PropertyAddress above

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing AS a
JOIN NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]  
WHERE a.PropertyAddress IS NULL

UPDATE a   --due to the self join, use alias to specify the table to update
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing AS a
JOIN NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]  
WHERE a.PropertyAddress IS NULL

--- after update, run the previous query to check for null values. There should be none.



----------------------------------------------------------------------------------------------------

-- Breaking Out Address Into Individual Columns (Address, City, State)

--- notice that address and city are both in the PropertyAddress field
---- comma used as the delimiter/separator between address and city

SELECT PropertyAddress
FROM NashvilleHousing

--- separate the address and city using substring and character index (CHARINDEX)

--- code logic; 
---- in each row of PropertyAddress field, return string values from 1st character to where comma (,) occurs 

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)) AS Address  
FROM NashvilleHousing

--- find out what position (e.g. 1st or 15th character) the comma is in the string for each row

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)) AS Address,  
	CHARINDEX(',', PropertyAddress)
FROM NashvilleHousing

--- remove the comma from the Address string values
---- -1 in code instructs that we go to the comma and then one step back from the comma

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) AS Address  
FROM NashvilleHousing

--- separate city from PropertyAddress
---- +1 in code instructs that we go to the comma and then one step forward from the comma

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) AS Address,  
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM NashvilleHousing

--- create new columns in the table for the separated Address and City outputs

ALTER TABLE NashvilleHousing 
ADD PropertySplitAddress NVARCHAR(255);

UPDATE NashvilleHousing 
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )


ALTER TABLE NashvilleHousing 
ADD PropertySplitCity NVARCHAR(255);

UPDATE NashvilleHousing 
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

--- view the two new fields

SELECT *
FROM NashvilleHousing



--- separate owner address, city and state code from OwnerAddress field

SELECT OwnerAddress
FROM NashvilleHousing

--- alternative to substring method; use PARSENAME to separate by delimiter
---- this function only looks for periods so we replace the comma delimiter with periods

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Address,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS City,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS State
FROM NashvilleHousing

--- Create new columns in table for the separated Owner Address outputs

ALTER TABLE NashvilleHousing 
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE NashvilleHousing 
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)


ALTER TABLE NashvilleHousing 
ADD OwnerSplitCity NVARCHAR(255);

UPDATE NashvilleHousing 
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)


ALTER TABLE NashvilleHousing 
ADD OwnerSplitState NVARCHAR(255);

UPDATE NashvilleHousing 
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)




----------------------------------------------------------------------------------------------------------

--- Change Y and N to Yes and No in "Sold as Vacant" Field
---- check for unique values and how many rows have each value

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

--- Yes and No are more popular than Y and N in the field so change Y to Yes and N to No

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END 
FROM NashvilleHousing


--- Update the SoldAsVacant Field in table
---- after executing query, rerun the initial DISTINCT query to check that the update worked

UPDATE NashvilleHousing 
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END


----------------------------------------------------------------------------------------------------------

--- Remove Duplicates

--- not standard practice to delete data in your database, best put the removed duplicates in a temp table.

--- use windows functions to find where there are duplicate values

SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
	ORDER BY UniqueID
	) AS row_num
FROM NashvilleHousing
ORDER BY ParcelID

--- put in a CTE so we can order the row_num to see where there is a duplicate (row_num > 1)

WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
	ORDER BY UniqueID
	) AS row_num
FROM NashvilleHousing
)

SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

--- to delete the duplicates, change the SELECT query after the CTE to DELETE

WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
	ORDER BY UniqueID
	) AS row_num
FROM NashvilleHousing
)

DELETE
FROM RowNumCTE
WHERE row_num > 1

--- re-run the previous SELECT query with the CTE to check if the duplicates deletion worked.


----------------------------------------------------------------------------------------------------------

--- Delete Unused Columns

--- don't do this to raw data; best for when creating a view to remove unwanted columns

SELECT *
FROM NashvilleHousing


ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress, SaleDate

