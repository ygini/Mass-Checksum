# Mass-Checksum
Mass Checksum is an open-source tool allowing you to create a checksum for a folder or a file.

## Creating a masschecksum

Start the application, a new window should pop up (if not, hit cmd-N). Use the select button to choose the file or folder to check, then click "compute".

The checksum displayed is the checksum for the whole data found at selected path. If you want to save the result as a proof for the future, you can write this global checksum or hit cmd-S to save the full report file. This file contains a full file tree relative to the target folder with checksum for each file.

## Validating a masschecksum

When you've saved a masschecksum in the past and want to check the current state, hit cmd-O to open a previous report. The app will try to locate the original base folder used for the report. If it can't find it for any reason, the app will ask you to select the same base folder as before. 

When the app is open, you just have to click on "verify" to check the target. If any differences are found, you can ask to see and save a changelog with list of deleted, created and updated files.

## Comparing two copies

If you have two copies of the same file or folder, create a masschecksum with the first one, then open it (you've to close the creating window and open the report file). When you've opened the masschecksum file, the app should select by default the original target file or folder. You can click on select to choose another target and click on "verify" to check this new target against the previous result.
