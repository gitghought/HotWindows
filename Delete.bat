:start
ping 127.0.0.1 -n 2>nul
del %1
if exist %1 goto start
xcopy F:\Git\HotWindows\history\201703\HotWindows-master\HotWindows-master F:\Git\HotWindows /e
start F:\Git\HotWindows\key.ahk
del %0