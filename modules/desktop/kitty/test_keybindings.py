"""Wayland smoke test: real key events in a disposable Kitty, never the user's shell.

Usage: kitty +launch test_keybindings.py --wtype /path/to/wtype [--config kitty.conf]
Requires a running niri session. Restores focus and closes only its own window.
"""

import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time


def wait_for(function, description, timeout=8):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        result = function()
        if result:
            return result
        time.sleep(0.05)
    raise AssertionError(f"Timed out: {description}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--wtype", required=True)
    parser.add_argument("--config", default=str(Path.home() / ".config/kitty/kitty.conf"))
    args = parser.parse_args()
    previous = json.loads(subprocess.check_output(["niri", "msg", "--json", "focused-window"]))
    env = dict(os.environ)
    for name in ("KITTY_LISTEN_ON", "KITTY_WINDOW_ID", "KITTY_PID"):
        env.pop(name, None)
    with tempfile.TemporaryDirectory(prefix="kitty-keybinding-test-") as directory:
        endpoint = f"unix:{directory}/control.sock"
        with open(Path(directory) / "kitty.log", "w+") as log:
            process = subprocess.Popen(
                [
                    "kitty", "--config", args.config,
                    "--override", "allow_remote_control=socket-only",
                    "--listen-on", endpoint, "--class", "kitty-keybinding-test",
                    "--title", "Kitty shortcut test", "sh", "-c", "sleep 120",
                ],
                env=env, stdout=log, stderr=log,
            )

            def remote(*arguments):
                return subprocess.check_output(
                    ["kitten", "@", "--to", endpoint, *arguments],
                    env=env, stderr=subprocess.DEVNULL, text=True,
                ).strip()

            def tab():
                return json.loads(remote("ls"))[0]["tabs"][0]

            def active():
                return next(w["id"] for w in tab()["windows"] if w["is_active"])

            def key(letter, *modifiers):
                # Focus only the test OS window before sending any synthetic key.
                remote("focus-window", "--match", f"id:{active()}")
                time.sleep(0.15)
                command = [args.wtype]
                for modifier in modifiers:
                    command += ["-M", modifier]
                command += ["-k", letter]
                for modifier in reversed(modifiers):
                    command += ["-m", modifier]
                subprocess.run(command, check=True)
                time.sleep(0.15)

            def expect_key(letter, target, *modifiers):
                key(letter, *modifiers)
                wait_for(lambda: active() == target, f"{'+'.join((*modifiers, letter))} focuses {target}")
                print(f"PASS {'+'.join((*modifiers, letter))} -> window {target}", flush=True)

            try:
                wait_for(lambda: Path(directory, "control.sock").exists(), "Kitty IPC socket")
                wait_for(lambda: bool(tab()["windows"]), "Kitty window")
                left = active()
                key("O", "ctrl", "shift")
                wait_for(lambda: len(tab()["windows"]) == 2, "Ctrl+Shift+O creates a split")
                right = active()
                expect_key("h", left, "ctrl", "alt")
                expect_key("l", right, "ctrl", "alt")
                key("E", "ctrl", "shift")
                wait_for(lambda: len(tab()["windows"]) == 3, "Ctrl+Shift+E creates a split")
                bottom = active()
                expect_key("k", right, "ctrl", "alt")
                expect_key("j", bottom, "ctrl", "alt")
                expect_key("Up", right, "ctrl", "alt")
                expect_key("Down", bottom, "ctrl", "alt")
                expect_key("Left", left, "ctrl", "alt")
                expect_key("Right", bottom, "ctrl", "alt")
                expect_key("Tab", left, "ctrl", "alt")
                remote("focus-window", "--match", f"id:{bottom}")
                key("Return", "ctrl", "shift")
                wait_for(lambda: tab()["layout"] == "stack", "stack layout")
                expect_key("k", right, "ctrl", "alt")
                assert tab()["layout"] == "splits", "directional navigation must reveal hidden splits"
                key("Return", "ctrl", "shift")
                assert tab()["layout"] == "stack"
                key("O", "ctrl", "shift")
                wait_for(lambda: len(tab()["windows"]) == 4, "split creation from stack")
                assert tab()["layout"] == "splits", "new splits must be visible, not hidden in stack"
                print("PASS stack navigation and split creation restore splits", flush=True)
            except Exception:
                log.seek(0)
                print(log.read())
                raise
            finally:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
                if previous:
                    subprocess.run(
                        ["niri", "msg", "action", "focus-window", "--id", str(previous["id"])],
                        check=False, stdout=subprocess.DEVNULL,
                    )


if __name__ == "__main__":
    main()
