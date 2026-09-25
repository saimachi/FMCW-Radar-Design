# This script uses an ST-Link v2 debugger to extract the sampled ADC values from the STM32F3 chip

# Start GDB Server
$pluginsPath = "C:/ST/STM32CubeIDE_1.19.0/STM32CubeIDE/plugins"
cd "C:/Personal/FMCW-Radar-Design/FMCW-Radar-v1/Firmware"
& "${pluginsPath}/com.st.stm32cube.ide.mcu.externaltools.openocd.win32_2.4.300.202509300731/tools/bin/openocd.exe" `
    "-f" "`"FMCW_Radar Debug.cfg`"" `
    "-s" "C:/Personal/FMCW-Radar-Design/FMCW-Radar-v1/Firmware" `
    "-s" "$pluginsPath/com.st.stm32cube.ide.mcu.debug.openocd_2.3.100.202501240831/resources/openocd/st_scripts" `
    "-s" "$pluginsPath/com.st.stm32cube.ide.mpu.debug.openocd_2.2.1.202505211639/resources/openocd/st_scripts" `
    "-c" "gdb_report_data_abort enable" `
    "-c" "gdb_port 3333" "-c" "tcl_port 6666" "-c" "telnet_port 4444"
