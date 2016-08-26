# Author: Yanni Zhan
# Date  : 08/11/2016
# For Modis EVI&NDVI download, mosaic, reproject and rescale

rm(list=ls())
getwd()
setwd("/data3/rstudio/EVINDVI")

#install packages
install.packages(c("raster"))
install.packages(c("crs"))
install.packages(c("rgdal"))
require(raster)
require(RCurl)
require(rgdal)

#read the script with all the functions
source("RModis-copy.R")


# Note: You must install the MODIS Reprojection tools
#       This is where it is on my machine.  It will probably
#       be different on yours
#
# Sys.setenv(MRT_HOME="/usr/local/mrt/", 
#            MRT_DATA_DIR="/usr/local/mrt/data")



############ Step 1. download + mosaic ###############
#download a whole year from Jan to Dec
for (i in 01:12) {
  #parameters
  product    = "MOD13Q1"
  month      = i
  year       = 2014  #remember also to change the year line #138 in the RModis.R; save; and source again
  h          = 18:19
  v          = 7:8
  ver        = "005"
  tmp.dir    = "./"
  MRTpath    = "/usr/local/mrt/bin"
  username   = "yzhan"
  pwd        = "1993912Zyn"
  
  #download
  files = modis.download( product=product, 
                          month=month, 
                          year=year,
                          h=h, v=v, 
                          ver=ver, 
                          username=username,
                          pwd=pwd,
                          tmp.dir=tmp.dir)
  
  #mosaic
  modis.mosaic( files, MRTpath )
}


############ Step 2. reproject to Lambert ###########
#create a new folder "2014_reproject"
dir.create("2014_reproject", showWarnings=F)

#list all the files of 2014 as inputs
ip<- list.files(pattern = "MOD13Q1_2014-.*.tif",full.names = T) 
ip

#remove '.tif' and './' in the file name
ip2<-strsplit(ip,"\\.tif")
ip2<-substring(ip2,3,nchar(ip2))

#create a new name as output
op<-paste("./2014_reproject/",ip2,"_laea.tif",sep="")
op

#bulk reproject
for (j in 1:length(ip)) {
  system(command= paste("gdalwarp -overwrite -t_srs '+proj=laea +lat_0=5 +lon_0=20 +x_0=0 +y_0=0 +ellps=WGS84 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs' -multi -wm 5000",
                        ip[j],
                        op[j]))
  file.remove(ip[j])
}


############ Step 3. rescale #######################
#rescale parameters from usgs website
offset  = 0
gain    = 0.0001
valid   = c(-2000,10000)

#list the files
folder = "/data3/rstudio/EVINDVI/2014_reproject"
files_name <- list.files(folder,pattern = "*.tif",full.names = T) 
files_name

#bulk rescale
modis.bulk.rescale (files_name, offset, gain, valid)


