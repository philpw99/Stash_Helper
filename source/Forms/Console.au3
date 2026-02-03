;Console.au3
Opt("GUIOnEventMode", 1)
#include <GuiEdit.au3>
#include "Console.isf"

DllCall("User32.dll","bool","SetProcessDPIAware")

$mGui = _GuiConsole()
GUISetState()

GUISetOnEvent($GUI_EVENT_CLOSE, "ExitWindow")
GUICtrlSetOnEvent($mGui.btnClear, "ClearText")

While True
	$str = ConsoleRead()
	if $str <> "" Then 
		_GUICtrlEdit_AppendText($mGui.edText, $str)
	EndIf
	Sleep(100)
Wend

Func ClearText()
	GUICtrlSetData( $mGui.edText, "")
EndFunc

Func ExitWindow()
	Exit 
EndFunc