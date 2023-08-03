# Data Analysis

This project contains python code to convert raw data to presentable charts which can then be used for a quick analysis.

## Pre-requisites

1.	Python 3.7 or later
2.	Pandas
3.	Xlsxwriter

## Usage

Use this project incase if you want to quckly analyze the raw data like fio data iostat/ifstat data. The python code can be used as a baseline for multiple requirements.

1.	Run fio performance tests on a linux machine using my repo [fio perf runs](https://github.com/prasannaram19591/source-code/tree/main/fio_benchmarking_scripts)
2.	Parallely collect iostat metrics on all the block devices using `iostat -xmt 2 > iostat.txt`
3.	Once the fio perf runs are over, execute the script `./iostat_chart_collector.sh` to allign the raw data to feed as input to the python parser script.
4.	After the above script, execute `python3 iostat_chart_plotter.py` to plot the charts for the raw data collected.
5.	Once the script is executed, it will creata a xlsx file named `iostat-stats-charts.xlsx` that contains the plots for analysis.
