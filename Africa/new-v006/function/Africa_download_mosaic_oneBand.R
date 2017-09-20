# Author: Yanni Zhan
# Date  : 08/03/2017
# For Modis EVI, red, blue, MIR, NIR raw data download over Africa

require(raster)
require(RCurl)
require(rgdal)

#read the script with all the functions
source("./function/RModis_Function_Revised2.R")

print(paste("Start downloading and mosacing:",Sys.time()))
start_time1=Sys.time()

#enbale multple users to process at the same time
TmpMosaic=paste("/TmpMosaic_",Sys.info()[["user"]],".prm",sep="")

#set the parameters for Africa
product    = "MOD13Q1"
h          = 16:23
v1         = 5:8
v2         = 9:12
ver        = "006"
tmp.dir    = "./"

#create a folder of your choosing month
dir.create(paste(base_directory,"/raws",sep=""),showWarnings=F,mode="0775")
dir.create(paste(base_directory,"/raws/",Band,sep=""),showWarnings=F,mode="0775")
dir.create(paste(base_directory,"/raws/",Band,"/",raw_folder,sep=""),showWarnings=F,mode="0775")

#set the directory you want to save all the files
setwd(paste(base_directory,"/raws/",Band,"/",raw_folder,sep=""))

#set the output bands
bands_EVI  ='0 1 0 0 0 0 0 0 0 0 0 0'
bands_RED  ='0 0 0 1 0 0 0 0 0 0 0 0'
bands_NIR  ='0 0 0 0 1 0 0 0 0 0 0 0'
bands_BLUE ='0 0 0 0 0 1 0 0 0 0 0 0'
bands_MIR  ='0 0 0 0 0 0 1 0 0 0 0 0'
bands_NDVI='1 0 0 0 0 0 0 0 0 0 0 0'

bands_mrt  =get(paste("bands_",Band,sep=""))





###North Part
#download the data of your choosing month & year

for (i in year_input){
  year  = i
  
  #retry if download process encounters error
  while(TRUE){
    files=try(modis.download( product=product, 
                              month=month, 
                              year=year,
                              h=h, v=v1, 
                              ver=ver, 
                              username=username,
                              pwd=pwd,
                              tmp.dir=tmp.dir))
    if(!is(files,"try-error"))
    {
      break
    } else {
      #remove empty hdf files
      ff=list.files(pattern="*.hdf")
      eff=ff[file.info(ff)[["size"]]==0]
      unlink(eff)
      #sleep for 300 seconds
      print("USGS website not responding. Wait for 5 min.")
      Sys.sleep(300)
      #file.remove(list.files(pattern="*.hdf"))
      print(paste("Start downloading",year[i],"again."))
    }
  }
  
  #mosaic
  modis.mosaic( files, bands_subset=bands_mrt, MRTpath,delete=T)
}


#rename the downloaded files for the northern part
files_name_n=list.files(pattern = "MOD13Q1.*.tif",full.names = T)
files_name_n
sapply(files_name_n,FUN=function(eachPath){ 
  file.rename(from=eachPath,to= sub(pattern="MOD13Q1_", replacement="N_",eachPath))
})



###South part:
#download the data of your choosing (the same) month from 2000 to 2016

for (i in year_input){
  year  = i
  
  #retry if download process encounters error
  while(TRUE){
    files=try(modis.download( product=product, 
                              month=month, 
                              year=year,
                              h=h, v=v2, 
                              ver=ver, 
                              username=username,
                              pwd=pwd,
                              tmp.dir=tmp.dir))
    if(!is(files,"try-error"))
    {
      break
    } else {
      #remove empty hdf files
      ff=list.files(pattern="*.hdf")
      eff=ff[file.info(ff)[["size"]]==0]
      unlink(eff)
      #sleep for 300 seconds
      print("USGS website not responding. Wait for 5 min.")
      Sys.sleep(300)
      #file.remove(list.files(pattern="*.hdf"))
      print(paste("Start downloading",year[i],"again."))
    }
  }
  
  #mosaic
  modis.mosaic( files, bands_subset=bands_mrt, MRTpath,delete=T)
}

#rename the downloaded files for the southern part
files_name_s=list.files(pattern = "MOD13Q1.*.tif",full.names = T)
files_name_s
sapply(files_name_s,FUN=function(eachPath){
  file.rename(from=eachPath,to= sub(pattern="MOD13Q1_",replacement="S_",eachPath))
})



#remove useless files
file.remove("./dates.html")
file.remove("./day.html")
file.remove("./resample.log")
file.remove("./tmp.prm")


#start merging
new_data_n=list.files(pattern="N_2.*.tif",full.names=T)
new_data_n
new_data_s=list.files(pattern="S_2.*.tif",full.names=T)
new_data_s

cl=makeCluster(detectCores())
registerDoParallel(cl)

foreach( i=1:length(new_data_n)) %dopar% {
  
  #for (i in 1:length(new_data_n)){
  
  print(paste("start merging:",new_data_n[i],"and",new_data_s[i]))

  output_name=paste("./",
                    substring(new_data_n[i],5,nchar(new_data_n[i])),sep="")
  output_name

  #system(command=paste("gdal_merge.py -of GTiff -n -3000 -a_nodata NaN -o",output_name,new_data_n[i],new_data_s[i]))
  system(command=paste("gdal_merge.py -of GTiff -o",output_name,new_data_n[i],new_data_s[i]))
  
  file.remove(new_data_n[i],new_data_s[i])
}

stopCluster(cl)

#change permission and group
system(command=paste("chmod 775 ",base_directory,"/raws/",Band,"/",raw_folder," -R",sep=""))
#system(command=paste("chgrp afsisdata ",base_directory,"/raws/",Band,"/",raw_folder," -R",sep=""))

print(paste("Finish downloading and mosacing:",Sys.time()))
finish_time1 = Sys.time()
print(finish_time1 - start_time1)

