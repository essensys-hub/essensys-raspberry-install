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
    {"name": "Traefik", "service": "traefik", "key": "t"},
    {"name": "AdGuard", "service": "AdGuardHome", "key": "a"}
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

        # Cache for disk stats
        self.last_disk_check = 0
        self.cached_disk_usage = (0, 0, 0)
        self.cached_logs_size = 0

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

    def update_disk_stats(self):
        # Update every 120 seconds
        if time.time() - self.last_disk_check > 120:
            self.cached_disk_usage = self._get_disk_usage('/')
            self.cached_logs_size = self._get_dir_size('/var/logs') if os.path.exists('/var/logs') else self._get_dir_size('/var/log')
            self.last_disk_check = time.time()

    def get_mac_address(self, interface):
        try:
            path = f"/sys/class/net/{interface}/address"
            if os.path.exists(path):
                with open(path, 'r') as f:
                    return f.read().strip()
        except:
            pass
        return "N/A"

    def _get_disk_usage(self, path):
        try:
            st = os.statvfs(path)
            total = st.f_blocks * st.f_frsize
            used = (st.f_blocks - st.f_bfree) * st.f_frsize
            return used, total, (used/total)*100
        except:
            return 0, 0, 0

    def _get_dir_size(self, path):
        try:
            # Using du -sb for bytes (recursive)
            # busybox du might not support -b, using -s with block size 1k?
            # Standard linux du supports -b or -k. Let's try -sk (kb) for compatibility
            cmd = ['du', '-sk', path]
            output = subprocess.check_output(cmd, stderr=subprocess.DEVNULL).decode().split()[0]
            return int(output) * 1024 # Convert KB to bytes
        except:
            return 0

    def reboot_system(self):
        def _reboot():
            time.sleep(1) # Visual feedback delay
            subprocess.call(["sudo", "reboot"])
        
        t = threading.Thread(target=_reboot)
        t.start()
        return "Rebooting system..."

    def prompt_login(self, stdscr):
        # We want to exit monitor and execute login
        # This will replace the current process
        self.running = False
        stdscr.clear()
        stdscr.refresh()
        curses.endwin()
        os.execl("/bin/login", "login")

    def open_raspi_config(self, stdscr):
        curses.def_prog_mode() # Save curses state
        curses.endwin()        # Restore terminal
        try:
            subprocess.call(["sudo", "raspi-config"])
        except Exception as e:
            print(f"Error launching raspi-config: {e}")
            time.sleep(2)
        curses.reset_prog_mode() # Restore curses state
        stdscr.refresh()

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
                # Non-blocking read needed or select? 
                # Actually readline is blocking. We can use select to timeout.
                # But since this is a thread, blocking is fine as long as we can kill it?
                # subprocess doesn't die easily.
                # Let's just use it. When self.running becomes False, we might be stuck in readline.
                # That's acceptable for a simple script, main thread will exit.
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


def format_bytes(size):
    power = 2**10
    n = 0
    power_labels = {0 : '', 1: 'K', 2: 'M', 3: 'G', 4: 'T'}
    while size > power:
        size /= power
        n += 1
    return f"{size:.1f}{power_labels.get(n, '')}B"

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
            
            # Disk Usage (Cached)
            monitor.update_disk_stats()
            root_used, root_total, root_pct = monitor.cached_disk_usage
            logs_size = monitor.cached_logs_size
            
            # MAC Addresses
            mac_eth0 = monitor.get_mac_address("eth0")
            mac_wlan0 = monitor.get_mac_address("wlan0")
            
            stats_str = f"CPU: {cpu_pct:.1f}% | MEM: {mem_pct:.1f}% ({int(mem_used)}/{int(mem_total)}MB) | CLIENTS: {clients}"
            stats_str2 = f"DISK /: {root_pct:.1f}% ({format_bytes(root_used)}/{format_bytes(root_total)}) | /var/logs: {format_bytes(logs_size)}"
            stats_str3 = f"MAC: eth0 [{mac_eth0}] | wlan0 [{mac_wlan0}]"
            
            draw_centered(stdscr, 2, stats_str)
            draw_centered(stdscr, 3, stats_str2)
            draw_centered(stdscr, 4, stats_str3)
            stdscr.hline(5, 0, curses.ACS_HLINE, w)

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
                    stdscr.addstr(6, bx + 2, f"{service['name']}", curses.A_BOLD)
                    stdscr.addstr(7, bx + 2, f"Status: {status_txt}", color)
                    stdscr.addstr(8, bx + 2, f"Restart: '{service['key']}'")
                except:
                    pass

            stdscr.hline(9, 0, curses.ACS_HLINE, w)
            stdscr.addstr(9, 2, " LOGS (tail -f) ", curses.color_pair(3))

            # --- Logs ---
            log_h = h - 11
            if log_h > 0:
                with monitor.log_lock:
                    logs = list(monitor.log_buffer)[-log_h:]
                
                for i, line in enumerate(logs):
                    try:
                        stdscr.addstr(10 + i, 1, line[:w-2])
                    except:
                        pass
            
            # --- Status Bar ---
            if time.time() - last_restart_time < 3:
                stdscr.addstr(h-1, 0, last_restart_msg, curses.color_pair(4) | curses.A_REVERSE)
            else:
                cmds = "'q': Quit | 'a': AdGuard | 'c': Config | 'l': Login | 'r': Reboot"
                stdscr.addstr(h-1, 0, cmds[:w-1], curses.color_pair(3))

            # --- Input Handling ---
            key = stdscr.getch()
            if key == ord('q'):
                break
            elif key == ord('c'):
                monitor.open_raspi_config(stdscr)
            elif key == ord('l'):
                monitor.prompt_login(stdscr)
                # If prompt_login returns (it shouldn't if exec works), break
                break
            elif key == ord('r'):
                last_restart_msg = monitor.reboot_system()
                last_restart_time = time.time()
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
            elif key == ord('a'):
                monitor.restart_service("AdGuardHome")
                last_restart_msg = "Restarting AdGuard..."
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
