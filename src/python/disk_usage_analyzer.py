#!/home/naazoh/.linux-toolkit-venv/bin/python3
"""
Disk Usage Analyzer - Analyze disk space usage and find large files/directories
"""

import os
import sys
import argparse
from pathlib import Path
from collections import defaultdict
import json

class DiskAnalyzer:
    def __init__(self, path, depth=3, min_size='1M'):
        self.path = Path(path).resolve()
        self.depth = depth
        self.min_size = self.parse_size(min_size)
        self.results = {}
    
    def parse_size(self, size_str):
        """Parse size string like 1K, 1M, 1G to bytes"""
        size_str = size_str.upper()
        multipliers = {'K': 1024, 'M': 1024**2, 'G': 1024**3, 'T': 1024**4}
        
        if size_str[-1] in multipliers:
            return int(size_str[:-1]) * multipliers[size_str[-1]]
        return int(size_str)
    
    def format_size(self, size_bytes):
        """Format bytes to human readable"""
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if size_bytes < 1024.0:
                return f"{size_bytes:.2f} {unit}"
            size_bytes /= 1024.0
        return f"{size_bytes:.2f} PB"
    
    def get_directory_size(self, path):
        """Calculate directory size recursively"""
        total = 0
        try:
            for entry in path.iterdir():
                if entry.is_file():
                    total += entry.stat().st_size
                elif entry.is_dir():
                    total += self.get_directory_size(entry)
        except (PermissionError, OSError):
            pass
        return total
    
    def analyze(self):
        """Analyze disk usage"""
        print(f"\n📊 Analyzing: {self.path}")
        print("-" * 50)
        
        self.results = self.scan_directory(self.path, depth=0)
        return self.results
    
    def scan_directory(self, path, depth=0):
        """Recursively scan directory"""
        if depth > self.depth:
            return None
        
        result = {
            'name': path.name,
            'path': str(path),
            'size': 0,
            'children': []
        }
        
        try:
            items = list(path.iterdir())
            
            for item in items:
                if item.is_file():
                    size = item.stat().st_size
                    if size >= self.min_size:
                        result['children'].append({
                            'name': item.name,
                            'path': str(item),
                            'size': size,
                            'type': 'file'
                        })
                        result['size'] += size
                
                elif item.is_dir():
                    sub_result = self.scan_directory(item, depth + 1)
                    if sub_result and sub_result['size'] >= self.min_size:
                        result['children'].append(sub_result)
                        result['size'] += sub_result['size']
            
            # Sort children by size (largest first)
            result['children'].sort(key=lambda x: x['size'], reverse=True)
            
        except (PermissionError, OSError):
            pass
        
        return result
    
    def display_tree(self, node, indent=0, is_last=True):
        """Display directory tree"""
        prefix = "    " * indent
        if indent > 0:
            prefix += "└── " if is_last else "├── "
        
        size_str = self.format_size(node['size'])
        print(f"{prefix}{node['name']} [{size_str}]")
        
        if 'children' in node:
            children = node['children'][:10]  # Show top 10
            for i, child in enumerate(children):
                is_last_child = (i == len(children) - 1)
                if child.get('type') == 'dir':
                    self.display_tree(child, indent + 1, is_last_child)
                else:
                    file_prefix = "    " * (indent + 1)
                    file_prefix += "└── " if is_last_child else "├── "
                    file_size = self.format_size(child['size'])
                    print(f"{file_prefix}{child['name']} [{file_size}]")
            
            if len(children) < len(node['children']):
                print(f"{'    ' * (indent + 1)}... and {len(node['children']) - 10} more items")
    
    def get_largest_files(self, n=20):
        """Find largest files"""
        files = []
        
        def find_large_files(path):
            try:
                for entry in path.iterdir():
                    if entry.is_file():
                        size = entry.stat().st_size
                        if size >= self.min_size:
                            files.append({
                                'path': str(entry),
                                'size': size,
                                'size_str': self.format_size(size)
                            })
                    elif entry.is_dir():
                        find_large_files(entry)
            except (PermissionError, OSError):
                pass
        
        find_large_files(self.path)
        files.sort(key=lambda x: x['size'], reverse=True)
        return files[:n]
    
    def get_file_type_distribution(self):
        """Get distribution of file types"""
        extensions = defaultdict(int)
        sizes_by_type = defaultdict(int)
        
        def scan_extensions(path):
            try:
                for entry in path.iterdir():
                    if entry.is_file():
                        ext = entry.suffix.lower() or 'no_extension'
                        extensions[ext] += 1
                        sizes_by_type[ext] += entry.stat().st_size
                    elif entry.is_dir():
                        scan_extensions(entry)
            except (PermissionError, OSError):
                pass
        
        scan_extensions(self.path)
        
        return {
            'counts': dict(extensions),
            'sizes': {k: self.format_size(v) for k, v in sizes_by_type.items()}
        }
    
    def display_summary(self):
        """Display summary statistics"""
        if not self.results:
            self.analyze()
        
        print("\n" + "="*60)
        print("DISK USAGE SUMMARY")
        print("="*60)
        
        total_size = self.results['size']
        print(f"\nTotal Size: {self.format_size(total_size)}")
        
        # Largest directories
        print("\n📁 LARGEST DIRECTORIES")
        print("-" * 40)
        dirs = []
        for child in self.results.get('children', []):
            if child.get('type') != 'file':
                dirs.append(child)
        
        dirs.sort(key=lambda x: x['size'], reverse=True)
        for i, dir_info in enumerate(dirs[:10], 1):
            print(f"  {i:2}. {dir_info['name']:<30} {self.format_size(dir_info['size'])}")
        
        # Largest files
        print("\n📄 LARGEST FILES")
        print("-" * 40)
        largest_files = self.get_largest_files(10)
        for i, file_info in enumerate(largest_files, 1):
            print(f"  {i:2}. {Path(file_info['path']).name:<40} {file_info['size_str']}")
        
        # File type distribution
        print("\n📊 FILE TYPE DISTRIBUTION")
        print("-" * 40)
        type_dist = self.get_file_type_distribution()
        sorted_types = sorted(type_dist['sizes'].items(), key=lambda x: x[1], reverse=True)
        
        for ext, size in sorted_types[:10]:
            count = type_dist['counts'][ext]
            print(f"  {ext:<15} {size:<12} ({count} files)")
    
    def export_json(self, output_file):
        """Export results to JSON"""
        if not self.results:
            self.analyze()
        
        export_data = {
            'path': str(self.path),
            'total_size': self.results['size'],
            'total_size_str': self.format_size(self.results['size']),
            'structure': self.results,
            'largest_files': self.get_largest_files(50),
            'file_types': self.get_file_type_distribution()
        }
        
        with open(output_file, 'w') as f:
            json.dump(export_data, f, indent=2, default=str)
        
        print(f"\n✓ Exported to: {output_file}")

def main():
    parser = argparse.ArgumentParser(description='Disk Usage Analyzer')
    parser.add_argument('path', nargs='?', default='.', help='Path to analyze')
    parser.add_argument('-d', '--depth', type=int, default=3,
                       help='Directory depth to show (default: 3)')
    parser.add_argument('-m', '--min-size', default='1M',
                       help='Minimum size to show (e.g., 1K, 1M, 1G)')
    parser.add_argument('-t', '--tree', action='store_true',
                       help='Display directory tree')
    parser.add_argument('-j', '--json', help='Export to JSON file')
    parser.add_argument('-l', '--largest', type=int, default=20,
                       help='Number of largest files to show')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.path):
        print(f"Error: Path '{args.path}' does not exist")
        sys.exit(1)
    
    analyzer = DiskAnalyzer(args.path, args.depth, args.min_size)
    
    if args.tree:
        analyzer.analyze()
        analyzer.display_tree(analyzer.results)
    else:
        analyzer.display_summary()
    
    if args.json:
        analyzer.export_json(args.json)

if __name__ == '__main__':
    main()
