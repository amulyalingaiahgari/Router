`timescale 1ns/100ps 
program automatic test(router_io.TB rtr_io);

import router_test_pkg::*;

  Environment env;

  initial begin
	env = new("env", rtr_io);
	env.configure();
	run_for_n_packets = env.run_for_n_packets;
	env.run();
  end

endprogram: test
