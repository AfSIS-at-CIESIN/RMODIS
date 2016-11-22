# RMODIS
Modis_Nigeria_EVINDVI.R script (sourcing the original RModis_Function.R) was written by Yanni Zhan, CIESIN, Columbia University. The script was modified to download, mosaic, reproject and rescale /250m /MOD13Q1 - MODIS Enhanced Vegetation Index (EVI), Normalized Difference Vegetation Index (NDVI) 16 day timeseries for the country of Nigeria. The year needs to be changed. It is set to run 2014. 

The outputs for 2014 are located on the AfSIS FTP Site 
ftp://africagrids.net/Other/Test/Nigeria/

Modis_Quarterly_NDVI.R (sourcing the updated RModis_Function_Revised.R) is a script created to update the quarterly MODIS 250m /MOD13Q1 datasets as an alternative to the original Bash scripts. 

The quarterly updates are located on AfSIS FTP Site
ftp://africagrids.net/250m/MOD13Q1/
ftp://africagrids.net/1000m/MYD11A2/

The RModis_Function.R is authored by  
 Guido Cervone (cervone@polygonsu.edu) and Yanni Cao (yvc5268@polygonsu.edu), The Pennsylvania State University

The RModis_Function_Revised.R is a script that were tweaked by Mengqi Wang, Data Science, Columbia University, which enables multi-threading to run downloading procedure faster.
