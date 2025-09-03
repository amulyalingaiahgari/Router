# MAKEfile for SystemVeilog tb 
RTL= .. / .. /rtl/router.v
SVTB= ./router_test_top.sv ./router_io.sv ./test.sv ./DriverBase.sv ./Driver.sv ./Generator.sv ./ReceiverBase.sv ./Receiver.sv ./Packet.sv ./Scoreboard.sv ./router_test_pkg.
sv ./Environment.sv
SEED =1

default: test

test: compile run debug

run:

./simv -1 simv.log +ntb_random_seed=$(SEED)

Compile:
vcs -sverilog -full64 +vcs+fsdbon -debug_all $(SVTB) $(RTL)

debug:
verdi -sv $(RTL) $(SVTB) -ssf simv.fsdb &

clean:
rm -rf simv* csrc* *. tmp *. vpd *. key *. log

help:
