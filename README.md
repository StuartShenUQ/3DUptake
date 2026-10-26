# **3DUptake Analysis**

[![Repo Size](https://img.shields.io/github/repo-size/StuartShenUQ/3DUptake)](https://github.com/StuartShenUQ/3DUptake)

**3DUptake is a Fiji/ImageJ workflow for quantifying intracellular uptake from live-cell shadow imaging datasets. The workflow combines live-cell shadow imaging, high-speeding live imaging capability of spinning-disc microscopy, automated thresholding, vesicle segmentation, and optional Cellpose-based cell segmentation to generate volumetric uptake measurements and quality-control outputs.**

---

> **Note:** 3DUptake is currently optimized for adherent cell lines and may not perform reliably on suspension cells.

Live imaging is performed by enriching the surrounding medium with fluorescent soluble cargo, with **unlabelled** cells shown as shadow. Detailed protocol of imaging acquisition can be found in these publications [JOVE](https://www.jove.com/t/62870/live-fluorescence-inverse-imaging-cell-ruffling), [JCS](https://www.jove.com/t/62870/live-fluorescence-inverse-imaging-cell-ruffling), or this [protocol](https://www.protocols.io/view/3duptake-jy6ycpzfx).
To learn more about Cellpose-SAM, check out the cellpose official repo [Mouseland/cellpose](https://github.com/MouseLand/cellpose/).

## **Changelog**
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

---

### Cellpose
> For the latest version and installation, refer to the offical Cellpose [repository](https://github.com/MouseLand/cellpose/).

Python environemnt is required for Cellpose segmentation. Virtual environment can be installed using [miniforge](https://github.com/conda-forge/miniforge), [Anaconda](https://www.anaconda.com/download), or python [venv](https://docs.python.org/3/library/venv.html).

#### Installation
> example using conda environment

In terminal window (Command Prompt or Terminal)
```bash
conda create --name cellpose python=3.12
```

Activate virtual python environment
```bash
conda activate cellpose
```
Install cellpose 4 (tested upto cellpose 4.0.4):
```bash
pip install cellpose==4.0.4
```

Install cellpose GUI (graphical user interface):
```bash
python -m pip install ‘cellpose[gui]’
```

Apple silicon may need to install pytorch to enable GPU support, found at https://pytorch.org/get-started/locally/
install with: pip3 install torch torchvision


#### Dependencies
Necessary dependencies will be installed during cellpose installation.
> To enable GPU acceleration on Apple Silicon equipped computers, install [pytorch](https://pytorch.org/get-started/locally/) with MPS support.
```bash
install with: pip3 install torch torchvision
```

---

### BIOP/ Wrappers for Fiji
In Fiji:
```
Update... - Manage Update Sites - PTBIOP
```

> BIOP/ijl-utilities-wrapper is required to access cellpose within Fiji. More details can be found [here](https://github.com/BIOP/ijl-utilities-wrappers).

---

### Install the 3DUptake Macro
> Under construction

## Usage

## Example Workflow

### Sample data and examples
Sample shadow imaging dataset and example output can be downloaded on [Zenodo archive](https://zenodo.org/records/20754623) (doi: 10.5281/zenodo.20754623)

# Citation
**3DUptake**
JCS

**Shadow imaging**
JOVE

**Cellpose**
1.0
2.0
Human in the loop
SAM

# Funding

# Licnese
BSD 3-Clause License