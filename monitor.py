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
LOG_FILE = "/var/logs/Essensys/backend/console.out.log"
SERVICES = [
    {"name": "Backend", "service": "essensys-backend", "key": "b"},
    {"name": "Frontend", "service": "nginx", "key": "f"},
    {"name": "Traefik", "service": "traefik", "key": "t"}
]
REFRESH_RATE = 1.0  # seconds

class SystemMonitor:
    def __init__(self):
        self.cpu_prev = self._read_cpu_stats()
        self.log_buffer = deque(maxlen=100)
        self.log_lock = threading.Lock()
        self.running = True
        
        # Start log reader thread
        self.log_thread = threading.Thread(target=self._tail_log, daemon=True)
        self.log_thread.start()

    def _read_cpu_stats(self):
        try:
            with open('/proc/stat', 'r') as f:
                line = f.readline()
                if line.startswith('cpu '):
                    parts = line.split()
                    # user, nice, system, idle, iowait
                    return [int(x) for x in parts[1:6]]
        except:
            return None
        return None

    def get_cpu_usage(self):
        curr = self._read_cpu_stats()
        if not curr or not self.cpu_prev:
            self.cpu_prev = curr
            return 0.0
        
        # Calculate diffs
        # user+nice+system+idle+iowait
        prev_sum = sum(self.cpu_prev)
        curr_sum = sum(curr)
        
        # idle is index 3, iowait is index 4 (if present, usually yes for linux 2.6+)
        # idle time = idle + iowait
        prev_idle = self.cpu_prev[3]
        curr_idle = curr[3]
        if len(self.cpu_prev) > 4:
            prev_idle += self.cpu_prev[4]
            curr_idle += curr[4]
            
        diff_total = curr_sum - prev_sum
        diff_idle = curr_idle - prev_idle
        
        self.cpu_prev = curr
        
        if diff_total == 0: return 0.0
        return 100.0 * (diff_total - diff_idle) / diff_total

    def get_mem_usage(self):
        try:
            mem = {}
            with open('/proc/meminfo', 'r') as f:
                for line in f:
                    parts = line.split(':')
                    if len(parts) == 2:
                        key = parts[0].strip()
                        val = int(parts[1].split()[0]) # kB
                        mem[key] = val
            
            total = mem.get('MemTotal', 1)
            avail = mem.get('MemAvailable', mem.get('MemFree', 0)) # Fallback if MemAvailable missing
            used = total - avail
            return (used / total) * 100.0, used/1024, total/1024
        except:
            return 0.0, 0, 0

    def get_client_count(self):
        # Count established connections on ports 80, 443, 7070
        # Using ss is cleaner and faster than netstat
        cmd = "ss -tun state established '( dport = :80 or dport = :443 or dport = :7070 )' | wc -l"
        try:
            output = subprocess.check_output(cmd, shell=True)
            count = int(output.strip())
            # ss output includes header line if not empty, but 'wc -l' counts lines.
            # ss header: "Netid Recv-Q Send-Q Local Address:Port Peer Address:Port Process"
            # However, 'state established' might filter. 
            # Ideally verify output. For now, assuming count - 1 if header exists?
            # Actually easier: just count lines. If 0 lines, 0 clients. If 1 line (header?), 0 clients.
            # Let's use grep -v to skip header just in case.
            cmd2 = "ss -tnH state established '( dport = :80 or dport = :443 or dport = :7070 )' | wc -l"
            output = subprocess.check_output(cmd2, shell=True)
            return int(output.strip())
        except:
            return 0

    def get_service_status(self, service_name):
        try:
            ret = subprocess.call(["systemctl", "is-active", "--quiet", service_name])
            return ret == 0
        except:
            return False

    def restart_service(self, service_name):
        def _restart():
            subprocess.call(["sudo", "systemctl", "restart", service_name])
        
        t = threading.Thread(target=_restart)
        t.start()

    def _tail_log(self):
        if not os.path.exists(LOG_FILE):
             with self.log_lock:
                 self.log_buffer.append(f"Log file not found: {LOG_FILE}")
             # Wait for file to appear
             while not os.path.exists(LOG_FILE) and self.running:
                 time.sleep(2)
        
        try:
            cmd = ['tail', '-F', '-n', '20', LOG_FILE]
            process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, bufsize=1)
            
            while self.running:
                line = process.stdout.readline()
                if not line:
                    break
                with self.log_lock:
                    self.log_buffer.append(line.strip())
        except Exception as e:
            with self.log_lock:
                self.log_buffer.append(f"Error reading logs: {str(e)}")

    def stop(self):
        self.running = False


def draw_centered(stdscr, y, text, attr=0):
    h, w = stdscr.getmaxyx()
    x = max(0, (w - len(text)) // 2)
    try:
        stdscr.addstr(y, x, text, attr)
    except:
        pass

def main(stdscr):
    # Setup curses
    curses.start_color()
    curses.use_default_colors()
    curses.init_pair(1, curses.COLOR_GREEN, -1)   # Status OK
    curses.init_pair(2, curses.COLOR_RED, -1)     # Status Error/Inactive
    curses.init_pair(3, curses.COLOR_CYAN, -1)    # Header
    curses.init_pair(4, curses.COLOR_YELLOW, -1)  # Warnings/Info
    
    stdscr.nodelay(True) # Non-blocking input
    stdscr.timeout(1000) # Refresh every 1s if no input
    curses.curs_set(0)   # Hide cursor

    monitor = SystemMonitor()
    
    # Store last restart times to show feedback
    last_restart_msg = ""
    last_restart_time = 0

    try:
        while True:
            stdscr.erase()
            h, w = stdscr.getmaxyx()
            
            # --- Header ---
            hostname = os.uname()[1]
            try:
                ip = subprocess.check_output(['hostname', '-I']).decode().strip().split()[0]
            except:
                ip = "?"
            
            header = f"ESSENSYS RASPBERRY PI MONITOR - {hostname} ({ip})"
            draw_centered(stdscr, 0, header, curses.color_pair(3) | curses.A_BOLD)
            stdscr.hline(1, 0, curses.ACS_HLINE, w)
            
            # --- Stats ---
            cpu_pct = monitor.get_cpu_usage()
            mem_pct, mem_used, mem_total = monitor.get_mem_usage()
            clients = monitor.get_client_count()
            
            stats_str = f"CPU: {cpu_pct:.1f}% | MEM: {mem_pct:.1f}% ({int(mem_used)}/{int(mem_total)} MB) | CLIENTS: {clients}"
            draw_centered(stdscr, 2, stats_str)
            stdscr.hline(3, 0, curses.ACS_HLINE, w)

            # --- Services ---
            # Calculate layout
            col_width = w // len(SERVICES)
            for i, service in enumerate(SERVICES):
                status = monitor.get_service_status(service['service'])
                color = curses.color_pair(1) if status else curses.color_pair(2)
                status_txt = "ACTIVE" if status else "INACTIVE"
                
                # Draw Box
                bx = i * col_width
                # content
                try:
                    stdscr.addstr(4, bx + 2, f"{service['name']}", curses.A_BOLD)
                    stdscr.addstr(5, bx + 2, f"Status: {status_txt}", color)
                    stdscr.addstr(6, bx + 2, f"Restart: Press '{service['key']}'")
                except:
                    pass

            stdscr.hline(7, 0, curses.ACS_HLINE, w)
            stdscr.addstr(7, 2, " LOGS (tail -f) ", curses.color_pair(3))

            # --- Logs ---
            log_h = h - 9
            if log_h > 0:
                with monitor.log_lock:
                    logs = list(monitor.log_buffer)[-log_h:]
                
                for i, line in enumerate(logs):
                    try:
                        stdscr.addstr(8 + i, 1, line[:w-2])
                    except:
                        pass
            
            # --- Status Bar ---
            if time.time() - last_restart_time < 3:
                stdscr.addstr(h-1, 0, last_restart_msg, curses.color_pair(4) | curses.A_REVERSE)
            else:
                stdscr.addstr(h-1, 0, "Press 'q' to quit | Commands: 'b' Backend, 'f' Frontend, 't' Traefik", curses.color_pair(3))

            # --- Input Handling ---
            key = stdscr.getch()
            if key == ord('q'):
                break
            elif key == ord('b'):
                monitor.restart_service("essensys-backend")
                last_restart_msg = "Restarting Backend..."
                last_restart_time = time.time()
            elif key == ord('f'):
                monitor.restart_service("nginx")
                last_restart_msg = "Restarting Frontend (Nginx)..."
                last_restart_time = time.time()
            elif key == ord('t'):
                monitor.restart_service("traefik")
                last_restart_msg = "Restarting Traefik..."
                last_restart_time = time.time()

            stdscr.refresh()
            
    except KeyboardInterrupt:
        pass
    finally:
        monitor.stop()

if __name__ == '__main__':
    # Ensure terminal size is sufficient
    # Set ESC delay to 0 to avoid lag
    os.environ.setdefault('ESCDELAY', '25')
    curses.wrapper(main)
