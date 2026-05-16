#!/home/naazoh/.linux-toolkit-venv/bin/python3
"""
System Information Tool - Advanced system information collector
Displays detailed hardware, OS, network, and process information
"""

import os
import sys
import platform
import subprocess
import psutil
import datetime
import json
import argparse
from pathlib import Path

class SystemInfo:
    def __init__(self):
        self.info = {}
    
    def get_os_info(self):
        """Get operating system information"""
        self.info['os'] = {
            'system': platform.system(),
            'release': platform.release(),
            'version': platform.version(),
            'machine': platform.machine(),
            'processor': platform.processor(),
            'hostname': platform.node(),
            'os_name': ' '.join(platform.uname())
        }
        
        # Get detailed OS info from lsb_release if available
        try:
            result = subprocess.run(['lsb_release', '-a'], 
                                  capture_output=True, text=True)
            self.info['os']['lsb_release'] = result.stdout.strip()
        except:
            pass
        
        return self.info['os']
    
    def get_cpu_info(self):
        """Get CPU information"""
        cpu_info = {
            'physical_cores': psutil.cpu_count(logical=False),
            'total_cores': psutil.cpu_count(logical=True),
            'max_frequency': f"{psutil.cpu_freq().max:.2f}MHz" if psutil.cpu_freq() else "N/A",
            'min_frequency': f"{psutil.cpu_freq().min:.2f}MHz" if psutil.cpu_freq() else "N/A",
            'current_frequency': f"{psutil.cpu_freq().current:.2f}MHz" if psutil.cpu_freq() else "N/A",
            'cpu_usage_per_core': psutil.cpu_percent(percpu=True, interval=1),
            'total_cpu_usage': psutil.cpu_percent(interval=1),
            'load_average': os.getloadavg()
        }
        
        # Get CPU model from /proc/cpuinfo
        try:
            with open('/proc/cpuinfo', 'r') as f:
                for line in f:
                    if 'model name' in line:
                        cpu_info['model'] = line.split(':')[1].strip()
                        break
        except:
            cpu_info['model'] = 'Unknown'
        
        self.info['cpu'] = cpu_info
        return cpu_info
    
    def get_memory_info(self):
        """Get memory information"""
        mem = psutil.virtual_memory()
        swap = psutil.swap_memory()
        
        self.info['memory'] = {
            'total': self._format_bytes(mem.total),
            'available': self._format_bytes(mem.available),
            'used': self._format_bytes(mem.used),
            'percentage': mem.percent,
            'swap_total': self._format_bytes(swap.total),
            'swap_used': self._format_bytes(swap.used),
            'swap_percentage': swap.percent
        }
        
        return self.info['memory']
    
    def get_disk_info(self):
        """Get disk and partition information"""
        disks = []
        for partition in psutil.disk_partitions():
            try:
                usage = psutil.disk_usage(partition.mountpoint)
                disks.append({
                    'device': partition.device,
                    'mountpoint': partition.mountpoint,
                    'fstype': partition.fstype,
                    'total': self._format_bytes(usage.total),
                    'used': self._format_bytes(usage.used),
                    'free': self._format_bytes(usage.free),
                    'percentage': usage.percent
                })
            except:
                pass
        
        self.info['disks'] = disks
        
        # Disk I/O statistics
        disk_io = psutil.disk_io_counters()
        if disk_io:
            self.info['disk_io'] = {
                'read_bytes': self._format_bytes(disk_io.read_bytes),
                'write_bytes': self._format_bytes(disk_io.write_bytes),
                'read_count': disk_io.read_count,
                'write_count': disk_io.write_count
            }
        
        return disks
    
    def get_network_info(self):
        """Get network interface information"""
        interfaces = {}
        for interface, addrs in psutil.net_if_addrs().items():
            interfaces[interface] = []
            for addr in addrs:
                interfaces[interface].append({
                    'family': str(addr.family),
                    'address': addr.address,
                    'netmask': addr.netmask,
                    'broadcast': addr.broadcast
                })
        
        # Network I/O statistics
        net_io = psutil.net_io_counters()
        self.info['network'] = {
            'interfaces': interfaces,
            'bytes_sent': self._format_bytes(net_io.bytes_sent),
            'bytes_recv': self._format_bytes(net_io.bytes_recv),
            'packets_sent': net_io.packets_sent,
            'packets_recv': net_io.packets_recv,
            'errin': net_io.errin,
            'errout': net_io.errout,
            'dropin': net_io.dropin,
            'dropout': net_io.dropout
        }
        
        return self.info['network']
    
    def get_process_info(self):
        """Get top processes information"""
        processes = []
        for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 
                                        'memory_percent', 'status']):
            try:
                pinfo = proc.info
                pinfo['memory_percent'] = round(pinfo['memory_percent'], 2)
                processes.append(pinfo)
            except:
                pass
        
        # Sort by CPU usage
        processes.sort(key=lambda x: x.get('cpu_percent', 0), reverse=True)
        
        self.info['top_processes'] = processes[:10]
        return self.info['top_processes']
    
    def get_users_info(self):
        """Get logged in users information"""
        users = []
        for user in psutil.users():
            users.append({
                'name': user.name,
                'terminal': user.terminal,
                'host': user.host,
                'started': datetime.datetime.fromtimestamp(user.started).strftime('%Y-%m-%d %H:%M:%S')
            })
        
        self.info['users'] = users
        return users
    
    def get_battery_info(self):
        """Get battery information (if available)"""
        if hasattr(psutil, 'sensors_battery'):
            battery = psutil.sensors_battery()
            if battery:
                self.info['battery'] = {
                    'percent': battery.percent,
                    'power_plugged': battery.power_plugged,
                    'seconds_left': battery.secsleft if battery.secsleft != -1 else 'N/A'
                }
                return self.info['battery']
        return None
    
    def get_system_uptime(self):
        """Get system uptime"""
        boot_time = datetime.datetime.fromtimestamp(psutil.boot_time())
        now = datetime.datetime.now()
        uptime = now - boot_time
        
        days = uptime.days
        hours, remainder = divmod(uptime.seconds, 3600)
        minutes, seconds = divmod(remainder, 60)
        
        self.info['uptime'] = {
            'days': days,
            'hours': hours,
            'minutes': minutes,
            'seconds': seconds,
            'boot_time': boot_time.strftime('%Y-%m-%d %H:%M:%S')
        }
        
        return self.info['uptime']
    
    def get_all_info(self):
        """Collect all system information"""
        self.get_os_info()
        self.get_cpu_info()
        self.get_memory_info()
        self.get_disk_info()
        self.get_network_info()
        self.get_process_info()
        self.get_users_info()
        self.get_system_uptime()
        self.get_battery_info()
        
        return self.info
    
    def _format_bytes(self, bytes_value):
        """Format bytes to human readable format"""
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if bytes_value < 1024.0:
                return f"{bytes_value:.2f} {unit}"
            bytes_value /= 1024.0
        return f"{bytes_value:.2f} PB"
    
    def print_table(self, data, headers):
        """Print formatted table"""
        col_widths = [len(h) for h in headers]
        for row in data:
            for i, cell in enumerate(row):
                col_widths[i] = max(col_widths[i], len(str(cell)))
        
        # Print headers
        print("┌" + "┬".join("─" * (w + 2) for w in col_widths) + "┐")
        header_line = "│"
        for i, header in enumerate(headers):
            header_line += f" {header:^{col_widths[i]}} │"
        print(header_line)
        print("├" + "┼".join("─" * (w + 2) for w in col_widths) + "┤")
        
        # Print rows
        for row in data:
            row_line = "│"
            for i, cell in enumerate(row):
                row_line += f" {str(cell):<{col_widths[i]}} │"
            print(row_line)
        
        print("└" + "┴".join("─" * (w + 2) for w in col_widths) + "┘")
    
    def display(self, output_format='text'):
        """Display system information"""
        if output_format == 'json':
            print(json.dumps(self.info, indent=2))
            return
        
        # Text output
        print("\n" + "="*60)
        print(" " * 20 + "SYSTEM INFORMATION")
        print("="*60)
        
        # OS Information
        print("\n📌 OPERATING SYSTEM")
        print("-" * 40)
        for key, value in self.info.get('os', {}).items():
            if key != 'lsb_release':
                print(f"  {key.replace('_', ' ').title():15}: {value}")
        
        # CPU Information
        print("\n📌 CPU INFORMATION")
        print("-" * 40)
        cpu = self.info.get('cpu', {})
        print(f"  Model            : {cpu.get('model', 'N/A')}")
        print(f"  Physical Cores   : {cpu.get('physical_cores', 'N/A')}")
        print(f"  Total Cores      : {cpu.get('total_cores', 'N/A')}")
        print(f"  Max Frequency    : {cpu.get('max_frequency', 'N/A')}")
        print(f"  Current Frequency: {cpu.get('current_frequency', 'N/A')}")
        print(f"  Total CPU Usage  : {cpu.get('total_cpu_usage', 'N/A')}%")
        
        # Load Average
        load_avg = cpu.get('load_average', [0, 0, 0])
        print(f"  Load Average     : {load_avg[0]:.2f}, {load_avg[1]:.2f}, {load_avg[2]:.2f}")
        
        # Memory Information
        print("\n📌 MEMORY INFORMATION")
        print("-" * 40)
        mem = self.info.get('memory', {})
        print(f"  Total     : {mem.get('total', 'N/A')}")
        print(f"  Used      : {mem.get('used', 'N/A')} ({mem.get('percentage', 'N/A')}%)")
        print(f"  Available : {mem.get('available', 'N/A')}")
        print(f"  Swap Total: {mem.get('swap_total', 'N/A')}")
        print(f"  Swap Used : {mem.get('swap_used', 'N/A')} ({mem.get('swap_percentage', 'N/A')}%)")
        
        # Disk Information
        print("\n📌 DISK INFORMATION")
        print("-" * 40)
        for disk in self.info.get('disks', []):
            print(f"  {disk['device']} on {disk['mountpoint']}")
            print(f"    Total: {disk['total']} | Used: {disk['used']} | Free: {disk['free']} ({disk['percentage']}%)")
        
        # Network Information
        print("\n📌 NETWORK INFORMATION")
        print("-" * 40)
        net = self.info.get('network', {})
        print(f"  Bytes Sent    : {net.get('bytes_sent', 'N/A')}")
        print(f"  Bytes Received: {net.get('bytes_recv', 'N/A')}")
        print("\n  Network Interfaces:")
        for interface, addrs in net.get('interfaces', {}).items():
            print(f"    {interface}:")
            for addr in addrs:
                if addr.get('address'):
                    print(f"      IP: {addr.get('address')}")
        
        # Top Processes
        print("\n📌 TOP 10 PROCESSES (by CPU)")
        print("-" * 40)
        processes_data = []
        for proc in self.info.get('top_processes', []):
            processes_data.append([
                proc.get('pid', 'N/A'),
                proc.get('name', 'N/A')[:20],
                f"{proc.get('cpu_percent', 0):.1f}%",
                f"{proc.get('memory_percent', 0):.1f}%",
                proc.get('status', 'N/A')
            ])
        
        if processes_data:
            self.print_table(processes_data, ['PID', 'NAME', 'CPU%', 'MEM%', 'STATUS'])
        
        # Users
        print("\n📌 LOGGED IN USERS")
        print("-" * 40)
        for user in self.info.get('users', []):
            print(f"  {user['name']} - {user['terminal']} ({user['host']}) since {user['started']}")
        
        # Uptime
        uptime = self.info.get('uptime', {})
        print("\n📌 SYSTEM UPTIME")
        print("-" * 40)
        print(f"  Boot Time: {uptime.get('boot_time', 'N/A')}")
        print(f"  Uptime: {uptime.get('days', 0)} days, {uptime.get('hours', 0)} hours, {uptime.get('minutes', 0)} minutes")
        
        # Battery
        battery = self.info.get('battery')
        if battery:
            print("\n📌 BATTERY INFORMATION")
            print("-" * 40)
            print(f"  Percentage: {battery.get('percent', 'N/A')}%")
            print(f"  Power Plugged: {battery.get('power_plugged', 'N/A')}")
            print(f"  Time Remaining: {battery.get('seconds_left', 'N/A')}")

def main():
    parser = argparse.ArgumentParser(description='System Information Tool')
    parser.add_argument('-j', '--json', action='store_true', help='Output in JSON format')
    parser.add_argument('-c', '--cpu', action='store_true', help='Show CPU information only')
    parser.add_argument('-m', '--memory', action='store_true', help='Show memory information only')
    parser.add_argument('-d', '--disk', action='store_true', help='Show disk information only')
    parser.add_argument('-n', '--network', action='store_true', help='Show network information only')
    parser.add_argument('-p', '--process', action='store_true', help='Show process information only')
    
    args = parser.parse_args()
    
    sys_info = SystemInfo()
    
    if args.cpu:
        info = sys_info.get_cpu_info()
        print(json.dumps(info, indent=2) if args.json else info)
    elif args.memory:
        info = sys_info.get_memory_info()
        print(json.dumps(info, indent=2) if args.json else info)
    elif args.disk:
        info = sys_info.get_disk_info()
        print(json.dumps(info, indent=2) if args.json else info)
    elif args.network:
        info = sys_info.get_network_info()
        print(json.dumps(info, indent=2) if args.json else info)
    elif args.process:
        info = sys_info.get_process_info()
        print(json.dumps(info, indent=2) if args.json else info)
    else:
        sys_info.get_all_info()
        sys_info.display('json' if args.json else 'text')

if __name__ == '__main__':
    main()
    
