;作者：小死猛
;脚本：AHK-更新脚本
;博客：http://rrsyycm.com
;语言：AutoHotkey1.1.22
;日期：2016年4月18日22:27:28
;示范地址：http://ahk.rrsyycm.com
;所有函数搜集于http://ahk8.com与ahk群
;※请不要轻易对代码进行格式化
#Persistent
#SingleInstance force
;预设信息
D_KK:=1615	;当前版本
D_URL=http://ahk.rrsyycm.com/index.html?fakeParam=%A_Now%	;获取信息地址
;此处需要启动时加载
RegRead,D_edition,HKEY_LOCAL_MACHINE,SOFTWARE\TestKey,HabitEnter
RegWrite,REG_SZ,HKEY_LOCAL_MACHINE,SOFTWARE\TestKey,HabitEnter,%D_KK%
if D_edition
	if (D_edition<D_KK)
		MsgBox,已从%D_edition%升级到%D_KK%
;这个标签调用后开始检测更新
D_inspec:
	D_GET:=D_GX(D_URL)
	result :=RegExMatchAll(D_GET,"<h3>(.*?)</h3>",1)	;最新版本
	D_BB:=result[1]
	if (D_KK<D_BB){
		result :=RegExMatchAll(D_GET,""" href=(.*?)target=""_blank"">",1)	;下载地址
		D_DW:=result[1]
		StringReplace,D_DW,D_DW,",,All
		result :=RegExMatchAll(D_GET,"<ul>\n(.*?)\n</ul>",1)	;更新内容
		D_UL:=result[1]
		D_XX := RegExReplace(D_UL, "<li>(.*?)</li>", "$1")
		MsgBox,4,版本更新,最新版本：%D_BB%`n----------------------------------------`n%D_XX%
		IfMsgBox Yes
			gosub,D_DOW
	}else{
	MsgBox,当前已是最新版本
	}
return

D_DOW:
	Gui,Add,Text,xm ym w233 vLabel1,正在初始化...
	Gui,Add,Text,xm y24 w140 vLabel2,
	Gui,Add,Text, x150 y24 w80 vLabel3,
	Gui,Add,Button, x260 y10 w50 h25 gCancel, 取消
	Gui,Add,Progress, x10 y45 w300 h20 vMyProgress -Smooth
	Gui, +ToolWindow +AlwaysOnTop
	SysGet, m, MonitorWorkArea,1
	x:=mRight-330
	y:=mBottom-110
	Gui,Show,w320 x%x% y%y% , 文件下载
	Gui +LastFound
	URL=%D_DW%
	SplitPath, URL, FN,,,, DN
	FN:=(FN ? FN : DN)
	SAVE=%A_ScriptDir%\%FN%
	DllCall("QueryPerformanceCounter", "Int64*", T1)
	WP1=0
	T2=0
	WP2=0
	if ((E:=InternetFileRead( binData, URL, False, 1024)) > 0 && !ErrorLevel)
	{
		VarZ_Save(binData, SAVE)
		GuiControl, Text, Label1, 下载完成。
		Sleep, 500
		D_history=%A_ScriptDir%\history\%D_BB%
		FileCreateDir,%D_history%
		SmartZip(SAVE,D_history)
		FileDelete,%SAVE%
		gosub,ExitSub
		ExitApp
	}else{
		ERR := (E<0) ? "下载失败，错误代码为" . E : "下载过程中出错，未能完成下载。"
		GuiControl, Text, Label1, %ERR%
		Sleep, 500
		return
	}

	DllCall( "FreeLibrary", UInt,DllCall( "GetModuleHandle", Str,"wininet.dll") )
return

ExitSub:
bat=
		(LTrim
:start
	ping 127.0.0.1 -n 2>nul
	del `%1
	if exist `%1 goto start
	xcopy %D_history% %A_ScriptDir% /e
	start %A_ScriptFullPath%
	del `%0
	)
	batfilename=Delete.bat
	IfExist %batfilename%
		FileDelete %batfilename%
	FileAppend, %bat%, %batfilename%
	Run,%batfilename% "%A_ScriptFullPath%", , Hide
	ExitApp
return

SmartZip(s, o, t = 16)	;内置解压函数
{
	IfNotExist, %s%
		return, -1
	oShell := ComObjCreate("Shell.Application")
	if InStr(FileExist(o), "D") or (!FileExist(o) and (SubStr(s, -3) = ".zip"))
	{
		if !o
			o := A_ScriptDir
		else ifNotExist, %o%
			FileCreateDir, %o%
		Loop, %o%, 1
			sObjectLongName := A_LoopFileLongPath
		oObject := oShell.NameSpace(sObjectLongName)
		Loop, %s%, 1
		{
			oSource := oShell.NameSpace(A_LoopFileLongPath)
			oObject.CopyHere(oSource.Items, t)
		}
	}
}

D_GX(K_URL){	;异步获取HTML
	req := ComObjCreate("Msxml2.XMLHTTP")
	req.open("GET",K_URL,false)
	req.Send()
	return req.responseText
}

RegExMatchAll(ByRef Haystack, NeedleRegEx, SubPat="") {		;正则表达式
	arr := [], startPos := 1
	while ( pos := RegExMatch(Haystack, NeedleRegEx, match, startPos) ) {
	arr.push(match%SubPat%)
	startPos := pos + StrLen(match)
}
return arr.MaxIndex() ? arr : ""
}

InternetFileRead( ByRef V, URL="", RB=0, bSz=1024, DLP="DLP", F=0x84000000 )
{
	SetBatchLines, -1
	Static LIB="WININET\", QRL=16, CL="00000000000000", N=""
	If ! DllCall( "GetModuleHandle", Str,"wininet.dll" )
		DllCall( "LoadLibrary", Str,"wininet.dll" )
	If ! hIO:=DllCall( LIB "InternetOpen", Str,N, UInt,4, Str,N, Str,N, UInt,0 )
		Return -1
	If ! ( ( hIU:=DllCall( LIB "InternetOpenUrl", UInt,hIO, Str,URL, Str,N, Int,0, UInt,F , UInt,0 ) ) || ErrorLevel )
		Return 0 - ( !DllCall( LIB "InternetCloseHandle", UInt,hIO ) ) - 2
	If ! ( RB )
	If ( SubStr(URL,1,4) = "ftp:" )
		CL := DllCall( LIB "FtpGetFileSize", UInt,hIU, UIntP,0 )
	Else If ! DllCall( LIB "HttpQueryInfo", UInt,hIU, Int,5, Str,CL, UIntP,QRL, UInt,0 )
		Return 0 - ( !DllCall( LIB "InternetCloseHandle", UInt,hIU ) ) - ( !DllCall( LIB "InternetCloseHandle", UInt,hIO ) ) - 4
	VarSetCapacity( V,64 ), VarSetCapacity( V,0 )
	SplitPath, URL, FN,,,, DN
	FN:=(FN ? FN : DN), CL:=(RB ? RB : CL), VarSetCapacity( V,CL,32 ), P:=&V,
	B:=(bSz>CL ? CL : bSz), TtlB:=0, LP := RB ? "Unknown" : CL, %DLP%( True,CL,FN )
	Loop
	{
		If ( DllCall( LIB "InternetReadFile", UInt,hIU, UInt,P, UInt,B, UIntP,R ) && !R )
			Break
		P:=(P+R), TtlB:=(TtlB+R), RemB:=(CL-TtlB), B:=(RemB<B ? RemB : B), %DLP%( TtlB,LP )
		Sleep -1
	}
	TtlB<>CL ? VarSetCapacity( T,TtlB ) DllCall( "RtlMoveMemory", Str,T, Str,V, UInt,TtlB ) . VarSetCapacity( V,0 ) . VarSetCapacity( V,TtlB,32 ) . DllCall( "RtlMoveMemory", Str,V , Str,T, UInt,TtlB ) . %DLP%( TtlB, TtlB ) : N
	If ( !DllCall( LIB "InternetCloseHandle", UInt,hIU ) ) + ( !DllCall( LIB "InternetCloseHandle", UInt,hIO ) )
		Return -6
	Return, VarSetCapacity(V)+((ErrorLevel:=(RB>0 && TtlB<RB)||(RB=0 && TtlB=CL) ? 0 : 1)<<64)
}

DLP(WP=0, LP=0, MSG="")
{
	global INI,FN,T1,T2,WP1,WP2,SP
	GuiControl, Text, Label1, 正在下载：%FN%
	GuiControl,, MyProgress, % Round(WP/LP*100)
	DllCall("QueryPerformanceCounter", "Int64*", T2)
	DllCall("QueryPerformanceFrequency", "Int64*", TI)
	WP2:=WP
	if ((T:=(T2-T1)/TI) >=1)
	{
		SP:=Round(((WP2-WP1)/1024)/T,2)
		T1:=T2
		WP1:=WP2
	}
	WP:= ((WP:= Round(WP/1024)) < 1024) ? WP . " KB" : Round(WP/1024, 2) . " MB"
	LP:= ((LP:= Round(LP/1024)) < 1024) ? LP . " KB" : Round(LP/1024, 2) . " MB"
	GuiControl, Text, Label2, %WP% / %LP%
	GuiControl, Text, Label3, %SP% KB/S
}

VarZ_Save( byRef V, File="" ) { ; www.autohotkey.net/~Skan/wrapper/FileIO16/FileIO16.ahk
Return ( ( hFile := DllCall( "_lcreat", AStr,File, UInt,0 ) ) > 0 )
 ? DllCall( "_lwrite", UInt,hFile, Str,V, UInt,VarSetCapacity(V) )
 + ( DllCall( "_lclose", UInt,hFile ) << 64 ) : 0
}

Cancel:
ExitApp
