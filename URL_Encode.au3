;===============================================================================
; _URLEncode()
; Description:  : Encodes a string to be URL-friendly
; Parameter(s):  : $toEncode       - The String to Encode
;                  : $encodeType = 0 - Practical Encoding (Encode only what is necessary)
;                  :             = 1 - Encode everything
;                  :             = 2 - RFC 1738 Encoding - http://www.ietf.org/rfc/rfc1738.txt
; Return Value(s): : The URL encoded string
; Author(s):  : nfwu
; Note(s):   : -
;
;===============================================================================
Func _URLEncode($toEncode, $encodeType = 0)
 Local $strHex = "", $iDec
 Local $aryChar = StringSplit($toEncode, "")
 If $encodeType = 1 Then;;Encode EVERYTHING
  For $i = 1 To $aryChar[0]
   $strHex = $strHex & "%" & Hex(Asc($aryChar[$i]), 2)
  Next
  Return $strHex
 ElseIf $encodeType = 0 Then;;Practical Encoding
  For $i = 1 To $aryChar[0]
   $iDec = Asc($aryChar[$i])
   if $iDec <= 32 Or $iDec = 37 Then
    $strHex = $strHex & "%" & Hex($iDec, 2)
   Else
    $strHex = $strHex & $aryChar[$i]
   EndIf
  Next
  Return $strHex
 ElseIf $encodeType = 2 Then;;RFC 1738 Encoding
  For $i = 1 To $aryChar[0]
   If Not StringInStr("$-_.+!*'(),;/?:@=&abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890", $aryChar[$i]) Then
    $strHex = $strHex & "%" & Hex(Asc($aryChar[$i]), 2)
   Else
    $strHex = $strHex & $aryChar[$i]
   EndIf
  Next
  Return $strHex
 EndIf
EndFunc
;===============================================================================
; _URLDecode()
; Description:  : Tranlates a URL-friendly string to a normal string
; Parameter(s):  : $toDecode - The URL-friendly string to decode
; Return Value(s): : The URL decoded string
; Author(s):  : nfwu
; Note(s):   : -
;
;===============================================================================
Func _URLDecode($toDecode)
 local $strChar = "", $iOne, $iTwo
 Local $aryHex = StringSplit($toDecode, "")
 For $i = 1 to $aryHex[0]
  If $aryHex[$i] = "%" Then
   $i = $i + 1
   $iOne = $aryHex[$i]
   $i = $i + 1
   $iTwo = $aryHex[$i]
   $strChar = $strChar & Chr(Dec($iOne & $iTwo))
  Else
   $strChar = $strChar & $aryHex[$i]
  EndIf
 Next
 Return StringReplace($strChar, "+", " ")
EndFunc