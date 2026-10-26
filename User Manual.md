3DUptake
3DUptake is a Fiji/ImageJ workflow for quantifying intracellular uptake from live-cell shadow imaging datasets. The workflow combines live-cell shadow imaging, automated thresholding, vesicle segmentation, and optional Cellpose-based cell segmentation to generate volumetric uptake measurements and quality-control outputs.

Note: 3DUptake is currently optimized for adherent cell lines and may not perform reliably on suspension cells.

Features
Automated 3D uptake quantification
Full-cell volumetric measurements
Optional Cellpose 4 cell segmentation
Quality-control reference images
2D benchmarking against selected z-slices
Support for TIFF and BioFormats-compatible image formats
Batch analysis of multiple datasets
Optional completion notifications via ntfy
Requirements
Hardware
Windows, macOS, or Linux
CUDA-compatible GPU recommended for Cellpose acceleration
Apple Silicon GPUs supported via MPS
Imaging
Recommended imaging systems:

Spinning disk confocal
Fast Airyscan
Resonant scanning confocal
Software Requirements
Software	Version
Fiji/ImageJ	1.54p or later
Cellpose	4.0.4
Python	3.9–3.12
Required packages:

Fiji/ImageJ
BIOP Fiji Wrappers
Cellpose 4
Python environment (Conda, Miniforge, Anaconda, or venv)
Installation
1. Install Python
Miniforge
https://github.com/conda-forge/miniforge

Anaconda
https://www.anaconda.com/download

2. Install Fiji
Download Fiji:

https://fiji.sc/

3. Install BIOP Fiji Wrappers
In Fiji:

Help → Update...
Select:

Manage Update Sites
Enable:

PTBIOP
Then:

Apply and Close
Apply Changes
4. Install Cellpose
Create a new environment:

conda create --name cellpose python=3.12
Activate the environment:

conda activate cellpose
Install Cellpose:

pip install cellpose==4.0.4
Install the GUI:

python -m pip install "cellpose[gui]"
Apple Silicon
pip install torch torchvision
5. Install 3DUptake
Download the latest release from the repository.

Within Fiji:

Plugins → Macros → Install...
Select:

3DUptake.ijm
Optimising Cellpose Parameters
Before analysing experimental datasets, optimise Cellpose using representative images.

Launch Cellpose:

conda activate cellpose
python -m cellpose
Verify GPU acceleration is detected correctly.

Recommended Starting Parameters
Parameter	Value
Diameter	200–300
Flow Threshold	0.6
Cell Probability Threshold	-2 to -4
Test both:

Average Intensity Projection
Sum Intensity Projection
Optimal settings may vary between cell types and microscopes.

Running 3DUptake
Launch from Fiji:

Plugins → Macros → 3DUptake
Select the desired parameters and start the analysis.

Main Parameters
File Extension
Image format used in the input folder.

TIFF files are loaded directly.
Other formats are imported using BioFormats.
Threshold Method
Recommended starting value:

Default
Alternative:

Huang
may perform better for some datasets.

Vesicle Area (µm²)
Suggested starting range for macropinosomes:

0.5–100 µm²
Circularity
Suggested starting range:

0.8–1.0
Cellpose Segmentation
Optional single-cell segmentation.

Parameters:

Cell Diameter
Cell Probability Threshold
Flow Threshold
should be determined during parameter optimisation.

Reference Files
Enabling reference images is strongly recommended.

Generated reference images contain:

Channel	Description
Red	Cell body
Green	Vesicles
Blue	Cellpose segmentation
These images allow rapid quality control of segmentation performance.

2D Benchmark Mode
Requires Cellpose segmentation.

Additional measurements are generated from:

Lower cell slice
Mid-cell slice
Results are saved separately from the main 3D analysis.

Output Files
Typical output includes:

Result_<version>_<date>_<time>.csv
Main results table.

Log.txt
Analysis settings and run information.

Summary_<filename>.tif
Quality-control image.

Result_low_<version>_<date>_<time>.csv
Lower-slice 2D measurements.

Result_mid_<version>_<date>_<time>.csv
Mid-slice 2D measurements.

2D_Summary_<filename>.tif
2D benchmark quality-control image.

Quality Control
Inspect the generated reference images after every analysis.

Cell Thresholding
Check that:

Cell boundaries are preserved.
Background pixels are excluded.
Empty slices are not influencing threshold selection.
Vesicle Segmentation
Inspect Channel 2 (green) and verify:

Minimal false positives
Minimal background noise
Vesicles are detected consistently
Recommended Imaging Conditions
Signal-to-Noise Ratio
For reliable thresholding:

SNR > 20 when cell shadow is considered background
SNR > 15 when fluorescent medium is considered background
Acquisition Speed
Rapid acquisition is recommended for dynamic uptake experiments.

Example spinning-disk performance:

Full stack acquired in approximately 5 seconds
Nyquist z-sampling (~0.18 µm)
Z-Stack Selection
When defining acquisition limits:

Start at the first fully focused cell plane.
End before the cell completely disappears.
Avoid unnecessary medium-only slices.
Troubleshooting
Cellpose Environment Not Found
Verify that the correct environment path has been selected.

Typical locations:

Windows
C:\Users\<username>\Anaconda3
macOS
/opt/anaconda3/envs/<environment>
Linux
/opt/anaconda3/envs/<environment>
Experimental Protocol
Detailed experimental procedures are available on Protocols.io:

https://www.protocols.io/view/3duptake-kqdg3mj9el25/v1

Citation
If you use 3DUptake in published work, please cite:

(Citation to be added after publication.)

License
(License information to be added.)
