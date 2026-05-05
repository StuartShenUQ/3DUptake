setBatchMode(true);
getDateAndTime(year, month, week, day, hour, min, sec, msec);
startTime = getTime();
methodList = getList("threshold.methods");

print("Script Run Date: "+day+"/"+(month+1)+"/"+year+"  Time: " +hour+":"+min+":"+sec);

//Create dialog to get inout/output directory
Dialog.create("Setup");
//	Dialog.setInsets(20,0,20);
	Dialog.addString("File Extension:", ".tif");
// 	Dialog.addMessage("(For example .czi  .lsm  .nd2  .lif  .ims)");
	Dialog.addDirectory("Choose the input folder:", "");
	Dialog.addChoice("Choose Threshold method", methodList);
Dialog.show();

ext = Dialog.getString();
inputPath = Dialog.getString();
outputPath = inputPath + "Analysis_output";
method = Dialog.getChoice();

File.makeDirectory(outputPath);
list=getFileList(inputPath);

for (i = 0; i < list.length; i++) {
	if (endsWith(list[i], ext)){
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
		run("Invert LUTs");
		run("Fill Holes", "stack");
		//Isolate MPS
		imageCalculator("Subtract create stack", "MPS","Cells");
		run("Analyze Particles...", "size=0.5-50 circularity=0.8-1.00 show=Masks clear stack");
		
		run("Merge Channels...", "c1=Cells c2=[Mask of Result of MPS] create ignore");
		run("Invert LUT");
		saveAs("Tiff", outputPath+ "/" + list[i] + "_Analysed.tif");
		run("Close All");
	}
}

//Prints runtime to log window
print("");
print("Batch Completed.");
print("Total Runtime was:" + (getTime()-startTime)/1000 + " sec.");

//Exit message
exitTitle = "Batch Completed";
exitMsg = "Put down that coffee! Your analysis is finished";
waitForUser(exitTitle, exitMsg); 


/*
path = File.openDialog("Select a File");
open(path); // open the file
*/

/*
function MPS_Analyse(x) {
	open(x);
	//Threshold and Binary convert
	setAutoThreshold("Huang dark no-reset");
	run("Convert to Mask", "method=Huang black");
	//Smooth edges
	run("Median...", "radius=4.0");
	//Make duplicates
	run("Duplicate...", "title=Cells duplicate");
	run("Duplicate...", "title=MPS duplicate");
	//Cell mask
	selectImage("Cells");
	run("Invert LUTs");
	run("Fill Holes", "stack");
	run("Invert LUT");
	//Isolate MPS
	imageCalculator("Subtract create stack", "MPS","Cells");
	run("Analyze Particles...", "size=0.5-50 circularity=0.8-1.00 show=Masks clear stack");
	
	run("Merge Channels...", "c1=[Mask of Result of MPS] c2=Cells create");
	saveAs("Tiff", "/Users/stuart/Desktop/test.tif");
	run("Close All");
}
*/