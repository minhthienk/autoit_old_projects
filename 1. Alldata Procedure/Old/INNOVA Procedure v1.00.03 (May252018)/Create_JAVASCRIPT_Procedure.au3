#cs ----------------------------------------------------------------------------
NOTE:
#ce ----------------------------------------------------------------------------


#include-once

#include <MsgBoxConstants.au3>
#include <FileConstants.au3>
#include <InetConstants.au3>

#include <Clipboard.au3>
#include <IE.au3>
#include <Excel.au3>
#include <WinAPIFiles.au3>




;====================================================================================================================
;                  FUNCTION DISCRIPTION: CREATE OTHER PROCEDURE IN DTC FROM ALLDATA
;				   RETURN              : A STRING OF PROCEDURE PATH
;====================================================================================================================
Func Create_JAVASCRIPT_Procedure ($sFilePath_YMME, $sProcedure_Link, $sInfo)
   ;------------------------------------------------------------------------------------------------------------------
   ;ĐOẠN CODE LẤY LINK CÁC PARTS TỪ LINK JAVASCRIPT
   Local $aPart_Links [1000] = Get_Procedure_Links_In_JAVASCRIPT ($sProcedure_Link)
   ;Nếu link javascript có chứa link procedure
   If $aPart_Links [0] <> "Page not found" Then
	  Local $iCount_Max = 0
	  While $aPart_Links [$iCount_Max] <> ""
		 $iCount_Max = $iCount_Max + 1
	  WEnd
	  $iCount_Max = $iCount_Max - 1
	  Local $sProcedure_Path = ""
	  For $i = $iCount_Max To 0 Step -1
		 Local $oIE_Procedure = IECreate_Check_Error ($aPart_Links [$i],  $bWeb_Attach, $bWeb_Visible, $bWeb_Wait, $bWeb_TakeFocus)
		 ;ĐOẠN CODE SỬ DỤNG FUNCTION "Check_Subscription_Alldata" ĐỂ KIỂM TRA SUBSCIPTION
		 $oIE_Procedure = Check_Subscription_Alldata ($oIE_Procedure, $sProcedure_Link, $iSubscription_Num)
		 ;------------------------------------------------------------------------------------------------------------------
		 ;ĐOẠN CODE LẤY TEXT TRONG TAG <TITLE> ĐỂ LÀM TITLE CHO HTML PROCEDURE VÀ KIỂM TRA XEM LINK ĐÓ CÓ PHẢI LINK DTC HAY KHÔNG
		 Local $sTxt_Title_Alldata = _IEPropertyGet ($oIE_Procedure, "title")
		 Local $sTxt_Title = $sTxt_Title_Alldata
		 $sTxt_Title = Standardize_String ($sTxt_Title)
		 ;------------------------------------------------------------------------------------------------------------------
		 ;Chỉnh sửa text trong Procedure của All data cho phù hợp với Innova
		 $sTxt_Body = Modify_Body_HTML ($oIE_Procedure)
		 ;------------------------------------------------------------------------------------------------------------------
		 ;Code lấy tên procedure trong $sTxt_Title để làm title cho file html và folder name cho Procedure
		 ;Mẫu: Computers and Control Systems |Testing and Inspection, Reading and Clearing Diagnostic Trouble Codes: DTC Check / Clear
		 $sTxt_Title = StringRight ($sTxt_Title, StringLen ($sTxt_Title) - StringInStr($sTxt_Title, ": ") - 1)
		 ;Chuẩn tên theo window
		 $sTxt_Title = Standardize_File_Name ($sTxt_Title)
		 ;Thêm string "Procedure: " phía trước
		 $sTxt_Title = "Procedure: " & $sTxt_Title
		 ;------------------------------------------------------------------------------------------------------------------
		 ;ĐOẠN CODE LẤY CÁC ID TRONG URL ĐỂ ĐẶT TÊN CHO PROCEDURE
		 Local $sTxt_File_Name = Create_Procedure_Name ($oIE_Procedure)
		 ;------------------------------------------------------------------------------------------------------------------
		 ;ĐOẠN CODE TẠO THƯ MỤC VÀ TẢI HÌNH ẢNH VỀ THƯ MỤC ĐÓ
		 ;Tạo các thư mục cần thiết
		 Local $sFilePath_PROCEDURE  = $sFilePath_YMME      &"\PROCEDURE"
		 If FileExists ($sFilePath_PROCEDURE) = 0 Then DirCreate($sFilePath_PROCEDURE)
		 Local $sFilePath_Title      = $sFilePath_YMME      &"\PROCEDURE"       &"\"& $sTxt_File_Name
		 If FileExists ($sFilePath_Title) = 0 Then	DirCreate($sFilePath_Title)
		 ;Tải hình ảnh của procedure vào thư mục
		 Download_Procedure_Image_Collection ($sFilePath_Title, $oIE_Procedure)
		 ;------------------------------------------------------------------------------------------------------------------
		 ;ĐOẠN CODE INSERT HÌNH ẢNH CHO PROCEDURE
		 $sTxt_Body = Insert_Images_HTML ($oIE_Procedure, $sTxt_Body)
		 ;------------------------------------------------------------------------------------------------------------------
		 ;ĐOẠN CODE LẤY TEXT TRONG TAG <A> ĐỂ REMOVE TẤT CẢ "SEE:............"
		 Local $oAs = _IETagNameGetCollection($oIE_Procedure, "a")
		 Local $aHyperlink_Innertexts [1000]
		 Local $iCount_Hyperlink = 0
		 Local $sTemp = ""
		 For $oA In $oAs
		  If StringInStr ($oA.innertext, "See:", 0, 1) <> 0 Then
			 $sTemp = Standardize_String ($oA.innertext)
			 $sTxt_Body = StringReplace ($sTxt_Body, $sTemp,"", 1, 0)
		  EndIf
		 Next
		 ;------------------------------------------------------------------------------------------------------------------
		 If $sProcedure_Path <> "" Then
			Local $sHTML_Procedure_Hyperlink = "<a href=""" & $sProcedure_Path & """ target=""_blank"">" & "CONTINUE" & "</a>"
			$sTxt_Body = $sTxt_Body & @CRLF & @CRLF & $sHTML_Procedure_Hyperlink
		 EndIf
		 Create_HTML  ($sFilePath_Title, $sTxt_File_Name,  $sTxt_Title, $sTxt_Body)
		 $sProcedure_Path = "../../PROCEDURE/" & $sTxt_File_Name & "/" & $sTxt_File_Name & ".html"
		 ;------------------------------------------------------------------------------------------------------------------
		 ;ĐOẠN CODE WRITE LOG FILE PROCEDURE
		 Local $sLog_Txt = "File name: " & $sTxt_File_Name & @CRLF & $sTxt_Title_Alldata & @CRLF & _IEPropertyGet ($oIE_Procedure, "locationurl")
		 Write_Log_File ($sFilePath_YMME,"Log File Procedure Successful", @CRLF & @CRLF & @CRLF & $sLog_Txt, "append")
		 _IEQuit($oIE_Procedure)
	  Next
   Else ;Nếu không chứa link procedure
	  $hFileOpen = FileOpen($sFilePath_YMME & "\" & "Log File Procedure Failed" & ".txt", $FO_READ)
	  $sLastline = FileReadLine($hFileOpen, -1)
	  FileClose($hFileOpen)

	  If $sLastline = "" Then
		 Local $sTxt_File_Name = "PROCEDURE_OTHER_1"
	  Else
		 $sTxt_File_Name = StringRight ($sLastline, StringLen ($sLastline)  - StringInStr ($sLastline, "_", 0, -1))
		 $sTxt_File_Name = "PROCEDURE_OTHER_" & (Number ($sTxt_File_Name) + 1)
	  EndIf
	  Local $sProcedure_Path = ""
	  $sProcedure_Path = "../../PROCEDURE/" & $sTxt_File_Name & "/" & $sTxt_File_Name & ".html"
	  ;------------------------------------------------------------------------------------------------------------------
	  ;ĐOẠN CODE WRITE LOG FILE PROCEDURE
	  Local $sLog_Txt = $sInfo & @CRLF & "You must name: " & $sTxt_File_Name
	  Write_Log_File ($sFilePath_YMME, "Log File Procedure Failed", @CRLF & @CRLF & @CRLF & $sLog_Txt, "append")
   EndIf


   ;------------------------------------------------------------------------------------------------------------------
   ;Trả về một string đường dẫn của PROCEDURE
   Return $sProcedure_Path
EndFunc

   $hFileOpen = FileOpen(@ScriptDir & "\Final Values File.txt", $FO_READ)
   $iCount_Year = FileReadLine($hFileOpen, 2)
      FileClose($hFileOpen)

;====================================================================================================================
;                  FUNCTION DISCRIPTION: CREATE OTHER PROCEDURE IN DTC FROM ALLDATA
;				   RETURN              : A STRING OF PROCEDURE PATH
;====================================================================================================================
Func Get_Procedure_Links_In_JAVASCRIPT ($sJavascript)
   Local $aIDs [4]
   Local $sProcedure_Mother_Link
   Local $sTemp = $sJavascript
   $sTemp = StringReplace ($sTemp, "javascript:navigateOnTree","")
   $sTemp = StringReplace ($sTemp, "alldata", "")
   $sTemp = StringReplace ($sTemp, "(", "")
   $sTemp = StringReplace ($sTemp, ")", "")
   $sTemp = StringReplace ($sTemp, "/", "")
   $sTemp = StringReplace ($sTemp, "'", "")
   $sTemp = StringReplace ($sTemp, " ", "")
   $sTemp = StringReplace ($sTemp, ";", "")
   $sTemp = $sTemp & ","
   ;------------------------------------------------------------------------------------------------------------------
   ;ĐOẠN CODE LẤY ID TẠO LINK
   For $i = 1 To 4 Step 1
	  $aIDs [$i-1] =  StringMid ($sTemp, Stringinstr ($sTemp, ",", 0, $i) + 1, Stringinstr ($sTemp, ",", 0, $i + 1) - Stringinstr ($sTemp, ",", 0, $i) - 1)
   Next
   $sProcedure_Mother_Link = "http://repair.alldata.com/alldata/article/display.action?componentId=" & $aIDs [0] & "&iTypeId=" & $aIDs [1] & "&nonStandardId=" & $aIDs [2] & "&vehicleId=" & $aIDs [3] & "&windowName=mainADOnlineWindow"
   Local $oIE = IECreate_Check_Error ($sProcedure_Mother_Link,  $bWeb_Attach, $bWeb_Visible, $bWeb_Wait, $bWeb_TakeFocus)
   $oIE = Check_Subscription_Alldata ($oIE, $sProcedure_Mother_Link, $iSubscription_Num)

   ;------------------------------------------------------------------------------------------------------------------
   ;Check link javascript có chứa link procedure hay không
   Local $sHTML_Innertext = _IEPropertyGet ($oIE, "innertext")

   If (StringInStr ($sHTML_Innertext, "Page not found") = 0 And StringInStr ($sHTML_Innertext, "The page you requested can not be displayed") = 0) _
	  And  (StringInStr ($sHTML_Innertext, "DOCTYPE html PUBLIC") = 0) Then
	  ;------------------------------------------------------------------------------------------------------------------
	  ;ĐOẠN CODE LẤY TEXT VÀ LINK PROCEDURE TRONG MOTHER LINK
	  Local $oAs = _IETagNameGetCollection($oIE, "a")
	  Local $aPart_Innertexts [1000]
	  Local $aPart_Links [1000]
	  Local $iCount_Part = 0
	  Local $bFlag = 0
	  For $oA In $oAs
		 If StringInStr ($oA.innertext, "Terms of Use") <> 0 Then $bFlag = 0
		 If $bFlag = 1 Then
			$aPart_Links [$iCount_Part] = $oA.href
			$iCount_Part = $iCount_Part + 1
		 EndIf
		 If StringInStr ($oA.innertext, "Advanced") <> 0 Then $bFlag = 1
		 Next
	  _IEQuit ($oIE)
   Else
	  Local $aPart_Links [1000]
	  $aPart_Links [0] = "Page not found"
	  _IEQuit ($oIE)
   EndIf
   Return $aPart_Links
EndFunc

