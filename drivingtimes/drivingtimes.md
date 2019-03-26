Intro
=====

Imagine you just fell out of a plane over Switzerland and landed at a
random location. As you are wounded your number one concern it to get to
a hospital asap. Not any hospital but one that has an emergency room and
is equiped at least with a CT (computer tomography).

In the following we want to create a map that shows the *driving time*
to the closest emergency hospital. We use the following:

-   a public list of Swiss hospitals
-   our own OSRM server (Docker) to estimate driving times
-   2D interpolation and mapping functions in R (ggmap, raster, sp etc.)
-   leaflet to create an interactive map

Preparation
===========

OSRM server
-----------

> The Open Source Routing Machine or OSRM is a C++ implementation of a
> high-performance routing engine for shortest paths in road networks.
> Licensed under the permissive 2-clause BSD license, OSRM is a free
> network service. OSRM supports Linux, FreeBSD, Windows, and Mac OS X
> platform.[1]

There is a [OSRM package for R](https://github.com/rCarto/osrm) that
makes it easy to send requests to a OSRM server. It can be installed
from CRAN.

    install.packages("osrm")

    library(osrm)

    ## Data: (c) OpenStreetMap contributors, ODbL 1.0 - http://www.openstreetmap.org/copyright

    ## Routing: OSRM - http://project-osrm.org/

By default the OSRM package uses a public demo server.

    getOption("osrm.server")

    ## [1] "http://router.project-osrm.org/"

The public server is fine for testing but not for sending too many
requests in a short time. It will give errors and not work. Therefore it
is suggested to get your own instance of OSRM.

The easiest solution is to run it with Docker. This requires 2
preparatory steps:

1.  Install Docker CE
    <a href="https://docs.docker.com/install/" class="uri">https://docs.docker.com/install/</a>
2.  Get the *osrm-backend* running
    <a href="https://hub.docker.com/r/osrm/osrm-backend/" class="uri">https://hub.docker.com/r/osrm/osrm-backend/</a>

The first step of installing Docker might take 30 minutes. The second
step is also pretty straightforward if you follow the *Quick Start*
section in the Docker Hub link provided above.

The OpenStreetMap data required to compute paths can be downloaded from
<a href="http://download.geofabrik.de" class="uri">http://download.geofabrik.de</a>.
For this project we want the latest data (\*.osm.pbf) of Switzerland,
which can be downloaded
[here](http://download.geofabrik.de/europe/switzerland-latest.osm.pbf).


    wget http://download.geofabrik.de/europe/switzerland-latest.osm.pbf

Then run the following:


    docker run -t -v "${PWD}:/data" osrm/osrm-backend osrm-extract -p /opt/car.lua /data/switzerland-latest.osm.pbf

    docker run -t -v "${PWD}:/data" osrm/osrm-backend osrm-partition /data/switzerland-latest.osrm
    docker run -t -v "${PWD}:/data" osrm/osrm-backend osrm-customize /data/switzerland-latest.osrm

    docker run -t -i -p 5000:5000 -v "${PWD}:/data" osrm/osrm-backend osrm-routed --algorithm mld /data/switzerland-latest.osrm

The last command will run the docker container. You can check it is
running with `bash docker container ls`. Also let’s request a route from
Zurich (47.3769 N, 8.5417 E) to Geneva (46.2044 N, 6.1432 E).


    curl "http://127.0.0.1:5000/route/v1/driving/8.5417,47.3769;6.1432,46.2044?steps=false"

    ##   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
    ##                                  Dload  Upload   Total   Spent    Left  Speed
    ## 
      0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
    100   797  100   797    0     0  99625      0 --:--:-- --:--:-- --:--:-- 99625
    ## {"code":"Ok","routes":[{"geometry":"shd`Hshcs@_fOz|n@vrA~nHneHpxGbcArjOn{KlqRpoB|aRyRbmYnePveb@``ZphE`sTzeSpbDxvRqpBnwc@daHl|IxnG|xZ`wGbkMu[zsH`pM~ya@kYd_Fl{BzxIj~AxwBjkWncBtoJkvA~pKdbZlzAveRzoJbvThqPhqMhsTxH","legs":[{"steps":[],"distance":276508.9,"duration":11477.7,"summary":"","weight":11477.7}],"distance":276508.9,"duration":11477.7,"weight_name":"routability","weight":11477.7}],"waypoints":[{"hint":"nVwUgP___38OAAAAGgAAAAAAAAAAAAAAK6-EQalSTEEAAAAAAAAAAA4AAAAaAAAAAAAAAAAAAACCAwAABFaCAAPq0gIEVoIABOrSAgAADwZqdrD8","distance":0.111178,"name":"Bahnhofplatz","location":[8.5417,47.376899]},{"hint":"CQAAgP___38BAAAACAAAAAAAAAA7AAAASiGUP5sKg0AAAAAAEjomQgEAAAAIAAAAAAAAADsAAACCAwAA4LxdAO8FwQLgvF0A8AXBAgAADxFqdrD8","distance":0.111155,"name":"Place de Bel-Air","location":[6.1432,46.204399]}]}

If the output is something with “Bahnhofsplatz” and “Place de Bel-Air”
then it is working fine.

Now back in R you want to set the server to your own, so all requests
are handled by your own instance. This has to be done each time after
you load the `osrm` package.

    options(osrm.server = "http://localhost:5000/")

    # check if it's set correctly
    getOption("osrm.server")

    ## [1] "http://localhost:5000/"

Swiss hospital data
-------------------

We will use the [Key figures for Swiss
hospitals](https://www.bag.admin.ch/bag/de/home/zahlen-und-statistiken/zahlen-fakten-zu-spitaelern/kennzahlen-der-schweizer-spitaeler.html)
from the Federal Office of Public Health. The latest dataset as of
writing this is from 2016 (publishment lags by around 2 years). That’s
an spreadsheet that we download to the project’s data directory.


    wget http://www.bag-anw.admin.ch/2016_taglab/2016_spitalstatistik/data/download/kzp16_daten.xlsx -P data/.

We load the data as follows. The relevant sheet we know from exploring
the spreadsheet manually. Also we found out that everything that follows
after row 283 is totals and therefore irrelevant. Note also that we
replace some character called *soft-hyphens* because they generally
cause trouble in my R environment (is it a UTF-8 problem?).

    library(tidyverse)

    ## ── Attaching packages ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── tidyverse 1.2.1 ──

    ## ✔ ggplot2 3.1.0       ✔ purrr   0.3.1  
    ## ✔ tibble  2.0.1       ✔ dplyr   0.8.0.1
    ## ✔ tidyr   0.8.3       ✔ stringr 1.4.0  
    ## ✔ readr   1.3.1       ✔ forcats 0.4.0

    ## ── Conflicts ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────── tidyverse_conflicts() ──
    ## ✖ dplyr::filter() masks stats::filter()
    ## ✖ dplyr::lag()    masks stats::lag()

    library(readxl)

    hospitals <- read_excel(path = "data/kzp16_daten.xlsx",
                            sheet = "KZ2016_KZP16",
                            n_max = 293) %>% 
      # replace soft-hyphens 
      mutate(Inst = gsub("\u00AD", "-", Inst, perl = F),
             Adr = gsub("\u00AD", "-", Adr, perl = F),
             Ort = gsub("\u00AD", "-", Ort, perl = F))

Next we filter the hospitals. We want the ones that have an emergency
room (*NF* for Notfall in the data), as well as a CT (computer
tomography). Also we filter for acute care institutions (*A* for
*Akut*). Lastly we select the columns that we need.

    emergency_hospitals <- hospitals %>%
      filter(str_detect(Akt, "A"),
             str_detect(SL, "NF"),
             str_detect(SA, "CT")) %>% 
      dplyr::select(Inst, Adr, Ort, KT, Akt, SA, LA)

    # three random hospitals
    sample_n(emergency_hospitals, 3)

    ## # A tibble: 3 x 7
    ##   Inst            Adr         Ort      KT    Akt   SA                LA    
    ##   <chr>           <chr>       <chr>    <chr> <chr> <chr>             <chr> 
    ## 1 Hôpital du Jur… Les Fonten… 2610 St… BE    A, R  CT, CC, Dia       Amb, …
    ## 2 Spital Lachen   Oberdorfst… 8853 La… SZ    A     MRI, CT, Angio, … Amb, …
    ## 3 Insel Gruppe A… Freiburgst… 3010 Be… BE    A, R  MRI, CT, PET, CC… Amb, …

    # number of hospitals
    nrow(emergency_hospitals)

    ## [1] 82

Next we geocode the hospitals. For this we first create a new field
*address* that we pass to the Google geocode API. Note that this service
is no longer available for free, but there’s the possibility to get a
free API key if you have never used Google Developer services before.
Ordinary price is $0.005, so for 82 addresses that is $0.41.

    library(ggmap)

    emergency_hospitals <- emergency_hospitals %>% 
      mutate(address = str_c(str_replace_na(Inst, ""),
                             str_replace_na(Adr, ""),
                             str_replace_na(Ort, ""),
                             sep = ", "))

    if(!file.exists("api.key")) { 
      print("you need a Google Map API key and put it in a file called api.key") 
    } else{
      key <- readChar("api.key", file.info("api.key")$size - 1)
      register_google(key)

      emergency_hospitals_geocoded <- emergency_hospitals %>% 
        mutate_geocode(address)
    }

It is advisable to save the geocoded locations.

    emergency_hospitals_geocoded %>% write_rds("data/emergency_hospitals_geocoded.RDS")

Now just for verification, let’s create an interactive map of the
emergency hospitals.

    library(leaflet)

    leaflet() %>% 
      addProviderTiles(providers$CartoDB.Positron) %>% 
      addMarkers(data = emergency_hospitals_geocoded,
                 lng = ~lon, lat = ~lat, popup = ~Inst)

Next we will calculate driving times.

Computation
===========

…

[1] <a href="https://en.wikipedia.org/wiki/Open_Source_Routing_Machine" class="uri">https://en.wikipedia.org/wiki/Open_Source_Routing_Machine</a>
