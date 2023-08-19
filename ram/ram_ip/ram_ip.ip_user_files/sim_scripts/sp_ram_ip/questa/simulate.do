onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib sp_ram_ip_opt

do {wave.do}

view wave
view structure
view signals

do {sp_ram_ip.udo}

run -all

quit -force
