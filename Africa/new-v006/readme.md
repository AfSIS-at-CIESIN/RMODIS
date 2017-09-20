## Scripts

### Modis_Quarterly_mon_avg.R 

* This script was written by Yanni Zhan, CIESIN, Columbia University. It is created to update the quarterly MODIS 250m /MOD13Q1 version 006 monthly average datasets as an alternative to the old version 005. 
(It is set to run EVI long term monthly average from 2000 to 2017)

* Basic workflow
     * Download & mosaic (sourcing the function **Africa_download_mosaic_oneBand.R** script)
     * Calculate long term monthly average (sourcing the function **Africa_mon_avg_oneBand.R** script)
     * Reproject to laea & clip (sourcing the function **Africa_laea_clip_oneBand.R** script)

* Parameters 
     * Download & mosaic:
         * Band (specific band you want to download for MOD13Q1, availabe for "EVI", "RED", "BLUE", "NIR", "MIR", "NDVI")
         * month (the month of data you want to download)
         * raw_folder (the name of the raw folder you want to save the raw data)
         * year_input (the temporal range of the you want to download for the raw data)
         * username & pwd (username and password from the USGS website)
         * MRTpath (where the Modis Reporjection Tool is located on your local machine)
     * Calculate long term monthly average:
         * gisBase & gisDbase (the GRASS settings on your local machine)
     * Reproject to laea & clip:
         * mapset (the mapset to use for GRASS)
         * in_folder (the folder that contains the files to be processed)

* The quarterly updates are located on AfSIS FTP Site
     * ftp://africagrids.net/250m/MOD13Q1/

### Modis_Quarterly_LTA.R

* This script was written by Yanni Zhan, CIESIN, Columbia University. It is created to update the quarterly MODIS 250m /MOD13Q1 version 006 long term average datasets as an alternative to the old version 005. 
(It is set to run EVI long term average from 2000 to 2017)

* Basic workflow
     * Download & mosaic (sourcing the function **Africa_download_mosaic_oneBand.R** script)
     * Calculate long term average (sourcing the function **Africa_LTA_oneBand.R** script)
     * Reproject to laea & clip (sourcing the function **Africa_laea_clip_oneBand.R** script)

* Parameters 
     * Download & mosaic:
         * Band (specific band available for MOD13Q1, availabe for "EVI", "RED", "BLUE", "NIR", "MIR", "NDVI")
         * month (the month of data you want to download) (**be sure to download all the months before moving to next step**)
         * raw_folder (the name of the raw folder you want to save the raw data)
         * year_input (the temporal range of the you want to download for the raw data)
         * username & pwd (username and password from the USGS website)
         * MRTpath (where the Modis Reporjection Tool is located on your local machine)
     * Calculate long term average:
         * gisBase & gisDbase (the GRASS settings on your local machine)
     * Reproject to laea & clip:
         * mapset (the mapset to use for GRASS)
         * in_folder (the folder that contains the files to be processed)

* The quarterly updates are located on AfSIS FTP Site
     * ftp://africagrids.net/250m/MOD13Q1/


## Folder

### /Function

* This folder contains all the function scripts needed in the Modis_Quarterly_mon_avg.R and Modis_Quarterly_LTA.R script.
