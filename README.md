# Map related things

The goal is to create a map animation with **trackanimation** (https://pypi.org/project/trackanimation/). First we have to reformat the location data (French coordinates). For this we use **R** with `rgdal`. Then we use this in Python to generate the animation.

# R to generate the data

**trackanimation** can work with *GPX* data or with simple locations. We have just locations in a CSV file. To have the right format, trackanimation needs the following fields:

* CodeRoute: Route number, could be distinguished with colors or so. We just set it to 1.
* Latitude
* Longitude
* Altitude: We don't have, we set to 0
* Data: Originally we have a Unix timestamp. In R we convert it with `anytime::anytime()`. Note that strangly only the first 10 characters are actually timestamp, we subset the string.
* Speed: We don't have, set 0. Could theoretically be computed.
* TimeDifference: Not needed but simple computation as `as.double(Data - lag(Date))`
* Distance: Again could be computed, we set 0 because we're lazy
* FileName: No relevance, we choose the id

Write to `data/tomap.csv`

# Python trackanimation

`make_trackanimation.py`: Very simple, the library does the work for us.

![](preview.gif)
