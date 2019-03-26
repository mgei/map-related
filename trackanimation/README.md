# 1. Using the trackanimation library

The goal is to create a map animation with **trackanimation** (https://pypi.org/project/trackanimation/). First we have to reformat the location data (French coordinates). For this we use **R** with `rgdal`. Then we use this in Python to generate the animation.

## R to generate the data

**trackanimation** can work with *GPX* data or with simple locations. We have just locations in a CSV file. To have the right format, trackanimation needs the following fields:

* CodeRoute: Route number, could be distinguished with colors or so. We just set it to 1.
* Latitude
* Longitude
* Altitude: We don't have, we set to 0
* Date: Originally we have a Unix timestamp. In R we convert it with `anytime::anytime()`. Note that strangly only the first 10 characters are actually timestamp, we subset the string.
* Speed: We don't have, set 0. Could theoretically be computed.
* TimeDifference: Not needed but simple computation as `as.double(Data - lag(Date))`
* Distance: Again could be computed, we set 0 because we're lazy
* FileName: No relevance, we choose the id

Write to `data/tomap.csv`

## Python trackanimation

`make_trackanimation.py`: Very simple, the library does the work for us.

![](preview.gif)

# 2. Create a video from individual static map images

The idea here is that these can be used for making a video, e.g. using OpenCV in Python.

We use R and **ggmap** (https://github.com/dkahle/ggmap) for this.

`Rscript gen_static_maps.R`. What it does:

1. Download a static map with `get_map(loc, zoom)` (Google API key required!)
2. Loop and save

# 3. Create a video from individual static map images with timestamp

## 3.1. Generate map images

`R/gen_static_maps_timestamp.R` takes the CSV we have. The first 10 digits from one column in our data is the UNIX timestamp. First we remove the double enteries (`dplyr::distinct()`) and just take the first coordinate positions recorded (`dplyr::first()`).

See the function variable inputs before running.

## 3.2. Generate video with OpenCV

`Python/make_video_opencv.py` is simple code to generate a video from the images previously saved.
