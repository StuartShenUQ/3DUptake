setBatchMode(true);
//setOption("ExpandableArrays", true);

run("Clear Results");
//run("Collect Garbage");
roiManager("reset");
print("\\Clear")

getDateAndTime(year, month, week, day, hour, min, sec, msec);
startTime = getTime();
methodList = getList("threshold.methods");
extras = newArray("---", "Airyscan border removal", "In development");
fileCount = 0;
totalCount = 0;
concatMes = "";
concatEst = "";
fs = File.separator;
run("Set Measurements...", "area mean min integrated redirect=None decimal=3");
indf = 16;
channel = newArray("C1", "C2");

//Set cellpose environment directory
cellposeDir = "";
if (substring(getInfo("os.name"), 0, 1) == "M") {
	cellposeDir = "/opt/anaconda3/envs/Cellpose";
}
if (substring(getInfo("os.name"), 0, 1) == "W") {
	cellposeDir = "C:\\Users\\Public\\Anaconda_MU\\envs\\cellpose"; //"C:\\Users\\Public\\Documents\\Anaconda_MU\\envs\\cellpose";} //C:\\Users\\uqshongy\\.conda\\envs\\cellpose
}

print("Volumetric Analysis of endosomal vesicles (inverse fluorescent imaging)");
print("Scripted by Hongyu (Stuart) Shen with help of Dr. Nicholas Condon");
print("as part of a PhD project in Jennifer L. Stow's Lab");
print("Institute for Molecular Bioscience | The University of Queensland\n");
print("Version 0.8.2M (Multichannels) | Cellpose version 2, Model: cyto2");
print("Dependencies: Conda environemnt, Cellpose, BIOP FIJI Wrapper");
print("Script Run Date: " + day + "/" + (month+1) + "/" + year + "  Time: " + hour + ":" + min + ":" + sec);
print("=============================================================");

//Create dialog to get input/output directory
Dialog.create("Setup");
	Dialog.setInsets(0,0,15);
	Dialog.addString("File Extension:", ".tif");
	Dialog.addToSameRow();
 	Dialog.addMessage("(For example .czi  .lsm  .nd2  .lif  .ims)");
	Dialog.setInsets(0,0,15);
	Dialog.addDirectory("Choose the input folder:", "");
	Dialog.setInsets(0,0,15);
	Dialog.addChoice("Choose Threshold method", methodList, "");
	Dialog.addToSameRow();
	Dialog.addMessage("Confocal - Huang | Airyscan/DragonFly - Default");
	Dialog.setInsets(0,0,15);
	Dialog.addString("Vesicle Size:", "0.5-10");
	Dialog.addRadioButtonGroup("Choose your referencing channel", channel, 1, 2, "C1");
	Dialog.addRadioButtonGroup("Choose your fluorescein channel", channel, 1, 2, "C2");
	Dialog.addCheckbox("Cellpose", true);
	Dialog.setInsets(0,0,0);
	Dialog.addDirectory("Choose the cellpose environment directory:", cellposeDir);
	Dialog.setInsets(0,0,15);
	Dialog.addMessage("Default directory: " + cellposeDir);//*Anaconda installation folder*" + fs + "envs" + fs + "cellpose");
	Dialog.addCheckbox("Reference files", true);
	Dialog.addCheckbox("De-noise", true);
	Dialog.addChoice("Extras", extras);
Dialog.show();

ext = Dialog.getString();
inputPath = Dialog.getString();
refPath = inputPath + "References" + fs;
method = Dialog.getChoice();
vesSize = Dialog.getString();
refCha = Dialog.getRadioButton();
fuoCha = Dialog.getRadioButton();
cellpose = Dialog.getCheckbox();
cellposeDir = Dialog.getString();
refMode = Dialog.getCheckbox();
deNoise = Dialog.getCheckbox();
extrasChoice = Dialog.getChoice();

//Define Cellpose directory
if (cellpose == true) {
	print("Cellpose: Enabled, Setting up...");
	while (File.isDirectory(cellposeDir) == 0) {
		Dialog.create("Error");
			Dialog.addMessage("Cellpose directory not found...");
			Dialog.addDirectory("Choose the cellpose environment directory:", cellposeDir);
		Dialog.show();
		cellposeDir = Dialog.getString();
	}
	run("Cellpose setup...", "cellposeenvdirectory=" + cellposeDir + " envtype=conda usegpu=true usemxnet=false usefastmode=false useresample=false version=2.0");
}
else {print("Cellpose: Disabled...");}
print("=============================\n");

function progressBar(progress, total, index) {
	bar = "";
	if (substring(getInfo("os.name"), 0, 1) == "M") {
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
		if (i > pp) {
			print("\\Update" + index + ":" + "[" + substring(barL, 0, i) + substring(barR, i, range) + "] " + round(progress/total*100) + "%");
			wait(20);
		}
	}
}

list = getFileList(inputPath);
for (i = 0; i < list.length; i++) {if (endsWith(list[i], ext)){totalCount++;}}
if (refMode == true) {File.makeDirectory(refPath);}

//Create Output File
Results = File.open(inputPath + "Results_" + year + "-" + (month+1) + "-" + day + "_" + hour + "." + min + ".csv");
print(Results, "File Number, File Name, Cell Count, Cell ID, Cell Volume, Total Vesicular Volume, Vesicle Count, Individual Vesicular Size");

for (i = 0; i < list.length; i++) {
	if (endsWith(list[i], ext)) {
		index = 12;
		fileCount++;
		print("\\Update" + index + ":Processing Image " + fileCount + "/" + totalCount);
		index++;
		progressBar(fileCount, totalCount, index);
		index = index + 2;
		for (m = index; m <= indf; m++) {
			print("\\Update" + m + ": ");
		}
		run("Clear Results");
		roiManager("reset");
		showProgress(i + 1, totalCount);
		open(inputPath+list[i]);
		rename("Input");
		getVoxelSize(width, height, depth, unit);

		//Airyscan remove border
		if (extrasChoice == "Airyscan border removal"){
			getDimensions(width, height, channels, slices, frames);
			makeRectangle(13, 13, width-26, height-26);
			run("Crop");
		}

		if (cellpose == true) {
			selectWindow(refCha + "-Input");
			//Cellpose initiation
			run("Duplicate...", "title=Segmentation duplicate");
			
			//Pre-processing
			run("Sharpen", "stack");
			run("Z Project...", "projection=[Average Intensity]");
			run("Invert");
			
			//Cellpose Segmentation
			print("\\Update" + index + ":Cellpose Processing...");
			index++;
			//print("Cellpose Processing...");
			run("Cellpose Advanced", "diameter=250 cellproba_threshold=-4.0 flow_threshold=0.6 anisotropy=1.0 diam_threshold=12.0 model=cyto2 nuclei_channel=0 cyto_channel=1 dimensionmode=2D stitch_threshold=-1.0 omni=false cluster=false additional_flags=");
	
			//Cellpose to ROI (@ Nick)
			selectWindow("AVG_Segmentation-cellpose");
			run("Select All");
			getMinAndMax(min, max);
			for (j = 1; j <= max; j ++) {
				setThreshold(j, j);
				run("Create Selection");
				run("Measure");
				if (getResult("Area", j - 1) > 5) {roiManager("Add");}
				resetThreshold();
			}
			
			//Output Headings
			print("\\Update" + index + ":" + RoiManager.size + " cell(s) found.");
			index = index + 2;
			print(Results, fileCount + "," + File.getNameWithoutExtension(list[i]) + "," + RoiManager.size);
		}
		
		//Threshold and Binary convert
		run("Clear Results");
		selectImage(fuoCha + "-Input");
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
		run("Duplicate...", "title=Cellmask duplicate");
		run("Watershed", "stack");
		run("Invert", "stack");
		run("Fill Holes", "stack");
		run("Invert", "stack");
		
		//Isolate Vesicle
		imageCalculator("Subtract create stack", "Vesicles","Cellmask");
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
		setThreshold(0.1, 1000000000000000000000000000000.0000);
		
		//Measurements with Clipping Masks
		print("\\Update" + index + ":Measuring...");
		index++;
		
		if (cellpose == true) {
			for (k = 0; k < RoiManager.size; k ++) {
				progressBar(k + 1, RoiManager.size, index);
				run("Clear Results");
				
				//Measurments
				selectImage("SUM_Cells");
				roiManager("select", k);
				run("Measure");
				selectImage("SUM_Vesiclemask");
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
					if (getResult("Max", l) > 1) {
						pixA = getResult("Area", l);
						pixR = sqrt(pixA/PI);
						pixV = getResult("IntDen", l);
							
						//Estimated volume based on area
						estVol = estVol + (4/3 * PI * pow(pixR,3)) + ", ";
						//Measured volume
						mesVol = mesVol + pixV * depth + ", ";
						//Number of vesicles
						numVes++;
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
			index = index + 2;
		}

		else {
			//Measurments
			index++;
			selectImage("SUM_Cells");
			run("Measure");
			selectImage("SUM_Vesiclemask");
			run("Measure");
			selectImage("Vesicle_count");
			run("Analyze Particles...", "size=0-50 circularity=0.0-1.00 show=Masks display stack");
			cellVol = getResult("IntDen", 0) * depth;
			veslVol = getResult("IntDen", 1) * depth;
			mesVol = "";
			estVol = "";
			numVes = 0;
			
			for (l = 2; l < nResults; l ++) {
				if (getResult("Max", l) > 1) {
					pixA = getResult("Area", l);
					pixR = sqrt(pixA/PI);
					pixV = getResult("IntDen", l);
					
					//Estimated volume based on area
					estVol = estVol + (4/3 * PI * pow(pixR,3)) + ", ";
					//Measured volume
					mesVol = mesVol + pixV * depth + ", ";
					//Number of vesicles
					numVes++;
				}
			}
			
			if (nResults > 2) {
				concatMes = concatMes + mesVol;
				concatEst = concatEst + estVol;
			}
			//Output file
			print(Results, ",,," + fileCount + "," + cellVol + "," + veslVol + "," + numVes + "," + mesVol);
		}
		
		//Concatenate files for reference
		if (refMode == true) {
			print("\\Update" + index + ":Writing Referencing Files...");
			index = index + 2;
			
			if (cellpose == true) {
				run("Merge Channels...", "c1=SUM_Cells c2=[SUM_Vesiclemask] c3=AVG_Segmentation-cellpose create ignore");
				run("From ROI Manager");
			}
			else {
				run("Merge Channels...", "c1=SUM_Cells c2=[SUM_Vesiclemask] create ignore");
			}
			
			saveAs("Tiff", refPath + "Summary_" + File.getNameWithoutExtension(list[i]) + year + "-" + (month+1) + "-" + day + "_" + hour + "." + min + ".tif");
		}
		print("\\Update" + index + ":Writing Outputs...");
		indf = index;

	}
	run("Close All");
}

print(Results, "Concatenated Measured Volume: ," + concatMes);
print(Results, "Concatenated Estimated Volume: ," + concatEst);

//Display runtime to log window
run("Clear Results");
run("Collect Garbage");
print("\n=============================================================");
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

/*Dev note:
 * De-noise does nothing - removed
 * Image name may clash
 */