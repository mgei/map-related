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
with the following.

    # To install the version from CRAN
    install.packages("osrm")

    library(osrm)

    ## Data: (c) OpenStreetMap contributors, ODbL 1.0 - http://www.openstreetmap.org/copyright

    ## Routing: OSRM - http://project-osrm.org/

    ??osrm

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

The first step of installing Docker might take 30 minutes or so. The
second step is also pretty straightforward if you follow the *Quick
Start* section in the Docker Hub link provided above.

The OpenStreetMap data required to compute paths can be downloaded from
<a href="http://download.geofabrik.de" class="uri">http://download.geofabrik.de</a>.
For this project we want the latest data (\*.osm.pbf) of Switzerland,
which can be downloaded
(here)\[<a href="http://download.geofabrik.de/europe/switzerland-latest.osm.pbf" class="uri">http://download.geofabrik.de/europe/switzerland-latest.osm.pbf</a>\].


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
    100   797  100   797    0     0  88555      0 --:--:-- --:--:-- --:--:-- 88555
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

[1] <a href="https://en.wikipedia.org/wiki/Open_Source_Routing_Machine" class="uri">https://en.wikipedia.org/wiki/Open_Source_Routing_Machine</a>
