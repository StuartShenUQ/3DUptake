setBatchMode(true);

run("Clear Results");

getDateAndTime(year, month, week, day, hour, min, sec, msec);
startTime = getTime();
methodList = getList("threshold.methods");
microscope = newArray("Confocal 4 (Airyscan)", "DragonFly");
fileCount = 0;
totalCount = 0;
fs = File.separator;
run("Set Measurements...", "area mean min integrated redirect=None decimal=3");

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
	Dialog.addString("MPS Size:", "0.5-10");
	Dialog.addRadioButtonGroup("Microscope", microscope, 1, microscope.length, "");
	Dialog.addCheckbox("Reference files", false);
Dialog.show();

ext = Dialog.getString();
inputPath = Dialog.getString();
refPath = inputPath + "References" + fs;
method = Dialog.getChoice();
mpsSize = Dialog.getString();
scopeChoice = Dialog.getRadioButton();
refMode = Dialog.getCheckbox();
//setBatchMode(Dialog.getCheckbox());

list = getFileList(inputPath);
for (i = 0; i < list.length; i++) {if (endsWith(list[i], ext)){totalCount = totalCount + 1;}}
if (refMode == true) {File.makeDirectory(refPath);}
Results = File.open(inputPath + "Results_" + year + "-" + (month+1) + "-" + day + "_" + hour + "." + min + ".csv");
print(Results, "#,File name,Total cell volume,Total vesicular volume,Number of vesicles,Volume of individual vesicles");

for (i = 0; i < list.length; i++) {
	if (endsWith(list[i], ext)){
		fileCount = fileCount + 1;
		print("Processing Image " + fileCount + "/" + totalCount);
		run("Clear Results");
		showProgress(i+1, totalCount);
		open(inputPath+list[i]);
		
		//Threshold and Binary convert
		
		//Airyscan remove border
		if (scopeChoice == "Airyscan"){
			getDimensions(width, height, channels, slices, frames);
			makeRectangle(13, 13, width-26, height-26);
			run("Crop");
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
		run("Duplicate...", "title=MPS duplicate");
		
		//Cell mask
		selectImage("Cells");
		run("Duplicate...", "title=CellsInv duplicate");
		run("Invert", "stack");
		run("Fill Holes", "stack");
		run("Invert", "stack");
		
		//Isolate MPS
		imageCalculator("Subtract create stack", "MPS","CellsInv");
		run("Analyze Particles...", "size=" + mpsSize + " circularity=0.9-1.00 show=Masks stack");
		
		//Create Volumetric Measurements
		selectImage("Cells");
		run("Invert", "stack");
		run("Subtract...", "value=254 stack");
		run("Z Project...", "projection=[Sum Slices]");
		run("Measure");
		
		selectImage("Mask of Result of MPS");
		run("Subtract...", "value=254 stack");
		run("Z Project...", "projection=[Sum Slices]");
		
		//DragonFly remove noise
		if (scopeChoice == "DragonFly"){
			run("Subtract...", "value=2");
			run("Min...", "value=0");
		}
		
		run("Measure");
		run("Duplicate...", "title=MPScount duplicate");
		run("Threshold...");
		setThreshold(0.1, 1000000000000000000000000000000.0000);
		run("Analyze Particles...", "size=0-50 circularity=0.0-1.00 show=Masks display stack");
		
		//Measurments
		getVoxelSize(width, height, depth, unit);
		cellVol = getResult("IntDen", 0) * depth;
		mpslVol = getResult("IntDen", 1) * depth;
		indVol = "";
		numVes = 0;
		for (n = 2; n < nResults; n++) {
			if (scopeChoice == "DragonFly") {indVol = indVol + (getResult("IntDen", n) + 2) * depth + ", ";}
			else {indVol = indVol + getResult("IntDen", n) * depth + ", ";}
			numVes = n-1;
		}

		//Output file
		print(Results, fileCount + "," + File.getNameWithoutExtension(list[i]) + "," + cellVol-mpslVol + "," + mpslVol + "," + numVes + "," + indVol);
		
		//Concatenate files for reference
		if (refMode == true) {
			refDir = refPath + File.getNameWithoutExtension(list[i]) + fs;
			File.makeDirectory(refDir);
			run("Merge Channels...", "c1=Cells c2=[Mask of Result of MPS] create ignore");
			saveAs("Tiff", refDir + "Mask.tif");
			run("Merge Channels...", "c1=SUM_Cells c2=[SUM_Mask of Result of MPS] create ignore");
			saveAs("Tiff", refDir + "SUM.tif");
		}
	
	run("Close All");
	}
}

//Prints runtime to log window
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
