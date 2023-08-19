onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib tdp_ram_ip_opt

do {wave.do}

view wave
view structure
view signals

do {tdp_ram_ip.udo}

run -all

quit -force
