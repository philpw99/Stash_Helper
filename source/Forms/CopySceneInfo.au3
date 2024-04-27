#include "CopySceneInfo.isf"

Func CopySceneInfo()
	; Global $mInfo

	Local $sURL = _WD_Action($sSession, "url")
	Local $nScene = GetNumber($sURL, "scenes")
	If @error Then
		MsgBox(48,"Not A Scene Page","The current webpage showing: " & @CRLF _
		& $sURL & @CRLF & "is not a scene's URL.",0)
		Return SetError(2)
	EndIf
	; Get Scene info will set the global $mInfo
	GetSceneInfo($nScene)
	If @error Then Return SetError(3)
	
	; Now $mInfo should have the current scene info
	
	; Create the gui and show
	Local $mGui = _guiCopySceneInfo()
	GUICtrlSetData( $mGui["lbCurrentSceneID"], "Current Scene ID: " & $mInfo.Item("SceneID") )
	GUICtrlSetData( $mGui["lbCurrentTitle"], "Current Title: " & $mInfo.Item("Title") )

	; Retrieve value here from the map. Map is slow for loops.
	Local $btnCancel = $mGui["btnCancel"], $btnOK = $mGui["btnOK"], $btnGetInfo = $mGui["btnGetInfo"]
	Local $lvSceneValues = $mGui["lvSceneValues"]
	
	; Set List view column width
	_GUICtrlListView_SetColumnWidth( $lvSceneValues, 0, 40 )  	; #
	_GUICtrlListView_SetColumnWidth( $lvSceneValues, 1, 200 )	; Property
	_GUICtrlListView_SetColumnWidth( $lvSceneValues, 2, 450 )	; Value
	
	GUISetState( @SW_SHOW, $mGui["guiCopySceneInfo"] )
	
	; Message loop for GUI
	While True
		Switch GUIGetMsg()
			
			Case $GUI_EVENT_CLOSE, $btnCancel
				ExitLoop 
			
			Case $btnGetInfo
				Local $nNum = GUICtrlRead( $mGui["inputSceneID"])
				If Not StringIsDigit($nNum) Then 
					MsgBox(48,"Scene ID should be a number","Please put in a number for the scene ID.",0)
					ContinueLoop
				EndIf
				SetSceneInfoToListView($lvSceneValues, $nNum)
				MsgBox(262192,"Under construction","This feature is surprisingly complicated. Need more time to work on it.",0)

			Case $btnOK
				MsgBox(262192,"Under construction","This feature is surprisingly complicated. Need more time to work on it.",0)
				
		EndSwitch
		
	Wend
	
	GUIDelete()
	
EndFunc

Func SetSceneInfoToListView($lvScene, $nNum)
	; $nNum should be the scene id number
	$nNum = StringStripWS($nNum, 8)
	GetSceneInfo($nNum)
	If @error Then Return SetError(1)
	
	
	
EndFunc

