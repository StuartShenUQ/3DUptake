ver = "0.9.11C";
setBatchMode(true);
//setOption("ExpandableArrays", true); //For FIJI prior to Ver.1.53

run("Clear Results");
//run("Collect Garbage");
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
fs = File.separator;
run("Set Measurements...", "area mean min integrated redirect=None decimal=3");
indf = 0;

//Set a random hex string for ntfy channel
ntfyPref = call("ij.Prefs.get", "ntfy.channel", "");
if (ntfyPref == "") {
    ntfyPref = "3DUptake-ntfy-" + toHex(floor(random()*65535));
    call("ij.Prefs.set", "ntfy.channel", ntfyPref);
}

//Set cellpose environment directory
cellposeDir = "";
if (substring(getInfo("os.name"), 0, 3) == "Mac") {
	cellposeDir = "/opt/anaconda3/envs/cellpose";
}
if (substring(getInfo("os.name"), 0, 3) == "Win") {
	cellposeDir = "C:\\Users\\Public\\Documents\\Anaconda3\\envs\\cellpose";
}

print("Volumetric Analysis of endosomal vesicles (inverse fluorescent imaging)");
print("Scripted by Hongyu (Stuart) Shen with help of Dr. Nicholas D. Condon");
print("as part of a PhD project in Jennifer L. Stow's Lab");
print("Institute for Molecular Bioscience | The University of Queensland\n");
print("Version " + ver + " (cellpose) | Cellpose 4.0,  Model: CPSAM");
print("Dependencies: Conda environemnt, Cellpose, BIOP FIJI Wrapper");
print("Script Run Date: " + day + "/" + (month+1) + "/" + year + " Time: " + hour + ":" + min + ":" + sec);
print("=============================================================");

//Create dialog to get input/output directory
Dialog.create("Setup");
	Dialog.setInsets(0,0,15);
	Dialog.addString("File extension:", ".tif");
	Dialog.addToSameRow();
 	Dialog.addMessage("For example .czi  .ims .lsm  .nd2  .lif");
	Dialog.setInsets(0,0,15);
	Dialog.addDirectory("Input folder:", "");
	Dialog.setInsets(0,0,15);
	Dialog.addChoice("Threshold method:", methodList, "");
	Dialog.addToSameRow();
	Dialog.addMessage("Confocal - Huang | Airyscan/DragonFly - Default");
	Dialog.setInsets(0,0,5);
	Dialog.addString("Vesicle Area (µm^2) :", "0.5-100");
	Dialog.addToSameRow();
	Dialog.addString("Circularity:", "0.8-1.0");
	Dialog.setInsets(0,70,5);
	Dialog.addMessage("-----------------------------------------------------------------------------------");
	Dialog.setInsets(0,135,5);
	Dialog.addCheckbox("Cellpose", true);
	Dialog.addToSameRow();
	Dialog.addCheckbox("Cellpose preprocessing", true);
//	Dialog.addToSameRow();
//	Dialog.addCheckbox("Multichannel classification", false);
	Dialog.setInsets(0,0,5);
	Dialog.addDirectory("Cellpose directory:", cellposeDir);
	Dialog.setInsets(0,135,5);
	Dialog.addMessage("Default directory: " + fs + "*Anaconda installation folder*" + fs + "envs" + fs + "cellpose");//*Anaconda installation folder*" + fs + "envs" + fs + "cellpose");
	Dialog.setInsets(0,0,5);
	Dialog.addString("Cell diameter:", "300");
	Dialog.addToSameRow();
	Dialog.addString("Cell probability:", "-2");
	Dialog.addToSameRow();
	Dialog.addString("   Flow threshold:", "0.6");
	Dialog.setInsets(0,135,5);
	Dialog.addCheckbox("Custom model", false);
	Dialog.setInsets(0,0,25);
	Dialog.addFile("Custom model:", "");
	Dialog.setInsets(0,70,5);
	Dialog.addMessage("-----------------------------------------------------------------------------------");
	Dialog.setInsets(0,135,5);
	Dialog.addCheckbox("Reference files", true);
	Dialog.setInsets(0,135,5);
	Dialog.addCheckbox("Completion notification", false);
	Dialog.addToSameRow();
	Dialog.addString("ntfy channel: ntfy.sh/", ntfyPref, 30);
	Dialog.setInsets(0,135,5);
	Dialog.addCheckbox("2D Benchmark", false);
	Dialog.addChoice("Extra functions:", extras);
Dialog.show();

ext = toLowerCase(String.trim(Dialog.getString()));
inputPath = Dialog.getString();
outputPath = inputPath + "Output" + fs;
File.makeDirectory(outputPath);
refPath = outputPath + "References_" + ver + "_" + year + "-" + (month+1) + "-" + day + "_" + hour + "." + min + fs;
method = Dialog.getChoice();
vesSize = Dialog.getString();
vesRoundness = Dialog.getString();
cellpose = Dialog.getCheckbox();
preprocess = Dialog.getCheckbox();
//Multichannel classification in development
//multichannel = Dialog.getCheckbox();
multichannel = false;
cellposeDir = Dialog.getString();
cellD = Dialog.getString();
cellProb = Dialog.getString();
flowTh = Dialog.getString();
customModel = Dialog.getCheckbox();
model = Dialog.getString();
refMode = Dialog.getCheckbox();
ntfyEnable = Dialog.getCheckbox();
ntfyCh = Dialog.getString();
if (ntfyCh != ntfyPref) {
    call("ij.Prefs.set", "ntfy.channel", ntfyCh);
}
benchmark = Dialog.getCheckbox();
extraChoice = Dialog.getChoice();

if (cellpose == false) {preprocess = false; benchmark = false; multichannel = false;}

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
			if (endsWith(toLowerCase(list[i]), ext)) {
				open(inputPath+list[i]);
				getDimensions(width, height, channels, slices, frames);
				for (j = 0; j < channels; j++) {
					channelList[j] = toString(j + 1);
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
		Dialog.addRadioButtonGroup("Pick the channel for cellpose segmentation:", channelList, 1, channels, "");
		if (channelList.length > 2) {
			Dialog.setInsets(15,0,15);
			Dialog.addRadioButtonGroup("Pick the channel for measurement:", channelList, 1, channels, "");
		}
		Dialog.show();
		
		refChannel = Dialog.getRadioButton();
		if (channelList.length == 2) {
			mesChannel = 3 - parseInt(refChannel);
		}
		
		//NEEDS MORE WORK - MEASURING MULTILE CHANNELS - CHECKBOX
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
	if (substring(getInfo("os.name"), 0, 3) == "Mac") {
		barL = "▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮";
		barR = "▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯";
	}
	else {
		barL = ">>>>>>>>>>>>>>>>>>>>>>>>>";
		barR = "=========================";
	}
	range = barL.length;
	p = progress/total*range;
	pp = p-range/total;
	
	for (i = 0; i <= p; i ++) {
		if (i >= pp) {
			print("\\Update" + index + ":" + "[" + substring(barL, 0, i) + substring(barR, i, range) + "] " + round(progress/total*100) + "%");
			wait(5);
		}
	}
}

function Processing(vesSize) { 
// Pre-processing image for measurements
	//Threshold and Binary convert
	run("Clear Results");
	print("\\Update" + index + ":Pre-processing...");
	index++;
	
	selectImage("Input");
	if (extraChoice == "Airyscan border removal"){
		run("Threshold...");
		setThreshold(100.0000, 1000000000000000000000000000000.0000);
	}
	else {
		//Use the second slice to set overall threshold - prevent bright fluorescent spot & high background near the top of the stack affecting threshold consistency
		setSlice(2);
		setAutoThreshold(method + " dark no-reset");
	}
	run("Convert to Mask", "background=Dark black");
	
	//Smooth edges
	run("Median...", "radius=4.0 stack");
	
	//Make duplicates
	run("Duplicate...", "title=Cells duplicate");
	run("Duplicate...", "title=Vesicles duplicate");
	close("Input");
	
	//Cell mask
	selectImage("Cells");
	run("Duplicate...", "title=Cellmask duplicate");
	run("Invert", "stack");
	run("Fill Holes", "stack");
	run("Invert", "stack");
	
	//Isolate Vesicle
	imageCalculator("Subtract create stack", "Vesicles","Cellmask");
	close("Vesicles");
	close("Cellmask");
	run("Watershed", "stack");
	run("Analyze Particles...", "size=" + vesSize + " circularity=" + vesRoundness + " show=Masks stack");
	close("Result of Vesicles");
	
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
	close("Vesicle_count");
	close("Vesicle_WS");
}

function Classification() {
	// Classfying cells based on intensity in the reference channel
	run("Clear Results");

	//select transfected channel
	selectImage("refChannel");
	run("Z Project...", "projection=[Max Intensity]");
	
	meanArray = newArray();
	for (i = 0; i < RoiManager.size; i++) {
		roiManager("select", i);
		run("Measure");
		meanArray[i] = getResult("Mean", i);
	}

	// Synthesise a 1-row image from the array
    newImage("tempOtsu", "32-bit", meanArray.length, 1, 1);
    for (i = 0; i < meanArray.length; i++) {
        setPixel(i, 0, meanArray[i]);
    }

	setAutoThreshold("Otsu dark no-reset");
    getThreshold(lower, upper);
	
	close("tempOtsu");
	close("MAX_refChannel");
	return lower;
}

function Measurement() { 
// Measure cell and vesicle volume
	cellVol = getResult("IntDen", 0) * vDepth;
	vesTotal = 0;
	vesVol = "";
	vesNum = 0;
	
	for (l = 1; l < nResults; l ++) {
		if (getResult("Max", l) > 1) {
			pixV = getResult("IntDen", l) * vDepth;
			
			//Measured volume
			vesVol = vesVol + pixV + ", ";
			//Calculate total
			vesTotal = vesTotal + pixV;
			//Number of vesicles
			vesNum ++;
		}
	}
	
	if (vesNum == 0) {
			vesVol = vesVol + 0 + ", ";
		}
	
	value = newArray(cellVol, vesTotal, vesVol, vesNum);
	return value;
}

function mask2ROI() { 
//Converting Cellpose mask to ROI @NickCondon
	run("Clear Results");
	run("Select All");
	getMinAndMax(lo, hi);
	getDimensions(imgW, imgH, bc, bs, bf);
	for (j = 1; j <= hi; j ++) {
		setThreshold(j, j);
		run("Create Selection");
		getSelectionBounds(bx, by, bw, bh);
		run("Measure");
		if (getResult("Area", nResults-1) > 10) {
			if (bx <= 0 || by <= 0 || bx + bw >= imgW || by + bh >= imgH) {
				outofbound++;
			}
			else {
				roiManager("Add");
			}
		}	
		resetThreshold();
	}
}

function Benchmarking() {
// Measure selected 2D sliced from the 3D stacks for benchmarking
	
	//Intercept 2D slices at 2nd, 40%, and 80% of the stack
	selectImage("Cells");
	sliceMid = round(nSlices*0.4);
//	sliceHigh = round(nSlices*0.8);
	run("Make Substack...", "slices=2," + sliceMid);// + "," + sliceHigh);
	rename("2D_Substacks_Cells");
	selectImage("Vesiclemask");
	run("Make Substack...", "slices=2," + sliceMid);// + "," + sliceHigh);
	rename("2D_Substacks_Vesicles");
	setThreshold(0.1, 1000000000000000000000000000000.0000);
	
	//Measurement
	for (n = 0; n < outputLabel.length; n++) {	
		//Output measurements
		benchresultsPath = benchPath + "Results_" + outputLabel[n] + "_" + year + "-" + (month+1) + "-" + day + "_" + hour + "." + min + ".csv";

		for (k = 0; k < RoiManager.size; k ++) {
			run("Clear Results");
			
			selectImage("2D_Substacks_Cells");
			setSlice(n+1);
			roiManager("select", k);
			run("Measure");
			selectImage("2D_Substacks_Vesicles");
			setSlice(n+1);
			roiManager("select", k);
			run("Analyze Particles...", "size=0-100 circularity=0.0-1.00 display");
						
			//Measure cell and vesicle volume
			cellArea = getResult("IntDen", 0);
			vesTotal = 0;
			vesArea = "";
			vesNum = 0;
		
			for (l = 1; l < nResults; l ++) {
				pixA = getResult("Area", l);
			
				//Measured volume
				vesArea = vesArea + pixA + ", ";
				//Calculate total
				vesTotal = vesTotal + pixA;
				//Number of vesicles
				vesNum ++;
			}
			
			if (vesNum == 0) {vesArea = vesArea + 0 + ", ";}

			if (vesNum == 0) {avgVes = 0;}
			else {avgVes = vesTotal / vesNum;}
			
			File.append(
				fileCount + "," + 
				inputName + "," + 
				RoiManager.size + "," + 
				fileCount + "_" + (k + 1) + "," + 
				cellArea + "," + 
				vesTotal + "," + 
				vesTotal / cellArea + "," + 
				vesNum + "," + 
				avgVes + "," + 
				vesArea, benchresultsPath);
		}
	}

	//Output the 2D slices
	run("Merge Channels...", "c1=2D_Substacks_Cells c2=2D_Substacks_Vesicles create ignore");
	saveAs("Tiff", benchPath + "2D_Summary_" + inputName + ".tif");
}

//----------------------------------------------------------------------------------------------------------------------------

for (i = 0; i < list.length; i++) {if (endsWith(toLowerCase(list[i]), ext)){totalCount++;}}
if (refMode == true) {File.makeDirectory(refPath);}

//Create Output File
resultsPath = outputPath + "Results_" + ver + "_" + year + "-" + (month+1) + "-" + day + "_" + hour + "." + min + ".csv";
File.saveString("File Number, File Name, Cell Count, Cell ID, Cell Volume, Total Vesicular Volume, Macropinocytic Index, Vesicle Count, Average Vesicle Size, Individual Vesicular Size\n", resultsPath);

//Create Output File for 2D benchmark mode
if (benchmark == true) {
	benchPath = outputPath + "2D_Analysis_" + ver + "_" + year + "-" + (month+1) + "-" + day + "_" + hour + "." + min + fs;
	File.makeDirectory(benchPath);
	
	outputLabel = newArray("low", "mid");//, "0.8");
	//Measurement
	for (n = 0; n < outputLabel.length; n++) {	
		//Output measurements
		benchresultsPath = benchPath + "Results_" + outputLabel[n] + "_" + year + "-" + (month+1) + "-" + day + "_" + hour + "." + min + ".csv";
		File.saveString("File Number, File Name, Cell Count, Cell ID, Cell Area, Total Vesicular Area, Macropinocytic Index, Vesicle Count, Average Vesicle Size, Individual Vesicular Size\n", benchresultsPath);
	}
}

for (i = 0; i < list.length; i++) {
	if (endsWith(toLowerCase(list[i]), ext)) {
		index = 11;
		outofbound = 0;
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
		inputName = File.getNameWithoutExtension(list[i]);
		
		//Supress Bio-Format Importer window
		if (ext == ".tif" || ext == ".tiff") {
			open(inputPath+list[i]);
		}
		else {
			run("Bio-Formats Windowless Importer", "open=[" + inputPath+list[i] + "]");
		}
		
		getDimensions(width, height, channels, slices, frames);
		
		if (slices == 1) {
    		showMessage("Error", "This image is not a volume image.");
    		exit();
		}
		
		//Dragonfly noise compensation
		if (extraChoice == "Dragonfly de-noise") {
			run("Duplicate...", "duplicate range=2-" + (slices-2));
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
		if (extraChoice == "Airyscan border removal") {
			if (multichannel == true) {
				selectImage("refChannel");
				makeRectangle(13, 13, width-26, height-26);
				run("Crop");
			}
			selectImage("Input");
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
				close("Segmentation");
				selectImage("AVG_Segmentation");
				rename("Segmentation");
			}
			
			//Cellpose Segmentation
			print("\\Update" + index + ":Cellpose Processing...");
			run("Cellpose ...", runParameter);

			//Cellpose to ROI (@ Nick)---
			selectWindow("Segmentation-cellpose");
			mask2ROI();
			
			//Exception and Output Headings
			if (RoiManager.size == 0) {
				print("\\Update" + index + ":No cell found, skipped to the next file.");
				skipped++;
				run("Close All");
				continue;
			}
			else {
				print("\\Update" + index + ":Cellpose Processing... " + RoiManager.size + " cell(s) found.");
				if (outofbound != 0) {
					index++;
					print("\\Update" + index + ":" + outofbound + " out of bound cell(s) removed.");
				}
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
				cutoff = Classification();
				
				//DO SOMETHING//
				
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
				run("Analyze Particles...", "size=0-100 circularity=0.0-1.00 display");
				
				//Measure cell and vesicle volume
				measurement = Measurement();
				cellVol = measurement[0];
				vesTotal = measurement[1];
				vesVol = measurement[2];
				vesNum = measurement[3];
				if (vesNum == 0) {avgVes = 0;}
				else {avgVes = vesTotal / vesNum;}
				
				//Output file
				File.append(
					fileCount + "," + 
					inputName + "," + 
					RoiManager.size + "," + 
					fileCount + "_" + (k + 1) + "," + 
					cellVol + "," + 
					vesTotal + "," + 
					vesTotal / cellVol + "," + 
					vesNum + "," + 
					avgVes + "," + 
					vesVol, resultsPath);
			}
			
			//2D Benchmark
			if (benchmark == true) {
				index = index + 2;
				print("\\Update" + index + ":2D Benchmarking...");
				Benchmarking();
			}
			index++;
		}
		
		else {
			//Measurments
			selectImage("SUM_Cells");
			run("Measure");
			selectImage("Result of Vesicle_count");
			run("Analyze Particles...", "size=0-100 circularity=0.0-1.00 display");
			
			//Measure cell and vesicle volume
			measurement = Measurement();
			cellVol = measurement[0];
			vesTotal = measurement[1];
			vesVol = measurement[2];
			vesNum = measurement[3];
			if (vesNum == 0) {avgVes = 0;}
			else {avgVes = vesTotal / vesNum;}
			
			//Output file
			File.append( 
				fileCount + "," + 
				inputName + ",,," + 
				cellVol + "," + 
				vesTotal + "," + 
				vesTotal / cellVol + "," + 
				vesNum + "," + 
				avgVes + "," + 
				vesVol, resultsPath);
		}
		index++;

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
			
			saveAs("Tiff", refPath + "Summary_" + inputName + " " + year + "-" + (month+1) + "-" + day + "_" + hour + "." + min + ".tif");
		}
		print("\\Update" + index + ":Writing Outputs...");
		
		indf = index;
		
		//Clean up after each entry
		run("Close All");
	}
}

//Display runtime to log window
run("Clear Results");
run("Collect Garbage");
print("=============================================================");
print("Batch Completed.");
print("Threshold method: " + method);
print("Number of file(s) skipped: " + skipped);
timer = round((getTime()-startTime)/1000);
print("Total Runtime was: " + floor(timer/60) + " min " + timer%60 + " s.");
print("Results saved to " + outputPath);
if (refMode == true) {
	print("Reference images saved to " + refPath);
	selectWindow("Log");
	saveAs("Text", refPath + "Log.txt");
}
print("\n");

//Exit message
exitTitle = "Batch Completed";
exitMsg = "Put down that iced oat latte! Your analysis is finished";
if (ntfyEnable == true) {exec("curl", "-s", "-o", "/dev/null", "-H", "Title: Fiji Macro Completed", "-H", "Priority: default", "-d", "Put down that iced oat latte! Your analysis is finished", ntfyCh);}
waitForUser(exitTitle, exitMsg);

/*Dev note:
 * Classification unfinished */