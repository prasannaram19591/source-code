@echo off
color 0B
echo.
echo ----------------------------------------------------------------------------------------------------------------------------
echo Use this query script to verify the rcrel properties and vdisk properties of V7000 or SVC Global mirrir with change volumes.
echo ----------------------------------------------------------------------------------------------------------------------------
echo.
:rcrelquery
SET PATH=%PATH%;C:\Program Files (x86)\PuTTY
SET /P rcrel_name=Please enter the rc relationship name(rcrelxx): 
echo.
echo Please wait while the rcrelationship %rcrel_name% properties are being collected..
SET cmd_set1=plink -ssh v7k_DR_ip -l username -pw password "lsrcrelationship %rcrel_name% | grep state; lsrcrelationship %rcrel_name% | grep progress; lsrcrelationship %rcrel_name% | grep freeze_time; lsrcrelationship %rcrel_name% | grep aux_change_vdisk_name; lsrcrelationship %rcrel_name% | grep aux_vdisk_name; lsrcrelationship %rcrel_name% | grep master_change_vdisk_name; lsrcrelationship %rcrel_name% | grep master_vdisk_name; lsrcrelationship %rcrel_name% | grep master_vdisk_id; lsrcrelationship %rcrel_name% | grep aux_vdisk_id; lsrcrelationship %rcrel_name% | grep master_change_vdisk_id; lsrcrelationship %rcrel_name% | grep aux_change_vdisk_id"
echo.
%cmd_set1% > rcrel_prop.txt
echo -----------------------------------
echo    State and Progress
echo -----------------------------------
for /f "tokens=1*" %%A in (rcrel_prop.txt) Do Set "%%A=%%B"
set | find /i "state="
for /f "tokens=1*" %%A in (rcrel_prop.txt) Do Set "%%A=%%B"
set | find /i "progress="
for /f "tokens=1*" %%A in (rcrel_prop.txt) Do Set "%%A=%%B"
set | find /i "_time="
echo -----------------------------------
echo.
:verbosequery
SET /p next_query=Do you want to verify the properties of vdisks used in %rcrel_name% (y/n)? 
IF /I "%next_query%"=="y" goto vdiskquery
IF /I "%next_query%"=="n" goto nextrcquery
echo you have entered an invalid input. Enter either y/n
goto verbosequery
:nextrcquery
DEL rcrel_prop.txt
SET /p next_query=Do you want to query another rcrelationship(y/n)? 
IF /I "%next_query%"=="y" goto rcrelquery
IF /I "%next_query%"=="n" goto exit
echo you have entered an invalid input. Enter either y/n
goto nextrcquery
:vdiskquery
echo.
echo -----------------------------------
echo  Master and Auxiliary Vdisk names
echo -----------------------------------
for /f "tokens=1*" %%A in (rcrel_prop.txt) Do Set "%%A=%%B"
set | find /i "master_vdisk_name="
for /f "tokens=1*" %%A in (rcrel_prop.txt) Do Set "%%A=%%B"
set | find /i "master_change_vdisk_name="
for /f "tokens=1*" %%A in (rcrel_prop.txt) Do Set "%%A=%%B"
set | find /i "aux_vdisk_name="
for /f "tokens=1*" %%A in (rcrel_prop.txt) Do Set "%%A=%%B"
set | find /i "aux_change_vdisk_name="
echo.
echo -----------------------------------
echo   Master and Auxiliary Vdisk ids
echo -----------------------------------
for /f "tokens=1*" %%A in (rcrel_prop.txt) Do Set "%%A=%%B"
set | find /i "master_vdisk_id="
for /f "tokens=1*" %%A in (rcrel_prop.txt) Do Set "%%A=%%B"
set | find /i "master_change_vdisk_id="
for /f "tokens=1*" %%A in (rcrel_prop.txt) Do Set "%%A=%%B"
set | find /i "aux_vdisk_id="
for /f "tokens=1*" %%A in (rcrel_prop.txt) Do Set "%%A=%%B"
set | find /i "aux_change_vdisk_id="
echo.
echo Please wait while the attributes of vdisks associated with %rcrel_name% are being collected..
SET mas_disk=plink -ssh v7k_PROD_ip -l username -pw password "lsvdisk %master_vdisk_id% | grep capacity; lsvdisk %master_vdisk_id% | grep volume_name; lsvdisk %master_vdisk_id% | grep UID; lsvdisk %master_vdisk_id% | grep se_copy; lsvdisk %master_vdisk_id% | grep compressed_copy; lsvdisk %master_vdisk_id% | grep mdisk_grp_name; lsvdisk %master_vdisk_id% | grep fc_map_count" 
SET mas_cdisk=plink -ssh v7k_PROD_ip -l username -pw password "lsvdisk %master_change_vdisk_id% | grep capacity; lsvdisk %master_change_vdisk_id% | grep volume_name; lsvdisk %master_change_vdisk_id% | grep UID; lsvdisk %master_change_vdisk_id% | grep se_copy; lsvdisk %master_change_vdisk_id% | grep compressed_copy; lsvdisk %master_change_vdisk_id% | grep mdisk_grp_name; lsvdisk %master_change_vdisk_id% | grep fc_map_count"
SET aux_disk=plink -ssh v7k_DR_ip -l username -pw password "lsvdisk %aux_vdisk_id% | grep capacity; lsvdisk %aux_vdisk_id% | grep volume_name; lsvdisk %aux_vdisk_id% | grep UID; lsvdisk %aux_vdisk_id% | grep se_copy; lsvdisk %aux_vdisk_id% | grep compressed_copy; lsvdisk %aux_vdisk_id% | grep mdisk_grp_name; lsvdisk %aux_vdisk_id% | grep fc_map_count" 
SET aux_cdisk=plink -ssh v7k_DR_ip -l username -pw password "lsvdisk %aux_change_vdisk_id% | grep capacity; lsvdisk %aux_change_vdisk_id% | grep volume_name; lsvdisk %aux_change_vdisk_id% | grep UID; lsvdisk %aux_change_vdisk_id% | grep se_copy; lsvdisk %aux_change_vdisk_id% | grep compressed_copy; lsvdisk %aux_change_vdisk_id% | grep mdisk_grp_name; lsvdisk %aux_change_vdisk_id% | grep fc_map_count"
%mas_disk% > diskprop.txt
%mas_cdisk% >> diskprop.txt
%aux_disk% >> diskprop.txt
%aux_cdisk% >> diskprop.txt
SET mas_host=plink -ssh v7k_PROD_ip -l username -pw password "lsvdiskhostmap %master_vdisk_id%"
SET mas_cv_host=plink -ssh v7k_PROD_ip -l username -pw password "lsvdiskhostmap %master_change_vdisk_id%"
SET aux_host=plink -ssh v7k_DR_ip -l username -pw password "lsvdiskhostmap %aux_vdisk_id%"
SET aux_cv_host=plink -ssh v7k_DR_ip -l username -pw password "lsvdiskhostmap %aux_change_vdisk_id%"
echo.
echo ---------------------------------------
echo Master vdisk properties
echo ---------------------------------------
echo.
for /f "skip=9 delims=" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo %Z% 
for /F "skip=10 delims=" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo %Z% 
for /F "skip=12 delims=" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo thin_volume/%Z% 
for /F "skip=14 delims=" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo %Z% 
for /F "skip=15 delims=" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo %Z% 
for /F "delims=capacity" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo total_capacity =%Z% 
for /F "skip=1 delims=used_capacity" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo used_capacity =%Z% 
for /F "skip=2 delims=real_capacity" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo real_capacity =%Z% 
for /F "skip=3 delims=free_capacity" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo free_capacity =%Z% 
for /F "skip=8 delims=uncompressed_used_capacity" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo uncompressed_used_capacity =%Z% 
for /F "skip=19 delims=" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo %Z%
echo Mapped hosts:
echo.
%mas_host%
echo.
echo ---------------------------------------
echo Master change vdisk properties
echo ---------------------------------------
echo.
for /f "skip=29 delims=" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo %Z%
for /F "skip=30 delims=" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo %Z%
for /F "skip=32 delims=" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo thin_volume/%Z%
for /F "skip=34 delims=" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo %Z%
for /F "skip=35 delims=" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo %Z%
for /F "skip=20 delims=capacity" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo total_capacity =%Z%
for /F "skip=21 delims=used_capacity" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo used_capacity =%Z%
for /F "skip=22 delims=real_capacity" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo real_capacity =%Z%
for /F "skip=23 delims=free_capacity" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo free_capacity =%Z%
for /F "skip=28 delims=uncompressed_used_capacity" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo uncompressed_used_capacity =%Z%
for /F "skip=39 delims=" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo %Z%
echo Mapped hosts:
echo.
%mas_cv_host%
echo Change volumes should not be mapped to any hosts. If you see any mappings above, consider deleting it.
echo.
echo ---------------------------------------
echo Auxiliary vdisk properties
echo ---------------------------------------
echo.
for /f "skip=49 delims=" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo %Z%
for /F "skip=50 delims=" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo %Z%
for /F "skip=52 delims=" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo thin_volume/%Z%
for /F "skip=54 delims=" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo %Z%
for /F "skip=55 delims=" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo %Z%
for /F "skip=40 delims=capacity" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo total_capacity =%Z%
for /F "skip=41 delims=used_capacity" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo used_capacity =%Z%
for /F "skip=42 delims=real_capacity" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo real_capacity =%Z%
for /F "skip=43 delims=free_capacity" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo free_capacity =%Z%
for /F "skip=48 delims=uncompressed_used_capacity" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo uncompressed_used_capacity =%Z%
for /F "skip=59 delims=" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo %Z%
echo Mapped hosts:
echo.
%aux_host%
echo.
echo ---------------------------------------
echo Auxiliary change vdisk properties
echo ---------------------------------------
echo.
for /f "skip=69 delims=" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo %Z%
for /F "skip=70 delims=" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo %Z%
for /F "skip=72 delims=" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo thin_volume/%Z%
for /F "skip=74 delims=" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo %Z%
for /F "skip=75 delims=" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo %Z%
for /F "skip=60 delims=capacity" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo total_capacity =%Z%
for /F "skip=61 delims=used_capacity" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo used_capacity =%Z%
for /F "skip=62 delims=real_capacity" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo real_capacity =%Z%
for /F "skip=63 delims=free_capacity" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo free_capacity =%Z%
for /F "skip=68 delims=uncompressed_used_capacity" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo uncompressed_used_capacity =%Z%
for /F "skip=79 delims=" %%i in (diskprop.txt) do (  
  set Z=%%i
  goto BREAK1
)
:BREAK1
echo %Z%
echo Mapped hosts:
echo.
%aux_cv_host%
echo Change volumes should not be mapped to any hosts. If you see any mappings above, consider deleting it.
echo.
DEL diskprop.txt
:anotherquery
DEL rcrel_prop.txt
SET /p next_query=Do you want to query another rcrelationship(y/n)? 
IF /I "%next_query%"=="y" goto rcrelquery
IF /I "%next_query%"=="n" goto exit
echo you have entered an invalid input. Enter either y/n
goto anotherquery
:exit
SET /p exit=Press enter to exit the prompt..
