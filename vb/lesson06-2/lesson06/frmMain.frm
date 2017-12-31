VERSION 5.00
Begin VB.Form frmMain 
   ClientHeight    =   7200
   ClientLeft      =   60
   ClientTop       =   60
   ClientWidth     =   9015
   ControlBox      =   0   'False
   KeyPreview      =   -1  'True
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   480
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   601
   ShowInTaskbar   =   0   'False
   StartUpPosition =   3  'Windows Default
End
Attribute VB_Name = "frmMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'frmMain.frm - Main Window for application

'Note:  KeyPreview must be set to TRUE in order to intercept key presses from the user.

Option Explicit


Private Sub Form_KeyDown(KeyCode As Integer, Shift As Integer)
'Indicate that the key given in KeyCode has been pressed

  gbKeys(KeyCode) = True
End Sub

Private Sub Form_Resize()
  ReSizeGLScene ScaleWidth, ScaleHeight
End Sub

Private Sub Form_Unload(Cancel As Integer)
'Destroy the OpenGL window associations
  KillGLWindow Me
End Sub

