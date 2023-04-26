--Cleaning Data in SQL Queries

SELECT *
FROM dbo.NashvilleHousing

--Standardize Date Format
--Sale date column is formatted as datetime..we dont need the time so we are going to add a column that is just the date


ALTER TABLE dbo.NashvilleHousing
ADD SaleDateConverted Date

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(date, SaleDate)

SELECT *
FROM dbo.NashvilleHousing
-------------------------------------------------------------------------------------------------------------------------------------

--Populate Addresses in NULL spaces

SELECT PropertyAddress
FROM dbo.NashvilleHousing

--Check for nulls

SELECT PropertyAddress
FROM dbo.NashvilleHousing
WHERE PropertyAddress IS NULL

--why are there NULL values for the property address and how do we fix it?
SELECT *
FROM dbo.NashvilleHousing
ORDER BY ParcelID

--we can see that the ParcelIDs match the addresses
--to fix, we will do a self join because we need to say if the parcelID equals a certain address then populate the null with that address


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM dbo.NashvilleHousing a
JOIN dbo.NashvilleHousing b
  ON a.ParcelID = b.ParcelID
  AND a.[UniqueID ] <> b.[UniqueID ]
  WHERE a.PropertyAddress IS NULL

  --this shows the correct address with the nulls

  SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM dbo.NashvilleHousing a
JOIN dbo.NashvilleHousing b
  ON a.ParcelID = b.ParcelID
  AND a.[UniqueID ] <> b.[UniqueID ]
  WHERE a.PropertyAddress IS NULL

  --now we have a new column with the address populated

  UPDATE a
 SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
 FROM dbo.NashvilleHousing a
JOIN dbo.NashvilleHousing b
  ON a.ParcelID = b.ParcelID
  AND a.[UniqueID ] <> b.[UniqueID ]
   WHERE a.PropertyAddress IS NULL

--now when we run the previous query we can see there are no longer any null values for the property address, they have been filled.
--ISNULL willcheck to see if the value is null, and if it is, replace it with whatever you input

SELECT PropertyAddress
FROM dbo.NashvilleHousing
WHERE PropertyAddress IS NULL

---------------------------------------------------------------------------------------------------------------------------------------------

--Breaking out the address field into individual columns for address, city, state

SELECT PropertyAddress
FROM dbo.NashvilleHousing

--we can see that the city is included with the address
--going to use a SUBSTRING 

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)) AS Address
FROM dbo.NashvilleHousing

--this query includes the comma, which we dont want

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS Address

FROM dbo.NashvilleHousing

--use the -1 to exclude the comma from the first part and +1 to exclude it from the second part, LEN means go to the end of PropertyAddress because they are
--all different lengths.
--Now we need to alter the table to add the new separated address columns

ALTER TABLE dbo.NashvilleHousing
ADD PropertyStreetAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertyStreetAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE dbo.NashvilleHousing
ADD PropertyCity NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

SELECT *
FROM dbo.NashvilleHousing;

--Now we have the new columns added which are much more usable for querying.

--Next, we are going to split the OwnerAddress column a different way using PARSENAME.

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM dbo.NashvilleHousing;

--this separates the state off

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
FROM dbo.NashvilleHousing;

--this splits it all, but reversed, STATE, then city, then address

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM dbo.NashvilleHousing;

--now it is in order and we can alter the table to add the columns

ALTER TABLE dbo.NashvilleHousing
ADD OwnerStreetAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerStreetAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE dbo.NashvilleHousing
ADD OwnerCity NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)


ALTER TABLE dbo.NashvilleHousing
ADD OwnerState NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

--check to make sure they are there

SELECT * 
FROM dbo.NashvilleHousing;

---------------------------------------------------------------------------------------------------------------------------------

--Change Y and N to Yes and No in SoldAsVacant column so they are all the same

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;

--this shows Yes and No are more used than Y and N so we are going to change it all to that.

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
     WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
FROM dbo.NashvilleHousing;

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
     WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END

	 --now the columns are updated
----------------------------------------------------------------------------------------------------------------------------

--Remove Duplicates (Typically you would write a temp table with remove dups in it instead of deleting data from the actual database)


WITH RowNumCTE AS (
SELECT * ,
  ROW_NUMBER() OVER (
  PARTITION BY ParcelId,
               PropertyAddress,
			   SalePrice,
			   SaleDate,
			   LegalReference
			   ORDER BY 
			   UniqueID) row_num
FROM dbo.NashvilleHousing
--ORDER BY ParcelID
)

SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;

--now we can see the duplicate columns 

WITH RowNumCTE AS (
SELECT * ,
  ROW_NUMBER() OVER (
  PARTITION BY ParcelId,
               PropertyAddress,
			   SalePrice,
			   SaleDate,
			   LegalReference
			   ORDER BY 
			   UniqueID) row_num
FROM dbo.NashvilleHousing
--ORDER BY ParcelID
)

DELETE
FROM RowNumCTE
WHERE row_num > 1
;

--Now the duplicates are gone from the dataset

-------------------------------------------------------------------------------------------------------------------------------

--Remove Unused Columns (also would not want to typically do this with your raw data, but would be useful in views, etc.)

ALTER TABLE dbo.NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, SaleDate;
































