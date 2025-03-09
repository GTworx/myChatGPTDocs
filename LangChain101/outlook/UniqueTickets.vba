Sub SendRITMTicketList()
    Dim olNamespace As Outlook.Namespace
    Dim olFolder As Outlook.MAPIFolder
    Dim olItems As Outlook.Items
    Dim olMail As Outlook.MailItem
    Dim dict As Object
    Dim regExp As Object
    Dim matches As Object
    Dim subjectText As String
    Dim match As Object
    Dim ticketList As Variant
    Dim i As Integer
    Dim output As String
    Dim newMail As Outlook.MailItem
    
    ' Initialize objects
    Set olNamespace = Application.GetNamespace("MAPI")
    Set olFolder = olNamespace.GetDefaultFolder(olFolderInbox).Folders("ITSM")
    Set olItems = olFolder.Items
    Set dict = CreateObject("Scripting.Dictionary")
    Set regExp = CreateObject("VBScript.RegExp")
    
    ' Regular expression to match RITM tickets
    regExp.Pattern = "RITM\d+"
    regExp.Global = True
    
    ' Loop through each email
    For i = 1 To olItems.Count
        If TypeName(olItems(i)) = "MailItem" Then
            Set olMail = olItems(i)
            subjectText = olMail.Subject
            
            ' Find matches
            If regExp.Test(subjectText) Then
                Set matches = regExp.Execute(subjectText)
                For Each match In matches
                    If Not dict.exists(match.Value) Then
                        dict.Add match.Value, 1
                    End If
                Next
            End If
        End If
    Next i
    
    ' Convert dictionary keys to an array
    ticketList = dict.Keys
    
    ' Generate email body content
    If Not IsEmpty(ticketList) Then
        output = "Here is the list of unique RITM tickets found in your ITSM folder:" & vbCrLf & vbCrLf
        For i = LBound(ticketList) To UBound(ticketList)
            output = output & ticketList(i) & vbCrLf
        Next i
    Else
        output = "No RITM tickets found in your ITSM folder."
    End If
    
    ' Create new email
    Set newMail = Application.CreateItem(olMailItem)
    With newMail
        .To = "your-email@domain.com"  ' Change this to your email
        .Subject = "Unique RITM Ticket List"
        .Body = output
        .Send  ' Send the email automatically
    End With
    
    ' Cleanup
    Set olNamespace = Nothing
    Set olFolder = Nothing
    Set olItems = Nothing
    Set dict = Nothing
    Set regExp = Nothing
    Set newMail = Nothing
    
    MsgBox "Email sent with the list of unique RITM tickets!", vbInformation, "Success"
End Sub
