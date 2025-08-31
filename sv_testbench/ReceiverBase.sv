`timescale 1ns/100ps
`ifndef INC_RECEIVERBASE_SV
`define INC_RECEIVERBASE_SV

class ReceiverBase;
  virtual router_io.TB rtr_io;	// interface signals
  string   name;		// unique identifier
  bit [3:0] da;			// output port to monitor
  logic [7:0] pkt2cmp_payload [$];	// actual payload array
  Packet   pkt2cmp;		// actual Packet object

  extern function new(string name = "ReceiverBase", virtual router_io.TB rtr_io);
  extern virtual task recv();
  extern virtual task get_payload();
endclass:ReceiverBase

function ReceiverBase::new(string name, virtual router_io.TB rtr_io);
  if (TRACE_ON) $display("[TRACE]%t %s:%m", $realtime, name);
  this.name = name;
  this.rtr_io = rtr_io;
  this.pkt2cmp = new();
endfunction:new

task ReceiverBase::recv();
  static int pkt_cnt = 0;
  if (TRACE_ON) $display("[TRACE]%t %s:%m", $realtime, this.name);
  this.get_payload(); //monitor
  this.pkt2cmp.da = da;
  this.pkt2cmp.payload = this.pkt2cmp_payload;
  this.pkt2cmp.name = $psprintf("rcvdPkt[%0d]", pkt_cnt++);
endtask:recv

task ReceiverBase::get_payload();
  if (TRACE_ON) $display("[TRACE]%t %s:%m", $realtime, this.name);
  this.pkt2cmp_payload.delete(); //deleting the content of stored packets //potential residues
  fork
    begin: wd_timer_fork //waiting for a falling edge of the o/p frame signal //watch_dog timer
    fork: frameo_wd_timer
      @(negedge this.rtr_io.cb.frameo_n[da]); //triggers at negedge of frame low
      begin
        repeat(1000) @(rtr_io.cb);
        $display("\n%m\n[ERROR]%t Frame[%0d] signal timed out!\n", $realtime,da);
        $finish;
      end
    join_any: frameo_wd_timer
    disable fork;
    end: wd_timer_fork
  join
  forever begin //sampling the o/p of rtr_io
    logic[7:0] datum; //each byte into the pkt queue
    for (int i=0; i<8; ) begin //loop until the end of frame is detected
      if (!this.rtr_io.cb.valido_n[da])
        datum[i++] = this.rtr_io.cb.dout[da];
      if (this.rtr_io.cb.frameo_n[da])
        if (i == 8) begin
          this.pkt2cmp_payload.push_back(datum); //alignning the data as a packet
          return;
        end
        else begin
          $display("\n%m\n[ERROR]%t Packet payload not byte aligned!\n", $realtime);
          $finish;
        end
      @(this.rtr_io.cb);
    end
    this.pkt2cmp_payload.push_back(datum);
  end
endtask:get_payload
`endif
