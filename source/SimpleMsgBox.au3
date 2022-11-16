;SimpleMsgBox.au3

;===========================================================================================
;
; Usage: _DisplayMsg($text,$button,[msgwidth,[msgheight,[msgxpos,[msgypos]]]])
;
; Where:
;     $text    =  The text to be displayed. Long lines will wrap. The text will also
;                    be centered.
;     $button    =  The text for the buttons. Seperate buttons with the
;                    pipe (|) character. To set a button as the default button,
;                    place the ampersand (&) character before the word. If you
;                    put more than 1 ampersand character, the function will
;                    fail and return -1, plus set @error to 1
;     msgwidth  =  Width of the displayed window. This value will be automatically
;                    increased if the resulting window will not be wide enough to
;                    accommodate the buttons requested. Default is 250
;     msgheight   =  Height of the displayed window. This is not adjusted. If the
;                    text is too big, it will not display it all. Default is 80
;     msgxpos    =  Where you want the window positioned horizontally. Default is centered.
;     msgypos    =  Where you want the window positioned vertically. Default is centered.
;
;	  hParent	=	The parent GUI
;     Success:  Returns the button pressed, starting at 1, counting from the LEFT.
;     Failure:  Returns 0 if more than 1 default button is set, or an error with the window
;                 occurs.
;
;===========================================================================================
; #include <GuiConstants.au3>

Func _SimpleMsgBox($text, $button,$msgwidth=300, $msgheight=120, $msgxpos=-1,$msgypos=-1 )
	; Global $gdScale.
	$msgwidth *= $gdScale
	$msgheight *= $gdScale
    Local $buttonarray,$msgbutton[5]=[1,1,1,1,1],$buttoncount,$defbutton=0
    If StringInStr($button,"&",0,2)<>0 Then
        SetError(1)
        Return 0
    EndIf
    $buttonarray=StringSplit($button,"|")
    If $buttonarray[0]>5 Then $buttonarray[0]=5
    If 88*$buttonarray[0] * $gdScale +8 > $msgwidth Then
        $msgwidth=88*$buttonarray[0] * $gdScale + 8
    EndIf
    $msggui = GUICreate("", $msgwidth, $msgheight, $msgxpos, $msgypos, $WS_popup + $WS_DLGframe, $WS_EX_TOOLWINDOW + $WS_EX_TOPMOST)
    If $msggui=0 Then Return 0
    GUICtrlCreateLabel($text, 8, 8, $msgwidth-16, $msgheight-40, $SS_CENTER)
    $buttonxpos=(($msgwidth/$buttonarray[0])-80 * $gdScale)/2
    For $buttoncount=0 To $buttonarray[0]-1
        $buttonwork=$buttonarray[$buttoncount+1]
        If StringLeft($buttonwork,1)="&" Then
            $defbutton=$BS_DEFPUSHBUTTON
            $buttonarray[$buttoncount+1]="[ " & StringTrimLeft($buttonwork,1) & " ]"
        EndIf
        $msgbutton[$buttoncount] = GUICtrlCreateButton($buttonarray[$buttoncount+1], $buttonxpos+($buttoncount*80 * $gdScale)+($buttoncount*$buttonxpos*2), $msgheight-32 * $gdScale, 80 * $gdScale, 24 * $gdScale,$defbutton)
        $defbutton=0
    Next
    GUISetState()
    While 1
        $mmsg = GUIGetMsg()
        Select
            Case $mmsg = $msgbutton[0]
                GUIDelete($msggui)
                Return 1
            Case $mmsg = $msgbutton[1]
                GUIDelete($msggui)
                Return 2
            Case $mmsg = $msgbutton[2]
                GUIDelete($msggui)
                Return 3
            Case $mmsg = $msgbutton[3]
                GUIDelete($msggui)
                Return 4
            Case $mmsg = $msgbutton[4]
                GUIDelete($msggui)
                Return 5
        EndSelect
    WEnd
EndFunc