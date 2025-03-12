Sub GenerateRITMReport()
    Dim olNamespace As Outlook.NameSpace
    Dim ITSMFolder As Outlook.Folder
    Dim email As Outlook.MailItem
    Dim ritmData As Object
    Dim ritmNumber As String
    Dim subject As String
    Dim receivedTime As Date
    Dim firstOccurrence As Date
    Dim lastOccurrence As Date
    Dim reportBody As String
    Dim reportEmail As Outlook.MailItem
    Dim keysArray As Variant
    Dim i As Long
    
    ' Initialize dictionary to store RITM data
    Set ritmData = CreateObject("Scripting.Dictionary")
    
    ' Get the ITSM folder
    Set olNamespace = Application.GetNamespace("MAPI")
    On Error Resume Next
    Set ITSMFolder = olNamespace.GetDefaultFolder(olFolderInbox).Folders("ITSM")
    On Error GoTo 0
    
    ' Check if the ITSM folder was found
    If ITSMFolder Is Nothing Then
        MsgBox "ITSM folder not found. Please check the folder name and try again.", vbExclamation
        Exit Sub
    End If
    
    ' Loop through emails in the ITSM folder
    For Each email In ITSMFolder.Items
        ' Ensure the item is an email
        If email.Class = olMail Then
            subject = email.subject
            If InStr(subject, "RITM") > 0 Then
                ' Extract RITM number from the subject
                ritmNumber = Mid(subject, InStr(subject, "RITM"), 11) ' Assumes RITM number is 11 characters long (e.g., RITM1697763)
                
                ' Get the received time of the email
                receivedTime = email.receivedTime
                
                ' Update first and last occurrence for the RITM number
                If ritmData.Exists(ritmNumber) Then
                    ' Retrieve the existing array from the dictionary
                    firstOccurrence = ritmData(ritmNumber)(0)
                    lastOccurrence = ritmData(ritmNumber)(1)
                    
                    ' Update first and last occurrence
                    If receivedTime < firstOccurrence Then
                        firstOccurrence = receivedTime
                    End If
                    If receivedTime > lastOccurrence Then
                        lastOccurrence = receivedTime
                    End If
                    
                    ' Store the updated array back in the dictionary
                    ritmData(ritmNumber) = Array(firstOccurrence, lastOccurrence)
                Else
                    ' Add new RITM number with first and last occurrence
                    ritmData.Add ritmNumber, Array(receivedTime, receivedTime)
                End If
            End If
        End If
    Next email
    
    ' Check if any RITM data was found
    If ritmData.Count = 0 Then
        MsgBox "No RITM emails found in the ITSM folder.", vbInformation
        Exit Sub
    End If
    
    ' Generate the report body in tabular format
    reportBody = "RITM Number,First Occurrence,Last Occurrence" & vbCrLf
    
    ' Get the keys from the dictionary and iterate over them
    keysArray = ritmData.Keys
    For i = LBound(keysArray) To UBound(keysArray)
        ritmNumber = keysArray(i)
        firstOccurrence = ritmData(ritmNumber)(0)
        lastOccurrence = ritmData(ritmNumber)(1)
        reportBody = reportBody & ritmNumber & "," & Format(firstOccurrence, "yyyy-mm-dd hh:mm") & "," & Format(lastOccurrence, "yyyy-mm-dd hh:mm") & vbCrLf
    Next i
    
    ' Create and send the report email
    Set reportEmail = Application.CreateItem(olMailItem)
    With reportEmail
        .To = "gokhan.tenekecioglu@me.com" ' Update with your email
        .subject = "RITM Email Dates Report"
        .Body = reportBody
        .Send
    End With
    
    MsgBox "Report generated and sent successfully!", vbInformation
End Sub
