# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# Shootdøwn windows destroyer v0.047
# Developed in 2017 by Guevara-chan.
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import System
import System.IO
import System.Text
import System.Linq
import System.Media
import System.Drawing
import System.Diagnostics
import System.Windows.Forms
import System.Collections.Generic
import System.Collections.Specialized
import System.Runtime.InteropServices
import System.Runtime.CompilerServices
import Microsoft.VisualBasic from Microsoft.VisualBasic

#.{ [Classes]
abstract class API():
	# --Auxilary definitions.
	[Flags] enum KeyModifier:
		None	= 0
		Alt		= 1
		Control	= 2
		Shift	= 4
		WinKey	= 8

	[Flags] enum ProcessAccess:
		All						= 0x001F0FFF
		Terminate				= 0x00000001
		CreateThread			= 0x00000002
		VirtualMemoryOperation	= 0x00000008
		VirtualMemoryRead		= 0x00000010
		VirtualMemoryWrite		= 0x00000020
		DuplicateHandle			= 0x00000040
		CreateProcess			= 0x000000080
		SetQuota				= 0x00000100
		SetInformation			= 0x00000200
		QueryInformation		= 0x00000400
		QueryLimitedInformation	= 0x00001000
		Synchronize				= 0x00100000

	enum GWL:
     	WndProc		= -4
     	hInstance	= -6
     	hWndParent	= -8
     	Style		= -16
     	ExStyle		= -20
     	UserData	= -21
     	ID			= -12

	[StructLayout(LayoutKind.Sequential)] public struct POINT:
		public X as int
		public Y as int
		def constructor(point as Point):
			X, Y = point.X, point.Y

	public callable EnumWindowsProc(hWnd as IntPtr, lParam as IntPtr) as bool

	# --Import table goes here:
	[DllImport("user32.dll")]
	[Extension]	static def RegisterHotKey(hWnd as IntPtr, id as int, fsModifiers as int, vk as Keys) as bool:
		pass
	[DllImport("user32.dll")]
	[Extension] static def GetKeyState(vk as Keys) as short:
		pass
	[DllImport("user32.dll")]
	[Extension]	static def GetWindowThreadProcessId(hWnd as IntPtr, ref ProcessId as IntPtr) as IntPtr:
		pass
	[DllImport("user32.dll")]
	[Extension]	static def WindowFromPoint(Point as POINT) as IntPtr:
		pass
	[DllImport("user32.dll")]
	[Extension]	static def EnumWindows(enumProc as EnumWindowsProc, lParam as IntPtr) as bool:
		pass
	[DllImport("user32.dll")]
	[Extension]	static def IsWindowVisible(hWnd as IntPtr) as bool:
		pass
	[DllImport("user32.dll", CharSet: CharSet.Unicode)]
	[Extension]	static def GetWindowText(hWnd as IntPtr, lpString as StringBuilder, nMaxCount as int) as int:
		pass
	[DllImport("user32.dll")]
	[Extension]	static def GetWindowLong(hWnd as IntPtr, nIndex as GWL) as int:
		pass
	[DllImport("user32.dll")]
	[Extension]	static def SetWindowLong(hWnd as IntPtr, nIndex as GWL, dwNewLong as int) as int:
		pass
	[DllImport("user32.dll")]
	[Extension]	static def SetLayeredWindowAttributes(hWnd as IntPtr, crKey as int, alpha as byte, 
		dwFlags as int) as bool:
		pass
	[DllImport("kernel32.dll")]
	[Extension]	static def OpenProcess(Access as ProcessAccess, bInheritHnd as bool, Id as IntPtr) as IntPtr:
		pass
	[DllImport("kernel32.dll")]
	[Extension]	static def CloseHandle(hObject as IntPtr) as bool:
		pass
	[DllImport("kernel32.dll", CharSet: CharSet.Unicode)]
	[Extension]	static def QueryFullProcessImageName(hProc as IntPtr, dwFlags as int, lpName as StringBuilder,
		ref lpdwSize as int) as bool:
		pass
	[DllImport("psapi.dll", CharSet: CharSet.Unicode)]
	[Extension]	static def GetModuleFileNameEx(hProc as IntPtr, hMod as IntPtr, lpName as StringBuilder, 
		nSize as int) as uint:
		pass
	[DllImport("psapi.dll")]
	[Extension]	static def EnumProcesses([MarshalAs(UnmanagedType.LPArray, ArraySubType: UnmanagedType.U4)]\
		processIds as (uint), arraySizeBytes as uint, ref bytesCopied as uint) as bool:
		pass
# -------------------- #
abstract class Δ(API):
	static final name					= "Shootdøwn"
	static final postXP					= Environment.OSVersion.Version.Major >= 6
	public static final win_title		= "💀|$name|💀"
	public static final assembly_icon	= Icon.ExtractAssociatedIcon(Application.ExecutablePath)
	public static final assembly		= Reflection.Assembly.GetExecutingAssembly()
	public static final nil				= IntPtr.Zero

	# --Methods goes here.
	[Extension] static def either[of T](val as bool, false_val as T, true_val as T):
		if val: return true_val
		else: return false_val

	[Extension] static def either[of T](val as string, false_val as T, true_val as T):
		return either(val != '', false_val, true_val)
	
	[Extension] static def msgbox(text as string, icon as MessageBoxIcon, buttons as MessageBoxButtons):
		return MessageBox.Show(text, win_title, buttons, icon)

	[Extension] static def msgbox(text as string, icon as MessageBoxIcon):
		return text.msgbox(icon, MessageBoxButtons.OK)

	[Extension] static def errorbox(text as string):
		return text.msgbox(MessageBoxIcon.Error)

	[Extension] static def errorbox(ex as Exception, rem as string):
		return "$(ex.ToString().Split(char('\n'))[0])\n$rem".errorbox()

	[Extension] static def errorbox(ex as Exception):
		return ex.errorbox("")

	[Extension] static def askbox(text as string):
		return text.msgbox(MessageBoxIcon.Question, MessageBoxButtons.YesNo) ==	DialogResult.Yes

	[Extension] static def request[of T](text as string, default as T) as T:
		while true:
			if result = Interaction.InputBox(text, win_title, default.ToString(), -1, -1):
				try: return Convert.ChangeType(result, T)
				except ex: "Invalid input proveded !".errorbox()
			else: return default

	[Extension] static def try_lock(lock_name as string):
		unique as bool
		mutex = Threading.Mutex(true, lock_name, unique)
		return mutex if unique

	[Extension] static def find_res(id as string) as Stream:
		if assembly.IsDynamic: return File.OpenRead(id)
		else: return assembly.GetManifestResourceStream(id)

	[Extension] static def cycle(dict as OrderedDictionary, max as int):
		while dict.Count > max: dict.RemoveAt(0)
		return dict

	[Extension] static def upcount(dict as OrderedDictionary, key as string):
		if dict.Contains(key): dict[key] = dict[key] cast int + 1
		else: dict.Add(key, 1)
		return dict

	[Extension] static def pressed(key as Keys):
		return (key.GetKeyState() & 0x10000000)

	[Extension] static def bind(proc as callable, arg):
		return {proc(arg)}

	[Extension] static def bind(proc as callable, arg, arg2):
		return {proc(arg, arg2)}

	# -- Additional service class.
	class WM_Receiver(Form):
		event WM as callable(Message)
		protected def SetVisibleCore(value as bool):
			super.SetVisibleCore(false)
		protected def WndProc(ref msg as Message):
			WM(msg)
			super.WndProc(msg)
# -------------------- #
class ProcInfo(Δ):
	public final exe as string
	public final pid as IntPtr
	public final taken = DateTime.Now

	def constructor(proc_id as IntPtr):
		pid	= proc_id
		exe	= pid.locate()

	def constructor(proc_path as string):
		exe	= proc_path

	def visit():
		print exe
		Process.Start("explorer", "/select,\"$exe\"")
		return self

	def purge():
		try:
			File.SetAttributes(exe, FileAttributes.Normal)
			File.Delete(exe)
		except ex: ex.errorbox()
		return self

	def reraise():
		Process.Start(ProcessStartInfo(FileName: exe, WorkingDirectory: Path.GetDirectoryName(exe)))
		return self

	[Extension] static def locate(proc_handle as IntPtr):
		proc_handle	= ProcessAccess.QueryLimitedInformation.OpenProcess(true, proc_handle)
		result		= StringBuilder(max = 4096)
		if postXP:	proc_handle.QueryFullProcessImageName(0, result, max)
		else:		proc_handle.GetModuleFileNameEx(nil, result, max)
		proc_handle.CloseHandle()
		return result.ToString()

	[Extension]	static def from_win(win_handle as IntPtr):
		pid as IntPtr
		win_handle.GetWindowThreadProcessId(pid)
		return ProcInfo(pid)

	def destroy():
		Process.GetProcessById(pid cast int).Kill()
		return self

	static all_pids:
		get:
			copied as uint, Δ as int = 0, sizeof(uint)
			pids = array(uint, max = 1024)
			pids.EnumProcesses(max * Δ, copied)
			return pids[:copied/Δ]

	static all:
		get: return all_pids.Select({x|ProcInfo(IntPtr(x))})
# -------------------- #
class WinInfo(Δ):
	public final id		as IntPtr
	public final owner	as ProcInfo
	public final taken	= DateTime.Now

	def constructor(win_handle as IntPtr):
		id		= win_handle
		owner 	= ProcInfo.from_win(id)

	[Extension] static def identify(win_handle as IntPtr):
		result	= StringBuilder(max = 256)
		max		= win_handle.GetWindowText(result, max)
		return result.ToString()

	title:
		get: return id.identify()
# -------------------- #
class InspectorWin(Form):
	final host as Shooter
	final info = Collections.Generic.Dictionary[of string, Label]()
	final flow = FlowLayoutPanel(FlowDirection: FlowDirection.TopDown, AutoSize: true, Size: Size(0, 0),
			Margin: Padding(0, 0, 0, 0))

	def constructor(base as Shooter):
		# Primary setup operations.
		host									= base
		TopMost, ShowInTaskbar, AutoSizeMode	= true, false,  AutoSizeMode.GrowAndShrink
		ControlBox, Text, FormBorderStyle		= false, "", FormBorderStyle.FixedSingle
		Size, AutoSize, BackColor				= Size(0, 0), true, Color.FromArgb(30, 30, 30)
		# Controls setup.
		Controls.Add(flow)
		for label, id in (("●「proc」:", "path"), ("●「win」:", "win"),  ("●「pid」:", "pid")):
			flow.Controls.Add(line = FlowLayoutPanel(FlowDirection: FlowDirection.LeftToRight, AutoSize: true,
				Margin: Padding(0, 0, 0, 0)))
			line.Controls.Add(Label(Text: label, ForeColor: Color.Cyan, AutoSize: true))
			info[id] = Label(ForeColor: Color.Coral, AutoSize: true, Size: Size(0, 0), 
				Margin: Padding(0, 0, 0, 0))
			line.Controls.Add(info[id])
		# Additional aligning.
		align = info.Values.Select({x|x.Location.X}).Max()
		info.Values.ToList().ForEach({x|x.Margin = Padding(align - x.Location.X, 0, 0, 0)})
		# API styling setup.
		style = API.GetWindowLong(Handle, API.GWL.ExStyle) | 0x80000 | 0x20
		API.SetWindowLong(Handle, API.GWL.ExStyle, style)
		API.SetLayeredWindowAttributes(Handle, 0, 245, 0x2)

	def update() as InspectorWin:
		Location			= Cursor.Position
		pinfo				= host.info(0)
		info['path'].Text	= pinfo.exe
		info['win'].Text	= host.target.id.ToString()
		info['pid'].Text	= pinfo.pid.ToString()
		flow.Location		= Point((Height - flow.Height) / 2 + 1, (Width - flow.Width) / 2 + 1)
		return self

	checkout:
		get: return join(info.Values.Select({x|x.Text}), '\n')
# -------------------- #
class Shooter(Δ):
	public max_necro	= 10
	public muffled		= false
	public inspect_on	= assembly.IsDynamic
	final my			= Process.GetCurrentProcess().Handle.info()
	final icon			= NotifyIcon(Visible: true, Icon: assembly_icon, ContextMenu: ContextMenu())
	final ak_timer		= Timer(Enabled: true, Interval: 1000, Tick: {shootdøwn(lookup_doomed())})
	final upd_timer		= Timer(Enabled: true, Interval: 100, Tick: {update})
	final msg_handler	= WM_Receiver(WM: {e as Message|shootdøwn() if e.Msg == 0x0312})
	final bang			= SoundPlayer("shoot.wav".find_res())
	final necrologue	= OrderedDictionary(max_necro)
	final analyzer		= InspectorWin(self)
	final autokill		= {"path": HashSet of string(), "title": HashSet of string()}
	public final locker	= "!$name!".try_lock()
	struct stat():
		static startup	= DateTime.Now
		static victims	= 0
		static errors	= 0

	# --Methods goes here.
	def constructor():
		return unless locker or destroy()
		icon.MouseDown += {setup_menu}
		msg_handler.Handle.RegisterHotKey(0, KeyModifier.Alt | KeyModifier.Shift, Keys.F4)
		update()

	def update() as Shooter:
		icon.Text = "$name 「💀: $(stat.victims)」"
		if inspect_on and Keys.RMenu.pressed() and Keys.ShiftKey.pressed():
			analyzer.update().Show()
			Clipboard.SetText(analyzer.checkout) if Keys.Insert.GetKeyState() & 1
		else: analyzer.Hide()
		return self

	private def setup_menu():
		# -Auxilary procedures.
		def grep_targets():
			cache = List of MenuItem()
			for win in look_around():
				owner = Path.GetFileNameWithoutExtension(win.owner.exe)
				cache.Add(MenuItem("$owner:: " + win.title.either('<nil_title>', win.title), {shootdøwn(win)}))
			return cache.GroupBy({x|x.Text}).Select({y|y.First()}).ToArray()
		def grep_necro():
			index		= 0
			cache	= List of MenuItem()
			for mortem as Collections.DictionaryEntry in necrologue:
				kill_count as int, info as ProcInfo = mortem.Value, ProcInfo(mortem.Key as string)
				cache.Add(tomb = MenuItem((kill_count > 1).either("", "「💀: $(kill_count)」 ") + info.exe))
				tomb.MenuItems.Add("Visit",		{x as ProcInfo|x.visit()}.bind(info))
				tomb.MenuItems.Add("Purge",		{x as ProcInfo,i as int|necrologue.RemoveAt(i+x.purge().pid cast int)
					if "Are you sure want to delete '$(x.exe)' ?".askbox()}.bind(info, index))
				tomb.MenuItems.Add("Reraise",	{x as ProcInfo|x.reraise()}.bind(info))
				index++
			return cache.ToArray()
		# -Main code.
		items = icon.ContextMenu.MenuItems
		items.Clear()
		# Settings and info.
		items.Add("About...", {join((
			"$name v0.047", "*" * 19,
			"Uptime:: $((DateTime.Now - stat.startup).ToString('d\\ \\d\\a\\y\\(\\s\\)\\ \\~\\ h\\:mm\\:ss'))",
			"Processess destroyed:: $(stat.victims)", "Termination errors:: $(stat.errors)"), '\n')\
			.msgbox(MessageBoxIcon.Information)})
		items.Add("Muffle sounds",				{muffled=(not muffled)}).Checked = muffled
		items.Add("Inspect on [r]Alt+Shift",	{inspect_on=(not inspect_on)}).Checked = inspect_on
		items.Add("-")
		# Alternative targeting and history.
		if len(Ω = grep_targets()):	items.Add("Targets").MenuItems.AddRange(Ω)
		else:						items.Add("No targets").Enabled = false
		sub = items.Add("Auxiliary").MenuItems
		sub.Add("Target by win id...",		{shootdøwn("Input window ID to destroy:".request(0))})
		sub.Add("Target by proc id...",		{shootdøwn_pid("Input process ID to destroy:".request(0))})
		sub.Add("Target by win title...",	{shootdøwn("Input window title to destroy:".request("").lookup_title())})
		sub.Add("Target by proc path...",	{shootdøwn("Input process path to destroy:".request("").lookup_path())})
		items.Add("Tombstones").MenuItems.AddRange(grep_necro()) if necrologue.Count
		items.Add("-")
		# Termination.
		items.Add("Terminate", {destroy})
		return self

	# Overloads.[
	def shootdøwn(proc as ProcInfo):
		return if proc.pid == my.pid or proc.pid == nil # Suicide is a mortal sin.
		try:
			bang.Play() unless muffled
			necrologue.upcount(proc.destroy().exe).cycle(max_necro)
			stat.victims++
		except ex: stat.errors++; ex.errorbox("●● [pid=$(proc.pid), module='$(proc.exe)']")

	def shootdøwn(victim as WinInfo):
		shootdøwn(victim.owner)

	def shootdøwn(victim as uint):
		shootdøwn(victim.winfo())

	def shootdøwn(procs as List of ProcInfo):
		for proc in procs: shootdøwn(proc)

	def shootdøwn(victims as List of WinInfo):
		for x in victims.Select({x|x.owner}).Distinct(): shootdøwn(x)

	def shootdøwn():
		shootdøwn(target)

	def shootdøwn_pid(pid as uint):
		shootdøwn(pid.info())
	# ].Overloads

	static def look_around():
		result = List of WinInfo()
		{hwnd as IntPtr, x|result.Add(WinInfo(hwnd)) if hwnd.IsWindowVisible(); return true}.EnumWindows(nil)
		return result

	private def lookup_doomed():
		result = List of ProcInfo()
		for proc in ProcInfo.all: result.AddRange(proc for path in autokill["path"] if path in proc.exe)
		return result.GroupBy({x|x.pid}).Select({y|y.First()}).ToList()

	[Extension]	static def lookup_title(title as string):
		result = List of WinInfo()
		if title:
			{hwnd as IntPtr, x|result.Add(hwnd.winfo()) if title in hwnd.winfo().title; return true}\
			.EnumWindows(nil)
		return result

	[Extension]	static def lookup_path(path as string):
		return List of ProcInfo(proc for proc in path.either((,), ProcInfo.all) if path in proc.exe)

	[Extension] static def info(pid as IntPtr):
		return nil.winfo().owner if pid == nil
		return ProcInfo(pid)

	[Extension] static def info(pid as uint):
		return IntPtr(pid).info()

	[Extension] static def winfo(win_handle as IntPtr):
		return WinInfo(POINT(Cursor.Position).WindowFromPoint()) if win_handle == nil
		return WinInfo(win_handle)

	[Extension] static def winfo(win_handle as uint):
		return IntPtr(win_handle).winfo()

	target:
		get: return nil.winfo()

	def destroy():
		icon.Visible = false; Application.Exit()
		return self
#.} [Classes]

# ==Main code==
if Shooter().locker: Application.Run()
else: Δ.errorbox("This program is already running.")