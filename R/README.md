# R scripts

(Notes to myself)

* `gen_csv_for_trackanimation.R`: generate CSV from our data to be used in Python `trackanimation`, function `generate_csv()`
* `gen_static_maps.R`: generate static map images and save them with `ggmap`. Function `generate_sta()`. It matches the coordinates from the CSV with the pictures we actually have and removes redundant entries.
* `gen_static_maps_timestamp.R`: almost the same but doesn't take into account the pictures in the pic directory. Generates static map images with `ggmap` and saves them with a UNIX timestamp we get from the CSV. Function `generate_sta()`.
* `gen_static_map_filename.R`: generates static maps with the filename info we get from the CSV. Not a function.

* `api.key`: Google Geocoding API key that is needed to download a background map with `ggmap::get_map()`. Gitignored.


* `extract_img_location.R`: some lines of code to get the exif information from pictures, in my case the coordinates taken with my Smartphone.

* `fixing_data_csv.R`: just data verification

## how to remove the white space around the map when saving ggmap

```
plot <- ggmap(statmap, extent = "device", maprange = T) +
    geom_point(data = data[i,], aes(x = Longitude, y = Latitude),
               size = 2, color = "red")
  
ggsave(filename = paste0(mapsoutput, data[i, "FileName"]), 
       plot = plot,
       scale = 0.5,
       width = 3, height = 3,
       dpi = 300)
```
