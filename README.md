# **3DUptake Analysis**

[![repo size](https://img.shields.io/github/repo-size/StuartShenUQ/3DUptake/)](https://github.com/StuartShenUQ/3DUptake/)

**3D Uptake is a workflow combining living imaging and a fully automated analysis that leverage the high-speeding live imaging capability of spinning-disc microscopy and AI cell segmentation tool cellpose to quantitively measure the uptake efficiency of soluble cargo in cells**

Live imaging is performed by enriching the surrounding medium with fluorescent soluble cargo, with **unlabelled** cells shown as shadow. Detailed protocol of imaging acquisition can be found in this [paper](https://www.jove.com/t/62870/live-fluorescence-inverse-imaging-cell-ruffling), or this [protocol](https://www.protocols.io/view/3duptake-jy6ycpzfx). Link for the upcoming manuscript will be added later.
To learn more about Cellpose-SAM, check the cellpose official repo [Mouseland/cellpose](https://github.com/MouseLand/cellpose/).

Installation instructions for all related programs can be found [below](README.md/##Installation).

## **Updates**
### v1.0 (May 2026)
* First release

## Installation

### System requirements

Linux, Windows and Mac OS are supported for running the code. The code has been tested on Windows 10/11 and MAC OS 26. Please open an issue if you have problems with installation. A discrete GPU is advised for running Cellpose.

### FIJI installation
FIJI can be installed following this [link](https://fiji.sc/).

### BIOP/ Wrappers for FIJI
BIOP/ijl-utilities-wrapper is required to access cellpose within FIJI. More details can be found [here](https://github.com/BIOP/ijl-utilities-wrappers).
Plug-ins can be installed by FIJI - Update... - Manage Update Sites - PTBIOP.

### Cellpose
Refer to the offical cellpose [repo](https://github.com/MouseLand/cellpose/) for the installation guide.
You can install cellpose using conda or with native python if you have python3.8+ on your machine. Alternatively, cellpose can be installed in conda environment using [Anaconda](https://www.anaconda.com/).

### Dependencies
Cellpose will automatically install missing dependencies upon installation. To enable GPU acceleration on Apple Silicon (M1/2/3/4/5) equipped computers, additionally install [pytorch](https://pytorch.org/get-started/locally/) with MPS support.

# Sample data and examples
