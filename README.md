This repository contains a high-performance, synthesis-ready **AXI4-Stream Sobel Edge Detection IP**. Designed as a "drop-in" hardware accelerator for FPGA video pipelines, this core performs real-time spatial gradient calculations with zero software overhead.

By utilizing the standard AXI4-Stream protocol, this IP seamlessly integrates with Xilinx VDMA, Video Out bridges, and sensor capture cores to provide instantaneous edge detection for computer vision applications.

## Specifications
* **Interface**: AXI4-Stream (Slave and Master).
* **Data Width**: 16-bit `tdata` (Configurable via `TDATA_W`). 
* **Resolution**: 640x480 default (Fully configurable via `H_ACTIVE` and `V_ACTIVE` parameters).
* **Color Processing**: RGB444 (12-bit active data).
* **Protocol Compliance**: Full support for `TUSER` (Start of Frame) and `TLAST` (End of Line).
* **Throughput**: 1 pixel per clock cycle with transparent back-pressure handling.

##  Key Features

###  Dynamic Flow Control
The IP implements a robust AXI4-Stream handshake mechanism. The internal pipeline `en` signal is tied directly to the downstream `m_axis_tready`. This ensures that if a downstream IP (like a VDMA) is busy, the Sobel filter freezes the pipeline and back-pressures the upstream camera source, preventing data corruption or frame loss.

###  Real-Time Thresholding
A dedicated 8-bit `THRESHOLD` port allows for live sensitivity adjustment. By wiring this to physical FPGA switches or an AXI4-Lite register, you can dynamically tune edge detection strength to compensate for varying lighting conditions without re-synthesizing the hardware.

###  Internal Coordinate Generation
The wrapper includes a **Dynamic Coordinate Generator** that uses incoming AXI signals to track pixel position:
* **`s_axis_tuser`**: Resets internal X/Y counters to synchronize with the Start of Frame.
* **`s_axis_tlast`**: Increments the Y-counter to designate the End of Line. 
This allows the internal `sobel_top` engine to perform complex 3x3 convolution math while remaining fully aware of image boundaries.

###  Shared Video Package
Built upon a centralized `video_pkg`, this IP shares the same structural definitions as our camera controllers. This unified approach makes scaling from VGA to **720p** or **1080p** as simple as updating a single package parameter, ensuring consistency across the entire video pipeline.

##  Repository Structure
* **`/src`**: 
    * `sobel_axis_wrapper.sv`: Top-level AXI-Stream wrapper and flow control.
    * `sobel_top.sv`: The core math engine performing the 3x3 gradient convolution.
    * `video_pkg.sv`: Shared definitions for pixel structs and timing.
* **`/sim`**: SystemVerilog testbenches for verifying kernel math and AXI handshaking.

##  Quick Integration
1.  **Package Setup**: Add `video_pkg.sv` to your Vivado project sources.
2.  **PAckage into IP:** Go to tools and 'Create and Package New IP'
3.  **Parameters**: Set `H_ACTIVE` and `V_ACTIVE` to match your sensor's resolution.
4.  **AXI-Stream Path**: Place the IP between your camera capture core and your DMA engine. 
5.  **Threshold Input**: Map the 8-bit `THRESHOLD` input to your board's physical switches for immediate visual feedback.

**Would you like me to help you draft the final LinkedIn post or a Portfolio summary that links these two individual IP repositories together as a "Hardware Vision Suite"?**
