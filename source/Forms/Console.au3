;Console.au3
Opt("GUIOnEventMode", 1)
#include <GuiEdit.au3>
#include "Console.isf"

DllCall("User32.dll","bool","SetProcessDPIAware")

$mGui = _GuiConsole()
GUISetState()

GUISetOnEvent($GUI_EVENT_CLOSE, "ExitWindow")
GUICtrlSetOnEvent($mGui.btnClear, "ClearText")
$sText = ""

While True
	$str = ConsoleRead()
	if $str <> "" Then 
		$sText &= $str
		if StringLen($sText) > 25000 Then
			$sText = StringTrimLeft( $sText, 10000 )
			GUICtrlSetData($mGui.edText, $sText)
		Else
			_GUICtrlEdit_AppendText($mGui.edText, $str)
		EndIf
		
	EndIf
	Sleep(100)
Wend

Func ClearText()
	$sText = ""
	GUICtrlSetData( $mGui.edText, "")
EndFunc

Func ExitWindow()
	Exit 
EndFunc