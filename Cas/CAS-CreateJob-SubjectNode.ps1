Param(
    [Parameter(Mandatory=$true)][string]$JobDropTargetId,
    [Parameter(Mandatory=$true)][string]$SubjectNodeId,
    [Parameter(Mandatory=$false)][string]$JobName="",
    [Parameter(Mandatory=$false)][bool]$CreateDisabled=$false)

# $JobDropTargetId = job drop target node id where new job should be created
# $SubjectNodeId = node id to be added to the job drop target
# $JobName = (optional) job name to be created, default is "New Job"
# $CreateDisabled = (optional) specifies whether the job should be created as disabled, default is "FALSE"

. .\CAS-Core.ps1

# connect to CAS
$context = Get-CasContext

# find job drop target to be used
$jobDropTargetNodeResult = Invoke-CasMethod -MethodRelativeUrl "/node/$($JobDropTargetId)?f=1" -Context $context
if($jobDropTargetNodeResult.retCode -ne 0)
{
    Write-Host "Failed to locate the job drop target node [$JobDropTargetId]: $($jobDropTargetNodeResult.error)"
} 
else
{
    # find subject node to be added 
    $subjectNodeResult = Invoke-CasMethod -MethodRelativeUrl "/node/$($SubjectNodeId)?f=1" -Context $context
    if($subjectNodeResult.retCode -ne 0)
    {
        Write-Host "Failed to locate the subject node [$SubjectNodeId]: $($subjectNodeResult.error)"
    } 
    else
    {
        # job creation parameters
        $jobParameters = [PSCustomObject]@{
            parent_id = $jobDropTargetId
            name = $JobName
            job_disabled = $CreateDisabled
            subjects = @( $subjectNode.node.node )
        }

        # generate request body, use Depth to properly serialize "subjects"
        $parametersJson = (ConvertTo-Json -InputObject $jobParameters -Depth 3)

        # create job node
        $response = Invoke-CasMethod -MethodRelativeUrl '/createjob' -Method POST -Body $parametersJson -Context $context  

        if($response.retCode -ne 0)
        {
            Write-Host "Failed to create job: $($response.error)"
        }
        else
        {
            Write-Host "Created new job with ID [$($response.node._id._nodeid_id)]"
        }
    }
}

# logout session
Invoke-CasLogout -Context $context

