Sub SendRITMTicketReport()
    Dim olNamespace As Outlook.NameSpace
    Dim olFolder As Outlook.MAPIFolder
    Dim olItems As Outlook.Items
    Dim olMail As Outlook.MailItem
    Dim dict As Object
    Dim regExp As Object
    Dim matches As Object
    Dim subjectText As String
    Dim match As Object
    Dim ticket As String
    Dim firstDate As Date
    Dim lastDate As Date
    Dim i As Integer
    Dim newMail As Outlook.MailItem
    Dim emailBody As String
    Dim ticketList As Variant
    
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
                    ticket = match.Value
                    If Not dict.exists(ticket) Then
                        ' Store first and last occurrence in an array
                        dict.Add ticket, Array(olMail.ReceivedTime, olMail.ReceivedTime)
                    Else
                        ' Update first and last occurrence
                        firstDate = dict(ticket)(0)
                        lastDate = dict(ticket)(1)
                        If olMail.ReceivedTime < firstDate Then dict(ticket)(0) = olMail.ReceivedTime
                        If olMail.ReceivedTime > lastDate Then dict(ticket)(1) = olMail.ReceivedTime
                    End If
                Next
            End If
        End If
    Next i
    
    ' Convert dictionary keys to an array
    ticketList = dict.Keys
    
    ' Generate email body (HTML Table)
    emailBody = "<html><body>"
    emailBody = emailBody & "<h3>Unique RITM Ticket Report</h3>"
    emailBody = emailBody & "<table border='1' cellspacing='0' cellpadding='5'>"
    emailBody = emailBody & "<tr><th>Ticket</th><th>First Email</th><th>Last Email</th></tr>"
    
    ' Loop through dictionary keys using an indexed loop
    If Not IsEmpty(ticketList) Then
        For i = LBound(ticketList) To UBound(ticketList)
            ticket = ticketList(i)
            emailBody = emailBody & "<tr>"
            emailBody = emailBody & "<td>" & ticket & "</td>"
            emailBody = emailBody & "<td>" & dict(ticket)(0) & "</td>"
            emailBody = emailBody & "<td>" & dict(ticket)(1) & "</td>"
            emailBody = emailBody & "</tr>"
        Next i
    End If

    emailBody = emailBody & "</table></body></html>"
    
    ' Create and send email
    Set newMail = Application.CreateItem(olMailItem)
    With newMail
        .To = "gokhan.tenekecioglu@oriola.com"  ' Change to your email
        .Subject = "RITM Ticket Report"
        .HTMLBody = emailBody
        .Send  ' Sends the email
    End With
    
    ' Cleanup
    Set olNamespace = Nothing
    Set olFolder = Nothing
    Set olItems = Nothing
    Set dict = Nothing
    Set regExp = Nothing
    Set newMail = Nothing
    
    MsgBox "Email sent with RITM ticket report!", vbInformation, "Success"
End Sub
