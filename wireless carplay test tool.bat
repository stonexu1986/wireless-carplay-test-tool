@echo off
setlocal enabledelayedexpansion

mode con cols=150 lines=40
title "Wireless CarPlay Test Tool"

echo +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ++++++++++++++++++++++++++++++++++++++++ Wireless CarPlay Test Tool V1.1 ++++++++++++++++++++++++++++++++++++++++
echo ++++++++++++++++++++++++++++++++++++++++ Copyright (c) 2020-2020 APTIV   ++++++++++++++++++++++++++++++++++++++++
echo ++++++++++++++++++++++++++++++++++++++++ Author: Xu,Baoling              ++++++++++++++++++++++++++++++++++++++++
echo ++++++++++++++++++++++++++++++++++++++++ Date: 2020-12-01                ++++++++++++++++++++++++++++++++++++++++
echo +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo.

echo * Please switch the HUT to ADB mode first
echo.

adb wait-for-device
adb root
echo =^> adb root succeeded

adb wait-for-device
adb remount
echo =^> adb remount succeeded

echo.
echo ============================================== Turn Off Firewall ================================================
echo.
::check the icmp type line number
echo ------------------------------------------------ iptables origin ------------------------------------------------
adb shell iptables --line -nvL INPUT 
echo -----------------------------------------------------------------------------------------------------------------

for /f "tokens=1" %%i in ('adb shell iptables --line -nvL INPUT ^| find /i "icmptype"') do ( 
set icmp_line_number=%%i
echo.
echo =^> icmp line number is: !icmp_line_number!
)

if "!icmp_line_number!" gtr "0" (
echo =^> disable the icmp type firewall
adb shell iptables -D INPUT !icmp_line_number!

::double check the icmp type line number
echo -------------------------------------------------- iptables new -------------------------------------------------
adb shell iptables --line -nvL INPUT 
echo -----------------------------------------------------------------------------------------------------------------
) else (
echo.
echo =^> no icmp type line number found!
)

for /f "tokens=1" %%i in ('adb shell iptables --line -nvL INPUT ^| find /i "icmptype"') do (
set check_icmp_line_number=%%i
)

if "!check_icmp_line_number!" gtr "0" (
echo.
echo =^> turn off the icmp firewall failed
) else (
echo.
echo =^> turn off the icmp firewall succeeded
)

echo.
echo ========================================= Prepare Wireless CarPlay Test =========================================

::set accessory_ipv4_addr=192.168.40.71
set apple_device_ipv4_addr=192.168.40.181

:input_accessory_ip_address
set /p accessory_ipv4_addr="* Please input accessory ipv4 address[like 192.168.x.x)]:"
if not defined accessory_ipv4_addr (
echo =^> the accessory ipv4 address is required
echo.
goto input_accessory_ip_address
) else (
echo =^> the accessory ipv4 address is %accessory_ipv4_addr%
echo.
)

:input_apple_device_ip_address
set /p apple_device_ipv4_addr="* Please input Apple device ipv4 address[like 192.168.x.x]:"
if not defined apple_device_ipv4_addr (
echo =^> the Apple device ipv4 address is required
echo.
goto input_apple_device_ip_address
) else (
echo =^> the Apple device ipv4 address is %apple_device_ipv4_addr%
)

:carplay_tests_option
echo.
echo ========================================== Start Wireless CarPlay Test ==========================================
echo  Option
echo  0  -  Verify Connectivity [15 sec]
echo  1  -  Performance uplink test {2 min]
echo  2  -  Performance downlink test [2 min]
echo  3  -  Performance uplink test [60 min]
echo  4  -  Performance downlink test [60 min]
echo  5  -  Co-existence test [2 min]
echo  q  -  Quit the test
echo =================================================================================================================

echo.
set /p carplay_tests_option="* Please select your option for wireless CarPlay test: "
if not defined carplay_tests_option (
echo =^> this option is required
goto carplay_tests_option
) else (
if "%carplay_tests_option%"=="" ( goto carplay_tests_option ) ^
else if "%carplay_tests_option%"=="0" ( goto run_verify_connectivity_test ) ^
else if "%carplay_tests_option%"=="1" ( goto run_performance_uplink_test_2_min ) ^
else if "%carplay_tests_option%"=="2" ( goto run_performance_downlink_test_2_min ) ^
else if "%carplay_tests_option%"=="3" ( goto run_performance_uplink_test_60_min ) ^
else if "%carplay_tests_option%"=="4" ( goto run_performance_downlink_test_60_min ) ^
else if "%carplay_tests_option%"=="5" ( goto run_co-existence_test ) ^
else if "%carplay_tests_option%"=="q" ( goto eof ) ^
else (
echo =^> invalid option, please select again 
goto carplay_tests_option )
)

::*********************************************** Verify Connectivity Start ***********************************************
:run_verify_connectivity_test
echo.
echo =^> start to verify connectivity test
echo.

set /p apple_device_run_test="* Please press 'Enter' after you pressed 'Run Test' button on Apple device: "

::PreCondition
set comments=Step 1: Connect the Apple device to the Wi-Fi Access Point
echo =^> %comments%

::TCP Server
set comments=Step 2: Start TCP Iperf server on the accessory by running:
set iperf_command=iperf -s -i 1 -w 176k -p 6001 -P 1
echo =^> %comments% %iperf_command%
start cmd /c "adb shell %iperf_command%

::UDP Server
set comments=Step 3: Start UDP Iperf server on the accessory by running:
set iperf_command=iperf -s -i 1 -w 512k -u -p 5001 -P 1
echo =^> %comments% %iperf_command%
start cmd /c "adb shell %iperf_command%

::TCP Client
set comments=Step 4: Start TCP Iperf client on the accessory by running:
set iperf_command=iperf -c %apple_device_ipv4_addr% -p 6001 -i 1 -w 176k -b 20M -t 15 -S 0xA0
echo =^> %comments% %iperf_command%
start cmd /c "adb shell %iperf_command%

::UDP Client
set comments=Step 5: Start UDP Iperf client on the accessory by running:
set iperf_command=iperf -c %apple_device_ipv4_addr% -p 5001 -i 1 -w 512k -t 15 -u -b 2M -S 0xE0
echo =^> %comments% %iperf_command%
start cmd /c "adb shell %iperf_command%

echo.
echo =^> it will take 15 sec to complete the test, please wait...

set test_time=15
for /l %%i in (%test_time%,-1,0) do (
echo =^> %%i seconds left...
ping -n 2 -w 500 127.1>nul
)

echo =^> run verify connectivity test complete
goto carplay_tests_option

::*********************************************** Verify Connectivity End ***********************************************


::***************************************** Performance Uplink Test 2 Min Start *****************************************
:run_performance_uplink_test_2_min
echo.
echo =^> start to run performance uplink test for 2 min
echo.

set /p apple_device_run_test="* Please press 'Enter' after you pressed 'Run Test' button on Apple device: "

::PreCondition
set comments=Step 1: Connect the Apple device to the Wi-Fi Access Point
echo =^> %comments%

::TCP Server
set comments=Step 2: Start TCP Iperf server on the accessory by running:
set iperf_command=iperf -s -i 1 -w 176k -p 6001 -P 1
echo =^> %comments% %iperf_command%
start cmd /c "adb shell %iperf_command%

::UDP Server
set comments=Step 3: Start UDP Iperf server on the accessory by running:
set iperf_command=iperf -s -i 1 -w 512k -u -p 5001 -P 1
echo =^> %comments% %iperf_command%
start cmd /c "adb shell %iperf_command%

::UDP Client
set comments=Step 4: Start UDP Iperf client on the accessory by running:
set iperf_command=iperf -c %apple_device_ipv4_addr% -p 5001 -i 1 -w 512k -t 120 -u -b 2M -S 0xE0
echo =^> %comments% %iperf_command%
start cmd /c "adb shell %iperf_command%

echo.
echo =^> it will take 2 min to complete the test, please wait...

set test_time=120
for /l %%i in (%test_time%,-1,0) do (
echo =^> %%i seconds left...
ping -n 2 -w 500 127.1>nul
)

echo =^> run performance uplink test for 2 min complete
goto carplay_tests_option
::******************************************* Performance Uplink Test 2 Min End *****************************************


::**************************************** Performance Downlink Test 2 Min Start ****************************************
:run_performance_downlink_test_2_min
echo.
echo =^> start to run performance downlink test for 2 min
echo.

set /p apple_device_run_test="* Please press 'Enter' after you pressed 'Run Test' button on Apple device: "

::PreCondition
set comments=Step 1: Connect the Apple device to the Wi-Fi Access Point
echo =^> %comments%

::UDP Server
set comments=Step 2: Start UDP Iperf server on the accessory by running:
set iperf_command=iperf -s -i 1 -w 512k -u -p 5001 -P 1
echo =^> %comments% %iperf_command%
start cmd /c "adb shell %iperf_command%

::TCP Client
set comments=Step 3: Start TCP Iperf client on the accessory by running:
set iperf_command=iperf -c %apple_device_ipv4_addr% -p 6001 -i 1 -w 176k -b 20M -t 120 -S 0xA0
echo =^> %comments% %iperf_command%
start cmd /c "adb shell %iperf_command%

set comments=Step 4: Start UDP Iperf client on the accessory by running:
set iperf_command=iperf -c %apple_device_ipv4_addr% -p 5001 -i 1 -w 512k -t 120 -u -b 2M -S 0xE0
echo =^> %comments% %iperf_command%
start cmd /c "adb shell %iperf_command%

echo.
echo =^> it will take 2 min to complete the test, please wait...

set test_time=120
for /l %%i in (%test_time%,-1,0) do (
echo =^> %%i seconds left...
ping -n 2 -w 500 127.1>nul
)

echo =^> run performance downlink test for 2 min complete
goto carplay_tests_option
::****************************************** Performance Downlink Test 2 Min End ****************************************


::***************************************** Performance Uplink Test 60 Min Start ****************************************
:run_performance_uplink_test_60_min
echo.
echo =^> start to run performance downlink test for 60 min
echo.

set /p apple_device_run_test="* Please press 'Enter' after you pressed 'Run Test' button on Apple device: "

::PreCondition
set comments=Step 1: Connect the Apple device to the Wi-Fi Access Point
echo =^> %comments%

::TCP Server
set comments=Step 2: Start TCP Iperf server on the accessory by running:
set iperf_command=iperf -s -i 1 -w 176k -p 6001 -P 1
echo =^> %comments% %iperf_command%
start cmd /c "adb shell %iperf_command%

::UDP Server
set comments=Step 3: Start UDP Iperf server on the accessory by running:
set iperf_command=iperf -s -i 1 -w 512k -u -p 5001 -P 1
echo =^> %comments% %iperf_command%
start cmd /c "adb shell %iperf_command%

::UDP Client
set comments=Step 4: Start UDP Iperf client on the accessory by running:
set iperf_command=iperf -c %apple_device_ipv4_addr% -p 5001 -i 1 -w 512k -t 3600 -u -b 2M -S 0xE0
echo =^> %comments% %iperf_command%
start cmd /c "adb shell %iperf_command%

echo.
echo =^> it will take 60 min to complete the test, please wait...

set test_time=3600
for /l %%i in (%test_time%,-1,0) do (
echo =^> %%i seconds left...
ping -n 2 -w 500 127.1>nul
)

echo =^> run performance downlink test for 60 min complete
goto carplay_tests_option
::******************************************* Performance Uplink Test 60 Min End ****************************************


::**************************************** Performance Downlink Test 60 Min Start ***************************************
:run_performance_downlink_test_60_min
echo.
echo =^> start to run performance downlink test for 60 min
echo.

set /p apple_device_run_test="* Please press 'Enter' after you pressed 'Run Test' button on Apple device: "

::PreCondition
set comments=Step 1: Connect the Apple device to the Wi-Fi Access Point
echo =^> %comments%

::UDP Server
set comments=Step 2: Start UDP Iperf server on the accessory by running:
set iperf_command=iperf -s -i 1 -w 512k -u -p 5001 -P 1
echo =^> %comments% %iperf_command%
start cmd /c "adb shell %iperf_command%

::TCP Client
set comments=Step 3: Start TCP Iperf client on the accessory by running:
set iperf_command=iperf -c %apple_device_ipv4_addr% -p 6001 -i 1 -w 176k -b 20M -t 3600 -S 0xA0
echo =^> %comments% %iperf_command%
start cmd /c "adb shell %iperf_command%

set comments=Step 4: Start UDP Iperf client on the accessory by running:
set iperf_command=iperf -c %apple_device_ipv4_addr% -p 5001 -i 1 -w 512k -t 3600 -u -b 2M -S 0xE0
echo =^> %comments% %iperf_command%
start cmd /c "adb shell %iperf_command%

echo.
echo =^> it will take 60 min to complete the test, please wait...

set test_time=3600
for /l %%i in (%test_time%,-1,0) do (
echo =^> %%i seconds left...
ping -n 2 -w 500 127.1>nul
)

echo =^> run performance downlink test for 60 min complete
goto carplay_tests_option
::****************************************** Performance Downlink Test 60 Min End ***************************************


::************************************************ Co-existence Test Start **********************************************
:run_co-existence_test
echo.
echo =^> start to run co-existence test
echo.

set /p apple_device_run_test="* Please press 'Enter' after you pressed 'Run Test' button on Apple device: "

::PreCondition
set comments=Step 1: Connect the Apple device to the Wi-Fi Access Point
echo =^> %comments%

::TCP Server
set comments=Step 2: Start TCP Iperf server on the accessory by running:
set iperf_command=iperf -s -i 1 -w 176k -p 6001 -P 1
echo =^> %comments% %iperf_command%
start cmd /c "adb shell %iperf_command%

::UDP Server
set comments=Step 3: Start UDP Iperf server on the accessory by running:
set iperf_command=iperf -s -i 1 -w 512k -u -p 5001 -P 1
echo =^> %comments% %iperf_command%
start cmd /c "adb shell %iperf_command%

::UDP Client
set comments=Step 4: Start UDP Iperf client on the accessory by running:
set iperf_command=iperf -c %apple_device_ipv4_addr% -p 5001 -i 1 -w 512k -t 120 -u -b 2M -S 0xE0
echo =^> %comments% %iperf_command%
start cmd /c "adb shell %iperf_command%

echo.
echo =^> it will take 120 sec to complete the test, please wait...

set test_time=120
for /l %%i in (%test_time%,-1,0) do (
echo =^> %%i seconds left...
ping -n 2 -w 500 127.1>nul
)

echo =^> run co-existence test complete
goto carplay_tests_option
::************************************************* Co-existence Test End ***********************************************


:eof
echo.
echo +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ++++++++++++++++++++++++++++++++++++++++++++++++++++ Bye Bye ++++++++++++++++++++++++++++++++++++++++++++++++++++
echo +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

pause
