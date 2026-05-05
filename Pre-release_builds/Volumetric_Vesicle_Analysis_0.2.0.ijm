setBatchMode(true);

run("Clear Results");

getDateAndTime(year, month, week, day, hour, min, sec, msec);
startTime = getTime();
methodList = getList("threshold.methods");

print("Script Run Date: " + day + "/" + (month+1) + "/" + year + "  Time: " + hour + ":" + min + ":" + sec);

//Create dialog to get inout/output directory
Dialog.create("Setup");
	Dialog.setInsets(10,0,0);
	Dialog.addString("File Extension:", ".tif");
	Dialog.setInsets(0,170,10);
 	Dialog.addMessage("(For example .czi  .lsm  .nd2  .lif  .ims)");
	Dialog.addDirectory("Choose the input folder:", "");
	Dialog.addChoice("Choose Threshold method", methodList, "Huang");
Dialog.show();

ext = Dialog.getString();
inputPath = Dialog.getString();
outputPath = inputPath + "References/";
method = Dialog.getChoice();
list = getFileList(inputPath);
File.makeDirectory(outputPath);
Results = File.open(inputPath + "Results_" + year + "-" + (month+1) + "-" + day + "_at_" + hour + "." + min + ".csv");
print(Results, "#, File name, Total cytoplasmic volume, Total vesicular volume, Number of vesicles, Volume of individual vesicles");

for (i = 0; i < list.length; i++) {
	if (endsWith(list[i], ext)){
		run("Clear Results");
		showProgress(i+1, list.length);
		open(inputPath+list[i]);

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
		
		//Create Volumetric Measurements
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
		print(Results, i + ", File Name ," + cellVol + "," + mpslVol + "," + numVes + "," + indVol);
		
		
		//Concatenate files for reference
		refDir = outputPath + list[i] + "/";
		File.makeDirectory(refDir);
		run("Merge Channels...", "c1=Cells c2=[Mask of Result of MPS] create ignore");
		saveAs("Tiff", refDir + "Mask.tif");
		run("Merge Channels...", "c1=SUM_Cells c2=[SUM_Mask of Result of MPS] create ignore");
		saveAs("Tiff", refDir + "SUM.tif");
		run("Close All");
	}
}

//Statistic
//print(Results, "=D2/C2");

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

















