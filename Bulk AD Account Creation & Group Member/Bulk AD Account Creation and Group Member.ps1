#Enter a path to your import CSV file
$ADUsers = Import-csv C:\AD_Creation\users.csv
 
foreach ($User in $ADUsers)
{
 
       $Username    = $User.username
       $Password    = $User.password
       $Firstname   = $User.firstname
       $Lastname    = $User.lastname
       $DisplayName = $User.displayname
       $Department  = $User.department
       $OU           = $User.ou
       $MobilePhone = $User.MobilePhone
       $OfficePhone = $User.OfficePhone
       $city        = $User.city
       $EmailAddress = $User.EmailAddress
       $jobtitle     = $User.jobtitle
       $Company      = $User.Company

 
 
       #Check if the user account already exists in AD
       if (Get-ADUser -F {SamAccountName -eq $Username})
       {
               #If user does exist, output a warning message
               Write-Warning "A user account $Username has already exist in Active Directory."
       }
       else
       {
              #If a user does not exist then create a new user account
        #Account will be created in the OU listed in the $OU variable in the CSV file; don’t forget to change the domain name in the"-UserPrincipalName" variable
              New-ADUser `
            -SamAccountName $Username `
            -UserPrincipalName "$Username@renew.com" `
            -Name "$Firstname $Lastname" `
            -GivenName $Firstname `
            -Surname $Lastname `
            -Enabled $True `
            -ChangePasswordAtLogon $True `
            -DisplayName "$Firstname $Lastname" `
            -Department $Department `
            -Path $OU `
            -MobilePhone $MobilePhone `
            -OfficePhone $OfficePhone `
            -City $city `
            -EmailAddress $EmailAddress `
            -Title $jobtitle `
            -Company $Company `
            -AccountPassword (convertto-securestring $Password -AsPlainText -Force)
 
       }
}
 
# Import AD Module
Import-Module ActiveDirectory
 
# Import the data from CSV file and assign it to variable
$List = Import-csv "C:\AD_Creation\Group.csv"
 
foreach ($User in $List) {
    # Retrieve UserSamAccountName and ADGroup
    $UserSam = $User.SamAccountName
    $Groups = $User.Group
 
    # Retrieve SamAccountName and ADGroup
    $ADUser = Get-ADUser -Filter "SamAccountName -eq '$UserSam'" | Select-Object SamAccountName
    $ADGroups = Get-ADGroup -Filter * | Select-Object DistinguishedName, SamAccountName
 
    # User does not exist in AD
    if ($ADUser -eq $null) {
        Write-Host "$UserSam does not exist in AD" -ForegroundColor Red
        Continue
    }
    # User does not have a group specified in CSV file
    if ($Groups -eq $null) {
        Write-Host "$UserSam has no group specified in CSV file" -ForegroundColor Yellow
        Continue
    }
    # Retrieve AD user group membership
    $ExistingGroups = Get-ADPrincipalGroupMembership $UserSam | Select-Object DistinguishedName, SamAccountName
 
    foreach ($Group in $Groups.Split(';')) {
        # Group does not exist in AD
        if ($ADGroups.SamAccountName -notcontains $Group) {
            Write-Host "$Group group does not exist in AD" -ForegroundColor Red
            Continue
        }
        # User already member of group
        if ($ExistingGroups.SamAccountName -eq $Group) {
            Write-Host "$UserSam already exists in group $Group" -ForeGroundColor Yellow
        } 
        else {
            # Add user to group
            Add-ADGroupMember -Identity $Group -Members $UserSam
            Write-Host "Added $UserSam to $Group" -ForeGroundColor Green
        }
    }
}
