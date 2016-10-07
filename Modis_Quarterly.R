# Author: Yanni Zhan
# Date  : 08/11/2016
# For Modis NDVI download, mosaic, reproject and rescale over Africa

rm(list=ls())
getwd()
setwd("/data3/rstudio/Quarterly")

#install packages
install.packages(c("raster"))
install.packages(c("RCurl"))
install.packages(c("rgdal"))
require(raster)
require(RCurl)
require(rgdal)

#read the script with all the functions
source("RModisRevised_NDVI&EVI.R")

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
year       = 2015
h          = 16:23
v1         = 5:7
v2         = 8:9
v3         = 10:12
ver        = "005"
tmp.dir    = "./"
MRTpath    = "/usr/local/mrt/bin"
username   = "yzhan"
pwd        = "199xxxxtttt3912Zyn"

#create a folder of your chossing year
dir.create(paste(year,"_reproject",sep=""),showWarnings=F)

#(it is slow to process so I suggest to download one month by one month)
month = 07

###NorthWest Part
#create a folder
dir.create(paste(m,"_NW",sep=""),showWarnings=F)
?dir.create
#download the data of your choosing month 
files = modis.download( product=product, 
                        month=month, 
                        year=year,
                        h=h, v=v1, 
                        ver=ver, 
                        username=username,
                        pwd=pwd,
                        tmp.dir=tmp.dir)
#mosaic
modis.mosaic( files, MRTpath )
#rename
files_name_1 <- list.files(pattern = "*.tif",full.names = T)
files_name_1
sapply(files_name_1,FUN=function(eachPath){ 
  file.rename(from=eachPath,to= sub(pattern="MOD13Q1_", replacement="1_",eachPath))
})



###NorthEast part:
#download the data of your choosing (the same) month
files = modis.download( product=product, 
                        month=month, 
                        year=year,
                        h=h, v=v2, 
                        ver=ver, 
                        username=username,
                        pwd=pwd,
                        tmp.dir=tmp.dir)
#mosaic
modis.mosaic( files, MRTpath )
#rename
files_name_2 <- list.files(pattern = "MOD13Q1_.*.tif",full.names = T)
files_name_2
sapply(files_name_2,FUN=function(eachPath){
  file.rename(from=eachPath,to= sub(pattern="MOD13Q1_",replacement="2_",eachPath))
})


###SouthWest part:
files = modis.download( product=product,
                        month=month,
                        year=year,
                        h=h1,v=v2,
                        username=username,
                        pwd=pwd,
                        tmp.dir=tmp.dir)
modis.mosaic( files, MRTpath)
files_name_3 <- list.files(pattern = "MOD13Q1_.*.tif",full.names = T)
files_name_3
sapply(files_name_3,FUN=function(eachPath){
  file.rename(from=eachPath,to= sub(pattern="MOD13Q1_",replacement="3_",eachPath))
})


###SouthEast
files = modis.download( product=product,
                        month=month,
                        year=year,
                        h=h2,v=v2,
                        username=username,
                        pwd=pwd,
                        tmp.dir=tmp.dir)
modis.mosaic( files, MRTpath)
files_name_4 <- list.files(pattern = "MOD13Q1_.*.tif",full.names = T)
files_name_4
sapply(files_name_4,FUN=function(eachPath){
  file.rename(from=eachPath,to= sub(pattern="MOD13Q1_",replacement="4_",eachPath))
})



############ Step 2. merge ##########################
#list all the files for North and South
files_name_1<-list.files(pattern = paste("1_",year,"-.*.tif",sep=""),full.names=T)
files_name_1
files_name_3 <- list.files(pattern = paste("3_",year,"-.*.tif",sep=""),full.names=T)
files_name_3

#raster the files
nw<-lapply(files_name_1,raster)
ne<-lapply(files_name_2,raster)
sw<-lapply(files_name_3,raster)
se<-lapply(files_name_4,raster)

nw<-raster(files_name_1)
ne<-raster(files_name_2)
sw<-raster(files_name_3)
se<-raster(files_name_4)
ndvi<-mosaic(nw,sw,ne,se)
plot(nw)
#merge and write the data
output_data=list()
for (i in 1:length(files_name)){
  print(paste("Loading",files_name[i]))
  output_data[[i]]<-merge(north[[i]],south[[i]])
  writeRaster(output_data[[i]],file=files_name[[i]],format="GTiff",overwrite=T)
  file.remove(files_name_n[[i]])
}



############ Step 3. reproject to Lambert ###########
#list all the files of your chosing year as inputs
ip<- list.files(pattern = paste("MOD13Q1_",year,"-.*.tif",sep=""),full.names = T) 
ip

#remove '.tif' and './' in the file name
ip2<-strsplit(ip,"\\.tif")
ip2<-substring(ip2,3,nchar(ip2))

#create a new name as output
op<-paste("./",year,"_reproject/",ip2,"_laea.tif",sep="")
op

#bulk reproject
for (j in 1:length(ip)) {
  system(command= paste("gdalwarp -overwrite -t_srs '+proj=laea +lat_0=5 +lon_0=20 +x_0=0 +y_0=0 +ellps=WGS84 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs' -multi -wm 5000",
                        ip[j],
                        op[j]))
  file.remove(ip[j])
}


############ Step 4. rescale #######################
#rescale parameters from usgs website
offset  = 0
gain    = 0.0001
valid   = c(-2000,10000)

#list the files in the "_reproject" folder
folder = paste("/data3/rstudio/Quarterly/",year,"_reproject",sep="")
merge_files_name <- list.files(folder,pattern = "*.tif",full.names = T) 
merge_files_name

#bulk rescale
modis.bulk.rescale (merge_files_name, offset, gain, valid)







########## others
#for (i in 1:length(north)){
#  if (!i %% 2){
#    next
#  }
#  output_data<-merge(north[[i]],south[[i]])
#  writeRaster(output_data,file=ndvi_name[i],format="GTiff",overwrite=T)
#}
