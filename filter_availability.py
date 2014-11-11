#!/usr/bin/env python
#
# file: filter_availability.py
#
# description:
#   extracts bike availability at 15 minute intervals from citibike data
#
#   ** NOTE **: requires manual rename of stations to names in fixed_station_names.txt
#
# usage:
#   run from directory containing per-station bike availability csv files
#
#     python filter_availability > availability.tsv
#
#   output is (station name, timestamp, interval, bikes)
#python filter_availability > availability.tsv



import sys
from glob import glob
import os
import re

INTERVAL = 15*60

if __name__=='__main__':
    # take path to csv files as optional argument
    if len(sys.argv) > 1:
        path = sys.argv[1]
    else:
        path = '.'

    # iterate over all station files
    for filename in glob(path + '/*.csv'):

        # extract station name from filename#
        match = re.search('\\\\([^/]+?)-available.csv', filename)
        
        if match.group(1) == "Water - Whitehall-Plaza":
            station = "Water - Whitehall Plaza"
        else: 
            station = match.group(1).replace("-and-", " & ")
            station = station.replace('-', ' ')
        
        prev_interval = None
        for n, line in enumerate(open(filename, 'r')):
            # skip the header
            if n == 0:
                continue

            # pull out timestamp in seconds and number of bikes
            ts, bikes = map(int, line.rstrip('\n').split(','))

            # round timestamp down to nearest interval
            curr_interval = (ts/INTERVAL)*INTERVAL

            # print availability when we move to a new interval
            # and increment interval
            if curr_interval != prev_interval:
                print "%s\t%s\t%s\t%s" % (station, ts, curr_interval, bikes)
                prev_interval = curr_interval


