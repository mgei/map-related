# JPG images that have the location saved, we want to extract that info and save it separately

library(exifr)
library(tidyverse)
library(leaflet)

path  <- "../data/images"
files <- list.files(path = path, pattern = "*.JPG")
dat   <- read_exif(path, recursive = T)
