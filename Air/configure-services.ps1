#Requires -RunAsAdministrator

#script to install Cinegy Playout Engine as a Windows Service

#Actions hashtable for main menu
$actions = [ordered]@{
    "CreateAll" = @{
        "Description" = "Create Missing Services For All Configured Engines"
        "Function" = "CreateAllServices"
    }
    #"RecreateSpecific" = @{
    #    "Description" = "(Re)create Service For Specific Engine Number"
    #    "Function" = "RecreateSpecificService"
    #}
    "StopAll" = @{
        "Description" = "Stop All Services"
        "Function" = "StopAllServices"
    }
    "RemoveAll" = @{
        "Description" = "Remove All Services"
        "Function" = "RemoveAllServices"
    }
    #"RemoveSpecifc" = @{
    #    "Description" = "Remove Service For Specific Engine Number"
    #   "Function" = "RemoveSpecifcService"
    #}
    "Exit" = @{
        "Description" = "Exit"
        "Function" = "exit"
    }
}

#This variable represents the expected location of the dashboard inhibit flag.
#It is also used as the source of the pop-up message when the dash is started while inhibited
$flagPath = "C:\ProgramData\Cinegy\CinegyAir\InhibitDashboard.flag"

#This variable represents the expected location of the actual playout engine exe.
$enginePath = "C:\Program Files\Cinegy\Cinegy Playout x64 14.0.0\PlayOutExApp.exe"

function Set-ServiceRecovery{
    param
    (
        [string] [Parameter(Mandatory=$true)] $ServiceName,
        [string] $action1 = "restart",
        [int] $time1 =  10000, # in miliseconds
        [string] $action2 = "restart",
        [int] $time2 =  30000, # in miliseconds
        [string] $actionLast = "restart",
        [int] $timeLast = 30000, # in miliseconds
        [int] $resetCounter = 600 # in seconds
    )

    $services = Get-CimInstance -ClassName 'Win32_Service' | Where-Object {$_.Name -imatch $ServiceName}
    $action = $action1+"/"+$time1+"/"+$action2+"/"+$time2+"/"+$actionLast+"/"+$timeLast

    foreach ($service in $services){
        # https://technet.microsoft.com/en-us/library/cc742019.aspx
        sc.exe $serverPath failure $($service.Name) reset= $resetCounter actions= $action | Out-Null
    }
}

function CreateAllServices{
    
    $configs = Get-ChildItem -Path C:\ProgramData\Cinegy\CinegyAir\Config\Instance-*.Config.xml
    $newServices = 0
    $existingServices = 0

    if($configs){
        #inhibit the dashboard running if we will install any services
        $flagExists = Test-Path -Path $flagPath
        if(!$flagExists){
            $startupMessage = "Cinegy Playout Engine Dashboard has been inhibited from starting, " +
                "because Playout Engines are configured to work as Windows Services.`n`n" +
                "If this is incorrect, please use the 'configure-services' script to remove all services."
            
            $startupMessage | Out-File -Force $flagPath 
        }
    }

    foreach($config in $configs)
    {
        if($config.Name -match "(Instance-)(\d+)(.Config.xml)"){
            $existingSvc = Get-Service -Name "CinegyPlayoutEngine$($Matches[2])" -ErrorAction SilentlyContinue
            if(!$existingSvc)
            {
                New-Service -Name "CinegyPlayoutEngine$($Matches[2])" `
                    -BinaryPathName "$enginePath $($Matches[2])" `
                    -DependsOn NetLogon -DisplayName "Cinegy Air Playout Engine Service $($Matches[2])" `
                    -StartupType Automatic -Description "The service wrapping configuration $($Matches[2]) of the Cinegy Air Playout Engine" | Out-Null

                Set-ServiceRecovery -ServiceName "CinegyPlayoutEngine$($Matches[2])"
                $newServices++
            }
            else{
                $existingServices++
            }
        }
    }

    
    Write-Host "`nFound $existingServices existing Cinegy Air Engine Services" -ForegroundColor Green
    Write-Host "`nCreated $newServices new Cinegy Air Engine Services" -ForegroundColor Green

    Read-Host "`nHit enter to continue"
}

function StopAllServices{    
    $services = Get-Service -Name "CinegyPlayoutEngine*"
    $servicesStopped = 0

    foreach($service in $services){
        if($service.Status -ne "Stopped"){
            Write-Host "Stopping service $($service.Name)"
            Stop-Service $service
            $servicesStopped++
        }
    }

    Write-Host "`nStopped $servicesStopped Cinegy Air Engine Services" -ForegroundColor Green
    Read-Host "`nHit enter to continue"
}

function RemoveAllServices{
    $services = Get-Service -Name "CinegyPlayoutEngine*"
    $servicesStopped = 0
    $servicesRemoved = 0

    $flagExists = Test-Path -Path $flagPath
    if($flagExists){
       Remove-Item -Path $flagPath
    }

    foreach($service in $services){
        if($service.Status -ne "Stopped"){
            Write-Host "Stopping service $($service.Name)"
            Stop-Service $service
            $servicesStopped++
        }
        sc.exe delete $($service.Name) | Out-Null 
        $servicesRemoved++
    }

    Write-Host "`nStopped $servicesStopped Cinegy Air Engine Services" -ForegroundColor Green
    Write-Host "`nRemoved $servicesRemoved Cinegy Air Engine Services" -ForegroundColor Green
    Read-Host "`nHit enter to continue"
}

# main script block starts here
while($true){
    Clear-Host
    Write-Host "`nWelcome to the Cinegy Playout Engine Service Installation & Configuration Script`n" -ForegroundColor Green
    
    #Action selection phase
    $actionIdx = 1

    Write-Host "Please select an action from the list: " -ForegroundColor Cyan

    #Generate menu from environments hashtable
    foreach($action in $actions.GetEnumerator())
    {
        Write-Host "$actionIdx - $($action.Value.Description)"
        $actionIdx = $actionIdx + 1
    }

    #Read in user choice
    $actionChoice = Read-Host "`nSelection"

    #Loop if invalid choice
    if ($actionChoice -and 
            ($actionChoice -match "^[\d\.]+$") -and
            ($actionChoice -le $actions.Count)) {

        $selectedAction = $actions[($actionChoice - 1)]

        #Inform user of choice
        Write-Host "`nAction " -NoNewline
        Write-Host $($selectedAction.Description) -ForegroundColor Green -NoNewline
        Write-Host " has been selected"

        #call associated function from menu hashtable for choice
        Invoke-Expression $selectedAction.Function

        $actionChoice = $null
    }
    else {
        Write-Host "`nInvalid Selection`n" -ForegroundColor Red
    }

    #loop back to start of menu
}