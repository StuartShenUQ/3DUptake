//setBatchMode(true);

run("Clear Results");
roiManager("reset");
print("\\Clear")

getDateAndTime(year, month, week, day, hour, min, sec, msec);
startTime = getTime();
methodList = getList("threshold.methods");
extras = newArray("Airyscan border removal", "DragonFly de-noise");
fileCount = 0;
totalCount = 0;
fs = File.separator;
run("Set Measurements...", "area mean min integrated redirect=None decimal=3");

print("Volumetric Analysis for inverse fluorescent imaging");
print("Scripted by Hongyu (Stuart) Shen as a project for PhD project");
print("in Jennifer L. Stow's Lab at Institute for Molecular Bioscience");
print("The University of Queensland");
print("Version 0.4.5C");
print("Cellpose version 2, Model: cyto2");
print("Script Run Date: " + day + "/" + (month+1) + "/" + year + "  Time: " + hour + ":" + min + ":" + sec);
print("");

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
	Dialog.addRadioButtonGroup("Extras", extras, 1, extras.length, "");
	Dialog.addCheckbox("Reference files", false);
Dialog.show();

ext = Dialog.getString();
inputPath = Dialog.getString();
refPath = inputPath + "References" + fs;
method = Dialog.getChoice();
vesSize = Dialog.getString();
extrasChoice = Dialog.getRadioButton();
refMode = Dialog.getCheckbox();
//setBatchMode(Dialog.getCheckbox());

function progressBar(a, b) {
	bar = "";
	p = a/b*20;	
	for (i = 0; i < 20; i++){
		if (p >= 1) {
			bar = bar + ">";
			p = p - 1;
		}
		else {
			bar = bar + "=";
		}
	}
	print(bar);
}

list = getFileList(inputPath);
for (i = 0; i < list.length; i++) {if (endsWith(list[i], ext)){totalCount = totalCount + 1;}}
if (refMode == true) {File.makeDirectory(refPath);}

//Create Output File
Results = File.open(inputPath + "Results_" + year + "-" + (month+1) + "-" + day + "_" + hour + "." + min + ".csv");
print(Results, "File Number, File Name, Cell Count, Cell Number, Cell Volume, Total Vesicular Volume, Vesicle Count, Individual Vesicular Size");

for (i = 0; i < list.length; i++) {
	if (endsWith(list[i], ext)){
		fileCount = fileCount + 1;
		print("Processing Image " + fileCount + "/" + totalCount);
		progressBar(fileCount, totalCount);	
		print("");
		run("Clear Results");
		roiManager("reset");
		showProgress(i+1, totalCount);
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

		//Cellpose to ROI (@Nick)
		run("Measure");
		nBins = getResult("Max",0);
  			run("Clear Results");
			getHistogram(values, counts, nBins);
  			for (l = 1; l < nBins; l++) {
     			if (counts[l] > 0){
     				selectWindow("AVG_Segmentation-cellpose");
     				run("Duplicate...", " ");
					setThreshold(l, l);
					setOption("BlackBackground", true);
					run("Convert to Mask");
					run("Create Selection");
					roiManager("Add");
					close();
     			}   
			}
		
		//Output Heading
		print(RoiManager.size + " cells found");
		print("");
		print(Results, fileCount + "," + File.getNameWithoutExtension(list[i]) + "," + RoiManager.size);
		
		//Threshold and Binary convert
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
		run("Duplicate...", "title=CellsInv duplicate");
		run("Invert", "stack");
		run("Fill Holes", "stack");
		run("Invert", "stack");
		
		//Isolate Vesicle
		imageCalculator("Subtract create stack", "Vesicles","CellsInv");
		run("Analyze Particles...", "size=" + vesSize + " circularity=0.9-1.00 show=Masks stack");
		
		//Prepare Volumetric Measurement Images
		selectImage("Cells");
		run("Invert", "stack");
		run("Subtract...", "value=254 stack");
		run("Z Project...", "projection=[Sum Slices]");
		
		selectImage("Mask of Result of Vesicles");
		rename("Vesicles");
		run("Subtract...", "value=254 stack");
		run("Z Project...", "projection=[Sum Slices]");
		
		//DragonFly de-noise
		if (extrasChoice == "DragonFly de-noise"){
			run("Subtract...", "value=2");
			run("Min...", "value=0");
		}

		run("Duplicate...", "title=Vesicle_count duplicate");
		setThreshold(0.1, 1000000000000000000000000000000.0000);
		
		//Measurements with Clipping Masks
		print("Measuring...");
		for (j = 0; j < RoiManager.size; j++) {
			progressBar(j+1, RoiManager.size);
			run("Clear Results");
			
			//Measurments
			selectImage("SUM_Cells");
			roiManager("select", j);
			run("Measure");
			selectImage("SUM_Vesicles");
			roiManager("select", j);
			run("Measure");
			selectImage("Vesicle_count");
			roiManager("select", j);
			run("Analyze Particles...", "size=0-50 circularity=0.0-1.00 show=Masks display stack");
			
			cellVol = getResult("IntDen", 0) * depth;
			veslVol = getResult("IntDen", 1) * depth;
			indVol = "";
			numVes = 0;
			
			for (n = 2; n < nResults; n++) {
				if (extrasChoice == "DragonFly de-noise") {indVol = indVol + (getResult("IntDen", n) + 2) * depth + ", ";}
				else {indVol = indVol + getResult("IntDen", n) * depth + ", ";}
				numVes = n-1;
			}

			//Output file
			print(Results, ",,," + j+1 + "," + cellVol + "," + veslVol + "," + numVes + "," + indVol);
		}
		
		//Concatenate files for reference
		if (refMode == true) {
			print("Writing Referencing Files");
			run("Merge Channels...", "c1=SUM_Cells c2=[SUM_Vesicles] c3=AVG_Segmentation-cellpose create ignore");
			run("From ROI Manager");
			saveAs("Tiff", refPath + "Summary_" + File.getNameWithoutExtension(list[i]) + ".tif");
		}
		print("");
		print("Writing Outputs...");
		print("");
	}
	run("Close All");
}

//Display runtime to log window
run("Clear Results");
print("Batch Completed");
print("Threshold method: " + method);
print("Total Runtime was: " + (getTime()-startTime)/1000 + " sec.");
print("Results saved to " + inputPath);
if (refMode == true) {print("Reference images saved to " + refPath);}
print("");

//Exit message
exitTitle = "Batch Completed";
exitMsg = "Put down that coffee! Your analysis is finished";
waitForUser(exitTitle, exitMsg); 
