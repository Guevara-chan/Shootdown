REM --Setup util_root for actual path.
chcp 65001
setlocal
set tmp_exe=Θuroboros.exe
set util_root=C:/Utils

if exist %tmp_exe% ( del %tmp_exe% )
%util_root%/[dot]Net/Boo/bin/booc.exe -debug- Θuroboros.boo

if exist %tmp_exe% (
%util_root%/Misc/ResHacker/ResourceHacker.exe -open %tmp_exe% -save %tmp_exe% -action addoverwrite -resource icon.ico -mask ICONGROUP, MAINICON, 0
%util_root%/[dot]Net/Extra/ILMerge/ilmerge.exe %tmp_exe% C:/Utils/[dot]Net/Boo/bin/Boo.Lang.dll /t:winexe /ndebug /out:../「Θuroboros」.exe
del %tmp_exe%
)