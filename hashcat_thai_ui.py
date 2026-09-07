import json
import queue
import subprocess
import threading
import time
import urllib.request
import webbrowser
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from tkinter import filedialog, messagebox
import tkinter as tk
from tkinter import ttk


APP_DIR = Path(__file__).resolve().parent
HASHCAT_EXE = APP_DIR / "hashcat.exe"
HISTORY_FILE = APP_DIR / ".hashcat_thai_ui_history.json"
ROCKYOU_URL = "https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt"
CAP2HASHCAT_URL = "https://hashcat.net/cap2hashcat/"

COLORS = {
    "bg": "#0d1117",
    "panel": "#151b23",
    "panel_2": "#1c2430",
    "border": "#30363d",
    "text": "#e6edf3",
    "muted": "#8b949e",
    "blue": "#58a6ff",
    "blue_2": "#1f6feb",
    "green": "#3fb950",
    "red": "#f85149",
    "yellow": "#d29922",
}

FONT = ("Segoe UI", 10)
FONT_SM = ("Segoe UI", 9)
FONT_MD = ("Segoe UI Semibold", 11)
FONT_TITLE = ("Segoe UI Semibold", 18)
FONT_MONO = ("Cascadia Mono", 9)


@dataclass
class Phase:
    title: str
    description: str
    attack_mode: str
    args: list
    required_files: list
    estimate: str


THAI_PREFIX_PATTERNS = [
    "099?d?d?d?d?d?d?d", "098?d?d?d?d?d?d?d", "097?d?d?d?d?d?d?d",
    "096?d?d?d?d?d?d?d", "095?d?d?d?d?d?d?d", "094?d?d?d?d?d?d?d",
    "093?d?d?d?d?d?d?d", "092?d?d?d?d?d?d?d", "091?d?d?d?d?d?d?d",
    "090?d?d?d?d?d?d?d", "089?d?d?d?d?d?d?d", "088?d?d?d?d?d?d?d",
    "087?d?d?d?d?d?d?d", "086?d?d?d?d?d?d?d", "085?d?d?d?d?d?d?d",
    "084?d?d?d?d?d?d?d", "083?d?d?d?d?d?d?d", "082?d?d?d?d?d?d?d",
    "081?d?d?d?d?d?d?d", "080?d?d?d?d?d?d?d", "069?d?d?d?d?d?d?d",
    "068?d?d?d?d?d?d?d", "067?d?d?d?d?d?d?d", "066?d?d?d?d?d?d?d",
    "065?d?d?d?d?d?d?d", "064?d?d?d?d?d?d?d", "063?d?d?d?d?d?d?d",
    "062?d?d?d?d?d?d?d", "061?d?d?d?d?d?d?d",
]

BIRTHDATE_PATTERNS = [
    "?d?d?d?d25?d?d",
    "?d?d?d?d26?d?d",
    "?d?d?d?d19?d?d",
    "?d?d?d?d20?d?d",
]


def now_text():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def format_duration(seconds):
    seconds = max(0, int(seconds))
    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    secs = seconds % 60
    return f"{hours}h {minutes}m {secs}s"


def safe_read_json(path, default):
    try:
        if path.exists():
            return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        pass
    return default


def safe_write_json(path, payload):
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def ensure_pattern_files():
    prefix_path = APP_DIR / "thaiprefix.txt"
    birthdate_path = APP_DIR / "birthdate_patterns.txt"
    if not prefix_path.exists():
        prefix_path.write_text("\n".join(THAI_PREFIX_PATTERNS) + "\n", encoding="utf-8")
    if not birthdate_path.exists():
        birthdate_path.write_text("\n".join(BIRTHDATE_PATTERNS) + "\n", encoding="utf-8")


def build_phases(level):
    rockyou = str(APP_DIR / "rockyou.txt")
    best66 = str(APP_DIR / "rules" / "best66.rule")
    phases = [
        Phase("Phase 1", "Dictionary attack: rockyou.txt", "0", [rockyou], [rockyou], "1-5 min"),
        Phase("Phase 2", "Thai birthdate masks (BE/CE)", "3", [str(APP_DIR / "birthdate_patterns.txt")], [], "5-10 min"),
        Phase("Phase 3", "8-digit numbers", "3", ["?d?d?d?d?d?d?d?d"], [], "10-30 min"),
        Phase("Phase 4", "Thai mobile phone numbers", "3", [str(APP_DIR / "thaiprefix.txt")], [], "30-60 min"),
    ]
    if level >= 2:
        phases.extend([
            Phase("Phase 5", "Dictionary + best66 rules", "0", [rockyou, "-r", best66], [rockyou, best66], "30-60 min"),
            Phase("Phase 6", "9-digit numbers", "3", ["?d?d?d?d?d?d?d?d?d"], [], "2-8 hours"),
        ])
    if level >= 3:
        phases.append(Phase("Phase 7", "10-digit numbers", "3", ["?d?d?d?d?d?d?d?d?d?d"], [], "20-80 hours"))
    if level >= 4:
        phases.extend([
            Phase("Phase 8", "11-digit numbers", "3", ["?d?d?d?d?d?d?d?d?d?d?d"], [], "8-33 days"),
            Phase("Phase 9", "12-digit numbers", "3", ["?d?d?d?d?d?d?d?d?d?d?d?d"], [], "83-333 days"),
        ])
    return phases


class HashcatRunner:
    def __init__(self, send):
        self.send = send
        self.process = None
        self.stop_requested = False
        self.skip_requested = False

    def stop(self):
        self.stop_requested = True
        self._terminate_current()

    def skip(self):
        self.skip_requested = True
        self._terminate_current()

    def _terminate_current(self):
        proc = self.process
        if proc and proc.poll() is None:
            try:
                proc.terminate()
                try:
                    proc.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    proc.kill()
            except Exception as exc:
                self.send("log", f"[WARN] Could not stop current process: {exc}\n")

    def run_job(self, settings):
        started_at = time.time()
        start_text = now_text()
        hashfile = Path(settings["hashfile"])
        level = int(settings["level"])
        device_mode = settings["device"]
        result = ""
        status = "completed"

        try:
            self.stop_requested = False
            self.skip_requested = False
            self._preflight(hashfile)
            ensure_pattern_files()

            device_param, optimize, device_label = self._resolve_device(device_mode)
            self.send("status", f"Running - {device_label}")
            self.send("log", f"[START] {hashfile.name}\n")
            self.send("log", f"[INFO] Device: {device_label} | Attack level: {level}\n\n")

            if settings["download_rockyou"]:
                self._download_rockyou_if_needed()

            for index, phase in enumerate(build_phases(level), start=1):
                if self.stop_requested:
                    status = "stopped"
                    break

                missing = [p for p in phase.required_files if not Path(p).exists()]
                if missing:
                    self.send("log", f"[SKIP] {phase.title}: missing {', '.join(Path(p).name for p in missing)}\n\n")
                    continue

                self.skip_requested = False
                self.send("phase", f"{phase.title}: {phase.description}")
                self.send("progress", (index - 1, len(build_phases(level))))
                self.send("log", f"============================================================\n")
                self.send("log", f"{phase.title.upper()} - {phase.description}\n")
                self.send("log", f"Estimated: {phase.estimate}\n")
                self.send("log", f"Shortcuts in UI: Stop ends the job, Skip moves to next phase.\n")
                self.send("log", f"============================================================\n")

                cmd = self._build_command(hashfile, phase, device_param, optimize)
                exit_code = self._run_process(cmd)

                if self.stop_requested:
                    status = "stopped"
                    break
                if self.skip_requested:
                    self.send("log", f"[SKIP] {phase.title} skipped by user.\n\n")
                    continue
                if exit_code not in (0, 1):
                    self.send("log", f"[WARN] {phase.title} ended with exit code {exit_code}. Continuing.\n\n")
                else:
                    self.send("log", f"[OK] {phase.title} finished.\n\n")

            if status == "completed":
                self.send("phase", "Checking results")
                result = self._show_results(hashfile)
                if result.strip():
                    self.send("log", "\n[FOUND]\n" + result + "\n")
                else:
                    self.send("log", "\n[INFO] No password found in this run.\n")

        except Exception as exc:
            status = "error"
            self.send("log", f"\n[ERROR] {exc}\n")
            self.send("error", str(exc))

        ended_at = time.time()
        history_item = {
            "name": hashfile.stem,
            "hashfile": str(hashfile),
            "status": status,
            "started": start_text,
            "finished": now_text(),
            "duration": format_duration(ended_at - started_at),
            "level": level,
            "device": device_mode,
            "result": result.strip(),
            "found": bool(result.strip()),
        }
        self.send("history", history_item)
        self.send("progress", (1, 1))
        self.send("status", status.capitalize())
        self.send("done", status)

    def _preflight(self, hashfile):
        if not HASHCAT_EXE.exists():
            raise FileNotFoundError("hashcat.exe not found. Put this UI file in the same folder as hashcat.exe.")
        if not hashfile.exists():
            raise FileNotFoundError(f"Input file not found: {hashfile}")
        if hashfile.suffix.lower() in (".cap", ".pcap"):
            raise ValueError("Hashcat needs .hc22000. Convert .cap/.pcap first at hashcat.net/cap2hashcat.")
        if hashfile.suffix.lower() != ".hc22000":
            raise ValueError("Please select a .hc22000 WPA/WPA2 hash file.")

    def _resolve_device(self, device_mode):
        if device_mode == "GPU":
            return ["-D", "2"], ["-O"], "GPU only"
        if device_mode == "CPU":
            return ["-D", "1"], [], "CPU only"

        self.send("phase", "Detecting device")
        self.send("log", "[INFO] Detecting available hashcat devices...\n")
        info = self._capture([str(HASHCAT_EXE), "-I"])
        has_gpu = any("Type" in line and "GPU" in line.upper() for line in info.splitlines())
        self.send("log", info + "\n")
        if has_gpu:
            return ["-D", "2"], ["-O"], "Auto: GPU detected"
        return ["-D", "1"], [], "Auto: CPU fallback"

    def _download_rockyou_if_needed(self):
        target = APP_DIR / "rockyou.txt"
        if target.exists():
            return
        self.send("log", "[INFO] rockyou.txt not found. Downloading...\n")
        try:
            urllib.request.urlretrieve(ROCKYOU_URL, target)
            self.send("log", "[OK] rockyou.txt downloaded.\n")
        except Exception as exc:
            self.send("log", f"[WARN] Download failed: {exc}. Dictionary phases will be skipped.\n")

    def _build_command(self, hashfile, phase, device_param, optimize):
        return [
            str(HASHCAT_EXE),
            "-m", "22000",
            "-a", phase.attack_mode,
            *optimize,
            "-w", "4",
            "--status",
            "--status-timer", "15",
            *device_param,
            str(hashfile),
            *phase.args,
        ]

    def _run_process(self, cmd):
        self.send("log", "[CMD] " + " ".join(f'"{part}"' if " " in part else part for part in cmd) + "\n\n")
        self.process = subprocess.Popen(
            cmd,
            cwd=str(APP_DIR),
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
            bufsize=1,
            creationflags=subprocess.CREATE_NO_WINDOW if hasattr(subprocess, "CREATE_NO_WINDOW") else 0,
        )
        assert self.process.stdout is not None
        for line in self.process.stdout:
            self.send("log", line)
        return self.process.wait()

    def _capture(self, cmd):
        completed = subprocess.run(
            cmd,
            cwd=str(APP_DIR),
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            creationflags=subprocess.CREATE_NO_WINDOW if hasattr(subprocess, "CREATE_NO_WINDOW") else 0,
        )
        output = (completed.stdout or "") + (completed.stderr or "")
        if completed.returncode not in (0, 1):
            raise RuntimeError(output.strip() or f"Command failed: {' '.join(cmd)}")
        return output

    def _show_results(self, hashfile):
        return self._capture([str(HASHCAT_EXE), "-m", "22000", "--show", str(hashfile)])


class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Hashcat Thai UI")
        self.geometry("1180x760")
        self.minsize(980, 640)
        self.configure(bg=COLORS["bg"])

        self.messages = queue.Queue()
        self.runner = HashcatRunner(lambda kind, payload: self.messages.put((kind, payload)))
        self.worker = None
        self.history = safe_read_json(HISTORY_FILE, [])
        self.current_page = "run"

        self.hashfile_var = tk.StringVar()
        self.device_var = tk.StringVar(value="Auto")
        self.level_var = tk.IntVar(value=2)
        self.download_var = tk.BooleanVar(value=True)
        self.search_var = tk.StringVar()
        self.status_var = tk.StringVar(value="Ready")
        self.phase_var = tk.StringVar(value="Choose a .hc22000 file to begin")

        self._setup_style()
        self._build_shell()
        self._show_page("run")
        self._refresh_history()
        self.after(100, self._poll_messages)

    def _setup_style(self):
        style = ttk.Style(self)
        style.theme_use("clam")
        style.configure(".", font=FONT, background=COLORS["bg"], foreground=COLORS["text"])
        style.configure("TFrame", background=COLORS["bg"])
        style.configure("Panel.TFrame", background=COLORS["panel"])
        style.configure("TLabel", background=COLORS["bg"], foreground=COLORS["text"])
        style.configure("Muted.TLabel", background=COLORS["bg"], foreground=COLORS["muted"], font=FONT_SM)
        style.configure("Panel.TLabel", background=COLORS["panel"], foreground=COLORS["text"])
        style.configure("PanelMuted.TLabel", background=COLORS["panel"], foreground=COLORS["muted"], font=FONT_SM)
        style.configure("Title.TLabel", background=COLORS["bg"], foreground=COLORS["text"], font=FONT_TITLE)
        style.configure("TEntry", fieldbackground=COLORS["panel_2"], foreground=COLORS["text"], bordercolor=COLORS["border"])
        style.configure("TCombobox", fieldbackground=COLORS["panel_2"], foreground=COLORS["text"])
        style.configure("TRadiobutton", background=COLORS["panel"], foreground=COLORS["text"], font=FONT)
        style.configure("TCheckbutton", background=COLORS["panel"], foreground=COLORS["text"], font=FONT)
        style.configure("Treeview", background=COLORS["panel"], fieldbackground=COLORS["panel"], foreground=COLORS["text"], rowheight=30, borderwidth=0)
        style.configure("Treeview.Heading", background=COLORS["panel_2"], foreground=COLORS["text"], font=FONT_MD)
        style.map("Treeview", background=[("selected", COLORS["blue_2"])], foreground=[("selected", "#ffffff")])
        style.configure("Horizontal.TProgressbar", troughcolor=COLORS["panel_2"], background=COLORS["blue"], bordercolor=COLORS["border"])

    def _build_shell(self):
        self.sidebar = tk.Frame(self, bg=COLORS["panel"], width=190)
        self.sidebar.pack(side="left", fill="y")
        self.sidebar.pack_propagate(False)

        tk.Label(self.sidebar, text="Hashcat Thai", bg=COLORS["panel"], fg=COLORS["text"], font=("Segoe UI Semibold", 16)).pack(anchor="w", padx=18, pady=(24, 2))
        tk.Label(self.sidebar, text="UI wrapper", bg=COLORS["panel"], fg=COLORS["muted"], font=FONT_SM).pack(anchor="w", padx=18, pady=(0, 24))

        self.nav_buttons = {}
        for key, text in (("run", "Input & Run"), ("completed", "Completed")):
            btn = tk.Button(
                self.sidebar,
                text=text,
                anchor="w",
                bd=0,
                padx=18,
                pady=12,
                font=FONT_MD,
                cursor="hand2",
                command=lambda page=key: self._show_page(page),
            )
            btn.pack(fill="x", padx=10, pady=4)
            self.nav_buttons[key] = btn

        tk.Label(
            self.sidebar,
            text="Use only on networks you own or have permission to test.",
            bg=COLORS["panel"],
            fg=COLORS["muted"],
            font=FONT_SM,
            wraplength=150,
            justify="left",
        ).pack(side="bottom", anchor="w", padx=18, pady=18)

        self.content = tk.Frame(self, bg=COLORS["bg"])
        self.content.pack(side="left", fill="both", expand=True)

        self.pages = {
            "run": self._build_run_page(),
            "completed": self._build_completed_page(),
        }

    def _panel(self, parent):
        return tk.Frame(parent, bg=COLORS["panel"], highlightbackground=COLORS["border"], highlightthickness=1)

    def _build_run_page(self):
        page = tk.Frame(self.content, bg=COLORS["bg"])
        header = tk.Frame(page, bg=COLORS["bg"])
        header.pack(fill="x", padx=28, pady=(26, 16))
        ttk.Label(header, text="Input & Run", style="Title.TLabel").pack(anchor="w")
        ttk.Label(header, text="เลือกไฟล์ .hc22000 ตั้งค่าระดับการค้นหา แล้วปล่อยให้ UI รัน phase ตาม batch เดิม", style="Muted.TLabel").pack(anchor="w", pady=(4, 0))

        body = tk.Frame(page, bg=COLORS["bg"])
        body.pack(fill="both", expand=True, padx=28, pady=(0, 24))
        body.columnconfigure(0, weight=0, minsize=370)
        body.columnconfigure(1, weight=1)
        body.rowconfigure(0, weight=1)

        controls = self._panel(body)
        controls.grid(row=0, column=0, sticky="nsew", padx=(0, 16))
        controls.columnconfigure(0, weight=1)

        ttk.Label(controls, text="Target file", style="Panel.TLabel", font=FONT_MD).grid(row=0, column=0, sticky="w", padx=18, pady=(18, 6))
        ttk.Label(controls, text="รองรับ WPA/WPA2 hash format .hc22000 เท่านั้น", style="PanelMuted.TLabel").grid(row=1, column=0, sticky="w", padx=18)

        file_row = tk.Frame(controls, bg=COLORS["panel"])
        file_row.grid(row=2, column=0, sticky="ew", padx=18, pady=(10, 18))
        file_row.columnconfigure(0, weight=1)
        ttk.Entry(file_row, textvariable=self.hashfile_var).grid(row=0, column=0, sticky="ew", ipady=6)
        self._button(file_row, "Browse", self._browse_file).grid(row=0, column=1, padx=(8, 0), ipady=5)

        ttk.Label(controls, text="Device", style="Panel.TLabel", font=FONT_MD).grid(row=3, column=0, sticky="w", padx=18, pady=(4, 8))
        self._radio_row(controls, self.device_var, [("Auto", "Recommended"), ("GPU", "Fast"), ("CPU", "Slow")]).grid(row=4, column=0, sticky="ew", padx=18)
        ttk.Label(controls, text="Auto จะเรียก hashcat.exe -I แล้วเลือก GPU ถ้าพบอุปกรณ์", style="PanelMuted.TLabel").grid(row=5, column=0, sticky="w", padx=18, pady=(8, 18))

        ttk.Label(controls, text="Attack level", style="Panel.TLabel", font=FONT_MD).grid(row=6, column=0, sticky="w", padx=18, pady=(0, 8))
        levels = [
            (1, "Fast", "Dictionary, birthdate, 8 digits, Thai mobile"),
            (2, "Standard", "Fast + rules and 9 digits"),
            (3, "Extended", "Standard + 10 digits"),
            (4, "Extreme", "Extended + 11-12 digits"),
        ]
        for row, (value, title, detail) in enumerate(levels, start=7):
            card = tk.Frame(controls, bg=COLORS["panel_2"], highlightbackground=COLORS["border"], highlightthickness=1)
            card.grid(row=row, column=0, sticky="ew", padx=18, pady=4)
            card.columnconfigure(1, weight=1)
            ttk.Radiobutton(card, value=value, variable=self.level_var).grid(row=0, column=0, padx=10, pady=10)
            tk.Label(card, text=title, bg=COLORS["panel_2"], fg=COLORS["text"], font=FONT_MD).grid(row=0, column=1, sticky="w", pady=(8, 0))
            tk.Label(card, text=detail, bg=COLORS["panel_2"], fg=COLORS["muted"], font=FONT_SM).grid(row=1, column=1, sticky="w", pady=(0, 8))

        ttk.Checkbutton(controls, text="Download rockyou.txt automatically if missing", variable=self.download_var).grid(row=11, column=0, sticky="w", padx=18, pady=(12, 0))

        actions = tk.Frame(controls, bg=COLORS["panel"])
        actions.grid(row=12, column=0, sticky="ew", padx=18, pady=18)
        actions.columnconfigure(0, weight=1)
        self.start_btn = self._button(actions, "Start", self._start_job, primary=True)
        self.start_btn.grid(row=0, column=0, sticky="ew", ipady=8)
        self.skip_btn = self._button(actions, "Skip Phase", self._skip_phase)
        self.skip_btn.grid(row=1, column=0, sticky="ew", pady=(8, 0), ipady=7)
        self.stop_btn = self._button(actions, "Stop", self._stop_job, danger=True)
        self.stop_btn.grid(row=2, column=0, sticky="ew", pady=(8, 0), ipady=7)
        self.skip_btn.configure(state="disabled")
        self.stop_btn.configure(state="disabled")

        log_panel = self._panel(body)
        log_panel.grid(row=0, column=1, sticky="nsew")
        log_panel.rowconfigure(3, weight=1)
        log_panel.columnconfigure(0, weight=1)

        status_row = tk.Frame(log_panel, bg=COLORS["panel"])
        status_row.grid(row=0, column=0, sticky="ew", padx=18, pady=(18, 8))
        status_row.columnconfigure(0, weight=1)
        tk.Label(status_row, textvariable=self.status_var, bg=COLORS["panel"], fg=COLORS["blue"], font=FONT_MD).grid(row=0, column=0, sticky="w")
        tk.Label(status_row, textvariable=self.phase_var, bg=COLORS["panel"], fg=COLORS["muted"], font=FONT_SM).grid(row=1, column=0, sticky="w", pady=(4, 0))
        self.progress = ttk.Progressbar(log_panel, style="Horizontal.TProgressbar", mode="determinate", maximum=1)
        self.progress.grid(row=1, column=0, sticky="ew", padx=18, pady=(0, 12))

        self.log_text = tk.Text(
            log_panel,
            bg="#0b0f14",
            fg=COLORS["text"],
            insertbackground=COLORS["text"],
            relief="flat",
            wrap="word",
            font=FONT_MONO,
            padx=14,
            pady=12,
        )
        self.log_text.grid(row=3, column=0, sticky="nsew", padx=18, pady=(0, 18))
        self.log_text.insert("end", "Ready. Place hashcat.exe beside this file, select .hc22000, then press Start.\n")
        self.log_text.configure(state="disabled")
        return page

    def _build_completed_page(self):
        page = tk.Frame(self.content, bg=COLORS["bg"])
        header = tk.Frame(page, bg=COLORS["bg"])
        header.pack(fill="x", padx=28, pady=(26, 16))
        ttk.Label(header, text="Completed", style="Title.TLabel").pack(anchor="w")
        ttk.Label(header, text="ประวัติงานที่จบแล้ว พร้อมค้นหาตามชื่อไฟล์และดูผลลัพธ์ที่ hashcat --show คืนมา", style="Muted.TLabel").pack(anchor="w", pady=(4, 0))

        body = tk.Frame(page, bg=COLORS["bg"])
        body.pack(fill="both", expand=True, padx=28, pady=(0, 24))
        body.columnconfigure(0, weight=3)
        body.columnconfigure(1, weight=2)
        body.rowconfigure(1, weight=1)

        search_row = tk.Frame(body, bg=COLORS["bg"])
        search_row.grid(row=0, column=0, columnspan=2, sticky="ew", pady=(0, 12))
        search_row.columnconfigure(0, weight=1)
        entry = ttk.Entry(search_row, textvariable=self.search_var)
        entry.grid(row=0, column=0, sticky="ew", ipady=7)
        entry.insert(0, "")
        self.search_var.trace_add("write", lambda *_: self._refresh_history())
        self._button(search_row, "Clear", lambda: self.search_var.set("")).grid(row=0, column=1, padx=(8, 0), ipady=6)

        table_panel = self._panel(body)
        table_panel.grid(row=1, column=0, sticky="nsew", padx=(0, 16))
        table_panel.rowconfigure(0, weight=1)
        table_panel.columnconfigure(0, weight=1)
        columns = ("name", "status", "found", "finished", "duration")
        self.history_tree = ttk.Treeview(table_panel, columns=columns, show="headings")
        for col, text, width in [
            ("name", "Name", 190),
            ("status", "Status", 100),
            ("found", "Result", 90),
            ("finished", "Finished", 160),
            ("duration", "Duration", 100),
        ]:
            self.history_tree.heading(col, text=text)
            self.history_tree.column(col, width=width, minwidth=70)
        self.history_tree.grid(row=0, column=0, sticky="nsew", padx=14, pady=14)
        self.history_tree.bind("<<TreeviewSelect>>", lambda _event: self._show_history_detail())

        detail_panel = self._panel(body)
        detail_panel.grid(row=1, column=1, sticky="nsew")
        detail_panel.rowconfigure(1, weight=1)
        detail_panel.columnconfigure(0, weight=1)
        tk.Label(detail_panel, text="Details", bg=COLORS["panel"], fg=COLORS["text"], font=FONT_MD).grid(row=0, column=0, sticky="w", padx=18, pady=(18, 8))
        self.detail_text = tk.Text(detail_panel, bg="#0b0f14", fg=COLORS["text"], relief="flat", wrap="word", font=FONT_MONO, padx=14, pady=12)
        self.detail_text.grid(row=1, column=0, sticky="nsew", padx=18, pady=(0, 18))
        self.detail_text.configure(state="disabled")
        return page

    def _radio_row(self, parent, variable, items):
        row = tk.Frame(parent, bg=COLORS["panel"])
        for idx, (value, hint) in enumerate(items):
            box = tk.Frame(row, bg=COLORS["panel_2"], highlightbackground=COLORS["border"], highlightthickness=1)
            box.grid(row=0, column=idx, sticky="ew", padx=(0 if idx == 0 else 8, 0))
            row.columnconfigure(idx, weight=1)
            ttk.Radiobutton(box, text=value, value=value, variable=variable).pack(anchor="w", padx=10, pady=(8, 0))
            tk.Label(box, text=hint, bg=COLORS["panel_2"], fg=COLORS["muted"], font=FONT_SM).pack(anchor="w", padx=34, pady=(0, 8))
        return row

    def _button(self, parent, text, command, primary=False, danger=False):
        bg = COLORS["blue_2"] if primary else COLORS["panel_2"]
        active = COLORS["blue"] if primary else "#263244"
        if danger:
            bg = "#3a1f24"
            active = "#57272e"
        return tk.Button(
            parent,
            text=text,
            command=command,
            bg=bg,
            fg="#ffffff" if primary or danger else COLORS["text"],
            activebackground=active,
            activeforeground="#ffffff",
            bd=0,
            padx=12,
            pady=8,
            font=FONT_MD,
            cursor="hand2",
        )

    def _show_page(self, page):
        self.current_page = page
        for child in self.content.winfo_children():
            child.pack_forget()
        self.pages[page].pack(fill="both", expand=True)
        for key, btn in self.nav_buttons.items():
            active = key == page
            btn.configure(
                bg=COLORS["blue_2"] if active else COLORS["panel"],
                fg="#ffffff" if active else COLORS["muted"],
                activebackground=COLORS["blue_2"] if active else COLORS["panel_2"],
                activeforeground="#ffffff",
            )

    def _browse_file(self):
        path = filedialog.askopenfilename(
            title="Select .hc22000 file",
            filetypes=[("Hashcat WPA/WPA2", "*.hc22000"), ("All files", "*.*")],
        )
        if path:
            self.hashfile_var.set(path)

    def _start_job(self):
        hashfile = self.hashfile_var.get().strip().strip('"')
        if not hashfile:
            messagebox.showerror("Missing file", "Please select a .hc22000 file first.")
            return
        suffix = Path(hashfile).suffix.lower()
        if suffix in (".cap", ".pcap"):
            if messagebox.askyesno("Wrong format", "Hashcat needs .hc22000. Open cap2hashcat converter?"):
                webbrowser.open(CAP2HASHCAT_URL)
            return

        self._clear_log()
        self.status_var.set("Starting")
        self.phase_var.set("Preparing")
        self.progress.configure(value=0, maximum=1)
        self.start_btn.configure(state="disabled")
        self.skip_btn.configure(state="normal")
        self.stop_btn.configure(state="normal")

        settings = {
            "hashfile": hashfile,
            "device": self.device_var.get(),
            "level": self.level_var.get(),
            "download_rockyou": self.download_var.get(),
        }
        self.worker = threading.Thread(target=self.runner.run_job, args=(settings,), daemon=True)
        self.worker.start()

    def _stop_job(self):
        self.status_var.set("Stopping")
        self.runner.stop()

    def _skip_phase(self):
        self.phase_var.set("Skipping current phase")
        self.runner.skip()

    def _poll_messages(self):
        try:
            while True:
                kind, payload = self.messages.get_nowait()
                if kind == "log":
                    self._append_log(payload)
                elif kind == "status":
                    self.status_var.set(payload)
                elif kind == "phase":
                    self.phase_var.set(payload)
                elif kind == "progress":
                    value, maximum = payload
                    self.progress.configure(maximum=max(1, maximum), value=value)
                elif kind == "history":
                    self.history.insert(0, payload)
                    self.history = self.history[:200]
                    safe_write_json(HISTORY_FILE, self.history)
                    self._refresh_history()
                elif kind == "error":
                    if "cap2hashcat" in payload:
                        if messagebox.askyesno("Wrong format", payload + "\n\nOpen converter website?"):
                            webbrowser.open(CAP2HASHCAT_URL)
                    else:
                        messagebox.showerror("Hashcat UI", payload)
                elif kind == "done":
                    self.start_btn.configure(state="normal")
                    self.skip_btn.configure(state="disabled")
                    self.stop_btn.configure(state="disabled")
        except queue.Empty:
            pass
        self.after(100, self._poll_messages)

    def _append_log(self, text):
        self.log_text.configure(state="normal")
        self.log_text.insert("end", text)
        self.log_text.see("end")
        self.log_text.configure(state="disabled")

    def _clear_log(self):
        self.log_text.configure(state="normal")
        self.log_text.delete("1.0", "end")
        self.log_text.configure(state="disabled")

    def _refresh_history(self):
        if not hasattr(self, "history_tree"):
            return
        term = self.search_var.get().strip().lower()
        self.history_tree.delete(*self.history_tree.get_children())
        for idx, item in enumerate(self.history):
            name = item.get("name", "")
            if term and term not in name.lower():
                continue
            found_text = "Found" if item.get("found") else "None"
            self.history_tree.insert(
                "",
                "end",
                iid=str(idx),
                values=(name, item.get("status", ""), found_text, item.get("finished", ""), item.get("duration", "")),
            )

    def _show_history_detail(self):
        selected = self.history_tree.selection()
        if not selected:
            return
        item = self.history[int(selected[0])]
        lines = [
            f"Name: {item.get('name', '')}",
            f"Status: {item.get('status', '')}",
            f"File: {item.get('hashfile', '')}",
            f"Started: {item.get('started', '')}",
            f"Finished: {item.get('finished', '')}",
            f"Duration: {item.get('duration', '')}",
            f"Device: {item.get('device', '')}",
            f"Attack level: {item.get('level', '')}",
            "",
            "Result:",
            item.get("result", "") or "No password found.",
        ]
        self.detail_text.configure(state="normal")
        self.detail_text.delete("1.0", "end")
        self.detail_text.insert("end", "\n".join(lines))
        self.detail_text.configure(state="disabled")


if __name__ == "__main__":
    App().mainloop()
