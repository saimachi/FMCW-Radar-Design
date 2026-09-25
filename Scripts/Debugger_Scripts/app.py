import os
import queue
import subprocess
import threading
import time
from flask import Flask, redirect, render_template, request, url_for

app = Flask(__name__)

GDB_EXECUTABLE = r"C:\ST\STM32CubeIDE_1.19.0\STM32CubeIDE\plugins\com.st.stm32cube.ide.mcu.externaltools.gnu-tools-for-stm32.13.3.rel1.win32_1.0.0.202411081344\tools\bin\arm-none-eabi-gdb.exe"
ELF_PATH = r"C:\Personal\FMCW-Radar-Design\FMCW-Radar-v1\Firmware\Debug\FMCW_Radar.elf"
BREAKPOINT_LOCATION = "main.c:206"
GDB_VARIABLE = "outputString"
GDB_PROMPT = b"(gdb) "

acq_state = {
    "running": False,
    "current_count": 0,
    "total_count": 0,
    "status": "idle",
    "error": "",
}
acq_lock = threading.Lock()


class GdbSession:
    """Drives a GDB subprocess via stdin/stdout, waiting on the (gdb) prompt."""

    def __init__(self, executable):
        self.proc = subprocess.Popen(
            [executable, "--quiet"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            bufsize=0,
        )
        self._q = queue.Queue()
        threading.Thread(target=self._reader, daemon=True).start()
        self._wait_prompt(timeout=10)   # consume startup banner

    def _reader(self):
        while True:
            byte = self.proc.stdout.read(1)
            if not byte:
                break
            self._q.put(byte)

    def _wait_prompt(self, timeout=60):
        """Accumulate bytes until the buffer ends with '(gdb) '."""
        buf = b""
        deadline = time.time() + timeout
        while time.time() < deadline:
            try:
                buf += self._q.get(timeout=0.5)
            except queue.Empty:
                continue
            if buf.endswith(GDB_PROMPT):
                output = buf[: -len(GDB_PROMPT)].decode(errors="replace")
                print(f"[GDB] {output.strip()}")
                return output
        raise RuntimeError(
            f"GDB prompt not seen within {timeout}s. "
            f"Last output: {buf.decode(errors='replace')!r}"
        )

    def send(self, cmd, timeout=60):
        print(f"[GDB >>>] {cmd}")
        self.proc.stdin.write((cmd + "\n").encode())
        self.proc.stdin.flush()
        return self._wait_prompt(timeout=timeout)

    def exit(self):
        try:
            self.proc.stdin.write(b"quit\n")
            self.proc.stdin.flush()
            self.proc.wait(timeout=5)
        except Exception:
            self.proc.kill()


def _gdb_path(windows_path):
    """Convert Windows backslashes to forward slashes for GDB."""
    return windows_path.replace("\\", "/")


def gdb_worker(total_count, base_path, base_filename):
    global acq_state
    gdb = None
    try:
        gdb = GdbSession(GDB_EXECUTABLE)

        gdb.send("set confirm off")
        gdb.send("target remote :3333", timeout=15)
        gdb.send(f'file "{_gdb_path(ELF_PATH)}"', timeout=15)
        gdb.send(f"break {BREAKPOINT_LOCATION}")

        for i in range(1, total_count + 1):
            with acq_lock:
                if not acq_state["running"]:
                    break

            print(f"[ACQ] {i}/{total_count} — continuing target")
            gdb.send("continue", timeout=180)

            dump_path = os.path.join(base_path, f"{base_filename}_{i}.hex")
            gdb.send(f"dump binary value {_gdb_path(dump_path)} {GDB_VARIABLE}")

            with acq_lock:
                acq_state["current_count"] = i

        with acq_lock:
            acq_state["running"] = False
            acq_state["status"] = "done"

    except Exception as exc:
        with acq_lock:
            acq_state["running"] = False
            acq_state["status"] = "error"
            acq_state["error"] = str(exc)


@app.route("/", methods=["GET"])
def index():
    with acq_lock:
        state = dict(acq_state)
    return render_template("index.html", state=state)


@app.route("/start", methods=["POST"])
def start():
    global acq_state

    try:
        total_count = int(request.form.get("total_count", 1))
    except ValueError:
        total_count = 1

    base_path = request.form.get("base_path", "").strip()
    base_filename = request.form.get("base_filename", "").strip()

    with acq_lock:
        if acq_state["running"]:
            return redirect(url_for("index"))

        acq_state = {
            "running": True,
            "current_count": 0,
            "total_count": total_count,
            "status": "running",
            "error": "",
        }

    threading.Thread(
        target=gdb_worker,
        args=(total_count, base_path, base_filename),
        daemon=True,
    ).start()

    return redirect(url_for("index"))


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
