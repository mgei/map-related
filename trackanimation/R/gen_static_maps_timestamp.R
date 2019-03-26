# R generate static maps with ggmap

library(tidyverse)
library(rgdal)
library(ggmap)
library(anytime)


generate_sta <- function(#imagedir = "../img/.",
                         #imgprefix = "W_",
                         #imgsuffix = "L.png",
                         csvpath = "../data/interval3.5m-gps.csv",
                         csvdelim = " ",
                         datecol = "X1",
                         xcol = "X4",
                         ycol = "X5",
                         obscol = "X2",
                         projection = "+init=epsg:27572",
                         outputdir = "../staticmap2/") {
  
  # pictures <- list.files(imagedir, include.dirs = F, recursive = F,
  #                        pattern = ".png$") %>% 
  #   enframe(name = "n") %>% 
  #   mutate(id = str_remove(value, imgprefix) %>% str_remove(imgsuffix),
  #          set = "main") %>% 
  #   mutate(id = as.integer(id))
  
  data <- read_delim(csvpath, csvdelim, col_names = F) %>%
    rename(Date = datecol, x = xcol, y = ycol, obs = obscol) %>% 
    mutate(Date = Date %>% str_sub(1,10) %>% as.integer(),
           Date_asdate = Date %>% anytime()) %>% 
    select(Date, Date_asdate, obs, x, y)
  
  # unique timestamp, take the first
  data %>% 
    group_by(Date) %>% 
    summarise(Date_asdate = first(Date_asdate),
              obs = first(obs),
              x = first(x), y = first(y)) %>% 
    ungroup() -> data
  
  orig_coords <- data %>% select(lat = x, lon = y, obs, Date, Date_asdate)
  coordinates(orig_coords) <- c('lat', 'lon')
  
  proj4string(orig_coords) <- CRS(projection)
  
  Metric_coords <- spTransform(orig_coords, CRS("+init=epsg:4326"))
  
  tomap <- Metric_coords %>% 
    as_tibble() %>% 
    select(obs, Longitude = lat, Latitude = lon, Date, Date_asdate) %>% 
    mutate(set = "main",
           col = if_else(set == "main", "blue", "red"))
  
  # get static map from Google
  if(!file.exists("api.key")) { 
    stop("you need a Google Map API key and put it in a file called api.key") }
  
  #key <- read_file("api.key")
  key <- readChar("api.key", file.info("api.key")$size - 1)
  register_google(key)
  
  mapcenter <- tomap %>% summarise(lon = mean(Longitude),
                                   lat = mean(Latitude)) %>% 
    unlist()
  
  statmap <- get_map(location = mapcenter, 
                     zoom = 16)
  
  
  for (i in 1:nrow(tomap)) {
    plot <- ggmap(statmap, extent = "device") + 
      geom_point(data = tomap[i,], aes(x = Longitude, y = Latitude),
                 size = 6, color = "red")
    
    ggsave(paste0(outputdir, tomap[i, "Date"], ".png"), plot)
  }
  
  print("static map images should be in the folder")
  
}

# if __name__ == ”__main__“
if (!interactive()) {
  generate_sta()
}
