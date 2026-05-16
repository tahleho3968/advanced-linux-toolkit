#!/home/naazoh/.linux-toolkit-venv/bin/python3
"""
Network Monitor Tool - Real-time network traffic monitoring and analysis
"""

import os
import time
import psutil
import argparse
import json
from datetime import datetime
from collections import defaultdict


class NetworkMonitor:
    def __init__(self, interval=1, output_file=None):
        self.interval = interval
        self.output_file = output_file
        self.prev_net_io = psutil.net_io_counters()
        self.prev_time = time.time()
        self.stats = defaultdict(list)

    def get_network_speed(self):
        """Calculate current network speed"""
        current_net_io = psutil.net_io_counters()
        current_time = time.time()

        time_diff = current_time - self.prev_time
        bytes_sent = current_net_io.bytes_sent - self.prev_net_io.bytes_sent
        bytes_recv = current_net_io.bytes_recv - self.prev_net_io.bytes_recv

        speed_sent = bytes_sent / time_diff if time_diff > 0 else 0
        speed_recv = bytes_recv / time_diff if time_diff > 0 else 0

        self.prev_net_io = current_net_io
        self.prev_time = current_time

        return {
            'upload': self.format_speed(speed_sent),
            'download': self.format_speed(speed_recv),
            'upload_bytes': speed_sent,
            'download_bytes': speed_recv
        }

    def format_speed(self, bytes_per_sec):
        """Format speed to human readable format"""
        for unit in ['B/s', 'KB/s', 'MB/s', 'GB/s']:
            if bytes_per_sec < 1024.0:
                return f"{bytes_per_sec:.2f} {unit}"
            bytes_per_sec /= 1024.0
        return f"{bytes_per_sec:.2f} TB/s"

    def get_connections(self):
        """Get network connections"""
        connections = {
            'total': 0,
            'established': 0,
            'listening': 0,
            'time_wait': 0,
            'close_wait': 0,
            'by_protocol': defaultdict(int),
            'by_state': defaultdict(int)
        }

        for conn in psutil.net_connections(kind='inet'):
            connections['total'] += 1

            if conn.status:
                connections['by_state'][conn.status] += 1

                if conn.status == 'ESTABLISHED':
                    connections['established'] += 1
                elif conn.status == 'LISTEN':
                    connections['listening'] += 1
                elif conn.status == 'TIME_WAIT':
                    connections['time_wait'] += 1
                elif conn.status == 'CLOSE_WAIT':
                    connections['close_wait'] += 1

            if conn.type == 1:   # SOCK_STREAM
                connections['by_protocol']['TCP'] += 1
            elif conn.type == 2:  # SOCK_DGRAM
                connections['by_protocol']['UDP'] += 1

        return connections

    def get_top_connections(self, n=10):
        """Get top connections by IP"""
        connections = defaultdict(int)
        for conn in psutil.net_connections(kind='inet'):
            if conn.raddr and conn.raddr.ip:
                connections[conn.raddr.ip] += 1

        top = sorted(connections.items(), key=lambda x: x[1], reverse=True)[:n]
        return [{'ip': ip, 'count': count} for ip, count in top]

    def monitor_once(self):
        """Run monitor once and display results"""
        speed = self.get_network_speed()
        connections = self.get_connections()
        top_conn = self.get_top_connections()

        # Store stats
        self.stats['timestamp'].append(datetime.now())
        self.stats['upload'].append(speed['upload_bytes'])
        self.stats['download'].append(speed['download_bytes'])
        self.stats['total_connections'].append(connections['total'])

        # Display
        self.clear_screen()
        self.print_header()

        print("\n📡 NETWORK SPEED")
        print("-" * 40)
        print(f"  ⬆ Upload:   {speed['upload']}")
        print(f"  ⬇ Download: {speed['download']}")

        print("\n🔌 NETWORK CONNECTIONS")
        print("-" * 40)
        print(f"  Total Connections: {connections['total']}")
        print(f"  Established: {connections['established']}")
        print(f"  Listening:   {connections['listening']}")
        print(f"  Time Wait:   {connections['time_wait']}")
        print(f"  Close Wait:  {connections['close_wait']}")

        print("\n📊 PROTOCOL DISTRIBUTION")
        print("-" * 40)
        for protocol, count in connections['by_protocol'].items():
            print(f"  {protocol}: {count}")

        print("\n🌐 TOP CONNECTIONS")
        print("-" * 40)
        for conn in top_conn:
            print(f"  {conn['ip']:<20} {conn['count']} connections")

        if self.output_file:
            self.write_to_file(speed, connections)

    def monitor_continuous(self, duration=None):
        """Continuous monitoring"""
        start_time = time.time()
        try:
            while True:
                self.monitor_once()
                if duration and (time.time() - start_time) > duration:
                    break
                time.sleep(self.interval)
        except KeyboardInterrupt:
            print("\n\n⚠ Monitoring stopped by user")
            self.print_statistics()

    def print_header(self):
        """Print header with timestamp"""
        print("=" * 60)
        print(f"{'NETWORK MONITOR':^60}")
        print("=" * 60)
        print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"Interval: {self.interval}s")

    def clear_screen(self):
        """Clear terminal screen"""
        os.system('clear' if os.name == 'posix' else 'cls')

    def write_to_file(self, speed, connections):
        """Write data to output file"""
        data = {
            'timestamp': datetime.now().isoformat(),
            'speed': speed,
            'connections': dict(connections)
        }
        mode = 'a' if os.path.exists(self.output_file) else 'w'
        with open(self.output_file, mode) as f:
            json.dump(data, f)
            f.write('\n')

    def print_statistics(self):
        """Print summary statistics"""
        print("\n" + "=" * 60)
        print("MONITORING STATISTICS")
        print("=" * 60)

        if self.stats['upload']:
            avg_upload   = sum(self.stats['upload'])   / len(self.stats['upload'])
            avg_download = sum(self.stats['download'])  / len(self.stats['download'])
            max_upload   = max(self.stats['upload'])
            max_download = max(self.stats['download'])

            print(f"\nAverage Upload:   {self.format_speed(avg_upload)}")
            print(f"Average Download: {self.format_speed(avg_download)}")
            print(f"Peak Upload:      {self.format_speed(max_upload)}")
            print(f"Peak Download:    {self.format_speed(max_download)}")
            print(f"Average Connections: "
                  f"{sum(self.stats['total_connections']) / len(self.stats['total_connections']):.1f}")

        if self.output_file:
            print(f"\nData logged to: {self.output_file}")


def main():
    parser = argparse.ArgumentParser(description='Network Monitor Tool')
    parser.add_argument('-i', '--interval', type=int, default=1,
                        help='Monitoring interval in seconds (default: 1)')
    parser.add_argument('-c', '--continuous', action='store_true',
                        help='Continuous monitoring mode')
    parser.add_argument('-d', '--duration', type=int,
                        help='Duration for continuous monitoring (seconds)')
    parser.add_argument('-o', '--output', help='Output file for logging')

    args = parser.parse_args()

    monitor = NetworkMonitor(args.interval, args.output)

    if args.continuous or args.duration:
        monitor.monitor_continuous(args.duration)
    else:
        monitor.monitor_once()


if __name__ == '__main__':
    main()
    
