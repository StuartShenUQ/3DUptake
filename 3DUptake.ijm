setBatchMode(true);

run("Clear Results");
roiManager("reset");
print("\\Clear")
if (nImages > 0) {
	waitForUser("Save any unsaved files, and click OK to close all windows");
}
run("Close All");

getDateAndTime(year, month, week, day, hour, min, sec, msec);
startTime = getTime();
methodList = getList("threshold.methods");
extras = newArray("---", "Dragonfly de-noise", "Airyscan border removal", "In development");
fileCount = 0;
totalCount = 0;
skipped = 0;
concatMes = "";
concatEst = "";
fs = File.separator;
run("Set Measurements...", "area mean min integrated redirect=None decimal=3");
indf = 0;

//Set cellpose environment directory
cellposeDir = "";
if (substring(getInfo("os.name"), 0, 3) == "Mac") {
	cellposeDir = "/opt/anaconda3/envs/cellposeSAM";
}
if (substring(getInfo("os.name"), 0, 3) == "Win") {
	cellposeDir = "C:\\Users\\Public\\Documents\\Anaconda_MU\\envs\\cellpose";
}

print("Volumetric Analysis of endosomal vesicles (inverse fluorescent imaging)");
print("Scripted by Hongyu (Stuart) Shen");
print("with help of Dr. Nicholas D. Condon");
print("as part of a PhD project in Jennifer L. Stow's Lab");
print("Institute for Molecular Bioscience | The University of Queensland\n");
print("Version 0.9.9C (cellpose) | Cellpose 4.0,  Model: CPSAM");
print("Dependencies: Conda environemnt, Cellpose, BIOP FIJI Wrapper");
print("Script Run Date: " + day + "/" + (month+1) + "/" + year + "  Time: " + hour + ":" + min + ":" + sec);
print("=============================================================");

//Create dialog to get input/output directory
Dialog.create("Setup");
	Dialog.setInsets(0,0,15);
	Dialog.addString("File Extension:", ".tif");
	Dialog.addToSameRow();
 	Dialog.addMessage("For example .czi  .ims .lsm  .nd2  .lif");
	Dialog.setInsets(0,0,15);
	Dialog.addDirectory("Input folder:", "");
	Dialog.setInsets(0,0,15);
	Dialog.addChoice("Threshold method", methodList, "");
	Dialog.addToSameRow();
	Dialog.addMessage("Confocal - Huang | Airyscan/DragonFly - Default");
	Dialog.setInsets(0,0,5);
	Dialog.addString("Vesicle Area (µm^2) :", "0.5-100");
	Dialog.setInsets(0,70,5);
	Dialog.addMessage("-----------------------------------------------------------------------------------");
	Dialog.setInsets(0,135,5);
	Dialog.addCheckbox("Cellpose", true);
	Dialog.addToSameRow();
	Dialog.addCheckbox("Cellpose preprocessing", false);
	Dialog.addToSameRow();
	Dialog.addCheckbox("Multichannel classification", false);
	Dialog.setInsets(0,0,5);
	Dialog.addDirectory("Cellpose directory:", cellposeDir);
	Dialog.setInsets(0,135,5);
	Dialog.addMessage("Default directory: " + fs + "*Anaconda installation folder*" + fs + "envs" + fs + "cellpose");
	Dialog.addString("Cell diameter:", "300");
	Dialog.addToSameRow();
	Dialog.addString("Cell probability:", "-2");
	Dialog.addToSameRow();
	Dialog.addString("Flow threshold:", "0.6");
	Dialog.setInsets(0,135,5);
	Dialog.addCheckbox("Custom Model", false);
	Dialog.setInsets(0,0,25);
	Dialog.addFile("Custom model:", "Custom model location");
	Dialog.setInsets(0,70,5);
	Dialog.addMessage("-----------------------------------------------------------------------------------");
	Dialog.setInsets(0,135,5);
	Dialog.addCheckbox("Reference files", true);
//	Dialog.addCheckbox("Dragonfly de-noise", true);
	Dialog.addChoice("Extras", extras);
Dialog.show();

ext = Dialog.getString();
inputPath = Dialog.getString();
outputPath = inputPath + "Output" + fs;
File.makeDirectory(outputPath);
refPath = outputPath + "References_" + year + "-" + (month+1) + "-" + day + "_" + hour + "." + min + fs;
method = Dialog.getChoice();
vesSize = Dialog.getString();
cellpose = Dialog.getCheckbox();
preprocess = Dialog.getCheckbox();
multichannel = Dialog.getCheckbox();
cellposeDir = Dialog.getString();
cellD = Dialog.getString();
cellProb = Dialog.getString();
flowTh = Dialog.getString();
customModel = Dialog.getCheckbox();
model = Dialog.getString();
refMode = Dialog.getCheckbox();
//deNoise = Dialog.getCheckbox();
extrasChoice = Dialog.getChoice();
if (cellpose == false) {
	multichannel = false;
}

//Input file path
list = getFileList(inputPath);

//Define Cellpose directory
if (cellpose == true) {
	print("Cellpose: Enabled...");
	while (File.isDirectory(cellposeDir) == 0) {
		Dialog.create("Error");
			Dialog.setInsets(0,0,5);
			Dialog.addMessage("Cellpose directory not found...");
			Dialog.addDirectory("Cellpose directory:", cellposeDir);
		Dialog.show();
		cellposeDir = Dialog.getString();
	}
	
	if (multichannel == true) {
		channelList = newArray();
		for (i = 0; i < list.length; i++) {
			if (endsWith(list[i], ext)) {
				open(inputPath+list[i]);
				getDimensions(width, height, channels, slices, frames);
				for (i = 0; i < channels; i++) {
					channelList[i] = "" + (i + 1);
				}
				break;
			}
		}	
	
		//User identify the reference channel
		setBatchMode("show");
		Stack.setDisplayMode("color");
		waitForUser("Identify the reference channel and measuring channel (if applicable)");
		close();
		
		Dialog.create("Setup");
		Dialog.addMessage("Make sure all images in the input directory has the same channel number and order");
		Dialog.setInsets(15,20,15);
		Dialog.addRadioButtonGroup("Pick the referencing channel:", channelList, 1, channels, "");
		if (channelList.length > 2) {
			Dialog.setInsets(15,0,15);
			Dialog.addRadioButtonGroup("Pick the measuring channel:", channelList, 1, channels, "");
		}
		Dialog.show();
		
		refChannel = Dialog.getRadioButton();
		if (channelList.length == 2) {
			if (refChannel == 1) {
				mesChannel = 2;
			}
			else {
				mesChannel = 1;
			}
		}
		if (channelList.length > 2) {
			mesChannel = Dialog.getRadioButton();
		}
	}
}

else {
	print("Cellpose: Disabled...");
}
print("=============================\n");

//Define functions -------------------------------------------------------------------------------------------------------------
function progressBar(progress, total, index) {
	//Progress bar
	bar = "";

	barL = ">>>>>>>>>>>>>>>>>>>>>>>>>";
	barR = "=========================";
	
	range = barL.length;
	p = progress/total*range;
	pp = p-range/total;
	
	for (i = 0; i <= p; i ++) {
		if (i >= pp) {
			print("\\Update" + index + ":" + "[" + substring(barL, 0, i) + substring(barR, i, range) + "] " + round(progress/total*100) + "%");
			wait(20);
		}
	}
}

function Processing(vesSize) { 
// Pre-processing image for measurements
	//Threshold and Binary convert
	run("Clear Results");
	print("\\Update" + index + ":Pre-processing...");
	index = index + 2;
	
	selectImage("Input");
	if (extrasChoice == "Airyscan border removal"){
		run("Threshold...");
		setThreshold(100.0000, 1000000000000000000000000000000.0000);
	}
	else {
		setAutoThreshold(method + " dark no-reset");
	}
	run("Convert to Mask", "background=Dark black");
	
	//Smooth edges
	run("Median...", "radius=4.0 stack");
	
	//Make duplicates
	run("Duplicate...", "title=Cells duplicate");
	run("Duplicate...", "title=Vesicles duplicate");
	
	//Cell mask
	selectImage("Cells");
	run("Duplicate...", "title=Cellmask duplicate");
	run("Invert", "stack");
	run("Fill Holes", "stack");
	run("Invert", "stack");
	
	//Isolate Vesicle
	imageCalculator("Subtract create stack", "Vesicles","Cellmask");
	run("Watershed", "stack");
	run("Analyze Particles...", "size=" + vesSize + " circularity=0.8-1.00 show=Masks stack");
	
	//Prepare Volumetric Measurement Images
	selectImage("Cells");
	run("Invert", "stack");
	run("Subtract...", "value=254 stack");
	run("Z Project...", "projection=[Sum Slices]");
	
	selectImage("Mask of Result of Vesicles");
	rename("Vesiclemask");
	run("Subtract...", "value=254 stack");
	run("Z Project...", "projection=[Sum Slices]");
	
	run("Duplicate...", "title=Vesicle_count duplicate");
	
	//Splitting touched vesicels
	run("Duplicate...", "title=Vesicle_WS duplicate");
	run("8-bit");
	setThreshold(1, 255);
	run("Convert to Mask");
	run("Watershed");
	run("32-bit");
	imageCalculator("AND create 32-bit", "Vesicle_count", "Vesicle_WS");
	setThreshold(0.1, 1000000000000000000000000000000.0000);
}

function Classification() {
	// Classfying cells based on intensity in the reference channel
	run("Clear Results");

	//select transfected channel
	selectImage("refChannel");
	run("Z Project...", "projection=[Max Intensity]");
//	setAutoThreshold("Default dark no-reset");
	run("Convert to Mask", "background=Dark black");

	meanArray = newArray();
	meanSort = newArray();
	stepArray = newArray();
	classified = newArray();

	for (i = 0; i < RoiManager.size; i ++) {
		roiManager("select", i);
		run("Measure");
	}

	//Get Mean and sort intensity in the reference channel
	for (l = 0; l < nResults; l ++) {
		meanArray[l] = getResult("Mean", l);
		meanSort[l] = getResult("Mean", l);
	}
	Array.sort(meanSort);

	for (k = 0; k < meanSort.length-1; k++) {
		if (meanSort[k] == 0) {
			meanSort[k] = 0.001;
		}
//		else{
			stepArray[k] = ((meanSort[k+1]-meanSort[k])/meanSort[k]);
		}
//	}

	step = stepArray[0];
	barIndex = 0;
	
	for (j = 0; j < stepArray.length; j++) {
		if (stepArray[j] > step) {
			step = stepArray[j];
			barIndex = j;
		}
	}

	for (p = 0; p < meanArray.length; p++) {
		if (meanArray[p] >= meanSort[barIndex+1]){
			classified = Array.concat(classified, p);
		}
	}
	return classified;
}

function Measurement() { 
// Measure cell and vesicle volume
	cellVol = getResult("IntDen", 0) * vDepth;
	vesVol = 0;
	mesVol = "";
	estVol = "";
	numVes = 0;
	
	for (l = 1; l < nResults; l ++) {
		if (getResult("Max", l) > 1) {
			pixA = getResult("Area", l);
			pixR = sqrt(pixA/PI);
			pixV = getResult("IntDen", l) * vDepth;
			
			//Estimated volume based on area
			estVol = estVol + (4/3 * PI * pow(pixR,3)) + ", ";
			//Measured volume
			mesVol = mesVol + pixV + ", ";
			//Calculate total
			vesVol = vesVol + pixV;
			//Number of vesicles
			numVes++;
		}
	}
	
	if (numVes == 0) {
				mesVol = mesVol + 0 + ", ";
				estVol = estVol + 0 + ", ";
		}
	
	value = newArray(cellVol, vesVol, mesVol, estVol, numVes);
	return value;
}

//----------------------------------------------------------------------------------------------------------------------------

for (i = 0; i < list.length; i++) {if (endsWith(list[i], ext)){totalCount++;}}
if (refMode == true) {File.makeDirectory(refPath);}

//Create Output File
Results = File.open(outputPath + "Results_" + year + "-" + (month+1) + "-" + day + "_" + hour + "." + min + ".csv");
print(Results, "File Number, File Name, Cell Count, Cell ID, Cell Volume, Total Vesicular Volume, Macropinocytic Index, Vesicle Count, Average Vesicle Size, Individual Vesicular Size");

for (i = 0; i < list.length; i++) {
	if (endsWith(list[i], ext)) {
		index = 12;
		fileCount++;
		print("\\Update" + index + ":Processing Image " + fileCount + "/" + totalCount);
		index++;
		progressBar(fileCount, totalCount, index);
		index = index + 2;
		//Clear previous log
		for (m = index; m <= indf; m++) {
			print("\\Update" + m + ": ");
		}
		run("Clear Results");
		roiManager("reset");
		showProgress(i + 1, totalCount);
		open(inputPath+list[i]);
		getDimensions(width, height, channels, slices, frames);
		
		if (slices == 1) {
    		showMessage("Error", "This image is not a volume image.");
    		exit();
		}
		
		//Dragonfly noise compensation
		if (extrasChoice == "Dragonfly de-noise"){
			run("Duplicate...", "duplicate range=2-" + slices - 2);
		}
		
		rename("Input");
		getVoxelSize(vWidth, vHeight, vDepth, vUnit);
		
		//Prepare for classification
		if (multichannel == true) {
			run("Split Channels");			
			selectImage("C" + refChannel + "-Input");
			rename("refChannel");
			selectImage("C" + mesChannel + "-Input");
			rename("Input");
		}
		
		//Airyscan remove border
		if (extrasChoice == "Airyscan border removal"){
			makeRectangle(13, 13, width-26, height-26);
			run("Crop");
		}

		if (cellpose == true) {
			modelPath = "model=cpsam model_path=";
			if (customModel == true) {
				modelPath = "model=[ ] model_path=" + model;
			}
			runParameter = "env_path=" + cellposeDir + " env_type=conda " + modelPath + " diameter=" + cellD + " ch1=0 ch2=-1 additional_flags=[--use_gpu, --cellprob_threshold, " + cellProb + ", --flow_threshold, " + flowTh + "]";
			
			//Cellpose initiation
			run("Duplicate...", "title=Segmentation duplicate");
			
			//Pre-processing
			if (preprocess == true) {
				run("Sharpen", "stack");
				run("Z Project...", "projection=[Average Intensity]");
				run("Invert");
				selectImage("AVG_Segmentation");
				rename("Segmentation");
			}
			
			//Cellpose Segmentation
			print("\\Update" + index + ":Cellpose Processing...");
			index++;
			run("Cellpose ...", runParameter);

			//Cellpose to ROI (@ Nick)---
			selectWindow("Segmentation-cellpose");
			run("Select All");
			getMinAndMax(min, max);
			for (j = 1; j <= max; j ++) {
				setThreshold(j, j);
				run("Create Selection");
				run("Measure");
				if (getResult("Area", j - 1) > 10) {roiManager("Add");}
				resetThreshold();
			}
			
			//Exception and Output Headings
			if (RoiManager.size == 0) {
				print("\\Update" + index + ":No cell found, skipped to the next file.");
				skipped++;
				run("Close All");
				continue;
			}
			else {
				print("\\Update" + index + ":" + RoiManager.size + " cell(s) found.");
				index = index + 2;
			}
		}
		
		//Pre-processing images for measurements
		Processing(vesSize);
		
		//Measurements with Clipping Masks
		if (multichannel == true) {
			print("\\Update" + index + ":Classifying cells...");
			index++;
		}
		print("\\Update" + index + ":Measuring...");
		index++;
		
		if (cellpose == true) {
			if (multichannel == true) {
				classified = Classification();
				print("\\Update" + (index-2) + ":Classifying cells... " + classified.length + " positive cells found.");
				check = 0;
			}
			
			for (k = 0; k < RoiManager.size; k ++) {
				progressBar(k + 1, RoiManager.size, index);
				run("Clear Results");
				
				//Placeholder for multichannel output
				if (multichannel == true) {
					if (check < classified.length) {
						if (classified[check] == k) {
							check++;
						}
					}
				}

				//Measurments
				selectImage("SUM_Cells");
				roiManager("select", k);
				run("Measure");
				selectImage("Result of Vesicle_count");
				roiManager("select", k);
				run("Analyze Particles...", "size=0-50 circularity=0.0-1.00 show=Masks display stack");
				
				//Measure cell and vesicle volume
				measurement = Measurement();
				concatMes = concatMes + measurement[2];
				concatEst = concatEst + measurement[3];
				
				//Output file
				print(Results, fileCount + "," + File.getNameWithoutExtension(list[i]) + "," + RoiManager.size + "," + fileCount + "_" + k + 1 + "," +  measurement[0] + "," + measurement[1] + "," + measurement[1]/measurement[0] + "," + measurement[4] + "," + measurement[1]/measurement[4] + "," + measurement[2]);
			}
			index = index + 2;
		}
		
		else {
			//Measurments
			index++;
			selectImage("SUM_Cells");
			run("Measure");
			selectImage("SUM_Vesiclemask");
			run("Measure");
			selectImage("Result of Vesicle_count");
			run("Analyze Particles...", "size=0-50 circularity=0.0-1.00 show=Masks display stack");
			
			//Measure cell and vesicle volume
			measurement = Measurement();
			concatMes = concatMes + measurement[2];
			concatEst = concatEst + measurement[3];
			
			//Output file
			print(Results, fileCount + "," + File.getNameWithoutExtension(list[i]) + ",,," + measurement[0] + "," + measurement[1] + "," + measurement[1]/measurement[0] + "," + measurement[4] + "," + measurement[1]/measurement[4] + "," + measurement[2]);
		}

		//Concatenate files for reference
		if (refMode == true) {
			print("\\Update" + index + ":Writing Referencing Files...");
			index = index + 1;
			
			if (cellpose == true) {
				run("Merge Channels...", "c1=SUM_Cells c2=[SUM_Vesiclemask] c3=Segmentation-cellpose create ignore");
				run("From ROI Manager");
			}
			else {
				run("Merge Channels...", "c1=SUM_Cells c2=[SUM_Vesiclemask] create ignore");
			}
			
			saveAs("Tiff", refPath + "Summary_" + File.getNameWithoutExtension(list[i]) + " " + year + "-" + (month+1) + "-" + day + "_" + hour + "." + min + ".tif");
		}
		print("\\Update" + index + ":Writing Outputs...");
		indf = index;
	}
	run("Close All");
}

//Display runtime to log window
run("Clear Results");
run("Collect Garbage");
print("\n=============================================================");
print("Batch Completed");
print("Threshold method: " + method);
print("Number of file(s) skipped: " + skipped);
print("Total Runtime was: " + (getTime()-startTime)/1000 + " sec.");
print("Results saved to " + outputPath);
if (refMode == true) {print("Reference images saved to " + refPath);}
selectWindow("Log");
saveAs("Text", refPath + "Log.txt");
print("\n");

//Exit message
exitTitle = "Batch Completed";
exitMsg = "Put down that iced oat latte! Your analysis is finished";
waitForUser(exitTitle, exitMsg);