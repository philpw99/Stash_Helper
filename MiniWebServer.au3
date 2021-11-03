#cs
GET /i.html HTTP/1.1
Accept: image/gif, image/x-xbitmap, image/jpeg, image/png
Accept-Language: en-us
Accept-Encoding: gzip, deflate
User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 1.0.3705; .NET CLR 2.0.50727)
Host: 127.0.0.1
Connection: Keep-Alive
#ce

#include <INet.au3>
#include <File.au3>

Global $mimetypes[16] = [ _
	"html","text/html", _
	"htm","text/html", _
	"gif", "image/gif", _
	"bmp", "image/x-xbitmap", _
	"jpg", "image/jpeg", _
	"jpeg", "image/jpeg", _
	"jpe", "image/jpeg", _
	"png", "image/png"]

Global Const $E404 = '<html><head><meta http-equiv="Content-Type" content="text/html; charset=gb_2312-80"><title> Localhost:9980 - Error 404 - File not found.</title>'& _
					'</head><body bgcolor="#FFFFFF"><h2>Error 404: File not found</h2>'& _
					'<p>The server which you are requesting the file cannot find the file.</p></body></html>'


Func MiniWebServer($sBaseDir, $timeout) ; Time out is in milliseconds.
	Local $listen, $sock, $recv

	Local Const $IP = "127.0.0.1"
	Local Const $PORT = 9980

	TCPStartup()

	$listen = TCPListen($IP, $PORT, 1)
	If $listen = -1 Then
		$err = @error
		ConsoleWrite("Error, Unable to connect." & @CRLF & @CRLF & "dec: " & $err & @CRLF & "hex: 0x" & Hex($err, 8))
		Return SetError(1)
	EndIf
	Local $hTimer = TimerInit()
	While TimerDiff($hTimer) < $timeout
		$sock = TCPAccept($listen)                           ;;Poll the socket for commands
		If $sock >= 0 Then
			; Got a connection request
			$recv = _SockRecv($sock)                         ;;Get Command from socket
			$pos1 = StringInStr( $recv, "GET", 2 )
			$pos2 = StringInStr( $recv, "Host", 2 )
			$sFirstLine = StringMid( $recv, $pos1, $pos2-$pos1) ; Get between 'GET' and 'Host'
			$aFirstLine = StringSplit( $sFirstLine, " ")
			$recvRequest = $aFirstLine[2] 				        ;;Split up the Request, 2nd one is the request file.
			$pos = StringInStr( $recvRequest, ".", 2, -1)
			If $pos = 0 Then
				$sFileType="html"		; No extension, presume to be html
			Else
				$sFileType=StringMid($recvRequest,$pos+1)	; Get the request file extension.
			EndIf
			ConsoleWrite ( "Request:" & $recvRequest & " file type:" & $sFileType & @CRLF )
			$Content = _ServerGetFile($sBaseDir, $recvRequest)    ;;Normal file request
			If $Content <> $E404 Then
				; Not 404 error.
				$sHeader = _ServerGetHeader($sFileType)
			Else
				; It's a 404 error
				$sHeader = _ServerGetHeader("html")
			EndIf
			; ConsoleWrite ( "Header: " & $sHeader & "|" & @CRLF)
			_SockSend($sock, $sHeader );;Send the header first.
			_SockSend($sock, $Content) ;; Send it seperately so no string conversion.
		EndIf
		TCPCloseSocket($sock)		; Close the tcp socket to allow listening afterwards
	WEnd
	TCPShutdown()
EndFunc

Func ServerExit()
	TCPShutdown()
EndFunc

;Gets the document header
Func _ServerGetHeader($filetype)
	$mime = _ServerGetFileType($filetype)
	Return 'HTTP/1.1 200 OK' & @CRLF _
		& 'Content-Type: ' & $mime & @CRLF & @CRLF
EndFunc

;Gets the filetype for the header using the extention
Func _ServerGetFileType($ext)
	For $i = 0 to UBound($mimetypes)-1 Step 2
		If StringInStr($ext, $mimetypes[$i]) Then Return $mimetypes[$i+1]
	Next
	Return "text/html"
EndFunc

;Get a file normally
Func _ServerGetFile($sBaseDir, $filename)
	;;Default to index.html
	If $filename = "/" or $filename = "\" or $filename = "" Then
		$filename = "\index.html"
	Else
		$filename = StringReplace( $filename, "/", "\" )
		If StringLeft($filename,1) <> "\" Then
			$filename = "\" & $filename
		EndIf
	EndIf
	$file = $sBaseDir & $filename

	;;If file does not exist, send an error 404
	If Not FileExists($file) Then
		Return $E404
	EndIf

	;;Read the data from the file
	If StringInStr($filename,".htm") Then
		; html or html file
		Return FileRead($file)
	Else
		; treat it like binary
		$hFile = FileOpen($file, $FO_BINARY)
		$sData = FileRead( $hFile, FileGetSize($file) )
		FileClose($hFile)
		Return $sData
	EndIf
EndFunc

;;Sock Functions

;Recieve Data on a socket
Func _SockRecv( $iSocket, $iBytes = 2048 )
	Local $sData = ""
	;;Loop Until you recieve data on the socket
	While $sData = ""
		$sData = TCPRecv($iSocket, $iBytes)
	Wend
	;;Flash a MsgBox
	; ConsoleWrite("Receive data:" & $sData & @CRLF)
	;;Log the Command
	; _FileWriteLog( @ScriptDir&"\log.txt", $sData )
	Return $sData
EndFunc

;Send Data on a socket
Func _SockSend( $iSocket, $sData )
	Return TCPSend($iSocket, $sData)
EndFunc
