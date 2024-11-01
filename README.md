# gpu3d
Learning GPU from scratch

1. gpufunc - qt-application to understand basic GPU transformations
2. rtl - System Verilog source code
3. prj - Makefiles to build rtl for different targets: KC705 board, simulation
4. examples - different application to emulate or interact with the FPGA board

## Hardware

Use 'riscv_vhdl' project and additional IP blocks for KC705 board:

- PCIe endpoint IP.
- HDMI transceivers.


## RTL Simulation

1. Reuse RISC-V CPU with 1 GB DDR from 'riscv_vhdl' project reducing design: 
   1 core, no FPU, minimal I/D caches, no MMU.

2. Successfully run KC705 PCIe simulation tests: PCIe Endpoint, RootHub 
and test application. 5.0GT/s passed.

```
[             4995000] : System Reset De-asserted...
[            54193412] : Transaction Reset Is De-asserted...
[            78469405] : Transaction Link Is Up...
[            78513380] : TSK_PARSE_FRAME on Transmit
[            80145226] : TSK_PARSE_FRAME on Receive
[            86513254] :    Check Max Link Speed = 5.0GT/s - PASSED
[            86513254] : Check Negotiated Link Width = 1x - PASSED
[            86561191] : TSK_PARSE_FRAME on Transmit
[            88193404] : TSK_PARSE_FRAME on Receive
[            94561298] :    Check Device/Vendor ID - PASSED
[            94609341] : TSK_PARSE_FRAME on Transmit
[            96241266] : TSK_PARSE_FRAME on Receive
[           102609392] :    Check CMPS ID - PASSED
[           102609392] : SYSTEM CHECK PASSED
[           102609392] : Inspecting Core Configuration Space...
[           102657356] : TSK_PARSE_FRAME on Transmit
[           104257220] : TSK_PARSE_FRAME on Receive
[           104305319] : TSK_PARSE_FRAME on Transmit
[           105937276] : TSK_PARSE_FRAME on Receive
[           112353380] : TSK_PARSE_FRAME on Transmit
```

3. HDMI tests (in progress)

## Software

Let's build fully functional PCIe device with the HDMI output
and then will think what to implement as a user application - 
GPU pipeline or AI math. accelerator.

