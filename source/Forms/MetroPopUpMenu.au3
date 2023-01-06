; MetroPopUpMenu.au3
; For middle mouse button pop up.
Global $gbMetroPopMenuOpen

Func MetroPopUpMenu()
	Local $aPos = MouseGetPos()
	; create the form.
	Local $iGuiX = $aPos[0], $iGuiY = $aPos[1]
	#include "MetroPopup.isf"
	Local $aButtonIDs = [ $btnMetroPlay, $btnMetroAddToList, $btnMetroSendList, _
						$btnMetroEditList, $btnMetroCreateMovie, $btnMetroFetchInfo, $btnMetroCancel]
	GUISetIcon("helper2.ico")
	GUISetState()
	While True 
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE, $btnMetroCancel
				ExitLoop

			Case $btnMetroPlay
				$sCatNo = GetCurrentTabCategoryAndNumber()
				If StringInStr($sCatNo, "-") = 0 Then 
					MsgBox(0, "Not support", "You are in category: " & $sCatNo & ". You need to browse to one scene or movie.")
				Else
					$aCatNo = StringSplit($sCatNo, "-")
					If $aCatNo[0] = 2 and StringIsDigit( $aCatNo[2]) Then 
						Switch $aCatNo[1]
							Case "scenes", "movies", "images", "galleries"
							GUISetState( @SW_HIDE, $guiMetroPopup )
							PlayCurrentTab()
							ExitLoop 
						EndSwitch
					EndIf 
					c( "$sCatNo:" & $sCatNo)
					MsgBox(262192,"Not supported","The current page is not supported.",0)
					ContinueLoop 

				EndIf				
				
			Case $btnMetroAddToList
				$sCatNo = GetCurrentTabCategoryAndNumber()
				If StringInStr($sCatNo, "-") = 0 Then 
					MsgBox(0, "Not support", "You are in category: " & $sCatNo & ". You need to browse to one scene or movie.")
				Else
					$aCatNo = StringSplit($sCatNo, "-")
					If $aCatNo[0] = 2 And StringIsDigit( $aCatNo[2] ) Then 
						Switch $aCatNo[1]
							Case "scenes", "movies", "images", "galleries"
								GUISetState( @SW_HIDE, $guiMetroPopup )
								AddItemToList()
								ExitLoop 
						EndSwitch
					EndIf 
					c( "$sCatNo:" & $sCatNo)
					MsgBox(262192,"Not supported","The current page is not supported.",0)
					ContinueLoop 
				EndIf				
				
			Case $btnMetroSendList
				GUISetState( @SW_HIDE, $guiMetroPopup )
				SendPlayerList()
				ExitLoop 
			Case $btnMetroEditList
				GUISetState( @SW_HIDE, $guiMetroPopup )
				ManagePlayList()
				ExitLoop 
			Case $btnMetroCreateMovie
				$sCatNo = GetCurrentTabCategoryAndNumber()
				If StringInStr($sCatNo, "-") = 0 Then 
					MsgBox(0, "Not support", "You are in category: " & $sCatNo & ". You need to browse to one scene.")
				Else
					$aCatNo = StringSplit($sCatNo, "-")
					If $aCatNo[0] = 2 And $aCatNo[1] = "scenes" And StringIsDigit( $aCatNo[2] ) Then 
							GUISetState( @SW_HIDE, $guiMetroPopup )
							Scene2Movie()
							ExitLoop 
					Else
							c( "$sCatNo:" & $sCatNo)
							MsgBox(262192,"Not supported","The current category: " & $aCatNo[1] & " is not supported.",0)
							ContinueLoop 
					EndIf 
				EndIf				
			Case $btnMetroFetchInfo
				MsgBox(0, "In progress...", "Working on this feature.", 10)
				ExitLoop 
		EndSwitch
		If Not WinActive($guiMetroPopup) Then WinActivate($guiMetroPopup)
		MetroHover( $guiMetroPopup )
		Sleep(10)
	Wend
	GUIDelete($guiMetroPopup)
	MetroHover( $guiMetroPopup, True) ; Reset hover 
EndFunc

; Set the hover effect for the metro buttons.
; $aButtonIDs are the array of button control ids.
Func MetroHover( $guiMetro, $bReset = False )
	; Judge if the mouse is over the button and return the button number, or 0
	Static $iCurrentButton = 0 ; 0: Outside, or button id.
	If $bReset Then 
		$iCurrentButton = 0
		return
	EndIf
	$aPos = GUIGetCursorInfo($guiMetro)
	If @error Then Return 	; Maybe outside

	If $aPos[4] = 0 Then 
		; Cursor is ourside
		If $iCurrentButton Then 
			; A button was changed, restore it.
			MetroNormalButton( $iCurrentButton )
			$iCurrentButton = 0
		EndIf
	Else
		; inside the gui
		If $iCurrentButton <> $aPos[4] Then
			If $iCurrentButton Then
				; Restore the previous button to normal
				MetroNormalButton( $iCurrentButton )
			Else
				; previously outside
			EndIf
			MetroHoverButton( $aPos[4] )	; Hover effect for new button
			$iCurrentButton = $aPos[4]
		EndIf
	EndIf
	
EndFunc

Func MetroHoverButton($iControlID)
	; Set the button to hover style
	GUICtrlSetBkColor( $iControlID, 0xFFFF99)
	GUICtrlSetColor( $iControlID, 0x000000)
EndFunc

Func MetroNormalButton($iControlID)
	; Set the button to normal style
	GUICtrlSetBkColor( $iControlID, 0x202B33)
	GUICtrlSetColor( $iControlID, 0xFFFFFF)
EndFunc