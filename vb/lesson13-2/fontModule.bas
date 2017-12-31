Attribute VB_Name = "FontModule"
'----------------------------------------------------------
'Comments , suggestions, help and all other things you want to know
'about this project: fredo@studenten.net
'Code by Edo
'----------------------------------------------------------

Public ghDC As Long                 'needs to be declared public for the swapbuffers command
Public ghRC As Long                 'maybe needed to switch contexts, not need to be declared public in this project
Public Sub showMsg(msg As String)

MsgBox msg, vbCritical + vbOKOnly

End Sub
