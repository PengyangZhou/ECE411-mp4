## Generated SDC file "mp4.out.sdc"

## Copyright (C) 2018  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 18.1.0 Build 625 09/12/2018 SJ Standard Edition"

## DATE    "Wed Nov 10 22:11:06 2021"

##
## DEVICE  "EP2AGX45DF25I3"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {clk} -period 10.000 -waveform { 0.000 5.000 } [get_ports {clk}]


#**************************************************************
# Create Generated Clock
#**************************************************************



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {clk}] -rise_to [get_clocks {clk}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clk}] -fall_to [get_clocks {clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clk}] -rise_to [get_clocks {clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clk}] -fall_to [get_clocks {clk}]  0.020  


#**************************************************************
# Set Input Delay
#**************************************************************

set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {clk}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[0]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[1]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[2]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[3]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[4]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[5]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[6]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[7]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[8]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[9]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[10]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[11]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[12]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[13]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[14]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[15]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[16]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[17]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[18]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[19]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[20]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[21]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[22]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[23]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[24]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[25]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[26]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[27]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[28]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[29]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[30]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_d[31]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[0]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[1]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[2]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[3]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[4]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[5]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[6]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[7]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[8]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[9]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[10]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[11]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[12]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[13]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[14]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[15]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[16]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[17]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[18]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[19]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[20]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[21]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[22]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[23]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[24]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[25]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[26]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[27]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[28]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[29]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[30]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_rdata_i[31]}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_resp_d}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_resp_i}]
set_input_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {rst}]


#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[0]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[1]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[2]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[3]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[4]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[5]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[6]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[7]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[8]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[9]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[10]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[11]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[12]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[13]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[14]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[15]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[16]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[17]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[18]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[19]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[20]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[21]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[22]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[23]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[24]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[25]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[26]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[27]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[28]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[29]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[30]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_d[31]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[0]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[1]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[2]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[3]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[4]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[5]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[6]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[7]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[8]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[9]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[10]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[11]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[12]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[13]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[14]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[15]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[16]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[17]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[18]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[19]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[20]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[21]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[22]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[23]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[24]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[25]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[26]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[27]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[28]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[29]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[30]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_address_i[31]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_byte_enable_d[0]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_byte_enable_d[1]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_byte_enable_d[2]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_byte_enable_d[3]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_read_d}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_read_i}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[0]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[1]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[2]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[3]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[4]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[5]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[6]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[7]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[8]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[9]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[10]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[11]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[12]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[13]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[14]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[15]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[16]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[17]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[18]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[19]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[20]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[21]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[22]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[23]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[24]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[25]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[26]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[27]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[28]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[29]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[30]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_wdata_d[31]}]
set_output_delay -add_delay  -clock [get_clocks {clk}]  0.000 [get_ports {mem_write_d}]


#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

