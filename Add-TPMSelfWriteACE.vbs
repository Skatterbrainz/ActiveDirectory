'===============================================================================
' copied from https://technet.microsoft.com/library/dn466534%28v=ws.11%29.aspx?f=255&MSPPError=-2147217396#BKMK_Add_TPMSelfWriteACE
' This script demonstrates the addition of an Access Control Entry (ACE)
' to allow computers to write Trusted Platform Module (TPM) 
' recovery information to Active Directory.
'
' This script creates a SELF ACE on the top-level domain object, and
' assumes that inheritance of ACL's from the top-level domain object to 
' down-level computer objects are enabled.
'
' 
'
' Last Updated: 12/05/2012
' Last Reviewed: 12/05/2012
' Microsoft Corporation
'
' Disclaimer
' 
' The sample scripts are not supported under any Microsoft standard support program
' or service. The sample scripts are provided AS IS without warranty of any kind. 
' Microsoft further disclaims all implied warranties including, without limitation, 
' any implied warranties of merchantability or of fitness for a particular purpose. 
' The entire risk arising out of the use or performance of the sample scripts and 
' documentation remains with you. In no event shall Microsoft, its authors, or 
' anyone else involved in the creation, production, or delivery of the scripts be 
' liable for any damages whatsoever (including, without limitation, damages for loss 
' of business profits, business interruption, loss of business information, or 
' other pecuniary loss) arising out of the use of or inability to use the sample 
' scripts or documentation, even if Microsoft has been advised of the possibility 
' of such damages.
'
' Version 1.0.2 - Tested and re-released for Windows 8 and Windows Server 2012 

' 
'===============================================================================

' --------------------------------------------------------------------------------
' Access Control Entry (ACE) constants 
' --------------------------------------------------------------------------------

'- From the ADS_ACETYPE_ENUM enumeration
Const ADS_ACETYPE_ACCESS_ALLOWED_OBJECT      = &H5   'Allows an object to do something

'- From the ADS_ACEFLAG_ENUM enumeration
Const ADS_ACEFLAG_INHERIT_ACE                = &H2   'ACE can be inherited to child objects
Const ADS_ACEFLAG_INHERIT_ONLY_ACE           = &H8   'ACE does NOT apply to target (parent) object

'- From the ADS_RIGHTS_ENUM enumeration
Const ADS_RIGHT_DS_WRITE_PROP                = &H20  'The right to write object properties
Const ADS_RIGHT_DS_CREATE_CHILD              = &H1   'The right to create child objects

'- From the ADS_FLAGTYPE_ENUM enumeration
Const ADS_FLAG_OBJECT_TYPE_PRESENT           = &H1   'Target object type is present in the ACE 
Const ADS_FLAG_INHERITED_OBJECT_TYPE_PRESENT = &H2   'Target inherited object type is present in the ACE 

' --------------------------------------------------------------------------------
' TPM and FVE schema object GUID's 
' --------------------------------------------------------------------------------

'- ms-TPM-OwnerInformation attribute
SCHEMA_GUID_MS_TPM_OWNERINFORMATION = "{AA4E1A6D-550D-4E05-8C35-4AFCB917A9FE}"

'- ms-FVE-RecoveryInformation object
SCHEMA_GUID_MS_FVE_RECOVERYINFORMATION = "{EA715D30-8F53-40D0-BD1E-6109186D782C}"

'- Computer object
SCHEMA_GUID_COMPUTER = "{BF967A86-0DE6-11D0-A285-00AA003049E2}"

'Reference: "Platform SDK: Active Directory Schema"




' --------------------------------------------------------------------------------
' Set up the ACE to allow write of TPM owner information
' --------------------------------------------------------------------------------

Set objAce1 = createObject("AccessControlEntry")

objAce1.AceFlags = ADS_ACEFLAG_INHERIT_ACE + ADS_ACEFLAG_INHERIT_ONLY_ACE
objAce1.AceType = ADS_ACETYPE_ACCESS_ALLOWED_OBJECT
objAce1.Flags = ADS_FLAG_OBJECT_TYPE_PRESENT + ADS_FLAG_INHERITED_OBJECT_TYPE_PRESENT

objAce1.Trustee = "SELF"
objAce1.AccessMask = ADS_RIGHT_DS_WRITE_PROP 
objAce1.ObjectType = SCHEMA_GUID_MS_TPM_OWNERINFORMATION
objAce1.InheritedObjectType = SCHEMA_GUID_COMPUTER



' --------------------------------------------------------------------------------
' NOTE: BY default, the "SELF" computer account can create 
' BitLocker recovery information objects and write BitLocker recovery properties
'
' No additional ACE's are needed.
' --------------------------------------------------------------------------------


' --------------------------------------------------------------------------------
' Connect to Discretional ACL (DACL) for domain object
' --------------------------------------------------------------------------------

Set objRootLDAP = GetObject("LDAP://rootDSE")
strPathToDomain = "LDAP://" & objRootLDAP.Get("defaultNamingContext") ' e.g. string dc=fabrikam,dc=com

Set objDomain = GetObject(strPathToDomain)

WScript.Echo "Accessing object: " + objDomain.Get("distinguishedName")

Set objDescriptor = objDomain.Get("ntSecurityDescriptor")
Set objDacl = objDescriptor.DiscretionaryAcl

 
' --------------------------------------------------------------------------------
' Add the ACEs to the Discretionary ACL (DACL) and set the DACL
' --------------------------------------------------------------------------------

objDacl.AddAce objAce1

objDescriptor.DiscretionaryAcl = objDacl
objDomain.Put "ntSecurityDescriptor", Array(objDescriptor)
objDomain.SetInfo

WScript.Echo "SUCCESS!"
List-ACEs.vbs
This script lists or removes the ACEs that are configured on BitLocker and TPM schema objects for the top-level domain. This enables you to verify that the expected ACEs have been added appropriately or to remove any ACEs that are related to BitLocker or the TPM, if necessary.
'===============================================================================
'
' This script lists the access control entries (ACE's) configured on 
' Trusted Platform Module (TPM) and BitLocker Drive Encryption (BDE) schema objects 
' for the top-level domain.
'
' You can use this script to check that the correct permissions have been set and
' to remove TPM and BitLocker ACE's from the top-level domain.
'
' 
' Last Updated: 12/05/2012
' Last Reviewed: 12/02/2012
'
' Microsoft Corporation
'
' Disclaimer
' 
' The sample scripts are not supported under any Microsoft standard support program
' or service. The sample scripts are provided AS IS without warranty of any kind. 
' Microsoft further disclaims all implied warranties including, without limitation, 
' any implied warranties of merchantability or of fitness for a particular purpose. 
' The entire risk arising out of the use or performance of the sample scripts and 
' documentation remains with you. In no event shall Microsoft, its authors, or 
' anyone else involved in the creation, production, or delivery of the scripts be 
' liable for any damages whatsoever (including, without limitation, damages for loss 
' of business profits, business interruption, loss of business information, or 
' other pecuniary loss) arising out of the use of or inability to use the sample 
' scripts or documentation, even if Microsoft has been advised of the possibility 
' of such damages.
'
' Version 1.0.2 - Tested and re-released for Windows 8 and Windows Server 2012
' 
'===============================================================================

' --------------------------------------------------------------------------------
' Usage
' --------------------------------------------------------------------------------

Sub ShowUsage
   Wscript.Echo "USAGE: List-ACEs"
   Wscript.Echo "List access permissions for BitLocker and TPM schema objects"
   Wscript.Echo ""
   Wscript.Echo "USAGE: List-ACEs -remove"
   Wscript.Echo "Removes access permissions for BitLocker and TPM schema objects"
   WScript.Quit
End Sub


' --------------------------------------------------------------------------------
' Parse Arguments
' --------------------------------------------------------------------------------

Set args = WScript.Arguments

Select Case args.Count
  
  Case 0
      ' do nothing - checks for ACE's 
      removeACE = False
      
  Case 1
    If args(0) = "/?" Or args(0) = "-?" Then
      ShowUsage
    Else 
      If UCase(args(0)) = "-REMOVE" Then
            removeACE = True
      End If
    End If

  Case Else
    ShowUsage

End Select

' --------------------------------------------------------------------------------
' Configuration of the filter to show/remove only ACE's for BDE and TPM objects
' --------------------------------------------------------------------------------

'- ms-TPM-OwnerInformation attribute
SCHEMA_GUID_MS_TPM_OWNERINFORMATION = "{AA4E1A6D-550D-4E05-8C35-4AFCB917A9FE}"

'- ms-FVE-RecoveryInformation object
SCHEMA_GUID_MS_FVE_RECOVERYINFORMATION = "{EA715D30-8F53-40D0-BD1E-6109186D782C}"

' Use this filter to list/remove only ACEs related to TPM and BitLocker

aceGuidFilter = Array(SCHEMA_GUID_MS_TPM_OWNERINFORMATION, _
                      SCHEMA_GUID_MS_FVE_RECOVERYINFORMATION)


' Note to script source reader:
' Uncomment the following line to turn off the filter and list all ACEs
'aceGuidFilter = Array()


' --------------------------------------------------------------------------------
' Helper functions related to the list filter for listing or removing ACE's
' --------------------------------------------------------------------------------

Function IsFilterActive()

    If Join(aceGuidFilter) = "" Then
       IsFilterActive = False
    Else 
       IsFilterActive = True
    End If

End Function


Function isAceWithinFilter(ace) 

    aceWithinFilter = False  ' assume first not pass the filter

    For Each guid In aceGuidFilter 

        If ace.ObjectType = guid Or ace.InheritedObjectType = guid Then
           isAceWithinFilter = True           
        End If
    Next

End Function

Sub displayFilter
    For Each guid In aceGuidFilter
       WScript.echo guid
    Next
End Sub


' --------------------------------------------------------------------------------
' Connect to Discretional ACL (DACL) for domain object
' --------------------------------------------------------------------------------

Set objRootLDAP = GetObject("LDAP://rootDSE")
strPathToDomain = "LDAP://" & objRootLDAP.Get("defaultNamingContext") ' e.g. dc=fabrikam,dc=com

Set domain = GetObject(strPathToDomain)

WScript.Echo "Accessing object: " + domain.Get("distinguishedName")
WScript.Echo ""

Set descriptor = domain.Get("ntSecurityDescriptor")
Set dacl = descriptor.DiscretionaryAcl


' --------------------------------------------------------------------------------
' Show Access Control Entries (ACE's)
' --------------------------------------------------------------------------------

' Loop through the existing ACEs, including all ACEs if the filter is not active

i = 1 ' global index
c = 0 ' found count - relevant if filter is active

For Each ace In dacl

 If IsFilterActive() = False or isAceWithinFilter(ace) = True Then

    ' note to script source reader:
    ' echo i to show the index of the ACE
    
    WScript.echo ">            AceFlags: " & ace.AceFlags
    WScript.echo ">             AceType: " & ace.AceType
    WScript.echo ">               Flags: " & ace.Flags
    WScript.echo ">          AccessMask: " & ace.AccessMask
    WScript.echo ">          ObjectType: " & ace.ObjectType
    WScript.echo "> InheritedObjectType: " & ace.InheritedObjectType
    WScript.echo ">             Trustee: " & ace.Trustee
    WScript.echo ""


    if IsFilterActive() = True Then
      c = c + 1

      ' optionally include this ACE in removal list if configured
      ' note that the filter being active is a requirement since we don't
      ' want to accidentally remove all ACEs

      If removeACE = True Then
        dacl.RemoveAce ace  
      End If

    end if

  End If 

  i = i + 1

Next


' Display number of ACEs found

If IsFilterActive() = True Then

  WScript.echo c & " ACE(s) found in " & domain.Get("distinguishedName") _
                 & " related to BitLocker and TPM" 'note to script source reader: change this line if you configure your own 

filter

  ' note to script source reader: 
  ' uncomment the following lines if you configure your own filter
  'WScript.echo ""
  'WScript.echo "The following filter was active: "
  'displayFilter
  'Wscript.echo ""

Else

  i = i - 1
  WScript.echo i & " total ACE(s) found in " & domain.Get("distinguishedName")
  
End If


' --------------------------------------------------------------------------------
' Optionally remove ACE's on a filtered list
' --------------------------------------------------------------------------------

if removeACE = True and IsFilterActive() = True then

  descriptor.DiscretionaryAcl =  dacl
  domain.Put "ntSecurityDescriptor", Array(descriptor)
  domain.setInfo

  WScript.echo c & " ACE(s) removed from " & domain.Get("distinguishedName")

else 

  if removeACE = True then

    WScript.echo "You must specify a filter to remove ACEs from " & domain.Get("distinguishedName") 
 
 end if


end if
Get-TPMOwnerInfo.vbs
This script retrieves TPM recovery information from AD DS for a particular computer so that you can verify that only domain administrators (or delegated roles) can read backed up TPM recovery information and verify that the information is being backed up correctly.
'=================================================================================
'
' This script demonstrates the retrieval of Trusted Platform Module (TPM) 
' recovery information from Active Directory for a particular computer.
'
' It returns the TPM owner information stored as an attribute of a 
' computer object.
'
' Last Updated: 12/05/2012
' Last Reviewed: 12/05/2012
'
' Microsoft Corporation
'
' Disclaimer
' 
' The sample scripts are not supported under any Microsoft standard support program
' or service. The sample scripts are provided AS IS without warranty of any kind. 
' Microsoft further disclaims all implied warranties including, without limitation, 
' any implied warranties of merchantability or of fitness for a particular purpose. 
' The entire risk arising out of the use or performance of the sample scripts and 
' documentation remains with you. In no event shall Microsoft, its authors, or 
' anyone else involved in the creation, production, or delivery of the scripts be 
' liable for any damages whatsoever (including, without limitation, damages for loss 
' of business profits, business interruption, loss of business information, or 
' other pecuniary loss) arising out of the use of or inability to use the sample 
' scripts or documentation, even if Microsoft has been advised of the possibility 
' of such damages.
'
' Version 1.0 - Initial release
' Version 1.1 - Updated GetStrPathToComputer to search the global catalog.
' Version 1.1.2 - Tested and re-released for Windows 8 and Windows Server 2012
' 
'=================================================================================


' --------------------------------------------------------------------------------
' Usage
' --------------------------------------------------------------------------------

Sub ShowUsage
   Wscript.Echo "USAGE: Get-TpmOwnerInfo [Optional Computer Name]"
   Wscript.Echo "If no computer name is specified, the local computer is assumed."
   WScript.Quit
End Sub

' --------------------------------------------------------------------------------
' Parse Arguments
' --------------------------------------------------------------------------------

Set args = WScript.Arguments

Select Case args.Count
  
  Case 0
      ' Get the name of the local computer      
      Set objNetwork = CreateObject("WScript.Network")
      strComputerName = objNetwork.ComputerName
    
  Case 1
    If args(0) = "/?" Or args(0) = "-?" Then
      ShowUsage
    Else
      strComputerName = args(0)
    End If
  
  Case Else
    ShowUsage

End Select


' --------------------------------------------------------------------------------
' Get path to Active Directory computer object associated with the computer name
' --------------------------------------------------------------------------------

Function GetStrPathToComputer(strComputerName) 

    ' Uses the global catalog to find the computer in the forest
    ' Search also includes deleted computers in the tombstone

    Set objRootLDAP = GetObject("LDAP://rootDSE")
    namingContext = objRootLDAP.Get("defaultNamingContext") ' e.g. string dc=fabrikam,dc=com    

    strBase = "<GC://" & namingContext & ">"
 
    Set objConnection = CreateObject("ADODB.Connection") 
    Set objCommand = CreateObject("ADODB.Command") 
    objConnection.Provider = "ADsDSOOBject" 
    objConnection.Open "Active Directory Provider" 
    Set objCommand.ActiveConnection = objConnection 

    strFilter = "(&(objectCategory=Computer)(cn=" &  strComputerName & "))"
    strQuery = strBase & ";" & strFilter  & ";distinguishedName;subtree" 

    objCommand.CommandText = strQuery 
    objCommand.Properties("Page Size") = 100 
    objCommand.Properties("Timeout") = 100
    objCommand.Properties("Cache Results") = False 

    ' Enumerate all objects found. 

    Set objRecordSet = objCommand.Execute 
    If objRecordSet.EOF Then
      WScript.echo "The computer name '" &  strComputerName & "' cannot be found."
      WScript.Quit 1
    End If

    ' Found object matching name

    Do Until objRecordSet.EOF 
      dnFound = objRecordSet.Fields("distinguishedName")
      GetStrPathToComputer = "LDAP://" & dnFound
      objRecordSet.MoveNext 
    Loop 


    ' Clean up. 
    Set objConnection = Nothing 
    Set objCommand = Nothing 
    Set objRecordSet = Nothing 

End Function

' --------------------------------------------------------------------------------
' Securely access the Active Directory computer object using Kerberos
' --------------------------------------------------------------------------------

Set objDSO = GetObject("LDAP:")
strPath = GetStrPathToComputer(strComputerName)


WScript.Echo "Accessing object: " + strPath

Const ADS_SECURE_AUTHENTICATION = 1
Const ADS_USE_SEALING = 64 '0x40
Const ADS_USE_SIGNING = 128 '0x80

Set objComputer = objDSO.OpenDSObject(strPath, vbNullString, vbNullString, _
                                   ADS_SECURE_AUTHENTICATION + ADS_USE_SEALING + ADS_USE_SIGNING)

' --------------------------------------------------------------------------------
' Get the TPM owner information from the Active Directory computer object
' --------------------------------------------------------------------------------

strOwnerInformation = objComputer.Get("msTPM-OwnerInformation")
WScript.echo "msTPM-OwnerInformation: " + strOwnerInformation
