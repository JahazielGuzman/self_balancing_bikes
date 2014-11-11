# Self-Balancing Bikes

This is the source code for a [Microsoft Data Science Summer School 2014 project](https://ds3.research.microsoft.com/projects) that looks at load imbalance in the CitiBike system.

1. `download_trips.sh`: grabs historical trip data from [CitiBike's site](http://citibikenyc.com/system-data) to local csv files

2. `filter_availability.py`: filters historical [station availability](https://github.com/astanway) to 15 minute intervals

2. `clean_data.R`: loads and parses historical trip data, station capacity, and station availability and saves results as RData file, `clean_citibike.RData`

3. `simulation.py`: runs simulations of system status without van transports, using either original rider routes ('rider' argument) or greedily re-routed trips ('greedy' argument)

4. `clean_sim_data.R`: loads simulation results and saves results as RData file, `simulation.RData`

5. `analysis.R`: generates all results and plots

The code was written by:

* Briana Vecchione (Pace University)
* Franky Rodriguez (St. Joseph's College)
* Donald Hanson (Adelphi University)
* Jahaziel Guzman (Brooklyn College)

Students were mentored by Sharad Goel, Jake Hofman, Justin Rao, and Hanna Wallach.