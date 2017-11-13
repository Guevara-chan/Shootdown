# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# Shootdøwn windows destroyer v0.035
# Developed in 2017 by Guevara-chan.
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import System
import System.Text
import System.Linq
import System.Media
import System.Drawing
import System.Windows.Forms
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
# -------------------- #
abstract class Δ(API):
	protected static final name			= "Shootdøwn"
	public static final title			= "💀|$name|💀"
	public static final assembly_icon	= Icon.ExtractAssociatedIcon(Application.ExecutablePath)
	public static final assembly		= Reflection.Assembly.GetExecutingAssembly()
	static final PostXP					= Environment.OSVersion.Version.Major >= 6

	# --Methods goes here.
	[Extension] static def either[of T](val as bool, false_val as T, true_val as T):
		if val: return true_val
		else: return false_val

	[Extension] static def msgbox(text as string, icon as MessageBoxIcon):
		return MessageBox.Show(text, title, MessageBoxButtons.OK, icon)

	[Extension] static def errorbox(text as string):
		return text.msgbox(MessageBoxIcon.Error)

	[Extension] static def request[of T](text as string, default as T) as T:
		while true:
			if result = Interaction.InputBox(text, title, default.ToString(), -1, -1):
				try: return Convert.ChangeType(result, T)
				except ex: "Invalid input proveded !".errorbox()
			else: return default

	[Extension] static def try_lock(lock_name as string):
		unique as bool
		mutex = Threading.Mutex(true, lock_name, unique)
		return mutex if unique

	[Extension] static def find_res(id as string) as IO.Stream:
		if assembly.IsDynamic: return IO.File.OpenRead(id)
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

	# -- Additional service class.
	class WM_Receiver(Form):
		event WM as callable(Message)
		protected def SetVisibleCore(value as bool):
			super.SetVisibleCore(false)
		protected def WndProc(ref msg as Message):
			WM(msg)
			super.WndProc(msg)
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
		summary				= host.Report(IntPtr.Zero)
		info['path'].Text	= summary.path
		info['win'].Text	= host.target.ToString()
		info['pid'].Text	= summary.pid.ToString()
		flow.Location		= Point((Height - flow.Height) / 2 + 1, (Width - flow.Width) / 2 + 1)
		return self

	checkout:
		get: return join(info.Values.Select({x|x.Text}), '\n')
# -------------------- #
class Shooter(Δ):
	public max_necro	= 10
	public muffled		= false
	public inspect_on	= assembly.IsDynamic
	final icon			= NotifyIcon(Visible: true, Icon: assembly_icon, ContextMenu: ContextMenu())
	final timer			= Timer(Enabled: true, Interval: 100, Tick: {update})
	final msg_handler	= WM_Receiver(WM: {e as Message|activate() if e.Msg == 0x0312})
	final bang			= SoundPlayer("shoot.wav".find_res())
	final necrologue	= OrderedDictionary(max_necro)
	final analyzer		= InspectorWin(self)
	public final locker	= "!$name!".try_lock()
	struct stat():
		static startup	= DateTime.Now
		static victims	= 0

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
			if Keys.Insert.GetKeyState() & 1: Clipboard.SetText(analyzer.checkout)
		else: analyzer.Hide()
		return self

	private def setup_menu():
		# -Auxilary procedures.
		def grep_targets():
			cache = List[of MenuItem]()
			for win in scan_around():
				owner, naming = IO.Path.GetFileNameWithoutExtension(win.zoom().locate()), win.identify()
				cache.Add(MenuItem(
					"$owner:: "+(naming != '').either('<nil_title>', naming), {activate(win)}
					))
			return cache.GroupBy({x|x.Text}).Select({y|y.First()}).ToArray()
		def grep_necro():
			cache = List[of MenuItem]()
			for mortem as Collections.DictionaryEntry in necrologue:
				kill_count as int, path = mortem.Value, mortem.Key
				cache.Add(MenuItem(
					(kill_count > 1).either("", "「💀: $(kill_count)」 ") + path,
					{shell("explorer", "/select,\"$path\"")}
					))
			return cache.ToArray()
		# -Main code.
		items = icon.ContextMenu.MenuItems
		items.Clear()
		# Settings and info.
		items.Add("About...", {join((
			"$name v0.035", "*" * 19,
			"Uptime:: $((DateTime.Now - stat.startup).ToString('d\\ \\d\\a\\y\\(\\s\\)\\ \\~\\ h\\:mm\\:ss'))",
			"Processess destroyed:: $(stat.victims)"), '\n').msgbox(MessageBoxIcon.Information)})
		items.Add("Muffle sounds",				{muffled=(not muffled)}).Checked = muffled
		items.Add("Inspect on [r]Alt+Shift",	{inspect_on=(not inspect_on)}).Checked = inspect_on
		items.Add("-")
		# Alternative targeting and history.
		if len(Ω = grep_targets()):	items.Add("Targets").MenuItems.AddRange(Ω)
		else:						items.Add("No targets").Enabled = false
		sub = items.Add("Auxiliary").MenuItems
		sub.Add("Target by win id...", {activate("Input window ID to destroy:".request(0))})
		sub.Add("Target by proc id...", {slay("Input process ID to destroy:".request(0))})
		if necrologue.Count: items.Add("Tombstones").MenuItems.AddRange(grep_necro())
		items.Add("-")
		# Termination.
		items.Add("Terminate", {destroy})
		return self

	private def slay(proc as IntPtr):
		try:
			bang.Play() unless muffled
			necrologue.upcount(proc.shoot().path).cycle(max_necro)
			stat.victims++
		except ex: ex.ToString().Split(char('\n'))[0].errorbox()
		return update()

	def activate(victim as IntPtr):
		return slay(victim.zoom())

	def activate(victim as int):
		if victim: return activate(IntPtr(victim))

	def activate():
		return activate(target)

	static def scan_around():
		result = List[of IntPtr]()
		{hwnd as IntPtr, lparam|result.Add(hwnd) if hwnd.IsWindowVisible(); return true}.EnumWindows(IntPtr.Zero)
		return result

	[Extension]	static def zoom(win_handle as IntPtr):
		pid as IntPtr
		win_handle.GetWindowThreadProcessId(pid)
		return pid

	[Extension] static def identify(win_handle as IntPtr):
		result	= StringBuilder(max = 256)
		max		= win_handle.GetWindowText(result, max)
		return result.ToString()

	[Extension] static def locate(proc_handle as IntPtr):
		proc_handle	= ProcessAccess.QueryLimitedInformation.OpenProcess(true, proc_handle)
		result		= StringBuilder(max = 4096)
		if PostXP:	proc_handle.QueryFullProcessImageName(0, result, max)
		else:		proc_handle.GetModuleFileNameEx(IntPtr.Zero, result, max)
		proc_handle.CloseHandle()
		return result.ToString()

	[Extension]	static def shoot(proc_handle as IntPtr):
		mortem = Report(proc_handle)
		Diagnostics.Process.GetProcessById(proc_handle cast int).Kill()
		return mortem

	def destroy():
		icon.Visible = false; Application.Exit()
		return self

	static target:
		get: return POINT(Cursor.Position).WindowFromPoint()

	# --Additional service struct.
	struct Report():
		path	as string
		pid		as IntPtr
		time	as DateTime
		def constructor(proc_handle as IntPtr):
			if proc_handle == IntPtr.Zero: proc_handle = Shooter.target.zoom()
			path, pid, time = proc_handle.locate(), proc_handle, DateTime.Now
#.} [Classes]

# ==Main code==
if Shooter().locker: Application.Run()
else: Δ.errorbox("This program is already running.")