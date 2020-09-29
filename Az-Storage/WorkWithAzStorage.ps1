###################################################################################################
#                              Azure Login
#
Login-AzAccount -Credential $credential   
Get-AzureRmSubscription
Select-AzureRmSubscription -Subscription "MSFT Azure Sponsorship IUR 2"
#
#
###################################################################################################


#########################################################################################################################

Import-Module Azure.Storage -MaximumVersion 4.6.1
Import-Module AzureRm.Storage
Import-Module AzureRmStorageTable -MaximumVersion 1.0.0.23
Import-Module AzureRmStorageQueue

#Azure Stack Storage Account
$StorageAccountName = "afwdemostorage" 
$StorageAccountKey = "TEK3hzdtKLgIjG2/0FSfj47/CfNgvBnLYbFZNQ4GWNr1kLXuh89RPdid0zcd1pUqKdhv8zBeqe+jMqZmHbbmxQ=="

$ctx = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

#########################################################################################################################

#########################################################################################################################
# Upload Files to Blob

#region

$ContainerName = "demoafw"
$localFileDirectory = "C:\temp\hybriddemo"

foreach ($file in (Get-ChildItem -Path $localFileDirectory))
{
if((Get-AzureStorageContainer -Context $ctx | Where-Object { $_.Name -eq $ContainerName }) -eq $null)
{
    New-AzureStorageContainer -Context $ctx -Name $ContainerName
}

Set-AzureStorageBlobContent -File $file.FullName -Container $ContainerName -Blob $file.Name -Context $ctx -Force
}

#endregion

#
#########################################################################################################################

#########################################################################################################################
# Create Azure Table
#region
# Req. Install-Module AzureRmStorageTable -

$tableName = "afwdemo"
$partitionKey = "Client"

# Create Table
$ctx = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

if((Get-AzureStorageTable -Name $tableName -Context $ctx -ErrorAction SilentlyContinue) -eq $null)
{
New-AzureStorageTable –Name $tableName –Context $ctx
}

$table = Get-AzureStorageTable -Name $tableName -Context $ctx

#Add items to table
Add-StorageTableRow -table $table -partitionKey $partitionKey -rowKey ([guid]::NewGuid().tostring()) -property @{"computerName"="COMP01";"osVersion"="Windows 10";"status"="OK"}
Add-StorageTableRow -table $table -partitionKey $partitionKey -rowKey ([guid]::NewGuid().tostring()) -property @{"computerName"="COMP02";"osVersion"="Windows 8.1";"status"="OK"}
Add-StorageTableRow -table $table -partitionKey $partitionKey -rowKey ([guid]::NewGuid().tostring()) -property @{"computerName"="COMP03";"osVersion"="Windows XP";"status"="NeedsOsUpgrade"}


#Get all rows
Get-AzureStorageTableRowAll -table $table | ft

#endregion
#
#########################################################################################################################


#########################################################################################################################
# Azure Queue samples
#region

$queueName = "afwdemo"

# Retrieve a specific queue
if((Get-AzureStorageQueue –Name $queueName –Context $ctx) -eq $null)
{
New-AzureStorageQueue -Name $queueName –Context $ctx
}

$queue = Get-AzureStorageQueue –Name $queueName –Context $ctx
# Show the properties of the queue
$queue

# Retrieve all queues and show their names
Get-AzureStorageQueue -Context $ctx | select Name

# Add Message to queue
$message = @{"location"="azure";
         "vhdname"="demovmazure01";
         "VMOwner"="laglerh";
         "VMType"="webserver"}

Add-AzureRmStorageQueueMessage -queue $queue -message $message

#Dequeue message
        Invoke-AzureRmStorageQueuePeekMessage -queue $queue #Message bleibt in der Queue
$message =  Invoke-AzureRmStorageQueueGetMessage -queue $queue  #Message wird gelesen und zeitgelich gelöscht von der Queue

$s = ConvertFrom-Json($message.AsString)
$s

#endregion
#
#########################################################################################################################