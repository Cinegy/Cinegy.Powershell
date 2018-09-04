These are the PowerShell files we use for scripting against CAS - in their full, working form.

They have been tested with CAS 11.1 RC in the current form, but should work fine with CAS v11.0 release and with adjustment to the version string with CAS 10.3.

To use the scripts, a JSON file is loaded by the CAS-Core script (a script imported by all other scripts). This JSON file contains the required connection details, and can also securely store an encrypted password for the account used to connect to CAS. You can either hand-create this script, or use our handy script CAS-StoreCredentials to interactively fill in the required parameters to create the script for you.

Have fun with them!