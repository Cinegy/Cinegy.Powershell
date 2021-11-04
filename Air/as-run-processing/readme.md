# Example Cinegy As Run Processor

This simple script shows how the structured Cinegy Playout As Run logs can be simply adapted into different formats.

The log format documentation (at time of writing) is here:

https://open.cinegy.com/products/air/21.9/playout/user-manual/configuration/logging/#activity-logging

The script reads all lines in the activity log, and then applys a simple filter to only pick lines involving 'VIDEO' devices with 'START' events.

The script also shows a simple conversion from the ISO8601 time format to whatever the hosting machine local timezone is (be careful reading processed timestamps covering daylight savings changes!)

The script will save the results to the same location of the input file, with the word '-processed' added to the filename.

To make execution easier, a simple BAT file is included - you can then drag / drop an as-run file onto the BAT file to trigger the conversion.