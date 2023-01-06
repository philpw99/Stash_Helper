; MetroPopUpMenu.au3
; For middle mouse button pop up.
Global $gbMetroPopMenuOpen

Func MetroPopUpMenu()
	Local $aPos = MouseGetPos()
	; create the form.
	Local $iGuiX = $aPos[0], $iGuiY = $aPos[1]
	#include "MetroPopup.isf"
	GUISetState()
	While True 
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE, $btnMetroCancel
				ExitLoop

			Case $btnMetroPlay
				Local $sCat = GetCategory( GetURL() )
				Switch $sCat
					Case "scenes", "movies", "images", "galleries"
						GUISetState( @SW_HIDE, $guiMetroPopup )
						PlayCurrentTab()
						ExitLoop 
					Case Else
						MsgBox(262192,"Not supported","The current category: " & $sCat & " is not supported.",0)
						ContinueLoop 
				EndSwitch
				
			Case $btnMetroAddToList
				Local $sCat = GetCategory( GetURL() )
				Switch $sCat
					Case "scenes", "movies", "images", "galleries"
						GUISetState( @SW_HIDE, $guiMetroPopup )
						AddItemToList()
						ExitLoop 
					Case Else
						MsgBox(262192,"Not supported","The current category: " & $sCat & " is not supported.",0)
						ContinueLoop 
				EndSwitch
				
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
				$aCatNo = StringSplit($sCatNo, "-")
				If $aCatNo[0] = "scenes" And StringIsDigit( $aCatNo[1] ) Then 
						GUISetState( @SW_HIDE, $guiMetroPopup )
						Scene2Movie()
						ExitLoop 
				Else
						MsgBox(262192,"Not supported","The current category: " & $sCat & " is not supported.",0)
						ContinueLoop 
				EndIf 
				
			Case $btnMetroFetchInfo
				MsgBox(0, "In progress...", "Working on this feature.", 10)
				ExitLoop 
		EndSwitch
	Wend
	GUIDelete($guiMetroPopup)
	
EndFunc

