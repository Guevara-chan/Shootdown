﻿REM --Setup util_root for actual path.
chcp 65001
setlocal
set tmp_exe=Shootdøwn.exe
set util_root=C:/Utils

if exist %tmp_exe% ( del %tmp_exe% )
%util_root%/[dot]Net/Boo/bin/booc.exe -embedres:shoot.wav,shoot.wav -embedres:decal.png,decal.png -debug- -i:icon.ico Shootdøwn.boo

if exist %tmp_exe% (
%util_root%/[dot]Net/Extra/ILMerge/ilmerge.exe %tmp_exe% C:/Utils/[dot]Net/Boo/bin/Boo.Lang.dll /t:winexe /ndebug /out:../Shootdøwn.exe
del %tmp_exe%
)