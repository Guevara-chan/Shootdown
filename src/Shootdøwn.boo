# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# Shootdøwn windows destroyer v0.063
# Developed in 2017 by Guevara-chan.
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import System
import System.IO
import System.Text
import System.Linq
import System.Drawing
import System.Diagnostics
import System.Windows.Forms
import System.Security.Principal
import System.Collections.Generic
import System.Collections.Specialized
import System.Runtime.InteropServices
import System.Runtime.CompilerServices
import Microsoft.VisualBasic from Microsoft.VisualBasic
import System.Web.Script.Serialization from System.Web.Extensions

#.{ [Classes]
abstract class API():
	# --Auxilary definitions.
	[Flags] enum Layer:
		Color = 1
		Alpha = 2

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
	[Extension]	static def SetLayeredWindowAttributes(hWnd as IntPtr, crKey as uint, bAlpha as byte, 
		dwFlags as int) as bool:
		pass
	[DllImport("user32.dll")] 
	[Extension]	static def GetLayeredWindowAttributes(hwnd as IntPtr, ref crKey as uint, ref bAlpha as byte, 
		ref dwFlags as int) as bool:
		pass
	[DllImport("user32.dll")]
	[Extension]	static def HungWindowFromGhostWindow(hwnd as IntPtr) as IntPtr:
		pass
	[DllImport("user32.dll")]
	[Extension]	static def IsHungAppWindow(hwnd as IntPtr) as bool:
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
	static final postXP			= Environment.OSVersion.Version.Major >= 6
	static final nil			= IntPtr.Zero
	static final gen_md5		= Security.Cryptography.MD5Cng()
	static final is_admin = WindowsPrincipal(WindowsIdentity.GetCurrent()).IsInRole(WindowsBuiltInRole.Administrator)
	public static final name			= "Shootdøwn"
	public static final win_title		= "💀|$name|💀"
	public static final assembly_icon	= Icon.ExtractAssociatedIcon(Application.ExecutablePath)
	public static final assembly		= Reflection.Assembly.GetExecutingAssembly()
	
	# --Methods goes here.
	[Extension] static def either[of T, T2](val as T, false_val as T2, true_val as T2):
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

	[Extension] static def request(text as string) as string:
		return request(text, "")

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

	[Extension] static def file_md5(path as string):
		return gen_md5.ComputeHash(File.OpenRead(path))	

	[Extension] static def bind(proc as callable, arg):
		return {proc(arg)}

	[Extension] static def bind(proc as callable, arg, arg2):
		return {proc(arg, arg2)}

	[Extension] static def ptr[of T](addr as T):
		alfa as uint = Convert.ChangeType(addr, uint)
		return IntPtr(alfa)

	[Extension] static def invert(ref val as bool):
		return val = (not val)

	[Extension] static def hex(src as (byte)):
		return join(x.ToString("x2") for x in src, "")

	[Extension] static def unhex(text as string):
		index	= 0
		text	= /[^0-9^a-f]/.Replace(text.ToLower(), "")
		accum	= StringBuilder(2)
		result	= array(byte, text.Length / 2)
		if text.Length % 2: text = "0" + text 
		for c in text:
			accum.Append(c)
			if accum.Length == 2: result[index++] = Convert.ToInt32(accum.ToString(), 16); accum.Clear()
		return result

	def peek(name as string):
		proto = GetType()
		if prop = proto.GetProperty(name): return prop.GetValue(self, null)
		else: return proto.GetField(name).GetValue(self)

	def poke(name as string, val as object):
		proto = GetType()
		if prop = proto.GetProperty(name): prop.SetValue(self, val)
		else: proto.GetField(name).SetValue(self, val)

	# -- Additional service class.
	class WM_Receiver(Form):
		event WM as callable(Message)
		protected def SetVisibleCore(value as bool):
			super.SetVisibleCore(false)
		protected def WndProc(ref msg as Message):
			WM(msg)
			super.WndProc(msg)
# -------------------- #
abstract class Observable(Δ):
	private Δprev_state = json

	# --Methods goes here.
	def constructor():
		pass

	static def op_Implicit(x as Observable):
		return "$x"

	def load(path as string):
		try: 
			json = File.ReadAllText(path) if File.Exists(path)
		except ex: ex.errorbox()
		return sync()

	def sync():
		Δprev_state = self
		return self

	def sync(path as string):
		try: File.WriteAllText(path, sync())
		except ex: ex.errorbox()
		return self

	override def ToString():
		return json

	[ScriptIgnoreAttribute]	json:
		get: return JavaScriptSerializer().Serialize(self)
		set: # Auxiliary procedure.
			def grep(aggregator as duck, feeder as Dictionary[of string, object]):
				for entry in feeder: aggregator[entry.Key] = entry.Value
			 # Deserializtion loop.
			for entry in JavaScriptSerializer().Deserialize of Dictionary[of string, object](value):
				if entry.Value.GetType() is Dictionary[of string, object]: grep(peek(entry.Key), entry.Value)
				else: poke(entry.Key, entry.Value)

	[ScriptIgnoreAttribute]	changed:
		get: return self != Δprev_state
# -------------------- #
abstract class AuxWindow(Form):
	protected static final click_through	= 0x80000 | 0x20
	protected static final AllLayers		= 3

	# --Methods goes here.
	def init(opacity as decimal):
		ex_style, α = ex_style | click_through, opacity
		return self

	private layer_flags:
		get:
			alpha as byte = color = (flags = 0) cast uint
			API.GetLayeredWindowAttributes(Handle, color, alpha, flags)
			return Tuple.Create(color, alpha)

	ex_style:
		get: return API.GetWindowLong(Handle, API.GWL.ExStyle)
		set: API.SetWindowLong(Handle, API.GWL.ExStyle, value)

	α as decimal:
		get: return layer_flags.Item2 / 255.0
		set: API.SetLayeredWindowAttributes(Handle, layer_flags.Item1, (255 * value) cast byte, AllLayers)

	color_key:
		get: return ColorTranslator.FromWin32(layer_flags.Item1)
		set: API.SetLayeredWindowAttributes(Handle, ColorTranslator.ToWin32(value), layer_flags.Item2, AllLayers)
# -------------------- #
class ProcInfo(Δ):
	private md5_hash as (byte)
	public final exe as string
	public final pid as IntPtr
	public final taken = DateTime.Now
	public static final current	= ProcInfo(Process.GetCurrentProcess().Id.ptr())

	# --Methods goes here.
	def constructor(proc_id as IntPtr):
		pid	= proc_id
		exe	= pid.locate()

	def constructor(proc_path as string):
		exe	= proc_path

	def visit():
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

	override def ToString():
		return exe

	static def op_Equality(x as ProcInfo, y as ProcInfo):
		return x.pid == y.pid

	static def op_Implicit(x as ProcInfo):
		return "$x"

	[Extension] static def locate(proc_handle as IntPtr):
		proc_handle	= ProcessAccess.QueryLimitedInformation.OpenProcess(true, proc_handle)
		result		= StringBuilder(max = 4096)
		if postXP:	proc_handle.QueryFullProcessImageName(0, result, max)
		else:		proc_handle.GetModuleFileNameEx(nil, result, max)
		proc_handle.CloseHandle()
		return result.ToString()

	[Extension]	static def from_win(win_handle as IntPtr):
		pid as IntPtr
		win_handle = win_handle.HungWindowFromGhostWindow() if win_handle.IsHungAppWindow()
		win_handle.GetWindowThreadProcessId(pid)
		return ProcInfo(pid)

	md5_raw:
		get:
			if md5_hash: return md5_hash
			try: return md5_hash = exe.file_md5()
			except: pass

	md5:
		get:
			return raw.hex() if raw = md5_raw

	static all_pids:
		get:
			copied as uint, Δ as int = 0, sizeof(uint)
			pids = array(uint, max = 1024)
			pids.EnumProcesses(max * Δ, copied)
			return pids[:copied/Δ]

	static all:
		get: return all_pids.Select({x|ProcInfo(x.ptr())})

	static none:
		get: return List of ProcInfo()

	def destroy():
		Process.GetProcessById(pid cast int).Kill()
		return self
# -------------------- #
class WinInfo(Δ):
	public final id		as IntPtr
	public final owner	as ProcInfo
	public final taken	= DateTime.Now

	# --Methods goes here.
	def constructor(win_handle as IntPtr):
		id		= win_handle
		owner 	= ProcInfo.from_win(id)

	static def op_Implicit(x as WinInfo):
		return x.owner

	static def op_Implicit(x as WinInfo) as string:
		return x.title

	[Extension] static def identify(win_handle as IntPtr):
		result	= StringBuilder(max = 256)
		max		= win_handle.GetWindowText(result, max)
		return result.ToString()

	title:
		get: return id.identify()

	visible:
		get: return id.IsWindowVisible()

	static all:
		get:
			result = List of WinInfo()
			{hwnd, x|result.Add(WinInfo(hwnd)); return true}.EnumWindows(nil)
			return result

	static none:
		get: return List of WinInfo()
# -------------------- #
class Decal(AuxWindow):
	final timer			= Timer(Enabled: true, Interval: 2000, Tick: {tick})
	static final atlas	= Bitmap(Δ.find_res("decal.png"))
	static final dim	= Point(5, 2)
	static final rnd	= Random()
	private final img	= PictureBox(Width: atlas.Width/ 1.0 /dim.X, Height: atlas.Height/ 1.0 /dim.Y)

	def constructor(origin as Point):
		# Primary setup operations.
		TopMost, ShowInTaskbar, FormBorderStyle = true, false, FormBorderStyle.None
		StartPosition, Size						= FormStartPosition.Manual, Size(140, 140)
		# Backgtound setup.
		img.Image		= atlas.Clone(
			Rectangle(img.Width * rnd.Next(dim.X), img.Height * rnd.Next(dim.Y), img.Width, img.Height),
			atlas.PixelFormat)
		img.Location	= Point((Width - img.Width) / 2, (Height - img.Height) / 2)
		Controls.Add(img)
		# Finalization.
		init(1).color_key	= BackColor = Color.DarkSlateGray
		Location			= Point(origin.X - Width / 2, origin.Y - Height / 2)
		Show()

	def tick():
		timer.Interval = 25
		if α > (d = 0.05): α -= d
		else: destroy()

	def destroy():
		timer.Dispose()
		Dispose()
# -------------------- #
class InspectorWin(AuxWindow):
	final host as Shooter
	final info = Collections.Generic.Dictionary[of string, Label]()
	final flow = FlowLayoutPanel(FlowDirection: FlowDirection.TopDown, AutoSize: true, Size: Size(0, 0),
		AutoSizeMode: AutoSizeMode.GrowAndShrink, Margin: Padding(0, 0, 0, 0))

	# --Methods goes here.
	def constructor(base as Shooter):
		# Primary setup operations.
		host									= base
		TopMost, ShowInTaskbar, AutoSizeMode	= true, false,  AutoSizeMode.GrowAndShrink
		ControlBox, Text, FormBorderStyle		= false, "", FormBorderStyle.FixedSingle
		Size, AutoSize, BackColor				= Size(0, 0), true, Color.FromArgb(30, 30, 30)
		# Controls setup.
		Controls.Add(flow)
		for id in "proc", "md5", "win", "pid":
			flow.Controls.Add(line = FlowLayoutPanel(FlowDirection: FlowDirection.LeftToRight, AutoSize: true,
				Margin: Padding(0, 0, 0, 0)))
			line.Controls.Add(Label(Text: "●「$(id)」:", ForeColor: Color.Cyan, AutoSize: true))
			info[id] = Label(ForeColor: Color.Coral, AutoSize: true, Size: Size(0, 0), 
				Margin: Padding(0, 0, 0, 0))
			line.Controls.Add(info[id])
		# Additional aligning.
		align = info.Values.Select({x|x.Location.X}).Max()
		info.Values.ToList().ForEach({x|x.Margin = Padding(align - x.Location.X, 0, 0, 0)})
		# Finalization
		init(0.95)

	def update() as InspectorWin:
		Location			= Cursor.Position
		pinfo				= host.target.owner
		for id, feed in ('proc', pinfo), ('md5', pinfo.md5), ("win", host.target.id), ("pid", pinfo.pid): 
			info[id].Text	= feed.ToString()
		flow.Location		= Point((Height - flow.Height) / 2 + 1, (Width - flow.Width) / 2 + 1)
		return self

	checkout:
		get: return join(info.Values.Select({x|x.Text}), ' | ')
# -------------------- #
class AutoKillerWin(Form):
	# TODO: Implement me, damn it.
	final host as Shooter
	final flow		= FlowLayoutPanel(FlowDirection: FlowDirection.TopDown, AutoSize: true, Size: Size(0, 0),
		AutoSizeMode: AutoSizeMode.GrowAndShrink, Margin: Padding(0, 0, 0, 0))
	final listing	= ListView(Margin: Padding(5, 5, 5, 5), BackColor: Color.FromArgb(20,20,20), 
		BorderStyle: BorderStyle.FixedSingle)

	# --Methods goes here.
	def constructor(base as Shooter):
		if base.autokill_win: base.autokill_win.Activate(); return
		super()
		host					= base
		Text, Icon, BackColor	= "|$(host.name)| =auto-kill", host.assembly_icon, Color.FromArgb(30,30,30)
		StartPosition			= FormStartPosition.CenterScreen
		DoubleBuffered			= true
		# Layout controls.
		Controls.Add(flow)
		flow.Controls.Add(listing)
		for name in "💀 title", "💀 exe", "💀 md5":
			btn = Button(Text: name, FlatStyle: FlatStyle.Flat, ForeColor: Color.AntiqueWhite)
		# Finalization.
		host.autokill_win = self
		Closed += {destroy}
		Show()

	def feedback():
		for cat in host.cfg.autokill:
			for desc as string in cat.Value:
				listing.Items.Add(desc)

	def destroy():
		host.autokill_win = null
		Dispose()
		return self
# -------------------- #
class Shooter(Δ):
	public autokill_win as AutoKillerWin
	final me			= ProcInfo.current
	final icon			= NotifyIcon(Visible: true, Icon: assembly_icon, ContextMenu: ContextMenu())
	final ak_timer		= Timer(Enabled: true, Interval: 3000, Tick: {shootdøwn(lookup_doomed())})
	final upd_timer		= Timer(Enabled: true, Interval: 100, Tick: {update})
	final msg_handler	= WM_Receiver(WM: {e as Message|shootdøwn() if e.Msg == 0x0312})
	final bang			= Media.SoundPlayer("shoot.wav".find_res())
	final analyzer		= InspectorWin(self)
	public final locker		= "!$name!".try_lock()
	public final work_dir	= assembly.IsDynamic.either(Path.GetDirectoryName(me.exe), Directory.GetCurrentDirectory())
	public final cfg_file	= Path.Combine(work_dir, "$name.json")
	public final cfg		= Config().load(cfg_file) as Config
	final necrologue		= OrderedDictionary(cfg.max_necro)
	struct stat():
		static startup	= DateTime.Now
		static victims	= 0
		static errors	= 0
	class Config(Observable):
		public max_necro	= 10
		public muffled		= false
		public hide_holes	= false
		public inspect_on	= assembly.IsDynamic
		public autosave 	= not assembly.IsDynamic
		public autokill		= {"path": HashSet of string(), "title": HashSet of string(), "md5": HashSet of string()}

	# --Methods goes here.
	def constructor():
		return unless locker or not destroy()
		icon.MouseDown += {setup_menu}
		msg_handler.Handle.RegisterHotKey(0, KeyModifier.Alt | KeyModifier.Shift, Keys.F4)
		update()

	def update() as Shooter:
		icon.Text = "$name 「💀: $(stat.victims)」"
		if cfg.inspect_on and Keys.RMenu.pressed() and Keys.ShiftKey.pressed():
			analyzer.update().Show()
			Clipboard.SetText(analyzer.checkout) if Keys.Insert.GetKeyState() & 1
		else: analyzer.Hide()
		if cfg.autosave and cfg.changed: cfg.sync(cfg_file)
		return self

	private def setup_menu():
		# -Auxilary procedures.
		def grep_targets():
			cache = List of MenuItem()
			for win in look_around():
				owner = Path.GetFileNameWithoutExtension(win.owner)
				cache.Add(MenuItem("$owner:: " + win.title.either('<nil_title>', win.title), {shootdøwn(win)}))
			return cache.GroupBy({x|x.Text}).Select({y|y.First()}).ToArray()
		def grep_necro():
			index	= 0
			cache	= List of MenuItem()
			for mortem as Collections.DictionaryEntry in necrologue:
				kill_count as int, info as ProcInfo = mortem.Value, ProcInfo(mortem.Key as string)
				cache.Add(tomb = MenuItem((kill_count > 1).either("", "「💀: $(kill_count)」 ") + info))
				tomb.MenuItems.Add("Visit",		{x as ProcInfo|x.visit()}.bind(info))
				tomb.MenuItems.Add("Purge",		{x as ProcInfo,i as int|necrologue.RemoveAt(i+x.purge().pid cast int)
					if "Are you sure want to delete '$(x)' ?".askbox()}.bind(info, index))
				tomb.MenuItems.Add("Reraise",	{x as ProcInfo|x.reraise()}.bind(info))
				index++
			return cache.ToArray()
		# -Main code.
		items = icon.ContextMenu.MenuItems
		items.Clear()
		# Settings and info.
		items.Add("About...", {join((
			"$name v0.063", "*" * 19,
			"Uptime:: $((DateTime.Now - stat.startup).ToString('d\\ \\d\\a\\y\\(\\s\\)\\ \\~\\ h\\:mm\\:ss'))",
			"Processess destroyed:: $(stat.victims)", "Termination errors:: $(stat.errors)"), '\n'
			).msgbox(MessageBoxIcon.Information)})
		items.Add("-")
		# Settings block.
		sub = items.Add("Configure").MenuItems
		sub.Add("Muffle sounds",			{cfg.muffled.invert()}		).Checked = cfg.muffled
		sub.Add("Hide bullet holes",		{cfg.hide_holes.invert()}	).Checked = cfg.hide_holes
		sub.Add("Inspect on [r]Alt+Shift",	{cfg.inspect_on.invert()}	).Checked = cfg.inspect_on
		items.Add("Autosave configuration",	
						{File.Delete(cfg_file) unless cfg.autosave.invert()}).Checked = cfg.autosave
		items.Add("-")
		# Alternative targeting and history.
		if len(Ω = grep_targets()):	items.Add("Targets").MenuItems.AddRange(Ω)
		else:						items.Add("No targets").Enabled = false
		sub = items.Add("Auxiliary").MenuItems
		sub.Add("Target by win id...",		{shootdøwn("Input window ID to destroy:".request(0))})
		sub.Add("Target by proc id...",		{shootdøwn_pid("Input process ID to destroy:".request(0))})
		sub.Add("-")
		sub.Add("Target by win title..",	{shootdøwn("Input window title to destroy:".request().lookup_title())})
		sub.Add("Target by proc path..",	{shootdøwn("Input module exepath to destroy:".request().lookup_path())})
		sub.Add("-")
		sub.Add("Target by exe md5...",		{shootdøwn("Input main module MD5 to destroy:".request().lookup_md5())})
		items.Add("Tombstones").MenuItems.AddRange(grep_necro()) if necrologue.Count
		items.Add("Setup auto-kill...", {setup_ak}) if false # Later, dear firends.
		items.Add("-")
		# Elevation & termination.
		items.Add("Elevate privileges", {elevate()}) unless is_admin
		items.Add("Terminate", {destroy})
		return self

	def setup_ak():
		AutoKillerWin(self)

	# Overloads.[
	def shootdøwn(proc as ProcInfo, positioned as bool):
		return if proc == me or proc.pid == nil # Suicide is a mortal sin.
		try:
			bang.Play() unless cfg.muffled
			if positioned and not cfg.hide_holes:
				Decal(Cursor.Position) 
				Application.DoEvents()
				Threading.Thread.Sleep(100)
			necrologue.upcount(proc.destroy()).cycle(cfg.max_necro)
			return stat.victims++ >= 0			
		except ex: stat.errors++; ex.errorbox("●● [pid=$(proc.pid), module='$proc']")

	def shootdøwn(proc as ProcInfo):
		return shootdøwn(proc as ProcInfo, false)

	def shootdøwn(victim as uint):
		return shootdøwn(WinInfo(victim.ptr())) if victim

	def shootdøwn(victims as ProcInfo*):
		for x in victims: shootdøwn(x)

	def shootdøwn(victims as WinInfo*):
		for x in victims.Select({x|x.owner}).Distinct(): shootdøwn(x)

	def shootdøwn():
		return shootdøwn(target, true)

	def shootdøwn_pid(pid as uint):
		return shootdøwn(ProcInfo(pid.ptr())) if pid
	# ].Overloads

	def elevate():
		try:
			Process.Start(ProcessStartInfo(FileName: me.exe, WorkingDirectory: Path.GetDirectoryName(me.exe),
				UseShellExecute: true, Verb: "runas"))
			return destroy()
		except ex as ComponentModel.Win32Exception: "Elevation request was rejected.".errorbox(); return self

	static def look_around():
		return WinInfo.all.Where({x|x.visible})

	private def lookup_doomed():
		result = List of ProcInfo()
		for win in WinInfo.all:	result.AddRange(win.owner for title in cfg.autokill["title"] if title in win.title)
		for proc in ProcInfo.all:
			result.AddRange(proc for path	in cfg.autokill["path"]	if path	in proc.exe)
			result.AddRange(proc for md5	in cfg.autokill["md5"]	if md5	== proc.md5)
		return result.GroupBy({x|x.pid}).Select({y|y.First()})

	[Extension]	static def lookup_title(title as string):
		return WinInfo.none unless title
		return WinInfo.all.Where({x|title in x})

	[Extension]	static def lookup_path(path as string):
		return ProcInfo.none unless path
		return ProcInfo.all.Where({x|path in x})

	[Extension]	static def lookup_md5(md5 as string):
		return ProcInfo.none unless (sample = md5.unhex()).Length == 16
		return ProcInfo.all.Where({x|x.md5_raw == sample})

	target:
		get: return WinInfo(POINT(Cursor.Position).WindowFromPoint())

	def destroy():
		icon.Visible = false; Application.Exit()
		return self
#.} [Classes]

# ==Main code==
if Shooter().locker: Application.Run()
else: Δ.errorbox("This program is already running.")