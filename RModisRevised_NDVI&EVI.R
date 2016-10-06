
#
#  "`-''-/").___..--''"`-._
# (`6_ 6  )   `-.  (     ).`-.__.`)   WE ARE ...
# (_Y_.)'  ._   )  `._ `. ``-..-'    PENN STATE!
#   _ ..`--'_..-_/  /--'_.' ,'
# (il),-''  (li),'  ((!.-'
#
#
#Author: Guido Cervone (cervone@polygonsu.edu) and Yanni Cao (yvc5268@polygonsu.edu)
#        Geoinformatics and Earth Observation Laboratory (http://geolab.polygonsu.edu)
#        Department of Geography and Institute for CyberScience
#        The Pennsylvania State University
#
#
require(raster)
require(foreach)
require(doParallel)

addZero <- function( x )
{
  x = as.numeric(x)
  
  if ( x < 10 )
    paste(0,x,sep="")
  else 
    x
}

modis.download = function( product, month, year, h, v, ver="005", username="", pwd="", tmp.dir="./") {
  
  base.url = "http://e4ftl01.cr.usgs.gov/"
  #base.url.2 = paste("http://",username,":",pwd,"@","e4ftl01.cr.usgs.gov/",sep="")
  
  # Download list of available days
  #
  url  = paste(base.url,"MOLT/",product,".",ver,sep="")
  
  list.fname = paste(tmp.dir, "dates.html",sep="")
  day.fname  = paste(tmp.dir, "day.html",sep="")
  
  # Download the file
  #
  download.file(url,list.fname)
  
  # read it
  #
  html=scan(list.fname,"character")
  
  # find out if there are any days which match our search
  #
  #pattern = paste(month.abb[as.numeric(month)],year,sep="-")
  pattern = paste(year,addZero(month),sep=".")
  
  valid   = html[ grep(pattern, html)]
  
  info    = regexpr("[[:digit:]]{4}\\.[[:digit:]]{2}\\.[[:digit:]]{2}",valid)
  start   = as.vector(info)
  end     = start + attr(info,"match.length") - 1
  
  files     = NULL
  
  for ( d in 1:length(valid) ) {
    
    date = substring(valid[d], start[d],end[d])
    print(paste("Date = ",date) )
    
    # New URL
    #
    url.month = paste(url,"/",date,sep="")
    
    # Download the file
    #
    download.file(url.month,day.fname,quiet=TRUE)
    
    # read it
    #
    html=scan(day.fname,"character")
    
    cl <- makeCluster(8)
    registerDoParallel(cl)

    foreach( lon=h, .export="addZero") %dopar% {
      for ( lat in v ) {
        pattern = paste(".(h",addZero(lon),"v",addZero(lat),").*(hdf)<",sep="")
        scene   = html[grep(pattern,html)]
        # Just get what's in the > and < (the file name)
        #
        info    = regexpr(">(.*)<",scene)
        fname   = substring(scene, info[1]+1,  info[1]+attr(info,"match.length")-2)
        
        # MAke sure that this file exists in the data
        #
        if ( !identical(fname, character(0)))    {
          # And now.... download this file
          #
          url.scene = paste(url.month,"/",fname,sep="")
          ofname    = paste(tmp.dir,fname,sep="")
          
          #files       = rbind(ret, c(date, ofname))
          
          # Download only if it does not exist
          #
          if (!file.exists(ofname)) {
            extra = paste("--http-user=",username," --http-password=",pwd,sep="")
            print(paste("Downloading",url.scene,extra))
            
            download.file(url.scene,ofname,method="wget",quiet=TRUE,extra=extra)
          }
        }
      }
    }
    
    stopCluster(cl)
  }  # End looping through the dates
  
  files = dir(path=tmp.dir, pattern=paste("^",product,".A",year,".*(hdf)$",sep=""))
  
  # Remove those files that do not exist and those that are small
  #
  v1      = as.vector(sapply(files, file.exists))
  sizes   = as.vector(unlist(sapply(files, file.info)[1,]))
  v2      = sizes > 100
  files   = files[v1&v2]
  
  return(files)
}


modis.mosaic = function( files, 
                         MRTpath="~/local/MRT/bin",
                         pixel_size=.00250, 
                         proj=T, 
                         proj_type="GEO") {
  
  # Get the dates and 
  #
  id      = regexpr("A[0-9]{6}",files)
  temp    = substring(files,id+1,id+attr(id,"match.length"))
  jd      = as.numeric(substring(temp,5,7))
  
  # Convert from Julian
  #
  dates   = as.Date(jd-1,origin=paste(year,"-01-01",sep=""))
  dates   = as.vector(gsub("-",".",dates))
  dHDF    = data.frame(Date=dates,Name=files)
  
  ModisMosaic(dHDF,mosaic=T, 
              MRTpath,pixel_size=pixel_size, proj=proj, proj_type=proj_type)
}


# pattern=".Lai_1km\\.tif$", filename,

modis.calibrate.merge = function(files, offset, gain, valid ) {
  
  # Now merge the mosaics for each day.  This takes a bit of time
  #
  merged = list()
  
  for ( i in 1:length(files) ) {
    print(paste("Loading",files[i]))
    
    temp  = raster(files[i])
    values  = values(temp)
    values[ values<valid[1] | values>valid[2] ] = NA
    values = values*gain + offset
    values(temp) = values
    
    merged[[i]] = temp
  }
  
  merged.stack = stack(merged)
  res          = calc(merged.stack, mean, na.rm=T)
  
  return(res)
}



# The following two functions have been adopted from ModisDownload.R
# Version: 3.3, 6th Oct. 2014
# Author: Babak Naimi (naimi.b@gmail.com)
#


ModisMosaic = function(dHDF,MRTpath,mosaic=FALSE,bands_subset='1 1 0 0 0 0 0 0 0 0 0 0',delete=TRUE,proj=FALSE,UL="",LR="",resample_type='NEAREST_NEIGHBOR',proj_type='UTM', proj_params='0 0 0 0 0 0 0 0 0 0 0 0',datum='WGS84',utm_zone=NA,pixel_size) {
  
  #dHDF <- .getMODIS(x,h,v,dates,version)
  dHDF$Date <- as.character(dHDF$Date)
  dHDF$Name <- as.character(dHDF$Name)
  if (nrow(dHDF) < 2) mosaic <- FALSE
  if (mosaic) {
    
    du <- unique(dHDF$Date)
    
    for (d in du) {
      dw <- dHDF[which(dHDF$Date == d),]
      if (nrow(dw) > 1){
        date_name <- sub(sub(pattern="\\.", replacement="-", d), pattern="\\.", replacement="-", d)
        name <- paste("Mosaic_",date_name,".hdf",sep='')
        Mosaic.success <- mosaicHDF(dw$Name,name,MRTpath=MRTpath,bands_subset=bands_subset,delete=delete)
        if (Mosaic.success) {
          if (delete) for (ModisName in dw[,2]) unlink(paste(getwd(), '/', ModisName, sep=""))
          if (proj) {
            pref <- strsplit(dw[1,2],'\\.')[[1]][1]
            e <- reprojectHDF(name,filename=paste(pref,'_',date_name,'.tif',sep=''),MRTpath=MRTpath,UL=UL,LR=LR,proj_type=proj_type,proj_params=proj_params,utm_zone=utm_zone,pixel_size=pixel_size)
            if (e & delete) unlink(paste(name))
            if (!e) warning (paste("The procedure has failed to REPROJECT the mosaic image for date ",d,"!",sep=""))
          }
        } else {
          warning(paste("The procedure has failed to MOSAIC the images for date ",d,"!",sep=""))
          if (proj) {
            warning ("Since the mosaic is failed, the individual hdf images are reprojected...")
            pref <- strsplit(dw[1,2],'\\.')[[1]]
            pref <- paste(pref[1],"_",pref[3],sep="")
            for (ModisName in dw[,2]) {
              e <- reprojectHDF(ModisName,filename=paste(pref,'_',date_name,'.tif',sep=''),MRTpath=MRTpath,UL=UL,LR=LR,bands_subset=bands_subset,proj_type=proj_type,proj_params=proj_params,utm_zone=utm_zone,pixel_size=pixel_size)
              if (e & delete) unlink(paste(ModisName))
              if (!e) warning (paste("The procedure has failed to REPROJECT the individual HDF image ",ModisName,"!",sep=""))
            }
          }
        } 
      }
    }   
  } else {
    if (proj) {
      for (i in 1:nrow(dHDF)) {
        ModisName <- dHDF[i,2]
        pref <- strsplit(ModisName,'\\.')[[1]]
        pref <- paste(pref[1],"_",pref[3],sep="")
        d <- dHDF[i,1]
        date_name <- sub(sub(pattern="\\.", replacement="-", d), pattern="\\.", replacement="-", d)
        e <- reprojectHDF(ModisName,filename=paste(pref,'_',date_name,'.tif',sep=''),MRTpath=MRTpath,UL=UL,LR=LR,bands_subset=bands_subset,proj_type=proj_type,proj_params=proj_params,utm_zone=utm_zone,pixel_size=pixel_size)
        if (e & delete) unlink(paste(ModisName))
        if (!e) warning (paste("The procedure has failed to REPROJECT the individual HDF image ",ModisName,"!",sep=""))
      }
    }
  }
  
}


mosaicHDF = function(hdfNames,filename,MRTpath,bands_subset='1 1 0 0 0 0 0 0 0 0 0 0',delete=TRUE) {
  if (missing(MRTpath)) stop("MRTpath argument should be specified...")
  if (length(hdfNames) < 2) stop("mosaic cannot be called for ONE image!")
  if (missing(bands_subset))  bands_subset <- ''
  if (missing(delete)) delete <- FALSE
  
  mosaicname = file(paste(MRTpath, TmpMosaic, sep=""), open="wt")
  write(paste(getwd(),"/",hdfNames[1], sep=""), mosaicname)
  for (j in 2:length(hdfNames)) write(paste(getwd(),"/",hdfNames[j], sep=""),mosaicname,append=T)
  close(mosaicname)
  # generate mosaic:
  
  if (bands_subset != '') {
    e <- system(paste(MRTpath, '/mrtmosaic -i ', MRTpath, paste0(TmpMosaic,' -s "'),bands_subset,'" -o ',getwd(), '/',filename, sep=""))
    if (e != 0) warning ("Mosaic failed! 'bands_subset' may has incorrect structure!")
  } else {
    e <- system(paste(MRTpath, '/mrtmosaic -i ', MRTpath, paste0(TmpMosaic,' -o '),getwd(), '/',filename, sep=""))
    if (e != 0) warning ("Mosaic failed!")
  }
  if (delete & e == 0) for (ModisName in hdfNames) unlink(paste(getwd(), '/', ModisName, sep=""))
  if (e == 0) return (TRUE)
  else return (FALSE)
}

reprojectHDF = function(hdfName,filename,MRTpath,UL="",LR="",resample_type='NEAREST_NEIGHBOR',proj_type='UTM',
                        bands_subset='',proj_params='0 0 0 0 0 0 0 0 0 0 0 0',datum='WGS84',utm_zone=NA,pixel_size=1000) {
  
  fname = file('tmp.prm', open="wt")
  write(paste('INPUT_FILENAME = ', getwd(), '/',hdfName, sep=""), fname) 
  if (bands_subset != '') {
    write(paste('SPECTRAL_SUBSET = ( ',bands_subset,' )',sep=''),fname,append=TRUE)
  }
  if (UL[1] != '' & LR[1] != '') {
    write('SPATIAL_SUBSET_TYPE = OUTPUT_PROJ_COORDS', fname, append=TRUE)
    write(paste('SPATIAL_SUBSET_UL_CORNER = ( ', as.character(UL[1]),' ',as.character(UL[2]),' )',sep=''), fname, append=TRUE)
    write(paste('SPATIAL_SUBSET_LR_CORNER = ( ', as.character(LR[1]),' ',as.character(LR[2]),' )',sep=''), fname, append=TRUE)
  }
  write(paste('OUTPUT_FILENAME = ', filename, sep=""), fname, append=TRUE)
  write(paste('RESAMPLING_TYPE = ',resample_type,sep=''), fname, append=TRUE)
  write(paste('OUTPUT_PROJECTION_TYPE = ',proj_type,sep=''), fname, append=TRUE)
  write(paste('OUTPUT_PROJECTION_PARAMETERS = ( ',proj_params,' )',sep=''), fname, append=TRUE)
  write(paste('DATUM = ',datum,sep=''), fname, append=TRUE)
  if (proj_type == 'UTM') write(paste('UTM_ZONE = ',utm_zone,sep=''), fname, append=TRUE)
  write(paste('OUTPUT_PIXEL_SIZE = ',as.character(pixel_size),sep=''), fname, append=TRUE)
  close(fname)
  e <- system(paste(MRTpath, '/resample -p ',getwd(),'/','tmp.prm', sep=''))
  if (e == 0) return (TRUE)
  else return(FALSE)
}


# Display a list of products that can be processed
#
modisProducts <- function() {
  load('ModisLP.RData')
  return(.ModisLPxxx)
  rm(.ModisLPxxx)
}



#######################

modis.rescale = function(temp, offset, gain, valid ) {
  
  values  = values(temp)
  values[ values<valid[1] | values>valid[2] ] = NA
  values = values*gain + offset
  values(temp) = values
  
  return(temp)
}

########################


# Bulk rescale +save function
modis.bulk.rescale = function(files, offset, gain, valid ) {
  
  merged = list()
  
  for ( i in 1:length(files) ) {
    print(paste("Loading",files[i]))
    
    temp  = raster(files[i])
    values  = values(temp)
    values[ values<valid[1] | values>valid[2] ] = NA
    values = values*gain + offset
    values(temp) = values
    
    merged[[i]] = temp
    writeRaster(merged[[i]], file=files[[i]],format="GTiff", overwrite=T)
  }
  
}
########################

