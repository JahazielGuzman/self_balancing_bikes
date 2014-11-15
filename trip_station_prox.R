library(data.table)
library(dplyr)
library(fossil)
load("data/trips.RData")

trips <- mutate(trips, 
                distance = deg.dist(start.station.longitude, 
                                    start.station.latitude, 
                                    end.station.longitude, 
                                    end.station.latitude)
                )

trips <- data.table(trips)

trips <- trips[start.station.name != end.station.name ,
               list(start.station.name, end.station.name, distance), 
               by=start.station.name]

names(trips) <- c("station.1", "imposter", "station.2", "d")
trips <- trips[, c(1,3,4), with=FALSE]

write.csv(trips, "data/trips_stationprox.csv")