Attribute VB_Name = "partEngModule"
'----------------------------------------------------------
'Comments , suggestions, help and all other things you want to know
'about this project: fredo@studenten.net
'----------------------------------------------------------

Public ghDC As Long                 'needs to be declared public for the swapbuffers command
Public ghRC As Long                 'maybe needed to switch contexts, not need to be declared public in this project
Public Sub showMsg(msg As String)

MsgBox msg, vbCritical + vbOKOnly

End Sub
Public Function log2(ByVal a As Single) As Double

'needed for right texture size
log2 = Log(a) / Log(2)

End Function

