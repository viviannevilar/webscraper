#@osa-lang:AppleScript
-- set the number of seconds necessary for the website to load.
-- if your internet is slower you need to increase this
global myDelay
set myDelay to 5


-- set locations
set capitalCities to {"6000", "6701", "5000", "5725", "2000", "2880", "3000", "3579", "0810", "0870", "4000", "4825", "7000", "7304"} --

set nameLocation to {"Perth St Georges Terrace", "Carnarvon", "Adelaide Rundall Mall", "Roxby Downs", "Sydney Metcentre", "Broken Hill", "Melbourne QV", "Kerang", "Darwin Casuarina", "Alice Springs", "Brisbane Macarthur Chambers", "Mount Isa", "Hobart City", "Deloraine"} --


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

to getInputByClass(theClass, num)
	tell application "Safari"
		set input to do JavaScript "document.getElementsByClassName('" & theClass & "')[" & num & "].innerHTML;" in document 1
	end tell
	return input
end getInputByClass


--------------------
---- Function to get the text in a page source using the ID
-- each product is inside an object class "tileListView-repeatAnimation". There will be as many of those in a page as the number of products in it

on getDataClass(theClass, num, splitProd)
	tell application "Safari"
		set input to do JavaScript "document.getElementsByClassName('product-grid--tile')[" & num & "].getElementsByClassName('" & theClass & "')[" & splitProd & "].innerHTML;" in document 1
	end tell
	return input
end getDataClass

--------------------
---- Function to get the text in a page source using the ID

to getInputById(theId)
	tell application "Safari"
		set input to do JavaScript "document.getElementById('" & theId & "').innerHTML;" in document 1
	end tell
	return input
end getInputById


--------------------
---- Function to click on an element by its ID name

to clickID(theId)
	tell application "Safari"
		do JavaScript "document.getElementById('" & theId & "').click();" in document 1
	end tell
end clickID


--------------------
-- Function to click on a button by class name

to clickClassName(theClassName, elementnum)
	tell application "Safari"
		do JavaScript "document.getElementsByClassName('" & theClassName & "')[" & elementnum & "].click();" in document 1
	end tell
end clickClassName


--------------------
---- Function to append data to file

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
	set this_file to (((path to desktop folder) as text) & "woolies.csv")
	my write_to_file(this_story, this_file, true)
end WriteLog


--------------------
---- Remove White Space

on removeWS(theText)
	local tempText
	set tempText to " "

	repeat while tempText ≠ theText
		set tempText to theText
		--remove leading spaces
		if first character of theText = space then
			set theText to text 2 thru -1 of theText
		end if

		--remove trailing spaces
		if last character of theText = space then
			set theText to text 1 thru -2 of theText
		end if
	end repeat

	return theText
end removeWS


-------------------------------------------------------------------------------------------

-- FILE SPECIFIC FUNCTIONS

-------------------------------------------------------------------------------------------

---- Function to clean some of the data that comes with RETURN and white space

on myTrim(nameTrim)
	set nameTrim to text 2 thru -1 of nameTrim
	set nameTrim to removeWS(nameTrim)
	set nameTrim to text 1 thru -2 of nameTrim
	return nameTrim
end myTrim


--------------------
---- Function to arrange the data in a line and write to file

on writeMyLine(capitalCity, nameLocation, prodName, productPrice, packageSize, packagePrice, onSpecial)
	set shortDateString to short date string of (current date)

	set myLine to shortDateString & ", " & capitalCity & ", " & nameLocation & ", " & prodName & ", " & productPrice & ", " & packageSize & ", " & packagePrice & ", " & onSpecial & "
"
	WriteLog(myLine)
end writeMyLine


--------------------
---- Do this for each page within a group (fruits of vegetables): get and save the data displayed on this page

on getDataProduct(t, capitalCity, nameLocation)

	-- package price
	try
		set packagePrice to getDataClass("shelfProductTile-cupPrice", t, 0)

		-- this used to trim the contents but it now trims too much
		-- set packagePrice to myTrim(packagePrice)

	on error
		set packagePrice to "NA"
	end try

	-- to stop the program here uncomment the next line
	-- error number -128


	-- product price
	try
		set productPrice to ("$" & getDataClass("price-dollars", t, 0) & "." & getDataClass("price-cents", t, 0))
	on error
		set productPrice to "NA"
	end try


	-- special
	try
		set onSpecial to getDataClass("shelfProductListTagCenter-text", t, 0)
	on error
		set onSpecial to " "
	end try


	try
		-- product name
		set prodName to getDataClass("shelfProductTile-descriptionLink", t, 0)
		-- set prodName to myTrim(prodName)


		-- some bundles contain a comma and it messes up the csv, so I am removing the commas here
		if (prodName contains ",") then
			set otid to AppleScript's text item delimiters
			set AppleScript's text item delimiters to ","
			set prodName to text items of prodName
			set AppleScript's text item delimiters to " "
			set prodName to prodName as string
			set AppleScript's text item delimiters to otid
		end if


		-- this is to infer the package size from the product name because this info is missing at Woolies
		set wordsName to words of prodName


		set theList to {"kg", "sachet", "bag", "tub", "tube", "pack"}
		if theList contains item -1 of wordsName then
			set packageSize to (item -2 of wordsName) & " " & (item -1 of wordsName)
		else
			if item -2 of wordsName is equal to "min" then
				set packageSize to (item -2 of wordsName) & " " & (item -1 of wordsName)
			else
				set packageSize to item -1 of wordsName
			end if
		end if


		-- now I can infer the package price when this information is missing
		if packagePrice is equal to "NA" then
			if packageSize is equal to "each" then
				set packagePrice to productPrice & " / 1EA"
			else if packageSize is equal to "1kg" then
				set packagePrice to productPrice & " / 1KG"
			end if
		end if


		-- write the data to file
		writeMyLine(capitalCity, nameLocation, prodName, productPrice, packageSize, packagePrice, onSpecial)
		set productCounter to 1

		-- now I will deal with the case when the product has two options of package size
	on error
		try
			set prodName to getDataClass("shelfBundleTile-title", t, 0)
			--set prodName to myTrim(prodName)


			set splitP to 0
			repeat 2 times
				set productPrice to getDataClass("shelfProductVariant-price", t, splitP)
				set productPrice to myTrim(productPrice)
				set packagePrice to getDataClass("shelfProductVariant-cup", t, splitP)
				set packagePrice to myTrim(packagePrice)
				set packageSize to getDataClass("shelfProductVariant-variant", t, splitP)
				set packageSize to myTrim(packageSize)
				writeMyLine(capitalCity, nameLocation, prodName, productPrice, packageSize, packagePrice, onSpecial)
				set splitP to 1
			end repeat


			set productCounter to 2
		on error
			set productCounter to 0
		end try
	end try

	return productCounter

end getDataProduct


--------------------
---- Get and write to file the information for the products given a location
-- This function calls the function getDataPage()

on getProductPrices(capitalCity, nameLocation, fv)


	set WebPage to "https://www.woolworths.com.au/shop/browse/fruit-veg/" & fv & "?pageNumber=1"
	goToWebPage(WebPage)
	delay myDelay

	-- figure out how many products per page there are
	-- this seems to change. It was 36 for me, now it is 24, so better check
	set nProducts to 0
	repeat 48 times
		try
			getInputByClass("product-grid--tile", nProducts)
			set nProducts to (nProducts + 1)
		on error
			-- display dialog "Could not get the number of products per page"

			-- stop the program with a "User cancelled" message
			-- error number -128

			exit repeat
		end try
	end repeat


	repeat

		-- debugging: display dialog nProducts
		set t to 0
		repeat nProducts times
			try
				getDataProduct(t, capitalCity, nameLocation)
				set t to (t + 1)

			on error
				exit repeat
			end try
		end repeat

		try
			-- I only include getInputByClass because this one throws an error when not found,
			-- whereas what I really want, clickClassName, won't throw an error if the element with class paging-next isn't found
			getInputByClass("paging-next", 0)
			clickClassName("paging-next", 0)
			delay myDelay
		on error
			exit repeat
		end try

	end repeat

end getProductPrices


-------------------------------------------------------------------------------------------

-- MAIN CODE

-------------------------------------------------------------------------------------------

-- header line for the csv file (might want to remove this if just adding to the same file)
set myLine to "Date" & ", " & "Postcode" & ", " & "Location" & ", " & "Product" & ", " & "Price" & ", " & "Package Size" & ", " & "Package Price" & ", " & "Special" & "
"
my WriteLog(myLine)

-- will loop trough this variable to get all the fruits and variables
set fruitsVegetables to {"fruit", "vegetables"}


goToWebPage("https://www.woolworths.com.au")
delay myDelay

-- this closes a pop up window if it shows up
try
	clickClassName("button button--primary fulfilmentSelectorDialog-button", 0)
end try
--fulfilmentSelectorDialog-buttonContainer


-- set cc to item 1 of capitalCities
set ccindex to 1


repeat with capitalCity in capitalCities
	-- will loop through this variable to go to all capital cities

	goToWebPage("https://www.woolworths.com.au/shop/browse/fruit-veg/fruit")
	delay myDelay

	-- Here I will click on the tab to the right of the screen to change location
	-- Some of these are redundant but necessary because sometimes the class name seems to change - maybe I need the ID!
	clickClassName("cartOffscreen-cartClosedMask", 0)
	delay 1

	-- This selects the link/button "Change".
	delay 1
	clickClassName("fulfilmentMethodWizardV2-selectedStateEdit", 0)
	clickClassName("fulfilmentMethod-selectedStateEdit", 0)


	delay 1
	clickClassName("fulfilmentMethodWizardV2-fulfilmentMethod-label", 0)
	clickClassName("input-group__content", 0)


	delay 1
	clickID("suburb-fulfilmentSelector-pickup")
	--clickID("pickupSelectorAddress-selectedStore")
	clickID("pickupAddressSelector")
	-- clickClassName("iconww-Cross", 0)
	clickClassName("icon-close_x", 0)
	--clickClassName("clear-text", 0)

	delay 1

	-- write the location name (variable capitalCity), press arrow down
	tell application "System Events"
		--keystroke (ASCII character 9)
		delay 1
		keystroke capitalCity
		delay 1
		key code 125
	end tell

	delay 2

	clickID("pickupAddressSelector-option0")


	delay 0.5

	-- press enter to send the input (location variable "capitalCity"), written with the code above.
	tell application "System Events"
		keystroke return
	end tell
	delay myDelay


	-- get the current location to be able to write in the data file
	try
		set thisLoc to getInputByClass("fulfilmentMethodWizardV2-selectedStateAddress", 0)
	on error
		try
			set thisLoc to getInputByClass("fulfilmentMethod-selectedStateAddress", 0)
		on error
			set thisLoc to " "
			display dialog "Error getting location"
		end try
	end try

	clickClassName("cartOffscreen-openButton", 0)


	delay 2


	----- xxx ----- xxx ----- Loop 2 ----- xxx ----- xxx -----
	repeat with fv in fruitsVegetables
		getProductPrices(capitalCity, thisLoc, fv)
	end repeat

	set ccindex to (ccindex + 1)
end repeat


