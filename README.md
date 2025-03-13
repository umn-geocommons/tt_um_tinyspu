![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# TinySPU -- Tiny Spatial Processing Unit

Tiny SPU is a proof of concept spatial processing unit. Originally developed for the TinyTapeout project, TinySPU is designed to be a hardware accelerator for spatial operations. TinySPU is powerful and flexible to operate on key vector, raster, and AI operands. 

- [Read the technical documentation](docs/info.md)

## Structure of TinySPU

TinySPU is structured to process a variety of spatial operations. The chip has four 4-bit integer input registers: A B C D, which are loaded via a multiplexer Q. Then a four-bit operation code, opCode, chooses the calculation to be performed. The results are output to two 4-bit registers, M and N.

## Operations

TinySPU is equipped to perform multiple spatial operations:

### Vector Operations
* Manhattan distance & aspect direction
* Bounding box area & perimeter
* Basic buffer
* 8-bit Manhattan distance

### Raster Operations
* Attribute comparison/reclass
* Focal row mean
* Focal row sum
* Focal row max pool
* Local division

### AI Operations
* 8-bit Dot product
* Custom local operation

### Data Management
* Equals gate
* Minimum gate
* Zero outputs

## Authors
  
Eric Shook - Associate Professor, Geography Environment & Society, University of Minnesota
Logan Gall - Masters of Geographic Information Science, University of Minnesota  

## What is Tiny Tapeout?

Tiny Tapeout is an educational project that aims to make it easier and cheaper than ever to get your digital and analog designs manufactured on a real chip.

To learn more and get started, visit https://tinytapeout.com.
