# **3DUptake Analysis**

[![Repo Size](https://img.shields.io/github/repo-size/StuartShenUQ/3DUptake)](https://github.com/StuartShenUQ/3DUptake)

**3DUptake is a Fiji/ImageJ workflow for quantifying intracellular uptake from live-cell shadow imaging datasets. The workflow combines live-cell shadow imaging, high-speeding live imaging capability of spinning-disc microscopy, automated thresholding, vesicle segmentation, and optional Cellpose-based cell segmentation to generate volumetric uptake measurements and quality-control outputs.**

---

> **Note:** 3DUptake is currently optimized for adherent cell lines and may not perform reliably on suspension cells.

Live imaging is performed by enriching the surrounding medium with fluorescent soluble cargo, with **unlabelled** cells shown as shadow. Detailed protocol of imaging acquisition can be found in these publications [JOVE](https://www.jove.com/t/62870/live-fluorescence-inverse-imaging-cell-ruffling), [JCS](https://www.jove.com/t/62870/live-fluorescence-inverse-imaging-cell-ruffling), or this [protocol](https://www.protocols.io/view/3duptake-jy6ycpzfx).
To learn more about Cellpose-SAM, check out the cellpose official repo [Mouseland/cellpose](https://github.com/MouseLand/cellpose/).

## **Updates**
### v1.1 (Oct 2026)
* Added 2D Benchmarking
* Added filter to remove the cell clipped by image boundaries
* Added option for push notifications
* ...

### v1.0 (May 2026)
* First release

## Documentation
📖 Full User Manual can be found [here](README.md/##Installation).

## System requirements
### Hardware

- Windows, macOS, or Linux
- CUDA-compatible GPU recommended for Cellpose acceleration
- Apple Silicon GPUs supported via MPS

> The code has been tested on Windows 10/11 and MAC OS 26. Please open an issue if you have problems with installation.

---

### Imaging Equipments

Recommended imaging systems:

- Spinning disk confocal
- Fast Airyscan
- Laser scanning confocal with resonant scanner

---

### Software Requirements

| Software | Version |
|-----------|---------|
| Fiji/ImageJ | 1.54p or later |
| Cellpose | 4.0.4 or later |
| Python | 3.9–3.12 |

---

## Installation

### Fiji installation
Fiji can be installed following this [link](https://fiji.sc/).

### BIOP/ Wrappers for FIJI
In Fiji:
```text
Update... - Manage Update Sites - PTBIOP
```

> BIOP/ijl-utilities-wrapper is required to access cellpose within Fiji. More details can be found [here](https://github.com/BIOP/ijl-utilities-wrappers).

---

### Cellpose
> For the latest version and installation, refer to the offical cellpose [repo](https://github.com/MouseLand/cellpose/).

You can install cellpose using conda or with native python if you have python3.8+ on your machine. Alternatively, cellpose can be installed in conda environment using [Anaconda](https://www.anaconda.com/).

### Dependencies
Cellpose will automatically install missing dependencies upon installation. To enable GPU acceleration on Apple Silicon (M1/2/3/4/5) equipped computers, additionally install [pytorch](https://pytorch.org/get-started/locally/) with MPS support.

# Sample data and examples
