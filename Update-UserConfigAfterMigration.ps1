
<#
.SYNOPSIS
this is a Script to look for all users in a Migration batch then add them multiple AD group to set the Cache Mode in Outlook, add EXO license and Configure Intune as well as adding Intune License. the groups name should be adjusted as needed to mach your own AD groups name and configure the group in Azure to take the suitable actions for you. 
this is a customized group for customized actions after the migration 
DESCRIPTION
This function updates the existing script with three switches:
- MigrationBatchName as input for the batch name 
-Exolicense: to run the 1st part of the code.
-CacheMode: to run the 2nd and 3rd parts of the code.
-IntuneConfig: to run the 4th and 5th parts of the code.

.PARAMETER MigrationBatchName
The name of the migration batch.

.EXAMPLE
     -MigrationBatchName "Batch1" -Exolicense -CacheMode -IntuneConfig
Updates the script with switches and runs all parts of the code.
#>

    param (
        [Parameter(Mandatory=$true)]
        [string]$MigrationBatchName,
        [switch]$Exolicense,
        [switch]$CacheMode,
        [switch]$IntuneConfig
    )

    $MigrationBatchUsers = Get-MigrationUser -BatchId $MigrationBatchName | Get-Mailbox

    foreach ($MigratedUser in $MigrationBatchUsers) {
        $ADDisplayName = $MigratedUser.DisplayName.ToString()
        $User = Get-ADUser -Filter { DisplayName -eq $ADDisplayName } | Select-Object -ExpandProperty SamAccountName

        # Check the mailbox type
        $MBType = Get-EXOMailbox $MigratedUser.DisplayName | Select-Object -ExpandProperty RecipientTypeDetails
        if ($MBType -notlike "UserMailbox") {
            Write-Host "The Mailbox $MigratedUser is a Shared or equipment Mailbox therefore we will not assign a license or add any other AD Group for this mailbox" -ForegroundColor Red
            continue
        } else {
            Write-Host "The Mailbox $MigratedUser is a User mailbox " -ForegroundColor Green
        }

        if ($Exolicense) {
            # 1. Check if the user is a member of the EXO group
            $EXOGroup = Get-ADUser -Filter { SamAccountName -eq $User } | Get-ADPrincipalGroupMembership | Where-Object { $_.Name -eq "RS-AZ-EXO" }
            if ($EXOGroup -eq $null) {
                # If user doesn't have the EXO Group, add them to the group
                Add-ADGroupMember -Identity "RS-AZ-EXO" -Members $User
                Write-Host "1. Added the user $User to RS-AZ-EXO group." -ForegroundColor Green
            } else {
                Write-Host "1. The user $User is already a member of RS-AZ-EXO group." -ForegroundColor Yellow
            }
        }

        if ($CacheMode) {
             #2.Check if the user is a member of the XA-OutlookExchangeCacheMode group
        	$AltOutlookExchangeCacheMode = Get-ADUser -Filter { SamAccountName -eq $User } | Get-ADPrincipalGroupMembership | Where-Object { $_.Name -eq "XA-OutlookExchangeCacheMode" }

            if ($AltOutlookExchangeCacheMode -eq $null) {
                # If user doesn't have the Cache Group, add them to the grop 
                Write-Host "2. The user $User is not a member of the old XA-OutlookExchangeCacheMode group." -ForegroundColor Yellow
            } else {
                Remove-ADGroupMember -Identity "XA-OutlookExchangeCacheMode" -Members $User
                Write-Host "2. Removed the User $User is from the old XA-OutlookExchangeCacheMode group." -ForegroundColor Green
            }

        
            #3. Check if the user is a member of the XA-OutlookCacheMode group
            $EXOCacheMode = Get-ADUser -Filter { SamAccountName -eq $User } | Get-ADPrincipalGroupMembership | Where-Object { $_.Name -eq "XA-OutlookCacheMode" }

            if ($EXOCacheMode -eq $null) {
                # If user doesn't have the Cache Group, add them to the group
                Add-ADGroupMember -Identity "XA-OutlookCacheMode" -Members $User
                Write-Host "3. Added the user $User to Excahnge Online XA-OutlookCacheMode group." -ForegroundColor Green
            } else {
                Write-Host "3. The user $User is already a member of Exchange Online XA-OutlookCacheMode group." -ForegroundColor Yellow
            }
        }

        if ($IntuneConfig) {
           # 4. Check if the user is a member of the RS-AZ-Intune-MDM  group
            $IntuneGroup  = Get-ADUser -Filter { SamAccountName -eq $User } | Get-ADPrincipalGroupMembership | Where-Object { $_.Name -eq "RS-AZ-Intune-MDM" }

            if ($IntuneGroup -eq $null) {
            # If user doesn't have the EXO Group, add them to the group
                Add-ADGroupMember -Identity "RS-AZ-Intune-MDM" -Members $User
                Write-Host "4. Added the user $User to RS-AZ-Intune-MDM group." -ForegroundColor Green
            } else {
                Write-Host "4. The user $User is already a member of RS-AZ-Intune-MDM group." -ForegroundColor Yellow     
            }

        
            # 5. Check if the user is a member of the RS-AZ-Intune  group
            $IntuneGroup2  = Get-ADUser -Filter { SamAccountName -eq $User } | Get-ADPrincipalGroupMembership | Where-Object { $_.Name -eq "RS-AZ-Intune" }

            if ($IntuneGroup2 -eq $null) {
            # If user doesn't have the EXO Group, add them to the group
                Add-ADGroupMember -Identity "RS-AZ-Intune" -Members $User
                Write-Host ""
                Write-Host "5. Added the user $User to RS-AZ-Intune group." -ForegroundColor Green
                Write-Host ""
            } else {
                Write-Host "5. The user $User is already a member of RS-AZ-Intune group." -ForegroundColor Yellow
                Write-Host ""
            }
        }
    }
