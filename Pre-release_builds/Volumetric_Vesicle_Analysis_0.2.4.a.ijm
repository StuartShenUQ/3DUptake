setBatchMode(true);

run("Clear Results");

getDateAndTime(year, month, week, day, hour, min, sec, msec);
startTime = getTime();
methodList = getList("threshold.methods");
count = 0;
fs = File.separator;

print("Script Run Date: " + day + fs + (month+1) + fs + year + "  Time: " + hour + ":" + min + ":" + sec);

//Create dialog to get inout/output directory
Dialog.create("Setup");
	Dialog.setInsets(10,0,0);
	Dialog.addString("File Extension:", ".tif");
	Dialog.setInsets(0,170,10);
 	Dialog.addMessage("(For example .czi  .lsm  .nd2  .lif  .ims)");
	Dialog.addDirectory("Choose the input folder:", "");
	Dialog.addChoice("Choose Threshold method", methodList, "Huang");
	Dialog.addCheckbox("Airyscan CF4", false);
	//Dialog.addCheckbox("Batch mode", true);
Dialog.show();

ext = Dialog.getString();
inputPath = Dialog.getString();
outputPath = inputPath + "References" + fs;
method = Dialog.getChoice();
cf4 = Dialog.getCheckbox();
//setBatchMode(Dialog.getCheckbox());

list = getFileList(inputPath);
File.makeDirectory(outputPath);
Results = File.open(inputPath + "Results_" + year + "-" + (month+1) + "-" + day + "_" + hour + "." + min + ".csv");

//Statistics
print(Results, "Statistics");
print(Results, "Average MPS Volume,Average MPS / Cytoplasm Volume");
print(Results, "=AVERAGE(SUM(D6:D1000)/SUM(E6:E1000)),=AVERAGE(SUM(D6:D1000)/SUM(C6:C1000))");
print(Results, "");
print(Results, "#,File name,Total cytoplasmic volume,Total vesicular volume,Number of vesicles,Volume of individual vesicles");

for (i = 0; i < list.length; i++) {
	if (endsWith(list[i], ext)){
		count = count + 1;
		run("Clear Results");
		showProgress(i+1, list.length);
		open(inputPath+list[i]);
		if (cf4 == 1){
			makeRectangle(20, 20, 1530, 1530);
			run("Crop");
		}

		//Threshold and Binary convert
		setAutoThreshold(method + " dark no-reset");
		run("Convert to Mask", "method=" + method +" black");
		
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
		run("Analyze Particles...", "size=0.5-50 circularity=0.8-1.00 show=Masks stack");
		
		//Volumetric Measurements
		selectImage("Cells");
		run("Subtract...", "value=254 stack");
		run("Z Project...", "projection=[Sum Slices]");
		run("Measure");
		
		selectImage("Mask of Result of MPS");
		run("Subtract...", "value=254 stack");
		run("Z Project...", "projection=[Sum Slices]");
		run("Measure");
		run("Duplicate...", "title=MPScount duplicate");
		setAutoThreshold("Huang dark no-reset");
		run("Analyze Particles...", "size=0.5-50 circularity=0.8-1.00 show=Masks display stack");
		
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
		refDir = outputPath + list[i] + fs;
		File.makeDirectory(refDir);
		run("Merge Channels...", "c1=Cells c2=[Mask of Result of MPS] create ignore");
		saveAs("Tiff", refDir + "Mask.tif");
		run("Merge Channels...", "c1=SUM_Cells c2=[SUM_Mask of Result of MPS] create ignore");
		saveAs("Tiff", refDir + "SUM.tif");
		run("Close All");
	}
}

//Prints runtime to log window
run("Clear Results");
print("");
print("Batch Completed.");
print("Total Runtime was:" + (getTime()-startTime)/1000 + " sec.");
print("Results saved to " + inputPath);
print("Reference images saved to " + outputPath);
print("");

//Exit message
exitTitle = "Batch Completed";
exitMsg = "Put down that coffee! Your analysis is finished";
waitForUser(exitTitle, exitMsg); 

















