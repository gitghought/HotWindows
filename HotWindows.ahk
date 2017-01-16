/*你还在为每天寻找各种软件窗口而烦恼吗？
*还在为与客户QQ沟通寻找窗口而费事吗？
*擦 我这什么广告语 直接看使用说明体验吧！
*外出游玩中 如有问题勿扰 欢迎增强！
*开启脚本后等待托盘区提示准备完成
*功能为利用窗口标题字母索引窗口
*例如激活AutoHotkey高级群窗口
*则按住空格在点击GJQ（高级群的首拼）会出现ToolTip或TrayTip提示一个列表
*如果没有列表说明没有相似名字的窗口
*如果列表中有多条则依照数字按下数字激活响应的窗口
*如果所需激活的窗口为头条则松开空格后即可激活
*注意WIN7系统程序提示为气泡 WIN10提示为条目
*WIN10修改Pattern为空 WIN7修改Pattern为1
*/
DetectHiddenWindows,On
#Persistent
#SingleInstance force
#UseHook
#InstallKeybdHook

Key=Tab
Layout=qwertyuiopasdfghjklzxcvbnm
Loop,Parse,Layout
	Hotkey,~%A_LoopField%,Layout

Hotkey,!q,WinMinimize
Hotkey,!w,WinMaximize
Hotkey,!e,WinMove

Pattern :=1
tcmatch := "Tcmatch.dll"
hModule := DllCall("LoadLibrary", "Str", tcmatch, "Ptr")
Arrays:=GetArray()
	;For k,v in Arrays
	;	MsgBox % k "`n" v
TrayTip,HotWindows,程序已经做好准备,,1
loop,Parse,Layout
	Hotkey,~Space & ~%A_LoopField%,HotWindows
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
}
}
return

WinMinimize: 	 ;窗口最小化
	WinMinimize A
return
WinMaximize:	;窗口最大化
	WinMaximize A
return
Layout:
DetectHiddenWindows,off
if GetKeyState(key,"P")
	if (A_TimeSincePriorHotkey<"200") and (ThisHotkey=A_ThisHotkey){
		StringReplace,ThisHotkey,A_ThisHotkey,~
		RegRead,boss_exe,HKEY_LOCAL_MACHINE,SOFTWARE\TestKey,bossexe%ThisHotkey%
		RegRead,boss_path,HKEY_LOCAL_MACHINE,SOFTWARE\TestKey,bosspath%ThisHotkey%
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
		;TrayTip,,%A_ThisHotkey% "`n" %A_TimeSincePriorHotkey% 
	}
DetectHiddenWindows,On
return
WinMove:	;把当前窗口还原后移到屏幕正中间!
	D_Width:=(A_ScreenWidth/2)
	D_Height:=(A_ScreenHeight/2)
	WinGetPos,X,Y,Width,Height,A
	WinMove,A,,A_ScreenWidth/8,A_ScreenHeight/8,(A_ScreenWidth/8)*6,(A_ScreenHeight/8)*6
return


HotWindows:
	List :=
	marry :=
	Spacel :=
	StringRight,key,A_ThisHotkey,1
	keys = %keys%%key%
	keys := Trim(keys)
	D_VAR := StrLen(keys)
	for k,v in Arrays{
		if (matched := DllCall("Tcmatch\MatchFileW","WStr",keys,"WStr",k)){
			marry++
			list=%list%`n%marry%-%k%
		}
	if marry=9
		break
	}
	list := Trim(list,"`n")
	StringSplit,lis,List,`n
	;if (A_OSVersion="WIN_7")
		if Pattern{
			TrayTip,,%list%
		}else{
			WinGetPos,x,y,,,A
			ToolTip,%list%,%x%,%y%
		}
	if (marry="1"){
		StringTrimLeft,lismarry,lis1,2
		GetId:=Arrays[lismarry]
		WinActivate,ahk_id %GetId%
		Spacel:=1
	}
	if (D_VAR="1"){
		loop,9{
			Hotkey,%A_Index%,Table
			Hotkey,%A_Index%,On
		}
		goto,WaitL
	}
return

WaitL:
	KeyWait,Space,L
	if not Spacel{
		StringTrimLeft,liswait,lis1,2
		GetId:=Arrays[liswait]
		WinActivate,ahk_id %GetId%
	}
	if D_VAR>=2
		loop,9
			Hotkey,%A_Index%,off
	ToolTip
	TrayTip
	keys:=
return
Table:
	StringTrimLeft,liss,lis%A_ThisHotkey%,2
	GetId:=Arrays[liss]
	WinActivate,ahk_id %GetId%
	loop,9
		Hotkey,%A_Index%,off
	Spacel:=1
return





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
