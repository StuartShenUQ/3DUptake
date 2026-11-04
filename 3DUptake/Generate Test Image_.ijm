setBatchMode(true);
run("Duplicate...", "title=Input duplicate");
run("Sharpen", "stack");
run("Z Project...", "projection=[Average Intensity]");
run("Invert");
close("Input");
selectImage("AVG_Input");
rename("AVG_Test_Image");
setBatchMode("show");