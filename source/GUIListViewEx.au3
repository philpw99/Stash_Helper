#include-once

; #INDEX# ============================================================================================================
; Title .........: GUIListViewEx
; AutoIt Version : 3.3.10 +
; Language ......: English
; Description ...: Permits insertion, deletion, moving, dragging, sorting, editing and colouring of items within ListViews
; Remarks .......: - It is important to use _GUIListViewEx_Close when a enabled ListView is deleted to free the memory used
;                    by the $aGLVEx_Data array which shadows the ListView contents.
;                  - _GUIListViewEx_EventMonitor must be placed in the script idel loop if editing or using colour
;                  - Windows message handlers required:
;                     - WM_NOTIFY: All UDF functions
;                     - WM_MOUSEMOVE and WM_LBUTTONUP: Only needed if dragging
;                     - WM_SYSCOMMAND: Permits immediate [X] GUI closure while editing
;                  - If the script already has WM_NOTIFY, WM_MOUSEMOVE, WM_LBUTTONUP or WM_SYSCOMMAND handlers then only set
;                    unregistered messages in _GUIListViewEx_MsgRegister and call the relevant _GUIListViewEx_WM_#####_Handler
;                    from within the existing handler
;                  - Uses 2 undocumented functions within GUIListView UDF to set and colour insert mark (thanks rover)
;                  - Enabling user colours significantly slows ListView redrawing
; Author ........: Melba23
; Credits .......: martin (basic drag code), Array.au3 authors (array functions), KaFu and ProgAndy (font function)
;                  LarsJ (colouring code)
; ====================================================================================================================

;#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w- 4 -w 5 -w 6 -w- 7

; #INCLUDES# =========================================================================================================
#include <GuiListView.au3>
#include <GUIImageList.au3>
#include <WinAPISys.au3>

; #GLOBAL VARIABLES# =================================================================================================
; Array to hold registered ListView data
Global $aGLVEx_Data[1][27] = [[0, 0, -1, "", -1, -1, -1, -1, _WinAPI_GetSystemMetrics(2), False, _
		 -1, -1, False, "", 0, True, 0, -1, -1, 0, 0, 0, 0, "08"]]
; [0][0]  = ListView Count      [n][0]  = ListView handle
; [0][1]  = Active Index        [n][1]  = Native ListView ControlID / 0
; [0][2]  = Active Column       [n][2]  = Shadow array
; [0][3]  = Row Depth           [n][3]  = Shadow array count element (0/1) & 2D return (+ 2)
; [0][4]  = Curr ToolTip Row    [n][4]  = Sort status
; [0][5]  = Curr ToolTip Col    [n][5]  = Drag image flag
; [0][6]  = Prev ToolTip Row    [n][6]  = Checkbox array flag
; [0][7]  = Prev ToolTip Col    [n][7]  = Editable columns data
; [0][8]  = VScrollbar width    [n][8]  = Editable header flag
; [0][9]  = SysClose flag       [n][9]  = Continue edit on click flag
; [0][10] = RtClick Row         [n][10] = Item depth for scrolling
; [0][11] = RtClick Col         [n][11] = Do not "select all" on edit flag
; [0][12] = Colour Handler Flag [n][12] = Drag/drop status flag
; [0][13] = Active Colour Array [n][13] = Header drag style flag
; [0][14] = Curr Redraw Handle  [n][14] = Edit width array
; [0][15] = Allow Redraw Flag   [n][15] = ToolTip column range
; [0][16] = KeyCode             [n][16] = ToolTip display time
; [0][17] = Active Row          [n][17] = ToolTip mode
; [0][18] = Active Column       [n][18] = Colour array
; [0][19] = Sort Flag           [n][19] - Colour flag
; [0][20] = Curr header handle  [n][20] - Active row
; [0][21] = Curr header font    [n][21] - Active column
; [0][22] = Colour redraw flag  [n][22] - Single cell flag
; [0][23] = Start edit keycode  [n][23] - Default user colours
; [0][24] = Separator char      [n][24] - Header colour flag (handle)
;                               [n][25] - Header data array
;                               [n][26] - Edit field colour

; Variables for UDF handlers
Global $hGLVEx_SrcHandle, $cGLVEx_SrcID, $iGLVEx_SrcIndex, $aGLVEx_SrcArray, $aGLVEx_SrcColArray
Global $hGLVEx_TgtHandle, $cGLVEx_TgtID, $iGLVEx_TgtIndex, $aGLVEx_TgtArray, $aGLVEx_TgtColArray
Global $iGLVEx_Dragging = 0, $iGLVEx_DraggedIndex, $hGLVEx_DraggedImage = 0, $sGLVEx_DragEvent
Global $iGLVEx_InsertIndex = -1, $iGLVEx_LastY, $fGLVEx_BarUnder, $fGVLEx_Resized = -1
; Variables for UDF edit
Global $hGLVEx_Editing, $cGLVEx_EditID = 9999, $fGLVEx_EditClickFlag = 0, $fGLVEx_HeaderEdit = False
; Flags for user selection indication
Global $fGLVEx_SelChangeFlag = 0, $fGLVEx_UserSelFlag = 0
; Predefined user colours [Normal text, normal field, selected cell text, selected cell field] - BGR
Global $aGLVEx_DefColours[4] = ["0x000000", "0xFEFEFE", "0xFFFFFF", "0xCC6600"]

; #CURRENT# ==========================================================================================================
; _GUIListViewEx_Init:                  Enables UDF functions for the ListView and sets various flags
; _GUIListViewEx_Close:                 Disables all UDF functions for the specified ListView and clears all memory used
; _GUIListViewEx_SetActive:             Set specified ListView as active for non-specific UDF functions
; _GUIListViewEx_GetActive:             Get index number of active ListView for non-specific UDF functions
; _GUIListViewEx_ReadToArray:           Creates an array from the current ListView content to be loaded in _Init function
; _GUIListViewEx_ReturnArray:           Returns an array of the current content, checkbox state, colour of the ListView
; _GUIListViewEx_SaveListView:          Saves ListView header data, ListView content, checkbox state and colour data to file
; _GUIListViewEx_LoadListView:          Loads ListView header data, ListView content, checkbox state and colour data from file
; _GUIListViewEx_Up:                    Moves selected row(s) in active ListView up 1 row
; _GUIListViewEx_Down:                  Moves selected row(s) in active ListView down 1 row
; _GUIListViewEx_Insert:                Inserts data in row below selected row in active ListView
; _GUIListViewEx_InsertSpec:            Inserts data in specified row in specified ListView
; _GUIListViewEx_Delete:                Deletes selected row(s) in active ListView
; _GUIListViewEx_DeleteSpec:            Deletes specified row(s) in specified ListView
; _GUIListViewEx_InsertCol:             Inserts blank column to right of selected column in active ListView
; _GUIListViewEx_InsertColSpec:         Inserts specified blank column in specified ListView
; _GUIListViewEx_DeleteCol:             Deletes selected column in active ListView
; _GUIListViewEx_DeleteColSpec:         Deletes specified column in specified ListView
; _GUIListViewEx_SortCol:               Sort specified column in specified ListView
; _GUIListViewEx_SetEditStatus:         Sets edit on doubleclick mode for specified column(s)
; _GUIListViewEx_SetEditKey:            Sets key(s) required to begin edit of selected item
; _GUIListViewEx_EditItem:              Manual edit of specified ListView item
; _GUIListViewEx_EditWidth:             Set required widths for column edit/combo when editing
; _GUIListViewEx_ChangeItem:            Programatic change of specified ListView item
; _GUIListViewEx_LoadHdrData:           Sets header title, text and back colour (if enabled), and sets edit mode (if enabled)
; _GUIListViewEx_EditHeader:            Manual edit of specified ListView header
; _GUIListViewEx_LoadColour:            Uses array to set text/back colours for user colour enabled ListViews
; _GUIListViewEx_SetDefColours:         Sets default colours for user colour/single cell select enabled ListViews
; _GUIListViewEx_SetColour:             Sets text and/or back colour for user colour enabled ListViews
; _GUIListViewEx_BlockReDraw:           Prevents ListView redrawing during looped Insert/Delete/Change calls
; _GUIListViewEx_UserSort:              Sets user defined function to sort specified columns
; _GUIListViewEx_SelectItem:            Programatically select row - and item if single selection available - in active ListView
; _GUIListViewEx_GetLastSelItem:        Get last selected item in active or specified ListView
; _GUIListViewEx_ContextPos:            Returns LV index and row/col of last right click
; _GUIListViewEx_ToolTipInit:           Defines column(s) which will display a tooltip when clicked
; _GUIListViewEx_EventMonitor:          Check for edit, sort, drag/drop and tooltip events - auto colour redraw - returns event results
; _GUIListViewEx_MsgRegister:           Registers Windows messages required for the UDF
; _GUIListViewEx_WM_NOTIFY_Handler:     Windows message handler for WM_NOTIFY - needed for all UDF functions
; _GUIListViewEx_WM_MOUSEMOVE_Handler:  Windows message handler for WM_MOUSEMOVE - needed for drag
; _GUIListViewEx_WM_LBUTTONUP_Handler:  Windows message handler for WM_LBUTTONUP - needed for drag
; _GUIListViewEx_WM_SYSCOMMAND_Handler: Windows message handler for WM_SYSCOMMAND - speeds GUI closure when editing
; ====================================================================================================================

; #INTERNAL_USE_ONLY#=================================================================================================
; __GUIListViewEx_ExpandRange:      Expands ranges into an array of values
; __GUIListViewEx_HighLight:        Highlights specified ListView item and ensures it is visible
; __GUIListViewEx_GetLVFont:        Gets font details for ListView to be edited
; __GUIListViewEx_EditProcess:      Runs ListView editing process
; __GUIListViewEx_EditCoords:       Ensures item in view then locates and sizes edit control
; __GUIListViewEx_ReWriteLV:        Deletes all ListView content and refills to match array
; __GUIListViewEx_GetLVCoords:      Gets screen coords for ListView
; __GUIListViewEx_GetCursorWnd:     Gets handle of control under the mouse cursor
; __GUIListViewEx_Array_Add:        Adds a specified value at the end of an array
; __GUIListViewEx_Array_Insert:     Adds a value at the specified index of an array
; __GUIListViewEx_Array_Delete:     Deletes a specified index from an array
; __GUIListViewEx_Array_Swap:       Swaps specified elements within an array
; __GUIListViewEx_ToolTipHide:      Called by Adlib to hide tooltip displayed by _GUIListViewEx_ToolTipShow
; __GUIListViewEx_MakeString:       Convert data/check/colour arrays to strings for saving
; __GUIListViewEx_MakeArray:        Convert data/check/colour strings to arrays for loading
; __GUIListViewEx_ColSort:          Sort columns even if colour enabled
; __GUIListViewEx_RedrawWindow:     Redraw ListView after update
; __GUIListViewEx_CheckUserEditKey: Check keys pressed in ListView
; ====================================================================================================================

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_Init
; Description ...: Enables UDF functions for the ListView and sets various flags
; Syntax.........: _GUIListViewEx_Init($hLV, [$aArray = ""[, $iStart = 0[, $iColour[, $fImage[, $iAdded]]]]])
; Parameters ....: $hLV       - Handle or ControlID of ListView
;                  $aArray    - Name of array used to fill ListView.  "" for empty ListView
;                  $iStart    - 0 = ListView data starts in [0] element of array (default)
;                               1 = Count in [0] element
;                  $iColour   - RGB colour for insert mark (default = black)
;                  $fImage    - True  = Shadow image of dragged item when dragging
;                               False = No shadow image (default)
;                  $iAdded    - 0       - No added features (default).  To get added features add any of the following values
;                               + 1     - Sortable by clicking on column headers
;                               + 2     - Do not "select all" when editing item text
;                               + 4     - Continue edit within same ListView by triple mouse-click on editable column
;                               + 8     - Headers editable by Ctrl-click (only if column editable)
;                               + 16    - User coloured header
;                               + 32    - User coloured items
;                               + 64    - No external drag
;                               + 128   - No external drop
;                               + 256   - No delete on external drag/drop
;                               + 512   - No internal drag/drop
;                               + 1024  - Single cell highlight (forces single row selection)
; Requirement(s).: v3.3.10 +
; Return values .: Index number of ListView for use in other GUIListViewEx functions
; Author ........: Melba23
; Modified ......:
; Remarks .......: - If the ListView is the only one enabled, it is automatically set as active
;                  - If no array is passed a shadow array is created automatically
;                  - The $iStart parameter determines if a count element will be returned by other GUIListViewEx functions
;                  - The _GUIListViewEx_ReadToArray function will read an existing ListView into an array
;                  - Only first item of a multiple selection is shadow imaged when dragging (API limitation)
;                  - Use the _GUIListViewEx_SetEditStatus function to make columns editable
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_Init($hLV, $aArray = "", $iStart = 0, $iColour = 0, $fImage = False, $iAdded = 0)

	Local $iLV_Index = 0

	; See if there is a blank line available in the array
	For $i = 1 To $aGLVEx_Data[0][0]
		If $aGLVEx_Data[$i][0] = 0 Then
			$iLV_Index = $i
			ExitLoop
		EndIf
	Next
	; If no blank line found then increase array size
	If $iLV_Index = 0 Then
		$aGLVEx_Data[0][0] += 1
		ReDim $aGLVEx_Data[$aGLVEx_Data[0][0] + 1][UBound($aGLVEx_Data, 2)]
		$iLV_Index = $aGLVEx_Data[0][0]
	EndIf

	; Store ListView handle and ControlID (if it exists)
	If IsHWnd($hLV) Then
		$aGLVEx_Data[$iLV_Index][0] = $hLV
		$aGLVEx_Data[$iLV_Index][1] = 0
	Else
		$aGLVEx_Data[$iLV_Index][0] = GUICtrlGetHandle($hLV)
		$aGLVEx_Data[$iLV_Index][1] = $hLV
	EndIf

	; Store separator char
	$aGLVEx_Data[0][24] = Opt("GUIDataSeparatorChar")

	; Store ListView content in shadow array
	$aGLVEx_Data[$iLV_Index][2] =  _GUIListViewEx_ReadToArray($hLV, 1)

	;Set no selected row or column
	$aGLVEx_Data[$iLV_Index][20] = -1
	$aGLVEx_Data[$iLV_Index][21] = -1

	; Store array count flag
	$aGLVEx_Data[$iLV_Index][3] = $iStart
	; Store 1D/2D array return type flag
	If IsArray($aArray) Then
		If UBound($aArray, 0) = 2 Then $aGLVEx_Data[$iLV_Index][3] += 2
	EndIf

	; Create and store editable array
	Local $aEditable[4][UBound($aGLVEx_Data[$iLV_Index][2], 2)]
	$aGLVEx_Data[$iLV_Index][7] = $aEditable

	; Set insert mark colour after conversion to BGR
	_GUICtrlListView_SetInsertMarkColor($hLV, BitOR(BitShift(BitAND($iColour, 0x000000FF), -16), BitAND($iColour, 0x0000FF00), BitShift(BitAND($iColour, 0x00FF0000), 16)))
	; If drag image required
	If $fImage Then
		$aGLVEx_Data[$iLV_Index][5] = 1
	EndIf

	; If sortable, store sort array
	If BitAND($iAdded, 1) Then
		Local $aLVSortState[_GUICtrlListView_GetColumnCount($hLV)]
		$aGLVEx_Data[$iLV_Index][4] = $aLVSortState
	Else
		$aGLVEx_Data[$iLV_Index][4] = 0
	EndIf

	; If do not "select all" on opening edit
	If BitAND($iAdded, 2) Then
		; Set flag
		$aGLVEx_Data[$iLV_Index][11] = 1
	EndIf

	; If continue edit on click
	If BitAND($iAdded, 4) Then
		; Set flag
		$aGLVEx_Data[$iLV_Index][9] = 1
	EndIf

	; If header editable on Ctrl-click set flag
	If BitAND($iAdded, 8) Then
		$aGLVEx_Data[$iLV_Index][8] = 1
	EndIf

	; Create default header data array
	Local $iCols = _GUICtrlListView_GetColumnCount($hLV)
	Local $aHdrData[4][$iCols], $aRet
	; If user coloured headers
	If BitAND($iAdded, 16) Then
		; Get header handle to act as flag
		Local $hHeader = _GUICtrlListView_GetHeader($hLV)
		$aGLVEx_Data[$iLV_Index][24] = $hHeader
		; Read in current header titles
		For $i = 0 To $iCols - 1
			$aRet = _GUICtrlListView_GetColumn($hLV, $i)
			$aHdrData[0][$i] = $aRet[5]
		Next
	EndIf
	; Store array
	$aGLVEx_Data[$iLV_Index][25] = $aHdrData

	; Load default colours
	$aGLVEx_Data[$iLV_Index][23] = $aGLVEx_DefColours
	$aGLVEx_Data[$iLV_Index][26] = $aGLVEx_DefColours[1]

	; If user coloured items
	If BitAND($iAdded, 32) Then
		Local $aColArray = $aGLVEx_Data[$iLV_Index][2]
		For $i = 1 To UBound($aColArray, 1) - 1
			For $j = 0 To UBound($aColArray, 2) - 1
				$aColArray[$i][$j] = ";"
			Next
		Next
		$aGLVEx_Data[$iLV_Index][18] = $aColArray
		; Set user colour flag
		$aGLVEx_Data[$iLV_Index][19] = 1
	EndIf

	; If no external drag
	If BitAND($iAdded, 64) Then
		$aGLVEx_Data[$iLV_Index][12] = 1
	EndIf

	; If no external drop
	If BitAND($iAdded, 128) Then
		$aGLVEx_Data[$iLV_Index][12] += 2
	EndIf

	; If no delete on external drag/drop
	If BitAND($iAdded, 256) Then
		$aGLVEx_Data[$iLV_Index][12] += 4
	EndIf

	; If no internal drag/drop
	If BitAND($iAdded, 512) Then
		$aGLVEx_Data[$iLV_Index][12] += 8
	EndIf

	; Set flag for no drag/drop at all
	If BitAND($aGLVEx_Data[$iLV_Index][12], 8) And BitAND($aGLVEx_Data[$iLV_Index][12], 2) And BitAND($aGLVEx_Data[$iLV_Index][12], 1) Then
		$aGLVEx_Data[$iLV_Index][12] += 16
	EndIf

	; If single cell selection
	If BitAND($iAdded, 1024) Then
		; Force single selection style
		Local $iStyle = _WinAPI_GetWindowLong($aGLVEx_Data[$iLV_Index][0], $GWL_STYLE)
		_WinAPI_SetWindowLong($aGLVEx_Data[$iLV_Index][0], $GWL_STYLE, BitOR($iStyle, $LVS_SINGLESEL))
		; Set flag
		$aGLVEx_Data[$iLV_Index][22] = 1
		; Load default colours
		$aGLVEx_Data[$iLV_Index][23] = $aGLVEx_DefColours
	EndIf

	;  If checkbox extended style
	If BitAND(_GUICtrlListView_GetExtendedListViewStyle($hLV), 4) Then ; $LVS_EX_CHECKBOXES
		$aGLVEx_Data[$iLV_Index][6] = 1
	EndIf

	;  If header drag extended style
	If BitAND(_GUICtrlListView_GetExtendedListViewStyle($hLV), 0x00000010) Then ; $LVS_EX_HEADERDRAGDROP
		$aGLVEx_Data[$iLV_Index][13] = 1
	EndIf

	; Measure item depth for scroll - if empty reset when filled later
	Local $aRect = _GUICtrlListView_GetItemRect($aGLVEx_Data[$iLV_Index][0], 0)
	$aGLVEx_Data[$iLV_Index][10] = $aRect[3] - $aRect[1]

	; If only 1 current ListView then activate
	Local $iListView_Count = 0
	For $i = 1 To $iLV_Index
		If $aGLVEx_Data[$i][0] Then $iListView_Count += 1
	Next
	If $iListView_Count = 1 Then _GUIListViewEx_SetActive($iLV_Index)

	; Return ListView index
	Return $iLV_Index

EndFunc   ;==>_GUIListViewEx_Init

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_Close
; Description ...: Disables all UDF functions for the specified ListView and clears all memory used
; Syntax.........: _GUIListViewEx_Close($iLV_Index)
; Parameters ....: $iLV_Index - Index number of ListView to close as returned by _GUIListViewEx_Init
;                            0 (default) = Closes all ListViews
; Requirement(s).: v3.3.10 +
; Return values .: Success: 1
;                  Failure: 0 and @error set to 1 - Invalid index number
; Author ........: Melba23
; Modified ......:
; Remarks .......:
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_Close($iLV_Index = 0)

	Local $iEditKeyCode

	; Check valid index
	If $iLV_Index < 1 Or $iLV_Index > $aGLVEx_Data[0][0] Then Return SetError(1, 0, 0)

	If $iLV_Index = 0 Then
		; Reinitialise data array - retaining selected edit key
		$iEditKeyCode = $aGLVEx_Data[0][23]
		Global $aGLVEx_Data[1][UBound($aGLVEx_Data, 2)] = [[0, 0, -1, "", -1, -1, -1, -1, _WinAPI_GetSystemMetrics(2), False, _
				 -1, -1, False, "", 0, True, 0, -1, -1, 0, 0, 0, 0, $iEditKeyCode]]
		; Note delimiter character reset when ListView next initialised
	Else
		; Reset all data for ListView
		For $i = 0 To UBound($aGLVEx_Data, 2) - 1
			$aGLVEx_Data[$iLV_Index][$i] = 0
		Next

		; Cancel active index if set to this ListView
		If $aGLVEx_Data[0][1] = $iLV_Index Then
			$aGLVEx_Data[0][1] = 0
		EndIf

	EndIf

	Return 1

EndFunc   ;==>_GUIListViewEx_Close

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_SetActive
; Description ...: Set specified ListView as active for non-specific UDF functions
; Syntax.........: _GUIListViewEx_SetActive($iLV_Index)
; Parameters ....: $iLV_Index - Index number of ListView as returned by _GUIListViewEx_Init
;                  An index of 0 clears any current setting
; Requirement(s).: v3.3.10 +
; Return values .: Success: Returns previous active index number, 0 = no previously active ListView
;                  Failure: -1 and @error set to 1 - Invalid index number
; Author ........: Melba23
; Modified ......:
; Remarks .......: ListViews can also be activated by clicking on them
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_SetActive($iLV_Index)

	; Check valid index
	If $iLV_Index < 0 Or $iLV_Index > $aGLVEx_Data[0][0] Then Return SetError(1, 0, -1)

	Local $iCurr_Index = $aGLVEx_Data[0][1]

	If $iLV_Index Then
		; Store index of specified ListView
		$aGLVEx_Data[0][1] = $iLV_Index
		; Set values for specified ListView
		$hGLVEx_SrcHandle = $aGLVEx_Data[$iLV_Index][0]
		$cGLVEx_SrcID = $aGLVEx_Data[$iLV_Index][1]
	Else
		; Clear active index
		$aGLVEx_Data[0][1] = 0
		$hGLVEx_SrcHandle = 0
		$cGLVEx_SrcID = 0
	EndIf

	Return $iCurr_Index

EndFunc   ;==>_GUIListViewEx_SetActive

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_GetActive
; Description ...: Get index number of ListView active for non-specific UDF functions
; Syntax.........: _GUIListViewEx_GetActive()
; Parameters ....: None
; Requirement(s).: v3.3.10 +
; Return values .: Success: Index number as returned by _GUIListViewEx_Init, 0 = no active ListView
; Author ........: Melba23
; Modified ......:
; Remarks .......:
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_GetActive()

	Return $aGLVEx_Data[0][1]

EndFunc   ;==>_GUIListViewEx_GetActive

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_ReadToArray
; Description ...: Creates an array from the current ListView content to be loaded in _Init function
; Syntax.........: _GUIListViewEx_ReadToArray($hLV[, $iCount = 0])
; Parameters ....: $hLV    - ControlID or handle of ListView
;                  $iCount - 0 (default) = ListView data starts in [0] element of array, 1 = Count in [0] element
; Requirement(s).: v3.3.10 +
; Return values .: Success: 2D array of current ListView content
;                           If ListView empty then [0] count element or an empty array
;                  Failure: Returns null string and sets @error as follows:
;                           1 = Invalid ListView ControlID or handle
; Author ........: Melba23
; Modified ......:
; Remarks .......: - Note that this function requires the handle/ControlID of the ListView, not the UDF index
;                  - If returned array is used in _GUIListViewEx_Init the $iStart parameters must match in the 2 functions
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_ReadToArray($hLV, $iStart = 0)

	Local $aLVArray = "", $aRow

	; Use the ListView handle
	If Not IsHWnd($hLV) Then
		$hLV = GUICtrlGetHandle($hLV)
		If Not IsHWnd($hLV) Then
			Return SetError(1, 0, "")
		EndIf
	EndIf
	; Get ListView row count
	Local $iRows = _GUICtrlListView_GetItemCount($hLV)
	; Get ListView column count
	Local $iCols = _GUICtrlListView_GetColumnCount($hLV)
	; Check for empty ListView with no count
	If ($iRows + $iStart <> 0) And $iCols <> 0 Then
		; Create 2D array to hold ListView content and add count - count overwritten if not needed
		Local $aLVArray[$iRows + $iStart][$iCols] = [[$iRows]]
		; Read ListView content into array
		For $i = 0 To $iRows - 1
			; Read the row content
			$aRow = _GUICtrlListView_GetItemTextArray($hLV, $i)
			For $j = 1 To $aRow[0]
				; Add to the ListView content array
				$aLVArray[$i + $iStart][$j - 1] = $aRow[$j]
			Next
		Next
	Else
		; Empty ListView
		Local $aLVArray[1][1]
		; Set count if required
		If $iStart = 1 Then $aLVArray[0][0] = 0
	EndIf

	; Return array
	Return $aLVArray

EndFunc   ;==>_GUIListViewEx_ReadToArray

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_ReturnArray
; Description ...: Returns an array reflecting the current content of an activated ListView
; Syntax.........: _GUIListViewEx_ReturnArray($iLV_Index[, $iMode])
; Parameters ....: $iLV_Index - Index number of ListView as returned by _GUIListViewEx_Init
;                  $iMode  - 0 = Content of ListView
;                            1 - State of the checkboxes
;                            2 - User colours (if initialised)
;                            3 - Content of ListView forced to 2D for saving
;                            4 - ListView header titles
;                            5 - Header colours (if initialised)
; Requirement(s).: v3.3.10 +
; Return values .: Success: Array of current ListView content - _GUIListViewEx_Init parameters determine:
;                               For modes 0/1:
;                                   Count in [0]/[0][0] element if $iStart = 1 when intialised
;                                   1D/2D array type - as array used to initialise
;                                   If no array passed then single col => 1D; multiple column => 2D
;                               For mode 2/3
;                                   Always 0-based 2D array
;                               For mode 4/5
;                                   Always 0-based 1D array
;                  Failure: Returns empty string and sets @error as follows:
;                               1 = Invalid index number
;                               2 = Empty array (no items in ListView)
;                               3 = $iMode set to 1 but no checkbox style
;                               4 = $iMode set to 2 but user colours not initialised
;                               5 = $iMode set to 5 but header colours not initialised
;                               6 = Invalid $iMode
; Author ........: Melba23
; Modified ......:
; Remarks .......: Colours returned as "text;back" - empty values use default colours
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_ReturnArray($iLV_Index, $iMode = 0)

	; Check valid index
	If $iLV_Index < 1 Or $iLV_Index > $aGLVEx_Data[0][0] Then Return SetError(1, 0, "")
	; Get ListView handle
	Local $hLV = $aGLVEx_Data[$iLV_Index][0]

	; Get column order
	Local $sOrder = _GUICtrlListView_GetColumnOrder($hLV)

	Local $aColOrder[1]
	If $sOrder = "" Then
		$aColOrder[0] = 0
	Else
		$aColOrder = StringSplit($sOrder, $aGLVEx_Data[0][24])
	EndIf

	; Extract array and get size
	Local $aData_Colour = $aGLVEx_Data[$iLV_Index][2]

	; Check for empty array
	If $aColOrder[0] = 0 Then
		$aData_Colour = ""
		Return SetError(2, 0, "")
	EndIf
	Local $iDim_1 = UBound($aData_Colour, 1), $iDim_2 = UBound($aData_Colour, 2)
	Local $aCheck[$iDim_1], $aHeader[$iDim_2], $aHdrData

	; Adjust array depending on mode required
	Switch $iMode
		Case 0, 3 ; Content
			; Array already filled

		Case 1 ; Checkbox state
			If $aGLVEx_Data[$iLV_Index][6] Then
				For $i = 1 To $iDim_1 - 1
					$aCheck[$i] = _GUICtrlListView_GetItemChecked($hLV, $i - 1)
				Next
				; Remove count element if required
				If BitAND($aGLVEx_Data[$iLV_Index][3], 1) = 0 Then
					; Delete count element
					__GUIListViewEx_Array_Delete($aCheck, 0, True)
				EndIf
				Return $aCheck
			Else
				Return SetError(3, 0, "")
			EndIf

		Case 2 ; Colour values
			If $aGLVEx_Data[$iLV_Index][19] Then
				; Load colour array
				$aData_Colour = $aGLVEx_Data[$iLV_Index][18]
				; Convert to RGB
				For $i = 0 To UBound($aData_Colour, 1) - 1
					For $j = 0 To UBound($aData_Colour, 2) - 1
						$aData_Colour[$i][$j] = StringRegExpReplace($aData_Colour[$i][$j], "0x(.{2})(.{2})(.{2})", "0x$3$2$1")
					Next
				Next
				$aData_Colour[0][0] = $iDim_1 - 1
			Else
				Return SetError(4, 0, "")
			EndIf

		Case 4 ; Headers
			If $aGLVEx_Data[$iLV_Index][24] Then
				; Header colour enabled, so read from header data
				$aHdrData = $aGLVEx_Data[$iLV_Index][25]
				For $i = 0 To $iDim_2 - 1
					$aHeader[$i] = $aHdrData[0][$i]
				Next
			Else
				; Read normal headers
				Local $aRet
				For $i = 0 To $iDim_2 - 1
					$aRet = _GUICtrlListView_GetColumn($hLV, $i)
					$aHeader[$i] = $aRet[5]
				Next
			EndIf

		Case 5 ; Header colours
			If $aGLVEx_Data[$iLV_Index][24] Then
				; Header colour enabled, so read from header data
				$aHdrData = $aGLVEx_Data[$iLV_Index][25]
				For $i = 0 To $iDim_2 - 1
					$aHeader[$i] = $aHdrData[1][$i]
				Next
			Else
				Return SetError(5, 0, "")
			EndIf

		Case Else
			Return SetError(6, 0, "")
	EndSwitch

	; Check if columns can be reordered
	If $aGLVEx_Data[$iLV_Index][13] And UBound($aData_Colour, 2) Then

		Switch $iMode
			Case 0, 2, 3 ; 2D data/colour array
				; Create temp array
				Local $aData_Colour_Ordered[$iDim_1][$iDim_2]
				; Check we are not dealing with an empty array with no data to transfer
				If $iDim_1 <> 1 Or $iDim_2 <> 0 Then
					; Fill temp array in correct column order
					$aData_Colour_Ordered[0][0] = $aData_Colour[0][0]
					For $i = 1 To $iDim_1 - 1
						For $j = 0 To $iDim_2 - 1
							$aData_Colour_Ordered[$i][$j] = $aData_Colour[$i][$aColOrder[$j + 1]]
						Next
					Next
				EndIf
				; Reset main and delete temp
				$aData_Colour = $aData_Colour_Ordered
				$aData_Colour_Ordered = ""

			Case 4, 5 ; 1D header array

				; Create return array
				Local $aHeader_Ordered[$iDim_2]
				; Check we are not dealing with an empty array
				If $iDim_1 <> 1 Or $iDim_2 <> 0 Then
					; Fill return array in correct column order
					For $i = 0 To $iDim_2 - 1
						$aHeader_Ordered[$i] = $aHeader[$aColOrder[$i + 1]]
					Next
				EndIf
				; Return reordered array
				Return $aHeader_Ordered
		EndSwitch
	Else
		; No reordering
		If $iMode = 4 Then
			; Return header array
			Return $aHeader
		EndIf
	EndIf

	; Remove count element of array if required - always for colour return
	Local $iCount = 1
	If BitAND($aGLVEx_Data[$iLV_Index][3], 1) = 0 Or $iMode = 2 Then
		$iCount = 0
		; Delete count element
		__GUIListViewEx_Array_Delete($aData_Colour, 0, True)
	EndIf

	; Now check if 1D array to be returned - always 2D for colour return and forced content
	If BitAND($aGLVEx_Data[$iLV_Index][3], 2) = 0 And $iMode < 2 Then
		If UBound($aData_Colour, 1) = 0 Then
			Local $aData_Colour[0]
		Else
			; Get number of 2D elements
			Local $iCols = UBound($aData_Colour, 2)
			; Create 1D array - count will be overwritten if not needed
			Local $aData_Colour_1D[UBound($aData_Colour)] = [$aData_Colour[0][0]]
			; Fill with concatenated lines
			For $i = $iCount To UBound($aData_Colour_1D) - 1
				Local $aLine = ""
				For $j = 0 To $iCols - 1
					$aLine &= $aData_Colour[$i][$j] & $aGLVEx_Data[0][24]
				Next
				$aData_Colour_1D[$i] = StringTrimRight($aLine, 1)
			Next
			; Reset array
			$aData_Colour = $aData_Colour_1D
		EndIf
	EndIf

	; Return array
	Return $aData_Colour

EndFunc   ;==>_GUIListViewEx_ReturnArray

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_SaveListView
; Description ...: Saves ListView header data, ListView content, checkbox state and colour data to file
; Syntax.........: _GUIListViewEx_SaveListView($iLV_Index, $sFileName)
; Parameters ....: $iLV_Index    - Index number of ListView as returned by _GUIListViewEx_Init
;                  $sFileName - File in which to save data
; Requirement(s).: v3.3.10 +
; Return values .: Success: 1
;                  Failure: 0 and sets @error as follows:
;                               1 = Invalid index number
;                               2 = File not written - @extended set:
;                                   1 = File not opened
;                                   2 = Data not written
; Author ........: Melba23
; Modified ......:
; Remarks .......:
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_SaveListView($iLV_Index, $sFileName)

	; Check valid index
	If $iLV_Index < 1 Or $iLV_Index > $aGLVEx_Data[0][0] Then Return SetError(1, 0, 0)

	; Get ListView parameters
	Local $hLV_Handle = $aGLVEx_Data[$iLV_Index][0]
	Local $iStart = BitAND($aGLVEx_Data[$iLV_Index][3], 1)

	; Get header data
	Local $sHeader = "", $aRet
	If $aGLVEx_Data[$iLV_Index][24] Then
		; Header colour enabled, so also read from header data
		Local $aHdrData = $aGLVEx_Data[$iLV_Index][25]
		; Create string
		For $i = 0 To _GUICtrlListView_GetColumnCount($hLV_Handle) - 1
			$aRet = _GUICtrlListView_GetColumn($hLV_Handle, $i)
			$sHeader &= $aHdrData[0][$i] & @CR & $aRet[4] & @CR & $aHdrData[1][$i] & @CR & $aHdrData[2][$i] & @CR & $aHdrData[3][$i] & @LF
		Next
	Else
		; Read normal headers and add blank unused elements
		For $i = 0 To _GUICtrlListView_GetColumnCount($hLV_Handle) - 1
			$aRet = _GUICtrlListView_GetColumn($hLV_Handle, $i)
			$sHeader &= $aRet[5] & @CR & $aRet[4] & @CR & @CR & @CR & @LF
		Next
	EndIf
	$sHeader = StringTrimRight($sHeader, 1)
	; Get data/check/colour content
	Local $aData = _GUIListViewEx_ReturnArray($iLV_Index, 3) ; Force 2D return
	If $iStart Then
		_ArrayDelete($aData, 0)
	EndIf
	Local $aCheck = _GUIListViewEx_ReturnArray($iLV_Index, 1)
	If $iStart Then
		_ArrayDelete($aCheck, 0)
	EndIf
	Local $aColour = _GUIListViewEx_ReturnArray($iLV_Index, 2)

	; Get edit data
	Local $aEditable = $aGLVEx_Data[$iLV_Index][7]

	; Get sort data
	Local $aSortable = $aGLVEx_Data[$iLV_Index][4]

	; Convert to strings
	Local $sData = "", $sCheck = "", $sColour = "", $sEditable = "", $sSortable = ""
	If IsArray($aData) Then
		$sData = __GUIListViewEx_MakeString($aData)
	EndIf
	If IsArray($aCheck) Then
		$sCheck = __GUIListViewEx_MakeString($aCheck)
	EndIf
	If IsArray($aColour) Then
		$sColour = __GUIListViewEx_MakeString($aColour)
	EndIf
	If IsArray($aEditable) Then
		$sEditable = __GUIListViewEx_MakeString($aEditable)
	EndIf
	If IsArray($aSortable) Then
		$sSortable = __GUIListViewEx_MakeString($aSortable)
	EndIf

	; Write data to file
	Local $iError = 0
	Local $hFile = FileOpen($sFileName, $FO_OVERWRITE)
	If @error Then
		$iError = 1
	Else
		FileWrite($hFile, $sHeader & ChrW(0xEF0F) & $sData & ChrW(0xEF0F) & $sCheck & ChrW(0xEF0F) & $sColour & ChrW(0xEF0F) & $sEditable & ChrW(0xEF0F) & $sSortable)
		If @error Then
			$iError = 2
		EndIf
	EndIf
	FileClose($hFile)

	If $iError Then Return SetError(2, $iError, 0)

	Return 1

EndFunc   ;==>_GUIListViewEx_SaveListView

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_LoadListView
; Description ...: Loads ListView header data, ListView content, checkbox state and colour data from file
; Syntax.........: _GUIListViewEx_LoadListView($iLV_Index, $sFileName[, $iDims = 2])
; Parameters ....: $iLV_Index    - Index number of ListView as returned by _GUIListViewEx_Init
;                  $sFileName - File from which to load data
;                  $iDims     - Force 1/2D return array - normally set by initialising array
; Requirement(s).: v3.3.10 +
; Return values .: Success: 1
;                  Failure: 0 and sets @error as follows:
;                               1 = Invalid index number
;                               2 = Invalid $iDims parameter
;                               3 = File not read
;                               4 = No data to load
; Author ........: Melba23
; Modified ......:
; Remarks .......:
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_LoadListView($iLV_Index, $sFileName, $iDims = 2)

	; Check valid index
	If $iLV_Index < 1 Or $iLV_Index > $aGLVEx_Data[0][0] Then Return SetError(1, 0, 0)
	; Check valid $iDims parameter
	Switch $iDims
		Case 1, 2
			; OK
		Case Else
			Return SetError(2, 0, 0)
	EndSwitch

	; Get ListView parameters
	Local $hLV_Handle = $aGLVEx_Data[$iLV_Index][0]
	Local $cLV_CID = $aGLVEx_Data[$iLV_Index][1]
	Local $iStart = BitAND($aGLVEx_Data[$iLV_Index][3], 1)

	; Read content
	Local $sContent = FileRead($sFileName)
	If @error Then Return SetError(3, 0, 0)

	; Split into separate sections
	Local $aSplit = StringSplit($sContent, ChrW(0xEF0F), $STR_ENTIRESPLIT)

	; Load arrays - checking there is some data to load
	Local $aHeader = __GUIListViewEx_MakeArray($aSplit[1])
	If Not IsArray($aHeader) Then Return SetError(4, 0, 0)
	Local $aData = __GUIListViewEx_MakeArray($aSplit[2])
	If Not IsArray($aData) Then Return SetError(4, 0, 0)
	Local $aCheck = __GUIListViewEx_MakeArray($aSplit[3])
	Local $aColour = __GUIListViewEx_MakeArray($aSplit[4])
	Local $aEditable = __GUIListViewEx_MakeArray($aSplit[5])
	Local $aSortable = __GUIListViewEx_MakeArray($aSplit[6])

	; If required, convert data and colour arrays into 2D for load
	If UBound($aData, 0) = 1 Then
		Local $aTempData[UBound($aData)][1]
		Local $aTempCol[UBound($aData)][1]
		For $i = 0 To UBound($aData) - 1
			$aTempData[$i][0] = $aData[$i]
			$aTempCol[$i][0] = $aColour[$i]
		Next
		$aData = $aTempData
		$aColour = $aTempCol
	EndIf

	; Create and fill header data array
	Local $aHdrData[4][UBound($aHeader)]
	For $i = 0 To UBound($aHeader) - 1
		$aHdrData[0][$i] = $aHeader[$i][0]
		$aHdrData[1][$i] = $aHeader[$i][2]
		$aHdrData[2][$i] = $aHeader[$i][3]
		$aHdrData[3][$i] = $aHeader[$i][4]
	Next
	; Store array
	$aGLVEx_Data[$iLV_Index][25] = $aHdrData

	; Set no colour redraw flag and prevent any normal redraw
	$aGLVEx_Data[0][12] = 1
	$aGLVEx_Data[0][15] = False
	_GUICtrlListView_BeginUpdate($hLV_Handle)

	; Clear current content of ListView
	_GUICtrlListView_DeleteAllItems($hLV_Handle)

	; Check correct number of columns
	Local $iCol_Count = _GUICtrlListView_GetColumnCount($hLV_Handle)
	If $iCol_Count < UBound($aHeader) Then
		; Add columns
		For $i = $iCol_Count To UBound($aHeader) - 1
			_GUICtrlListView_AddColumn($hLV_Handle, "", 100)
		Next
	EndIf
	If $iCol_Count > UBound($aHeader) Then
		; Delete columns
		For $i = $iCol_Count To UBound($aHeader) Step -1
			_GUICtrlListView_DeleteColumn($hLV_Handle, $i)
		Next
	EndIf

	; Reset header titles and widths
	For $i = 0 To UBound($aHeader) - 1
		_GUICtrlListView_SetColumn($hLV_Handle, $i, $aHeader[$i][0], $aHeader[$i][1])
	Next

	; Load ListView content
	If $cLV_CID Then
		; Native ListView
		Local $sLine, $iLastCol = UBound($aData, 2) - 1
		For $i = 0 To UBound($aData) - 1
			$sLine = ""
			For $j = 0 To $iLastCol
				$sLine &= $aData[$i][$j] & $aGLVEx_Data[0][24]
			Next
			GUICtrlCreateListViewItem(StringTrimRight($sLine, 1), $cLV_CID)
		Next
	Else
		; UDF ListView
		_GUICtrlListView_AddArray($hLV_Handle, $aData)
	EndIf

	_GUICtrlListView_EndUpdate($hLV_Handle)

	; Add required count row to shadow array
	_ArrayInsert($aData, 0, UBound($aData))
	; Store content array
	$aGLVEx_Data[$iLV_Index][2] = $aData
	; Store editable array
	$aGLVEx_Data[$iLV_Index][7] = $aEditable
	; Store sortable array
	$aGLVEx_Data[$iLV_Index][4] = $aSortable

	; Set 1/2D return flag as required
	$aGLVEx_Data[$iLV_Index][3] = $iStart + (($iDims = 2) ? (2) : (0))

	; Reset checkboxes if required
	If IsArray($aCheck) Then
		; Reset checkboxes
		For $i = 0 To UBound($aCheck) - 1
			If $aCheck[$i] = "True" Then
				_GUICtrlListView_SetItemChecked($hLV_Handle, $i, True)
			EndIf
		Next
	EndIf

	; Clear no colour redraw flag and allow normal redraw
	$aGLVEx_Data[0][12] = 0
	$aGLVEx_Data[0][15] = True

	; Reset data colours if required
	If $aGLVEx_Data[$iLV_Index][19] Then
		If IsArray($aColour) Then
			; Load colour
			_GUIListViewEx_LoadColour($iLV_Index, $aColour)
		Else
			; Create empty array
			$aColour = $aData
			For $i = 0 To UBound($aData) - 1
				For $j = 0 To UBound($aData, 2) - 1
					$aColour[$i][$j] = ";"
				Next
			Next
			$aGLVEx_Data[$iLV_Index][18] = $aColour
		EndIf
	EndIf

	; Redraw ListView
	__GUIListViewEx_RedrawWindow($iLV_Index)

	; Set active
	$aGLVEx_Data[0][1] = $iLV_Index

	Return 1

EndFunc   ;==>_GUIListViewEx_LoadListView

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_Up
; Description ...: Moves selected item(s) in active ListView up 1 row
; Syntax.........: _GUIListViewEx_Up()
; Parameters ....: None
; Requirement(s).: v3.3.10 +
; Return values .: Success: Array of active ListView with count in [0] element
;                  Failure: Returns "" and sets @error as follows:
;                      1 = No ListView active
;                      2 = No item selected
;                      3 = Item already at top
;                      4 = Empty ListView
; Author ........: Melba23
; Modified ......:
; Remarks .......: If multiple items are selected, only the top consecutive block is moved
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_Up()

	Local $iGLVExMove_Index, $iGLVEx_Moving = 0

	; Set data for active ListView
	Local $iLV_Index = $aGLVEx_Data[0][1]
	; If no ListView active then return
	If $iLV_Index = 0 Then Return SetError(1, 0, 0)

	; Load active ListView details
	$hGLVEx_SrcHandle = $aGLVEx_Data[$iLV_Index][0]
	$cGLVEx_SrcID = $aGLVEx_Data[$iLV_Index][1]
	Local $fCheckBox = $aGLVEx_Data[$iLV_Index][6]

	; Copy array for manipulation
	$aGLVEx_SrcArray = $aGLVEx_Data[$iLV_Index][2]
	; Check for empty ListView
	If $aGLVEx_SrcArray[0][0] = 0 Then
		; No rows to move
		$aGLVEx_SrcArray = 0
		Return SetError(4, 0, "")
	EndIf
	$aGLVEx_SrcColArray = $aGLVEx_Data[$iLV_Index][18]

	; Create Local array for checkboxes (if no checkboxes makes no difference)
	Local $aCheck_Array[UBound($aGLVEx_SrcArray)]
	For $i = 1 To UBound($aCheck_Array) - 1
		$aCheck_Array[$i] = _GUICtrlListView_GetItemChecked($hGLVEx_SrcHandle, $i - 1)
	Next

	; Check for selected items
	Local $iIndex
	; Check if colour single cell selection enabled
	If $aGLVEx_Data[$iLV_Index][19] Or $aGLVEx_Data[$iLV_Index][22] Then
		; Use stored value
		$iIndex = $aGLVEx_Data[$iLV_Index][20]
	Else
		; Check actual values
		$iIndex = _GUICtrlListView_GetSelectedIndices($hGLVEx_SrcHandle)
	EndIf
	If $iIndex == "" Then
		Return SetError(2, 0, "")
	EndIf
	Local $aIndex = StringSplit($iIndex, "|")
	$iGLVExMove_Index = $aIndex[1]
	; Check if item is part of a multiple selection
	If $aIndex[0] > 1 Then
		; Check for consecutive items
		For $i = 1 To $aIndex[0] - 1
			If $aIndex[$i + 1] = $aIndex[1] + $i Then
				$iGLVEx_Moving += 1
			Else
				ExitLoop
			EndIf
		Next
	Else
		$iGLVExMove_Index = $aIndex[1]
	EndIf

	; Check not top item
	If $iGLVExMove_Index < 1 Then
		__GUIListViewEx_HighLight($hGLVEx_SrcHandle, $cGLVEx_SrcID, 0)
		Return SetError(3, 0, "")
	EndIf

	; Remove all highlighting
	_GUICtrlListView_SetItemSelected($hGLVEx_SrcHandle, -1, False)

	; Set no redraw flag - prevents problems while colour arrays are updated
	$aGLVEx_Data[0][12] = True

	; Move consecutive items
	For $iIndex = $iGLVExMove_Index To $iGLVExMove_Index + $iGLVEx_Moving
		; Swap array elements
		__GUIListViewEx_Array_Swap($aGLVEx_SrcArray, $iIndex, $iIndex + 1)
		__GUIListViewEx_Array_Swap($aCheck_Array, $iIndex, $iIndex + 1)
		__GUIListViewEx_Array_Swap($aGLVEx_SrcColArray, $iIndex, $iIndex + 1)
	Next

	; Amend stored row
	$aGLVEx_Data[$iLV_Index][20] -= 1

	; Rewrite ListView
	__GUIListViewEx_ReWriteLV($hGLVEx_SrcHandle, $aGLVEx_SrcArray, $aCheck_Array, $iLV_Index, $fCheckBox)

	; Set highlight
	For $i = 0 To $iGLVEx_Moving
		__GUIListViewEx_HighLight($hGLVEx_SrcHandle, $cGLVEx_SrcID, $iGLVExMove_Index + $i - 1)
	Next

	; Store amended array
	$aGLVEx_Data[$iLV_Index][2] = $aGLVEx_SrcArray
	$aGLVEx_Data[$iLV_Index][18] = $aGLVEx_SrcColArray
	; Delete copied array
	$aGLVEx_SrcArray = 0
	$aGLVEx_SrcColArray = 0

	; Clear no redraw flag
	$aGLVEx_Data[0][12] = False

	; If colour used or single cell selection
	__GUIListViewEx_RedrawWindow($iLV_Index)

	; Return amended array
	Return _GUIListViewEx_ReturnArray($iLV_Index)

EndFunc   ;==>_GUIListViewEx_Up

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_Down
; Description ...: Moves selected item(s) in active ListView down 1 row
; Syntax.........: _GUIListViewEx_Down()
; Parameters ....: None
; Requirement(s).: v3.3.10 +
; Return values .: Success: Array of active ListView with count in [0] element
;                  Failure: Returns "" and sets @error as follows:
;                      1 = No ListView active
;                      2 = No item selected
;                      3 = Item already at bottom
;                      4 = Empty ListView
; Author ........: Melba23
; Modified ......:
; Remarks .......: If multiple items are selected, only the bottom consecutive block is moved
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_Down()

	Local $iGLVExMove_Index, $iGLVEx_Moving = 0

	; Set data for active ListView
	Local $iLV_Index = $aGLVEx_Data[0][1]
	; If no ListView active then return
	If $iLV_Index = 0 Then Return SetError(1, 0, 0)

	; Load active ListView details
	$hGLVEx_SrcHandle = $aGLVEx_Data[$iLV_Index][0]
	$cGLVEx_SrcID = $aGLVEx_Data[$iLV_Index][1]
	Local $fCheckBox = $aGLVEx_Data[$iLV_Index][6]

	; Copy array for manipulation
	$aGLVEx_SrcArray = $aGLVEx_Data[$iLV_Index][2]

	; Check for empty ListView
	If $aGLVEx_SrcArray[0][0] = 0 Then
		; No rows to move
		$aGLVEx_SrcArray = 0
		Return SetError(4, 0, "")
	EndIf

	$aGLVEx_SrcColArray = $aGLVEx_Data[$iLV_Index][18]

	; Create Local array for checkboxes (if no checkboxes makes no difference)
	Local $aCheck_Array[UBound($aGLVEx_SrcArray)]
	For $i = 1 To UBound($aCheck_Array) - 1
		$aCheck_Array[$i] = _GUICtrlListView_GetItemChecked($hGLVEx_SrcHandle, $i - 1)
	Next

	; Check for selected items
	Local $iIndex
	; Check if colour or single cell selection enabled
	If $aGLVEx_Data[$iLV_Index][19] Or $aGLVEx_Data[$iLV_Index][22] Then
		; Use stored value
		$iIndex = $aGLVEx_Data[$iLV_Index][20]
		If $iIndex = -1 Then $iIndex = 0
	Else
		; Check actual values
		$iIndex = _GUICtrlListView_GetSelectedIndices($hGLVEx_SrcHandle)
	EndIf
	If $iIndex == "" Then
		Return SetError(2, 0, "")
	EndIf
	Local $aIndex = StringSplit($iIndex, "|")
	; Check if item is part of a multiple selection
	If $aIndex[0] > 1 Then
		$iGLVExMove_Index = $aIndex[$aIndex[0]]
		; Check for consecutive items
		For $i = 1 To $aIndex[0] - 1
			If $aIndex[$aIndex[0] - $i] = $aIndex[$aIndex[0]] - $i Then
				$iGLVEx_Moving += 1
			Else
				ExitLoop
			EndIf
		Next
	Else
		$iGLVExMove_Index = $aIndex[1]
	EndIf

	; Remove all highlighting
	_GUICtrlListView_SetItemSelected($hGLVEx_SrcHandle, -1, False)

	; Check not last item
	If $iGLVExMove_Index = _GUICtrlListView_GetItemCount($hGLVEx_SrcHandle) - 1 Then
		__GUIListViewEx_HighLight($hGLVEx_SrcHandle, $cGLVEx_SrcID, $iIndex)
		Return SetError(3, 0, "")
	EndIf

	; Set no redraw flag - prevents problems while colour arrays are updated
	$aGLVEx_Data[0][12] = True

	; Move consecutive items
	For $iIndex = $iGLVExMove_Index To $iGLVExMove_Index - $iGLVEx_Moving Step -1
		; Swap array elements
		__GUIListViewEx_Array_Swap($aGLVEx_SrcArray, $iIndex + 1, $iIndex + 2)
		__GUIListViewEx_Array_Swap($aCheck_Array, $iIndex + 1, $iIndex + 2)
		__GUIListViewEx_Array_Swap($aGLVEx_SrcColArray, $iIndex + 1, $iIndex + 2)
	Next

	; Amend stored row
	$aGLVEx_Data[$iLV_Index][20] += 1

	; Rewrite ListView
	__GUIListViewEx_ReWriteLV($hGLVEx_SrcHandle, $aGLVEx_SrcArray, $aCheck_Array, $iLV_Index, $fCheckBox)

	; Set highlight
	For $i = 0 To $iGLVEx_Moving
		__GUIListViewEx_HighLight($hGLVEx_SrcHandle, $cGLVEx_SrcID, $iGLVExMove_Index - $iGLVEx_Moving + $i + 1)
	Next

	; Store amended array
	$aGLVEx_Data[$iLV_Index][2] = $aGLVEx_SrcArray
	$aGLVEx_Data[$iLV_Index][18] = $aGLVEx_SrcColArray
	; Delete copied array
	$aGLVEx_SrcArray = 0
	$aGLVEx_SrcColArray = 0

	; Clear no redraw flag
	$aGLVEx_Data[0][12] = False

	; If colour used or single cell selection
	__GUIListViewEx_RedrawWindow($iLV_Index)

	; Return amended array
	Return _GUIListViewEx_ReturnArray($iLV_Index)

EndFunc   ;==>_GUIListViewEx_Down

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_Insert
; Description ...: Inserts data just below selected item in active ListView - if no selection, data added at end
; Syntax.........: _GUIListViewEx_Insert($vData[, $fMultiRow = False[, $fRetainWidth = False]])
; Parameters ....: $vData        - Data to insert, can be in array or delimited string format
;                  $fMultiRow    - (Optional) If $vData is a 1D array:
;                                     - False (default) - elements added as subitems to a single row
;                                     - True - elements added as rows containing a single item
;                                  Ignored if $vData is a single item or a 2D array
;                  $fRetainWidth - (Optional) True  = native ListView column width is retained on insert
;                                  False = native ListView columns expand to fit data (default)
; Requirement(s).: v3.3.10 +
; Return values .: Success: Array of current ListView content with count in [0] element
;                  Failure: If no ListView active then returns "" and sets @error to 1
; Author ........: Melba23
; Modified ......:
; Remarks .......: - New data is inserted after the selected item.  If no item is selected then the data is added at
;                  the end of the ListView.  If multiple items are selected, the data is inserted after the first
;                  - $vData can be passed in string or array format - it is automatically transformed if required
;                  - $vData as single item - item added to all columns
;                  - $vData as 1D array - see $fMultiRow above
;                  - $vData as 2D array - added as rows/columns
;                  - Native ListViews automatically expand subitem columns to fit inserted data.  Setting the
;                  $fRetainWidth parameter resets the original width after insertion
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_Insert($vData, $fMultiRow = False, $fRetainWidth = False)

	;Local $vInsert

	; Set data for active ListView
	Local $iLV_Index = $aGLVEx_Data[0][1]
	; If no ListView active then return
	If $iLV_Index = 0 Then Return SetError(1, 0, "")

	; Check for selected items
	Local $iIndex
	; Check if colour or single cell selection enabled
	If $aGLVEx_Data[$iLV_Index][19] Or $aGLVEx_Data[$iLV_Index][22] Then
		; Use stored value
		$iIndex = $aGLVEx_Data[$iLV_Index][20]
	Else
		; Check actual values
		$iIndex = _GUICtrlListView_GetSelectedIndices($hGLVEx_SrcHandle)
	EndIf
	Local $iInsert_Index = $iIndex
	; If no selection
	If $iIndex == "" Then $iInsert_Index = -1

	; Check for multiple selections
	If StringInStr($iIndex, "|") Then
		Local $aIndex = StringSplit($iIndex, "|")
		; Use first selection
		$iIndex = $aIndex[1]
		; Cancel all other selections
		For $i = 2 To $aIndex[0]
			_GUICtrlListView_SetItemSelected($hGLVEx_SrcHandle, $aIndex[$i], False)
		Next
	EndIf

	Local $vRet = _GUIListViewEx_InsertSpec($iLV_Index, $iInsert_Index + 1, $vData, $fMultiRow, $fRetainWidth)

	Return SetError(@error, 0, $vRet)

EndFunc   ;==>_GUIListViewEx_Insert

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_InsertSpec
; Description ...: Inserts data in specified row in specified ListView
; Syntax.........: _GUIListViewEx_InsertSpec($iLV_Index, $iRow, $vData[, $fMultiRow = False[, $fRetainWidth = False]])
; Parameters ....: $iLV_Index    - Index of ListView as returned by _GUIListViewEx_Init
;                  $iRow         - Row which will be inserted - setting -1 adds at end
;                  $vData        - Data to insert, can be in array or delimited string format
;                  $fMultiRow    - (Optional) If $vData is a 1D array:
;                                     - False (default) - elements added as subitems to a single row
;                                     - True - elements added as rows containing a single item
;                                  Ignored if $vData is a single item or a 2D array
;                  $fRetainWidth - (Optional) True  = native ListView column width is retained on insert
;                                  False = native ListView columns expand to fit data (default)
; Requirement(s).: v3.3.10 +
; Return values .: Success: Array of specified ListView content with count in [0] element
;                  Failure: Returns "" and sets @error as follows:
;                             1 - Invalid index
;                             2 - No columns
;                             3 - Invalid row
; Author ........: Melba23
; Modified ......:
; Remarks .......: - New data is inserted after the specified row.
;                  - $vData can be passed in string or array format - it is automatically transformed if required
;                  - $vData as single item - item added to all columns
;                  - $vData as 1D array - see $fMultiRow above
;                  - $vData as 2D array - added as rows/columns
;                  - Native ListViews automatically expand subitem columns to fit inserted data.  Setting the
;                  - $fRetainWidth parameter resets the original width after insertion
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_InsertSpec($iLV_Index, $iRow, $vData, $fMultiRow = False, $fRetainWidth = False)

	Local $vInsert, $iMax_Row

	; Check valid index
	If $iLV_Index < 0 Or $iLV_Index > $aGLVEx_Data[0][0] Then Return SetError(1, 0, "")

	; Load active ListView details
	$hGLVEx_SrcHandle = $aGLVEx_Data[$iLV_Index][0]
	$cGLVEx_SrcID = $aGLVEx_Data[$iLV_Index][1]
	Local $fCheckBox = $aGLVEx_Data[$iLV_Index][6]

	; Copy array for manipulation
	$aGLVEx_SrcArray = $aGLVEx_Data[$iLV_Index][2]
	; Check for empty array
	Local $aHdrData = $aGLVEx_Data[$iLV_Index][25]
	If UBound($aHdrData, 2) = 0 Then
		; No columns to hold row
		$aGLVEx_SrcArray = ""
		Return SetError(2, 0, "")
	EndIf
	$aGLVEx_SrcColArray = $aGLVEx_Data[$iLV_Index][18]

	Local $aCheck_Array[UBound($aGLVEx_SrcArray)]
	For $i = 1 To UBound($aCheck_Array) - 1
		$aCheck_Array[$i] = _GUICtrlListView_GetItemChecked($hGLVEx_SrcHandle, $i - 1)
	Next

	; Check if valid row
	If Not IsArray($aGLVEx_SrcArray) Or UBound($aGLVEx_SrcArray) = 0 Then
		$iMax_Row = 0
	Else
		$iMax_Row = $aGLVEx_SrcArray[0][0]
		If $iRow = -1 Then $iRow = $iMax_Row
		If $iRow < 0 Or $iRow > $iMax_Row Then Return SetError(3, 0, "")
	EndIf

	; Get data into array format for insert
	If IsArray($vData) Then
		$vInsert = $vData
	Else
		Local $aData = StringSplit($vData, $aGLVEx_Data[0][24])
		Switch $aData[0]
			Case 1
				$vInsert = $aData[1]
			Case Else
				Local $vInsert[$aData[0]]
				For $i = 0 To $aData[0] - 1
					$vInsert[$i] = $aData[$i + 1]
				Next
		EndSwitch
	EndIf

	; Set no redraw flag - prevents problems while colour arrays are updated
	$aGLVEx_Data[0][12] = True

	; Insert data into arrays
	If $iRow = -1 Then
		__GUIListViewEx_Array_Add($aGLVEx_SrcArray, $vInsert, $fMultiRow)
		__GUIListViewEx_Array_Add($aCheck_Array, $vInsert, $fMultiRow)
		__GUIListViewEx_Array_Add($aGLVEx_SrcColArray, ";", $fMultiRow)
	Else
		__GUIListViewEx_Array_Insert($aGLVEx_SrcArray, $iRow + 1, $vInsert, $fMultiRow)
		__GUIListViewEx_Array_Insert($aCheck_Array, $iRow + 1, $vInsert, $fMultiRow)
		__GUIListViewEx_Array_Insert($aGLVEx_SrcColArray, $iRow + 1, ";", $fMultiRow)
	EndIf

	; If Loop No Redraw flag set
	If $aGLVEx_Data[0][15] Then
		; Rewrite ListView
		__GUIListViewEx_ReWriteLV($hGLVEx_SrcHandle, $aGLVEx_SrcArray, $aCheck_Array, $iLV_Index, $fCheckBox, $fRetainWidth)
	EndIf

	; Set highlight
	If $iRow = -1 Then
		__GUIListViewEx_HighLight($hGLVEx_SrcHandle, $cGLVEx_SrcID, _GUICtrlListView_GetItemCount($hGLVEx_SrcHandle) - 1)
	Else
		__GUIListViewEx_HighLight($hGLVEx_SrcHandle, $cGLVEx_SrcID, $iRow)
	EndIf

	; Store amended array
	$aGLVEx_Data[$iLV_Index][2] = $aGLVEx_SrcArray
	$aGLVEx_Data[$iLV_Index][18] = $aGLVEx_SrcColArray
	; Delete copied array
	$aGLVEx_SrcArray = 0
	$aGLVEx_SrcColArray = 0

	; Clear no redraw flag
	$aGLVEx_Data[0][12] = False

	; If colour used or single cell selection
	__GUIListViewEx_RedrawWindow($iLV_Index)

	; Return amended array
	Return _GUIListViewEx_ReturnArray($iLV_Index)

EndFunc   ;==>_GUIListViewEx_InsertSpec

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_Delete
; Description ...: Deletes selected row(s) in active ListView
; Syntax.........: _GUIListViewEx_Delete([$vRange = ""])
; Parameters ....: $vRange - items to delete.  If no parameter passed any selected items are deleted
; Requirement(s).: v3.3.10 +
; Return values .: Success: Array of active ListView content with count in [0] element
;                  Failure: Returns "" and sets @error as follows:
;                      1 = No ListView active
;                      2 = No row selected
;                      3 = No items to delete
;                      4 = Invalid range parameter
; Author ........: Melba23
; Modified ......:
; Remarks .......: If multiple items are selected, all are deleted
;                  $vRange must be semicolon-delimited with hypenated consecutive values.
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_Delete($vRange = "")

	; Set data for active ListView
	Local $iLV_Index = $aGLVEx_Data[0][1]
	; If no ListView active then return
	If $iLV_Index = 0 Then Return SetError(1, 0, "")

	Local $vRet = _GUIListViewEx_DeleteSpec($iLV_Index, $vRange)
	Local $iError = @error

	; Check if no rows left
	Local $bEmpty = False
	; If 0-based look for zero rows
	If UBound($vRet) = 0 Then
		$bEmpty = True
	Else
		; Check type of array returned
		If UBound($vRet, 2) <> 0 Then
			; 2D array
			If $vRet[0][0] = 0 Then
				$bEmpty = True
			EndIf
		Else
			; 1D array
			If $vRet[0] = 0 Then
				$bEmpty = True
			EndIf
		EndIf
	EndIf
	If $bEmpty Then
		; Show no row selected
		$aGLVEx_Data[$iLV_Index][20] = -1
	EndIf

	Return SetError($iError, 0, $vRet)

EndFunc   ;==>_GUIListViewEx_Delete

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_DeleteSpec
; Description ...: Deletes specified row(s) in specified ListView
; Syntax.........: _GUIListViewEx_DeleteSpec($iLV_Index, $vRange = "")
; Parameters ....: $iLV_Index - Index of ListView as returned by _GUIListViewEx_Init
;                  $vRange    - Items to delete.
;                                   If no parameter passed any selected items are deleted
;                                   If -1 passed last row is deleted
; Requirement(s).: v3.3.10 +
; Return values .: Success: Array of specified ListView content with count in [0] element
;                  Failure: Returns "" and sets @error as follows:
;                      1 = Invalid ListView index
;                      2 = No row selected if no range passed
;                      3 = No items to delete
;                      4 = Invalid range parameter
; Author ........: Melba23
; Modified ......:
; Remarks .......: If multiple items are selected, all are deleted
;                  $vRange must be semicolon-delimited with hypenated consecutive values.
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_DeleteSpec($iLV_Index, $vRange = "")

	; Check valid index
	If $iLV_Index < 0 Or $iLV_Index > $aGLVEx_Data[0][0] Then Return SetError(1, 0, "")

	; Load active ListView details
	$hGLVEx_SrcHandle = $aGLVEx_Data[$iLV_Index][0]
	$cGLVEx_SrcID = $aGLVEx_Data[$iLV_Index][1]
	Local $fCheckBox = $aGLVEx_Data[$iLV_Index][6]

	; Copy array for manipulation
	$aGLVEx_SrcArray = $aGLVEx_Data[$iLV_Index][2]
	If UBound($aGLVEx_SrcArray) = 1 Then ; Check for no rows to delete
		Return SetError(3, 0, "")
	EndIf

	$aGLVEx_SrcColArray = $aGLVEx_Data[$iLV_Index][18]

	; Create Local array for checkboxes (if no checkboxes makes no difference)
	Local $aCheck_Array[UBound($aGLVEx_SrcArray)]
	For $i = 1 To UBound($aCheck_Array) - 1
		$aCheck_Array[$i] = _GUICtrlListView_GetItemChecked($hGLVEx_SrcHandle, $i - 1)
	Next

	If $vRange = "-1" Then
		$vRange = UBound($aGLVEx_SrcArray) - 2
	EndIf

	Local $iIndex, $aIndex

	; Check for range
	If String($vRange) <> "" Then
		$aIndex = __GUIListViewEx_ExpandRange($vRange, $iLV_Index, 0) ; Rows not columns
		If @error Then Return SetError(4, 0, 0)
	Else
		; Check if colour or single cell selection enabled
		If $aGLVEx_Data[$iLV_Index][19] Or $aGLVEx_Data[$iLV_Index][22] Then
			; Use stored value
			$iIndex = $aGLVEx_Data[$iLV_Index][20]
		Else
			; Check actual values
			$iIndex = _GUICtrlListView_GetSelectedIndices($hGLVEx_SrcHandle)
		EndIf

		If $iIndex == "" Then
			Return SetError(2, 0, "")
		EndIf
		; Extract all selected items
		$aIndex = StringSplit($iIndex, $aGLVEx_Data[0][24])
	EndIf

	For $i = 1 To $aIndex[0]
		; Remove highlighting from items
		_GUICtrlListView_SetItemSelected($hGLVEx_SrcHandle, $i, False)
	Next

	; Set no redraw flag - prevents problems while colour arrays are updated
	$aGLVEx_Data[0][12] = True

	; Delete elements from array - start from bottom
	For $i = $aIndex[0] To 1 Step -1
		; Check element exists in array
		If $aIndex[$i] <= UBound($aGLVEx_SrcArray) - 2 Then
			__GUIListViewEx_Array_Delete($aGLVEx_SrcArray, $aIndex[$i] + 1)
			__GUIListViewEx_Array_Delete($aCheck_Array, $aIndex[$i] + 1)
			__GUIListViewEx_Array_Delete($aGLVEx_SrcColArray, $aIndex[$i] + 1)
		EndIf
	Next

	; If Loop No Redraw flag set
	If $aGLVEx_Data[0][15] Then
		; Rewrite ListView
		__GUIListViewEx_ReWriteLV($hGLVEx_SrcHandle, $aGLVEx_SrcArray, $aCheck_Array, $iLV_Index, $fCheckBox)
		; Set highlight
		If $aIndex[1] = 0 Then
			__GUIListViewEx_HighLight($hGLVEx_SrcHandle, $cGLVEx_SrcID, 0)
		Else
			__GUIListViewEx_HighLight($hGLVEx_SrcHandle, $cGLVEx_SrcID, $aIndex[1] - 1)
		EndIf
	EndIf

	; Store amended array
	$aGLVEx_Data[$iLV_Index][2] = $aGLVEx_SrcArray
	$aGLVEx_Data[$iLV_Index][18] = $aGLVEx_SrcColArray
	; Delete copied array
	$aGLVEx_SrcArray = 0
	$aGLVEx_SrcColArray = 0

	; Clear no redraw flag
	$aGLVEx_Data[0][12] = False

	; If colour used or single cell selection
	__GUIListViewEx_RedrawWindow($iLV_Index)

	; Return amended array
	Return _GUIListViewEx_ReturnArray($iLV_Index)

EndFunc   ;==>_GUIListViewEx_DeleteSpec

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_InsertCol
; Description ...: Inserts blank column to right of selected column in active ListView
; Syntax.........: _GUIListViewEx_InsertCol([$sTitle = ""[, $iWidth = 50]])
; Parameters ....: $sTitle - (Optional) Title of column - default none
;                  $iWidth - (Optional) Width of new column - default = 50
; Requirement(s).: v3.3.10 +
; Return values .: Success: Array of active ListView content with count in [0] element
;                  Failure: If no ListView active then returns "" and sets @error to 1
; Author ........: Melba23
; Modified ......:
; Remarks .......:
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_InsertCol($sTitle = "", $iWidth = 50)

	; Set data for active ListView
	Local $iLV_Index = $aGLVEx_Data[0][1]
	; If no ListView active then return
	If $iLV_Index = 0 Then Return SetError(1, 0, "")

	; Pass active column
	Local $vRet = _GUIListViewEx_InsertColSpec($iLV_Index, $aGLVEx_Data[$iLV_Index][21] + 1, $sTitle, $iWidth)

	Return SetError(@error, 0, $vRet)

EndFunc   ;==>_GUIListViewEx_InsertCol

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_InsertColSpec
; Description ...: Inserts specified blank column in specified ListView
; Syntax.........: _GUIListViewEx_InsertColSpec($iLV_Index[, $iCol = -1[, $sTitle = ""[, $iWidth = 50]]])
; Parameters ....: $iLV_Index - Index of ListView as returned by _GUIListViewEx_Init
;                  $iCol      - (Optional) Column to be be inserted - default -1 adds at right
;                  $sTitle    - (Optional) Title of column - default none
;                  $iWidth    - (Optional) Width of new column - default = 50
; Requirement(s).: v3.3.10 +
; Return values .: Success: Array of active ListView content with count in [0] element
;                  Failure: Empty string sets @error to
;                      1 = Invalid ListView index
;                      2 = Invalid column
; Author ........: Melba23
; Modified ......:
; Remarks .......:
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_InsertColSpec($iLV_Index, $iCol = -1, $sTitle = "", $iWidth = 75)

	; Check valid index
	If $iLV_Index < 0 Or $iLV_Index > $aGLVEx_Data[0][0] Then Return SetError(1, 0, "")

	; Load active ListView details
	$hGLVEx_SrcHandle = $aGLVEx_Data[$iLV_Index][0]
	$cGLVEx_SrcID = $aGLVEx_Data[$iLV_Index][1]
	Local $fCheckBox = $aGLVEx_Data[$iLV_Index][6]
	Local $fColourEnabled = $aGLVEx_Data[$iLV_Index][19]
	;Local $fHdrColourEnabled = $aGLVEx_Data[$iLV_Index][24]
	Local $aHdrData

	; Copy arrays for manipulation
	$aGLVEx_SrcArray = $aGLVEx_Data[$iLV_Index][2]
	If $fColourEnabled Then
		$aGLVEx_SrcColArray = $aGLVEx_Data[$iLV_Index][18]
	EndIf
	Local $aEditable = $aGLVEx_Data[$iLV_Index][7]
	$aHdrData = $aGLVEx_Data[$iLV_Index][25]

	; Check if valid column
	Local $iMax_Col = UBound($aGLVEx_SrcArray, 2) - 1
	If $iCol = -1 Then $iCol = $iMax_Col + 1
	If $iCol < 0 Or $iCol > $iMax_Col Then Return SetError(2, 0, "")

	; Create Local array for checkboxes (if no checkboxes makes no difference)
	Local $aCheck_Array[UBound($aGLVEx_SrcArray)]
	For $i = 1 To UBound($aCheck_Array) - 1
		$aCheck_Array[$i] = _GUICtrlListView_GetItemChecked($hGLVEx_SrcHandle, $i - 1)
	Next

	; Set no redraw flag - prevents problems while colour arrays are updated
	$aGLVEx_Data[0][12] = True

	; Add column to array
	If UBound($aHdrData, 2) = 0 Then
		; Empty array so no need to add column as one already exists
	Else
		ReDim $aGLVEx_SrcArray[UBound($aGLVEx_SrcArray)][UBound($aGLVEx_SrcArray, 2) + 1]
		If $fColourEnabled Then
			ReDim $aGLVEx_SrcColArray[UBound($aGLVEx_SrcColArray)][UBound($aGLVEx_SrcColArray, 2) + 1]
		EndIf

		; Move data and blank new column
		For $i = 0 To UBound($aGLVEx_SrcArray) - 1
			For $j = UBound($aGLVEx_SrcArray, 2) - 2 To $iCol Step -1
				$aGLVEx_SrcArray[$i][$j + 1] = $aGLVEx_SrcArray[$i][$j]
				If $fColourEnabled Then
					$aGLVEx_SrcColArray[$i][$j + 1] = $aGLVEx_SrcColArray[$i][$j]
				EndIf
			Next
			$aGLVEx_SrcArray[$i][$iCol] = ""
			If $fColourEnabled Then
				$aGLVEx_SrcColArray[$i][$iCol] = ";"
			EndIf
		Next
	EndIf

	; And now for the editable columns and header data (fixed number of rows)
	ReDim $aEditable[4][UBound($aEditable, 2) + 1]
	ReDim $aHdrData[4][UBound($aHdrData, 2) + 1]
	For $i = 0 To 3
		For $j = UBound($aEditable, 2) - 2 To $iCol Step -1
			$aEditable[$i][$j + 1] = $aEditable[$i][$j]
			$aHdrData[$i][$j + 1] = $aHdrData[$i][$j]
		Next
		$aEditable[$i][$iCol] = ""
	Next
	; Set new column title with default data
	$aHdrData[0][$iCol] = $sTitle
	$aHdrData[1][$iCol] = ";"
	$aHdrData[2][$iCol] = ""
	$aHdrData[3][$iCol] = 0

	; Set row value in [0][0] element - might have been moved
	$aGLVEx_SrcArray[0][0] = _GUICtrlListView_GetItemCount($hGLVEx_SrcHandle)

	; Store amended arrays
	$aGLVEx_Data[$iLV_Index][2] = $aGLVEx_SrcArray
	If $fColourEnabled Then
		$aGLVEx_Data[$iLV_Index][18] = $aGLVEx_SrcColArray
	EndIf
	$aGLVEx_Data[$iLV_Index][7] = $aEditable
	$aGLVEx_Data[$iLV_Index][25] = $aHdrData

	; Add column to ListView
	_GUICtrlListView_InsertColumn($hGLVEx_SrcHandle, $iCol, $sTitle, $iWidth)

	; If Loop No Redraw flag set
	If $aGLVEx_Data[0][15] Then
		; Rewrite ListView
		__GUIListViewEx_ReWriteLV($hGLVEx_SrcHandle, $aGLVEx_SrcArray, $aCheck_Array, $iLV_Index, $fCheckBox)
	EndIf

	; Clear no redraw flag
	$aGLVEx_Data[0][12] = False

	; If colour used or single cell selection
	__GUIListViewEx_RedrawWindow($iLV_Index)

	; Delete copied array
	$aGLVEx_SrcArray = 0
	$aGLVEx_SrcColArray = 0

	; Reset sort array
	Local $aLVSortState[_GUICtrlListView_GetColumnCount($hGLVEx_SrcHandle)]
	$aGLVEx_Data[$iLV_Index][4] = $aLVSortState

	; Return amended array
	Return _GUIListViewEx_ReturnArray($iLV_Index)

EndFunc   ;==>_GUIListViewEx_InsertColSpec

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_DeleteCol
; Description ...: Deletes selected column in active ListView
; Syntax.........: _GUIListViewEx_DeleteCol()
; Parameters ....: None
; Requirement(s).: v3.3.10 +
; Return values .: Success: Array of active ListView content with count in [0] element
;                  Failure: If no ListView active then returns "" and sets @error to 1
; Author ........: Melba23
; Modified ......:
; Remarks .......:
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_DeleteCol()

	; Set data for active ListView
	Local $iLV_Index = $aGLVEx_Data[0][1]
	; If no ListView active then return
	If $iLV_Index = 0 Then Return SetError(1, 0, "")

	; Get active column
	Local $iCol = $aGLVEx_Data[$iLV_Index][21]
	If $iCol = -1 Then $iCol = 0

	; Delete active column
	Local $vRet = _GUIListViewEx_DeleteColSpec($iLV_Index, $iCol)
	Local $iError = @error

	If Not @error Then
		; Check was not last col
		If UBound($vRet, 2) <= $aGLVEx_Data[0][2]  Then
			; Show no col selected
			$aGLVEx_Data[$iLV_Index][21] = -1
		EndIf
	EndIf

	Return SetError($iError, 0, $vRet)

EndFunc   ;==>_GUIListViewEx_DeleteCol

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_DeleteColSpec
; Description ...: Deletes specified column in specified ListView
; Syntax.........: _GUIListViewEx_DeleteCol($iLV_Index[, $iCol = -1])
; Parameters ....: $iLV_Index - Index of ListView as returned by _GUIListViewEx_Init
;                  $iCol      - (Optional) Column to delete - default -1 deletes rightmost column
; Requirement(s).: v3.3.10 +
; Return values .: Success: Array of active ListView content with count in [0] element
;                  Failure: Empty string and sets @error to
;                      1 = Invalid ListView index
;                      2 = Invalid column
; Author ........: Melba23
; Modified ......:
; Remarks .......:
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_DeleteColSpec($iLV_Index, $iCol = -1)

	; Check valid index
	If $iLV_Index < 0 Or $iLV_Index > $aGLVEx_Data[0][0] Then Return SetError(1, 0, "")

	; Load active ListView details
	$hGLVEx_SrcHandle = $aGLVEx_Data[$iLV_Index][0]
	$cGLVEx_SrcID = $aGLVEx_Data[$iLV_Index][1]
	Local $fCheckBox = $aGLVEx_Data[$iLV_Index][6]
	Local $fColourEnabled = $aGLVEx_Data[$iLV_Index][19]
	;Local $fHdrColourEnabled = $aGLVEx_Data[$iLV_Index][24]

	; Copy array for manipulation
	$aGLVEx_SrcArray = $aGLVEx_Data[$iLV_Index][2]

	If $fColourEnabled Then
		$aGLVEx_SrcColArray = $aGLVEx_Data[$iLV_Index][18]
	EndIf
	Local $aEditable = $aGLVEx_Data[$iLV_Index][7]
	Local $aHdrData[4][UBound($aGLVEx_SrcArray, 2)]
	$aHdrData = $aGLVEx_Data[$iLV_Index][25]

	; Check if valid column
	Local $iMax_Col = UBound($aGLVEx_SrcArray, 2) - 1
	If $iCol = -1 Then $iCol = $iMax_Col
	If $iCol < 0 Or $iCol > $iMax_Col Then Return SetError(2, 0, "")

	; Create Local array for checkboxes (if no checkboxes makes no difference)
	Local $aCheck_Array[UBound($aGLVEx_SrcArray)]
	For $i = 1 To UBound($aCheck_Array) - 1
		$aCheck_Array[$i] = _GUICtrlListView_GetItemChecked($hGLVEx_SrcHandle, $i - 1)
	Next

	; Set no redraw flag - prevents problems while colour arrays are updated
	$aGLVEx_Data[0][12] = True

	; Check if deleting only column
	If UBound($aGLVEx_SrcArray, 2) = 1 Then
		; Reset arrays to empty
		ReDim $aGLVEx_SrcArray[1][1]
		$aGLVEx_SrcArray[0][0] = 0
		ReDim $aGLVEx_SrcColArray[1][1]
		ReDim $aEditable[4][0]
		ReDim $aHdrData[4][0]
	Else
		; Move data
		For $i = 0 To UBound($aGLVEx_SrcArray) - 1
			For $j = $iCol To UBound($aGLVEx_SrcArray, 2) - 2
				$aGLVEx_SrcArray[$i][$j] = $aGLVEx_SrcArray[$i][$j + 1]
				If $fColourEnabled Then
					$aGLVEx_SrcColArray[$i][$j] = $aGLVEx_SrcColArray[$i][$j + 1]
				EndIf
			Next
		Next
		; Resize arrays
		ReDim $aGLVEx_SrcArray[UBound($aGLVEx_SrcArray)][UBound($aGLVEx_SrcArray, 2) - 1]
		If $fColourEnabled Then
			ReDim $aGLVEx_SrcColArray[UBound($aGLVEx_SrcColArray)][UBound($aGLVEx_SrcColArray, 2) - 1]
		EndIf
		; And now for the editable columns and header data (fixed number of rows)
		For $i = 0 To 3
			For $j = $iCol To UBound($aEditable, 2) - 2
				$aEditable[$i][$j] = $aEditable[$i][$j + 1]
				$aHdrData[$i][$j] = $aHdrData[$i][$j + 1]
			Next
		Next
		ReDim $aEditable[4][UBound($aEditable, 2) - 1]
		ReDim $aHdrData[4][UBound($aHdrData, 2) - 1]
		; Set row value in [0][0] element - might have been deleted
		$aGLVEx_SrcArray[0][0] = _GUICtrlListView_GetItemCount($hGLVEx_SrcHandle)
	EndIf

	; Delete column from ListView
	_GUICtrlListView_DeleteColumn($hGLVEx_SrcHandle, $iCol)

	; Store amended arrays
	$aGLVEx_Data[$iLV_Index][2] = $aGLVEx_SrcArray
	If $fColourEnabled Then
		$aGLVEx_Data[$iLV_Index][18] = $aGLVEx_SrcColArray
	EndIf
	$aGLVEx_Data[$iLV_Index][7] = $aEditable
	$aGLVEx_Data[$iLV_Index][25] = $aHdrData

	; If Loop No Redraw flag set
	If $aGLVEx_Data[0][15] Then
		; Rewrite ListView
		__GUIListViewEx_ReWriteLV($hGLVEx_SrcHandle, $aGLVEx_SrcArray, $aCheck_Array, $iLV_Index, $fCheckBox)
	EndIf

	; Clear no redraw flag
	$aGLVEx_Data[0][12] = False

	; If colour used or single cell selection
	__GUIListViewEx_RedrawWindow($iLV_Index)

	; Delete copied array
	$aGLVEx_SrcArray = 0
	$aGLVEx_SrcColArray = 0

	; Reset sort array
	Local $aLVSortState[_GUICtrlListView_GetColumnCount($hGLVEx_SrcHandle)]
	$aGLVEx_Data[$iLV_Index][4] = $aLVSortState

	; Return amended array
	Return _GUIListViewEx_ReturnArray($iLV_Index)

EndFunc   ;==>_GUIListViewEx_DeleteColSpec

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_SortCol
; Description ...: Sort specified column in specified ListView
; Syntax.........: _GUIListViewEx_SortCol($iLV_Index[, $iCol = -1])
; Parameters ....: $iLV_Index - Index of ListView as returned by _GUIListViewEx_Init
;                  $iCol      - (Optional) Column to sort - default -1 sorts active column
; Requirement(s).: v3.3.10 +
; Return values .: Success: 1
;                  Failure: 0 and sets @error to
;                      1 = Invalid ListView index
;                      2 = Invalid column
; Author ........: Melba23
; Modified ......:
; Remarks .......:
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_SortCol($iLV_Index, $iCol = -1)

	; Check valid index
	If $iLV_Index < 0 Or $iLV_Index > $aGLVEx_Data[0][0] Then Return SetError(1, 0, 0)

	; Load array
	Local $aGLVEx_SrcArray = $aGLVEx_Data[$iLV_Index][2]
	; Check if valid column
	Local $iMax_Col = UBound($aGLVEx_SrcArray, 2) - 1
	If $iCol = -1 Then
		; Use active column
		$iCol = $aGLVEx_Data[$iLV_Index][21]
	EndIf
	If $iCol < 0 Or $iCol > $iMax_Col Then Return SetError(2, 0, 0)

	; Load current ListView sort state array
	Local $aLVSortState = $aGLVEx_Data[$iLV_Index][4]
	; Sort column
	__GUIListViewEx_ColSort($aGLVEx_Data[$iLV_Index][0], $iLV_Index, $aLVSortState, $iCol)

	Return 1

EndFunc   ;==>_GUIListViewEx_SortCol

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_SetEditStatus
; Description ...: Sets edit on doubleclick mode for specified column(s)
; Syntax.........: _GUIListViewEx_SetEditStatus($iLV_Index, $vCol [, $iMode = 1 , $vParam1 = Default [, $vParam2 = Default]]])
; Parameters ....: $iLV_Index - Index number of ListView as returned by _GUIListViewEx_Init
;                  $vCol      - Column of ListView to set (string or single number)
;                                   All columns: "*"
;                                   Range string example: "1;2;5-6;8-9;10" - expanded automatically
;                  $iMode     - 0 = Not editable
;                                   $vParam1 & $vParam2 ignored
;                  $iMode     - 1 = Editable using manual input
;                                   $vParam1 = 0: (default) Standard text edit
;                                              1: Add UpDown
;                                   $vParam2 = Only used if $vParam set to 1
;                                              Delimited string: "Min value|Max value|0/1" - final value 1 = UpDown wrap
;                  $iMode     - 2 = Editable using combo
;                                   $vParam1 = Content of combo - either delimited string or 0-based array
;                                   $vParam2 = 0: editable combo (default); 1: readonly
;                                                + 2 - Combo list automatically drops down on edit
;                  $iMode     - 3 = Editable using date control
;                                   $vParam1 = Preselected date (yyyy\MM\dd) - default current date. Trailing # for auto dropdown
;                                   $vParam2 = Required display format for DTP control (see below) - default system date setting
;                  $iMode     - 9 = Editable with user-defined function
;                                   $vParam1 = Function as object
; Requirement(s).: v3.3.10 +
; Return values .: Success: 1
;                  Failure: 0 and sets @error as follows:
;                           1 - Invalid ListView Index
;                           2 - Invalid column parameter
;                           3 - Invalid mode
;                           4 - Invalid $vParam1/2 - @extended set as follows
;                               11 = Mode 1: $vParam1 invalid
;                               12 = Mode 1: $vParam2 invalid
;                               21 = Mode 2: $vParam1 not string or array
;                               22 = Mode 2: $vParam2 not boolean
;                               31 = Mode 3: $vParam1 date string incorrectly formatted
;                               91 = Mode 9: $vParam1 not function
; Author ........: Melba23
; Modified ......:
; Remarks .......: - Overrides all previous edit settings for the specified column(s).
;                  - Columns are non-editable by default so function only required to set editable columns
;                  - {ENTER} accepts edit - {TAB} accepts and moves to next cell if EditMode allows
;                  - {ESCAPE} abandons edit, and possibly all text edits if EditMode negative
;                  - Ctrl-{LEFT}{RIGHT}{UP}{DOWN} moves to next cell if EditMode allows
;                        - Accepts input for manual text
;                        - Abandons input for combo and date (because they use arrow keys to modify their data)
;                  - Display format string for date control uses any of following plus required punctuation/spacing:
;                       "d"    - One/two digit day
;                       "dd"   - Two digit day padded with leading zero if required
;                       "ddd"  - 3-char weekday abbreviation
;                       "dddd" - Full weekday name
;                       "h"    - One/two digit hour - 12-hour format
;                       "hh"   - Two digit hour padded with leading zero if required - 12-hour format
;                       "H"    - One/two digit hour - 24-hour format
;                       "HH"   - Two digit hour padded with leading zero if required - 24 hour format
;                       "m"    - One/two digit minute
;                       "mm"   - Two digit minute padded with leading zero if required
;                       "M"    - One/two digit month number
;                       "MM"   - Two digit month number padded with leading zero if required
;                       "MMM"  - 3-char month abbreviation
;                       "MMMM" - Full month name
;                       "t"    - One letter AM/PM abbreviation
;                       "tt"   - Two letter AM/PM abbreviation
;                       "yy"   - Last two digits of year
;                       "yyyy" - Full year
;                   - User-defined function must accept 4 (and only 4) parameters:
;                       ListView handle, ListView index within the UDF, clicked row, clicked column
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_SetEditStatus($iLV_Index, $vCol, $iMode = 1, $vParam1 = Default, $vParam2 = Default)

	; Check valid index
	If $iLV_Index < 1 Or $iLV_Index > $aGLVEx_Data[0][0] Then
		Return SetError(1, 0, 0)
	EndIf

	; Check column index
	Local $aRange = __GUIListViewEx_ExpandRange($vCol, $iLV_Index)
	If @error Then Return SetError(2, 0, 0)

	; Extract editable array
	Local $aEditable = $aGLVEx_Data[$iLV_Index][7]

	Switch $iMode
		Case 0, 1 ; Not editable/editable
			If $vParam1 = Default Then $vParam1 = 0
			If $vParam2 = Default Then $vParam2 = ""
			Switch $vParam1
				Case 0
					If $vParam2 Then
						Return SetError(4, 12, 0)
					EndIf
				Case 1
					If $vParam2 And Not StringRegExp($vParam2, "^\d+\|\d+\|(0|1)$") Then
						Return SetError(4, 12, 0)
					EndIf
				Case Else
					Return SetError(4, 11, 0)
			EndSwitch

			For $i = 1 To $aRange[0]
				; Set/clear status and clear any other edit data
				$aEditable[0][$aRange[$i]] = $iMode
				$aEditable[1][$aRange[$i]] = $vParam1
				$aEditable[2][$aRange[$i]] = $vParam2
			Next

		Case 2
			If Not (IsArray($vParam1) Or IsString($vParam1)) Then
				Return SetError(4, 21, 0)
			EndIf
			If $vParam2 = Default Then $vParam2 = 0
			Switch $vParam2
				Case 0 To 3
					;
				Case Else
					Return SetError(4, 22, 0)
			EndSwitch
			For $i = 1 To $aRange[0]
				; Set status and combo data/format
				$aEditable[0][$aRange[$i]] = 2
				$aEditable[1][$aRange[$i]] = $vParam1
				$aEditable[2][$aRange[$i]] = $vParam2
			Next

		Case 3
			If $vParam1 = Default Then
				$vParam1 = ""
			EndIf
			If Not StringRegExp($vParam1, "^(\d{4}\/\d{2}\/\d{2})?#?$") Then
				Return SetError(4, 31, 0)
			EndIf
			If $vParam2 = Default Then
				$vParam2 = ""
			EndIf
			For $i = 1 To $aRange[0]
				; Set status and date default/format
				$aEditable[0][$aRange[$i]] = 3
				$aEditable[1][$aRange[$i]] = $vParam1
				$aEditable[2][$aRange[$i]] = $vParam2
			Next

		Case 9
			If Not IsFunc($vParam1) Then
				Return SetError(4, 91, 0)
			EndIf
			For $i = 1 To $aRange[0]
				; Set flag
				$aEditable[0][$aRange[$i]] = 9
				$aEditable[1][$aRange[$i]] = $vParam1
			Next

		Case Else
			Return SetError(3, 0, 0)
	EndSwitch

	; Store amended array
	$aGLVEx_Data[$iLV_Index][7] = $aEditable

	; Show success
	Return 1

EndFunc   ;==>_GUIListViewEx_SetEditStatus

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_SetEditKey
; Description ...: Sets key(s) required to begin edit of selected item
; Syntax.........: _GUIListViewEx_SetEditKey([$sKey = Default])
; Parameters ....: $sKey - String of key(s): 0/1/2 modifiers (^ = Ctrl, ! = Alt) plus single main key code from _IsPressed
;                          Default - reset default key = BackSpace
; Requirement(s).: v3.3.10 +
; Return values .: Success: 1
;                  Failure: 0 and sets @error as follows:
;                           1 - Invalid string
; Author ........: Melba23
; Modified ......:
; Remarks .......: Shift key not available as modifier
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_SetEditKey($sKey = Default)

	; Check for default reset
	If $sKey = Default Then
		$aGLVEx_Data[0][23] = "08"
		Return 1
	EndIf
	; Check string format
	If Not StringRegExp($sKey, "(?i)^([!^]){0,2}([0-9a-f]{2})$") Then
		Return SetError(1, 0, 0)
	EndIf
	; Replace modifier(s) and store code
	$aGLVEx_Data[0][23] = StringReplace(StringReplace($sKey, "^", "11;"), "!", "12;")
	Return 1

EndFunc   ;==>_GUIListViewEx_SetEditKey

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_EditItem
; Description ...: Open ListView items for editing programatically
; Syntax.........: _GUIListViewEx_EditItem($iLV_Index, $iRow, $iCol[, $iEditMode = 0[, $iDelta_X = 0[, $iDelta_Y = 0]]])
; Parameters ....: $iLV_Index - Index number of ListView as returned by _GUIListViewEx_Init
;                  $iRow      - Zero-based row of item to edit
;                  $iCol      - Zero-based column of item to edit
;                  $iEditMode - Only used if using Edit control:
;                                    Return after single edit - 0 (default)
;                                    {TAB} and arrow keys move to next item - 2-digit code (row mode/column mode)
;                                        1 = Reaching edge terminates edit process
;                                        2 = Reaching edge remains in place
;                                        3 = Reaching edge loops to opposite edge
;                               	     Positive value = ESC abandons current edit only, previous edits remain
;                                        Negative value = ESC resets all edits in current session
;                               Ignored if using Combo control - return after single edit
;                  $iDelta_X  - Permits fine adjustment of edit control in X axis if needed
;                  $iDelta_Y  - Permits fine adjustment of edit control in Y axis if needed
; Requirement(s).: v3.3.10 +
; Return values .: Success: 2D array of items edited
;                              - Total number of edits in [0][0] element, with each edit following:
;                              - [zero-based row][zero-based column][original content][new content]
;                           @extended set depending on key used to end edit:
;							   - True = {ENTER} pressed
;							   - False = {ESC} pressed
;                  Failure: Sets @error as follows:
;                           1 - Invalid ListView Index
;                           2 - ListView not editable
;                           3 - Invalid row
;                           4 - Invalid column
;                           5 - Invalid edit mode
; Author ........: Melba23
; Modified ......:
; Remarks .......: - Once edit started, all other script activity is suspended as explained for _GUIListViewEx_EventMonitor
;                  - Returned array allows for verification of new value - _GUIListViewEx_ChangeItem can reset original
;                  - @extended value can be used to determine if to continue in a loop post-edit
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_EditItem($iLV_Index, $iRow, $iCol, $iEditMode = 0, $iDelta_X = 0, $iDelta_Y = 0)

	; Activate the ListView
	_GUIListViewEx_SetActive($iLV_Index)
	If @error Then
		Return SetError(1, 0, "")
	EndIf
	; Check row and col values
	Local $iMax = _GUICtrlListView_GetItemCount($hGLVEx_SrcHandle)
	If $iRow < 0 Or $iRow > $iMax - 1 Then
		Return SetError(3, 0, "")
	EndIf
	$iMax = _GUICtrlListView_GetColumnCount($hGLVEx_SrcHandle)
	If $iCol < 0 Or $iCol > $iMax - 1 Then
		Return SetError(4, 0, "")
	EndIf
	; Check edit mode parameter
	Switch Abs($iEditMode)
		Case 0, 11, 12, 13, 21, 22, 23, 31, 32, 33 ; Single edit or both axes set to valid parameter
			; Allow
		Case Else
			Return SetError(5, 0, "")
	EndSwitch
	; Declare location array
	Local $aLocation[2] = [$iRow, $iCol]
	; Start edit - force text edit type
	Local $aEdited = __GUIListViewEx_EditProcess($iLV_Index, $aLocation, $iDelta_X, $iDelta_Y, $iEditMode, True)
	; Check if edits occurred
	If $aEdited[0][0] = 0 Then
		$aEdited = ""
	EndIf
	; Determine key used to exit
	Local $iKeyCode = @extended
	; Wait until return key no longer pressed
	_WinAPI_GetAsyncKeyState($iKeyCode)
	While _WinAPI_GetAsyncKeyState($iKeyCode)
		Sleep(10)
	WEnd
	; Unselect row
	_GUICtrlListView_SetItemSelected($aGLVEx_Data[$iLV_Index][0], -1, False)
	; Set extended value
	SetExtended(($iKeyCode = 0x0D) ? (True) : (False))
	; Return result array
	Return $aEdited

EndFunc   ;==>_GUIListViewEx_EditItem

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_EditWidth
; Description ...: Set required widths for column edit/combo when editing
; Syntax.........: _GUIListViewEx_EditWidth($iLV_Index, $aWidth)
; Parameters ....: $iLV_Index - Index number of ListView as returned by _GUIListViewEx_Init
;                  $aWidth    - Zero-based 1D array of required edit/combo widths where array index = column
;                               0/Default/empty = use actual column width
; Requirement(s).: v3.3.10 +
; Return values .: Success: 1
;                  Failure: 0 and sets @error as follows:
;                           1 - Invalid ListView Index
;                           2 - Invalid $aWidth array
; Author ........: Melba23
; Modified ......:
; Remarks .......: - $aWidth will be ReDimmed to match columns - all values converted to Number datatype.
;                  - Negative value resizes read-only combo edit control, otherwise only dropdown resized.
;                  - Actual column width used if wider than set value
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_EditWidth($iLV_Index, $aWidth)

	; Check valid index
	If $iLV_Index < 1 Or $iLV_Index > $aGLVEx_Data[0][0] Then
		Return SetError(1, 0, 0)
	EndIf
	; Check valid array
	If (Not IsArray($aWidth)) Or (UBound($aWidth, 0) <> 1) Then Return SetError(2, 0, 0)
	; Resize array
	ReDim $aWidth[_GUICtrlListView_GetColumnCount($aGLVEx_Data[$iLV_Index][0])]
	; Store array
	$aGLVEx_Data[$iLV_Index][14] = $aWidth

EndFunc   ;==>_GUIListViewEx_EditWidth

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_ChangeItem
; Description ...: Change ListView item content programatically
; Syntax.........: _GUIListViewEx_ChangeItem($iLV_Index, $iRow, $iCol, $vValue)
; Parameters ....: $iLV_Index - Index number of ListView as returned by _GUIListViewEx_Init
;                  $iRow      - Zero-based row of item to change
;                  $iCol      - Zero-based column of item to change
;                  $vValue    - Content to place in ListView item
; Requirement(s).: v3.3.10 +
; Return values .: Success: Success: Array of current ListView content as returned by _GUIListViewEx_ReturnArray
;                  Failure: Sets @error as follows:
;                           1 - Invalid ListView Index
;                           2 - Deprecated
;                           3 - Invalid row
;                           4 - Invalid column
; Author ........: Melba23
; Modified ......:
; Remarks .......: This function will change content even if column is not editable
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_ChangeItem($iLV_Index, $iRow, $iCol, $vValue)

	; Activate the ListView
	_GUIListViewEx_SetActive($iLV_Index)
	If @error Then
		Return SetError(1, 0, "")
	EndIf
	; Check row and col values
	Local $iMax = _GUICtrlListView_GetItemCount($hGLVEx_SrcHandle)
	If $iRow < 0 Or $iRow > $iMax - 1 Then
		Return SetError(3, 0, "")
	EndIf
	$iMax = _GUICtrlListView_GetColumnCount($hGLVEx_SrcHandle)
	If $iCol < 0 Or $iCol > $iMax - 1 Then
		Return SetError(4, 0, "")
	EndIf
	; Load array
	Local $aData_Array = $aGLVEx_Data[$iLV_Index][2]
	; Amend item text
	_GUICtrlListView_SetItemText($hGLVEx_SrcHandle, $iRow, $vValue, $iCol)
	; Amend array element
	$aData_Array[$iRow + 1][$iCol] = $vValue
	; Store amended array
	$aGLVEx_Data[$iLV_Index][2] = $aData_Array

	; If colour used or single cell selection
	__GUIListViewEx_RedrawWindow($iLV_Index)

	; Return changed array
	Return _GUIListViewEx_ReturnArray($iLV_Index)

EndFunc   ;==>_GUIListViewEx_ChangeItem

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_LoadHdrData
; Description ...: Sets header title, text and back colour (if enabled), edit mode (if enabled), and width resizing mode
; Syntax.........: _GUIListViewEx_LoadHdrData($iLV_Index, $aHdrData)
; Parameters ....: $iLV_Index - Index of ListView
;                  $aColArray - 0-based 4-row 2D array containing titles, semicolon delimited colour strings in RGB hex, edit settings, resize settings
;                                 [0][ColIndex] = Title - only needed if headers colour enabled
;                                 [1][ColIndex] = Colour strings in RGB hex - only if header colour enabled
;                                                    "text;back"          = both colours set
;                                                    "text;" or ";back"   = one colour set
;                                                    ";" or "" or Default = use default colours
;                                 [2][ColIndex] = Empty string or Default = Edit header as text
;                                                 Delimited string        = Edit header with combo - leading @TAB = read only
;                                 [3][ColIndex] = 0                = column resizable
;                                                 Positive integer = fixed width required
;                                                 Default          = fix at current width
; Requirement(s).: v3.3.10 +
; Return values .: Success: Returns 1
;                  Failure: Returns 0 and sets @error as follows:
;                      1 = Invalid index
;                      2 = Invalid array - @extended set as follows:
;                                            0 - Array not 2D
;                                            1 - Not 4 rows
;                                            2 - Incorrect number of columns
;                      3 = Header colour not enabled but colour set
;                      4 = Invalid colour string
; Author ........: Melba23
; Modified ......:
; Remarks .......: Column resize values forced to positive integers - non-numeric values converted to 0
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_LoadHdrData($iLV_Index, $aHdrData)

	; Check valid index
	If $iLV_Index < 0 Or $iLV_Index > $aGLVEx_Data[0][0] Then Return SetError(1, 0, 0)
	; Check array
	If UBound($aHdrData, 0) <> 2 Then
		Return SetError(2, 0, 0)
	EndIf
	If UBound($aHdrData) <> 4 Then
		Return SetError(2, 1, 0)
	EndIf
	If UBound($aHdrData, 2) <> UBound($aGLVEx_Data[$iLV_Index][2], 2) Then
		Return SetError(2, 2, 0)
	EndIf
	; Convert colours to BGR
	Local $sColSet, $aColSplit
	For $i = 0 To UBound($aHdrData, 2) - 1

		; Check titles
		If $aHdrData[0][$i] = Default Then
			$aHdrData[0][$i] = ""
		EndIf

		; Convert colours to BGR
		$sColSet = $aHdrData[1][$i]
		; Force empty colour to ;
		If $sColSet = "" Or $sColSet = Default Then
			$sColSet = ";"
		EndIf
		; Check valid colour string
		If Not StringRegExp($sColSet, "^(\Q0x\E[0-9A-Fa-f]{6})?;(\Q0x\E[0-9A-Fa-f]{6})?$") Then
			Return SetError(4, 0, 0)
		EndIf
		$aColSplit = StringSplit($sColSet, ";")
		; Convert colours to BGR
		For $j = 1 To 2
			; If colour set check header colour enabled
			If $aColSplit[$j] And Not $aGLVEx_Data[$iLV_Index][24] Then
				Return SetError(3, 0, 0)
			Else
				$aColSplit[$j] = StringRegExpReplace($aColSplit[$j], "0x(.{2})(.{2})(.{2})", "0x$3$2$1")
			EndIf
		Next
		; Reset to converted colour
		$aHdrData[1][$i] = $aColSplit[1] & ";" & $aColSplit[2]

		; Check edit parameters
		If $aHdrData[2][$i] = Default Then
			$aHdrData[2][$i] = ""
		EndIf

		; Check resize parameters
		If $aHdrData[3][$i] = Default Then
			$aHdrData[3][$i] = _GUICtrlListView_GetColumnWidth($aGLVEx_Data[$iLV_Index][0], $i)
		Else
			$aHdrData[3][$i] = Abs(Number($aHdrData[3][$i]))
		EndIf

	Next

	; Store header data
	$aGLVEx_Data[$iLV_Index][25] = $aHdrData

	; Force redraw
	__GUIListViewEx_RedrawWindow($iLV_Index, True)

	Return 1

EndFunc   ;==>_GUIListViewEx_LoadHdrData

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_EditHeader
; Description ...: Manual edit of specified ListView header
; Syntax.........: _GUIListViewEx_EditHeader([$iLV_Index = Default[, $iCol = Default[, $iDelta_X = 0[, $iDelta_Y = 0]]]])
; Parameters ....: $iLV_Index - Index number of ListView as returned by _GUIListViewEx_Init - default active ListView
;                  $iCol      - Zero-based column of header to edit
;                  $iDelta_X  - Permits fine adjustment of edit control in X axis if needed
;                  $iDelta_Y  - Permits fine adjustment of edit control in Y axis if needed
; Requirement(s).: v3.3.10 +
; Return values .: Success: Array: 2D array [column][original header text][new header text]
;                  Failure: Empty string and sets @error as follows:
;                           1 - Invalid ListView Index
;                           2 - ListView headers not editable
;                           3 - Invalid column
; Author ........: Melba23
; Modified ......:
; Remarks .......: - Once edit started, all other script activity is suspended until following occurs:
;                      {ENTER}  = Current edit confirmed and editing ended
;                      {ESCAPE} or click on other control = Current edit cancelled and editing ended
;                  - Note this function will alter a header even if the column is not editable
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_EditHeader($iLV_Index = Default, $iCol = Default, $iDelta_X = 0, $iDelta_Y = 0)

	Local $aRet = ""

	If $iLV_Index = Default Then
		$iLV_Index = $aGLVEx_Data[0][1]
	EndIf
	; Activate the ListView
	_GUIListViewEx_SetActive($iLV_Index)
	If @error Then
		Return SetError(1, 0, $aRet)
	EndIf

	Local $hLV_Handle = $aGLVEx_Data[$iLV_Index][0]
	Local $cLV_CID = $aGLVEx_Data[$iLV_Index][1]

	; Check ListView headers are editable
	If $aGLVEx_Data[$iLV_Index][8] = "" Then
		Return SetError(2, 0, $aRet)
	EndIf
	; Check col value
	If $iCol = Default Then
		$iCol = $aGLVEx_Data[0][2]
	EndIf
	Local $iMax = _GUICtrlListView_GetColumnCount($hLV_Handle)
	If $iCol < 0 Or $iCol > $iMax - 1 Then
		Return SetError(3, 0, $aRet)
	EndIf

	Local $tLVPos = DllStructCreate("struct;long X;long Y;endstruct")
	; Get position of ListView within GUI client area
	__GUIListViewEx_GetLVCoords($hLV_Handle, $tLVPos)
	; Get ListView client area to allow for scrollbars
	Local $aLVClient = WinGetClientSize($hLV_Handle)
	; Get ListView font details
	Local $aLV_FontDetails = __GUIListViewEx_GetLVFont($hLV_Handle)
	; Disable ListView
	WinSetState($hLV_Handle, "", @SW_DISABLE)
	; Load header data
	Local $aHdrData = $aGLVEx_Data[$iLV_Index][25]
	; Get current text of header
	Local $aColData, $sHeaderOrgText
	; Check if header colour enabled
	If $aGLVEx_Data[$iLV_Index][24] Then
		$sHeaderOrgText = $aHdrData[0][$iCol]
	Else
		$aColData = _GUICtrlListView_GetColumn($hLV_Handle, $iCol)
		$sHeaderOrgText = $aColData[5]
	EndIf
	; Get required edit coords for 0 item
	Local $aLocation[2] = [0, $iCol]
	Local $aEdit_Coords = __GUIListViewEx_EditCoords($hLV_Handle, $cLV_CID, $aLocation, $tLVPos, $aLVClient[0] - 5, $iDelta_X, $iDelta_Y)
	; Now get header size and adjust coords for header
	Local $hHeader = _GUICtrlListView_GetHeader($hLV_Handle)
	Local $aHeader_Pos = WinGetPos($hHeader)
	$aEdit_Coords[0] -= 2
	$aEdit_Coords[1] -= $aHeader_Pos[3]
	$aEdit_Coords[3] = $aHeader_Pos[3]

	Local $hCombo, $hTemp_Edit, $hTemp_List, $hTemp_Combo, $sCombo_Data

	; Check edit mode
	If $aHdrData[2][$iCol] Then ; Combo
		$sCombo_Data = $aHdrData[2][$iCol]
		; Create temporary combo
		If StringLeft($sCombo_Data, 1) = @TAB Then ; Read only combo
			$cGLVEx_EditID = GUICtrlCreateCombo("", $aEdit_Coords[0], $aEdit_Coords[1], $aEdit_Coords[2], $aEdit_Coords[3], 0x00200043) ; $CBS_DROPDOWNLIST, $CBS_AUTOHSCROLL, $WS_VSCROLL
			$sCombo_Data = StringTrimLeft($sCombo_Data, 1)
		Else ; Normal combo
			$cGLVEx_EditID = GUICtrlCreateCombo("", $aEdit_Coords[0], $aEdit_Coords[1], $aEdit_Coords[2], $aEdit_Coords[3], 0x00200042) ; $CBS_DROPDOWN, $CBS_AUTOHSCROLL, $WS_VSCROLL
		EndIf
		GUICtrlSetData($cGLVEx_EditID, $sCombo_Data)
		; Get combo data
		$hCombo = GUICtrlGetHandle($cGLVEx_EditID)
		Local $tInfo = DllStructCreate("dword Size;struct;long EditLeft;long EditTop;long EditRight;long EditBottom;endstruct;" & _
				"struct;long BtnLeft;long BtnTop;long BtnRight;long BtnBottom;endstruct;dword BtnState;hwnd hCombo;hwnd hEdit;hwnd hList")
		Local $iInfo = DllStructGetSize($tInfo)
		DllStructSetData($tInfo, "Size", $iInfo)
		_SendMessage($hCombo, 0x164, 0, $tInfo, 0, "wparam", "struct*") ; $CB_GETCOMBOBOXINFO
		$hTemp_Edit = DllStructGetData($tInfo, "hEdit")
		$hTemp_List = DllStructGetData($tInfo, "hList")
		$hTemp_Combo = DllStructGetData($tInfo, "hCombo")
	Else ; Edit
		; Create temporary edit
		$cGLVEx_EditID = GUICtrlCreateEdit($sHeaderOrgText, $aEdit_Coords[0], $aEdit_Coords[1], $aEdit_Coords[2], $aEdit_Coords[3], 0)
		$hTemp_Edit = GUICtrlGetHandle($cGLVEx_EditID)
	EndIf
	; Set font size
	GUICtrlSetFont($cGLVEx_EditID, $aLV_FontDetails[0], Default, Default, $aLV_FontDetails[1])
	; Give keyboard focus
	_WinAPI_SetFocus($hTemp_Edit)
	; Check "select all" flag state
	If Not $aGLVEx_Data[$iLV_Index][11] Then
		GUICtrlSendMsg($cGLVEx_EditID, 0xB1, 0, -1) ; $EM_SETSEL
	EndIf

	Local $tMouseClick = DllStructCreate($tagPOINT)

	; Valid keys to action (ENTER, ESC)
	Local $aKeys[2] = [0x0D, 0x1B]
	; Clear key code flag
	Local $iKey_Code = 0
	Local $fCombo_State = False
	; Prevent GUI closure on ESC as needed to exit edit
	Local $iOldESC = Opt("GUICloseOnESC", 0)

	; Wait for a key press
	While 1
		; Check for SYSCOMMAND Close Event
		If $aGLVEx_Data[0][9] Then
			$aGLVEx_Data[0][9] = False
			ExitLoop
		EndIf
		; Check for valid key or mouse button pressed or combo open/close
		For $i = 0 To 1
			_WinAPI_GetAsyncKeyState($aKeys[$i])
			If _WinAPI_GetAsyncKeyState($aKeys[$i]) Then
				; Set key pressed flag
				$iKey_Code = $aKeys[$i]
				ExitLoop 2
			EndIf
		Next
		; Temp input loses focus
		If _WinAPI_GetFocus() <> $hTemp_Edit Then
			ExitLoop
		EndIf
		; Check for mouse pressed outside edit
		_WinAPI_GetAsyncKeyState(0x01)
		If _WinAPI_GetAsyncKeyState(0x01) Then
			; Look for clicks outside edit/combo control
			DllStructSetData($tMouseClick, "x", MouseGetPos(0))
			DllStructSetData($tMouseClick, "y", MouseGetPos(1))
			Switch _WinAPI_WindowFromPoint($tMouseClick)
				Case $hTemp_Combo, $hTemp_Edit, $hTemp_List
					; Over edit/combo
				Case Else
					ExitLoop
			EndSwitch
			; Wait for mouse button release
			_WinAPI_GetAsyncKeyState(0x01)
			While _WinAPI_GetAsyncKeyState(0x01)
				Sleep(10)
			WEnd
		EndIf
		If $hCombo Then
			; Check for dropdown open and close
			Switch _SendMessage($hCombo, 0x157) ; $CB_GETDROPPEDSTATE
				Case 0
					; If opened and closed
					If $fCombo_State = True Then
						; If no content
						If GUICtrlRead($cGLVEx_EditID) = "" Then
							; Ignore
							$fCombo_State = False
						Else
							; Act as if Enter pressed
							$iKey_Code = 0x0D
							ExitLoop
						EndIf
					EndIf
				Case 1
					; Set flag if opened
					If Not $fCombo_State Then
						$fCombo_State = True
					EndIf
			EndSwitch
		EndIf
		; Save CPU
		Sleep(10)
	WEnd
	; Action keypress
	Switch $iKey_Code
		Case 0x0D
			; Change column header text
			Local $sHeaderNewText = GUICtrlRead($cGLVEx_EditID)
			If $sHeaderNewText <> $sHeaderOrgText Then
				; Check if header colour enabled
				If $aGLVEx_Data[$iLV_Index][24] Then
					$aHdrData[0][$iCol] = $sHeaderNewText

				Else
					_GUICtrlListView_SetColumn($hLV_Handle, $iCol, $sHeaderNewText)
				EndIf
				; Save header data
				$aGLVEx_Data[$iLV_Index][25] = $aHdrData
				Local $aRet[1][3] = [[$iCol, $sHeaderOrgText, $sHeaderNewText]]
			EndIf
		Case Else
			; Return empty string
			$aRet = ""
	EndSwitch
	; Wait until key no longer pressed
	_WinAPI_GetAsyncKeyState($iKey_Code)
	While _WinAPI_GetAsyncKeyState($iKey_Code)
		Sleep(10)
	WEnd

	; Reset user value
	Opt("GUICloseOnESC", $iOldESC)
	; Delete Edit
	GUICtrlDelete($cGLVEx_EditID)
	; Reenable ListView
	WinSetState($hLV_Handle, "", @SW_ENABLE)

	Return $aRet

EndFunc   ;==>_GUIListViewEx_EditHeader

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_LoadColour
; Description ...: Uses array to set text and back colour for a user colour enabled ListView
; Syntax.........: _GUIListViewEx_LoadColour($iLV_Index, $aColArray)
; Parameters ....: $iLV_Index - Index of ListView
;                  $aColArray - 0-based 2D array containing colour strings in RGB hex
;                                    "text;back"        = both user colours set
;                                    "text;" or ";back" = one user colour set
;                                    ";" or ""          = default colours
; Requirement(s).: v3.3.10 +
; Return values .: Success: Returns 1
;                  Failure: Returns 0 and sets @error as follows:
;                      1 = Invalid index
;                      2 = ListView not user colour enabled
;                      3 = Array not 2D (@extended = 0) or not correct size for LV (@extended = 1)
;                      4 = Invalid colour string in array
; Author ........: Melba23
; Modified ......:
; Remarks .......:
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_LoadColour($iLV_Index, $aColArray)

	Local $sColSet

	; Check valid index
	If $iLV_Index < 0 Or $iLV_Index > $aGLVEx_Data[0][0] Then Return SetError(1, 0, 0)
	; Check ListView is user colour enabled
	If Not $aGLVEx_Data[$iLV_Index][19] Then
		Return SetError(2, 0, 0)
	EndIf
	If UBound($aColArray, 0) <> 2 Then
		Return SetError(3, 0, 0)
	EndIf

	; Add a 0-line to match the stored data array
	_ArrayInsert($aColArray, 0)
	; Compare sizes
	If (UBound($aColArray) <> UBound($aGLVEx_Data[$iLV_Index][2])) Or (UBound($aColArray, 2) <> UBound($aGLVEx_Data[$iLV_Index][2], 2)) Then
		Return SetError(3, 1, 0)
	EndIf
	; Convert all colours to BGR
	For $i = 1 To UBound($aColArray, 1) - 1
		For $j = 0 To UBound($aColArray, 2) - 1
			$sColSet = $aColArray[$i][$j]
			If $sColSet = "" Then
				$sColSet = ";"
				$aColArray[$i][$j] = ";"
			EndIf
			If Not StringRegExp($sColSet, "^(\Q0x\E[0-9A-Fa-f]{6})?;(\Q0x\E[0-9A-Fa-f]{6})?$") Then
				Return SetError(4, 0, 0)
			EndIf
			$aColArray[$i][$j] = StringRegExpReplace($sColSet, "0x(.{2})(.{2})(.{2})", "0x$3$2$1")
		Next
	Next
	$aGLVEx_Data[$iLV_Index][18] = $aColArray

	Return 1

EndFunc   ;==>_GUIListViewEx_LoadColour

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_SetDefColours
; Description ...: Sets default colours for user colour/single cell select enabled ListViews
; Syntax.........: _GUIListViewEx_SetDefColours($iLV_Index, $aDefCols)
; Parameters ....: $iLV_Index - Index of ListView
;                  $aDefCols  - 1D 5-element array of hex RGB default colour strings
;                                 [Normal text, Normal field, Selected text, Selected field, Edit field]
; Requirement(s).: v3.3.10 +
; Return values .: Success: Returns 1
;                  Failure: Returns 0 and sets @error as follows:
;                      1 = Invalid index
;                      2 = Not user colour or single cell selection enabled
;                      3 = Invalid array
;                      4 - Invalid colour elements 0-3
;                      5 - Invalid colour edit field
; Author ........: Melba23
; Modified ......:
; Remarks .......: Setting element to Default resets the original default colour
;                  Setting element to "" maintains current default colour
;                  Normal colours are used for all non-user coloured ListView items
;                  Selected colours used for row/single cell selection
;                  Edit field used for input when editing
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_SetDefColours($iLV_Index, $aDefCols)

	; Check valid index
	If $iLV_Index < 0 Or $iLV_Index > $aGLVEx_Data[0][0] Then Return SetError(1, 0, 0)
	; Check colour or single cell enabled
	If Not ($aGLVEx_Data[$iLV_Index][19] Or $aGLVEx_Data[$iLV_Index][22]) Then Return SetError(2, 0, 0)
	; Check valid array
	If Not IsArray($aDefCols) Or UBound($aDefCols) <> 5 Or UBound($aDefCols, 0) <> 1 Then Return SetError(3, 0, 0)

	; Load current colours
	Local $aCurCols = $aGLVEx_Data[$iLV_Index][23]

	; Loop through elements 0-3
	Local $sCol
	For $i = 0 To 3
		If $aDefCols[$i] = Default Then
			; Reset default colour
			$aDefCols[$i] = $aGLVEx_DefColours[$i]
		ElseIf $aDefCols[$i] = "" Then
			; Maintain current colour
			$aDefCols[$i] = $aCurCols[$i]
		Else
			Switch Number($aDefCols[$i])
				; Check valid colour
				Case 0 To 0xFFFFFF
					; Convert to BGR
					$sCol = '0x' & StringMid($aDefCols[$i], 7, 2) & StringMid($aDefCols[$i], 5, 2) & StringMid($aDefCols[$i], 3, 2)
					; Save in array
					$aDefCols[$i] = $sCol
				Case Else
					Return SetError(4, 0, 0)
			EndSwitch
		EndIf
	Next

	; Now check and store edit field colour
	Switch $aDefCols[4]
		Case Default ; Use default field colour
			$aGLVEx_Data[$iLV_Index][26] = $aGLVEx_DefColours[1]
		Case ""
			;  Use current field colour
		Case 0 To 0xFFFFFF ; Use new colour
			$aGLVEx_Data[$iLV_Index][26] = $aDefCols[4]
		Case Else
			Return SetError(5, 0, 0)
	EndSwitch

	; Truncate and store array
	ReDim $aDefCols[4]
	$aGLVEx_Data[$iLV_Index][23] = $aDefCols

	; Force reload of redraw colour array
	__GUIListViewEx_RedrawWindow($iLV_Index, True)

	Return 1

EndFunc   ;==>_GUIListViewEx_SetDefColours

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_SetColour
; Description ...: Sets text and/or back colour for a user colour enabled ListView item
; Syntax.........: _GUIListViewEx_SetColour($iLV_Index, $sColSet, $iRow, $iCol)
; Parameters ....: $iLV_Index - Index of ListView
;                  $sColSet   - Colour string in RGB hex (0xRRGGBB)
;                                   "text;back"        = both user colours set
;                                   "text;" or ";back" = one user colour set, no change to other
;                                   ";" or ""          = reset both to default colours
;                  $iRow      - Row index (0-based)
;                  $iCol      - Column index (0-based)
; Requirement(s).: v3.3.10 +
; Return values .: Success: Returns 1
;                  Failure: Returns 0 and sets @error as follows:
;                      1 = Invalid index
;                      2 = Not user colour enabled
;                      3 = Invalid colour
;                      4 - Invalid row/col
; Author ........: Melba23
; Modified ......:
; Remarks .......:
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_SetColour($iLV_Index, $sColSet, $iRow, $iCol)

	; Activate the ListView
	_GUIListViewEx_SetActive($iLV_Index)
	If @error Then
		Return SetError(1, 0, 0)
	EndIf
	; Check ListView is user colour enabled
	If Not $aGLVEx_Data[$iLV_Index][19] Then
		Return SetError(2, 0, 0)
	EndIf
	; Check colour
	If $sColSet = "" Then
		$sColSet = ";"
	EndIf
	; Check for default colour setting and set flag
	Local $fDefCol = (($sColSet = ";") ? (True) : (False))
	; Check for valid colour strings
	If Not StringRegExp($sColSet, "^(\Q0x\E[0-9A-Fa-f]{6})?;(\Q0x\E[0-9A-Fa-f]{6})?$") Then
		Return SetError(3, 0, 0)
	EndIf
	; Load current array
	Local $aColArray = $aGLVEx_Data[$iLV_Index][18]

	; Check position exists in ListView
	If $iRow < 0 Or $iCol < 0 Or $iRow > UBound($aColArray) - 2 Or $iCol > UBound($aColArray, 2) - 1 Then
		Return SetError(4, 0, 0)
	EndIf
	; Current colour
	Local $aCurrSplit = StringSplit($aColArray[$iRow + 1][$iCol], ";")
	; New colour
	Local $aNewSplit = StringSplit($sColSet, ";")
	; Replace if required
	For $i = 1 To 2
		If $aNewSplit[$i] Then
			; Convert to BGR
			$aCurrSplit[$i] = '0x' & StringMid($aNewSplit[$i], 7, 2) & StringMid($aNewSplit[$i], 5, 2) & StringMid($aNewSplit[$i], 3, 2)
		EndIf
		If $fDefCol Then
			; Reset default
			$aCurrSplit[$i] = ""
		EndIf
	Next
	; Store new colour
	$aColArray[$iRow + 1][$iCol] = $aCurrSplit[1] & ";" & $aCurrSplit[2]
	; Store amended array
	$aGLVEx_Data[$iLV_Index][18] = $aColArray

	; Force reload of redraw colour array
	$aGLVEx_Data[0][14] = 0
	; Redraw listView item to show colour
	_GUICtrlListView_RedrawItems($aGLVEx_Data[$iLV_Index][0], $iRow, $iRow)

	Return 1

EndFunc   ;==>_GUIListViewEx_SetColour

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_BlockReDraw
; Description ...: Prevents ListView redrawing during looped Insert/Delete/Change calls
; Syntax.........: _GUIListViewEx_BlockReDraw($iLV_Index, $fMode)
; Parameters ....: $iLV_Index - Index number of ListView as returned by _GUIListViewEx_Init
;                  $fMode     - True  = Prevent redrawing during Insert/Delete/Change calls
;                             - False = Allow future redrawing and force a redraw
; Requirement(s).: v3.3.10 +
; Return values .: Success: 1
;                  Failure: 0 and sets @error as follows:
;                           1 - Invalid ListView Index
;                           2 - Invalid $fMode
; Author ........: Melba23
; Modified ......:
; Remarks .......: Allows multiple items to be inserted/deleted/changed programatically without redrawing the ListView
;                  after each call. When block removed, ListView is redrawn to update with new content
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_BlockReDraw($iLV_Index, $bMode)

	; Check valid index
	If $iLV_Index < 1 Or $iLV_Index > $aGLVEx_Data[0][0] Then
		Return SetError(1, 0, 0)
	EndIf
	Switch $bMode
		Case True
			; Clear redraw flag
			$aGLVEx_Data[0][15] = False

		Case False
			; Set redraw flag
			$aGLVEx_Data[0][15] = True
			; Force ListView redraw to current content
			Local $aData_Array = $aGLVEx_Data[$iLV_Index][2]
			Local $aCheck_Array[UBound($aData_Array)]
			For $i = 1 To UBound($aCheck_Array) - 1
				$aCheck_Array[$i] = _GUICtrlListView_GetItemChecked($hGLVEx_SrcHandle, $i - 1)
			Next
			__GUIListViewEx_ReWriteLV($aGLVEx_Data[$iLV_Index][0], $aData_Array, $aCheck_Array, $iLV_Index, $aGLVEx_Data[$iLV_Index][6])

		Case Else
			Return SetError(2, 0, 0)
	EndSwitch
	Return 1

EndFunc   ;==>_GUIListViewEx_BlockReDraw

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_UserSort
; Description ...: Sets user defined sort function for specified columns
; Syntax.........: _GUIListViewEx_UserSort($iLV_Index, $vCol [, $hFunc = -1])
; Parameters ....: $iLV_Index - Index number of ListView as returned by _GUIListViewEx_Init
;                  $vCol      - Column of ListView to set (string or single number)
;                                   All columns: "*"
;                                   Range string example: "1;2;5-6;8-9;10" - expanded automatically
;                  $hFunc     - User function as object - set to -1 for no sort (default)
; Requirement(s).: v3.3.10 +
; Return values .: Success: 1
;                  Failure: 0 and sets @error as follows:
;                             1 - Invalid ListView Index
;                             2 - ListView not sortable
;                             3 - Invalid column parameter
;                             4 - Invalid function object
; Author ........: Melba23
; Modified ......:
; Remarks .......: If function not specified for a column then default sort function used (standard _ArraySort)
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_UserSort($iLV_Index, $vCol, $hFunc = -1)

	; Check valid index
	If $iLV_Index < 1 Or $iLV_Index > $aGLVEx_Data[0][0] Then
		Return SetError(1, 0, 0)
	EndIf
	; Check if ListView sortable
	If Not (IsArray($aGLVEx_Data[$iLV_Index][4])) Then
		Return SetError(2, 0, 0)
	EndIf
	; Check column index
	Local $aRange = __GUIListViewEx_ExpandRange($vCol, $iLV_Index)
	If @error Then Return SetError(3, 0, 0)
	; Check function object (or none)
	If Not ($hFunc = -1) And Not (IsFunc($hFunc)) Then
		Return SetError(4, 0, 0)
	EndIf

	; Extract, amend and store editable array
	Local $aEditable = $aGLVEx_Data[$iLV_Index][7]
	For $i = 1 To $aRange[0]
		$aEditable[3][$aRange[$i]] = $hFunc
	Next
	$aGLVEx_Data[$iLV_Index][7] = $aEditable

	Return 1

EndFunc   ;==>_GUIListViewEx_UserSort

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_SelectItem
; Description ...: Programatically select row - and item if single selection available - in active ListView
; Syntax.........: _GUIListViewEx_SelectItem($iRow[, $iCol])
; Parameters ....: $iRow - 0-based row to select
;                  $iCol - 0-based column to select only if single cell selection is available - else column 0
; Requirement(s).: v3.3.10 +
; Return values .: Success: 1
;                  Failure: 0 and sets @error as follows:
;                               1 = Invalid row parameter
;                               2 = Invalid column parameter
; Author ........: Melba23
; Modified ......:
; Remarks .......: Operates on active ListView - use _GUIListViewEx_SetActive to select
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_SelectItem($iRow, $iCol = -1)

	; Get active LV handle
	Local $hLVHandle = $aGLVEx_Data[$aGLVEx_Data[0][1]][0]
	Local $cLV_CID = $aGLVEx_Data[$aGLVEx_Data[0][1]][1]

	; Check for valid row
	$iRow = Int($iRow)
	If $iRow < 0 Then Return SetError(1, 0, 0)
	If $iRow > _GUICtrlListView_GetItemCount($hLVHandle) - 1 Then Return SetError(1, 0, 0)

	;Check for valid column if required
	If $iCol <> -1 Then
		$iCol = int($iCol)
		If $iCol < 0 Then Return SetError(2, 0, 0)
		If $iCol > _GUICtrlListView_GetColumnCount($hLVHandle) - 1 Then Return SetError(2, 0, 0)
	EndIf

	; Remove all current highlighting
	_GUICtrlListView_SetItemSelected($hLVHandle, -1, False)

	; Set required row - and column if required
	__GUIListViewEx_HighLight($hLVHandle, $cLV_CID, $iRow)

	; Set selected row/col data in UDF arrays
	$aGLVEx_Data[0][2] = $iRow
	$aGLVEx_Data[0][17] = $iRow
	$aGLVEx_Data[0][18] = (($iCol = -1) ? (0) : ($iCol))
	$aGLVEx_Data[$aGLVEx_Data[0][1]][20] = $iRow
	$aGLVEx_Data[$aGLVEx_Data[0][1]][21] = (($iCol = -1) ? (0) : ($iCol))

	Return 1

EndFunc

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_GetLastSelItem
; Description ...: Get last selected item in active or specified ListView
; Syntax.........: _GUIListViewEx_GetLastSelItem($iLV_Index = 0)
; Parameters ....: $iLV_Index - Index of ListView as returned by _GUIListViewEx_Init
;                                 0 = currently active ListView (default)
; Requirement(s).: v3.3.10 +
; Return values .: Success: Delimited string ListViewIndex|Row|Col
;                  Failure: Returns "" and sets @error as follows:
;                      1 = No ListView currently active
;                      2 = Invalid index
;                      3 = No item yet selected in active or specified ListView
; Author ........: Melba23
; Modified ......:
; Remarks .......: If multiple items are selected, only the last selected is returned
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_GetLastSelItem($iLV_Index = 0)

	; Check valid index
	Switch $iLV_Index
		Case 1 To $aGLVEx_Data[0][0]
			; Valid index
		Case 0, Default
			; Get active ListView
			$iLV_Index = _GUIListViewEx_GetActive()
			; If no ListView active
			If $iLV_Index = 0 Then Return SetError(1, 0, "")
		Case Else
			Return SetError(2, 0, "")
	EndSwitch

	; Read last selected item
	Local $iRow = $aGLVEx_Data[$iLV_Index][20]
	Local $iCol = $aGLVEx_Data[$iLV_Index][21]
	; Check selection has been made
	If $iRow = -1 Or $iCol = -1 Then Return SetError(3, 0, "")
	; Return selection details
	Return $iLV_Index & "|" & $iRow & "|" & $iCol

EndFunc   ;==>_GUIListViewEx_GetLastSelItem

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_ContextPos
; Description ...: Returns index and row/col of last right click
; Syntax.........: _GUIListViewEx_ContextPos()
; Parameters ....: None
; Requirement(s).: v3.3.10 +
; Return values .: Success: Returns 3 element array: [ListView_index, Row, Column]
;                  Failure: Returns empty string and sets @error to 1
; Author ........: Melba23
; Modified ......:
; Remarks .......: Allows user colours to be set via a context menu
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_ContextPos()

	If $aGLVEx_Data[0][10] = -1 Then
		Return SetError(1, 0, "")
	Else
		Local $aPos[3] = [$aGLVEx_Data[0][1], $aGLVEx_Data[0][10], $aGLVEx_Data[0][11]]
		Return $aPos
	EndIf

EndFunc   ;==>_GUIListViewEx_ContextPos

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_ToolTipInit
; Description ...: Defines column(s) which will display a tooltip when clicked
; Syntax.........: _GUIListViewEx_ToolTipInit($iLV_Index, $vRange [, $iTime = 1000 ], $iMode = 1]])
; Parameters ....: $iLV_Index - Index of ListView holding columns
;                  $vRange    - Range of columns - see remarks
;                  $iTime     - Time for tooltip to display (default = 1000)
;                  $iMode     - Display: 1 (default) = cell content, 2 = 0 column
; Requirement(s).: v3.3.10 +
; Return values .: Success: Returns 1
;                  Failure: Returns 0 and sets @error as follows:
;                      1 = Invalid index
;                      2 = Invalid range
;                      3 = Invalid time
; Author ........: Melba23
; Modified ......:
; Remarks .......: - Function is designed to show:
;                      Mode 1: ListView content if column is too narrow for data within
;                      Mode 2: 0 column data to allow for row identification when ListView right scrolled
;                  - $vRange is a string containing the rows which show tooltips.
;                      It can be a single number or a range separated by a hyphen (-).
;                      Multiple items are separated by a semi-colon (;).
;                      "*" = all columns
;                  - _GUIListViewEx_EventMonitor must be placed in the script idle loop for the tooltips to display
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_ToolTipInit($iLV_Index, $vRange, $iTime = 1000, $iMode = 1)

	; Check valid parameters
	If $iLV_Index < 0 Or $iLV_Index > $aGLVEx_Data[0][0] Then Return SetError(1, 0, 0)
	Local $aRange = __GUIListViewEx_ExpandRange($vRange, $iLV_Index)
	If @error Then Return SetError(2, 0, 0)
	If Not IsInt($iTime) Then Return SetError(3, 0, 0)

	; Store data
	$aGLVEx_Data[$iLV_Index][15] = $aRange
	$aGLVEx_Data[$iLV_Index][16] = $iTime
	$aGLVEx_Data[$iLV_Index][17] = $iMode

	Return 1

EndFunc   ;==>_GUIListViewEx_ToolTipInit

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_EventMonitor
; Description ...: Check for edit, sort, drag/drop and tooltip events - auto colour redraw - returns event results
; Syntax.........: _GUIListViewEx_EventMonitor([$iEditMode = 0[, $iDelta_X = 0[, $iDelta_Y = 0]]])
; Parameters ....: $iEditMode - Only used if editing cells as simple text:
;                                    Return after single edit - 0 (default)
;                                    {TAB} and ctrl-arrow keys move to next item - 2-digit code (row mode/column mode)
;                                        0 = Cannot move
;                                        1 = Reaching edge terminates edit process
;                                        2 = Reaching edge remains in place
;                                        3 = Reaching edge loops to opposite edge
;                               	     Positive value = ESC abandons current edit only, previous edits remain
;                                        Negative value = ESC resets all edits in current session
;                  $iDelta_X  - Permits fine adjustment of edit control in X axis if needed
;                  $iDelta_Y  - Permits fine adjustment of edit control in Y axis if needed
; Requirement(s).: v3.3.10 +
; Return values .: Success:
;                  No UDF events detected: Empty string and @extended set to 0
;                  Return value is not an empty string, while @extended indicates type of event detected
;                    @extended = 1 - Cell(s) edit event
;                                      Returns 2D array of items edited
;                                          - Total number of edits in [0][0] element, with each edit following:
;                                          - [zero-based row][zero-based column][original content][new content]
;                                2 - Header edit event
;                                      Returns single row 2D array
;                                          - [column edited][original header text][new header text]
;                                3 - ListView sort event
;                                      Returns index number of newly sorted ListView
;                                4 - Drag/drop event
;                                      Returns colon-separated index numbers of "drag" and "drop" ListViews
;                                5 - Column resize event
;                                      Returns column index
;                                6-8 (Not used at present)
;                                9 - User selection change event
;                                      Returns 3-element 1D array
;                                          - [ListView index, zero-based row, zero-based col]
;                  Failure: Sets @error as follows when editing:
;                      1 - Invalid EditMode parameter
;                      2 - Empty ListView
;                      3 - Column not editable
; Author ........: Melba23
; Modified ......:
; Remarks .......: - This function must be placed within the script idle loop.
;                  - Editing cells:
;                      - Using edit mode 1-3:
;                        - Once item edit process started, all other script activity is suspended until following occurs:
;                          {ENTER}  = Current edit confirmed and editing process ended
;                          {ESCAPE} = Current or all edits cancelled and editing process ended
;                          If $iEditMode non-zero then {TAB} and ctrl-arrow keys =
;                              For edit controls: Current edit confirmed & continue editing
;                              For cother controls: Current edit cancelled & continue editing
;                          If using Edit control:
;                              Click outside edit = Editing process ends and
;                                  If $iAdded + 4 : Current edit accepted
;                                  Else           : Current edit cancelled
;                          If using Combo control:
;                              Combo actioned     = Combo selection accepted and editing process ended
;                              Click outside edit = Edit process ended and editing process ended
;                          If using DTP control:
;                              only {ENTER} & {ESCAPE} will end edit
;                        The function only returns an array after an edit process launched by a double-click.  If no
;                        double-click has occurred, the function returns an empty string.  The user should check that a
;                        valid array is present before attempting to access it.
;                    - Using edit mode 9
;                        The function will return the same return values as set by the user-defined function
;                    - If "continue edit on triple click elsewhere" ($iAdded = 4) option is set when ListView intitiated
;                      the function returns an array after each edit.
;                  - Editing header
;                      Only {ENTER}, {ESCAPE} and mouse click are actioned - single edit only
;                  - Returned array allows verification of new value(s) and _GUIListViewEx_ChangeItem can reset original value
;=====================================================================================================================
Func _GUIListViewEx_EventMonitor($iEditMode = 0, $iDelta_X = 0, $iDelta_Y = 0)

	Local $aRet, $vRet, $iLV_Index, $iError

	; Check for a cell Edit double click event
	If $fGLVEx_EditClickFlag <> 0 Then

		; Set active ListView
		$iLV_Index = $fGLVEx_EditClickFlag
		$aGLVEx_Data[0][1] = $iLV_Index

		; Clear flag
		$fGLVEx_EditClickFlag = 0

		; Check Type parameter
		Switch Abs($iEditMode)
			Case 0, 1, 2, 3, 10, 11, 12, 13, 20, 21, 22, 23, 30, 31, 32, 33 ; Single edit or both axes set to valid parameter
				; Allow
			Case Else
				Return SetError(1, 0, "")
		EndSwitch

		; Get clicked item info
		Local $aLocation[2] = [$aGLVEx_Data[0][17], $aGLVEx_Data[0][18]]
		; Check valid row
		If $aLocation[0] = -1 Then
			Return SetError(2, 0, "")
		EndIf
		; Check for valid editable column
		Local $aEditable = $aGLVEx_Data[$iLV_Index][7]
		; If column not selected as mouse not used...
		If $aLocation[1] = -1 Then
			; ...find first editable column
			For $i = 0 To UBound($aEditable, 2) - 1
				If $aEditable[0][$i] <> 0 Then
					$aLocation[1] = $i
					$aGLVEx_Data[0][18] = $i
					ExitLoop
				EndIf
			Next
		EndIf

		Switch $aEditable[0][$aLocation[1]]
			Case 0 ; Not editable
				Return SetError(3, 0, "")

			Case 9 ; User-defined function
				; Extract user function
				Local $hUserFunction = $aEditable[1][$aLocation[1]]
				; Pass function 4 parameters (LV handle, UDF LV index, row, col)
				$vRet = $hUserFunction($hGLVEx_SrcHandle, $iLV_Index, $aLocation[0], $aLocation[1])
				; Return function return values
				Return SetError(@error, @extended, $vRet)

			Case Else
				; Start edit
				$aRet = __GUIListViewEx_EditProcess($iLV_Index, $aLocation, $iDelta_X, $iDelta_Y, $iEditMode)
				$iError = @error
				; Check if edits occurred
				If IsArray($aRet) And $aRet[0][0] Then
					; Return result array
					Return SetError($iError, 1, $aRet)
				Else
					; Return empty string
					Return SetError($iError, 1, "")
				EndIf
		EndSwitch
	EndIf

	; Check for a header Edit Ctrl-click
	If $fGLVEx_HeaderEdit Then
		; Clear the flag
		$fGLVEx_HeaderEdit = False
		; Wait until mouse button released as click occurs outside the control or Ctrl key still pressed
		_WinAPI_GetAsyncKeyState(0x01)
		While _WinAPI_GetAsyncKeyState(0x01) Or _WinAPI_GetAsyncKeyState(0x11)
			Sleep(10)
		WEnd
		; Edit header using the default values set by the handler
		$aRet = _GUIListViewEx_EditHeader()
		$iError = @error
		; Check for edit
		If IsArray($aRet) Then
			; Return result array
			Return SetError($iError, 2, $aRet)
		Else
			; Return empty string
			Return SetError($iError, 2, "")
		EndIf
	EndIf

	; Check for a Sort event
	If $aGLVEx_Data[0][19] Then
		; Save Sort event return
		$vRet = $aGLVEx_Data[0][19]
		; Clear flag
		$aGLVEx_Data[0][19] = ""
		;Check for colour event
		If $aGLVEx_Data[0][22] = 1 Then
			; Redraw ListView and reset flag
			__GUIListViewEx_RedrawWindow($vRet, True)
			$aGLVEx_Data[0][22] = 0
		EndIf
		Return SetError(0, 3, $vRet)
	EndIf

	; Check for a Drag event
	If $sGLVEx_DragEvent Then
		$vRet = $sGLVEx_DragEvent
		; Clear flag
		$sGLVEx_DragEvent = ""
		;Check for colour event
		If $aGLVEx_Data[0][22] Then
			; Redraw ListView(s) and reset flag
			Local $aIndex = StringSplit($vRet, ":")
			__GUIListViewEx_RedrawWindow($aIndex[1], True)
			If $aIndex[2] <> $aIndex[1] Then
				__GUIListViewEx_RedrawWindow($aIndex[2], True)
			EndIf
			$aGLVEx_Data[0][22] = 0
		EndIf

		; Return drag/drop index string
		Return SetError(0, 4, $vRet)
	EndIf

	; Check if tooltips initiated
	Local $iMode = $aGLVEx_Data[$aGLVEx_Data[0][1]][17]
	If $iMode Then
		$iLV_Index = $aGLVEx_Data[0][1]
		Local $fToolTipCol = False
		; Get active cell if single cell selection
		If $aGLVEx_Data[$iLV_Index][21] Then
			$aGLVEx_Data[0][4] = $aGLVEx_Data[0][17]
			$aGLVEx_Data[0][5] = $aGLVEx_Data[0][18]
		EndIf
		; If new item clicked
		If $aGLVEx_Data[0][4] <> $aGLVEx_Data[0][6] Or $aGLVEx_Data[0][5] <> $aGLVEx_Data[0][7] Then
			; Check range
			If $aGLVEx_Data[$iLV_Index][15] = "*" Then
				$fToolTipCol = True
			Else
				If IsArray($aGLVEx_Data[$iLV_Index][15]) Then
					Local $vRange = $aGLVEx_Data[$iLV_Index][15]
					For $i = 1 To $vRange[0]
						; If initiated column
						If $aGLVEx_Data[0][2] = $vRange[$i] Then
							$fToolTipCol = True
							ExitLoop
						EndIf
					Next
				EndIf
			EndIf
		EndIf
		If $fToolTipCol Then
			; Read all row text
			Local $aItemText = _GUICtrlListView_GetItemTextArray($aGLVEx_Data[$iLV_Index][0], $aGLVEx_Data[0][4])
			If Not @error Then
				Local $sText
				Switch $iMode
					Case 1
						$sText = $aItemText[$aGLVEx_Data[0][5] + 1]
					Case 2
						$sText = $aItemText[1]
				EndSwitch
				; Create ToolTip
				ToolTip($sText)
				; Set up clearance
				AdlibRegister("__GUIListViewEx_ToolTipHide", $aGLVEx_Data[$iLV_Index][16])
				; Store location to prevent repeat showing
				$aGLVEx_Data[0][6] = $aGLVEx_Data[0][4]
				$aGLVEx_Data[0][7] = $aGLVEx_Data[0][5]
			EndIf
		EndIf
	EndIf

	; Check for selection change
	If $fGLVEx_SelChangeFlag Then
		; Get selecton data
		Local $aRetArray[3] = [$fGLVEx_SelChangeFlag, $aGLVEx_Data[0][17], $aGLVEx_Data[0][18]]
		; Clear flag
		$fGLVEx_SelChangeFlag = 0
		; Check if user selection
		If $fGLVEx_UserSelFlag Then
			; Clear flag
			$fGLVEx_UserSelFlag = 0
			; Return selection data
			Return SetError(0, 9, $aRetArray)
		EndIf
	EndIf

	; Check for column resizing
	If $fGVLEx_Resized <> -1 Then
		Local $iCol = $fGVLEx_Resized
		$fGVLEx_Resized = -1
		Return SetError(0, 5, $iCol)
	EndIf

	; If no events
	Return SetError(0, 0, "")

EndFunc   ;==>_GUIListViewEx_EventMonitor

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_MsgRegister
; Description ...: Registers Windows messages required for the UDF
; Syntax.........: _GUIListViewEx_MsgRegister([$fNOTIFY = True, [$fMOUSEMOVE = True, [$fLBUTTONUP = True, [ $fSYSCOMMAND = True]]]])
; Parameters ....: $fNOTIFY     - True = Register WM_NOTIFY message
;                  $fMOUSEMOVE  - True = Register WM_MOUSEMOVE message
;                  $fLBUTTONUP  - True = Register WM_LBUTTONUP message
;                  $fSYSCOMMAND - True = Register WM_SYSCOMAMND message
; Requirement(s).: v3.3.10 +
; Return values .: None
; Author ........: Melba23
; Modified ......:
; Remarks .......: If message handlers already registered, then call the relevant handler function from within that handler
;                  WM_NOTIFY handler required for all UDF functions
;                  WM_MOUSEMOVE and WM_LBUTTONUP handlers required for drag
;                  WM_SYSCOMMAND required for single click [X] GUI closure while editing
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_MsgRegister($fNOTIFY = True, $fMOUSEMOVE = True, $fLBUTTONUP = True, $fSYSCOMMAND = True)

	; Register required messages
	If $fNOTIFY Then GUIRegisterMsg(0x004E, "_GUIListViewEx_WM_NOTIFY_Handler") ; $WM_NOTIFY
	If $fMOUSEMOVE Then GUIRegisterMsg(0x0200, "_GUIListViewEx_WM_MOUSEMOVE_Handler") ; $WM_MOUSEMOVE
	If $fLBUTTONUP Then GUIRegisterMsg(0x0202, "_GUIListViewEx_WM_LBUTTONUP_Handler") ; $WM_LBUTTONUP
	If $fSYSCOMMAND Then GUIRegisterMsg(0x0112, "_GUIListViewEx_WM_SYSCOMMAND_Handler") ; $WM_SYSCOMMAND

EndFunc   ;==>_GUIListViewEx_MsgRegister

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_WM_NOTIFY_Handler
; Description ...: Windows message handler for WM_NOTIFY
; Syntax.........: _GUIListViewEx_WM_NOTIFY_Handler()
; Requirement(s).: v3.3.10 +
; Return values .: None
; Author ........: Melba23
; Modified ......:
; Remarks .......: If a WM_NOTIFY handler already registered, then call this function from within that handler
;                  If user colours are enabled, the handler return value must be returned on handler exit
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_WM_NOTIFY_Handler($hWnd, $iMsg, $wParam, $lParam)

	#forceref $hWnd, $iMsg, $wParam

	Local $dwDrawStage, $iCol, $aHdrData

	Local $tStruct = DllStructCreate($tagNMLISTVIEW, $lParam)
	If @error Then Return

	Local $hLV = DllStructGetData($tStruct, 1)
	Local $iItem = DllStructGetData($tStruct, 4)
	Local $iCode = BitAND(DllStructGetData($tStruct, 3), 0xFFFFFFFF)

	; Deal with drawing quickly
	If $iCode = -12 Then ; $NM_CUSTOMDRAW

		; Prevent redraw if still changing ListView arrays
		If $aGLVEx_Data[0][12] Then Return

		; Check if enabled ListView
		For $iLV_Index = 1 To $aGLVEx_Data[0][0]
			If $aGLVEx_Data[$iLV_Index][0] = DllStructGetData($tStruct, 1) Then
				ExitLoop
			EndIf
		Next

		; It is an enabled ListView
		If $iLV_Index <= $aGLVEx_Data[0][0] Then

			Local Static $aDefCols = $aGLVEx_DefColours

			; Check if ListView to be redrawn has changed
			If $aGLVEx_Data[0][14] <> DllStructGetData($tStruct, 1) Then
				; Store new handle
				$aGLVEx_Data[0][14] = DllStructGetData($tStruct, 1)
				If $aGLVEx_Data[$iLV_Index][19] Or $aGLVEx_Data[$iLV_Index][22] Then
					; Copy new colour array
					$aGLVEx_Data[0][13] = $aGLVEx_Data[$iLV_Index][18]
					; Set new default colours
					$aDefCols = $aGLVEx_Data[$iLV_Index][23]
				EndIf
			EndIf
			; If colour or single cell selection
			If $aGLVEx_Data[$iLV_Index][19] Or $aGLVEx_Data[$iLV_Index][22] Then
				Local $tNMLVCUSTOMDRAW = DllStructCreate($tagNMLVCUSTOMDRAW, $lParam)
				$dwDrawStage = DllStructGetData($tNMLVCUSTOMDRAW, "dwDrawStage")
				Switch $dwDrawStage ; Holds a value that specifies the drawing stage
					Case 1 ; $CDDS_PREPAINT
						; Before the paint cycle begins
						Return 32 ; $CDRF_NOTIFYITEMDRAW - Notify the parent window of any item-related drawing operations

					Case 65537 ; $CDDS_ITEMPREPAINT
						; Before painting an item
						Return 32 ; $CDRF_NOTIFYSUBITEMDRAW - Notify the parent window of any subitem-related drawing operations

					Case 196609 ; BitOR($CDDS_ITEMPREPAINT, $CDDS_SUBITEM)
						; Before painting a subitem
						$iItem = DllStructGetData($tNMLVCUSTOMDRAW, "dwItemSpec") ; Row index
						Local $iSubItem = DllStructGetData($tNMLVCUSTOMDRAW, "iSubItem") ; Column index
						; Check if selected row
						Local $bSelColour = False
						If $iItem = $aGLVEx_Data[$iLV_Index][20] Then
							; If single sel also check for column
							If $aGLVEx_Data[$iLV_Index][22] Then
								If $iSubItem = $aGLVEx_Data[$iLV_Index][21] Then
									$bSelColour = True
								EndIf
							Else
								$bSelColour = True
							EndIf
						EndIf
						; Set default colours
						Local $iTextColour = $aDefCols[0]
						Local $iBackColour = $aDefCols[1]
						; Set selected colours if required
						If $bSelColour Then
							; Set selected item colours
							$iTextColour = $aDefCols[2]
							$iBackColour = $aDefCols[3]
						Else
							; If colour enabled
							If $aGLVEx_Data[$iLV_Index][19] Then
								; Check for user colours
								If StringInStr(($aGLVEx_Data[0][13])[$iItem + 1][$iSubItem], ";") Then
									; Get required user colours
									Local $aSplitColour = StringSplit(($aGLVEx_Data[0][13])[$iItem + 1][$iSubItem], ";")
									If $aSplitColour[1] Then $iTextColour = $aSplitColour[1]
									If $aSplitColour[2] Then $iBackColour = $aSplitColour[2]
								EndIf
							EndIf
						EndIf

						; Set required colours
						DllStructSetData($tNMLVCUSTOMDRAW, "ClrText", $iTextColour)
						DllStructSetData($tNMLVCUSTOMDRAW, "ClrTextBk", $iBackColour)
						Return 2 ; $CDRF_NEWFONT must be returned after changing font or colors
				EndSwitch
			EndIf

		Else

			; Check if colour enabled header
			For $iLV_Index = 1 To $aGLVEx_Data[0][0]
				If DllStructGetData($tStruct, 1) = $aGLVEx_Data[$iLV_Index][24] Then
					ExitLoop
				EndIf
			Next
			; It is a colour enabled header
			If $iLV_Index <= $aGLVEx_Data[0][0] Then

				Local $tNMCustomDraw = DllStructCreate($tagNMLVCUSTOMDRAW, $lParam)
				Local $hDC = DllStructGetData($tNMCustomDraw, "hdc")

				; Check if ListView to be redrawn has changed
				If $aGLVEx_Data[0][20] <> DllStructGetData($tStruct, 1) Then
					; Store new handle
					$aGLVEx_Data[0][20] = DllStructGetData($tStruct, 1)
					; Get header font
					Local $hFont = _SendMessage(DllStructGetData($tStruct, 1), 0x0031) ; $WM_GETFONT
					Local $hObject = _WinAPI_SelectObject($hDC, $hFont)
					Local $tLogFont = DllStructCreate($tagLOGFONT)
					; Get header font
					_WinAPI_GetObject($hFont, DllStructGetSize($tLogFont), DllStructGetPtr($tLogFont))
					_WinAPI_SelectObject($hDC, $hObject)
					_WinAPI_ReleaseDC(DllStructGetData($tStruct, 1), $hDC)
					; Set to medium weight
					DllStructSetData($tLogFont, "Weight", 600) ; $FW_SEMIBOLD
					; Store font handle
					$aGLVEx_Data[0][21] = _WinAPI_CreateFontIndirect($tLogFont)
				EndIf

				; Check drawing stage
				$dwDrawStage = DllStructGetData($tNMCustomDraw, "dwDrawStage")
				Switch $dwDrawStage
					Case 1 ; $CDDS_PREPAINT ; Before the paint cycle begins
						Return 32 ; $CDRF_NOTIFYITEMDRAW ; Notify parent window of coming item related drawing operations

					Case 65537 ; $CDDS_ITEMPREPAINT ; Before an item is drawn: Default painting (frames and background)
						Return 0x00000010 ; $CDRF_NOTIFYPOSTPAINT ; Notify parent window of coming post item related drawing operations

					Case 0x00010002 ; $CDDS_ITEMPOSTPAINT ; After an item is drawn: Custom painting
						Local $iColumnIndex = DllStructGetData($tNMCustomDraw, "dwItemSpec") ; Column
						$aHdrData = $aGLVEx_Data[$iLV_Index][25] ; Header data
						Local $aColSplit = StringSplit($aHdrData[1][$iColumnIndex], ";")
						; Set default colours
						Local $aHdrDefCols = $aGLVEx_Data[$iLV_Index][23]
						Local $iHdrTextColour, $iHdrBackColour
						; Set user or default colours
						If $aColSplit[1] == "" Then
							$iHdrTextColour = $aHdrDefCols[0]
						Else
							$iHdrTextColour = $aColSplit[1]
						EndIf
						If $aColSplit[2] == "" Then
							$iHdrBackColour = $aHdrDefCols[1]
						Else
							$iHdrBackColour = $aColSplit[2]
						EndIf
						; Set header section size
						Local $tRECT = DllStructCreate($tagRECT)
						DllStructSetData($tRECT, 1, DllStructGetData($tNMCustomDraw, 6) + 1)
						DllStructSetData($tRECT, 2, DllStructGetData($tNMCustomDraw, 7) + 1)
						DllStructSetData($tRECT, 3, DllStructGetData($tNMCustomDraw, 8) - 2)
						DllStructSetData($tRECT, 4, DllStructGetData($tNMCustomDraw, 9) - 2)
						; Set transparent background
						_WinAPI_SetBkMode($hDC, 1) ; $TRANSPARENT
						; Set text font and colour
						_WinAPI_SelectObject($hDC, $aGLVEx_Data[0][21])
						_WinAPI_SetTextColor($hDC, $iHdrTextColour)
						; Set and draw back colour
						Local $hBrush = _WinAPI_CreateSolidBrush($iHdrBackColour)
						_WinAPI_FillRect($hDC, $tRECT, $hBrush)
						; Write text
						If $iColumnIndex < _GUICtrlListView_GetColumnCount($aGLVEx_Data[$iLV_Index][0]) Then
							; Get column alignment
							Local $aRet = _GUICtrlListView_GetColumn($aGLVEx_Data[$iLV_Index][0], $iColumnIndex)
							Local $iColAlign = 2 * $aRet[0]
							_WinAPI_DrawText($hDC, $aHdrData[0][$iColumnIndex], $tRECT, $iColAlign)
						EndIf
						Return 2 ; $CDRF_NEWFONT must be returned after changing font or colors
				EndSwitch
			EndIf
		EndIf

	Else ; Not a drawing message

		; Flag to indicate use of Edit HotKey
		Local $fEditHotKey = False

		; Check if enabled ListView
		For $iLV_Index = 1 To $aGLVEx_Data[0][0]
			If $aGLVEx_Data[$iLV_Index][0] = DllStructGetData($tStruct, 1) Then
				ExitLoop
			EndIf
		Next

		Local $iRow

		; It is an enabled ListView
		If $iLV_Index <= $aGLVEx_Data[0][0] Then

			; Check if changed from current ListView
			If $iLV_Index <> $aGLVEx_Data[0][1] Then
				; Reset current index and row/column data
				$aGLVEx_Data[0][1] = $iLV_Index
				$aGLVEx_Data[0][17] = $aGLVEx_Data[$iLV_Index][20]
				$aGLVEx_Data[0][18] = $aGLVEx_Data[$iLV_Index][21]
			EndIf

			; Check message
			Switch $iCode

				Case $LVN_BEGINSCROLL

					; if editing then abandon
					If $cGLVEx_EditID <> 9999 Then
						; Delete temp edit control and set placeholder
						GUICtrlDelete($cGLVEx_EditID)
						$cGLVEx_EditID = 9999
						; Reactivate ListView
						WinSetState($hGLVEx_Editing, "", @SW_ENABLE)
					EndIf

				Case $LVN_BEGINDRAG

					; Check if any form of drag/drop permitted for this ListView
					If Not BitAND($aGLVEx_Data[$iLV_Index][12], 16) Then

						; Set values for this ListView
						$aGLVEx_Data[0][1] = $iLV_Index

						; Store source & target ListView data for eventual inter-LV drag
						$hGLVEx_SrcHandle = $aGLVEx_Data[$iLV_Index][0]
						$cGLVEx_SrcID = $aGLVEx_Data[$iLV_Index][1]
						$iGLVEx_SrcIndex = $iLV_Index
						$aGLVEx_SrcArray = $aGLVEx_Data[$iLV_Index][2]
						$hGLVEx_TgtHandle = $hGLVEx_SrcHandle
						$cGLVEx_TgtID = $cGLVEx_SrcID
						$iGLVEx_TgtIndex = $iGLVEx_SrcIndex
						$aGLVEx_TgtArray = $aGLVEx_SrcArray

						; Copy array for manipulation
						$aGLVEx_SrcArray = $aGLVEx_Data[$iLV_Index][2]

						; Set drag image flag
						Local $fImage = $aGLVEx_Data[$iLV_Index][5]

						; Check if Native or UDF and set focus
						If $cGLVEx_SrcID Then
							GUICtrlSetState($cGLVEx_SrcID, 256) ; $GUI_FOCUS
						Else
							_WinAPI_SetFocus($hGLVEx_SrcHandle)
						EndIf

						; Get dragged item index
						$iGLVEx_DraggedIndex = DllStructGetData($tStruct, 4) ; Item
						; Set dragged item count
						$iGLVEx_Dragging = 1

						; Check for selected items
						Local $iIndex
						; Check if colour or single cell selection enabled
						If $aGLVEx_Data[$iLV_Index][19] Or $aGLVEx_Data[$iLV_Index][22] Then
							; Use stored value
							$iIndex = $aGLVEx_Data[$iLV_Index][20]
						Else
							; Check actual values
							$iIndex = _GUICtrlListView_GetSelectedIndices($hGLVEx_SrcHandle)
						EndIf
						; Check if item is part of a multiple selection
						If StringInStr($iIndex, $iGLVEx_DraggedIndex) And StringInStr($iIndex, "|") Then
							; Extract all selected items
							Local $aIndex = StringSplit($iIndex, "|")
							For $i = 1 To $aIndex[0]
								If $aIndex[$i] = $iGLVEx_DraggedIndex Then ExitLoop
							Next
							; Now check for consecutive items
							If $i <> 1 Then ; Up
								For $j = $i - 1 To 1 Step -1
									; Consecutive?
									If $aIndex[$j] <> $aIndex[$j + 1] - 1 Then ExitLoop
									; Adjust dragged index to this item
									$iGLVEx_DraggedIndex -= 1
									; Increase number to drag
									$iGLVEx_Dragging += 1
								Next
							EndIf
							If $i <> $aIndex[0] Then ; Down
								For $j = $i + 1 To $aIndex[0]
									; Consecutive
									If $aIndex[$j] <> $aIndex[$j - 1] + 1 Then ExitLoop
									; Increase number to drag
									$iGLVEx_Dragging += 1
								Next
							EndIf
						Else ; Either no selection or only a single
							; Set flag
							$iGLVEx_Dragging = 1
						EndIf

						; Remove all highlighting
						_GUICtrlListView_SetItemSelected($hGLVEx_SrcHandle, -1, False)

						; Create drag image
						If $fImage Then
							Local $aImageData = _GUICtrlListView_CreateDragImage($hGLVEx_SrcHandle, $iGLVEx_DraggedIndex)
							$hGLVEx_DraggedImage = $aImageData[0]
							_GUIImageList_BeginDrag($hGLVEx_DraggedImage, 0, 0, 0)
						EndIf

					EndIf

				Case $LVN_COLUMNCLICK, -2 ; $NM_CLICK

					; Set values for active ListView
					$aGLVEx_Data[0][1] = $iLV_Index
					$hGLVEx_SrcHandle = $aGLVEx_Data[$iLV_Index][0]
					$cGLVEx_SrcID = $aGLVEx_Data[$iLV_Index][1]
					; Get and store row index
					$iRow = DllStructGetData($tStruct, 4)
					$aGLVEx_Data[0][4] = $iRow
					$aGLVEx_Data[0][17] = $iRow
					$aGLVEx_Data[$iLV_Index][20] = $iRow
					; Get and store column index
					$iCol = DllStructGetData($tStruct, 5)
					; Tooltip use
					$aGLVEx_Data[0][2] = $iCol
					; Normal use
					$aGLVEx_Data[0][5] = $iCol
					$aGLVEx_Data[0][18] = $iCol
					$aGLVEx_Data[$iLV_Index][21] = $iCol
					; If a column was clicked
					If $iCode = $LVN_COLUMNCLICK Then
						; Load editable column array
						Local $aEditable = $aGLVEx_Data[$iLV_Index][7]

						; Scroll column into view
						; Get X coord of first item in column
						Local $aRect = _GUICtrlListView_GetSubItemRect($hGLVEx_SrcHandle, 0, $iCol)
						; Get col width
						Local $aLV_Pos = WinGetPos($hGLVEx_SrcHandle)
						; Scroll to left edge if all column not in view
						If $aRect[0] < 0 Or $aRect[2] > $aLV_Pos[2] - $aGLVEx_Data[0][8] Then ; Reduce by scrollbar width
							_GUICtrlListView_Scroll($hGLVEx_SrcHandle, $aRect[0], 0)
						EndIf

						; Look for Ctrl key pressed
						_WinAPI_GetAsyncKeyState(0x11)
						If _WinAPI_GetAsyncKeyState(0x11) Then
							; Check column is editable
							If $aEditable[0][$iCol] Then
								; Set header edit flag
								$fGLVEx_HeaderEdit = True
							EndIf
						Else
							; If ListView sortable
							If IsArray($aGLVEx_Data[$iLV_Index][4]) Then
								; Load array
								$aGLVEx_SrcArray = $aGLVEx_Data[$iLV_Index][2]
								; Load current ListView sort state array
								Local $aLVSortState = $aGLVEx_Data[$iLV_Index][4]
								; Sort the ListView - passing a possible user sort function
								__GUIListViewEx_ColSort($hGLVEx_SrcHandle, $iLV_Index, $aLVSortState, $iCol, $aEditable[3][$iCol])
								; Store new ListView sort state array
								$aGLVEx_Data[$iLV_Index][4] = $aLVSortState
								; Reread listview items into array
								Local $iDim2 = UBound($aGLVEx_SrcArray, 2) - 1
								For $j = 1 To $aGLVEx_SrcArray[0][0]
									For $k = 0 To $iDim2
										$aGLVEx_SrcArray[$j][$k] = _GUICtrlListView_GetItemText($hGLVEx_SrcHandle, $j - 1, $k)
									Next
								Next
								; Store amended array
								$aGLVEx_Data[$iLV_Index][2] = $aGLVEx_SrcArray
								; Delete array
								$aGLVEx_SrcArray = 0
							EndIf
						EndIf
					Else
						; It was a mouseclick so set user selection flag
						$fGLVEx_UserSelFlag = 1
					EndIf

				Case $LVN_KEYDOWN

					; Determine which key pressed
					Local $tKey = DllStructCreate($tagNMHDR & ";WORD KeyCode", $lParam)
					; Store key value
					$aGLVEx_Data[0][16] = DllStructGetData($tKey, "KeyCode")
					; Check if manual edit key(s) pressed
					If __GUIListViewEx_CheckUserEditKey() Then
						; Set flag to show HotKey pressed and so struct does not give valid row/column
						$fEditHotKey = True
						ContinueCase
					EndIf

					; If single cell selection
					If $aGLVEx_Data[$iLV_Index][22] Then
						; Remove selected state
						_GUICtrlListView_SetItemSelected($hLV, $aGLVEx_Data[0][17], False)
						; Act on left/right keys
						Switch $aGLVEx_Data[0][16]
							Case 37 ; Left
								; Adjust column and prevent overrun
								If $aGLVEx_Data[0][18] > 0 Then $aGLVEx_Data[0][18] -= 1
								; Store new column
								$aGLVEx_Data[$iLV_Index][21] = $aGLVEx_Data[0][18]
								; Redraw row
								_GUICtrlListView_RedrawItems($hLV, $aGLVEx_Data[0][17], $aGLVEx_Data[0][17])
								; Set user selection and change flags
								$fGLVEx_UserSelFlag = 1
								$fGLVEx_SelChangeFlag = $iLV_Index

							Case 39 ; Right
								If $aGLVEx_Data[0][18] < _GUICtrlListView_GetColumnCount($hLV) - 1 Then $aGLVEx_Data[0][18] += 1
								$aGLVEx_Data[$iLV_Index][21] = $aGLVEx_Data[0][18]
								_GUICtrlListView_RedrawItems($hLV, $aGLVEx_Data[0][17], $aGLVEx_Data[0][17])
								; Set user selection and change flags
								$fGLVEx_UserSelFlag = 1
								$fGLVEx_SelChangeFlag = $iLV_Index

						EndSwitch
					EndIf

				Case -3 ; $NM_DBLCLK

					; Set values for active ListView
					$aGLVEx_Data[0][1] = $iLV_Index
					$hGLVEx_SrcHandle = $aGLVEx_Data[$iLV_Index][0]
					; Set active cell if valid struct - keypress does not set row/column fields
					If Not $fEditHotKey Then
						; Store doubleclicked item row and column
						$iRow = DllStructGetData($tStruct, 4)
						$aGLVEx_Data[0][17] = $iRow
						$aGLVEx_Data[$iLV_Index][20] = $iRow
						$iCol = DllStructGetData($tStruct, 5)
						$aGLVEx_Data[0][18] = $iCol
						$aGLVEx_Data[$iLV_Index][21] = $iCol
					EndIf
					; Copy array for manipulation
					$aGLVEx_SrcArray = $aGLVEx_Data[$iLV_Index][2]
					; Set editing flag
					$fGLVEx_EditClickFlag = $iLV_Index

				Case $LVN_ITEMCHANGED

					; Remove selection state if colour or single cell selection
					If $aGLVEx_Data[$iLV_Index][19] Or $aGLVEx_Data[$iLV_Index][22] Then
						_GUICtrlListView_SetItemSelected($hLV, $iItem, False)
					EndIf
					; If a key was used to change selection need to reset active row
					If $aGLVEx_Data[0][16] <> 0 Then
						; Check key used
						Switch $aGLVEx_Data[0][16]
							Case 38 ; Up
								If $aGLVEx_Data[0][17] > 0 Then $aGLVEx_Data[0][17] -= 1
								$aGLVEx_Data[$iLV_Index][20] = $aGLVEx_Data[0][17]
								; Set user selection flag
								$fGLVEx_UserSelFlag = 1

							Case 40 ; Down
								If $aGLVEx_Data[0][17] < _GUICtrlListView_GetItemCount($hLV) - 1 Then $aGLVEx_Data[0][17] += 1
								$aGLVEx_Data[$iLV_Index][20] = $aGLVEx_Data[0][17]
								; Set user selection flag
								$fGLVEx_UserSelFlag = 1

						EndSwitch
						; Clear key flag
						$aGLVEx_Data[0][16] = 0
					Else
						; If mouse button pressed
						_WinAPI_GetAsyncKeyState(0x01)
						If _WinAPI_GetAsyncKeyState(0x01) Then
							; Determine position of mouse within ListView
							Local $aMPos = MouseGetPos()
							Local $tPoint = DllStructCreate("int X;int Y")
							DllStructSetData($tPoint, "X", $aMPos[0])
							DllStructSetData($tPoint, "Y", $aMPos[1])
							_WinAPI_ScreenToClient($hLV, $tPoint)
							Local $aCurPos[2] = [DllStructGetData($tPoint, "X"), DllStructGetData($tPoint, "Y")]
							; Check for cell under mouse
							Local $aHitTest = _GUICtrlListView_SubItemHitTest($hLV, $aCurPos[0], $aCurPos[1])
							; If click on valid cell
							If $aHitTest[0] > -1 And $aHitTest[1] > -1 And $aHitTest[0] = $iItem Then
								; Redraw previously selected row
								If $aGLVEx_Data[0][17] <> $iItem Then _GUICtrlListView_RedrawItems($hLV, $aGLVEx_Data[0][17], $aGLVEx_Data[0][17])
								; Set new row and column
								$aGLVEx_Data[0][17] = $aHitTest[0]
								$aGLVEx_Data[0][18] = $aHitTest[1]
								$aGLVEx_Data[$iLV_Index][20] = $aGLVEx_Data[0][17]
								$aGLVEx_Data[$iLV_Index][21] = $aGLVEx_Data[0][18]
								; Redraw newly selected row
								_GUICtrlListView_RedrawItems($hLV, $iItem, $iItem)
							EndIf

							; Set user selection flag
							$fGLVEx_UserSelFlag = 1

						EndIf
					EndIf

					; Set selection change flag
					$fGLVEx_SelChangeFlag = $iLV_Index

				Case -5 ; $NM_RCLICK

					; Set active ListView
					$aGLVEx_Data[0][1] = $iLV_Index
					; Get position of right click within Listview
					$aGLVEx_Data[0][10] = DllStructGetData($tStruct, 4)
					$aGLVEx_Data[0][11] = DllStructGetData($tStruct, 5)
					; Redraw last selected row
					_GUICtrlListView_RedrawItems($hLV, $aGLVEx_Data[0][17], $aGLVEx_Data[0][17])
					; Set new active cell
					$aGLVEx_Data[0][17] = DllStructGetData($tStruct, 4)
					$aGLVEx_Data[0][18] = DllStructGetData($tStruct, 5)
					$aGLVEx_Data[$iLV_Index][20] = $aGLVEx_Data[0][17]
					$aGLVEx_Data[$iLV_Index][21] = $aGLVEx_Data[0][18]
					; Redraw newly selected row
					_GUICtrlListView_RedrawItems($hLV, $aGLVEx_Data[0][17], $aGLVEx_Data[0][17])

			EndSwitch
		Else

			; Check if header of enabled ListView
			For $iLV_Index = 1 To $aGLVEx_Data[0][0]
				If DllStructGetData($tStruct, 1) = _GUICtrlListView_GetHeader($aGLVEx_Data[$iLV_Index][0]) Then
					ExitLoop
				EndIf
			Next

			If $iLV_Index <= $aGLVEx_Data[0][0] Then
				; Create header data struct
				Local $tNMHEADER = DllStructCreate($tagNMHEADER, $lParam)
				$iCol = DllStructGetData($tNMHEADER, "Item")

				Switch $iCol
					Case 0 To _GUICtrlListView_GetColumnCount($aGLVEx_Data[$iLV_Index][0]) - 1

						; Load header data
						$aHdrData = $aGLVEx_Data[$iLV_Index][25]

						; Check if valid data
						If IsArray($aHdrData) And UBound($aHdrData, 2) Then
							; Check header resizing status
							Local $iHdrResize = $aHdrData[3][$iCol]
							Switch $iCode
								Case -306, -326 ; $HDN_BEGINTRACK(W)
									If $iHdrResize Then
										; Prevent resizing
										Return True
									Else
										; Allow resizing
										Return False
									EndIf
								Case -305, -325 ; $HDN_DIVIDERDBLCLICK(W)
									If $iHdrResize Then
										; Instant resize of column to fixed width
										_GUICtrlListView_SetColumnWidth($aGLVEx_Data[$iLV_Index][0], $iCol, $iHdrResize)
										; Redraw header
										_WinAPI_RedrawWindow(DllStructGetData($tStruct, 1))
									EndIf
								Case -307, -327 ; $HDN_ENDTRACK(W)
									$fGVLEx_Resized = $iCol
							EndSwitch
						EndIf
				EndSwitch
			EndIf
		EndIf
	EndIf

	Return "GUI_RUNDEFMSG"

EndFunc   ;==>_GUIListViewEx_WM_NOTIFY_Handler

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_WM_MOUSEMOVE_Handler
; Description ...: Windows message handler for WM_MOUSEMOVE
; Syntax.........: _GUIListViewEx_WM_MOUSEMOVE_Handler()
; Requirement(s).: v3.3.10 +
; Return values .: None
; Author ........: Melba23
; Modified ......:
; Remarks .......: If a WM_MOUSEMOVE handler already registered, then call this function from within that handler
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_WM_MOUSEMOVE_Handler($hWnd, $iMsg, $wParam, $lParam)

	#forceref $hWnd, $iMsg, $wParam

	Local $iVertScroll

	If $iGLVEx_Dragging = 0 Then
		Return "GUI_RUNDEFMSG"
	EndIf

	; Get item depth to make sure scroll is enough to get next item into view
	If $aGLVEx_Data[$aGLVEx_Data[0][1]][10] Then
		$iVertScroll = $aGLVEx_Data[$aGLVEx_Data[0][1]][10]
	Else
		Local $aRect = _GUICtrlListView_GetItemRect($hGLVEx_SrcHandle, 0)
		$iVertScroll = $aRect[3] - $aRect[1]
	EndIf

	; Get window under mouse cursor
	Local $hCurrent_Wnd = __GUIListViewEx_GetCursorWnd()

	; If not over the current tgt ListView
	If $hCurrent_Wnd <> $hGLVEx_TgtHandle Then

		; Check if external drag permitted
		If BitAND($aGLVEx_Data[$iGLVEx_TgtIndex][12], 1) Then
			Return "GUI_RUNDEFMSG"
		EndIf

		; Is it another initiated ListView
		For $i = 1 To $aGLVEx_Data[0][0]
			If $aGLVEx_Data[$i][0] = $hCurrent_Wnd Then

				; Check same column count for Src and Tgt ListViews
				If _GUICtrlListView_GetColumnCount($hGLVEx_SrcHandle) = _GUICtrlListView_GetColumnCount($hCurrent_Wnd) Then
					; Compatible so switch to new target
					; Clear insert mark in current tgt ListView
					_GUICtrlListView_SetInsertMark($hGLVEx_TgtHandle, -1, True)
					; Set data for new tgt ListView
					$hGLVEx_TgtHandle = $hCurrent_Wnd
					$cGLVEx_TgtID = $aGLVEx_Data[$i][1]
					$iGLVEx_TgtIndex = $i
					$aGLVEx_TgtArray = $aGLVEx_Data[$i][2]
					$aGLVEx_Data[0][3] = $aGLVEx_Data[$i][10] ; Set item depth
					; No point in looping further
					ExitLoop
				EndIf
			EndIf
		Next
	EndIf

	; Get current mouse Y coord
	Local $iCurr_Y = BitShift($lParam, 16)

	; Set insert mark to correct side of items depending on sense of movement when cursor within range
	If $iGLVEx_InsertIndex <> -1 Then
		If $iGLVEx_LastY = $iCurr_Y Then
			Return "GUI_RUNDEFMSG"
		ElseIf $iGLVEx_LastY > $iCurr_Y Then
			$fGLVEx_BarUnder = False
			_GUICtrlListView_SetInsertMark($hGLVEx_TgtHandle, $iGLVEx_InsertIndex, False)
		Else
			$fGLVEx_BarUnder = True
			_GUICtrlListView_SetInsertMark($hGLVEx_TgtHandle, $iGLVEx_InsertIndex, True)
		EndIf
	EndIf

	; Store current Y coord
	$iGLVEx_LastY = $iCurr_Y

	; Get ListView item under mouse
	Local $aLVHit = _GUICtrlListView_HitTest($hGLVEx_TgtHandle)
	Local $iCurr_Index = $aLVHit[0]

	; If mouse is above or below ListView then scroll ListView
	If $iCurr_Index = -1 Then
		If $fGLVEx_BarUnder Then
			_GUICtrlListView_Scroll($hGLVEx_TgtHandle, 0, $iVertScroll)
		Else
			_GUICtrlListView_Scroll($hGLVEx_TgtHandle, 0, -$iVertScroll)
		EndIf
		Sleep(10)
	EndIf

	; Check if over same item
	If $iGLVEx_InsertIndex <> $iCurr_Index Then
		; Show insert mark on current item
		_GUICtrlListView_SetInsertMark($hGLVEx_TgtHandle, $iCurr_Index, $fGLVEx_BarUnder)
		; Store current item
		$iGLVEx_InsertIndex = $iCurr_Index
	EndIf

	Return "GUI_RUNDEFMSG"

EndFunc   ;==>_GUIListViewEx_WM_MOUSEMOVE_Handler

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_WM_LBUTTONUP_Handler
; Description ...: Windows message handler for WM_LBUTTONUP
; Syntax.........: _GUIListViewEx_WM_LBUTTONUP_Handler()
; Requirement(s).: v3.3.10 +
; Return values .: None
; Author ........: Melba23
; Modified ......:
; Remarks .......: If a WM_LBUTTONUP handler already registered, then call this function from within that handler
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_WM_LBUTTONUP_Handler($hWnd, $iMsg, $wParam, $lParam)

	#forceref $hWnd, $iMsg, $wParam, $lParam

	If Not $iGLVEx_Dragging Then
		Return "GUI_RUNDEFMSG"
	EndIf

	; Get item count
	Local $iMultipleItems = $iGLVEx_Dragging - 1

	; Reset flag
	$iGLVEx_Dragging = 0

	; Check for valid insert index (set to -1 if dropping into empty space)
	If $iGLVEx_InsertIndex = -1 Then
		; Set to bottom
		$iGLVEx_InsertIndex = _GUICtrlListView_GetItemCount($hGLVEx_TgtHandle) - 1
	EndIf

	; Get window under mouse cursor
	Local $hCurrent_Wnd = __GUIListViewEx_GetCursorWnd()

	; Abandon if mouse not within tgt ListView
	If $hCurrent_Wnd <> $hGLVEx_TgtHandle Then
		; Clear insert mark
		_GUICtrlListView_SetInsertMark($hGLVEx_TgtHandle, -1, True)
		; Reset highlight to original items in Src ListView
		For $i = 0 To $iMultipleItems
			__GUIListViewEx_HighLight($hGLVEx_TgtHandle, $cGLVEx_TgtID, $iGLVEx_DraggedIndex + $i)
		Next
		; Delete copied arrays
		$aGLVEx_SrcArray = 0
		$aGLVEx_TgtArray = 0
		Return
	EndIf

	; Clear insert mark
	_GUICtrlListView_SetInsertMark($hGLVEx_TgtHandle, -1, True)

	; Clear drag image
	If $hGLVEx_DraggedImage Then
		_GUIImageList_DragLeave($hGLVEx_SrcHandle)
		_GUIImageList_EndDrag()
		_GUIImageList_Destroy($hGLVEx_DraggedImage)
		$hGLVEx_DraggedImage = 0
	EndIf

	; Dropping within same ListView
	If $hGLVEx_SrcHandle = $hGLVEx_TgtHandle Then

		; Check internal drag/drop allowed
		If BitAND($aGLVEx_Data[$iGLVEx_SrcIndex][12], 8) Then
			Return "GUI_RUNDEFMSG"
		EndIf

		; Determine position to insert
		If $fGLVEx_BarUnder Then
			If $iGLVEx_DraggedIndex > $iGLVEx_InsertIndex Then $iGLVEx_InsertIndex += 1
		Else
			If $iGLVEx_DraggedIndex < $iGLVEx_InsertIndex Then $iGLVEx_InsertIndex -= 1
		EndIf

		; Check not dropping on dragged item(s)
		Switch $iGLVEx_InsertIndex
			Case $iGLVEx_DraggedIndex To $iGLVEx_DraggedIndex + $iMultipleItems
				; Reset highlight to original items
				For $i = 0 To $iMultipleItems
					__GUIListViewEx_HighLight($hGLVEx_SrcHandle, $cGLVEx_SrcID, $iGLVEx_DraggedIndex + $i)
				Next
				; Delete copied arrays
				$aGLVEx_SrcArray = 0
				$aGLVEx_TgtArray = 0
				Return
		EndSwitch

		; Create Local array for checkboxes (if no checkboxes makes no difference)
		Local $aCheck_Array[UBound($aGLVEx_SrcArray)]
		For $i = 1 To UBound($aCheck_Array) - 1
			$aCheck_Array[$i] = _GUICtrlListView_GetItemChecked($hGLVEx_SrcHandle, $i - 1)
		Next

		; Create Local array for dragged items checkbox state
		Local $aCheckDrag_Array[$iMultipleItems + 1]

		; Create Local colour array
		$aGLVEx_SrcColArray = $aGLVEx_Data[$iGLVEx_SrcIndex][18]
		Local $bUserCol = ((IsArray($aGLVEx_SrcColArray)) ? (True) : (False))

		; Amend arrays
		; Get data from dragged element(s)
		If $iMultipleItems Then
			; Multiple dragged elements
			Local $aInsertData[$iMultipleItems + 1]
			Local $aColData[$iMultipleItems + 1]
			Local $aItemData[UBound($aGLVEx_SrcArray, 2)]
			For $i = 0 To $iMultipleItems
				; Data
				For $j = 0 To UBound($aGLVEx_SrcArray, 2) - 1
					$aItemData[$j] = $aGLVEx_SrcArray[$iGLVEx_DraggedIndex + 1 + $i][$j]
				Next
				$aInsertData[$i] = $aItemData
				; Colours if required
				If $bUserCol Then
					For $j = 0 To UBound($aGLVEx_SrcColArray, 2) - 1
						$aItemData[$j] = $aGLVEx_SrcColArray[$iGLVEx_DraggedIndex + 1 + $i][$j]
					Next
					$aColData[$i] = $aItemData
				EndIf
				; Checkboxes
				$aCheckDrag_Array[$i] = _GUICtrlListView_GetItemChecked($hGLVEx_SrcHandle, $iGLVEx_DraggedIndex + $i)
			Next
		Else
			; Single dragged element
			Local $aInsertData[1]
			Local $aColData[1]
			Local $aItemData[UBound($aGLVEx_SrcArray, 2)]
			For $i = 0 To UBound($aGLVEx_SrcArray, 2) - 1
				$aItemData[$i] = $aGLVEx_SrcArray[$iGLVEx_DraggedIndex + 1][$i]
			Next
			$aInsertData[0] = $aItemData
			If $bUserCol Then
				For $i = 0 To UBound($aGLVEx_SrcColArray, 2) - 1
					$aItemData[$i] = $aGLVEx_SrcColArray[$iGLVEx_DraggedIndex + 1][$i]
				Next
				$aColData[0] = $aItemData
			EndIf
			$aCheckDrag_Array[0] = _GUICtrlListView_GetItemChecked($hGLVEx_SrcHandle, $iGLVEx_DraggedIndex)
		EndIf

		; Set no redraw flag - prevents problems while colour arrays are updated
		$aGLVEx_Data[0][12] = True

		; Delete dragged element(s) from arrays
		For $i = 0 To $iMultipleItems
			__GUIListViewEx_Array_Delete($aGLVEx_SrcArray, $iGLVEx_DraggedIndex + 1)
			__GUIListViewEx_Array_Delete($aCheck_Array, $iGLVEx_DraggedIndex + 1)
			If $bUserCol Then __GUIListViewEx_Array_Delete($aGLVEx_SrcColArray, $iGLVEx_DraggedIndex + 1)
		Next

		; Amend insert positon for multiple items deleted above
		If $iGLVEx_DraggedIndex < $iGLVEx_InsertIndex Then
			$iGLVEx_InsertIndex -= $iMultipleItems
		EndIf

		; Re-insert dragged element(s) into array
		For $i = $iMultipleItems To 0 Step -1
			__GUIListViewEx_Array_Insert($aGLVEx_SrcArray, $iGLVEx_InsertIndex + 1, $aInsertData[$i])
			__GUIListViewEx_Array_Insert($aCheck_Array, $iGLVEx_InsertIndex + 1, $aCheckDrag_Array[$i])
			If $bUserCol Then __GUIListViewEx_Array_Insert($aGLVEx_SrcColArray, $iGLVEx_InsertIndex + 1, $aColData[$i], False, False)
		Next

		; Rewrite ListView to match array
		__GUIListViewEx_ReWriteLV($hGLVEx_SrcHandle, $aGLVEx_SrcArray, $aCheck_Array, $iGLVEx_SrcIndex)

		; Set highlight to inserted item(s)
		For $i = 0 To $iMultipleItems
			__GUIListViewEx_HighLight($hGLVEx_SrcHandle, $cGLVEx_SrcID, $iGLVEx_InsertIndex + $i)
		Next

		; Store amended array
		$aGLVEx_Data[$aGLVEx_Data[0][1]][2] = $aGLVEx_SrcArray
		$aGLVEx_Data[$iGLVEx_SrcIndex][18] = $aGLVEx_SrcColArray

	Else ; Dropping in another ListView

		; Check external drop allowed
		If BitAND($aGLVEx_Data[$iGLVEx_TgtIndex][12], 2) Then
			Return "GUI_RUNDEFMSG"
		EndIf

		; Check checkbox status
		Local $bCheckbox = (($aGLVEx_Data[$iGLVEx_SrcIndex][6] And $aGLVEx_Data[$iGLVEx_TgtIndex][6]) ? (True) : (False))

		; Determine position to insert
		If $fGLVEx_BarUnder Then
			$iGLVEx_InsertIndex += 1
		EndIf

		; Colour arrays for manipulation
		$aGLVEx_SrcColArray = $aGLVEx_Data[$iGLVEx_SrcIndex][18]
		Local $bUserColSrc = ((IsArray($aGLVEx_SrcColArray)) ? (True) : (False))
		$aGLVEx_TgtColArray = $aGLVEx_Data[$iGLVEx_TgtIndex][18]
		Local $bUserColTgt = ((IsArray($aGLVEx_TgtColArray)) ? (True) : (False))

		; Create Local arrays for checkboxes (if no checkboxes makes no difference)
		Local $aCheck_SrcArray[UBound($aGLVEx_SrcArray)]
		For $i = 1 To UBound($aCheck_SrcArray) - 1
			$aCheck_SrcArray[$i] = _GUICtrlListView_GetItemChecked($hGLVEx_SrcHandle, $i - 1)
		Next
		Local $aCheck_TgtArray[UBound($aGLVEx_TgtArray)]
		For $i = 1 To UBound($aCheck_TgtArray) - 1
			$aCheck_TgtArray[$i] = _GUICtrlListView_GetItemChecked($hGLVEx_TgtHandle, $i - 1)
		Next

		; Create Local array for dragged items checkbox state
		Local $aCheckDrag_Array[$iMultipleItems + 1]

		; Amend arrays
		; Get data from dragged element(s)
		If $iMultipleItems Then
			; Multiple dragged elements
			Local $aInsertData[$iMultipleItems + 1]
			Local $aColData[$iMultipleItems + 1]
			Local $aItemData[UBound($aGLVEx_SrcArray, 2)]
			For $i = 0 To $iMultipleItems
				; Data
				For $j = 0 To UBound($aGLVEx_SrcArray, 2) - 1
					$aItemData[$j] = $aGLVEx_SrcArray[$iGLVEx_DraggedIndex + 1 + $i][$j]
				Next
				$aInsertData[$i] = $aItemData
				; Colours if required
				If $bUserColTgt Then
					For $j = 0 To UBound($aGLVEx_SrcArray, 2) - 1
						If $bUserColSrc Then
							$aItemData[$j] = $aGLVEx_SrcColArray[$iGLVEx_DraggedIndex + 1 + $i][$j]
						Else
							$aItemData[$j] = ";"
						EndIf
					Next
					$aColData[$i] = $aItemData
				EndIf
				; Checkboxes
				$aCheckDrag_Array[$i] = _GUICtrlListView_GetItemChecked($hGLVEx_SrcHandle, $iGLVEx_DraggedIndex + $i)
			Next
		Else
			; Single dragged element
			Local $aInsertData[1]
			Local $aColData[1]
			Local $aItemData[UBound($aGLVEx_SrcArray, 2)]
			For $i = 0 To UBound($aGLVEx_SrcArray, 2) - 1
				$aItemData[$i] = $aGLVEx_SrcArray[$iGLVEx_DraggedIndex + 1][$i]
			Next
			$aInsertData[0] = $aItemData
			If $bUserColTgt Then
				For $i = 0 To UBound($aGLVEx_SrcArray, 2) - 1
					If $bUserColSrc Then
						$aItemData[$i] = $aGLVEx_SrcColArray[$iGLVEx_DraggedIndex + 1][$i]
					Else
						$aItemData[$i] = ";"
					EndIf
				Next
				$aColData[0] = $aItemData
			EndIf
			$aCheckDrag_Array[0] = _GUICtrlListView_GetItemChecked($hGLVEx_SrcHandle, $iGLVEx_DraggedIndex)
		EndIf

		; Set no redraw flag - prevents problems while colour arrays are updated
		$aGLVEx_Data[0][12] = True

		; Delete dragged element(s) from source array
		If Not BitAND($aGLVEx_Data[$iGLVEx_SrcIndex][12], 4) Then
			For $i = 0 To $iMultipleItems
				__GUIListViewEx_Array_Delete($aGLVEx_SrcArray, $iGLVEx_DraggedIndex + 1)
				__GUIListViewEx_Array_Delete($aCheck_SrcArray, $iGLVEx_DraggedIndex + 1, $aCheckDrag_Array[$i])
				If $bUserColSrc Then __GUIListViewEx_Array_Delete($aGLVEx_SrcColArray, $iGLVEx_DraggedIndex + 1)
			Next
		EndIf

		; Check if insert index is valid
		If $iGLVEx_InsertIndex < 0 Then
			$iGLVEx_InsertIndex = _GUICtrlListView_GetItemCount($hGLVEx_TgtHandle)
		EndIf

		; Insert dragged element(s) into target array
		For $i = $iMultipleItems To 0 Step -1
			__GUIListViewEx_Array_Insert($aGLVEx_TgtArray, $iGLVEx_InsertIndex + 1, $aInsertData[$i])
			__GUIListViewEx_Array_Insert($aCheck_TgtArray, $iGLVEx_InsertIndex + 1, $aCheckDrag_Array[$i])
			If $bUserColTgt Then __GUIListViewEx_Array_Insert($aGLVEx_TgtColArray, $iGLVEx_InsertIndex + 1, $aColData[$i], False, False)
		Next

		; Rewrite ListViews to match arrays
		__GUIListViewEx_ReWriteLV($hGLVEx_SrcHandle, $aGLVEx_SrcArray, $aCheck_SrcArray, $iGLVEx_SrcIndex, $bCheckbox)
		__GUIListViewEx_ReWriteLV($hGLVEx_TgtHandle, $aGLVEx_TgtArray, $aCheck_TgtArray, $iGLVEx_TgtIndex, $bCheckbox)

		; Set highlight to inserted item(s)
		_GUIListViewEx_SetActive($iGLVEx_TgtIndex)
		For $i = 0 To $iMultipleItems
			__GUIListViewEx_HighLight($hGLVEx_TgtHandle, $cGLVEx_TgtID, $iGLVEx_InsertIndex + $i)
		Next

		; Store amended arrays
		$aGLVEx_Data[$iGLVEx_SrcIndex][2] = $aGLVEx_SrcArray
		$aGLVEx_Data[$iGLVEx_SrcIndex][18] = $aGLVEx_SrcColArray
		$aGLVEx_Data[$iGLVEx_TgtIndex][2] = $aGLVEx_TgtArray
		$aGLVEx_Data[$iGLVEx_TgtIndex][18] = $aGLVEx_TgtColArray

	EndIf

	; Delete copied arrays
	$aGLVEx_SrcArray = 0
	$aGLVEx_TgtArray = 0
	$aGLVEx_SrcColArray = 0
	$aGLVEx_TgtColArray = 0

	; Set DragEvent details
	$sGLVEx_DragEvent = $iGLVEx_SrcIndex & ":" & $iGLVEx_TgtIndex
	; Set colour redraw flag
	$aGLVEx_Data[0][22] = 1

	; Clear no redraw flag
	$aGLVEx_Data[0][12] = False

	; If colour used or single cell selection
	__GUIListViewEx_RedrawWindow($iGLVEx_SrcIndex)
	If $hGLVEx_TgtHandle <> $hGLVEx_SrcHandle Then
		__GUIListViewEx_RedrawWindow($iGLVEx_TgtIndex)
	EndIf

EndFunc   ;==>_GUIListViewEx_WM_LBUTTONUP_Handler

; #FUNCTION# =========================================================================================================
; Name...........: _GUIListViewEx_WM_SYSCOMMAND_Handler
; Description ...: Windows message handler for WM_SYSCOMMAND
; Syntax.........: _GUIListViewEx_WM_SYSCOMMAND_Handler()
; Requirement(s).: v3.3.10 +
; Return values .: None
; Author ........: Melba23
; Modified ......:
; Remarks .......: If a WM_SYSCOMMAND handler already registered, then call this function from within that handler
; Example........: Yes
;=====================================================================================================================
Func _GUIListViewEx_WM_SYSCOMMAND_Handler($hWnd, $iMsg, $wParam, $lParam)

	#forceref $hWnd, $iMsg, $lParam, $lParam

	; Check correct event from ListView GUI
	If $hWnd = _WinAPI_GetParent($hGLVEx_SrcHandle) And $wParam = 0xF060 Then ; $SC_CLOSE
		$aGLVEx_Data[0][9] = True
	EndIf

EndFunc   ;==>_GUIListViewEx_WM_SYSCOMMAND_Handler

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __GUIListViewEx_ExpandRange
; Description ...: Expands ranges into an array of values - $iMode determines if columns or rows
; Author ........: Melba23
; Modified ......:
; ===============================================================================================================================
Func __GUIListViewEx_ExpandRange($vRange, $iLV_Index, $iMode = 1)

	; Check for valid range string
	If StringRegExp($vRange, "[^*0-9-;]") <> 0 Then
		Return SetError(1, 0, 0)
	EndIf

	; Get column/row count and create an array
	Local $iCount
	If $iMode = 1 Then
		$iCount = _GUICtrlListView_GetColumnCount($aGLVEx_Data[$iLV_Index][0])
	Else
		$iCount = _GUICtrlListView_GetItemCount($aGLVEx_Data[$iLV_Index][0])
	EndIf
	Local $aRet[$iCount + 1]

	; Strip any whitespace
	$vRange = StringStripWS($vRange, 8)
	; Check if "all"
	If $vRange = "*" Then
		$aRet[0] = $iCount
		For $i = 1 To $iCount
			$aRet[$i] = $i - 1
		Next
	Else
		; Check if there are ranges to be expanded
		If StringInStr($vRange, "-") Then
			; Parse string
			Local $aSplit_1, $aSplit_2, $iNumber
			; Split on ";"
			$aSplit_1 = StringSplit($vRange, ";")
			$vRange = ""
			; Check each element
			For $i = 1 To $aSplit_1[0]
				; Try and split on "-"
				$aSplit_2 = StringSplit($aSplit_1[$i], "-")
				; Add first value in all cases
				$vRange &= $aSplit_2[1] & ";"
				; If a valid range
				If ($aSplit_2[0]) > 1 Then
					; Check valid range
					If (Number($aSplit_2[2]) > Number($aSplit_2[1])) Then
						; Add the full range
						$iNumber = $aSplit_2[1]
						Do
							$iNumber += 1
							$vRange &= $iNumber & ";"
						Until $iNumber = $aSplit_2[2]
					Else
						Return SetError(1, 0, 0)
					EndIf
				EndIf
			Next
		EndIf
		; Split string into array
		Local $aSplit = StringSplit($vRange, ";")
		; Check for valid elements
		For $i = 1 To $aSplit[0]
			If $aSplit[$i] Then
				$aRet[0] += 1
				$aRet[$aRet[0]] = $aSplit[$i]
			EndIf
		Next
		; Remove empty elements
		ReDim $aRet[$aRet[0] + 1]
	EndIf
	; Return array of range values
	Return $aRet

EndFunc   ;==>__GUIListViewEx_ExpandRange

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __GUIListViewEx_HighLight
; Description ...: Highlights first item and ensures visible, second item has highlight removed
; Author ........: Melba23
; Remarks .......:
; ===============================================================================================================================
Func __GUIListViewEx_HighLight($hLVHandle, $cLV_CID, $iIndexA, $iIndexB = -1)

	; Check if Native or UDF and set focus
	If $cLV_CID Then
		GUICtrlSetState($cLV_CID, 256) ; $GUI_FOCUS
	Else
		_WinAPI_SetFocus($hLVHandle)
	EndIf
	; Cancel highlight on other item - needed for multisel listviews
	If $iIndexB <> -1 Then _GUICtrlListView_SetItemSelected($hLVHandle, $iIndexB, False)
	; Set highlight to inserted item and ensure in view
	_GUICtrlListView_SetItemState($hLVHandle, $iIndexA, $LVIS_SELECTED, $LVIS_SELECTED)
	_GUICtrlListView_EnsureVisible($hLVHandle, $iIndexA)

EndFunc   ;==>__GUIListViewEx_HighLight

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __GUIListViewEx_GetLVFont
; Description ...: Gets font details for ListView to be edited
; Author ........: Based on _GUICtrlGetFont by KaFu & Prog@ndy
; Modified ......: Melba23
; ===============================================================================================================================
Func __GUIListViewEx_GetLVFont($hLVHandle)

	Local $iError = 0, $aFontDetails[2] = [Default, Default]

	; Check handle
	If Not IsHWnd($hLVHandle) Then
		$hLVHandle = GUICtrlGetHandle($hLVHandle)
	EndIf
	If Not IsHWnd($hLVHandle) Then
		$iError = 1
	Else
		Local $hFont = _SendMessage($hLVHandle, 0x0031) ; WM_GETFONT
		If Not $hFont Then
			$iError = 2
		Else
			Local $hDC = _WinAPI_GetDC($hLVHandle)
			Local $hObjOrg = _WinAPI_SelectObject($hDC, $hFont)
			Local $tFONT = DllStructCreate($tagLOGFONT)
			Local $aRet = DllCall('gdi32.dll', 'int', 'GetObjectW', 'ptr', $hFont, 'int', DllStructGetSize($tFONT), 'ptr', DllStructGetPtr($tFONT))
			If @error Or $aRet[0] = 0 Then
				$iError = 3
			Else
				; Get font size
				$aFontDetails[0] = Round((-1 * DllStructGetData($tFONT, 'Height')) * 72 / _WinAPI_GetDeviceCaps($hDC, 90), 1) ; $LOGPIXELSY = 90 => DPI aware
				; Now look for font name
				$aRet = DllCall("gdi32.dll", "int", "GetTextFaceW", "handle", $hDC, "int", 0, "ptr", 0)
				Local $iCount = $aRet[0]
				Local $tBuffer = DllStructCreate("wchar[" & $iCount & "]")
				Local $pBuffer = DllStructGetPtr($tBuffer)
				$aRet = DllCall("Gdi32.dll", "int", "GetTextFaceW", "handle", $hDC, "int", $iCount, "ptr", $pBuffer)
				If @error Then
					$iError = 4
				Else
					$aFontDetails[1] = DllStructGetData($tBuffer, 1) ; FontFacename
				EndIf
			EndIf
			_WinAPI_SelectObject($hDC, $hObjOrg)
			_WinAPI_ReleaseDC($hLVHandle, $hDC)
		EndIf
	EndIf

	Return SetError($iError, 0, $aFontDetails)

EndFunc   ;==>__GUIListViewEx_GetLVFont

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __GUIListViewEx_EditProcess
; Description ...: Runs ListView editing process
; Author ........: Melba23
; Modified ......:
; ===============================================================================================================================
Func __GUIListViewEx_EditProcess($iLV_Index, $aLocation, $iDelta_X, $iDelta_Y, $iEditMode, $iForce = False)

	Local $hTemp_Combo = 9999, $hTemp_Edit = 9999, $hTemp_List = 9999, $iKey_Code, $fCombo_State, $aSplit, $sInsert
	Local $iEditType, $fEdit, $fCombo, $fRead_Only, $fAuto_Drop, $fDTP, $fClick_Move = False, $cUpDown, $hUpDown

	; Force ListView GUI to become current GUI for control creation and store previous GUI handle
	Local $hPrevCurrGUI = GUISwitch(_WinAPI_GetParent($hGLVEx_SrcHandle))

	; Unselect item
	_GUICtrlListView_SetItemSelected($hGLVEx_SrcHandle, $aLocation[0], False)

	; Declare return array
	Local $aEdited[1][4] = [[0]] ; [[Number of edited items, blank, blank, blank]]

	; Load active ListView details
	$hGLVEx_SrcHandle = $aGLVEx_Data[$iLV_Index][0]
	$cGLVEx_SrcID = $aGLVEx_Data[$iLV_Index][1]

	; Store handle of ListView concerned
	$hGLVEx_Editing = $hGLVEx_SrcHandle
	Local $cEditingID = $cGLVEx_SrcID

	; Valid keys to action ; TAB, ENTER, ESC, left/right/up/down arrows
	Local $aKeys[7] = [0x09, 0x0D, 0x1B, 0x25, 0x27, 0x26, 0x28]

	; Set Reset-on-ESC mode
	Local $fReset_Edits = False
	If $iEditMode < 0 Then
		$fReset_Edits = True
		$iEditMode = Abs($iEditMode)
	EndIf

	; Set row/col edit mode - default single edit
	Local $iEditRow = 0, $iEditCol = 0
	If $iEditMode Then
		; Separate axis settings - force leading 0 if required
		$aSplit = StringSplit(StringFormat("%02s", $iEditMode), "")
		$iEditRow = $aSplit[1]
		$iEditCol = $aSplit[2]
	EndIf

	; Extract editable array
	Local $aEditable = $aGLVEx_Data[$iLV_Index][7]

	; Check if edit to move on click
	If $aGLVEx_Data[$iLV_Index][9] Then
		$fClick_Move = True
	EndIf

	Local $tLVPos = DllStructCreate("struct;long X;long Y;endstruct")
	; Get position of ListView within GUI client area
	__GUIListViewEx_GetLVCoords($hGLVEx_Editing, $tLVPos)
	; Get ListView client area to allow for scrollbars
	Local $aLVClient = WinGetClientSize($hGLVEx_Editing)
	; Get ListView font details
	Local $aLV_FontDetails = __GUIListViewEx_GetLVFont($hGLVEx_Editing)
	; Disable ListView
	WinSetState($hGLVEx_Editing, "", @SW_DISABLE)

	; Load edit width data array
	Local $aWidth = ($aGLVEx_Data[$iLV_Index][14])
	; Create dummy array if required
	If Not IsArray($aWidth) Then Local $aWidth[_GUICtrlListView_GetColumnCount($aGLVEx_Data[$iLV_Index][0])]

	; Define variables
	Local $iWidth, $fExitLoop, $tMouseClick = DllStructCreate($tagPOINT)
	; Set default mousecoordmode
	Local $iOldMouseOpt = Opt("MouseCoordMode", 1)
	; Prevent GUI closure on ESC as needed to exit edit
	Local $iOldESC = Opt("GUICloseOnESC", 0)
	; Wait for mouse button release
	_WinAPI_GetAsyncKeyState(0x01)
	While _WinAPI_GetAsyncKeyState(0x01)
		Sleep(10)
	WEnd

	; Start the edit loop
	While 1

		; Clear all type flags
		$fEdit = False
		$fCombo = False
		$fRead_Only = False
		$fAuto_Drop = False
		$fDTP = False

		; Determine type of control required for this cell and extract data if required
		$iEditType = $aEditable[0][$aLocation[1]]
		Switch $iEditType
			Case 0, 1 ; Edit
				$fEdit = True
				If $iForce Then
					$iEditType = 1 ; Force text edit if called by _GUIListViewEx_EditItem
				EndIf

			Case 2 ; Combo
				$fCombo = True
				Local $sCombo_Data = $aEditable[1][$aLocation[1]]
				$fRead_Only = (BitAND($aEditable[2][$aLocation[1]], 1) = 1)
				$fAuto_Drop = (BitAND($aEditable[2][$aLocation[1]], 2) = 2)

			Case 3 ; DTP
				$fDTP = True
				Local $sDTP_Default = $aEditable[1][$aLocation[1]]
				If StringRight($sDTP_Default, 1) = "#" Then
					$sDTP_Default = StringTrimRight($sDTP_Default, 1)
					$fAuto_Drop = True
				EndIf
				If $sDTP_Default = Default Then
					$sDTP_Default = @YEAR & "/" & @MON & "/" & @MDAY
				EndIf
				Local $sDTP_Format = $aEditable[2][$aLocation[1]]
				If $sDTP_Format = Default Then
					$sDTP_Format = ""
				EndIf
		EndSwitch

		; Read current text of clicked item
		Local $sItemOrgText = _GUICtrlListView_GetItemText($hGLVEx_Editing, $aLocation[0], $aLocation[1])
		; Ensure item is visible and get required edit coords
		Local $aEdit_Pos = __GUIListViewEx_EditCoords($hGLVEx_Editing, $cEditingID, $aLocation, $tLVPos, $aLVClient[0] - 5, $iDelta_X, $iDelta_Y)
		; Get required edit width - force to number so non-digits are set to 0
		$iWidth = Number($aWidth[$aLocation[1]])
		; Alter edit/combo width if required value less than current width
		If $iWidth > $aEdit_Pos[2] Then
			If $fRead_Only Then ; Only adjust read-only combo edit width if value is negative
				If $iWidth < 0 Then
					$aEdit_Pos[2] = Abs($iWidth)
				EndIf
			Else ; Always adjust for if manual input accepted
				$aEdit_Pos[2] = Abs($iWidth)
			EndIf
		EndIf

		; Create control
		Switch $iEditType
			Case 1 ; Edit
				; Create temporary edit - get handle, set font size, give keyboard focus and select all text
				$cGLVEx_EditID = GUICtrlCreateInput($sItemOrgText, $aEdit_Pos[0], $aEdit_Pos[1], $aEdit_Pos[2], $aEdit_Pos[3], 128) ; $ES_AUTOHSCROLL

				; Set edit field colour if required
				If $aGLVEx_Data[$iLV_Index][19] Then
					GUICtrlSetBkColor($cGLVEx_EditID, $aGLVEx_Data[$iLV_Index][26])
				EndIf

				$hTemp_Edit = GUICtrlGetHandle($cGLVEx_EditID)
				; Check if UpDown required
				If $aEditable[1][$aLocation[1]] = 1 Then
					Local $iWrap = -1 ; Default no wrap
					; Check if limits to be applied
					If $aEditable[2][$aLocation[1]] Then
						$aSplit = StringSplit($aEditable[2][$aLocation[1]], "|")
						; Check valid syntax
						If UBound($aSplit) = 4 Then
							$iWrap = (($aSplit[3] = 1) ? (0x05) : (-1)) ; ($UDS_ALIGNRIGHT, $UDS_WRAP), (Default)
						EndIf
					EndIf
					; Create UpDowm
					$cUpDown = GUICtrlCreateUpdown($cGLVEx_EditID, $iWrap)
					$hUpDown = GUICtrlGetHandle($cUpDown)
					; Check for limits
					If UBound($aSplit) = 4 Then
						GUICtrlSetLimit($cUpDown, $aSplit[2], $aSplit[1])
					EndIf
					; Ensure visible
					_WinAPI_RedrawWindow($hUpDown)
				EndIf

			Case 2 ; Combo
				; Create temporary combo - get handle, set font size, give keyboard focus
				If $fRead_Only Then
					$cGLVEx_EditID = GUICtrlCreateCombo("", $aEdit_Pos[0], $aEdit_Pos[1], $aEdit_Pos[2], $aEdit_Pos[3], 0x00200043) ; $CBS_DROPDOWNLIST, $CBS_AUTOHSCROLL, $WS_VSCROLL
					; Set existing content as default for read-only
					GUICtrlSetData($cGLVEx_EditID, $sCombo_Data, $sItemOrgText)
				Else
					$cGLVEx_EditID = GUICtrlCreateCombo("", $aEdit_Pos[0], $aEdit_Pos[1], $aEdit_Pos[2], $aEdit_Pos[3], 0x00200042) ; $CBS_DROPDOWN, $CBS_AUTOHSCROLL, $WS_VSCROLL
					; Do NOT set existing content as default only for editable
					GUICtrlSetData($cGLVEx_EditID, $sCombo_Data)
				EndIf

				Local $tInfo = DllStructCreate("dword Size;struct;long EditLeft;long EditTop;long EditRight;long EditBottom;endstruct;" & _
						"struct;long BtnLeft;long BtnTop;long BtnRight;long BtnBottom;endstruct;dword BtnState;hwnd hCombo;hwnd hEdit;hwnd hList")
				Local $iInfo = DllStructGetSize($tInfo)
				DllStructSetData($tInfo, "Size", $iInfo)
				Local $hCombo = GUICtrlGetHandle($cGLVEx_EditID)
				; Set readonly combo dropped width if required
				If $fRead_Only And Abs($iWidth) > $aEdit_Pos[2] Then
					_SendMessage($hCombo, 0x160, Abs($iWidth)) ; $CB_SETDROPPEDWIDTH
				EndIf
				; Get combo data
				_SendMessage($hCombo, 0x164, 0, $tInfo, 0, "wparam", "struct*") ; $CB_GETCOMBOBOXINFO
				$hTemp_Edit = DllStructGetData($tInfo, "hEdit")
				$hTemp_List = DllStructGetData($tInfo, "hList")
				$hTemp_Combo = DllStructGetData($tInfo, "hCombo")

			Case 3 ; DTP
				; Create temp date picker
				$cGLVEx_EditID = GUICtrlCreateDate($sDTP_Default, $aEdit_Pos[0], $aEdit_Pos[1], $aEdit_Pos[2], $aEdit_Pos[3])
				$hTemp_Edit = GUICtrlGetHandle($cGLVEx_EditID)
				; Set format if required
				If $sDTP_Format Then
					GUICtrlSendMsg($cGLVEx_EditID, 0x1032, 0, $sDTP_Format) ; $DTM_SETFORMATW
				EndIf

		EndSwitch

		; Set font
		GUICtrlSetFont($cGLVEx_EditID, $aLV_FontDetails[0], Default, Default, $aLV_FontDetails[1])

		; Set focus to editing control
		_WinAPI_SetFocus($hTemp_Edit)
		; Check "select all" flag state
		If Not $aGLVEx_Data[$iLV_Index][11] Then
			GUICtrlSendMsg($cGLVEx_EditID, 0xB1, 0, -1) ; $EM_SETSEL
		EndIf
		; Check for auto "drop-down" combo
		If $fAuto_Drop Then
			Switch $iEditType
				Case 2
					_SendMessage($hCombo, 0x14F, True) ; $$CB_SHOWDROPDOWN
				Case 3
					_SendMessage($hTemp_Edit, 0x0201, 1, $aEdit_Pos[2] - 10) ; WM_LBUTTONDOWN
			EndSwitch
		EndIf

		; Copy array for manipulation
		$aGLVEx_SrcArray = $aGLVEx_Data[$iLV_Index][2]
		; Clear key code flag
		$iKey_Code = 0
		; Set combo down/up flag depending on initial state
		$fCombo_State = (($fAuto_Drop) ? (True) : (False))

		; Wait for a key press or combo down/up
		While 1

			; Clear flag
			$fExitLoop = False

			; Check for SYSCOMMAND Close Event
			If $aGLVEx_Data[0][9] Then
				$fExitLoop = True
				$aGLVEx_Data[0][9] = False
			EndIf

			; Mouse pressed
			_WinAPI_GetAsyncKeyState(0x01)
			If _WinAPI_GetAsyncKeyState(0x01) Then
				; Look for clicks outside edit/combo control
				DllStructSetData($tMouseClick, "x", MouseGetPos(0))
				DllStructSetData($tMouseClick, "y", MouseGetPos(1))
				Switch _WinAPI_WindowFromPoint($tMouseClick)
					Case $hTemp_Combo, $hTemp_Edit, $hTemp_List, $hUpDown
						; Over edit/combo
					Case Else
						; Ignore if using date control
						If Not $fDTP Then
							$fExitLoop = True
						EndIf
				EndSwitch
				; Wait for mouse button release
				_WinAPI_GetAsyncKeyState(0x01)
				While _WinAPI_GetAsyncKeyState(0x01)
					Sleep(10)
				WEnd
			EndIf

			; Exit loop
			If $fExitLoop Then
				; If standard edit control
				If $fEdit Then
					; Set appropriate behaviour
					If $fClick_Move Then
						$iKey_Code = 0x02 ; Confirm edit and move to next cell
					Else
						$iKey_Code = 0x01 ; Abandon editing process
					EndIf
				EndIf
				ExitLoop
			EndIf

			If $fCombo Then

				; Check for dropdown open and close
				Switch _SendMessage($hCombo, 0x157) ; $CB_GETDROPPEDSTATE

					Case 0
						; If opened and closed
						If $fCombo_State = True Then
							; If no content
							If GUICtrlRead($cGLVEx_EditID) = "" Then
								; Ignore
								$fCombo_State = False
							Else
								; Act as if Enter pressed
								$iKey_Code = 0x0D
								ExitLoop
							EndIf
						EndIf

					Case 1
						; Set flag if opened
						If Not $fCombo_State Then
							$fCombo_State = True
						EndIf

				EndSwitch
			EndIf

			; Check for valid key pressed
			For $i = 0 To 2 ; TAB, ENTER, ESC
				_WinAPI_GetAsyncKeyState($aKeys[$i])
				If _WinAPI_GetAsyncKeyState($aKeys[$i]) Then
					; Set key pressed flag
					$iKey_Code = $aKeys[$i]
					ExitLoop 2
				EndIf
			Next
			For $i = 3 To 6 ; l/r/u/d with ctrl pressed
				_WinAPI_GetAsyncKeyState($aKeys[$i])
				If _WinAPI_GetAsyncKeyState($aKeys[$i]) And _WinAPI_GetAsyncKeyState(0x11) Then
					; Set key pressed flag
					$iKey_Code = $aKeys[$i]
					ExitLoop 2
				EndIf
			Next

			; Temp input lost focus
			If _WinAPI_GetFocus() <> $hTemp_Edit Then
				ExitLoop
			EndIf

			; Save CPU
			Sleep(10)
		WEnd

		; Check if edit to be confirmed
		Switch $iKey_Code
			Case 0x25, 0x26, 0x27, 0x28 ; arrow keys
				; If not standard edit control then abandon edit
				If $fEdit Then
					ContinueCase
				EndIf

			Case 0x02, 0x09, 0x0D ; Mouse (with Click_Move), TAB, ENTER
				; Read edit content
				Local $sItemNewText = GUICtrlRead($cGLVEx_EditID)
				; Check replacement required
				If $sItemNewText <> $sItemOrgText Then
					; Amend item text
					_GUICtrlListView_SetItemText($hGLVEx_Editing, $aLocation[0], $sItemNewText, $aLocation[1])
					; Amend array element
					$aGLVEx_SrcArray[$aLocation[0] + 1][$aLocation[1]] = $sItemNewText
					; Store amended array
					$aGLVEx_Data[$iLV_Index][2] = $aGLVEx_SrcArray
					; Add item data to return array
					$aEdited[0][0] += 1
					ReDim $aEdited[$aEdited[0][0] + 1][4]
					; Save location & original content
					$aEdited[$aEdited[0][0]][0] = $aLocation[0]
					$aEdited[$aEdited[0][0]][1] = $aLocation[1]
					$aEdited[$aEdited[0][0]][2] = $sItemOrgText
					$aEdited[$aEdited[0][0]][3] = $sItemNewText
				EndIf
		EndSwitch

		; Delete temporary edit and set place holder
		GUICtrlDelete($cGLVEx_EditID)
		GUICtrlDelete($cUpDown)
		$cGLVEx_EditID = 9999
		; Reset user mousecoord mode
		Opt("MouseCoordMode", $iOldMouseOpt)

		; Check edit mode
		If $iEditMode = 0 Then ; Single edit
			; Exit edit process
			ExitLoop
		Else
			Switch $iKey_Code
				Case 0x02
					$iKey_Code = 0x01
					ContinueCase

				Case 0x00, 0x01, 0x0D ; Edit lost focus, mouse button outside edit, ENTER pressed
					; Wait until key/button no longer pressed
					_WinAPI_GetAsyncKeyState($iKey_Code)
					While _WinAPI_GetAsyncKeyState($iKey_Code)
						Sleep(10)
					WEnd
					; Exit Edit process
					ExitLoop

				Case 0x1B ; ESC pressed
					; Check Reset-on-ESC mode
					If $fReset_Edits Then
						; Reset previous confirmed edits starting with most recent
						For $i = $aEdited[0][0] To 1 Step -1
							_GUICtrlListView_SetItemText($hGLVEx_Editing, $aEdited[$i][0], $aEdited[$i][2], $aEdited[$i][1])
							Switch UBound($aGLVEx_SrcArray, 0)
								Case 1
									$aSplit = StringSplit($aGLVEx_SrcArray[$aEdited[$i][0] + 1], $aGLVEx_Data[0][24])
									$aSplit[$aEdited[$i][1] + 1] = $aEdited[$i][2]
									$sInsert = ""
									For $j = 1 To $aSplit[0]
										$sInsert &= $aSplit[$j] & $aGLVEx_Data[0][24]
									Next
									$aGLVEx_SrcArray[$aEdited[$i][0] + 1] = StringTrimRight($sInsert, 1)

								Case 2
									$aGLVEx_SrcArray[$aEdited[$i][0] + 1][$aEdited[$i][1]] = $aEdited[$i][2]
							EndSwitch
						Next
						; Store amended array
						$aGLVEx_Data[$iLV_Index][2] = $aGLVEx_SrcArray
						; Empty return array as no edits were made
						Local $aEdited[1][4] = [[0]]
					EndIf
					; Wait until key no longer pressed
					_WinAPI_GetAsyncKeyState(0x1B)
					While _WinAPI_GetAsyncKeyState(0x1B)
						Sleep(10)
					WEnd
					; Exit Edit process
					ExitLoop

				Case 0x09, 0x27 ; TAB or right arrow
					While 1
						If $iEditCol <> 0 Then
							; Set next column
							$aLocation[1] += 1
							; Check column exists
							If $aLocation[1] = _GUICtrlListView_GetColumnCount($hGLVEx_Editing) Then
								; Does not exist so check required action
								Switch $iEditCol
									Case 1
										; Exit edit process
										ExitLoop 2
									Case 2
										; Stay on same location
										$aLocation[1] -= 1
										ExitLoop
									Case 3
										; Loop
										$aLocation[1] = 0
								EndSwitch
							EndIf
							; Check this column is editable
							If $aEditable[0][$aLocation[1]] <> 0 Then
								; Editable column
								ExitLoop
							Else
								; Not editable column
								ExitLoop 2
							EndIf
						Else
							; End edit
							ExitLoop 2
						EndIf
					WEnd

				Case 0x25 ; Left arrow
					While 1
						If $iEditCol <> 0 Then
							$aLocation[1] -= 1
							If $aLocation[1] < 0 Then
								Switch $iEditCol
									Case 1
										ExitLoop 2
									Case 2
										$aLocation[1] += 1
										ExitLoop
									Case 3
										$aLocation[1] = _GUICtrlListView_GetColumnCount($hGLVEx_Editing) - 1
								EndSwitch
							EndIf
							; Check this column is editable
							If $aEditable[0][$aLocation[1]] <> 0 Then
								ExitLoop
							Else
								ExitLoop 2
							EndIf
						Else
							; End edit
							ExitLoop 2
						EndIf
					WEnd

				Case 0x28 ; Down key
					While 1
						If $iEditRow <> 0 Then
							; Set next row
							$aLocation[0] += 1
							; Check column exists
							If $aLocation[0] = _GUICtrlListView_GetItemCount($hGLVEx_Editing) Then
								; Does not exist so check required action
								Switch $iEditRow
									Case 1
										; Exit edit process
										ExitLoop 2
									Case 2
										; Stay on same location
										$aLocation[0] -= 1
										ExitLoop
									Case 3
										; Loop
										$aLocation[0] = -1
								EndSwitch
							Else
								; All rows editable
								ExitLoop
							EndIf
						Else
							; End edit
							ExitLoop 2
						EndIf
					WEnd

				Case 0x26 ; Up key
					While 1
						If $iEditRow <> 0 Then
							$aLocation[0] -= 1
							If $aLocation[0] < 0 Then
								Switch $iEditRow
									Case 1
										ExitLoop 2
									Case 2
										$aLocation[0] += 1
										ExitLoop
									Case 3
										$aLocation[0] = _GUICtrlListView_GetItemCount($hGLVEx_Editing)
								EndSwitch
							Else
								ExitLoop
							EndIf
						Else
							; End edit
							ExitLoop 2
						EndIf
					WEnd
			EndSwitch
			; Wait until key no longer pressed
			_WinAPI_GetAsyncKeyState($iKey_Code)
			While _WinAPI_GetAsyncKeyState($iKey_Code)
				Sleep(10)
			WEnd
			; Continue edit loop on next item
		EndIf
	WEnd
	; Delete copied array
	$aGLVEx_SrcArray = 0
	; Reenable ListView
	WinSetState($hGLVEx_Editing, "", @SW_ENABLE)
	; Reselect item
	_GUICtrlListView_SetItemState($hGLVEx_Editing, $aLocation[0], $LVIS_SELECTED, $LVIS_SELECTED)

	; Set extended to key value
	SetExtended($iKey_Code)
	; Reset user value
	Opt("GUICloseOnESC", $iOldESC)

	; Reset current GUI to previous handle
	GUISwitch($hPrevCurrGUI)

	; Reset focus to the ListView
	_WinAPI_SetFocus($hGLVEx_Editing)

	; Return array
	Return $aEdited

EndFunc   ;==>__GUIListViewEx_EditProcess

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __GUIListViewEx_EditCoords
; Description ...: Ensures item in view then locates and sizes edit control
; Author ........: Melba23
; Modified ......:
; ===============================================================================================================================
Func __GUIListViewEx_EditCoords($hLV_Handle, $cLV_CID, $aLocation, $tLVPos, $iLVWidth, $iDelta_X, $iDelta_Y)

	; Declare array to hold return data
	Local $aEdit_Data[4]
	; Ensure row visible
	_GUICtrlListView_EnsureVisible($hLV_Handle, $aLocation[0])
	; Get size of item
	Local $aRect = _GUICtrlListView_GetSubItemRect($hLV_Handle, $aLocation[0], $aLocation[1])
	; Set required edit height
	$aEdit_Data[3] = $aRect[3] - $aRect[1] + 1
	; Set required edit width
	$aEdit_Data[2] = _GUICtrlListView_GetColumnWidth($hLV_Handle, $aLocation[1])
	; Ensure column visible - scroll to left edge if all column not in view
	If $aRect[0] < 0 Or $aRect[2] > $iLVWidth Then
		_GUICtrlListView_Scroll($hLV_Handle, $aRect[0], 0)
		; Redetermine item coords
		$aRect = _GUICtrlListView_GetSubItemRect($hLV_Handle, $aLocation[0], $aLocation[1])
		; Check available column width and limit if required
		If $aRect[0] + $aEdit_Data[2] > $iLVWidth Then
			$aEdit_Data[2] = $iLVWidth - $aRect[0]
		EndIf
	EndIf
	; Adjust Y coord if Native ListView
	If $cLV_CID Then
		$iDelta_Y += 1
	EndIf
	; Determine screen coords for edit control
	$aEdit_Data[0] = DllStructGetData($tLVPos, "X") + $aRect[0] + $iDelta_X + 2
	$aEdit_Data[1] = DllStructGetData($tLVPos, "Y") + $aRect[1] + $iDelta_Y

	; Return edit data
	Return $aEdit_Data

EndFunc   ;==>__GUIListViewEx_EditCoords

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __GUIListViewEx_ReWriteLV
; Description ...: Deletes all ListView content and refills to match array
; Author ........: Melba23
; Modified ......:
; ===============================================================================================================================
Func __GUIListViewEx_ReWriteLV($hLVHandle, ByRef $aLV_Array, ByRef $aCheck_Array, $iLV_Index, $fCheckBox = True, $fRetainWidth = True)

	Local $iVertScroll, $iColCount
	Local $iLV_CID = $aGLVEx_Data[$iLV_Index][1]

	; Get item depth
	If $aGLVEx_Data[$iLV_Index][10] Then
		$iVertScroll = $aGLVEx_Data[$iLV_Index][10]
	Else
		; If not already set then ListView was empty so determine
		Local $aRect = _GUICtrlListView_GetItemRect($hLVHandle, 0)
		$aGLVEx_Data[$iLV_Index][10] = $aRect[3] - $aRect[1]
		; If still empty set a placeholder for this instance
		If $iVertScroll = 0 Then
			; And make sure scroll is likely to be enough to get next item into view
			$iVertScroll = 20
		EndIf
	EndIf

	; Get top item
	Local $iTopIndex_Org = _GUICtrlListView_GetTopIndex($hLVHandle)

	; If native ListView column width to be retained then save column widths - normally widened if data too wide for existing width
	If $fRetainWidth And $iLV_CID Then
		$iColCount = _GUICtrlListView_GetColumnCount($hGLVEx_SrcHandle)
		; Store column widths
		Local $aCol_Width[$iColCount]
		For $i = 1 To $iColCount - 1
			$aCol_Width[$i] = _GUICtrlListView_GetColumnWidth($hGLVEx_SrcHandle, $i)
		Next
	EndIf

	_GUICtrlListView_BeginUpdate($hLVHandle)

	; Empty ListView
	_GUICtrlListView_DeleteAllItems($hLVHandle)

	; Check array to fill ListView
	If UBound($aLV_Array, 2) Then

		; Remove count line from stored array
		Local $aArray = $aLV_Array
		_ArrayDelete($aArray, 0)

		; Load ListView content
		Local $cLV_CID = $aGLVEx_Data[$iLV_Index][1]
		If $cLV_CID Then
			; Native ListView
			Local $sLine, $iLastCol = UBound($aArray, 2) - 1
			For $i = 0 To UBound($aArray) - 1
				$sLine = ""
				For $j = 0 To $iLastCol
					$sLine &= $aArray[$i][$j] & $aGLVEx_Data[0][24]
				Next
				GUICtrlCreateListViewItem(StringTrimRight($sLine, 1), $cLV_CID)
			Next
		Else
			; UDF ListView
			_GUICtrlListView_AddArray($hLVHandle, $aArray)
		EndIf

		; Reset checkbox if required
		For $i = 1 To $aLV_Array[0][0]
			If $fCheckBox And $aCheck_Array[$i] Then
				_GUICtrlListView_SetItemChecked($hLVHandle, $i - 1)
			EndIf
		Next

		; Now scroll to same place or max possible
		Local $iTopIndex_Curr = _GUICtrlListView_GetTopIndex($hLVHandle)
		While $iTopIndex_Curr < $iTopIndex_Org
			_GUICtrlListView_Scroll($hLVHandle, 0, $iVertScroll)
			; If scroll had no effect then max scroll up
			If _GUICtrlListView_GetTopIndex($hLVHandle) = $iTopIndex_Curr Then
				ExitLoop
			Else
				; Reset current top index
				$iTopIndex_Curr = _GUICtrlListView_GetTopIndex($hLVHandle)
			EndIf
		WEnd
	EndIf

	; Reset column widths if needed
	If $fRetainWidth And $iLV_CID Then
		For $i = 1 To $iColCount - 1
			$aCol_Width[$i] = _GUICtrlListView_SetColumnWidth($hGLVEx_SrcHandle, $i, $aCol_Width[$i])
		Next
	EndIf

	_GUICtrlListView_EndUpdate($hLVHandle)

EndFunc   ;==>__GUIListViewEx_ReWriteLV

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __GUIListViewEx_GetLVCoords
; Description ...: Gets screen coords for ListView
; Author ........: Melba23
; Modified ......:
; ===============================================================================================================================
Func __GUIListViewEx_GetLVCoords($hLV_Handle, ByRef $tLVPos)

	; Get handle of ListView parent
	Local $aWnd = DllCall("user32.dll", "hwnd", "GetParent", "hwnd", $hLV_Handle)
	Local $hWnd = $aWnd[0]
	; Get position of ListView within GUI client area
	Local $aLVPos = WinGetPos($hLV_Handle)
	DllStructSetData($tLVPos, "X", $aLVPos[0])
	DllStructSetData($tLVPos, "Y", $aLVPos[1])
	_WinAPI_ScreenToClient($hWnd, $tLVPos)

EndFunc   ;==>__GUIListViewEx_GetLVCoords

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __GUIListViewEx_GetCursorWnd
; Description ...: Gets handle of control under the mouse cursor
; Author ........: Melba23
; Modified ......:
; ===============================================================================================================================
Func __GUIListViewEx_GetCursorWnd()

	Local $iOldMouseOpt = Opt("MouseCoordMode", 1)
	Local $tMPos = DllStructCreate("struct;long X;long Y;endstruct")
	DllStructSetData($tMPos, "X", MouseGetPos(0))
	DllStructSetData($tMPos, "Y", MouseGetPos(1))
	Opt("MouseCoordMode", $iOldMouseOpt)
	Return _WinAPI_WindowFromPoint($tMPos)

EndFunc   ;==>__GUIListViewEx_GetCursorWnd

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __GUIListViewEx_Array_Add
; Description ...: Adds a specified value at the end of an existing 1D or 2D array.
; Author ........: Melba23
; Remarks .......:
; ===============================================================================================================================
Func __GUIListViewEx_Array_Add(ByRef $avArray, $vAdd, $fMultiRow = False, $bCount = True)

	; Get size of the Array to modify
	Local $iIndex_Max = UBound($avArray)
	Local $iAdd_Dim

	; Get type of array
	Switch UBound($avArray, 0)
		Case 1 ; Checkbox array
			If UBound($vAdd, 0) = 2 Or $fMultiRow Then ; 2D or 1D as rows
				$iAdd_Dim = UBound($vAdd, 1)
				ReDim $avArray[$iIndex_Max + $iAdd_Dim]
			Else ; 1D as columns
				ReDim $avArray[$iIndex_Max + 1]
			EndIf

		Case 2 ; Data array
			; Get column count of data array
			Local $iDim2 = UBound($avArray, 2)
			If UBound($vAdd, 0) = 2 Then ; 2D add
				; Redim the Array
				$iAdd_Dim = UBound($vAdd, 1)
				ReDim $avArray[$iIndex_Max + $iAdd_Dim][$iDim2]
				$avArray[0][0] += $iAdd_Dim
				; Add new elements
				Local $iAdd_Max = UBound($vAdd, 2)
				For $i = 0 To $iAdd_Dim - 1
					For $j = 0 To $iDim2 - 1
						; If Insert array is too small to fill Array then continue with blanks
						If $j > $iAdd_Max - 1 Then
							$avArray[$iIndex_Max + $i][$j] = ""
						Else
							$avArray[$iIndex_Max + $i][$j] = $vAdd[$i][$j]
						EndIf
					Next
				Next

			ElseIf $fMultiRow Then ; 1D add as rows
				; Redim the Array
				$iAdd_Dim = UBound($vAdd, 1)
				ReDim $avArray[$iIndex_Max + $iAdd_Dim][$iDim2]
				$avArray[0][0] += $iAdd_Dim
				; Add new elements
				For $i = 0 To $iAdd_Dim - 1
					$avArray[$iIndex_Max + $i][0] = $vAdd[$i]
				Next

			Else ; 1D add as columns
				; Redim the Array
				ReDim $avArray[$iIndex_Max + 1][$iDim2]
				If $bCount Then
					$avArray[0][0] += 1
				EndIf
				; Add new elements
				If IsArray($vAdd) Then
					; Get size of Insert array
					Local $vAdd_Max = UBound($vAdd)
					For $j = 0 To $iDim2 - 1
						; If Insert array is too small to fill Array then continue with blanks
						If $j > $vAdd_Max - 1 Then
							$avArray[$iIndex_Max][$j] = ""
						Else
							$avArray[$iIndex_Max][$j] = $vAdd[$j]
						EndIf
					Next
				Else
					; Fill Array with variable
					For $j = 0 To $iDim2 - 1
						$avArray[$iIndex_Max][$j] = $vAdd
					Next
				EndIf
			EndIf

	EndSwitch

EndFunc   ;==>__GUIListViewEx_Array_Add

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __GUIListViewEx_Array_Insert
; Description ...: Adds a value at the specified index of a 1D or 2D array.
; Author ........: Melba23
; Remarks .......:
; ===============================================================================================================================
Func __GUIListViewEx_Array_Insert(ByRef $avArray, $iIndex, $vInsert, $fMultiRow = False, $bCount = True)

	; Get size of the Array to modify
	Local $iIndex_Max = UBound($avArray)
	Local $iInsert_Dim = UBound($vInsert, 1)

	; Get type of array
	Switch UBound($avArray, 0)
		Case 1 ; Checkbox array
			If UBound($vInsert, 0) = 2 Or $fMultiRow Then ; 2D or 1D as rows
				; Resize array
				ReDim $avArray[$iIndex_Max + $iInsert_Dim]

				; Move down all elements below the new index
				For $i = $iIndex_Max + $iInsert_Dim - 1 To $iIndex + 1 Step -1
					$avArray[$i] = $avArray[$i - 1]
				Next

			Else ; 1D as columns

				; Resize array
				ReDim $avArray[$iIndex_Max + 1]

				; Move down all elements below the new index
				For $i = $iIndex_Max To $iIndex + 1 Step -1
					$avArray[$i] = $avArray[$i - 1]
				Next

				; Insert dragged element state
				$avArray[$iIndex] = $vInsert

			EndIf

		Case 2 ; Data array
			; If at end of array
			If $iIndex > $iIndex_Max - 1 Then
				__GUIListViewEx_Array_Add($avArray, $vInsert, $fMultiRow, $bCount)
				Return
			EndIf
			; Get column count of data array
			Local $iDim2 = UBound($avArray, 2)
			If UBound($vInsert, 0) = 2 Then ; 2D insert
				; Redim the Array
				$iInsert_Dim = UBound($vInsert, 1)
				ReDim $avArray[$iIndex_Max + $iInsert_Dim][$iDim2]
				If $bCount Then
					$avArray[0][0] += $iInsert_Dim
				EndIf
				; Move down all elements below the new index
				For $i = $iIndex_Max + $iInsert_Dim - 1 To $iIndex + $iInsert_Dim Step -1
					For $j = 0 To $iDim2 - 1
						$avArray[$i][$j] = $avArray[$i - $iInsert_Dim][$j]
					Next
				Next
				; Add new elements
				Local $iInsert_Max = UBound($vInsert, 2)
				For $i = 0 To $iInsert_Dim - 1
					For $j = 0 To $iDim2 - 1
						; If Insert array is too small to fill Array then continue with blanks
						If $j > $iInsert_Max - 1 Then
							$avArray[$iIndex + $i][$j] = ""
						Else
							$avArray[$iIndex + $i][$j] = $vInsert[$i][$j]
						EndIf
					Next
				Next

			ElseIf $fMultiRow Then ; 1D insert as rows
				; Redim the Array
				$iInsert_Dim = UBound($vInsert, 1)
				ReDim $avArray[$iIndex_Max + $iInsert_Dim][$iDim2]
				$avArray[0][0] += $iInsert_Dim
				; Move down all elements below the new index
				For $i = $iIndex_Max + $iInsert_Dim - 1 To $iIndex + $iInsert_Dim Step -1
					For $j = 0 To $iDim2 - 1
						$avArray[$i][$j] = $avArray[$i - $iInsert_Dim][$j]
					Next
				Next
				; Add new items
				For $i = 0 To $iInsert_Dim - 1
					$avArray[$iIndex + $i][0] = $vInsert[$i]
				Next

			Else ; 1D insert as columns
				; Redim the Array
				ReDim $avArray[$iIndex_Max + 1][$iDim2]
				$avArray[0][0] += 1
				; Move down all elements below the new index
				For $i = $iIndex_Max To $iIndex + 1 Step -1
					For $j = 0 To $iDim2 - 1
						$avArray[$i][$j] = $avArray[$i - 1][$j]
					Next
				Next
				; Insert new elements
				If IsArray($vInsert) Then
					; Get size of Insert array
					Local $vInsert_Max = UBound($vInsert)
					For $j = 0 To $iDim2 - 1
						; If Insert array is too small to fill Array then continue with blanks
						If $j > $vInsert_Max - 1 Then
							$avArray[$iIndex][$j] = ""
						Else
							$avArray[$iIndex][$j] = $vInsert[$j]
						EndIf
					Next
				Else
					; Fill Array with variable
					For $j = 0 To $iDim2 - 1
						$avArray[$iIndex][$j] = $vInsert
					Next
				EndIf
			EndIf

	EndSwitch

EndFunc   ;==>__GUIListViewEx_Array_Insert

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __GUIListViewEx_Array_Delete
; Description ...: Deletes a specified index from an existing 1D or 2D array.
; Author ........: Melba23
; Remarks .......:
; ===============================================================================================================================
Func __GUIListViewEx_Array_Delete(ByRef $avArray, $iIndex, $bDelCount = False)

	; Get size of the Array to modify
	Local $iIndex_Max = UBound($avArray)
	If $iIndex_Max = 0 Then Return

	; Adjust index if not deleting count row
	If Not $bDelCount Then
		If $iIndex = 0 Then $iIndex = 1
	EndIf

	; Get type of array
	Switch UBound($avArray, 0)
		Case 1 ; Checkbox array
			; Move up all elements below the new index
			For $i = $iIndex To $iIndex_Max - 2
				$avArray[$i] = $avArray[$i + 1]
			Next
			; Redim the Array
			ReDim $avArray[$iIndex_Max - 1]

		Case 2 ; Data array
			; Get size of second dimension
			Local $iDim2 = UBound($avArray, 2)
			; Move up all elements below the index
			For $i = $iIndex To $iIndex_Max - 2
				For $j = 0 To $iDim2 - 1
					$avArray[$i][$j] = $avArray[$i + 1][$j]
				Next
			Next
			; Redim the Array
			ReDim $avArray[$iIndex_Max - 1][$iDim2]
			; If count element not being deleted
			If Not $bDelCount Then
				$avArray[0][0] -= 1
			EndIf

	EndSwitch

EndFunc   ;==>__GUIListViewEx_Array_Delete

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __GUIListViewEx_Array_Swap
; Description ...: Swaps specified elements within a 1D or 2D array
; Author ........: Melba23
; Remarks .......:
; ===============================================================================================================================
Func __GUIListViewEx_Array_Swap(ByRef $avArray, $iIndex1, $iIndex2)

	Local $vTemp

	; Get type of array
	Switch UBound($avArray, 0)
		Case 1
			; Swap the elements via a temp variable
			$vTemp = $avArray[$iIndex1]
			$avArray[$iIndex1] = $avArray[$iIndex2]
			$avArray[$iIndex2] = $vTemp

		Case 2
			; Get size of second dimension
			Local $iDim2 = UBound($avArray, 2)
			; Swap the elements via a temp variable
			For $i = 0 To $iDim2 - 1
				$vTemp = $avArray[$iIndex1][$i]
				$avArray[$iIndex1][$i] = $avArray[$iIndex2][$i]
				$avArray[$iIndex2][$i] = $vTemp
			Next
	EndSwitch

	Return 0

EndFunc   ;==>__GUIListViewEx_Array_Swap

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __GUIListViewEx_ToolTipHide
; Description ...: Called by Adlib to hide a tooltip displayed by _GUIListViewEx_ToolTipShow
; Author ........: Melba23
; Remarks .......:
; ===============================================================================================================================
Func __GUIListViewEx_ToolTipHide()
	; Cancel Adlib
	AdlibUnRegister("__GUIListViewEx_ToolTipHide")
	; Clear tooltip
	ToolTip("")
EndFunc   ;==>__GUIListViewEx_ToolTipHide

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __GUIListViewEx_MakeString
; Description ...: Convert data/check/colour arrays to strings for saving
; Author ........: Melba23
; Remarks .......:
; ===============================================================================================================================
Func __GUIListViewEx_MakeString($aArray)

	If Not IsArray($aArray) Then Return SetError(1, 0, "")

	Local $sRet = ""
	Local $sDelim_Col = @CR
	Local $sDelim_Row = @LF

	Switch UBound($aArray, $UBOUND_DIMENSIONS)
		Case 1
			For $i = 0 To UBound($aArray, $UBOUND_ROWS) - 1
				$sRet &= $aArray[$i] & $sDelim_Row
			Next
			Return StringTrimRight($sRet, StringLen($sDelim_Col))

		Case 2
			For $i = 0 To UBound($aArray, $UBOUND_ROWS) - 1
				For $j = 0 To UBound($aArray, $UBOUND_COLUMNS) - 1
					$sRet &= $aArray[$i][$j] & $sDelim_Col
				Next
				$sRet = StringTrimRight($sRet, StringLen($sDelim_Col)) & $sDelim_Row
			Next
			Return StringTrimRight($sRet, StringLen($sDelim_Row))

		Case Else
			Return SetError(2, 0, "")
	EndSwitch

EndFunc   ;==>__GUIListViewEx_MakeString

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __GUIListViewEx_MakeArray
; Description ...: Convert data/check/colour strings to arrays for loading
; Author ........: Melba23
; Remarks .......:
; ===============================================================================================================================
Func __GUIListViewEx_MakeArray($sString)

	If $sString = "" Then Return SetError(1, 0, "")

	Local $aRetArray, $aRows, $aItems
	Local $sRowDelimiter = @LF
	Local $sColDelimiter = @CR

	If StringInStr($sString, $sColDelimiter) Then
		; 2D array
		$aRows = StringSplit($sString, $sRowDelimiter)
		; Get column count
		StringReplace($aRows[1], $sColDelimiter, "")
		; Create array
		Local $aRetArray[$aRows[0]][@extended + 1]
		; Fill array
		For $i = 1 To $aRows[0]
			$aItems = StringSplit($aRows[$i], $sColDelimiter)
			For $j = 1 To $aItems[0]
				$aRetArray[$i - 1][$j - 1] = $aItems[$j]
			Next
		Next
	Else
		; 1D array
		$aRetArray = StringSplit($sString, $sRowDelimiter, $STR_NOCOUNT)
	EndIf

	Return $aRetArray

EndFunc   ;==>__GUIListViewEx_MakeArray

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __GUIListViewEx_ColSort
; Description ...: Sort columns even if colour enabled
; Author ........: Melba23
; Remarks .......:
; ===============================================================================================================================
Func __GUIListViewEx_ColSort($hLV, $iLV_Index, ByRef $vSortSense, $iCol, $hUserSortFunction = 0, $bToggleSense = True)

	Local $aListViewContent = $aGLVEx_Data[$iLV_Index][2]
	Local $aColourSettings = $aGLVEx_Data[$iLV_Index][18]
	; Check there are items to sort
	Local $iItemCount = $aListViewContent[0][0]
	If $iItemCount Then
		; Set sort order
		Local $iDescending = 0
		If UBound($vSortSense) Then
			$iDescending = $vSortSense[$iCol]
		Else
			$iDescending = $vSortSense
		EndIf
		; Get column count
		Local $iColumnCount = UBound($aListViewContent, 2)
		; Check if colour enabled
		Local $fColourEnabled = ((IsArray($aGLVEx_Data[$iLV_Index][18])) ? (True) : (False))
		If $fColourEnabled Then
			; ReDim data to add columns for index value, ItemParam and colour settings
			ReDim $aListViewContent[UBound($aListViewContent)][($iColumnCount * 2) + 2]
			; Add colour data to array
			For $i = 1 To $iItemCount
				For $j = 0 To $iColumnCount - 1
					$aListViewContent[$i][$iColumnCount + $j + 2] = $aColourSettings[$i][$j]
				Next
			Next
		Else
			; ReDim data to add coluns for index value and ItemParam
			ReDim $aListViewContent[UBound($aListViewContent)][$iColumnCount + 2]
		EndIf
		; Determine indices for index and param elements
		Local Enum $iIndexValue = $iColumnCount, $iItemParam
		; Get selected items
		Local $sSelectedItems = _GUICtrlListView_GetSelectedIndices($hLV)
		Local $aSelectedItems
		If $sSelectedItems = "" Then
			; If no selection (colour enabled) then use stored value
			Local $aSelectedItems[2] = [1, $aGLVEx_Data[0][17]]
		Else
			$aSelectedItems = StringSplit($sSelectedItems, Opt('GUIDataSeparatorChar'))
		EndIf
		; Get checked items
		Local $aCheckedItems[$iItemCount + 1] = [0]
		For $i = 0 To $iItemCount - 1
			If _GUICtrlListView_GetItemChecked($hLV, $i) Then
				$aCheckedItems[0] += 1
				$aCheckedItems[$aCheckedItems[0]] = $i
			EndIf
		Next
		ReDim $aCheckedItems[$aCheckedItems[0] + 1]
		; Clear current focused and selected items and save item data in array
		Local $iFocused = -1
		For $i = 0 To $iItemCount - 1
			If $iFocused = -1 Then
				If _GUICtrlListView_GetItemFocused($hLV, $i) Then $iFocused = $i
			EndIf
			_GUICtrlListView_SetItemSelected($hLV, $i, False)
			_GUICtrlListView_SetItemChecked($hLV, $i, False)
			; Store index and param values
			$aListViewContent[$i + 1][$iIndexValue] = $i
			$aListViewContent[$i + 1][$iItemParam] = _GUICtrlListView_GetItemParam($hLV, $i)
		Next

		; Check which sort function to use on the clicked column within the array
		If IsFunc($hUserSortFunction) Then
			; Pass user function the standard 5 parameters
			; (ByRef LV content array, Descending variable, Start = 1 , End = 0, Column to sort)
			$hUserSortFunction($aListViewContent, $iDescending, 1, 0, $iCol)
		ElseIf $hUserSortFunction = -1 Then
			; Do nothing
		Else
			; Use standard sort function
			_ArraySort($aListViewContent, $iDescending, 1, 0, $iCol)
		EndIf

		; Enter the sorted ListView data
		For $i = 1 To $iItemCount ; Rows
			For $j = 0 To $iColumnCount - 1 ; Columns
				_GUICtrlListView_SetItemText($hLV, $i - 1, $aListViewContent[$i][$j], $j)
				; Reset the colour array if colour enabled
				If $fColourEnabled Then
					$aColourSettings[$i][$j] = $aListViewContent[$i][$iColumnCount + $j + 2]
				EndIf
			Next
			; Reset item param
			_GUICtrlListView_SetItemParam($hLV, $i - 1, $aListViewContent[$i][$iItemParam])
			; Reset selected states
			For $j = 1 To $aSelectedItems[0]
				If $aListViewContent[$i][$iIndexValue] = $aSelectedItems[$j] Then
					$aGLVEx_Data[0][17] = $i - 1
					$aGLVEx_Data[$iLV_Index][20] = $i - 1
					If Not ($aGLVEx_Data[$iLV_Index][19] Or $aGLVEx_Data[$iLV_Index][22]) Then
						If $aListViewContent[$i - 1][$iIndexValue] = $iFocused Then
							_GUICtrlListView_SetItemSelected($hLV, $i - 1, True, True)
						Else
							_GUICtrlListView_SetItemSelected($hLV, $i - 1, True)
						EndIf
						ExitLoop
					EndIf
				EndIf
			Next
			; Reset checked states
			For $j = 1 To $aCheckedItems[0]
				If $aListViewContent[$i][$iIndexValue] = $aCheckedItems[$j] Then
					_GUICtrlListView_SetItemChecked($hLV, $i - 1, True)
					ExitLoop
				EndIf
			Next
		Next
		; Check automatic sort sense toggle and adjust if required
		If $bToggleSense Then
			If UBound($vSortSense) Then
				$vSortSense[$iCol] = Not $iDescending
			Else
				$vSortSense = Not $iDescending
			EndIf
		EndIf

		; ReDim content array to remove additional columns
		ReDim $aListViewContent[UBound($aListViewContent)][$iColumnCount]
		; Store sorted arrays
		$aGLVEx_Data[$iLV_Index][2] = $aListViewContent
		$aGLVEx_Data[$iLV_Index][18] = $aColourSettings

		; Set flags using ListView index
		$aGLVEx_Data[0][19] = $iLV_Index ; SortEvent
		$aGLVEx_Data[0][22] = 1 ; ColourEvent

	EndIf

EndFunc   ;==>__GUIListViewEx_ColSort

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __GUIListViewEx_RedrawWindow
; Description ...: Redraw ListView after update
; Author ........: Melba23
; Remarks .......:
; ===============================================================================================================================
Func __GUIListViewEx_RedrawWindow($iLV_Index, $fForce = False)

	; Force redraw if colour used or single cell selection
	If $fForce Or $aGLVEx_Data[$iLV_Index][19] Or $aGLVEx_Data[$iLV_Index][22] Then
		; Force reload of redraw colour array
		$aGLVEx_Data[0][14] = 0
		; If Redraw flag set
		If $aGLVEx_Data[0][15] Then
			; Redraw ListView
			_WinAPI_RedrawWindow($aGLVEx_Data[$iLV_Index][0])
		EndIf
	EndIf

EndFunc   ;==>__GUIListViewEx_RedrawWindow

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __GUIListViewEx_CheckUserEditKey
; Description ...: Check keys pressed in ListView
; Author ........: Melba23
; Remarks .......:
; ===============================================================================================================================
Func __GUIListViewEx_CheckUserEditKey()

	Local $aKey = StringSplit($aGLVEx_Data[0][23], ";"), $iKeyValue
	; Set flag
	Local $fCheck = True
	; Check if keys required are pressed
	For $i = 1 To $aKey[0]
		; Convert to number
		$iKeyValue = Dec($aKey[$i])
		If Not _WinAPI_GetAsyncKeyState($iKeyValue) Then
			; Required key not pressed so clear flag
			$fCheck = False
			; No point in looking further
			ExitLoop
		EndIf
	Next

	Return $fCheck

EndFunc   ;==>__GUIListViewEx_CheckUserEditKey
