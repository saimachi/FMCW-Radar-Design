# This script uses an ST-Link v2 debugger to extract the sampled ADC values from the STM32F3 chip

# Start GDB Server
$pluginsPath = "C:/ST/STM32CubeIDE_1.16.1/STM32CubeIDE/plugins"
cd "C:/Projects/Personal/FMCW-Radar-Design/FMCW-Radar-v1/Firmware"
& "${pluginsPath}/com.st.stm32cube.ide.mcu.externaltools.openocd.win32_2.3.200.202404091248/tools/bin/openocd.exe" `
    "-f" "`"FMCW_Radar Debug.cfg`"" `
    "-s" "C:/Projects/Personal/FMCW-Radar-Design/FMCW-Radar-v1/Firmware" `
    "-s" "$pluginsPath/com.st.stm32cube.ide.mcu.debug.openocd_2.2.100.202406131243/resources/openocd/st_scripts" `
    "-s" "$pluginsPath/com.st.stm32cube.ide.mpu.debug.openocd_2.1.200.202405171325/resources/openocd/st_scripts" `
    "-c" "gdb_report_data_abort enable" `
    "-c" "gdb_port 3333" "-c" "tcl_port 6666" "-c" "telnet_port 4444"

# Connect to GDB
cd "C:/Projects/Personal/FMCW-Radar-Design/Scripts"
$pluginsPath = "C:/ST/STM32CubeIDE_1.16.1/STM32CubeIDE/plugins"
& "$pluginsPath/com.st.stm32cube.ide.mcu.externaltools.gnu-tools-for-stm32.12.3.rel1.win32_1.0.200.202406191623/tools/bin/arm-none-eabi-gdb.exe" -x gdb-commands.txt
# & "$pluginsPath/com.st.stm32cube.ide.mcu.externaltools.gnu-tools-for-stm32.12.3.rel1.win32_1.0.200.202406191623/tools/bin/arm-none-eabi-gdb.exe"