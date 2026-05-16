#!/home/naazoh/.linux-toolkit-venv/bin/python3
"""
Log Visualizer - Generate graphical reports from log files
"""

import re
import json
import argparse
import matplotlib.pyplot as plt
import numpy as np
from collections import defaultdict, Counter
from datetime import datetime
from pathlib import Path

class LogVisualizer:
    def __init__(self, log_file):
        self.log_file = Path(log_file)
        self.data = {
            'timestamp': [],
            'levels': [],
            'messages': [],
            'sources': []
        }
        
        # Common log patterns
        self.patterns = {
            'timestamp': r'\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}',
            'level': r' (ERROR|WARNING|INFO|DEBUG|CRITICAL|FATAL) ',
            'ip': r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b',
            'status': r' \d{3} ',
            'user': r'user[=:]\s*\w+'
        }
    
    def parse_log(self):
        """Parse log file and extract data"""
        print(f"📄 Parsing: {self.log_file}")
        
        with open(self.log_file, 'r') as f:
            for line_num, line in enumerate(f, 1):
                # Extract timestamp
                timestamp_match = re.search(self.patterns['timestamp'], line)
                if timestamp_match:
                    try:
                        ts = datetime.strptime(timestamp_match.group(), '%Y-%m-%d %H:%M:%S')
                        self.data['timestamp'].append(ts)
                    except:
                        self.data['timestamp'].append(None)
                else:
                    self.data['timestamp'].append(None)
                
                # Extract log level
                level_match = re.search(self.patterns['level'], line)
                if level_match:
                    level = level_match.group(1)
                    self.data['levels'].append(level)
                else:
                    self.data['levels'].append('UNKNOWN')
                
                # Extract IP addresses
                ips = re.findall(self.patterns['ip'], line)
                if ips:
                    self.data['sources'].extend(ips)
                
                # Store message
                self.data['messages'].append(line.strip())
        
        print(f"✓ Parsed {len(self.data['messages'])} lines")
    
    def get_statistics(self):
        """Calculate statistics from parsed data"""
        stats = {
            'total_lines': len(self.data['messages']),
            'unique_ips': len(set(self.data['sources'])),
            'level_counts': Counter(self.data['levels']),
            'top_ips': Counter(self.data['sources']).most_common(10),
            'top_keywords': self.get_top_keywords()
        }
        
        # Timestamp analysis
        valid_timestamps = [ts for ts in self.data['timestamp'] if ts]
        if valid_timestamps:
            stats['time_range'] = {
                'start': min(valid_timestamps),
                'end': max(valid_timestamps),
                'duration': max(valid_timestamps) - min(valid_timestamps)
            }
            
            # Hourly distribution
            hours = [ts.hour for ts in valid_timestamps]
            stats['hourly_distribution'] = Counter(hours)
        
        return stats
    
    def get_top_keywords(self, n=20):
        """Extract top keywords from log messages"""
        words = []
        stopwords = {'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
                     'of', 'with', 'by', 'from', 'up', 'down', 'is', 'was', 'are', 'were'}
        
        for msg in self.data['messages']:
            # Split into words and clean
            clean_words = re.findall(r'\b[a-zA-Z]{3,}\b', msg.lower())
            words.extend([w for w in clean_words if w not in stopwords])
        
        return Counter(words).most_common(n)
    
    def generate_timeline_chart(self, output_file):
        """Generate timeline chart of log events"""
        if not any(self.data['timestamp']):
            print("No timestamp data available for timeline chart")
            return
        
        valid_data = [(ts, level) for ts, level in zip(self.data['timestamp'], self.data['levels']) if ts]
        
        if not valid_data:
            return
        
        # Group by hour
        hourly_counts = defaultdict(lambda: defaultdict(int))
        for ts, level in valid_data:
            hour_key = ts.replace(minute=0, second=0, microsecond=0)
            hourly_counts[hour_key][level] += 1
        
        hours = sorted(hourly_counts.keys())
        levels = set(self.data['levels'])
        
        # Prepare data for stacked bar chart
        level_data = {level: [hourly_counts[h][level] for h in hours] for level in levels}
        
        fig, ax = plt.subplots(figsize=(12, 6))
        bottom = np.zeros(len(hours))
        
        colors = {'ERROR': 'red', 'WARNING': 'orange', 'INFO': 'green', 
                  'DEBUG': 'blue', 'CRITICAL': 'darkred', 'FATAL': 'darkred'}
        
        for level in ['CRITICAL', 'ERROR', 'WARNING', 'INFO', 'DEBUG']:
            if level in level_data and sum(level_data[level]) > 0:
                ax.bar(hours, level_data[level], bottom=bottom, 
                       label=level, color=colors.get(level, 'gray'), alpha=0.7)
                bottom += np.array(level_data[level])
        
        ax.set_xlabel('Time')
        ax.set_ylabel('Number of Events')
        ax.set_title('Log Events Timeline')
        ax.legend()
        plt.xticks(rotation=45)
        plt.tight_layout()
        plt.savefig(output_file, dpi=100, bbox_inches='tight')
        print(f"✓ Timeline chart saved: {output_file}")
    
    def generate_pie_chart(self, output_file):
        """Generate pie chart of log levels"""
        level_counts = Counter(self.data['levels'])
        
        if not level_counts:
            print("No level data available for pie chart")
            return
        
        fig, ax = plt.subplots(figsize=(8, 8))
        colors = ['#ff6b6b', '#ffa502', '#26de81', '#70a1ff', '#a4b0be', '#747d8c']
        
        wedges, texts, autotexts = ax.pie(level_counts.values(), 
                                           labels=level_counts.keys(),
                                           autopct='%1.1f%%',
                                           colors=colors[:len(level_counts)],
                                           explode=[0.05] * len(level_counts))
        
        ax.set_title('Log Level Distribution')
        plt.savefig(output_file, dpi=100, bbox_inches='tight')
        print(f"✓ Pie chart saved: {output_file}")
    
    def generate_top_ips_chart(self, output_file):
        """Generate bar chart of top IP addresses"""
        top_ips = Counter(self.data['sources']).most_common(10)
        
        if not top_ips:
            print("No IP data available")
            return
        
        ips, counts = zip(*top_ips)
        
        fig, ax = plt.subplots(figsize=(10, 6))
        bars = ax.bar(range(len(ips)), counts, color='skyblue', alpha=0.7)
        
        ax.set_xlabel('IP Address')
        ax.set_ylabel('Request Count')
        ax.set_title('Top IP Addresses')
        ax.set_xticks(range(len(ips)))
        ax.set_xticklabels(ips, rotation=45, ha='right')
        
        # Add value labels on bars
        for bar, count in zip(bars, counts):
            ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.5,
                   str(count), ha='center', va='bottom')
        
        plt.tight_layout()
        plt.savefig(output_file, dpi=100, bbox_inches='tight')
        print(f"✓ Top IPs chart saved: {output_file}")
    
    def generate_hourly_chart(self, output_file):
        """Generate hourly distribution chart"""
        stats = self.get_statistics()
        
        if 'hourly_distribution' not in stats:
            print("No hourly data available")
            return
        
        hours = sorted(stats['hourly_distribution'].keys())
        counts = [stats['hourly_distribution'][h] for h in hours]
        
        fig, ax = plt.subplots(figsize=(12, 6))
        ax.bar(hours, counts, color='lightgreen', alpha=0.7, edgecolor='green')
        
        ax.set_xlabel('Hour of Day')
        ax.set_ylabel('Number of Events')
        ax.set_title('Log Events by Hour')
        ax.set_xticks(range(0, 24))
        
        plt.tight_layout()
        plt.savefig(output_file, dpi=100, bbox_inches='tight')
        print(f"✓ Hourly distribution chart saved: {output_file}")
    
    def generate_report(self, output_prefix='log_report'):
        """Generate all charts and summary report"""
        print("\n" + "="*60)
        print("LOG VISUALIZATION REPORT")
        print("="*60)
        
        self.parse_log()
        stats = self.get_statistics()
        
        # Display statistics
        print(f"\n📊 STATISTICS")
        print("-" * 40)
        print(f"Total lines:     {stats['total_lines']}")
        print(f"Unique IPs:      {stats['unique_ips']}")
        print(f"Time range:      {stats.get('time_range', {}).get('start', 'N/A')} - {stats.get('time_range', {}).get('end', 'N/A')}")
        
        print("\n📈 LOG LEVEL DISTRIBUTION")
        print("-" * 40)
        for level, count in sorted(stats['level_counts'].items(), key=lambda x: x[1], reverse=True):
            percentage = (count / stats['total_lines']) * 100
            print(f"  {level:<10} {count:>6} ({percentage:5.1f}%)")
        
        print("\n🌐 TOP 5 IP ADDRESSES")
        print("-" * 40)
        for ip, count in stats['top_ips'][:5]:
            print(f"  {ip:<20} {count} requests")
        
        print("\n🔤 TOP 10 KEYWORDS")
        print("-" * 40)
        for word, count in stats['top_keywords'][:10]:
            print(f"  {word:<20} {count} occurrences")
        
        # Generate charts
        charts_dir = Path(f"{output_prefix}_charts")
        charts_dir.mkdir(exist_ok=True)
        
        print("\n📊 Generating charts...")
        self.generate_timeline_chart(charts_dir / "timeline.png")
        self.generate_pie_chart(charts_dir / "pie.png")
        self.generate_top_ips_chart(charts_dir / "top_ips.png")
        self.generate_hourly_chart(charts_dir / "hourly.png")
        
        # Save JSON data
        json_file = f"{output_prefix}_data.json"
        with open(json_file, 'w') as f:
            json.dump(stats, f, indent=2, default=str)
        print(f"✓ Data saved: {json_file}")
        
        print(f"\n✓ Report generated in: {charts_dir}/")
        return charts_dir

def main():
    parser = argparse.ArgumentParser(description='Log Visualizer - Generate graphical reports from log files')
    parser.add_argument('logfile', help='Path to log file')
    parser.add_argument('-o', '--output', default='log_report', help='Output prefix for reports')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.logfile):
        print(f"Error: Log file '{args.logfile}' does not exist")
        sys.exit(1)
    
    visualizer = LogVisualizer(args.logfile)
    visualizer.generate_report(args.output)

if __name__ == '__main__':
    main()
    
