
else if(testname == "sample_smoke_test0")
begin


    TSK_SIMULATION_TIMEOUT(5050);

    //System Initialization
    TSK_SYSTEM_INITIALIZATION;




    
    $display("[%t] : Expected Device/Vendor ID = %x", $realtime, DEV_VEN_ID); 
    
    //--------------------------------------------------------------------------
    // Read core configuration space via PCIe fabric interface
    //--------------------------------------------------------------------------

    $display("[%t] : Reading from PCI/PCI-Express Configuration Register 0x00", $realtime);

    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h0, 4'hF);
    TSK_WAIT_FOR_READ_DATA;
    if  (P_READ_DATA != DEV_VEN_ID) begin
        $display("[%t] : TEST FAILED --- Data Error Mismatch, Write Data %x != Read Data %x", $realtime, 
                                    DEV_VEN_ID, P_READ_DATA);
    end
    else begin
        $display("[%t] : TEST PASSED --- Device/Vendor ID %x successfully received", $realtime, P_READ_DATA);
        $display("Test Completed Successfully");
    end

    //--------------------------------------------------------------------------
    // Direct Root Port to allow upstream traffic by enabling Mem, I/O and
    // BusMstr in the command register
    //--------------------------------------------------------------------------

    `ROOTPORT_TB.cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);
    `ROOTPORT_TB.cfg_usrapp.TSK_WRITE_CFG_DW(32'h00000001, 32'h00000007, 4'b1110);
    `ROOTPORT_TB.cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);

  $finish;
end


else if(testname == "sample_smoke_test1")
begin

    // This test use tlp expectation tasks.

    TSK_SIMULATION_TIMEOUT(5050);

    //System Initialization
    TSK_SYSTEM_INITIALIZATION;

fork
  begin
    //--------------------------------------------------------------------------
    // Read core configuration space via PCIe fabric interface
    //--------------------------------------------------------------------------

    $display("[%t] : Reading from PCI/PCI-Express Configuration Register 0x00", $realtime);

    TSK_TX_TYPE0_CONFIGURATION_READ(DEFAULT_TAG, 12'h0, 4'hF);
    DEFAULT_TAG = DEFAULT_TAG + 1;
    TSK_TX_CLK_EAT(100);
  end
    //---------------------------------------------------------------------------
    // List Rx TLP expections
    //---------------------------------------------------------------------------
  begin
    test_vars[0] = 0;                                                                                                                         
                                          
    $display("[%t] : Expected Device/Vendor ID = %x", $realtime, DEV_VEN_ID);                                              

    expect_cpld_payload[0] = DEV_VEN_ID[7:0]; 
    expect_cpld_payload[1] = DEV_VEN_ID[15:8]; 
    expect_cpld_payload[2] = DEV_VEN_ID[23:16]; 
    expect_cpld_payload[3] = DEV_VEN_ID[31:24]; 
    `ROOTPORT_TB.com_usrapp.TSK_EXPECT_CPLD(
      3'h0, //traffic_class;
      1'b0, //td;
      1'b0, //ep;
      2'h0, //attr;
      10'h1, //length;
      16'h0000, //completer_id;
      3'h0, //completion_status;
      1'b0, //bcm;
      12'h4, //byte_count;
      `ROOTPORT_TB.tx_usrapp.REQUESTER_ID, //16 bit requester_id;
      8'h0, //tag;
      7'b0, //address_low;
      expect_status //expect_status;
    );

    if (expect_status) 
      test_vars[0] = test_vars[0] + 1;      
  end
join
  
  expect_finish_check = 1;

  if (test_vars[0] == 1) begin
    $display("[%t] : TEST PASSED --- Finished transmission of PCI-Express TLPs", $realtime);
    $display ("Test Completed Successfully");
  end
  else begin
    $display("[%t] : TEST FAILED --- Haven't Received All Expected TLPs", $realtime);

    //--------------------------------------------------------------------------
    // Direct Root Port to allow upstream traffic by enabling Mem, I/O and
    // BusMstr in the command register
    //--------------------------------------------------------------------------

    `ROOTPORT_TB.cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);
    `ROOTPORT_TB.cfg_usrapp.TSK_WRITE_CFG_DW(32'h00000001, 32'h00000007, 4'b1110);
    `ROOTPORT_TB.cfg_usrapp.TSK_READ_CFG_DW(32'h00000001);

  end

  $finish;
end

else if(testname == "pio_writeReadBack_test0")
begin

    // This test performs a 32 bit write to a 32 bit Memory space and performs a read back

    `ROOTPORT_TB.tx_usrapp.TSK_SIMULATION_TIMEOUT(10050);

    `ROOTPORT_TB.tx_usrapp.TSK_SYSTEM_INITIALIZATION;

    `ROOTPORT_TB.tx_usrapp.TSK_BAR_INIT;

//--------------------------------------------------------------------------
// Event : Testing BARs
//--------------------------------------------------------------------------

        for (`ROOTPORT_TB.tx_usrapp.ii = 0; `ROOTPORT_TB.tx_usrapp.ii <= 6; `ROOTPORT_TB.tx_usrapp.ii =
            `ROOTPORT_TB.tx_usrapp.ii + 1) begin
            if (`ROOTPORT_TB.tx_usrapp.BAR_INIT_P_BAR_ENABLED[`ROOTPORT_TB.tx_usrapp.ii] > 2'b00) // bar is enabled
               case(`ROOTPORT_TB.tx_usrapp.BAR_INIT_P_BAR_ENABLED[`ROOTPORT_TB.tx_usrapp.ii])
                   2'b01 : // IO SPACE
                        begin

                          $display("[%t] : Transmitting TLPs to IO Space BAR %x", $realtime, `ROOTPORT_TB.tx_usrapp.ii);

                          //--------------------------------------------------------------------------
                          // Event : IO Write bit TLP
                          //--------------------------------------------------------------------------



                          `ROOTPORT_TB.tx_usrapp.TSK_TX_IO_WRITE(`ROOTPORT_TB.tx_usrapp.DEFAULT_TAG,
                             `ROOTPORT_TB.tx_usrapp.BAR_INIT_P_BAR[`ROOTPORT_TB.tx_usrapp.ii][31:0], 4'hF, 32'hdead_beef);

                          `ROOTPORT_TB.com_usrapp.TSK_EXPECT_CPL(3'h0, 1'b0, 1'b0, 2'b0,
                             `ROOTPORT_TB.tx_usrapp.COMPLETER_ID_CFG, 3'h0, 1'b0, 12'h4,
                             `ROOTPORT_TB.tx_usrapp.COMPLETER_ID_CFG, `ROOTPORT_TB.tx_usrapp.DEFAULT_TAG,
                             `ROOTPORT_TB.tx_usrapp.BAR_INIT_P_BAR[`ROOTPORT_TB.tx_usrapp.ii][31:0], test_vars[0]);

                          `ROOTPORT_TB.tx_usrapp.TSK_TX_CLK_EAT(10);
                          `ROOTPORT_TB.tx_usrapp.DEFAULT_TAG = `ROOTPORT_TB.tx_usrapp.DEFAULT_TAG + 1;

                          //--------------------------------------------------------------------------
                          // Event : IO Read bit TLP
                          //--------------------------------------------------------------------------


                          // make sure P_READ_DATA has known initial value
                          `ROOTPORT_TB.tx_usrapp.P_READ_DATA = 32'hffff_ffff;
                          fork
                             `ROOTPORT_TB.tx_usrapp.TSK_TX_IO_READ(`ROOTPORT_TB.tx_usrapp.DEFAULT_TAG,
                                `ROOTPORT_TB.tx_usrapp.BAR_INIT_P_BAR[`ROOTPORT_TB.tx_usrapp.ii][31:0], 4'hF);
                             `ROOTPORT_TB.tx_usrapp.TSK_WAIT_FOR_READ_DATA;
                          join
                          if  (`ROOTPORT_TB.tx_usrapp.P_READ_DATA != 32'hdead_beef)
                             begin
                               $display("[%t] : Test FAILED --- Data Error Mismatch, Write Data %x != Read Data %x",
                                   $realtime, 32'hdead_beef, `ROOTPORT_TB.tx_usrapp.P_READ_DATA);
                               test_failed_flag = 1;
                             end
                          else
                             begin
                               $display("[%t] : Test PASSED --- Write Data: %x successfully received",
                                   $realtime, `ROOTPORT_TB.tx_usrapp.P_READ_DATA);
                             end


                          `ROOTPORT_TB.tx_usrapp.TSK_TX_CLK_EAT(10);
                          `ROOTPORT_TB.tx_usrapp.DEFAULT_TAG = `ROOTPORT_TB.tx_usrapp.DEFAULT_TAG + 1;


                        end

                   2'b10 : // MEM 32 SPACE
                        begin


                          $display("[%t] : Transmitting TLPs to Memory 32 Space BAR %x", $realtime,
                              `ROOTPORT_TB.tx_usrapp.ii);

                          //--------------------------------------------------------------------------
                          // Event : Memory Write 32 bit TLP
                          //--------------------------------------------------------------------------

                          `ROOTPORT_TB.tx_usrapp.DATA_STORE[0] = 8'h04;
                          `ROOTPORT_TB.tx_usrapp.DATA_STORE[1] = 8'h03;
                          `ROOTPORT_TB.tx_usrapp.DATA_STORE[2] = 8'h02;
                          `ROOTPORT_TB.tx_usrapp.DATA_STORE[3] = 8'h01;

                          `ROOTPORT_TB.tx_usrapp.TSK_TX_MEMORY_WRITE_32(`ROOTPORT_TB.tx_usrapp.DEFAULT_TAG,
                              `ROOTPORT_TB.tx_usrapp.DEFAULT_TC, 10'd1,
                              `ROOTPORT_TB.tx_usrapp.BAR_INIT_P_BAR[`ROOTPORT_TB.tx_usrapp.ii][31:0]+8'h10, 4'h0, 4'hF, 1'b0);
                          `ROOTPORT_TB.tx_usrapp.TSK_TX_CLK_EAT(10);
                          `ROOTPORT_TB.tx_usrapp.DEFAULT_TAG = `ROOTPORT_TB.tx_usrapp.DEFAULT_TAG + 1;

                          //--------------------------------------------------------------------------
                          // Event : Memory Read 32 bit TLP
                          //--------------------------------------------------------------------------


                         // make sure P_READ_DATA has known initial value
                         `ROOTPORT_TB.tx_usrapp.P_READ_DATA = 32'hffff_ffff;
                          fork
                             `ROOTPORT_TB.tx_usrapp.TSK_TX_MEMORY_READ_32(`ROOTPORT_TB.tx_usrapp.DEFAULT_TAG,
                                 `ROOTPORT_TB.tx_usrapp.DEFAULT_TC, 10'd1,
                                 `ROOTPORT_TB.tx_usrapp.BAR_INIT_P_BAR[`ROOTPORT_TB.tx_usrapp.ii][31:0]+8'h10, 4'h0, 4'hF);
                             `ROOTPORT_TB.tx_usrapp.TSK_WAIT_FOR_READ_DATA;
                          join
                          if  (`ROOTPORT_TB.tx_usrapp.P_READ_DATA != {`ROOTPORT_TB.tx_usrapp.DATA_STORE[3],
                             `ROOTPORT_TB.tx_usrapp.DATA_STORE[2], `ROOTPORT_TB.tx_usrapp.DATA_STORE[1],
                             `ROOTPORT_TB.tx_usrapp.DATA_STORE[0] })
                             begin
                               $display("[%t] : Test FAILED --- Data Error Mismatch, Write Data %x != Read Data %x",
                                    $realtime, {`ROOTPORT_TB.tx_usrapp.DATA_STORE[3],`ROOTPORT_TB.tx_usrapp.DATA_STORE[2],
                                     `ROOTPORT_TB.tx_usrapp.DATA_STORE[1],`ROOTPORT_TB.tx_usrapp.DATA_STORE[0]},
                                     `ROOTPORT_TB.tx_usrapp.P_READ_DATA);
                               test_failed_flag = 1;

                             end
                          else
                             begin
                               $display("[%t] : Test PASSED --- Write Data: %x successfully received",
                                   $realtime, `ROOTPORT_TB.tx_usrapp.P_READ_DATA);
                             end


                          `ROOTPORT_TB.tx_usrapp.TSK_TX_CLK_EAT(10);
                          `ROOTPORT_TB.tx_usrapp.DEFAULT_TAG = `ROOTPORT_TB.tx_usrapp.DEFAULT_TAG + 1;

                     end
                2'b11 : // MEM 64 SPACE
                     begin


                          $display("[%t] : Transmitting TLPs to Memory 64 Space BAR %x", $realtime,
                              `ROOTPORT_TB.tx_usrapp.ii);


                          //--------------------------------------------------------------------------
                          // Event : Memory Write 64 bit TLP
                          //--------------------------------------------------------------------------

                          `ROOTPORT_TB.tx_usrapp.DATA_STORE[0] = 8'h64;
                          `ROOTPORT_TB.tx_usrapp.DATA_STORE[1] = 8'h63;
                          `ROOTPORT_TB.tx_usrapp.DATA_STORE[2] = 8'h62;
                          `ROOTPORT_TB.tx_usrapp.DATA_STORE[3] = 8'h61;

                          `ROOTPORT_TB.tx_usrapp.TSK_TX_MEMORY_WRITE_64(`ROOTPORT_TB.tx_usrapp.DEFAULT_TAG,
                              `ROOTPORT_TB.tx_usrapp.DEFAULT_TC, 10'd1,
                              {`ROOTPORT_TB.tx_usrapp.BAR_INIT_P_BAR[`ROOTPORT_TB.tx_usrapp.ii+1][31:0],
                              `ROOTPORT_TB.tx_usrapp.BAR_INIT_P_BAR[`ROOTPORT_TB.tx_usrapp.ii][31:0]+8'h20}, 4'h0, 4'hF, 1'b0);
                          `ROOTPORT_TB.tx_usrapp.TSK_TX_CLK_EAT(10);
                          `ROOTPORT_TB.tx_usrapp.DEFAULT_TAG = `ROOTPORT_TB.tx_usrapp.DEFAULT_TAG + 1;

                          //--------------------------------------------------------------------------
                          // Event : Memory Read 64 bit TLP
                          //--------------------------------------------------------------------------


                          // make sure P_READ_DATA has known initial value
                          `ROOTPORT_TB.tx_usrapp.P_READ_DATA = 32'hffff_ffff;
                          fork
                             `ROOTPORT_TB.tx_usrapp.TSK_TX_MEMORY_READ_64(`ROOTPORT_TB.tx_usrapp.DEFAULT_TAG,
                                 `ROOTPORT_TB.tx_usrapp.DEFAULT_TC, 10'd1,
                                 {`ROOTPORT_TB.tx_usrapp.BAR_INIT_P_BAR[`ROOTPORT_TB.tx_usrapp.ii+1][31:0],
                                 `ROOTPORT_TB.tx_usrapp.BAR_INIT_P_BAR[`ROOTPORT_TB.tx_usrapp.ii][31:0]+8'h20}, 4'h0, 4'hF);
                             `ROOTPORT_TB.tx_usrapp.TSK_WAIT_FOR_READ_DATA;
                          join
                          if  (`ROOTPORT_TB.tx_usrapp.P_READ_DATA != {`ROOTPORT_TB.tx_usrapp.DATA_STORE[3],
                             `ROOTPORT_TB.tx_usrapp.DATA_STORE[2], `ROOTPORT_TB.tx_usrapp.DATA_STORE[1],
                             `ROOTPORT_TB.tx_usrapp.DATA_STORE[0] })

                             begin
                               $display("[%t] : Test FAILED --- Data Error Mismatch, Write Data %x != Read Data %x",
                                   $realtime, {`ROOTPORT_TB.tx_usrapp.DATA_STORE[3],
                                   `ROOTPORT_TB.tx_usrapp.DATA_STORE[2], `ROOTPORT_TB.tx_usrapp.DATA_STORE[1],
                                   `ROOTPORT_TB.tx_usrapp.DATA_STORE[0]}, `ROOTPORT_TB.tx_usrapp.P_READ_DATA);
                               test_failed_flag = 1;
                             end
                          else
                             begin
                               $display("[%t] : Test PASSED --- Write Data: %x successfully received",
                                   $realtime, `ROOTPORT_TB.tx_usrapp.P_READ_DATA);
                             end


                          `ROOTPORT_TB.tx_usrapp.TSK_TX_CLK_EAT(10);
                          `ROOTPORT_TB.tx_usrapp.DEFAULT_TAG = `ROOTPORT_TB.tx_usrapp.DEFAULT_TAG + 1;


                     end
                default : $display("Error case in usrapp_tx\n");
            endcase

         end


    $display("[%t] : Finished transmission of PCI-Express TLPs", $realtime);
    if (!test_failed_flag) begin 
       $display ("Test Completed Successfully");
    end 
    $finish;
end
