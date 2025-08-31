`timesacle 1ns/100ps
`ifndef INC_SCOREBOARD_SV
`define INC_SCOREBOARD_SV

class Scoreboard;
  string   name;		// unique identifier
  event    DONE;		// flag to indicate goal reached
  Packet   refPkt[$];		// reference Packet array
  Packet   pkt2send;		// Packet object from Drivers
  Packet   pkt2cmp;		// Packet object from Receivers
  pkt_mbox  driver_mbox;		// mailbox for Packet objects from Drivers
  pkt_mbox  receiver_mbox;	// mailbox for Packet objects from Receivers

	bit[3:0] sa, da; //functional coverage properties
  
  covergroup router_cov;
	  coverpoint sa{type_option.weight=0;}
	  coverpoint da{typr_option.weight=0;}
	cross sa, da;
  endgroup: router_cov


  extern function new(string name = "Scoreboard", pkt_mbox driver_mbox = null, receiver_mbox = null);
  extern virtual task start();
  extern virtual task check();
endclass: Scoreboard

function Scoreboard::new(string name, pkt_mbox driver_mbox, receiver_mbox);
	if (TRACE_ON) $display("[TRACE]%0t %s:%m", $realtime, name);
  this.name = name;
  if (driver_mbox == null) driver_mbox = new();
  this.driver_mbox = driver_mbox;
  if (receiver_mbox == null) receiver_mbox = new();
  this.receiver_mbox = receiver_mbox;
  router_cov = new();
endfunction: new

task Scoreboard::start();
	if (TRACE_ON) $display("[TRACE]%0t %s:%m", $realtime, this.name);
  fork
    while (1) begin
      this.receiver_mbox.get(this.pkt2cmp);
      while (this.driver_mbox.num()) begin
        Packet pkt;
        this.driver_mbox.get(pkt);
        this.refPkt.push_back(pkt);
      end
      this.check();
    end
  join_none
endtask: start

task Scoreboard::check();
  int    index[$];
  string message;
  static int  pkts_checked = 0;
  real coverage_result;

	if (TRACE_ON) $display("[TRACE]%0t %s:%m", $realtime, this.name);
	index = this.refPkt.find_first_index() with (item.da == this.pkt2cmp.da);
  if (index.size() <= 0) begin
	  $display("\n%m\n[ERROR]%0t %s not found in Reference Queue\n", $realtime, this.pkt2cmp.name);
    this.pkt2cmp.display("ERROR");
    $finish;
  end
  this.pkt2send = this.refPkt[index[0]];
  this.refPkt.delete(index[0]);
	if (!this.pkt2send.compare(this.pkt2cmp, message)) begin //task
    $display("\n%m\n[ERROR]%0t Packet #%0d %s\n", $time, pkts_checked, message);
    this.pkt2send.display("ERROR");
    this.pkt2cmp.display("ERROR");
    $finish;
  end
	
  this.sa = pkt2send.sa;
  this.da = pkt2send.da;
  this.router_cov.sample();

  coverage_result = $get_coverage();
	$display("[NOTE]%0t Packet #%0d %s - Coverage = %3.2f", $realtime, pkts_checked++, message, coverage_result);
	$display("packetschecked %d",pkts_checked);
	if ((pkts_checked >= run_for_n_packets) || (coverage_result == 100.00)) begin
		$dispaly("runforpackets %d packets checked %d", run_for_n_packets, pkts_checked);
    ->this.DONE;
	end
endtask: check
`endif
