#@osa-lang:AppleScript
-------------------------------------------------------------------------------------------
-- INITIAL COMMENTS
-------------------------------------------------------------------------------------------

-- this script gets data from Coles
-- if there is no file named coles.csv is in your Desktop this program will create one. If there is it will append data to it.

-- if your internet connection is slow the script may not get the data
-- if so, increase the value of the variable below (myDelay) which gives the number of seconds it waits for the page to load
set myDelay to 4

-- set locations
set capitalCities to {"Perth 6000"} ---, "Adelaide 5000" , "Sydney 2000", "Melbourne 3000", "Darwin 0800", "Brisbane 4000", "Hobart 7000"}

set Locations to {"Perth, WA", "Adelaide, SA", "Sydney, NSW", "Melbourne, VIC", "Darwin City, NT", "Brisbane City, QLD", "West Hobart, TAS"}

set linkLocation to {"Perth, WA, 6000"}
------------------------------------------------------------------------------------------
-- MAIN CODE
-------------------------------------------------------------------------------------------

-- go to the initial page so I can go to the first location
goToWebPage("https://shop.coles.com.au")


delay myDelay

-- header line for the file (might want to remove this if just adding to the same file)
set myLine to "Date, Postcode, Location, Product Name, Product Price, Package Size, Package Price, Special
"
my WriteLog(myLine)


-- For each capital city
set ccindex to 1
repeat with cc in capitalCities
	set ColesLocation to getInputByClass("localised-suburb", 0)

	clickID("changeLocationBar")
	delay 1
	-- clickID("localisation-search")


	-- I have this to make sure that the location is set right. Sometimes it doesn't set the correct location for the first capital city, so I try it up to 3 times and if still not right, there will be a popup later warning there is a problem
	repeat 3 times
		if ColesLocation is not equal to item ccindex of Locations then

			-- fill in the login details
			tell application "System Events"
				keystroke cc
				delay 1.5
				key code 125
				keystroke return
				delay myDelay
			end tell
			set ColesLocation to getInputByClass("localised-suburb", 0)

		else
			exit repeat
		end if
	end repeat

	if ColesLocation is not equal to item ccindex of Locations then
		display dialog ColesLocation & " " & item ccindex of Locations
		display dialog "Location not set correctly"
	end if

	set postCode to text -4 thru -1 of cc
	getPrices(postCode, myDelay)
	set ccindex to (ccindex + 1)
end repeat


display dialog "Program Finished"


-------------------------------------------------------------------------------------------
-- FILE SPECIFIC FUNCTIONS
-------------------------------------------------------------------------------------------

--------------------
-- this Function cycles through each page of fruits and each page of vegetables for the given location
-- To get the data on the page it calls the function getDataWebsite

on getPrices(postCode, myDelay)
	set base to "https://shop.coles.com.au/a/a-wa-metro-mirrabooka/everything/browse/fruit-vegetables/"
	set productType to {"fruit", "vegetables"}

	-- for each product type (fruit or vegetables) do
	repeat with p in productType
		set WebPage to base & p & "?pageNumber=1"
		goToWebPage(WebPage)
		delay myDelay

		-- get the total number of products to deduct the number of pages
		set totalItems to getInputById("everything-page-1")
		set listOfWords to splitText(totalItems, space)
		set totalProducts to item -1 of listOfWords
		set lastProductsPage to item -3 of listOfWords


		-- this will get the next page for the category (fruit or vegetables) until there are no more products left
		-- it also calls the function which saves the data for each page
		set i to 1
		repeat while totalProducts is greater than 0

			-- when i = 1 you don't need to load a new webpage because it was loaded before the "repeat"
			if i is not equal to 1 then
				set WebPage to base & p & "?pageNumber=" & (i as string)
				goToWebPage(WebPage)
				delay myDelay
			end if

			-- set the number of products on this page
			if (totalProducts - 48) is less than 0 then
				set thisPage to totalProducts
			else
				set thisPage to 48
			end if

			-- the remaining products after this page
			set totalProducts to (totalProducts - 48)

			-- calls the function which collects and writes to file the information about the products on this page
			getDataWebsite(thisPage, postCode)
			set i to (i + 1)
		end repeat
	end repeat
end getPrices


--------------------
---- Function to get data from Coles Website (for the page currently shown).

-- thisPage is the number of products on this page (max 48)
-- it will grab the names, prices, package size, package price, and whether the product is on special

on getDataWebsite(thisPage, postCode)

	set t to 0
	repeat thisPage times

		-- figure out the date
		set shortDateString to short date string of (current date)

		-- get product name. I also need the brand name because it matters for some of the products
		set productBrand to getDataClass("product-brand", t)
		set productName to getDataClass("product-name", t)
		set fullName to productBrand & " " & productName


		-- sometimes the package size is not available for a product so
		try
			set packageSize to getDataClass("package-size", t)
		on error
			set packageSize to " "
		end try

		-- this one always exists for each product, even if its value is an empty space
		set packageSizeCheck to getDataClass("package-size accessibility-inline", t)


		-- set the value of the variable "special" for when the product is on special
		if packageSizeCheck contains "on special" then
			set special to "YES"
		else
			set special to " "
		end if

		-- when packageSizeCheck has a space or " on special" only,
		-- the package size is 1 unit, so I set packageSize to 1 unit
		if packageSizeCheck is equal to " " then
			set packageSize to "1 unit "
		else if packageSizeCheck is equal to " on special" then
			set packageSize to "1 unit "
		end if

		-- product price. Sometimes it isn't available
		try
			set dollarValue to getDataClass("dollar-value", t)
			set centValue to getDataClass("cent-value", t)
			set productPrice to "$" & dollarValue & centValue
		on error
			set productPrice to "NA"
		end try

		-- This is for the case when PRICE is unavailable
		-- When that happens, there is no class "package-price" or "product-price" for that product
		set packagePrice to getDataClass("package-price", t)
		if contents of packagePrice is "" then
			set packagePrice to "NA"
			set productPrice to "NA" --- maybe I don't need this line?
		end if

		set ColesLocation to text 1 thru -5 of getInputByClass("localised-suburb", 0)

		-- this assembles the line with data to be written to file
		set myLine to shortDateString & ", " & postCode & "," & ColesLocation & "," & fullName & ", " & productPrice & ", " & packageSize & ", " & packagePrice & "," & special & "
"
		my WriteLog(myLine)

		set t to t + 1
	end repeat
end getDataWebsite



--------------------
---- Function to get the text in a page source using the ID
-- each product is inside an object class "colrs-animate tile-animate tile-stagger". There will be as many of those in a page as the number of products in it

on getDataClass(theClass, num)
	tell application "Safari"
		set input to do JavaScript "document.getElementsByClassName('colrs-animate tile-animate')[" & num & "].getElementsByClassName('" & theClass & "')[0].innerHTML;" in document 1
	end tell
	return input
end getDataClass

-------------------------------------------------------------------------------------------
-- GENERAL FUNCTIONS
-------------------------------------------------------------------------------------------

---- Function to go to a webpage

to goToWebPage(theWebPage)
	tell application "Safari"
		activate
		set URL of document 1 to theWebPage
	end tell
end goToWebPage

--------------------
---- Function to get the text in a page source using the class name

to getInputByClass(theClass, num) -- defines a function with two inputs, theClass and num
	tell application "Safari" --tells AS that we are going to use Safari
		set input to do JavaScript "document.getElementsByClassName('" & theClass & "')[" & num & "].innerHTML;" in document 1 -- uses JavaScript to set the variable input to the information we want
	end tell
	return input --tells the function to return the value of the variable input
end getInputByClass

--------------------
---- Function to get the text in a page source using the ID

to getInputById(theId)
	tell application "Safari"
		set input to do JavaScript "document.getElementById('" & theId & "').innerHTML;" in document 1
	end tell
	return input
end getInputById

--------------------
---- Function to click on an element by its id name

to clickID(theId)
	tell application "Safari"
		do JavaScript "document.getElementById('" & theId & "').click();" in document 1
	end tell
end clickID

--------------------
---- Function to get the words of a sentence as a list

on splitText(theText, theDelimiter)
	set AppleScript's text item delimiters to theDelimiter
	set theTextItems to every text item of theText
	set AppleScript's text item delimiters to ""
	return theTextItems
end splitText

--------------------
---- Function to append data to file

-- https://stackoverflow.com/questions/3780985/how-do-i-write-to-a-text-file-using-applescript
-- there are two functions here, the second calls the first
-- to use it call WriteLog(text)

on write_to_file(this_data, target_file, append_data) -- (string, file path as string, boolean)
	try
		set the target_file to the target_file as text
		set the open_target_file to ¬
			open for access file target_file with write permission
		if append_data is false then ¬
			set eof of the open_target_file to 0
		write this_data to the open_target_file starting at eof
		close access the open_target_file
		return "data appended"
	on error
		try
			close access file target_file
		end try
		return "error"
	end try
end write_to_file

on WriteLog(the_text)
	set this_story to the_text
	set this_file to (((path to desktop folder) as text) & "coles.csv")
	my write_to_file(this_story, this_file, true)
end WriteLog


