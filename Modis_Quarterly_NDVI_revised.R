# Author: Yanni Zhan
# Date  : 08/11/2016
# For Modis NDVI monthly average download, mosaic, reproject and rescale over Africa

rm(list=ls())
getwd()
setwd("/data3/rstudio/Quarterly/")

#install packages
install.packages(c("raster"))
install.packages(c("RCurl"))
install.packages(c("rgdal"))
require(raster)
require(RCurl)
require(rgdal)

#read the script with all the functions
source("RModis_Function_Revised.R")

# Note: You must install the MODIS Reprojection tools
#       This is where it is on my machine.  It will probably
#       be different on yours
#
Sys.setenv(MRT_HOME="/usr/local/mrt/", 
           MRT_DATA_DIR="/usr/local/mrt/data")


#enbale multple users to process at the same time
if (Sys.info()[["user"]]=="yzhan") {
  TmpMosaic="/TmpMosaic_Zh.prm"
} else {
  TmpMosaic="/TmpMosaic_01.prm"
}



############ Step 1. download + mosaic ###############
#set the parameters
product    = "MOD13Q1"
h          = 16:23
v1         = 5:8
v2         = 9:12
ver        = "005"
tmp.dir    = "./"
MRTpath    = "/usr/local/mrt/bin"
username   = "yzhan"
pwd        = "199xxxx3912Zyn"

#set the month
month      = 08

#create a folder of your chossing month
dir.create("August",showWarnings=F)

#set the directory you want to save all the files
setwd("/data3/rstudio/Quarterly/August")

#set the output bands
#bands_EVI  ='0 1 0 0 0 0 0 0 0 0 0 0'
#bands_RED  ='0 0 0 1 0 0 0 0 0 0 0 0'
#bands_NIR  ='0 0 0 0 1 0 0 0 0 0 0 0'
#bands_BLUE  ='0 0 0 0 0 1 0 0 0 0 0 0'
#bands_MIR  ='0 0 0 0 0 0 1 0 0 0 0 0'
bands_NDVI ='1 0 0 0 0 0 0 0 0 0 0 0'


###North Part
#download the data of your choosing month from 2000 to 2016
for (i in 2000:2016){
  year  = i
  files = modis.download( product=product, 
                          month=month, 
                          year=year,
                          h=h, v=v1, 
                          ver=ver, 
                          username=username,
                          pwd=pwd,
                          tmp.dir=tmp.dir)
  #mosaic
  #modis.mosaic( files, bands_subset=bands_EVI, MRTpath,delete=F)
  #modis.mosaic( files, bands_subset=bands_RED, MRTpath,delete=F)
  #modis.mosaic( files, bands_subset=bands_NIR, MRTpath,delete=F)
  #modis.mosaic( files, bands_subset=bands_BLUE, MRTpath,delete=F)
  #modis.mosaic( files, bands_subset=bands_MIR, MRTpath,delete=F)
  modis.mosaic( files, bands_subset=bands_NDVI, MRTpath,delete=T)
}

#rename the downloaded files for the northern part
files_name_n <- list.files(pattern = "*.tif",full.names = T)
files_name_n
sapply(files_name_n,FUN=function(eachPath){ 
  file.rename(from=eachPath,to= sub(pattern="MOD13Q1_", replacement="N_",eachPath))
})


###South part:
#download the data of your choosing (the same) month from 2000 to 2016
for (i in 2000:2016){
  year  = i
  files = modis.download( product=product, 
                          month=month, 
                          year=year,
                          h=h, v=v2, 
                          ver=ver, 
                          username=username,
                          pwd=pwd,
                          tmp.dir=tmp.dir)
  #mosaic
  #modis.mosaic( files, bands_subset=bands_EVI, MRTpath,delete=F)
  #modis.mosaic( files, bands_subset=bands_RED, MRTpath,delete=F)
  #modis.mosaic( files, bands_subset=bands_NIR, MRTpath,delete=F)
  #modis.mosaic( files, bands_subset=bands_BLUE, MRTpath,delete=F)
  #modis.mosaic( files, bands_subset=bands_MIR, MRTpath,delete=F)
  modis.mosaic( files, bands_subset=bands_NDVI, MRTpath,delete=T)
}

#rename the downloaded files for the southern part
files_name_s <- list.files(pattern = "MOD13Q1.*.tif",full.names = T)
files_name_s
sapply(files_name_s,FUN=function(eachPath){
  file.rename(from=eachPath,to= sub(pattern="MOD13Q1_",replacement="S_",eachPath))
})



############ Step 2. monthly average ##########################
#rescale parameters from usgs website
offset  = 0
gain    = 0.0001
valid   = c(-2000,10000)

###North
#list all the files for the northern part for NDVI
files_name_n  = list.files(pattern = paste("N_.*.NDVI.tif",sep=""),full.names=T)
files_name_n
#monthly average
north         = lapply(files_name_n,raster)
north_stack   = stack(north)
north_average = calc(north_stack,mean,na.rm=T)
plot(north_average)
#rescale
north_rescale = modis.rescale(north_average,offset,gain,valid)
plot(north_rescale)
#write the result
#writeRaster(north_rescale,file="N_NDVI_avgR_Aug_2000_2016.tif",format="GTiff",overwrite=T)


###South
#list all the files for the southern part
files_name_s  = list.files(pattern = paste("S_.*.NDVI.tif",sep=""),full.names=T)
files_name_s
#monthly average
south         = lapply(files_name_s,raster)
south_stack   = stack(south)
south_average = calc(south_stack,mean,na.rm=T)
plot(south_average)
#rescale
south_rescale = modis.rescale(south_average,offset,gain,valid)
plot(south_rescale)
#write the result
#writeRaster(south_rescale,file="S_NDVI_avgR_Aug_2000_2016.tif",format="GTiff",overwrite=T)


############ Step 3. merge and reproject ##########################
#merge the northern and southern part into one
merge_data  = merge(north_rescale,south_rescale)
plot(merge_data)

#write the result, you can change the name of the file here
setwd("/data3/rstudio/Quarterly")
writeRaster(merge_data,file="NDVI_avg_Aug_2000_2016.tif",format="GTiff",overwrite=T)

#reproject, the first .tif file is input(should be the same as the merge_data file you named), the second .tif file is the output which you can change the name
system(command= paste("gdalwarp -overwrite -t_srs '+proj=laea +lat_0=5 +lon_0=20 +x_0=0 +y_0=0 +ellps=WGS84 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs' -multi -wm 5000",
                      "NDVI_avg_Aug_2000_2016.tif",
                      "NDVI_avg_Aug_2000_2016_laea.tif"))

#change the permission of all the files in the folder created
folder="/data3/rstudio/Quarterly/August/"
system(command=paste("chmod -R 775",folder))
