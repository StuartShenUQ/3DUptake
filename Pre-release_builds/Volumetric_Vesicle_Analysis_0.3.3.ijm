setBatchMode(true);

run("Clear Results");

getDateAndTime(year, month, week, day, hour, min, sec, msec);
startTime = getTime();
methodList = getList("threshold.methods");
microscope = newArray("Confocal 4 (Airyscan)", "DragonFly");
count = 0;
fs = File.separator;

print("Script Run Date: " + day + "/" + (month+1) + "/" + year + "  Time: " + hour + ":" + min + ":" + sec);

//Create dialog to get inout/output directory
Dialog.create("Setup");
	Dialog.setInsets(10,0,0);
	Dialog.addString("File Extension:", ".tif");
	Dialog.setInsets(0,170,10);
 	Dialog.addMessage("(For example .czi  .lsm  .nd2  .lif  .ims)");
	Dialog.addDirectory("Choose the input folder:", "");
	Dialog.addChoice("Choose Threshold method", methodList, "");
	Dialog.addMessage("Confocal - Huang | Airyscan/DragonFly - Default");
	Dialog.addString("MPS Size:", "");
	Dialog.addRadioButtonGroup("Microscope", microscope, 1, microscope.length, "");
	Dialog.addCheckbox("Reference files", false);
Dialog.show();

ext = Dialog.getString();
inputPath = Dialog.getString();
refPath = inputPath + "References" + fs;
method = Dialog.getChoice();
mpsSize = Dialog.getString();
scopeChoice = Dialog.getRadioButton();
refChoice = Dialog.getCheckbox();
//setBatchMode(Dialog.getCheckbox());

list = getFileList(inputPath);
if (refChoice == true) {File.makeDirectory(refPath);}
Results = File.open(inputPath + "Results_" + year + "-" + (month+1) + "-" + day + "_" + hour + "." + min + ".csv");
print(Results, "#,File name,Total cell volume,Total vesicular volume,Number of vesicles,Volume of individual vesicles");

for (i = 0; i < list.length; i++) {
	if (endsWith(list[i], ext)){
		count = count + 1;
		print("Processing Image " + count + "/" + list.length);
		run("Clear Results");
		showProgress(i+1, list.length);
		open(inputPath+list[i]);
		
		//Threshold and Binary convert
		
		//CF4 Airyscan remove border
		if (scopeChoice == "Confocal 4 (Airyscan)"){
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
		cellVol = getResult("IntDen", 0);
		mpslVol = getResult("IntDen", 1);
		indVol = "";
		numVes = 0;
		for (n = 2; n < nResults; n++) {
			indVol = indVol + getResult("IntDen", n) + ", ";
			numVes = n-1;
		}

		//Output file
		print(Results, count + "," + File.getNameWithoutExtension(list[i]) + "," + cellVol + "," + mpslVol + "," + numVes + "," + indVol);
		
		//Concatenate files for reference
		if (refChoice == true) {
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
if (refChoice == true) {print("Reference images saved to " + refPath);}
print("");

//Exit message
exitTitle = "Batch Completed";
exitMsg = "Put down that coffee! Your analysis is finished";
waitForUser(exitTitle, exitMsg); 
