# Author: Yanni Zhan
# Date  : 09/05/2017
# For Modis EVI, red, blue, MIR, NIR LTA one band calculation via GRASS over Africa

###############LTA Grass
require(spgrass6)
require(doParallel)

print(paste("Start calculating long term average and merge:",Sys.time()))
start_time2=Sys.time()

#Band="EVI"

mapset_ts=substring(Band,1,1) #less characters

#location of your grass installation
loc=initGRASS(gisBase=gisBase,home=tempdir(),gisDbase=gisDbase,location="Geographic",
              mapset=mapset_ts,override=T)


if (Band=="EVI"|Band=="NDVI") {null_value="-3000"} else {null_value="-1000"}


###LTA
print(paste("Start LTA Africa for ",Band,":",sep=""))

folder_all=paste(base_directory,"/raws/",Band,"/",raw_folder,sep="")
setwd(folder_all)

r_in_gdal_list=list.files(pattern="*.tif$",recursive=T,full.names=T)
r_in_gdal_list

#enable multi threading
cl2=makeCluster(detectCores())
registerDoParallel(cl2)

count=c(1:length(r_in_gdal_list))
r_in_gdal=paste("A",count,sep="")
r_in_gdal_map=paste(r_in_gdal,"@",mapset_ts,sep="")

foreach( j=1:length(r_in_gdal_list),.packages="spgrass6" ) %dopar% {
  #for (j in 1:length(r_in_gdal_list)){
  execGRASS("r.in.gdal",parameters=list(input=r_in_gdal_list[j],output=r_in_gdal[j]))
  execGRASS("r.null",parameters=list(map=r_in_gdal_map[j],setnull=null_value))
}
stopCluster(cl2)

#set the region as africa
execGRASS("g.region",parameters=list(rast=r_in_gdal_map[1]))

#calculate time series(long term average)
r_series_input=paste(r_in_gdal_map,collapse=",")
r_series_output=paste(avg@",mapset_ts,sep="")

execGRASS("r.series",parameters=list(input=r_series_input,output=r_series_output,method="average"))

#output name
r_out_output=paste(base_directory,"/out_folder/","/",Band,"_",raw_folder,"_avg_",out_naming,"_x10000.tif",sep="")

#start outputing
print(paste("Start outputing Africa for ",Band,":",sep=""))
execGRASS("r.out.gdal",parameters=list(input=r_series_output,output=r_out_output))



#unlink(paste("/data3/grassdata/Geographic/",mapset_ts,sep=""),recursive=T)









##############