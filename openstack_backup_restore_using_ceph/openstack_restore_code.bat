@Echo Off
setLOCAL EnableDelayedExpansion
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do     rem"') do (
  set "DEL=%%a"
)

Rem Display warning banner
echo.
echo #######################################################
echo #                   USAGE WARNING                     #
echo #######################################################
echo #                                                     #
echo # This code is built to perform restoration tasks on  #
echo #  openstack private cloud machines which will cause  #
echo # the instances to power down and replace data inside #
echo #   it. Please close the terminal immediately if you  #
echo #         are not aware of the implications...        # 
echo #                                                     #
echo #######################################################
echo.

Rem Decrypting ceph and openstack password
color 0B
set code=-xx-xx-xx-xx-xxx-xx-xxx
set chars=0123456789abcdefghijklmnoPqrstuvwxyz
for /L %%N in (10 1 36) do ( for /F %%C in ("!chars:~%%N,1!") do ( set "code=!code:%%N=-%%C!"))
)
set OPSK_PWD=!code:~2,1!!code:~5,1!!code:~8,
echo !OPSK_PWD! > OPSK_auth.tmp

Rem Setting code run time parameters
set agent_type=plink
set connc_type=ssh
set /p OPSK_PWD=<OPSK_auth.tmp
del OPSK_auth.tmp
set PATH=%PATH%;D:\softwares\PuTTY
set ref_count=35
set snp_cnt=0
set invalid_srv=0

Rem Collecting the list of available pools on ceph
!agent_type! -!connc_type! -t ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "echo !OPSK_PWD! | sudo -S sudo ceph osd pool ls" > ceph_pool_list.csv

for /F "tokens=5 delims= " %%r in (ceph_pool_list.csv) do (
	echo %%r > ceph_pool_list.txt
	)
more +1 ceph_pool_list.csv >> ceph_pool_list.txt

Rem Get an instance from user.
:get_instance
set /P vm_name=Enter an instance name to perform a restore: 
echo !vm_name! > opsk_srv_list.lst

Rem Getting controller node time for restore job.
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p res_srt_stamp=<snp_date.tmp
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p now=<snp_date.tmp
echo Timestamp: !now!: Enter an instance name to perform a restore:  >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p now=<snp_date.tmp
echo.
echo Timestamp: !now!: Received !vm_name! as an input for instance name.. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log

Rem colleting Server list project wise to verify the instance provided belongs to which project.
!agent_type! -!connc_type! openstack_client_node_ip -l root -pw !OPSK_PWD! "source /root/ev; openstack project list -f value -c Name > opsk_proj_list.csv"
!agent_type! -!connc_type! openstack_client_node_ip -l root -pw !OPSK_PWD! "cat opsk_proj_list.csv" > opsk_proj_list.csv
echo Timestamp: !now!: Please wait while the server list is being generated to find the project for !vm_name!. Ignore authentication errors if any..
echo.
for /f %%x in (opsk_proj_list.csv) do (
echo Timestamp: !now!: Generating server list for %%x.. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
!agent_type! -!connc_type! openstack_client_node_ip -l root -pw !OPSK_PWD! "source /root/%%x; openstack server list -f value -c Name > %%x_srv_list.csv"
!agent_type! -!connc_type! openstack_client_node_ip -l root -pw !OPSK_PWD! "cat %%x_srv_list.csv" > %%x_srv_list.csv
)
echo.

more +0 opsk_proj_list.csv > opsk_proj_list.doc
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p now=<snp_date.tmp

Rem Setting Project source file on openstack based on server input..
for /f %%x in (opsk_proj_list.doc) do ( setlocal enabledelayedexpansion
	more +0 %%x_srv_list.csv > %%x_srv_list.doc
	for /f %%c in (opsk_srv_list.lst) do (
		echo Timestamp: !now!: verifying if the server %%c is in the %%x. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
		echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
		type %%x_srv_list.doc | findstr /x /c:"%%c" > %%x_srv_proj.doc
		for %%i in (%%x_srv_proj.doc) do @set srv_cnt=%%~zi
		if /i "!srv_cnt!" neq "!invalid_srv!" (
			echo %%x > Project_code.tmp
			!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
			set /p now=<snp_date.tmp
			echo Timestamp: !now!: The instance %%c is under the %%x
			echo Timestamp: !now!: The instance %%c is under the %%x >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
			echo.
			echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
			!agent_type! -!connc_type! openstack_client_node_ip -l root -pw !OPSK_PWD! "source /root/%%x; openstack server show %%c -f value -c id > opsk_srvid.tmp; openstack server show %%c -f value -c 'volumes_attached' | cut -c 5- | sed 's/.$//' > opsk_volid.tmp"
			set "srv_proj="	
			!agent_type! -!connc_type! openstack_client_node_ip -l root -pw !OPSK_PWD! "cat opsk_srvid.tmp" > opsk_srvid.tmp
			!agent_type! -!connc_type! openstack_client_node_ip -l root -pw !OPSK_PWD! "cat opsk_volid.tmp" > opsk_volid.tmp
			goto ceph_id_get
			)
		)
	)
echo Timestamp: !now!: The instance !vm_name! is not under any of the Project. Enter a valid instance name to restore.
echo Timestamp: !now!: The instance !vm_name! is not under any of the Project. Enter a valid instance name to restore. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo.
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
goto get_instance

Rem Code to decide root only instances
:ceph_id_get
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p now=<snp_date.tmp
echo Timestamp: !now!: Please wait while the drive id for the instance !vm_name! is pulled out from openstack and ceph..
echo. 

Rem Determining if the server has attached disks or not..
for %%i in (opsk_volid.tmp) do @set extd_disk_chk=%%~zi
if !extd_disk_chk! lss !ref_count! goto :root_disk_routine
if !extd_disk_chk! gtr !ref_count! goto :extd_disk_routine

Rem Finding root drive and extended drive ids on ceph..
:extd_disk_routine
for /F %%k in (opsk_volid.tmp) do ( 
	for /F %%p in (ceph_pool_list.txt) do ( 
		!agent_type! -!connc_type! -t ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "echo !OPSK_PWD! | sudo -S sudo rbd ls %%p | grep %%k" > %%p_ceph_volfnd.tmp
		for %%i in (%%p_ceph_volfnd.tmp) do @set srv_count=%%~zi
			if !srv_count! geq !ref_count! (
				for /F "tokens=5 delims= " %%r in (%%p_ceph_volfnd.tmp) do ( 
					echo %%r >> !vm_name!_ceph_extd_drive.xlsx
					more +0 !vm_name!_ceph_extd_drive.xlsx > !vm_name!_ceph_extd_drive.tmp
					) 
				)
			)
		)

!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p now=<snp_date.tmp

Rem code block for non-cinder backed bootable volume instances
echo > !vm_name!_ceph_attached_drive.tmp
echo > !vm_name!_ceph_srvfnd.tmp
for /F %%k in (opsk_srvid.tmp) do ( 
	for /F %%p in (ceph_pool_list.txt) do ( 
		!agent_type! -!connc_type! -t ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "echo !OPSK_PWD! | sudo -S sudo rbd ls %%p | grep %%k" > %%p_ceph_srvfnd.tmp
		for %%i in (%%p_ceph_srvfnd.tmp) do @set srv_count=%%~zi
			if !srv_count! geq !ref_count! (
				for /F "tokens=5 delims= " %%r in (%%p_ceph_srvfnd.tmp) do ( 
					echo %%r > !vm_name!_ceph_root_drive.xlsx
					more +0 !vm_name!_ceph_root_drive.xlsx > !vm_name!_ceph_root_drive.tmp
					echo Timestamp: !now!: The root drive for the instance !vm_name! has the below id on ceph..
					echo Timestamp: !now!: The root drive for the instance !vm_name! has the below id on ceph.. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
					echo.
					echo. >> openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log					
					type !vm_name!_ceph_root_drive.tmp
					type !vm_name!_ceph_root_drive.tmp > !vm_name!_root_id.docx
					type !vm_name!_ceph_root_drive.tmp >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
					echo.
					echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
					echo Timestamp: !now!: The extended drive for the instance !vm_name! has the below id on ceph..
					echo Timestamp: !now!: The extended drive for the instance !vm_name! has the below id on ceph.. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
					echo.
					echo. >> openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
					type !vm_name!_ceph_extd_drive.tmp
					type !vm_name!_ceph_extd_drive.tmp > !vm_name!_extd_id.docx
					type !vm_name!_ceph_extd_drive.tmp >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
					echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
					)
						) else ( 
								more +1 !vm_name!_ceph_extd_drive.tmp > !vm_name!_ceph_attached_drive.tmp
								set /p root_drive=<!vm_name!_ceph_extd_drive.tmp
								echo !root_drive! > !vm_name!_ceph_root_drive.tmp
								)
							)
						)
echo.

Rem Ceph pool consolidation 
for /F %%p in (ceph_pool_list.txt) do (
	for /F "tokens=5 delims= " %%r in (%%p_ceph_srvfnd.tmp) do (
		echo %%r >> !vm_name!_ceph_srvfnd.xlsx
		more +0 !vm_name!_ceph_srvfnd.xlsx > !vm_name!_ceph_srvfnd.tmp
		)
	)		
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p now=<snp_date.tmp

Rem code block for cinder backed bootable volume instances
findstr disk !vm_name!_ceph_srvfnd.tmp > !vm_name!_root_disk_chk.tmp
for %%i in (!vm_name!_root_disk_chk.tmp) do @set root_disk_chk=%%~zi
if !root_disk_chk! lss !ref_count! (
		echo Timestamp: !now!: The server !vm_name! is a cinder backed bootable volume instance..
		echo Timestamp: !now!: The server !vm_name! is a cinder backed bootable volume instance.. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
		echo.
		echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
		echo Timestamp: !now!: The root drive for the instance !vm_name! has the below id on ceph..
		echo Timestamp: !now!: The root drive for the instance !vm_name! has the below id on ceph.. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
		echo.
		echo. >> openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
		type !vm_name!_ceph_root_drive.tmp
		type !vm_name!_ceph_root_drive.tmp > !vm_name!_root_id.docx
		type !vm_name!_ceph_root_drive.tmp >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
		echo.
		echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
		for %%i in (!vm_name!_ceph_attached_drive.tmp) do @set extd_disk_chk=%%~zi
		if !extd_disk_chk! lss !ref_count! (
			!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
			set /p now=<snp_date.tmp
			echo Timestamp: !now!: The server !vm_name! has no additional disks attached to it..
			echo Timestamp: !now!: The server !vm_name! has no additional disks attached to it.. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
			echo.
			echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
			type !vm_name!_root_id.docx > !vm_name!_all_drives.docx
			goto vm_state_check
			) else (
		echo Timestamp: !now!: The extended drive for the instance !vm_name! has the below id on ceph..
		echo Timestamp: !now!: The extended drive for the instance !vm_name! has the below id on ceph.. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
		echo.
		echo. >> openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
		type !vm_name!_ceph_attached_drive.tmp
		type !vm_name!_ceph_attached_drive.tmp > !vm_name!_extd_id.docx
		type !vm_name!_ceph_attached_drive.tmp >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
		echo.
		echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
		)
	)
goto disk_consolidation

Rem Block for instances which has root disk alone..
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p now=<snp_date.tmp
:root_disk_routine
for /F %%k in (opsk_srvid.tmp) do ( 
	for /F %%p in (ceph_pool_list.txt) do ( 
		!agent_type! -!connc_type! -t ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "echo !OPSK_PWD! | sudo -S sudo rbd ls %%p | grep %%k" > %%p_ceph_srvfnd.tmp
		for %%i in (%%p_ceph_srvfnd.tmp) do @set srv_count=%%~zi
			if !srv_count! geq !ref_count! (
				for /F "tokens=5 delims= " %%r in (%%p_ceph_srvfnd.tmp) do ( 
					!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
					set /p now=<snp_date.tmp
					echo %%r > !vm_name!_ceph_root_drive.xlsx
					more +0 !vm_name!_ceph_root_drive.xlsx > !vm_name!_ceph_root_drive.tmp
					echo Timestamp: !now!: The root drive for the instance !vm_name! has the below id on ceph..
					echo Timestamp: !now!: The root drive for the instance !vm_name! has the below id on ceph.. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
					echo.
					echo. >> openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
					type !vm_name!_ceph_root_drive.tmp
					type !vm_name!_ceph_root_drive.tmp > !vm_name!_root_id.docx
					type !vm_name!_ceph_root_drive.tmp >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
					echo.
					echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
					echo Timestamp: !now!: The server The !vm_name! has no additional disks attached to it..
					echo.
					echo Timestamp: !now!: The server The !vm_name! has no additional disks attached to it.. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
					echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
					type !vm_name!_root_id.docx > !vm_name!_all_drives.docx
					goto vm_state_check
					)
				)
			)
		)
:disk_consolidation
type !vm_name!_root_id.docx > !vm_name!_all_drives.docx
type !vm_name!_extd_id.docx >> !vm_name!_all_drives.docx

Rem Checking the state of the instance
:vm_state_check
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p now=<snp_date.tmp
echo Timestamp: !now!: Verifying the state of the instance !vm_name! on openstack..
echo Timestamp: !now!: Verifying the state of the instance !vm_name! on openstack.. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
set /p proj_src=<Project_code.tmp
!agent_type! -!connc_type! openstack_client_node_ip -l root -pw !OPSK_PWD! "source /root/!proj_src!; openstack server show !vm_name! -f value -c status" > opsk_srv_state.tmp
set /p z=<opsk_srv_state.tmp
set vm_state=SHUTOFF
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p now=<snp_date.tmp
echo.
echo Timestamp: !now!: The state of the instance !vm_name! is !z!
echo Timestamp: !now!: The state of the instance !vm_name! is !z! >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
if /i "!z!"=="!vm_state!" goto drive_id_ask
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log

Rem code block to confirm shutoff an instance from an user
:shut_entry
echo Timestamp: !now!: Do you want to proceed to shutdown the instance !vm_name! (y/n)? >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo.
set /p shut_ask=Timestamp: !now!: Do you want to proceed to shutdown the instance !vm_name! (y/n)? 
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p now=<snp_date.tmp
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo Timestamp: !now!: Received !shut_ask! as an input for shutdown prompt >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
if /I "!shut_ask!"=="y" goto shut_instance
if /I "!shut_ask!"=="n" goto power_state_code_leave
echo.
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p now=<snp_date.tmp
echo Timestamp: !now!: You have entered an invalid input. Enter either y/n
goto shut_entry

Rem code block to shutdown the server
:shut_instance
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p now=<snp_date.tmp
echo.
echo Timestamp: !now!: Initiating shutdown for the instance !vm_name!
echo Timestamp: !now!: Initiating shutdown for the instance !vm_name! >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
!agent_type! -!connc_type! openstack_client_node_ip -l root -pw !OPSK_PWD! "source /root/!proj_src!; openstack server stop !vm_name!"

Rem Prompting user for a drive id to restore
:drive_id_ask
echo.
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p now=<snp_date.tmp
set /P drive_ask=Timestamp: !now!: Enter either root or extended drive id to perform a restore: 
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo Timestamp: !now!: Enter either root or extended drive id to perform a restore: >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo.
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
findstr !drive_ask! !vm_name!_all_drives.docx > !vm_name!_checked_drive.csv
echo Timestamp: !now!: Received !drive_ask! as an input for drive id prompt >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo Timestamp: !now!: Verifying if the id !drive_ask! is present for the instance !vm_name!
echo Timestamp: !now!: Verifying if the id !drive_ask! is present for the instance !vm_name! >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo.
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log

Rem Verifying if the drive id is present for the server or not
for /F "tokens=1 delims= " %%r in (!vm_name!_checked_drive.csv) do ( 
	if "!drive_ask!"=="%%r" goto ceph_snap_get
	)
echo Timestamp: !now!: The drive id !drive_ask! is not valid for the instance !vm_name!. Please input a valid id..
echo Timestamp: !now!: The drive id !drive_ask! is not valid for the instance !vm_name!. Please input a valid id.. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
goto :drive_id_ask

Rem code block for verifying and getting the ids on ceph
:ceph_snap_get
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p now=<snp_date.tmp
echo Timestamp: !now!: Verified that the id !drive_ask! is present for the instance !vm_name!
echo Timestamp: !now!: Verified that the id !drive_ask! is present for the instance !vm_name! >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo.
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p now=<snp_date.tmp
echo Timestamp: !now!: Checking for a list of available snapshots for the ceph rbd object !drive_ask! in ceph.. 
echo Timestamp: !now!: Checking for a list of available snapshots for the ceph rbd object !drive_ask! in ceph.. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo.
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log

Rem Collecting list and count of snaps for the drive id on ceph
for /F %%p in (ceph_pool_list.txt) do (
	!agent_type! -!connc_type! -t ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "echo !OPSK_PWD! | sudo -S sudo rbd ls %%p | grep !drive_ask!" > !drive_ask!_img_fnd.tmp
	for %%i in (!drive_ask!_img_fnd.tmp) do @set img_count=%%~zi
		if !img_count! geq !ref_count! (
		for /F "tokens=5 delims= " %%r in (!drive_ask!_img_fnd.tmp) do (
			!agent_type! -!connc_type! -t ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "echo !OPSK_PWD! | sudo -S sudo rbd snap ls %%p/%%r | awk '{print $2}' | tail -n +2" > !drive_ask!_snp_lst.tmp
			!agent_type! -!connc_type! -t ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "echo !OPSK_PWD! | sudo -S sudo rbd snap ls %%p/%%r | awk '{print $2}' | tail -n +2 | wc -l" > !drive_ask!_snp_cnt.tmp
			)
		)
	)
for /F "tokens=5 delims= " %%r in (!drive_ask!_snp_cnt.tmp) do (
	echo %%r > !drive_ask!_snp_cnt.xlsx
	)
set /p img_snp_cnt=<!drive_ask!_snp_cnt.xlsx

Rem code block for checking snapshots on ceph
if /i "!img_snp_cnt!" gtr "!snp_cnt!" (
	for /F "tokens=5 delims= " %%r in (!drive_ask!_snp_lst.tmp) do (
		echo %%r > !drive_ask!_snp_lst.csv
		)
	more +1 !drive_ask!_snp_lst.tmp >> !drive_ask!_snp_lst.csv
	!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
	set /p now=<snp_date.tmp
	echo Timestamp: !now!: The drive rbd object !drive_ask! for the server !vm_name! is having the below shapshots in ceph..
	echo Timestamp: !now!: The drive rbd object !drive_ask! for the server !vm_name! is having the below shapshots in ceph.. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
	echo.
	echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
	type !drive_ask!_snp_lst.csv
	type !drive_ask!_snp_lst.csv >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
	echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
	) else (
	echo Timestamp: !now!: The volume rbd object !drive_ask! owned by the server !vm_name! doesn't have any snapshot on ceph.. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
	echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
	call :colorEcho E4 "The volume rbd object !drive_ask! owned by the server !vm_name! doesn't have any snapshot on ceph.."
	echo.
	goto exit
)

Rem Prompting user for a snapshot name to restore
:snp_req
echo.
set /P snp_name=Timestamp: !now!: Enter which snap for !drive_ask! you need to perform a restore: 
echo Timestamp: !now!: Enter which snap for !drive_ask! you need to perform a restore: >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p now=<snp_date.tmp
echo.
echo Timestamp: !now!: Received !snp_name! as an input for snap name to restore for !drive_ask!.. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo Timestamp: !now!: Querying ceph if the snap !snp_name! is valid for !drive_ask!
echo Timestamp: !now!: Querying ceph if the snap !snp_name! is valid for !drive_ask! >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
for /F %%r in (!drive_ask!_snp_lst.csv) do (
	if /i "!snp_name!"=="%%r" goto snp_present
)
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p now=<snp_date.tmp
echo.
echo Timestamp: !now!: The snap name !snp_name! you have entered doesn't exist for this !drive_ask! in the instance !vm_name!. Enter a valid snap name to restore..
echo Timestamp: !now!: The snap name !snp_name! you have entered doesn't exist for this !drive_ask! in the instance !vm_name!. Enter a valid snap name to restore.. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
goto snp_req

Rem code block for verifying the snapshot on ceph
:snp_present
echo.
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "date" > snp_date.tmp
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p now=<snp_date.tmp
echo Timestamp: !now!: Verified that the snap !snp_name! is valid for !vm_name!..
echo Timestamp: !now!: Verified that the snap !snp_name! is valid for !vm_name!.. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p now=<snp_date.tmp
echo.
echo Timestamp: !now!: Verifying the state of the instance !vm_name! on openstack once again before snap trigger..
echo Timestamp: !now!: Verifying the state of the instance !vm_name! on openstack once again before snap trigger.. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
!agent_type! -!connc_type! openstack_client_node_ip -l root -pw !OPSK_PWD! "source /root/!proj_src!; openstack server show !vm_name! -f value -c status" > opsk_srv_state.tmp
set /p z=<opsk_srv_state.tmp
set vm_state=SHUTOFF
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p now=<snp_date.tmp
echo.
echo Timestamp: !now!: The state of the instance !vm_name! is !z!
echo Timestamp: !now!: The state of the instance !vm_name! is !z! >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
if /i "!z!"=="!vm_state!" goto snp_add_ask
if /i "!z!" neq "!vm_state!" goto power_state_code_leave

Rem code block to prompt user to add a snap before a restore trigger
:snp_add_ask
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p now=<snp_date.tmp
echo.
set /p snp_add_ask=Timestamp: !now!: Do you want to take a snap of !drive_ask! before a restore (y/n)? 
echo Timestamp: !now!: Do you want to take a snap of !drive_ask! before a restore (y/n)? >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo Timestamp: !now!: Received !snp_add_ask! as an input for snap add prompt >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo.
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
if /i "!snp_add_ask!"=="y" goto snp_add
if /i "!snp_add_ask!"=="n" goto restore_block
echo Timestamp: !now!: You have entered an invalid input. Enter either y/n
goto snp_add_ask

Rem code block to snapshot the instance drive before a restore trigger.
:snp_add
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p now=<snp_date.tmp
echo Timestamp: !now!: Saving the current state as a snap for !drive_ask! prior a restore trigger..
echo Timestamp: !now!: Saving the current state as a snap for !drive_ask! prior a restore trigger.. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
for /F %%p in (ceph_pool_list.txt) do (
	!agent_type! -!connc_type! -t ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "echo !OPSK_PWD! | sudo -S sudo rbd ls %%p | grep !drive_ask!" > !drive_ask!_img_fnd.tmp
	for %%i in (!drive_ask!_img_fnd.tmp) do @set img_count=%%~zi
		if !img_count! geq !ref_count! (
		for /F "tokens=5 delims= " %%r in (!drive_ask!_img_fnd.tmp) do (
			!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
			set /p now=<snp_date.tmp
			!agent_type! -!connc_type! -t ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "echo !OPSK_PWD! | sudo -S sudo rbd snap add %%p/%%r@prior_!snp_name!_restore_!now!" > snap_pri_res.tmp
			set /p z=<snap_pri_res.tmp
			set snp_chk=[sudo] password for vmadmin: rbd:
			if /i "!z:~0,33!"=="!snp_chk!" (
				echo.
				echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
				call :colorEcho E4 "There is an error while creating the volume rbd object !vol_name! snapshot on the instance !vm_name!. Check the logs to see more details.."
				echo Timestamp: !now!: There is an error while creating the volume rbd object !vol_name! snapshot on the instance !vm_name!: !z:~29,300! >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
				goto power_on_entry
				)
			)
		)
	)
echo.
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p now=<snp_date.tmp
if /i "!z:~0,33!" neq "!snp_chk!" echo Timestamp: !now!: The volume instane rbd object !drive_ask! for !vm_name! is snapshotted at !now! 
if /i "!z:~0,33!" neq "!snp_chk!" echo Timestamp: !now!: The volume instane rbd object !drive_ask! for !vm_name! is snapshotted at !now! >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo.

Rem code block for restoring a drive id on ceph
:restore_block
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p now=<snp_date.tmp
echo Timestamp: !now!: Triggering a point in time restore for the instance !vm_name! back to its snap !snp_name! on ceph..
echo Timestamp: !now!: Triggering a point in time restore for the instance !vm_name! back to its snap !snp_name! on ceph.. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo.
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
for /F %%p in (ceph_pool_list.txt) do (
	!agent_type! -!connc_type! -t ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "echo !OPSK_PWD! | sudo -S sudo rbd ls %%p | grep !drive_ask!" > !drive_ask!_img_fnd.tmp
	for %%i in (!drive_ask!_img_fnd.tmp) do @set img_count=%%~zi
		if !img_count! geq !ref_count! (
		for /F "tokens=5 delims= " %%r in (!drive_ask!_img_fnd.tmp) do (
			!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
			set /p now=<snp_date.tmp
			!agent_type! -!connc_type! -t ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "echo !OPSK_PWD! | sudo -S sudo rbd snap revert %%p/%%r@!snp_name!" >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
			for /F "UseBackQ Delims=" %%A In ("Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log") Do Set "lastline=%%A"
			echo !lastline!
			)
		)
	)
	
Rem code block for prompting instance powering on
:power_on_entry
echo.
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo Timestamp: !now!: Do you want to power on the instance !vm_name! (y/n)? >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
set /P power_on_ask=Timestamp: !now!: Do you want to power on the instance !vm_name! (y/n)? 
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p now=<snp_date.tmp
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo Timestamp: !now!: Received !power_on_ask! as an input for power on prompt >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
if /I "!power_on_ask!"=="y" goto power_on
if /I "!power_on_ask!"=="n" goto exit
echo.
echo Timestamp: !now!: You have entered an invalid input. Enter either y/n
goto power_on_entry

Rem code block for powering on an instance
:power_on
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p now=<snp_date.tmp
echo.
echo Timestamp: !now!: Powering on the instance !vm_name!
echo Timestamp: !now!: Powering on the instance !vm_name! >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
!agent_type! -!connc_type! openstack_client_node_ip -l root -pw !OPSK_PWD! "source /root/!proj_src!; openstack server start !vm_name!"
goto exit

Rem code block for stopping the code if the server state is not SHUTOFF
:power_state_code_leave
echo.
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
if /i "!z!" neq "!vm_state!" call :colorEcho E4 "The state of the server should be SHUTOFF to restore. Please shutdown and try again.."
if /i "!z!" neq "!vm_state!" call :colorEcho E4 "The state of the server should be SHUTOFF to restore. Please shutdown and try again.." >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo.
if /i "!z!" neq "!vm_state!" ( goto exit
)

Rem code exit block
:exit 
echo.
echo Timestamp: !now!: Restore task logs for the instance !vm_name! can be found at the below path for future reference..
echo.
!agent_type! -!connc_type! ceph_controller_node_ip -l vmadmin -pw !OPSK_PWD! "dt=`date`; day=`echo $dt | awk '{ print $1 }'`; mon=`echo $dt | awk '{ print $2 }'`; date=`echo $dt | awk '{ print $3 }'`; time=`echo $dt | awk '{ print $4 }' | sed 's/:/_/g'`; year=`echo $dt | awk '{ print $6 }'`; echo $day-$year-$mon-$date-$time" > snp_date.tmp
set /p now=<snp_date.tmp
echo. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo Timestamp: !now!: Restore log ends for !vm_name!. Session disconnected from Openstack and Ceph.. >> Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo D:\Ceph_snap_jobs\Ceph_opsk_snap_restore_logs\Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log
echo.
xcopy *.log "D:\Ceph_snap_jobs\Ceph_opsk_snap_restore_logs" > dump.tmp
!agent_type! -!connc_type! openstack_client_node_ip -l root -pw !OPSK_PWD! "echo !vm_name! > /root/ceph-openstack-restore/restore-logs/restore_vm.txt"
pscp -pw !OPSK_PWD! "Openstack_VM_Restore_!vm_name!_!res_srt_stamp!.log" root@"openstack_client_node_ip:/root/ceph-openstack-restore/restore-logs" > copy_log.tmp

Rem code to trigger a jenkins mail notification
!agent_type! -!connc_type! openstack_client_node_ip -l root -pw !OPSK_PWD! "curl -IX POST http://job-adm:jenkins_crumb_token@jenkins_machine_ip:8080/job/openstack_restore_dump/build -H "Jenkins-Crumb:jenkins_crumb_token" &> jen.tmp" 
del *.tmp, *.xlsx, *.docx, *.csv ,*.doc, *.txt, *.lst, *.log
set /p exit=Press enter to quit the prompt..
exit
:colorEcho
echo off
<nul set /p ".=%DEL%" > "%~2"
findstr /v /a:%1 /R "^$" "%~2" nul
del "%~2" > nul 2>&1i
