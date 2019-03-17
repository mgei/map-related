library(tidyverse)
library(rgdal)
library(ggmap)

pictures <- list.files("../img/.", include.dirs = F, recursive = F,
                       pattern = ".png$") %>% 
  enframe(name = "n") %>% 
  mutate(id = str_remove(value, "W_") %>% str_remove("L.png"),
         set = "main") %>% 
  mutate(id = as.integer(id))

data <- read_delim("../data/interval3.5m-gps.csv", " ", col_names = F) %>% 
  rename(x = 4, y = 5, obs = 2) %>%
  filter(obs %in% pictures$id) %>% 
  left_join(pictures, by = c("obs" = "id"))


orig_coords <- data %>% select(lat = x, lon = y, obs, value, set)
coordinates(orig_coords) <- c('lat', 'lon')

proj4string(orig_coords) <- CRS("+init=epsg:27572")

Metric_coords <- spTransform(orig_coords, CRS("+init=epsg:4326"))

tomap <- Metric_coords %>% 
  as_tibble() %>% 
  select(obs, Longitude = lat, Latitude = lon, value, set) %>% 
  mutate(col = if_else(set == "main", "blue", "red"))

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

  ggsave(paste0("../staticmap/map_", tomap[i, "value"]), plot)
}

print("static map images should be in the folder")
