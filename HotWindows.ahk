DetectHiddenWindows,On
#Persistent
#SingleInstance force
#UseHook
#InstallKeybdHook
#Include %A_ScriptDir%\JSON.ahk
GuiArr := Object()
Edition:=201703
RegRead,LastTime,HKEY_LOCAL_MACHINE,SOFTWARE\TestKey,HotEdit
RegWrite,REG_SZ,HKEY_LOCAL_MACHINE,SOFTWARE\TestKey,HotEdit,%Edition%
if LastTime and (LastTime<>Edition)
	TrayTip,升级成功,已从%LastTime%升级到%Edition%
GetJson:=JSON.load(Update())
if (GetJson[1].time>Edition){
	Time:=GetJson[1].time
	Inf:=GetJson[1].inf
	Url:=GetJson[1].URL
	MsgBox,4,版本更新,最新版本：%Time%`n----------------------------------------`n%INF%
	IfMsgBox Yes
		gosub,Downloand
}
Menu,Tray,Add,Hot-Windows,Menu_show
Menu,Tray,Add,开机启动,Auto
Menu,Tray,Add,重启脚本,Reload
Menu,Tray,Add,退出脚本,ExitApp
Menu,Tray,Default,Hot-Windows
Menu,Tray,NoStandard

Gui,+HwndMyGuiHwnd -MaximizeBox
Gui,Add,Text,,热启动
Gui,Add,Edit,vDDL1
Gui,Add,Text,,热激活
Gui,Add,Edit,vDDL2
Gui,Add,Text,,最小化热键
Gui,Add,Hotkey,vWinmin
Gui,Add,Text,,最大化热键
Gui,Add,Hotkey,vWinmax
Gui,Add,Text,,剧中热键
Gui,Add,Hotkey,vWinmove
Gui,Add,Button,gSubmit w135,保存配置
RegRead,HotRun,HKEY_CURRENT_USER,Software\Microsoft\Windows\CurrentVersion\Run,HotRun
IfExist,%HotRun%
{
	RegWrite,REG_SZ,HKEY_CURRENT_USER,Software\Microsoft\Windows\CurrentVersion\Run,HotRun,%A_ScriptFullPath%
	Menu,Tray,ToggleCheck,开机启动
}
;启动做准备
tcmatch := "Tcmatch.dll"
hModule := DllCall("LoadLibrary", "Str", tcmatch, "Ptr")
Arrays:=GetArray()
;注册热键
Gui_Submit("0")
Key:=GuiArr["Key"]
Hot:=GuiArr["Hot"]
Layout=qwertyuiopasdfghjklzxcvbnm
Loop,Parse,Layout
	Hotkey,~%A_LoopField%,Layout
TrayTip,HotWindows,程序已经做好准备`n点击托盘图标设置`n%INF%,1
loop{
	WinGet,WinGet_ID,ID,A
	WinGet,getexe,ProcessName,ahk_id %WinGet_ID%
	WinGet,WinList,List,ahk_exe %getexe%
	loop,%WinList% {
		id:=WinList%A_Index%
		WinGetTitle,Title,ahk_id %id%
		if Title
			Arrays[Title] := id
	}
	WinWaitNotActive,ahk_id %WinGet_ID%
	For k,v in Arrays{
		IfWinNotExist,ahk_id %v%
			Arrays.Delete(k)
		IfWinNotExist,%k%
			Arrays.Delete(k)
}
}
return

Layout:
if GetKeyState(key,"P"){
	if (A_TimeSincePriorHotkey<"200") and (ThisHotkey=A_ThisHotkey){
		StringReplace,ThisHotkey,A_ThisHotkey,~
		RegRead,boss_exe,HKEY_LOCAL_MACHINE,SOFTWARE\TestKey,bossexe%ThisHotkey%
		RegRead,boss_path,HKEY_LOCAL_MACHINE,SOFTWARE\TestKey,bosspath%ThisHotkey%
		DetectHiddenWindows,Off
		if boss_exe
		{
			IfWinActive,ahk_exe %boss_exe%
			{
				WinMinimize
			}else{
				IfWinExist,ahk_exe %boss_exe%
					WinActivate,ahk_exe %boss_exe%
				else
					Run,%boss_path%,,,RunPid
			}
		}else{
			WinGet,boss_exe,ProcessName,A
			WinGet,boss_path,ProcessPath,A
			RegWrite,REG_SZ,HKEY_LOCAL_MACHINE,SOFTWARE\TestKey,bossexe%ThisHotkey%,%boss_exe%
			RegWrite,REG_SZ,HKEY_LOCAL_MACHINE,SOFTWARE\TestKey,bosspath%ThisHotkey%,%boss_path%
			TrayTip,,程序：%boss_exe%`n热键：%A_ThisHotkey%
			WinMinimize A
		}
		DetectHiddenWindows,On
	}
}
if GetKeyState(Hot,"P"){
	StringReplace,ThisHotkey,A_ThisHotkey,~
	Hots = %Hots%%ThisHotkey%
	vars := StrLen(Hots)
	list :=
	marry :=
	if (vars="1"){
		lists := Object()
		loop,9{
			Hotkey,%A_Index%,Table
			Hotkey,%A_Index%,On
		}
		goto,WaitHot
	}
	for k,v in Arrays{
		if (matched := DllCall("Tcmatch\MatchFileW","WStr",Hots,"WStr",k)){
			marry++
			if marry>9
				list=%list%`n%k%
			else
				list=%list%`n%marry%-%k%
			lists[marry]:=v
		}
	}
	if marry{
		list := Trim(list,"`n")
		TrayTip,,%list% ; `n %A_ThisHotkey% `n %hots% `n %vars% `n %marry%
		if (marry="1")
			Activate("1")
	}
}
	ThisHotkey:=A_ThisHotkey
return

WaitHot:
	KeyWait,%Hot%,L
	Activate("1")
return

Table:
	Activate(A_ThisHotkey)
return

WinMinimize:
	WinMinimize A
return

WinMaximize:
	WinMaximize A
return

WinMove:
	D_Width:=(A_ScreenWidth/2)
	D_Height:=(A_ScreenHeight/2)
	WinGetPos,X,Y,Width,Height,A
	WinMove,A,,A_ScreenWidth/8,A_ScreenHeight/8,(A_ScreenWidth/8)*6,(A_ScreenHeight/8)*6
return

Auto:
	IfExist,%HotRun%
		RegDelete,HKEY_CURRENT_USER,Software\Microsoft\Windows\CurrentVersion\Run,HotRun
	else
		RegWrite,REG_SZ,HKEY_CURRENT_USER,Software\Microsoft\Windows\CurrentVersion\Run,HotRun,%A_ScriptFullPath%
	Menu,Tray,ToggleCheck,开机启动
return

Reload:
	Reload
ExitApp:
	ExitApp

Submit:
if (DDL1=DDL2)
	TrayTip,HotWindows,热启动与热激活热键不可相同,,3
else
	Gui_Submit("1")
return

Menu_show:
DetectHiddenWindows,Off
IfWinNotExist,ahk_id %MyGuiHwnd%
	Gui,Show
else
	Gui,Cancel
DetectHiddenWindows,On
return

Downloand:
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
	SplitPath, URL, FN,,,, DN
	FN:=(FN ? FN : DN)
	SAVE=%A_ScriptDir%\HotWindows-master.zip
	DllCall("QueryPerformanceCounter", "Int64*", T1)
	WP1=0
	T2=0
	WP2=0
	if ((E:=InternetFileRead( binData, URL, False, 1024)) > 0 && !ErrorLevel)
	{
		VarZ_Save(binData, SAVE)
		GuiControl, Text, Label1, 下载完成。
		Sleep, 500
		D_history=%A_ScriptDir%\history\%Edition%
		FileCreateDir,%D_history%
		SmartZip(SAVE,D_history)
		FileDelete,%SAVE%
		gosub,ExitSub
		ExitApp
	}else{
		ERR := (E<0) ? "下载失败，错误代码为" . E : "下载过程中出错，未能完成下载。"
		GuiControl, Text, Label1, %ERR%
		Sleep, 500
		Gui,Destroy
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
	xcopy %D_history%\HotWindows-master %A_ScriptDir% /s/e/y
	start %A_ScriptFullPath%
	del `%0
	)
	batfilename=Delete.bat
	IfExist %batfilename%
		FileDelete %batfilename%
	FileAppend, %bat%, %batfilename%
	Run,%batfilename% , , Hide
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

Update(){
	static req := ComObjCreate("Msxml2.XMLHTTP")
	req.open("GET","http://autoahk.com/hotwindows.php",false)
	req.Send()
	return req.responseText
}

Gui_Submit(Access){
	Gui,Submit,NoHide
	IniRead,IniList,ini.ini
	global GuiArr
	Loop,Parse,IniList,`n
	{
		IniRead,Gui_Key,ini.ini,%A_LoopField%,Key
		IniRead,Gui_Way,ini.ini,%A_LoopField%,Way,%A_Space%
		IniRead,Gui_Label,ini.ini,%A_LoopField%,Label
		if Access
		{	;写入设置到INI 保存 保存设置时执行
			if (Gui_Way="Hotkey")
				Hotkey,%Gui_Key%,Off
			GuiControlGet,Gui_Key,,%A_LoopField%
			if (Gui_Way="Hotkey"){
				Hotkey,%Gui_Key%,%Gui_Label%
				Hotkey,%Gui_Key%,On
			}
			IniWrite,%Gui_Key%,ini.ini,%A_LoopField%,Key
		}else{ ;读取设置到GUI 设置 只在脚本开始时执行
			if (Gui_Way="Hotkey"){
				Hotkey,%Gui_Key%,%Gui_Label%
				Hotkey,%Gui_Key%,On
			}
			if (Gui_Way="var"){
				IniRead,Gui_var,ini.ini,%A_LoopField%,var
				GuiArr[Gui_var]:=Gui_Key
			}
			GuiControl,,%A_LoopField%,%Gui_Key%
		}
	}
	return
}

Activate(Ranking){
	global lists
	global Hots
	global Arrays
	Activate:=lists[Ranking]
	WinActivate,ahk_id %Activate%
	loop,9
		Hotkey,%A_Index%,off
	For k,v in Arrays{
		IfWinNotExist,ahk_id %v%
			Arrays.Delete(k)
		IfWinNotExist,%k%
			Arrays.Delete(k)
	}
	Hots:=
	TrayTip
	return
}

GetArray(){
	Array := Object()
	d := "`n"
	s := 4096  ; 缓存和数组的大小 (4 KB)
	Process, Exist
	h := DllCall("OpenProcess", "UInt", 0x0400, "Int", false, "UInt", ErrorLevel, "Ptr")
	DllCall("Advapi32.dll\OpenProcessToken", "Ptr", h, "UInt", 32, "PtrP", t)
	VarSetCapacity(ti, 16, 0)
	NumPut(1, ti, 0, "UInt")
	DllCall("Advapi32.dll\LookupPrivilegeValue", "Ptr", 0, "Str", "SeDebugPrivilege", "Int64P", luid)
	NumPut(luid, ti, 4, "Int64")
	NumPut(2, ti, 12, "UInt")
	r := DllCall("Advapi32.dll\AdjustTokenPrivileges", "Ptr", t, "Int", false, "Ptr", &ti, "UInt", 0, "Ptr", 0, "Ptr", 0)
	DllCall("CloseHandle", "Ptr", t)
	DllCall("CloseHandle", "Ptr", h)
	hModule := DllCall("LoadLibrary", "Str", "Psapi.dll")  ; 通过预加载来提升性能
	s := VarSetCapacity(a, s)
	c := 0
	DllCall("Psapi.dll\EnumProcesses", "Ptr", &a, "UInt", s, "UIntP", r)
	loop, % r // 4
	{
		id := NumGet(a, A_Index * 4, "UInt")
		h := DllCall("OpenProcess", "UInt", 0x0010 | 0x0400, "Int", false, "UInt", id, "Ptr")
		if !h
			continue
		VarSetCapacity(n, s, 0)
		e := DllCall("Psapi.dll\GetModuleBaseName", "Ptr", h, "Ptr", 0, "Str", n, "UInt", A_IsUnicode ? s//2 : s)
		if !e
			if e := DllCall("Psapi.dll\GetProcessImageFileName", "Ptr", h, "Str", n, "UInt", A_IsUnicode ? s//2 : s)
				SplitPath n, n
		DllCall("CloseHandle", "Ptr", h)  ; 关闭进程句柄以节约内存
		if (n && e)  ; 如果映像不是空的, 则添加到列表:
		{
			l .= n . d, c++
		}
	}
	DllCall("FreeLibrary", "Ptr", hModule)  ; 卸载库来释放内存
	Sort,l,U
	even:=100/(c-ErrorLevel)
	evens:=0
	loop, Parse,l,`n
	{
		WinGet,WinList,List,ahk_exe %A_LoopField%
		loop,%WinList% {
			id:=WinList%A_Index%
			WinGetTitle,Title,ahk_id %id%
			if Title
				Array[Title] := id
		}
		evens:=evens+even
		event:=Ceil(evens)
		TrayTip,程序正在准备,%event%,,2
	}
	return Array
}
