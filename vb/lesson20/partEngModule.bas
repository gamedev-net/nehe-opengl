Attribute VB_Name = "maskingModule"
'----------------------------------------------------------
'Comments , suggestions, help and all other things you want to know
'about this project: fredo@studenten.net
'----------------------------------------------------------

Public ghDC As Long                 'needs to be declared public for the swapbuffers command
Public ghRC As Long                 'maybe needed to switch contexts, not need to be declared public in this project
Public Sub showMsg(msg As String)

MsgBox msg, vbCritical + vbOKOnly

End Sub
