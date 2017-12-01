# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# Θuroboros network daemon v0.02
# Developed in 2017 by Guevara-chan.
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import System
import System.Text
import System.Drawing
import System.Windows.Forms
import System.Runtime.InteropServices
import System.Runtime.CompilerServices
import Microsoft.VisualBasic from Microsoft.VisualBasic

#.{ [Classes]
abstract class Δ:
	static final name					= "Θuroboros"	
	public static final title			= "「$(name)」"
	public static final assembly_icon	= Icon.ExtractAssociatedIcon(Application.ExecutablePath)

	# --Methods goes here.
	[Extension] static def either[of T](val as bool, false_val as T, true_val as T):
		if val: return true_val
		else: return false_val

	[Extension] static def msgbox(text as string, icon as MessageBoxIcon):
		return MessageBox.Show(text, title, MessageBoxButtons.OK, icon)

	[Extension] static def as_title(text as string):
		return text[:1].ToUpper() + text[1:].ToLower()

	[Extension] static def try_lock(lock_name as string):
		unique as bool
		mutex = Threading.Mutex(true, lock_name, unique)
		return mutex if unique

	def peek(name as string):
		proto = GetType()
		if prop = proto.GetProperty(name): return prop.GetValue(self, null)
		else: return proto.GetField(name).GetValue(self)

	def poke(name as string, val as object):
		proto = GetType()
		if prop = proto.GetProperty(name): prop.SetValue(self, val)
		else: proto.GetField(name).SetValue(self, val)
# -------------------- #
class IniFile():
	final	path	= ""
	public	section	= ""

	# --Import table goes here.
	[DllImport("kernel32", CharSet: CharSet.Unicode)]
	def GetPrivateProfileString(Section as string, Key as string, Default as string, RetVal as StringBuilder, \
		Size as int, FilePath as string) as int:
		pass

	# --Methods goes here.
	def constructor(ini_file as string):
		path = IO.FileInfo(ini_file).FullName

	def get_key(key as string, default as string, section as string):
		GetPrivateProfileString(section, key, default, result = StringBuilder(255), 255, path)
		return result.ToString()

	def get_key[of T](key as string, default as T, section as string):
		return Convert.ChangeType(get_key(key, "$default", section), default.GetType())

	def get_key[of T](key as string, default as T):
		return get_key(key, default, section)
# -------------------- #
class SetupWin(Form):
	final host as NetDaemon
	final feeders = Collections.Generic.Dictionary[of string, TextBox]()

	# --Methods goes here.
	def constructor(daemon as NetDaemon):
		# Primary setup operations.
		if daemon.at_setup: daemon.at_setup.Activate(); return 
		super()
		host							= daemon
		Text, Icon, BackColor			= "$(host.title) =setup", host.assembly_icon, Color.FromArgb(30, 30, 30)
		StartPosition, FormBorderStyle	= FormStartPosition.CenterScreen, FormBorderStyle.FixedSingle
		Size, AutoSize					= Size(0, 0), true
		# Layout controls.
		Controls.Add(flow = FlowLayoutPanel(FlowDirection: FlowDirection.TopDown, AutoSize: true,
			Margin: Padding(0, 0, 0, 0)))
		new_line = def():
			flow.Controls.Add(new_line = FlowLayoutPanel(AutoSize: true, FlowDirection:
			FlowDirection.LeftToRight, BorderStyle: BorderStyle.FixedSingle))
			return new_line
		# Additional controls.
		for id in daemon.fullcfg:
			flow_line = new_line()
			# Label.
			flow_line.Controls.Add(t=Label(Text: "● $(Δ.as_title(id))::", Dock: DockStyle.Fill,
				TextAlign: ContentAlignment.MiddleCenter, BorderStyle: BorderStyle.FixedSingle, 
				ForeColor: Color.Coral, Font: Font("Palatino Linotype", 10, FontStyle.Bold)))
			# Input field
			flow_line.Controls.Add(f=TextBox(Text: daemon.peek(id).ToString(), BorderStyle: BorderStyle.FixedSingle,
				ForeColor: Color.Gold, BackColor: Color.Black, TextAlign: HorizontalAlignment.Center, Width: 200,
				Font: Font("Sylfaen", 10)))
			f.Select(0, 0)
			feeders[id] = f
		# Additional controls.
		btn_line = new_line()
		for name, cb as callable in ("Save", {dump}), ("Accept", {feedback; done}), ("Exit", {done}):
			btn_line.Controls.Add(Button(Text: name, FlatStyle: FlatStyle.Flat, ForeColor: Color.AntiqueWhite,
				Click: {cb()}))
		btn_line.Margin = Padding((Width - btn_line.Width) / 2, 2, 0, 0)
		# Finalization.
		host.at_setup = self
		Closed += {done}
		Show()

	def feedback():
		for item as duck in feeders: 
			try: host.poke(id = item.Key, Convert.ChangeType(item.Value.Text, host.peek(id).GetType()))
			except: pass
			(item.Value as TextBox).Text = host.peek(id).ToString()

	def dump():
		feedback()
		IO.File.WriteAllText(host.config_path, "[$(host.config_sect)]\n$(host.config)", Encoding.Unicode)

	def done():
		host.at_setup = null
		Dispose()
# -------------------- #
class NetDaemon(Δ):
	public network	= ""
	public login	= ""
	public password	= ""
	public active	= true
	public at_setup as SetupWin
	final timer		= Timers.Timer(Enabled: true, AutoReset: true, Interval: 3 * 1000, Elapsed: {update})
	final icon		= NotifyIcon(Visible: true, Icon: assembly_icon, ContextMenu: ContextMenu())
	public final locker	= "!$name!".try_lock()
	struct stat():
		static startup	= DateTime.Now
		static fixes 	= 0

	# --Constants goes here.
	static final public maincfg		= ("network", "login", "password")
	static final public fullcfg		= maincfg + ("period",)	
	static final public config_path	= "$name.ini"
	static final public config_sect	= "Main"

	# --Methods goes here.
	def constructor():
		return unless locker or destroy()
		icon.MouseDown	+= {setup_menu}
		config = config_path
		settings() if "" in map(maincfg, peek)
		update()

	def update() as NetDaemon:
		if active and not online and online = true and online: stat.fixes++
		icon.Text 	= "「$(Strings.Left(network, 52))」:: " + online.either("offline", "online")
		return self

	private def setup_menu():
		items = icon.ContextMenu.MenuItems
		items.Clear()		
		items.Add(online.either("Reconnect", "Disconnect"), {online=(not online); update()}) if not active
		items.Add(active.either("Resume", "Pause")+" watch", {active=(not active); update()})
		items.Add("-", {0})
		items.Add("Setup", {settings()})
		items.Add("About...", {join((
			"$name v0.02", "*" * 18, config, "*" * 18, 
			"Uptime:: $((DateTime.Now - stat.startup).ToString('d\\ \\d\\a\\y\\(\\s\\)\\ \\~\\ h\\:mm\\:ss'))",
			"Network fixes:: $(stat.fixes)"), '\n').msgbox(MessageBoxIcon.Information)})
		items.Add("Terminate", {destroy()})

	def settings():
		SetupWin(self)

	def destroy():
		icon.Visible = false; Application.Exit()
		return self

	period as int:
		get: return timer.Interval
		set: timer.Interval = value

	config as string:
		get: return join("$(id.as_title()) = $(peek(id))" for id in fullcfg, '\n')
		set:
			cfg = IniFile(value, section: config_sect)
			for id in fullcfg: poke(id, cfg.get_key(id, peek(id)))
			update()

	online as bool:
		get: # is_online technically.
			try:	return 0 != Net.Dns.GetHostEntry("google.com")
			except: pass
		set: # reconnection/disconnection.
			shell("rasdial", value.either("/disconnect", join("\"$(peek(id))\"" for id in maincfg)))
#.}

# ==Main code==
if NetDaemon().locker: Application.Run()
else: Δ.msgbox("This daemon is already running.", MessageBoxIcon.Error)