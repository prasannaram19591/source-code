# fio_benchmarking_scripts

Shell script to perform automatic bench-marking and reporting. This script takes different values of block size, data set size, read/write percentage and number of threads per run as input from file and performs fio tests and prepares a csv report of read/write IOPS and read/write bandwidth reported per run. This could be exported for analysis for storage architecting and design considerations.

Pre-requisites
  1.  Install Fio on any linux distro
  2.  Input various block sizes ex (4k, 8k) one per line and save it as block_size.csv
  3.  Input various data set sizes ex (4M, 8G) one per line and save it as data_size.csv
  4.  Input various thread ex (1, 2, 4) one per line and save it as threads.csv
  5.  Input various read percentages ex (75, 50, 25) one per line and save it as percentage.csv
  6.  Save all the csv and the sh files in a directory
  7.  Change the file permissions to executable by chmod +x seq_rw_mix.sh rand_rw_mix.sh
  8.  Run the script by ./seq_rw_mix.sh for sequential workload bench-marking and reporting
  9.  Run the script by ./rand_rw_mix.sh for random workload bench-marking and reporting
