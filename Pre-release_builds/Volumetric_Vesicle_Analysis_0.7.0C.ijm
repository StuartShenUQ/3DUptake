setBatchMode(true);
//setOption("ExpandableArrays", true);

run("Clear Results");
//run("Collect Garbage");
roiManager("reset");
print("\\Clear")

getDateAndTime(year, month, week, day, hour, min, sec, msec);
startTime = getTime();
methodList = getList("threshold.methods");
extras = newArray("---", "Airyscan border removal", "De-noise");
fileCount = 0;
totalCount = 0;
concatMes = "";
concatEst = "";
fs = File.separator;
run("Set Measurements...", "area mean min integrated redirect=None decimal=3");

//Set cellpose environment directory
cellposeDir = "";
if (substring(getInfo("os.name"), 0, 1) == "M") {cellposeDir = "/opt/anaconda3/envs/Cellpose";}
if (substring(getInfo("os.name"), 0, 1) == "W") {cellposeDir = "C:\\Users\\Public\\Documents\\Anaconda_MU\\envs\\cellpose";} //C:\\Users\\uqshongy\\.conda\\envs\\cellpose

print("Volumetric Analysis of endosomal vesicles using inverse fluorescent imaging");
print("Scripted by Hongyu (Stuart) Shen with help of Dr. Nicholas Condon");
print("as part of a PhD project in Jennifer L. Stow's Lab");
print("Institute for Molecular Bioscience");
print("The University of Queensland\n");
print("Version 0.6.3C (cellpose)");
print("Cellpose version 2, Model: cyto2");
print("Dependencies: Conda environemnt and Cellpose installed");
print("Script Run Date: " + day + "/" + (month+1) + "/" + year + "  Time: " + hour + ":" + min + ":" + sec + "\n");
print("=============================================================\n");

//Create dialog to get input/output directory
Dialog.create("Setup");
	Dialog.setInsets(10,0,0);
	Dialog.addString("File Extension:", ".tif");
	Dialog.setInsets(0,170,10);
 	Dialog.addMessage("(For example .czi  .lsm  .nd2  .lif  .ims)");
	Dialog.addDirectory("Choose the input folder:", "");
	Dialog.addChoice("Choose Threshold method", methodList, "");
	Dialog.addMessage("Confocal - Huang | Airyscan/DragonFly - Default");
	Dialog.addString("Vesicle Size:", "0.5-10");
	Dialog.addCheckbox("Cellpose - not working", true);
	Dialog.addDirectory("Choose the cellpose environment directory:", cellposeDir);
	Dialog.addMessage("Default directory: *Anaconda installation folder*" + fs + "envs" + fs + "cellpose");
	Dialog.addCheckbox("Reference files", true);
	Dialog.addCheckbox("De-noise", true);
	//	Dialog.addRadioButtonGroup("Extras", extras, 1, extras.length, "");
	Dialog.addChoice("Extras", extras);
Dialog.show();

ext = Dialog.getString();
inputPath = Dialog.getString();
refPath = inputPath + "References" + fs;
method = Dialog.getChoice();
vesSize = Dialog.getString();
cellpose = Dialog.getCheckbox();
cellposeDir = Dialog.getString();
refMode = Dialog.getCheckbox();
deNoise = Dialog.getCheckbox();
//extrasChoice = Dialog.getRadioButton();
extrasChoice = Dialog.getChoice();

//Define Cellpose directory
if (cellpose == true) {
	while (File.isDirectory(cellposeDir) == 0) {
		Dialog.create("Error");
			Dialog.addMessage("Cellpose directory not found...");
			Dialog.addDirectory("Choose the cellpose environment directory:", cellposeDir);
		Dialog.show();
		cellposeDir = Dialog.getString();
	}
	run("Cellpose setup...", "cellposeenvdirectory=" + cellposeDir + " envtype=conda usegpu=true usemxnet=false usefastmode=false useresample=false version=2.0");
}

function progressBar(a, b) {
	bar = "";
/*	barL = "▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮";
	barR = "▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯▯";*/
	barL = ">>>>>>>>>>>>>>>>>>>>>>>>>";
	barR = "=========================";
	range = barL.length;
	p = a/b*range;
	pp = (a-1)/b*range;
	
	for (i = 0; i <= p; i ++) {
		if (i > pp) {
			print("\\Update:" + "[" + substring(barL, 0, i) + substring(barR, i, range) + "] " + round(a/b*100) + "%");
			wait(20);
		}
	}
}

list = getFileList(inputPath);
for (i = 0; i < list.length; i++) {if (endsWith(list[i], ext)){totalCount = totalCount + 1;}}
if (refMode == true) {File.makeDirectory(refPath);}

//Create Output File
Results = File.open(inputPath + "Results_" + year + "-" + (month+1) + "-" + day + "_" + hour + "." + min + ".csv");
print(Results, "File Number, File Name, Cell Count, Cell ID, Cell Volume, Total Vesicular Volume, Vesicle Count, Individual Vesicular Size");

for (i = 0; i < list.length; i++) {
	if (endsWith(list[i], ext)) {
		fileCount = fileCount + 1;
		print("Processing Image " + fileCount + "/" + totalCount + "\n");
		progressBar(fileCount, totalCount);	
		print("");
		run("Clear Results");
		roiManager("reset");
		showProgress(i + 1, totalCount);
		open(inputPath+list[i]);
		getVoxelSize(width, height, depth, unit);

		//Airyscan remove border
		if (extrasChoice == "Airyscan border removal"){
			getDimensions(width, height, channels, slices, frames);
			makeRectangle(13, 13, width-26, height-26);
			run("Crop");
		}

		//Cellpose initiation
		rename("Input");
		run("Duplicate...", "title=Segmentation duplicate");
		
		//Pre-processing
		run("Sharpen", "stack");
		run("Z Project...", "projection=[Average Intensity]");
		run("Invert");
		
		//Cellpose Segmentation
		print("Cellpose Processing...");
		run("Cellpose Advanced", "diameter=250 cellproba_threshold=-4.0 flow_threshold=0.6 anisotropy=1.0 diam_threshold=12.0 model=cyto2 nuclei_channel=0 cyto_channel=1 dimensionmode=2D stitch_threshold=-1.0 omni=false cluster=false additional_flags=");

		//Cellpose to ROI (@ Nick)
		selectWindow("AVG_Segmentation-cellpose");
		run("Select All");
		getMinAndMax(min, max);
		for (j = 1; j < = max; j ++) {
			setThreshold(j, j);
			run("Create Selection");
			run("Measure");
			if (getResult("Area", j - 1) > 5) {roiManager("Add");}
			resetThreshold();
		}
		
		//Output Headings
		print(RoiManager.size + " cells found\n");
		print(Results, fileCount + "," + File.getNameWithoutExtension(list[i]) + "," + RoiManager.size);
		
		//Threshold and Binary convert
		run("Clear Results");
		selectImage("Input");
		if (extrasChoice == "Airyscan border removal"){
			run("Threshold...");
			setThreshold(100.0000, 1000000000000000000000000000000.0000);
		}
		else{
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
		run("Duplicate...", "title=CellsWS duplicate");
		run("Watershed", "stack");
		run("Invert", "stack");
		run("Fill Holes", "stack");
		run("Invert", "stack");
		
		//Isolate Vesicle
		imageCalculator("Subtract create stack", "Vesicles","CellsWS");
		run("Analyze Particles...", "size=" + vesSize + " circularity=0.8-1.00 show=Masks stack");
		
		//Prepare Volumetric Measurement Images
		selectImage("Cells");
		run("Invert", "stack");
		run("Subtract...", "value=254 stack");
		run("Z Project...", "projection=[Sum Slices]");
		
		selectImage("Mask of Result of Vesicles");
		rename("Vesicles");
		run("Subtract...", "value=254 stack");
		run("Z Project...", "projection=[Sum Slices]");
		
		run("Duplicate...", "title=Vesicle_count duplicate");
		setThreshold(0.1, 1000000000000000000000000000000.0000);
		
		//Measurements with Clipping Masks
		print("Measuring...\n");
		for (k = 0; k < RoiManager.size; k ++) {
			progressBar(k + 1, RoiManager.size);
			run("Clear Results");
			
			//Measurments
			selectImage("SUM_Cells");
			roiManager("select", k);
			run("Measure");
			selectImage("SUM_Vesicles");
			roiManager("select", k);
			run("Measure");
			selectImage("Vesicle_count");
			roiManager("select", k);
			run("Analyze Particles...", "size=0-50 circularity=0.0-1.00 show=Masks display stack");

			cellVol = getResult("IntDen", 0) * depth;
			veslVol = getResult("IntDen", 1) * depth;
			mesVol = "";
			estVol = "";
			numVes = 0;
			
			for (l = 2; l < nResults; l ++) {
				//De-noise
				if (deNoise == true) {
					if (getResult("Max", l) > 1) {
						pixA = getResult("Area", l);
						pixR = sqrt(pixA/PI);
						pixV = getResult("IntDen", l);
						
						//Estimated volume based on area
						estVol = estVol + (4/3 * PI * pow(pixR,3)) + ", ";
						
						//Measured volume
						mesVol = mesVol + pixV * depth + ", ";
						
						//Number of vesicles
						numVes = numVes + 1;
					}
				}
			}
			
			//Concatenated array of individual volume for statistics
			if (nResults > 2) {
				concatMes = concatMes + mesVol;
				concatEst = concatEst + estVol;
				}
			
			//Output file
			print(Results, ",,," + fileCount + "_" + k + 1 + "," + cellVol + "," + veslVol + "," + numVes + "," + mesVol);
		}
		//Concatenate files for reference
		if (refMode == true) {
			print("Writing Referencing Files");
			run("Merge Channels...", "c1=SUM_Cells c2=[SUM_Vesicles] c3=AVG_Segmentation-cellpose create ignore");
			run("From ROI Manager");
			saveAs("Tiff", refPath + "Summary_" + File.getNameWithoutExtension(list[i]) + year + "-" + (month+1) + "-" + day + "_" + hour + "." + min + ".tif");
		}
		print("\nWriting Outputs...\n");
		if (fileCount < totalCount) {
			print("=============================\n");
		}
	}
	run("Close All");
}

print(Results, "Concatenated Measured Volume: ," + concatMes);
print(Results, "Concatenated Estimated Volume: ," + concatEst);

//Display runtime to log window
run("Clear Results");
run("Collect Garbage");
print("=============================================================\n");
print("Batch Completed");
print("Threshold method: " + method);
print("Total Runtime was: " + (getTime()-startTime)/1000 + " sec.");
print("Results saved to " + inputPath);
if (refMode == true) {print("Reference images saved to " + refPath);}
print("\n");

//Exit message
exitTitle = "Batch Completed";
exitMsg = "Put down that iced oat latte! Your analysis is finished";
waitForUser(exitTitle, exitMsg);