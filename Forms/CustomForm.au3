; -- Created with ISN Form Studio 2 for ISN AutoIt Studio -- ;
#include <StaticConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#Include <GuiButton.au3>
; #include <Array.au3>
#include <..\GUIListViewEx.au3>
Global $customList

Func CustomList($sCategory, ByRef $aCategory)
	; sCategory is "Scenes","Movies"...
	; aCategory is the array that contains Item_Handle, Item_Title, Item_Link
	; Global Enum $ITEM_HANDLE, $ITEM_TITLE, $ITEM_LINK
	; Global $iMaxSubItems
		
	$Custom = GUICreate("Customize " & $sCategory,1060,800,-1,-1,-1,-1)
	
	GUICtrlCreateLabel("Customize the list of " & $sCategory & _ 
	  ". This is like bookmarks or favorites for Stash. You paste the link from the address bar, then put a title for it, as the examples you see below." _ 
		  &@crlf&"To edit the list, double-click on the item, type or paste the text then press enter.",80,50,882,196,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")
	
	$customList = GUICtrlCreatelistview("#|  Title|  Query Link",40,270,972,410, _ 
		$LVS_NOSCROLL, _ 
		BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	; #
	_GUICtrlListView_SetColumnWidth($customList, 0, 50)
	; Title
	_GUICtrlListView_SetColumnWidth($customList, 1, 300)
	; _GUICtrlListView_JustifyColumn($customList, 1, 2)
	; Query Link
	_GUICtrlListView_SetColumnWidth($customList, 2, 700)
	; _GUICtrlListView_JustifyColumn($customList, 2, 2)
	
	$btnSave = GUICtrlCreateButton("Save",370,710,238,47,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")

	Local $aList[$iMaxSubItems]
	For $i = 0 to $iMaxSubItems -1
		; Popular all numbers anyway
		$aList[$i] = String($i + 1)
	Next
	For $i = 0 to UBound($aCategory) -1
		$aList[$i] &= "|" & $aCategory[$i][$ITEM_TITLE] & "|" & $aCategory[$i][$ITEM_LINK]
	Next
	
	For $i = 0 to 10
		_GUICtrlListView_AddItem($customList, $i + 1)
	Next
	
	; Populate the list view
	Local $aListHandles[11][2]
	For $i = 0 to UBound($aCategory) -1
		_GUICtrlListView_AddSubItem($customList, $i, $aCategory[$i][$ITEM_TITLE], 1)
		_GUICtrlListView_AddSubItem($customList, $i, $aCategory[$i][$ITEM_LINK], 2)
	Next

	GUISetState(@SW_SHOW, $Custom)
	; Make list view editable
	$iLV_Index = _GUIListViewEx_Init($customList, $aList, 0, 0, True, 2)
	_GUIListViewEx_SetEditStatus($iLV_Index, "1;2", 1, Default)
	_GUIListViewEx_MsgRegister(True, False, False)
	
	; Now do the loop
	While True 
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case 0
				; Nothing should be here.
			Case $customList
				; ConsoleWrite("here" & @CRLF)
			Case $btnSave
				$aRead =  _GUIListViewEx_ReturnArray($iLV_Index)
				; _ArrayDisplay($aRead)
				Local $str = $aRead[0]
				For $i = 1 to 10
					$str &= "@@@" & $aRead[$i]
				Next
				RegWrite("HKEY_CURRENT_USER\Software\Stash_Helper", $sCategory & "List", "REG_SZ", $str)
				; Need to load the Items here.
				ReloadMenu()
				ExitLoop 
			Case $GUI_EVENT_CLOSE
				ExitLoop 
		EndSwitch
		
		_GUIListViewEx_EventMonitor()
	Wend
	GUIDelete($Custom)
	$customList = 0
EndFunc

