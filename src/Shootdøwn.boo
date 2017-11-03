# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# Shootdown windows destroyer v0.015
# Developed in 2017 by Guevara-chan.
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import System
import System.Text
import System.Linq
import System.Media
import System.Drawing
import System.Windows.Forms
import System.Runtime.InteropServices
import System.Runtime.CompilerServices

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
	[DllImport("kernel32.dll")]
	[Extension]	static def OpenProcess(Access as ProcessAccess, bInheritHnd as bool, Id as IntPtr) as IntPtr:
		pass
	[DllImport("kernel32.dll")]
	[Extension]	static def CloseHandle(hObject as IntPtr) as bool:
		pass
	[DllImport("psapi.dll", CharSet: CharSet.Unicode)]
	[Extension]	static def GetProcessImageFileName(hProc as IntPtr, lpName as StringBuilder, nSize as int) as uint:
		pass
# -------------------- #
abstract class Δ(API):
	protected static final name			= "Shootdøwn"
	public static final title			= "💀|$name|💀"
	public static final assembly_icon	= Icon.ExtractAssociatedIcon(Application.ExecutablePath)

	# --Methods goes here.
	[Extension] static def either[of T](val as bool, false_val as T, true_val as T):
		if val: return true_val
		else: return false_val

	[Extension] static def msgbox(text as string, icon as MessageBoxIcon):
		return MessageBox.Show(text, title, MessageBoxButtons.OK, icon)

	[Extension] static def try_lock(lock_name as string):
		unique as bool
		mutex = Threading.Mutex(true, lock_name, unique)
		return mutex if unique

	[Extension] static def find_res(id as string) as IO.Stream:
		asm = Reflection.Assembly.GetExecutingAssembly()
		if asm.IsDynamic: return IO.File.OpenRead(id)
		else: return asm.GetManifestResourceStream(id)

	# Additional service class.
	class WM_Receiver(Form):
		event WM as callable(Message)
		protected def SetVisibleCore(value as bool):
			super.SetVisibleCore(false)
		protected def WndProc(ref msg as Message):
			WM(msg)
			super.WndProc(msg)
# -------------------- #
class Shooter(Δ):
	public muffled		= false
	final icon			= NotifyIcon(Visible: true, Icon: assembly_icon, ContextMenu: ContextMenu())
	final timer			= Timers.Timer(Enabled: true, AutoReset: true, Interval: 500, Elapsed: {update})
	final msg_handler	= WM_Receiver(WM: {e as Message|activate() if e.Msg == 0x0312})
	final bang			= SoundPlayer("shoot.wav".find_res())
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
		return self

	private def setup_menu():
		# -Auxilary procedure.		
		def grep_targets():
			cache = List[of MenuItem]()
			for win in scan_around():
				owner, naming = IO.Path.GetFileNameWithoutExtension(win.zoom().locate()), win.identify()
				cache.Add(MenuItem(
					"$owner:: "+(naming != '').either('<nil_title>', naming), {activate(win)}
					))
			return cache.GroupBy({x|x.Text}).Select({y|y.First()})
		# -Main code.
		items = icon.ContextMenu.MenuItems
		items.Clear()
		items.Add("About...", {join((
			"$name v0.015", "*" * 19,
			"Uptime:: $((DateTime.Now - stat.startup).ToString('d\\ \\d\\a\\y\\(\\s\\)\\ \\~\\ h\\:mm\\:ss'))",
			"Process destroyed:: $(stat.victims)"), '\n').msgbox(MessageBoxIcon.Information)})
		items.Add("Targets", {0}).MenuItems.AddRange(grep_targets().ToArray())
		items.Add("-", {0})
		items.Add("Muffle sounds", {muffled=(not muffled)}).Checked = muffled
		items.Add("-", {0})
		items.Add("Terminate", {destroy})
		return self

	def activate(victim as IntPtr):
		bang.Play() unless muffled
		victim.zoom().shoot()
		stat.victims++
		return update()

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
		proc_handle	= ProcessAccess.All.OpenProcess(true, proc_handle)
		result		= StringBuilder(max = 4096)
		max			= proc_handle.GetProcessImageFileName(result, max)
		proc_handle.CloseHandle()
		return result.ToString()

	[Extension]	static def shoot(proc_handle as IntPtr):
		mortem = proc_handle.locate()
		Diagnostics.Process.GetProcessById(proc_handle cast int).Kill()
		return mortem

	def destroy():
		icon.Visible = false; Application.Exit()
		return self

	static target:
		get: return POINT(Cursor.Position).WindowFromPoint()
#.} [Classes]

# ==Main code==
if Shooter().locker: Application.Run()
else: Δ.msgbox("This program is already running.", MessageBoxIcon.Error)