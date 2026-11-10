N ?= 4

sim:
	iverilog -g2012 -Ptb_systolic_array.N=$(N) -o sim.out src/pe.v src/systolic_array.v tb/tb_systolic_array.v
	vvp sim.out

wave:
	gtkwave tb.vcd

clean:
	rm -f sim.out tb.vcd
