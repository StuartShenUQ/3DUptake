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
print("Version 0.4.3C");
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
		run("Clear Results");
		
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
		
		//Analyse with Clipping Masks
		for (j = 0; j < RoiManager.size; j++) {
			run("Clear Results");
			
			//Make duplicates
			roiManager("select", j);
			run("Duplicate...", "title=Cells duplicate");
			run("Clear Outside", "stack");
			run("Duplicate...", "title=Vesicle duplicate");
			
			//Cell mask
			selectImage("Cells");
			run("Duplicate...", "title=CellsInv duplicate");
			run("Invert", "stack");
			run("Fill Holes", "stack");
			run("Invert", "stack");
			
			//Isolate Vesicle
			imageCalculator("Subtract create stack", "Vesicle","CellsInv");
			run("Analyze Particles...", "size=" + vesSize + " circularity=0.9-1.00 show=Masks stack");
			
			//Create Volumetric Measurements
			selectImage("Cells");
			run("Invert", "stack");
			run("Subtract...", "value=254 stack");
			run("Z Project...", "projection=[Sum Slices]");
			run("Measure");
			
			selectImage("Mask of Result of Vesicle");
			run("Subtract...", "value=254 stack");
			run("Z Project...", "projection=[Sum Slices]");
			
			//DragonFly de-noise
			if (extrasChoice == "DragonFly de-noise"){
				run("Subtract...", "value=2");
				run("Min...", "value=0");
			}
			
			run("Measure");
			run("Duplicate...", "title=Vesiclecount duplicate");
			setThreshold(0.1, 1000000000000000000000000000000.0000);
			run("Analyze Particles...", "size=0-50 circularity=0.0-1.00 show=Masks display stack");

			//Measurments
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

			selectImage("Input");
			close("\\Others");
		}
	}
		
/*		//Concatenate files for reference
		if (refMode == true) {
			refDir = refPath + File.getNameWithoutExtension(list[i]) + fs;
			File.makeDirectory(refDir);
			run("Merge Channels...", "c1=Cells c2=[Mask of Result of Vesicle] create ignore");
			saveAs("Tiff", refDir + "Mask.tif");
			run("Merge Channels...", "c1=SUM_Cells c2=[SUM_Mask of Result of Vesicle] create ignore");
			saveAs("Tiff", refDir + "SUM.tif");
		}
*/

	run("Close All");
}

//Display runtime to log window
run("Clear Results");
print("");
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
