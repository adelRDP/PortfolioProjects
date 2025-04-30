-- Cleaning Housing Data in SQL 

	SELECT * 
	FROM HousingDataCleaning.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

-- Convert DateTime to Date (get rid of Useless 00:00:00s)

	SELECT SaleDate ,Convert(date, SaleDate)
	FROM HousingDataCleaning.dbo.NashvilleHousing

	Update HousingDataCleaning.dbo.NashvilleHousing
	SET SaleDate = Convert(date, SaleDate)

-- If it doesn't Update properly

	-- Alter directly (Risky):

	--ALTER TABLE NashvilleHousing
	--ALTER COLUMN SaleDate DATE


-- Make a new Converted Column (Safer):

	ALTER TABLE NashvilleHousing
	ADD SaleDateConverted DATE

	UPDATE HousingDataCleaning.dbo.NashvilleHousing
	SET SaleDateConverted = Convert(date, SaleDate)

	-- Now Remove SaleDate
	ALTER TABLE NashvilleHousing
	DROP COLUMN SaleDate

	-- Rename Back to SaleDate
	EXEC sp_rename 'NashvilleHousing.SaleDateConverted', 'SaleDate', 'COLUMN'

	-- Validate Results
	SELECT SaleDate ,Convert(date, SaleDate)
	FROM HousingDataCleaning.dbo.NashvilleHousing


 --------------------------------------------------------------------------------------------------------------------------

 -- Populate Property Address data


	-- Finding rows that have same ParcelID but one has empty PropertyAddress
	select *
	FROM HousingDataCleaning.dbo.NashvilleHousing
	WHERE parcelID IN	(Select ParcelID
						From HousingDataCleaning.dbo.NashvilleHousing
						Where PropertyAddress is null)

	-- Find the exact ParcelIDs which have property addresses, and also NULL property addresses
	SELECT L.ParcelID, L.PropertyAddress,R.ParcelID, R.PropertyAddress, ISNULL(L.PropertyAddress, R.PropertyAddress)
	FROM HousingDataCleaning.dbo.NashvilleHousing L
	JOIN HousingDataCleaning.dbo.NashvilleHousing R
	ON L.ParcelID = R.ParcelID
	AND L.[UniqueID ] != R.[UniqueID ]
	WHERE L.PropertyAddress IS NULL

	-- Now let's populate the Null Rows
	UPDATE L
	SET PropertyAddress = ISNULL(L.PropertyAddress, R.PropertyAddress)
	FROM HousingDataCleaning.dbo.NashvilleHousing L
	JOIN HousingDataCleaning.dbo.NashvilleHousing R
	ON L.ParcelID = R.ParcelID
	AND L.[UniqueID ] != R.[UniqueID ]
	WHERE L.PropertyAddress IS NULL

	
-- Checking to see if it worked as intended
	Select COUNT(*)
	From HousingDataCleaning.dbo.NashvilleHousing
	Where PropertyAddress is null

	-- AND THERE WE HAVE IT! 
	-- NO NULLS IN THE PROPERTY ADDRESS COLUMN!
	   
 --------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)

	
	Select PropertyAddress
	From HousingDataCleaning.dbo.NashvilleHousing

	-- This is what we want(Split by delimiter ,)
	SELECT
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) City
	FROM HousingDataCleaning.dbo.NashvilleHousing

	--Add Address and City columns
	ALTER TABLE HousingDataCleaning.dbo.NashvilleHousing
	ADD property_address NVARCHAR(255)

	ALTER TABLE HousingDataCleaning.dbo.NashvilleHousing
	ADD property_city NVARCHAR(100)

	UPDATE HousingDataCleaning.dbo.NashvilleHousing
	SET property_address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

	UPDATE HousingDataCleaning.dbo.NashvilleHousing
	SET property_city = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

	-- Check results real Quick!
	Select *
	From HousingDataCleaning.dbo.NashvilleHousing

-- Nice, as intended!

	-- Now let's fix OwnerAddress as well:
	Select OwnerAddress
	From HousingDataCleaning.dbo.NashvilleHousing

	-- Use PARSENAME this time
	SELECT
	PARSENAME(REPLACE(OwnerAddress, ',','.'),3),
	PARSENAME(REPLACE(OwnerAddress, ',','.'),2),
	PARSENAME(REPLACE(OwnerAddress, ',','.'),1)
	From HousingDataCleaning.dbo.NashvilleHousing

	--Add Owner Address, State and City columns
	ALTER TABLE HousingDataCleaning.dbo.NashvilleHousing
	ADD owner_address NVARCHAR(255)

	ALTER TABLE HousingDataCleaning.dbo.NashvilleHousing
	ADD owner_city NVARCHAR(100)

	ALTER TABLE HousingDataCleaning.dbo.NashvilleHousing
	ADD owner_state NVARCHAR(5)

	UPDATE HousingDataCleaning.dbo.NashvilleHousing
	SET owner_address = PARSENAME(REPLACE(OwnerAddress, ',','.'),3)

	UPDATE HousingDataCleaning.dbo.NashvilleHousing
	SET owner_city = PARSENAME(REPLACE(OwnerAddress, ',','.'),2)

	UPDATE HousingDataCleaning.dbo.NashvilleHousing
	SET owner_state = PARSENAME(REPLACE(OwnerAddress, ',','.'),1)

	-- Check the end results now!
	Select *
	From HousingDataCleaning.dbo.NashvilleHousing


	--NOW THESE INFORMATION ARE MUCH MORE USEABLE!

--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field

	SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
	FROM HousingDataCleaning.dbo.NashvilleHousing
	GROUP BY SoldAsVacant
	ORDER BY 2

	-- Let's replace Y with Yes and N with No quickly:
	SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'N' THEN 'No'
		 WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 ELSE SoldAsVacant
		 END
	FROM HousingDataCleaning.dbo.NashvilleHousing 

	-- NOW LET'S UPDATE THE TABLE
	UPDATE HousingDataCleaning.dbo.NashvilleHousing
	SET SoldAsVacant = 
		 CASE WHEN SoldAsVacant = 'N' THEN 'No'
		 WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 ELSE SoldAsVacant
		 END


-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates
	
	--Lets see if we find any, Using CTE and Partition by
	WITH RowNumCTE AS(
	SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
	FROM HousingDataCleaning.dbo.NashvilleHousing
	)
	SELECT *
	FROM RowNumCTE
	WHERE row_num > 1
	ORDER BY PropertyAddress

	-- Now Let's delete these duplicates
	WITH RowNumCTE AS(
	SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
	FROM HousingDataCleaning.dbo.NashvilleHousing
	)

	DELETE
	FROM RowNumCTE
	WHERE row_num > 1

	-- OK, Now Let's check
	SELECT *
	FROM HousingDataCleaning.dbo.NashvilleHousing


	-- 104 DUPLICATE ROWS WERE DELETED!


---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns


	ALTER TABLE HousingDataCleaning.dbo.NashvilleHousing
	DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

	SELECT *
	FROM HousingDataCleaning.dbo.NashvilleHousing