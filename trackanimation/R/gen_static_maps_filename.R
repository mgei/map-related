# R generate static maps with ggmap

library(tidyverse)
library(rgdal)
library(ggmap)

csvpath <- "../data/GPS_imageInfo2.csv"
data <- read_csv(csvpath)

  
# get static map from Google
if(!file.exists("api.key")) {
  stop("you need a Google Map API key and put it in a file called api.key") }

#key <- read_file("api.key")
key <- readChar("api.key", file.info("api.key")$size - 1)
register_google(key)

mapcenter <- data %>% summarise(lon = mean(Longitude),
                                 lat = mean(Latitude)) %>%
  unlist()
  
statmap <- get_map(location = mapcenter, 
                   zoom = 16,
                   color = "color")
  
mapsoutput <- "../staticmap3/"

for (i in 1:30) {
  plot <- ggmap(statmap, extent = "device", maprange = T) +  #
    geom_point(data = data[i,], aes(x = Longitude, y = Latitude),
               size = 2, color = "red")
  
  ggsave(filename = paste0(mapsoutput, data[i, "FileName"]), 
         plot = plot,
         scale = 0.5,
         width = 3, height = 3,
         dpi = 300)
}

