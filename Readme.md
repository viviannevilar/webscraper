# Webscraper to get price data from Woolworths and Coles' websites

This repository contains scripts to grab prices of fruit and vegetables from Woolworths and Coles' websites for different cities and save to a .csv file that will be put on your Desktop. If the file already exists, it will append the data to the same file (Coles.csv and Woolies.csv).

The scripts are written in AppleScript, which works as the "driver" to open Safari, go to a webpage, do loops, etc. The scripts also execute JavaScript commands to grab the data from the DOM.

While the scripts are running you can't use your computer to do something else or it won't work properly (because Safari needs to be active with the window/tab that is being used open as current one).

The scripts work as of 18/02/2021, but if the website is updated it may no longer work (for example, change in class names, change in structure, etc).

To run a script, open it with Script Editor (mac) and click on the run (play) button on the top left hand side corner of the window.

The functions used in each script can be found at the end of each file.

## Coles

Coles has one price for each product per state, so the script gets the prices for each capital city. This script works as of 18/02/2021, but if the website is updated it may no longer work. For example, if some class or id names change, or the structure changes somewhat.

## Woolworths

You need to log in first before running the script. For each state, Woolworths has two sets of prices: one for urban and one for rural areas. Thus, the script saves price data for one chosen rural city and one chosen location in the capital of each state.

## Osagitfilter

I am using Osagitfilter (https://github.com/doekman/osagitfilter) to put AppleScript on github as a text file (otherwise it doesn't show the contents)
