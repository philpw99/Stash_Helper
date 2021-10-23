
#include-once

; #AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w- 4 -w 5 -w 6 -w- 7

; #INDEX# =======================================================================================================================
; Title .........: _Date_Time_Convert
; AutoIt Version : v3.3.8.1 or higher
; Language ......: English
; Description ...: Converts between date/time formats
; Note ..........:
; Author(s) .....: Melba23
; Remarks .......:
; ===============================================================================================================================

; #CURRENT# =====================================================================================================================
; _Date_Time_Convert     : Convert between date/time formats
; _Date_Time_Convert_Set : Set non-English strings for long/short day/month names
; ===============================================================================================================================

; #INTERNAL_USE_ONLY#=================================================================================================
; __DTC_Create_Array : Creates long/short day/month names
; __DTC_Match_Array  : Matches long/short day/month names
; ===============================================================================================================================

; #GLOBAL VARIABLES# =================================================================================================
Global $g_sDTC_Mon_Long_In, $g_sDTC_Mon_Short_In, $g_sDTC_Day_Long_In, $g_sDTC_Day_Short_In
Global $g_sDTC_Mon_Long_Out, $g_sDTC_Mon_Short_Out, $g_sDTC_Day_Long_Out, $g_sDTC_Day_Short_Out
; ===============================================================================================================================

; #FUNCTION# ====================================================================================================================
; Name...........: _Date_Time_Convert
; Description ...: Converts between date/time formats
; Syntax.........: _Date_Time_Convert($sIn_Date, $sIn_Mask, $sOut_Mask [, $i19_20])
; Parameters ....: $sIn_Date  - Valid date/time string
;                                   Only one element from each main group should be defined (exception Day name/date)
;                  $sIn_Mask  - Mask defining the date/time elements used in the In_Date string.  Mask is made up as follows:
;                                   Year   : yyyy = 2013
;                                            yy = 13
;                                   Month  : MMMM = April (long)
;                                            MMM = Apr (short)
;                                            MM = 04 (2 digit padded)
;                                            M = 4 (1/2 digit) *
;                                   Day    : dddd = Thursday (long)
;                                            ddd = Thu (short)
;                                   Day    : dd = 01 (2 digit padded)
;                                            d = 1 (1/2 digit) *
;                                   Hour   : HH = 20 (2 digit 24 hr)
;                                            hh = 08 (2 digit padded 12 hr)
;                                            h = 8 (1/2 digit 12 hr) *
;                                   Minute : mm = 05 (2 digit padded)
;                                            m = 5 (1/2 digit) *
;                                   Second : ss = 08 (2 digit padded)
;                                            s = 8 (1/2 digit) *
;                                   AM/PM  : TT = AM/PM
;                                            T = A/P
;                               Any additional text or punctuation in the date/time string must be matched in the mask
;                                   but need not be exact so that mask letters can be avoided
;                  $sOut_Mask - Mask defining date/time elements used in the returned string.  Uses the same format as $sIn_Mask
;                                   Exact additional text or punctuation required must be included, so avoid mask letters
;                  $i19_20    - Year which determines either 19## to 20## for long year format if only short format defined
;                                   Default = 50 (1951-1999, 2000-2050)
; Requirement(s).: v3.3.8.1 or higher
; Return values .: Success: A string containing required date/time format as set out in the $sOut_Mask parameter
;                  Failure: An empty string with @error set as follows
;                            @error = 1 with @extended set as follows (all refer to $sIn_Date):
;                                0 = Both long and short year formats
;                                1 = More than one month format
;                                2 = Both padded and unpadded day formats
;                                4 = Both padded and unpadded 12 hr formats
;                                5 = Both padded and unpadded min formats
;                                6 = Both padded and unpadded sec formats
;                                7 = Both long and short AM/PM formats
;                                8 = Only 12 hr hour format and no AM/PM set
;                            @error = 2 with @extended set as follows:
;                                0 = Invalid year (1000 - 2999)
;                                1 = Invalid month (1 - 12)
;                                2 = Invalid day (1 - depends on month/leap year)
;                                3 = Invalid hour when converted to 24hr format (0 - 23)
;                                4 = Invalid minute (0 - 59)
;                                5 = Invalid second (0 - 59)
;                            @error = 3 - Invalid $i19_20 parameter
;                            @error = 4 with @extended set as follows
;                                1 = Invalid In Mask
;                                2 = Invalid Out Mask
; Author ........: Melba23
; Remarks .......: Undefined $sOut_Mask date/time elements set to similar number of "-/*" characters
;                  If $sIn_Date includes a valid date then the day name is automatically set for that date even if another name provided
;                  Padded 1/2 digit masks (* above) must be followed by a non-numeric or space character if only single digit - if not
;                      they are assumed to be double digit
; Example .......; Yes
; ===============================================================================================================================
Func _Date_Time_Convert($sIn_Date, $sIn_Mask, $sOut_Mask, $i19_20 = Default)

	#region ; Initialisation

		; Declare variables
		Local $iCaret_Date = 1, $iCaret_Mask = 1, $sCurr_Char, $iLen, $sCurr_Date

		; Create array of mask characters and valid repeat numbers
		Local $aMask[8][5] = [["y", 0, 1, 0, 1], _
							  ["M", 1, 1, 1, 1], _
							  ["d", 1, 1, 1, 1], _
							  ["H", 0, 1, 0, 0], _
							  ["h", 1, 1, 0, 0], _
							  ["m", 1, 1, 0, 0], _
							  ["s", 1, 1, 0, 0], _
							  ["T", 1, 1, 0, 0]]
		; Create array to hold In_Date data
		Local $aDTC_Data[UBound($aMask)][5]

		; Create default month/day string arrays
		Local $aMon_Long_In[13] = [12, "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
		Local $aMon_Long_Out = $aMon_Long_In
		Local $aMon_Short_In[13] = [12, "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
		Local $aMon_Short_Out = $aMon_Short_In
		Local $aDay_Long_In[8] = [7, "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
		Local $aDay_Long_Out = $aDay_Long_In
		Local $aDay_Short_In[8] = [7, "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
		Local $aDay_Short_Out = $aDay_Short_In

		; Check if In names overridden
		If $g_sDTC_Mon_Long_In Then
			$aMon_Long_In = __DTC_Create_Array($g_sDTC_Mon_Long_In)
		EndIf
		If $g_sDTC_Mon_Short_In Then
			$aMon_Short_In = __DTC_Create_Array($g_sDTC_Mon_Short_In, $aMon_Long_In)
		EndIf
		If $g_sDTC_Day_Long_In Then
			$aDay_Long_In = __DTC_Create_Array($g_sDTC_Day_Long_In)
		EndIf
		If $g_sDTC_Day_Short_In Then
			$aDay_Short_In = __DTC_Create_Array($g_sDTC_Day_Short_In, $aDay_Long_In)
		EndIf

		; Check if Out names overridden
		If $g_sDTC_Mon_Long_Out Then
			$aMon_Long_Out = __DTC_Create_Array($g_sDTC_Mon_Long_Out)
		EndIf
		If $g_sDTC_Mon_Short_Out Then
			$aMon_Short_Out = __DTC_Create_Array($g_sDTC_Mon_Short_Out, $aMon_Long_Out)
		EndIf
		If $g_sDTC_Day_Long_Out Then
			$aDay_Long_Out = __DTC_Create_Array($g_sDTC_Day_Long_Out)
		EndIf
		If $g_sDTC_Day_Short_Out Then
			$aDay_Short_Out = __DTC_Create_Array($g_sDTC_Day_Short_Out, $aDay_Long_Out)
		EndIf

		; Check $i19_20
		Switch $i19_20
			Case Default
				$i19_20 = 50
			Case 0 To 99
				$i19_20 = Int($i19_20)
			Case Else
				Return SetError(3, 0, "")
		EndSwitch

	#endregion ; Initialisation
	#region ; Get data from In_Date

		; Work through In_Mask and extract data from In_Date
		For $iCaret_Mask = 1 To StringLen($sIn_Mask)
			$sCurr_Char = StringMid($sIn_Mask, $iCaret_Mask, 1)
			$iLen = 0
			For $i = 0 To UBound($aMask) - 1
				; Current character is a mask character
				If $sCurr_Char == $aMask[$i][0] Then
					; See how many characters in the mask
					While 1
						$iLen += 1
						If StringMid($sIn_Mask, $iCaret_Mask + $iLen, 1) <> $sCurr_Char Then ExitLoop
					WEnd
					; Check for valid In_Mask pattern
					If Not $aMask[$i][$iLen] Then
						Return SetError(4, 1, "")
					EndIf
					; Now extract the value from In-Date
					Switch $iLen
						Case 1
							Switch $sCurr_Char
								Case "M", "d", "h", "m", "s"
									; Single mask char - could be 1 or 2 digit
									If StringRegExp(StringMid($sIn_Date, $iCaret_Date + 1, 1), "[0-9]") Then
										$sCurr_Date = Number(StringMid($sIn_Date, $iCaret_Date, 2))
										$iCaret_Date += 1 ; +1 auto
									Else
										$sCurr_Date = Number(StringMid($sIn_Date, $iCaret_Date, 1))
										; Caret_Date +1 auto
									EndIf
									; Caret_Mask +1 auto
								Case "T"
									$sCurr_Date = StringMid($sIn_Date, $iCaret_Date, 1)
								Case "H"
									ConsoleWrite("Hit" & @CRLF)
							EndSwitch
						Case 2
							; Always 2 digit
							$sCurr_Date = StringMid($sIn_Date, $iCaret_Date, 2)
							$iCaret_Date += 1 ; +1 auto
							$iCaret_Mask += 1 ; +1 auto
						Case 3
							Switch $sCurr_Char
								Case "M"
									; Search short array
									$sCurr_Date = __DTC_Match_Array($aMon_Short_In, $sIn_Date, $iCaret_Date)
									$iCaret_Date += @extended
									; Save index not name
									$iLen = 1
								Case "d"
									$sCurr_Date = __DTC_Match_Array($aDay_Short_In, $sIn_Date, $iCaret_Date)
									$iCaret_Date += @extended
									; Save index not name
									$iLen = 0
							EndSwitch
							$iCaret_Mask += 2 ; +1 auto
						Case 4
							Switch $sCurr_Char
								Case "y"
									; 4 digit year
									$sCurr_Date = StringMid($sIn_Date, $iCaret_Date, 4)
									$iCaret_Date += 3 ; +1 auto
								Case "M"
									; Search long array
									$sCurr_Date = __DTC_Match_Array($aMon_Long_In, $sIn_Date, $iCaret_Date)
									$iCaret_Date += @extended
									; Save index not name
									$iLen = 1
								Case "d"
									; Search long array
									$sCurr_Date = __DTC_Match_Array($aDay_Long_In, $sIn_Date, $iCaret_Date)
									$iCaret_Date += @extended
									; Save index not name
									$iLen = 0
							EndSwitch
							$iCaret_Mask += 3 ; +1 auto
					EndSwitch
					; Store the extracted data
					$aDTC_Data[$i][$iLen] = $sCurr_Date
					ExitLoop
				EndIf
			Next
			; Auto-increase Caret_Date - Caret_Mask increased by loop
			$iCaret_Date += 1
		Next

	#endregion ; Get data from In_Date
	#region ; Fill data array ready for use by Out_Mask

		; Year
		If $aDTC_Data[0][2] And $aDTC_Data[0][4] Then ; Check only 1 element set
			Return SetError(1, 0, "")
		ElseIf $aDTC_Data[0][4] Then ; If long year...
			$aDTC_Data[0][2] = StringRight($aDTC_Data[0][4], 2) ; ...set short year
		ElseIf $aDTC_Data[0][2] Then ; If short year...
			If $aDTC_Data[0][2] > $i19_20 Then
				$aDTC_Data[0][4] = "19" & $aDTC_Data[0][2] ; ...assume 1951-1999...
			Else
				$aDTC_Data[0][4] = "20" & $aDTC_Data[0][2] ; ...and 2000-2050
			EndIf
		Else
			$aDTC_Data[0][2] = "--"
			$aDTC_Data[0][4] = "----"
		EndIf
		; Check valid year
		If ($aDTC_Data[0][4] < 1000 Or $aDTC_Data[0][4] > 2999) And $aDTC_Data[0][4] <> "----" Then
			Return SetError(2, 0, "")
		EndIf

		; Month
		If $aDTC_Data[1][1] And $aDTC_Data[1][2] Then ; Check only 1 element set
			Return SetError(1, 1, "")
		EndIf
		If $aDTC_Data[1][1] Then ; Unpadded month
			; Check valid month
			If ($aDTC_Data[1][1] < 1 Or $aDTC_Data[1][1] > 12) Then
				Return SetError(2, 1, "")
			EndIf
			$aDTC_Data[1][2] = StringFormat("%02i", $aDTC_Data[1][1])
			$aDTC_Data[1][3] = $aMon_Short_Out[$aDTC_Data[1][1]]
			$aDTC_Data[1][4] = $aMon_Long_Out[$aDTC_Data[1][1]]
		ElseIf $aDTC_Data[1][2] Then ; Padded month
			If ($aDTC_Data[1][2] < 1 Or $aDTC_Data[1][2] > 12) Then
				Return SetError(2, 1, "")
			EndIf
			$aDTC_Data[1][1] = Int($aDTC_Data[1][2])
			$aDTC_Data[1][3] = $aMon_Short_Out[$aDTC_Data[1][1]]
			$aDTC_Data[1][4] = $aMon_Long_Out[$aDTC_Data[1][1]]
		Else
			$aDTC_Data[1][1] = "-"
			$aDTC_Data[1][2] = "--"
			$aDTC_Data[1][3] = "---"
			$aDTC_Data[1][4] = "---"
		EndIf

		; Day
		If $aDTC_Data[2][1] And $aDTC_Data[2][2] Then ; Check only 1 numeric element set
			Return SetError(1, 2, "")
		EndIf
		If $aDTC_Data[2][1] Then ; Unpadded day
			$aDTC_Data[2][2] = StringFormat("%02i", $aDTC_Data[2][1])
		ElseIf $aDTC_Data[2][2] Then ; Padded day
			$aDTC_Data[2][1] = Int($aDTC_Data[2][2])
		Else
			$aDTC_Data[2][1] = "-"
			$aDTC_Data[2][2] = "--"
		EndIf
		; Check valid day
		Local $aDayLimit[13] = [0, 32, 29, 32, 31, 32, 31, 32, 32, 31, 32, 31, 32]
		If (Mod($aDTC_Data[0][4], 4) = 0 And Mod($aDTC_Data[0][4], 100) <> 0) Or Mod($aDTC_Data[0][4], 400) = 0 Then
			$aDayLimit[2] = 30
		EndIf
		If $aDTC_Data[2][2] > 0 And $aDTC_Data[2][2] < $aDayLimit[$aDTC_Data[1][1]] Then
			; Determine correct weekday index
			Local $i_aFactor = Int((14 - $aDTC_Data[1][2]) / 12) ; MM
			Local $i_yFactor = $aDTC_Data[0][4] - $i_aFactor ; yyyy
			Local $i_mFactor = $aDTC_Data[1][2] + (12 * $i_aFactor) - 2 ; MM
			; Replace any found alpha value
			$aDTC_Data[2][0] = 1 + Mod($aDTC_Data[2][2] + $i_yFactor + Int($i_yFactor / 4) - Int($i_yFactor / 100) + _
				Int($i_yFactor / 400) + Int((31 * $i_mFactor) / 12), 7) ; dd
		Else
			If $aDTC_Data[2][2] <> "--" Then
				Return SetError(2, 2, "")
			EndIf
		EndIf

		; Set day name
		$aDTC_Data[2][3] = $aDay_Short_Out[$aDTC_Data[2][0]]
		$aDTC_Data[2][4] = $aDay_Long_Out[$aDTC_Data[2][0]]

		; AM/PM
		$aDTC_Data[7][1] = StringUpper($aDTC_Data[7][1]) ; Uppercase existing elements
		$aDTC_Data[7][2] = StringUpper($aDTC_Data[7][2])
		If $aDTC_Data[7][1] And $aDTC_Data[7][2] Then ; Check only 1 element set
			Return SetError(1, 7, "")
		EndIf
		; Set other element
		If $aDTC_Data[7][1] Then
			$aDTC_Data[7][2] = $aDTC_Data[7][1] & "M"
		ElseIf $aDTC_Data[7][2] Then
			$aDTC_Data[7][1] = StringLeft($aDTC_Data[7][2], 1)
		EndIf

		; Hour 24
		If $aDTC_Data[3][2] Then
			; Set defaults
			$aDTC_Data[4][1] = "12"
			$aDTC_Data[4][2] = "12"
			$aDTC_Data[7][1] = "A" ; Note forced AM/PM if 24hr format hour
			$aDTC_Data[7][2] = "AM"
			Switch $aDTC_Data[3][2]
				Case 0
					; Do nothing
				Case 1 To 11
					$aDTC_Data[4][1] = Int($aDTC_Data[3][2])
					$aDTC_Data[4][2] = $aDTC_Data[3][2]
				Case 12
					$aDTC_Data[7][1] = "P"
					$aDTC_Data[7][2] = "PM"
				Case Else
					$aDTC_Data[4][1] = Int($aDTC_Data[3][2] - 12)
					$aDTC_Data[4][2] = StringFormat("%02i", $aDTC_Data[3][2] - 12)
					$aDTC_Data[7][1] = "P"
					$aDTC_Data[7][2] = "PM"
			EndSwitch
			; Hour 12
		Else
			If $aDTC_Data[4][1] And $aDTC_Data[4][2] Then ; Check only 1 element set
				Return SetError(1, 4, "")
			EndIf
			If ($aDTC_Data[4][1] Or $aDTC_Data[4][2]) And $aDTC_Data[7][1] & $aDTC_Data[7][2] = "" Then ; No AM/PM set
				Return SetError(1, 8, "")
			EndIf
			If $aDTC_Data[4][1] & $aDTC_Data[4][2] = "" Then ; Set to 0 if no value set
				$aDTC_Data[4][1] = "*"
				$aDTC_Data[4][2] = "**"
			ElseIf $aDTC_Data[4][1] Then ; Unpadded hour
				$aDTC_Data[4][2] = StringFormat("%02i", $aDTC_Data[4][1])
			ElseIf $aDTC_Data[4][2] Then ; Padded hour
				$aDTC_Data[4][1] = Int($aDTC_Data[4][2])
			EndIf
			; Set 24hr elements
			If $aDTC_Data[7][1] = "P" Then
				Switch $aDTC_Data[4][1]
					Case 12
						$aDTC_Data[3][2] = "12"
					Case Else
						$aDTC_Data[3][2] = StringFormat("%02i", $aDTC_Data[4][1] + 12)
				EndSwitch
			Else
				Switch $aDTC_Data[4][1]
					Case 12
						$aDTC_Data[3][2] = "00"
					Case Else
						$aDTC_Data[3][2] = StringFormat("%02i", $aDTC_Data[4][1])
				EndSwitch
			EndIf
		EndIf
		; Check valid hour
		If $aDTC_Data[3][2] < 0 Or $aDTC_Data[3][2] > 23 Then
			Return SetError(2, 3, "")
		EndIf

		; Min
		If $aDTC_Data[5][1] And $aDTC_Data[5][2] Then ; Check only 1 element set
			Return SetError(1, 5, "")
		EndIf
		If $aDTC_Data[5][1] & $aDTC_Data[5][2] = "" Then ; Set to 0 if no value set
			$aDTC_Data[5][1] = "*"
			$aDTC_Data[5][2] = "**"
		ElseIf $aDTC_Data[5][1] Then ; Unpadded min
			$aDTC_Data[5][2] = StringFormat("%02i", $aDTC_Data[5][1])
		ElseIf $aDTC_Data[5][2] Then ; padded Min
			$aDTC_Data[5][1] = Int($aDTC_Data[5][2])
		EndIf
		; Check valid minute
		If $aDTC_Data[5][1] < 0 Or $aDTC_Data[5][1] > 59 Then
			Return SetError(2, 4, "")
		EndIf

		; Sec
		If $aDTC_Data[6][1] And $aDTC_Data[6][2] Then ; Check only 1 element set
			Return SetError(1, 6, "")
		EndIf
		If $aDTC_Data[6][1] & $aDTC_Data[6][2] = "" Then ; Set to 0 if no value set
			$aDTC_Data[6][1] = "*"
			$aDTC_Data[6][2] = "**"
		ElseIf $aDTC_Data[6][1] Then ; Unpadded sec
			$aDTC_Data[6][2] = StringFormat("%02i", $aDTC_Data[6][1])
		ElseIf $aDTC_Data[6][2] Then ; Padded sec
			$aDTC_Data[6][1] = Int($aDTC_Data[6][2])
		EndIf
		; Check valid second
		If $aDTC_Data[6][1] < 0 Or $aDTC_Data[6][1] > 59 Then
			Return SetError(2, 5, "")
		EndIf

	#endregion ; Fill data array ready for use by Out_Mask
	#region ; Create Out_Date

		; Declare empty Out_Date
		Local $sOut_Date = ""

		; Reset caret for Out_Mask
		$iCaret_Mask = 1
		; Move through Out_Mask
		For $iCaret_Mask = 1 To StringLen($sOut_Mask)
			$sCurr_Char = StringMid($sOut_Mask, $iCaret_Mask, 1)
			$iLen = 0
			For $i = 0 To UBound($aMask) - 1
				; Current character is a mask character
				If $sCurr_Char == $aMask[$i][0] Then
					While 1
						$iLen += 1
						If StringMid($sOut_Mask, $iCaret_Mask + $iLen, 1) <> $sCurr_Char Then ExitLoop
					WEnd
					; Check for valid Out_Mask pattern
					If Not $aMask[$i][$iLen] Then
						Return SetError(4, 2, "")
					EndIf
					; Add correct value to Out_Date
					$sOut_Date &= $aDTC_Data[$i][$iLen]
					; Move caret for next check
					$iCaret_Mask += $iLen - 1
					ExitLoop
				EndIf
			Next
			; If not mask character
			If $iLen = 0 Then
				; Add to Out_Date
				$sOut_Date &= $sCurr_Char
			EndIf
		Next

		; Return Out_Date
		Return $sOut_Date

	#endregion ; Create Out_Date

EndFunc   ;==>_Date_Time_Convert

; #FUNCTION# ====================================================================================================================
; Name...........: _Date_Time_Convert_Set
; Description ...: Set non-English strings for long/short day/month names
; Syntax.........: _Date_Time_Convert_Set([$sType = "" [, $sData = 0]])
; Parameters ....: $sType - 3-char string to determine whether data for Month/Day, Long/Short, In/Out array
;                               Elements can be used in any order in lower or upper case
;                               Omitting this parameter sets all strings to "" and resets default English names
;                  $sData - String of alphabetical long/short names for months/days, separated by "," with no spaces
;                               For "short" names only, a single numerical digit uses that many characters from the long name
; Requirement(s).: v3.3.8.1 or higher
; Return values .: Success: 1
;                  Failure: 0 and @error set to 1 with @extended set as follows
;                             1 - Month Long In invalid
;                             1 - Month Short In invalid
;                             1 - Day Long In invalid
;                             1 - Day Short In invalid
;                             1 - Month Long Out invalid
;                             1 - Month Short Out invalid
;                             1 - Day Long Out invalid
;                             1 - Day Short Out invalid
; Author ........: Melba23
; Remarks .......:
; Example .......; Yes
; ===============================================================================================================================
Func _Date_Time_Convert_Set($sType = "", $sData = "")

	Switch $sType
		; In
		Case "MLI", "MIL", "LMI", "LIM", "ILM", "IML"
			; Count elements
			StringReplace($sData, ",", ",")
			If @extended <> 11 Then
				Return SetError(1, 1, 0)
			EndIf
			$g_sDTC_Mon_Long_In = $sData
		Case "MSI", "MIS", "SMI", "SIM", "ISM", "IMS"
			If Not IsInt($sData) Then
				StringReplace($sData, ",", ",")
				If @extended <> 11 Then
					Return SetError(1, 2, 0)
				EndIf
			EndIf
			$g_sDTC_Mon_Short_In = $sData
		Case "DLI", "DIL", "LDI", "LID", "ILD", "IDL"
			StringReplace($sData, ",", ",")
			If @extended <> 6 Then
				Return SetError(1, 3, 0)
			EndIf
			$g_sDTC_Day_Long_In = $sData
		Case "DSI", "DIS", "SDI", "SID", "ISD", "IDS"
			If Not IsInt($sData) Then
				StringReplace($sData, ",", ",")
				If @extended <> 6 Then
					Return SetError(1, 4, 0)
				EndIf
			EndIf
			$g_sDTC_Day_Long_In = $sData

		; Out
		Case "MLO", "MOL", "LMO", "LOM", "OLM", "OML"
			StringReplace($sData, ",", ",")
			If @extended <> 11 Then
				Return SetError(1, 5, 0)
			EndIf
			$g_sDTC_Mon_Long_Out = $sData
		Case "MSO", "MOS", "SMO", "SOM", "OSM", "OMS"
			If Not IsInt($sData) Then
				StringReplace($sData, ",", ",")
				If @extended <> 11 Then
					Return SetError(1, 6, 0)
				EndIf
			EndIf
			$g_sDTC_Mon_Short_Out = $sData
		Case "DLO", "DOL", "LDO", "LOD", "OLD", "ODL"
			StringReplace($sData, ",", ",")
			If @extended <> 6 Then
				Return SetError(1, 7, 0)
			EndIf
			$g_sDTC_Day_Long_Out = $sData
		Case "DSO", "DOS", "SDO", "SOD", "OSD", "ODS"
			If Not IsInt($sData) Then
				StringReplace($sData, ",", ",")
				If @extended <> 6 Then
					Return SetError(1, 8, 0)
				EndIf
			EndIf
			$g_sDTC_Day_Short_Out = $sData

		; Reset to default
		Case Else
			$g_sDTC_Mon_Long_In = ""
			$g_sDTC_Mon_Short_In = ""
			$g_sDTC_Day_Long_In = ""
			$g_sDTC_Day_Short_In = ""
			$g_sDTC_Mon_Long_Out = ""
			$g_sDTC_Mon_Short_Out = ""
			$g_sDTC_Day_Long_Out = ""
			$g_sDTC_Day_Short_Out = ""
	EndSwitch

	Return 1

EndFunc   ;==>_Date_Time_Convert_Set

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __DTC_Create_Array
; Description ...: Creates long/short day/month names
; Author ........: Melba23
; Remarks .......:
; ===============================================================================================================================
Func __DTC_Create_Array($sString, $aArray = "")

	If IsNumber($sString) Then
		; Create shortened version of Long name array
		Local $iBound = UBound($aArray) - 1
		Local $aRet[$iBound + 1] = [$iBound]
		For $i = 1 To $iBound
			$aRet[$i] = StringLeft($aArray[$i], $sString)
		Next
		Return $aRet
	Else
		; Split string into array
		Return StringSplit($sString, ",")
	EndIf

EndFunc   ;==>__DTC_Create_Array

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: __DTC_Match_Array
; Description ...: Matches long/short day/month names
; Author ........: Melba23
; Remarks .......:
; ===============================================================================================================================
Func __DTC_Match_Array($aArray, $sString, $iIndex)

	Local $sItem, $iLen

	For $i = 1 To $aArray[0]
		; For each element
		$sItem = StringUpper($aArray[$i])
		$iLen = StringLen($sItem)
		; Compare to In_Date string
		If $sItem == StringUpper(StringMid($sString, $iIndex, $iLen)) Then
			Return SetExtended($iLen - 1, $i)
		EndIf
	Next
	Return SetExtended(0, "")

EndFunc   ;==>__DTC_Match_Array


