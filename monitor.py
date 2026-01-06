#!/usr/bin/env python3
import curses
import time
import subprocess
import threading
import os
import sys
from collections import deque
import re

# Configuration
LOG_FILES = [
    ("/var/logs/Essensys/backend/console.out.log", "Backend"),
    ("/var/log/traefik/traefik-error.log", "Traefik"),
    ("/var/log/nginx/essensys-api-error.log", "Nginx")
]

class SystemMonitor:
    def __init__(self):
        # Separate buffers for each source
        self.log_buffers = {
            "Backend": deque(maxlen=200),
            "Traefik": deque(maxlen=200),
            "Nginx": deque(maxlen=200)
        }
        self.log_lock = threading.Lock()
        self.running = True
        
        # Start log reader thread
        self.log_thread = threading.Thread(target=self._tail_log, daemon=True)
        self.log_thread.start()

    def prompt_login(self, stdscr):
        self.running = False
        stdscr.clear()
        stdscr.refresh()
        curses.endwin()
        os.execl("/bin/login", "login")

    def _tail_log(self):
        file_map = {f[0]: f[1] for f in LOG_FILES}
        files_to_tail = [f[0] for f in LOG_FILES]
        current_source = "Backend" # Default

        try:
            cmd = ['tail', '-F', '-n', '20'] + files_to_tail
            process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, bufsize=1)
            
            while self.running:
                line = process.stdout.readline()
                if not line:
                    break
                
                line = line.strip()
                if not line: continue

                header_match = re.match(r'^==> (.+) <==$', line)
                if header_match:
                    fname = header_match.group(1)
                    current_source = file_map.get(fname, "Backend") # Fallback to Backend if unknown
                    continue
                
                with self.log_lock:
                    if current_source in self.log_buffers:
                        self.log_buffers[current_source].append(line)
                    else:
                        self.log_buffers["Backend"].append(f"[{current_source}] {line}")
                    
        except Exception as e:
            with self.log_lock:
                self.log_buffers["Backend"].append(f"Error reading logs: {str(e)}")

    def stop(self):
        self.running = False

def draw_centered(stdscr, y, text, attr=0):
    h, w = stdscr.getmaxyx()
    x = max(0, (w - len(text)) // 2)
    try:
        stdscr.addstr(y, x, text, attr)
    except:
        pass

def draw_box(stdscr, y, x, h, w, title, logs, color):
    # Draw simple box borders if possible, or just background
    # y, x is top-left
    # h, w is size
    
    # Check bounds
    max_y, max_x = stdscr.getmaxyx()
    if y >= max_y or x >= max_x: return
    h = min(h, max_y - y)
    w = min(w, max_x - x)
    
    # Draw Header
    header = f" {title} "
    try:
        stdscr.addstr(y, x, header[:w], color | curses.A_BOLD | curses.A_REVERSE)
        # Fill rest of header line
        if len(header) < w:
            stdscr.addstr(y, x + len(header), " " * (w - len(header)), color | curses.A_REVERSE)
            
        # Draw logs
        content_h = h - 1
        visible_logs = list(logs)[-content_h:]
        for i, line in enumerate(visible_logs):
            if y + 1 + i < max_y:
                stdscr.addstr(y + 1 + i, x, line[:w])
                
    except:
        pass

def main(stdscr):
    # Setup curses
    curses.start_color()
    curses.use_default_colors()
    curses.init_pair(3, curses.COLOR_CYAN, -1)    # Header
    curses.init_pair(5, curses.COLOR_WHITE, curses.COLOR_BLUE) # Focused/Box Header
    
    stdscr.nodelay(True)
    stdscr.timeout(500)
    curses.curs_set(0)

    monitor = SystemMonitor()
    
    # View State: 0=All, 1=Backend, 2=Traefik, 3=Nginx
    view_mode = 0 
    VIEW_NAMES = {0: "Overview", 1: "Backend", 2: "Traefik", 3: "Nginx"}

    try:
        while True:
            stdscr.erase()
            h, w = stdscr.getmaxyx()
            
            # --- Header ---
            hostname = os.uname()[1]
            header = f"ESSENSYS PI MONITOR - {VIEW_NAMES[view_mode]} View"
            draw_centered(stdscr, 0, header, curses.color_pair(3) | curses.A_BOLD)
            stdscr.hline(1, 0, curses.ACS_HLINE, w)
            
            # --- Logs Section ---
            log_start_y = 2
            log_area_h = h - log_start_y - 2 # Reserve bottom for hints
            
            if log_area_h > 0:
                with monitor.log_lock:
                    if view_mode == 0:
                        if w > 120:
                            # 3 Columns
                            col_w = w // 3
                            draw_box(stdscr, log_start_y, 0, log_area_h, col_w-1, "Backend", monitor.log_buffers["Backend"], curses.color_pair(5))
                            draw_box(stdscr, log_start_y, col_w, log_area_h, col_w-1, "Traefik", monitor.log_buffers["Traefik"], curses.color_pair(5))
                            draw_box(stdscr, log_start_y, col_w*2, log_area_h, col_w-1, "Nginx", monitor.log_buffers["Nginx"], curses.color_pair(5))
                        else:
                            # 3 Stacked Rows
                            row_h = log_area_h // 3
                            draw_box(stdscr, log_start_y, 0, row_h, w, "Backend", monitor.log_buffers["Backend"], curses.color_pair(5))
                            draw_box(stdscr, log_start_y + row_h, 0, row_h, w, "Traefik", monitor.log_buffers["Traefik"], curses.color_pair(5))
                            draw_box(stdscr, log_start_y + row_h*2, 0, log_area_h - row_h*2, w, "Nginx", monitor.log_buffers["Nginx"], curses.color_pair(5))
                    
                    elif view_mode == 1:
                        draw_box(stdscr, log_start_y, 0, log_area_h, w, "Backend (Maximized)", monitor.log_buffers["Backend"], curses.color_pair(5))
                    elif view_mode == 2:
                        draw_box(stdscr, log_start_y, 0, log_area_h, w, "Traefik (Maximized)", monitor.log_buffers["Traefik"], curses.color_pair(5))
                    elif view_mode == 3:
                        draw_box(stdscr, log_start_y, 0, log_area_h, w, "Nginx (Maximized)", monitor.log_buffers["Nginx"], curses.color_pair(5))

            # --- Status Bar ---
            cmds = "1:Backend 2:Traefik 3:Nginx 0:All | q:Logoff"
            stdscr.addstr(h-1, 0, cmds[:w-1], curses.color_pair(3))

            # --- Input ---
            key = stdscr.getch()
            if key == ord('q'):
                monitor.prompt_login(stdscr)
                break
            elif key == ord('0') or key == 27: # 27 is ESC
                view_mode = 0
            elif key == ord('1'):
                view_mode = 1
            elif key == ord('2'):
                view_mode = 2
            elif key == ord('3'):
                view_mode = 3

            stdscr.refresh()
            
    except KeyboardInterrupt:
        pass
    finally:
        monitor.stop()

if __name__ == '__main__':
    os.environ.setdefault('ESCDELAY', '25')
    curses.wrapper(main)
