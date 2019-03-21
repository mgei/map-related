library(tidyverse)
library(lubridate)


tomap <- read_csv("data/tomap.csv")

gsp <- read_csv("data/GPS_imageInfo2.csv")

gsp %>% mutate(mydate = ymd_hm(Date)) %>% 
  group_by(mydate) %>% 
  mutate(millisec = row_number()) %>% 
  filter(millisec <= 60) %>% 
  ungroup() %>% 
  mutate(millisec = str_pad(millisec, width = 2, pad = "0", side = "left"),
         Date = str_c(Date, ":", millisec)) %>% 
  select(-X1) -> gps

gps %>% write.csv("data/gps.csv")


gsp %>% ggplot(aes(x = Longitude, y = Latitude, color = X1)) + 
  geom_point() 

gps %>% mutate(Date = ymd_hms(Date)) %>% 
  ggplot(aes(x = Longitude, y = Latitude, color = Date)) + 
  geom_point() +
  geom_label(aes(label = Date))
