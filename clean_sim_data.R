library(data.table)
library(plyr)

# read simulation data
simulation <- data.frame()
for (strategy in c('greedy','rider')) {
    # read in simulation results for this strategy
    sim_file <- sprintf("data/sim_%s.tsv", strategy)
    print(sim_file)
    sim_data <- read.delim(sim_file, header=F)
    colnames(sim_data) <- c("ymdhms","start.station.name","start.available.bikes","start.station.cap","start.station.prox"
			,"end.station.name","end.available.bikes","end.station.cap","end.station.prox")
    sim_data <- data.table(sim_data)

    # round time down to nearest 15 minute bin
    sim_data <- sim_data[, starttime := floor(as.numeric(as.POSIXct(ymdhms,origin="1970-01-01"))/(15*60))*(15*60)]

    # create column for 15 minute interval within the day
    sim_data <- sim_data[, rounded.interval := strftime(as.POSIXct(starttime, origin="1970-01-01"),format="%H:%M")]

    # create column for strategy ("greedy" or "rider")
    sim_data$strategy <- strategy

    # append to one big data frame
    simulation <- rbind(simulation, sim_data)
}

save(simulation, file="data/simulation.RData")
