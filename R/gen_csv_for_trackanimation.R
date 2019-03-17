library(tidyverse)
library(rgdal)
library(readxl)
library(anytime)

# read pictures
pictures <- list.files("../img/.", include.dirs = F, recursive = F,
                       pattern = ".png$") %>% 
  enframe(name = "n") %>% 
  mutate(id = str_remove(value, "W_") %>% str_remove("L.png"),
         set = "main") %>% 
  mutate(id = as.integer(id))

# read CSV location data and join with pictures (only overlapping are relevant)
data <- read_delim("../data/interval3.5m-gps.csv", " ", col_names = F) %>% 
  mutate(Date = X1 %>% str_sub(1,10) %>% as.integer() %>% anytime(),
         x = X4, y = X5, obs = X2) %>% 
  filter(obs %in% pictures$id) %>% 
  left_join(pictures, by = c("obs" = "id"))

orig_coords <- data %>% select(lat = x, lon = y, obs, value, set, Date)

coordinates(orig_coords) <- c('lat', 'lon')

# adjust projection, we have some French projection in the input location CSV
proj4string(orig_coords) <- CRS("+init=epsg:27572")

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

tomap %>% write.csv("../data/tomap.csv")
