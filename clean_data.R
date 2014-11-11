library(data.table)
library(reshape)
library(plyr)
library(dplyr)
library(fossil)


# define a function to turn strings into datetimes
parse_datetime <- function(s, format="%Y-%m-%d %H:%M:%S") {
  as.POSIXct(as.character(s), format=format)
}


########################################
# load and clean trip data from download_trips.sh
########################################

# load each month of the trip data into one big data frame
csvs <- Sys.glob('data/citibike/*-tripdata.csv')
trips <- data.frame()
for (csv in csvs) {
  tmp <- read.table(csv, header=T, sep=',', na.strings='\\N')
  trips <- rbind(trips, tmp)
}

# parse the start and stop time strings to datetimes
trips <- transform(trips,
                   starttime=parse_datetime(starttime),
                   stoptime=parse_datetime(stoptime))

# add a column for year/month/day (without time of day)
trips <- transform(trips,
                   ymd=parse_datetime(strftime(starttime, format="%Y-%m-%d"), "%Y-%m-%d"))

# recode gender from (0,1,2) to (Unknown, Male, Female)
trips <- transform(trips, gender=revalue(as.factor(gender), c("0"="Unknown", "1"="Male", "2"="Female")))

# save data frame for easy loading in the future
save(trips, file='data/trips.RData')


########################################
# load and clean station capacity data
########################################
stationcap <- data.table(read.csv("data/station_cap.csv"))
setnames(stationcap, c('station.name', 'station_capacity'),
         c('station.name','station.capacity'))

########################################
# load and clean station availability data
########################################
availability <- read.delim(file = gzfile("data/station_availability.csv"), header = F,
                           col.names = c("station.name", "timestamp", "interval", "bikes.available"))
availability <- mutate(availability,
                       interval = as.POSIXct(interval, origin = "1970-01-01"),
                       rounded.interval = as.character(strftime(interval, format = "%H:%M")),
                       ymd =  as.character(strftime(interval, format = "%Y-%m-%d")),
                       is.weekday = strftime(ymd, format = "%u") < 6
                       )
availability <- data.table(availability)

########################################
# add columns to trips data
########################################
trips <- mutate(trips,
  starthour = as.numeric(as.character(strftime(starttime, format = "%H"))),
  startminutes = as.numeric(as.character(strftime(starttime, format = "%M"))),
  rounded.starttime =  as.factor(sprintf('%02d:%02d',starthour, round_any(startminutes, 15, f=floor))),
  stophour = as.numeric(as.character(strftime(stoptime, format = "%H"))),
  stopminutes = as.numeric(as.character(strftime(stoptime, format = "%M"))),
  rounded.stoptime = as.factor(sprintf('%02d:%02d',stophour, round_any(stopminutes, 15, f=floor))),
  startymd = as.character(strftime(starttime, format = "%Y-%m-%d")),
  stopymd = as.character(strftime(stoptime, format = "%Y-%m-%d")),
  distance = deg.dist(start.station.longitude, start.station.latitude, end.station.longitude, end.station.latitude),
  is.weekday = strftime(trips$starttime, format = "%u") < 6
  )
trips$ymd <- NULL
trips <- data.table(trips)

# merge start and end station capacity into trips
setkey(stationcap, station.name)
setkey(trips, start.station.name)
trips <- stationcap[trips, nomatch=NA] #for every row in trips, look up matching key
setnames(trips, "station.name", "start.station.name")

# merge station availability into trips
setkey(availability, station.name, ymd, rounded.interval)
setkey(trips, start.station.name, startymd, rounded.starttime)
trips <- availability[trips, nomatch = NA]
setnames(trips, c("station.name", "ymd", "rounded.interval"), c("start.station.name","startymd","rounded.starttime"))
trips$interval <- NULL
trips$timestamp <- NULL
trips$is.weekday <- NULL
setnames(trips, "is.weekday.1", "is.weekday")


###############################################################
# Determines bike transportations by Citibike workers, theft, #
# reparations, etc. Also generates separate dataframes which  #
# show when and where bikes where transported by hour/station.#
###############################################################

# creates a datatable in which the next start station is appended
# to every row.
setkey(trips, starttime)
teleportations <- trips[ , list(
  time.lastknown = stoptime,
  station.disappeared = end.station.name,
  station.reappeared = lead(start.station.name),
  time.reappeared = lead(starttime),
  station.disappeared.latitude = end.station.latitude,
  station.disappeared.longitude = end.station.longitude,
  station.reappeared.latitude = lead(start.station.latitude),
  station.reappeared.longitude = lead(start.station.longitude),
  is.weekday,
  startymd,
  stopymd,
  rounded.time.lastknown = rounded.stoptime,
  rounded.time.reappeared = lead(rounded.starttime),
  hour.lastknown = stophour,
  hour.reappeared = lead(starthour)
),
by = bikeid ][station.disappeared != station.reappeared]

####################################################
# Calculates a given station's 3 nearest neighbors #
# and their corresponding availability/capacity    #
# per hour                                         #
####################################################

stationprox <- trips[ start.station.name != end.station.name , list(
  d = distance[1]),
  by=c("start.station.name", "end.station.name")]
stationprox <- stationprox[ , list(
  end.station.name,
  d,
  rank = rank(d)),
  by=start.station.name][rank <=3]
stationprox <- stationprox[ , list(
  station.1 = start.station.name,
  station.2 = end.station.name,
  d)]
write.csv(stationprox, file="data/stationprox.csv", row.names = FALSE)


########################################
# save all data tables to one RData file
########################################
save(trips, teleportations, stationcap, availability, stationprox, file = "data/clean_citibike.RData")
