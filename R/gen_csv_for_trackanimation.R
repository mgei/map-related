# R generate CSV from our data

library(tidyverse)
library(rgdal)
library(readxl)
library(anytime)

generate_csv <- function(imagedir = "../img/.",
                         imgprefix = "W_",
                         imgsuffix = "L.png",
                         csvpath = "../data/interval3.5m-gps.csv",
                         csvdelim = " ",
                         datecol = "X1",
                         xcol = "X4",
                         ycol = "X5",
                         obscol = "X2",
                         projection = "+init=epsg:27572",
                         csvoutput = "../data/tomap.csv") {
  
  # read pictures
  pictures <- list.files(imagedir, include.dirs = F, recursive = F,
                         pattern = ".png$") %>% 
    enframe(name = "n") %>% 
    mutate(id = str_remove(value, imgprefix) %>% str_remove(imgsuffix),
           set = "main") %>% 
    mutate(id = as.integer(id))
  
  
  
  # read CSV location data and join with pictures (only overlapping are relevant)
  data <- read_delim(csvpath, csvdelim, col_names = F) %>%
    rename(Date = datecol, x = xcol, y = ycol, obs = obscol) %>% 
    mutate(Date = Date %>% str_sub(1,10) %>% as.integer() %>% anytime()) %>% 
    filter(obs %in% pictures$id) %>% 
    left_join(pictures, by = c("obs" = "id"))
  
  orig_coords <- data %>% select(lat = x, lon = y, obs, value, set, Date)
  
  coordinates(orig_coords) <- c('lat', 'lon')
  
  # adjust projection, we have some French projection in the input location CSV
  proj4string(orig_coords) <- CRS(projection)
  
  # world coordinates
  Metric_coords <- spTransform(orig_coords, CRS("+init=epsg:4326"))
  
  # save as csv
  tomap <- Metric_coords %>% 
    as_tibble() %>% 
    mutate(Altitude = 0, Speed = 0,
           TimeDifference = as.double(Date - lag(Date)),
           Distance = 0,
           FileName = 1,
           CodeRoute = 1) %>% 
    select(CodeRoute, Latitude = lon, Longitude = lat, 
           Altitude, Date, Speed, TimeDifference, Distance, 
           FileName = obs)
  
  tomap %>% write.csv(csvoutput)

}

# if __name__ == ”__main__“
if (!interactive()) {
  generate_csv()
}


