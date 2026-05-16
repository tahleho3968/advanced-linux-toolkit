#!/home/naazoh/.linux-toolkit-venv/bin/python3
"""
File Organizer Tool - Automatically organize files by type, date, or name
"""

import os
import shutil
import argparse
import datetime
import mimetypes
from pathlib import Path
from collections import defaultdict

class FileOrganizer:
    def __init__(self, directory, dry_run=False, recursive=False):
        self.directory = Path(directory)
        self.dry_run = dry_run
        self.recursive = recursive
        self.extensions_map = self.get_extensions_map()
        self.stats = {'organized': 0, 'skipped': 0, 'errors': 0}
    
    def get_extensions_map(self):
        """Map file extensions to categories"""
        return {
            'Images': ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg', '.ico', '.tiff', '.webp'],
            'Documents': ['.pdf', '.doc', '.docx', '.txt', '.rtf', '.odt', '.xls', '.xlsx', '.ppt', '.pptx'],
            'Archives': ['.zip', '.tar', '.gz', '.rar', '.7z', '.bz2', '.xz'],
            'Audio': ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a'],
            'Video': ['.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm'],
            'Code': ['.py', '.js', '.html', '.css', '.cpp', '.c', '.java', '.php', '.rb', '.go', '.rs', '.sh'],
            'Config': ['.json', '.xml', '.yaml', '.yml', '.toml', '.ini', '.cfg', '.conf'],
            'Executables': ['.exe', '.msi', '.appimage', '.deb', '.rpm', '.sh'],
            'Databases': ['.db', '.sqlite', '.sql', '.csv', '.tsv'],
            'Temporary': ['.tmp', '.temp', '.cache', '.log', '.bak', '.swp']
        }
    
    def get_category(self, file_path):
        """Determine category based on file extension"""
        ext = file_path.suffix.lower()
        for category, extensions in self.extensions_map.items():
            if ext in extensions:
                return category
        return 'Others'
    
    def create_category_dir(self, category):
        """Create category directory if it doesn't exist"""
        category_path = self.directory / category
        if not category_path.exists():
            if not self.dry_run:
                category_path.mkdir(parents=True, exist_ok=True)
                print(f"✓ Created directory: {category}")
            else:
                print(f"  Would create directory: {category}")
        return category_path
    
    def is_organizable(self, file_path):
        """Check if file should be organized"""
        # Skip directories
        if file_path.is_dir():
            return False
        
        # Skip hidden files (optional)
        if file_path.name.startswith('.'):
            return False
        
        # Skip files already in category directories
        for category in self.extensions_map.keys():
            if category in str(file_path.parent):
                return False
        
        return True
    
    def get_date_based_path(self, file_path):
        """Get path based on file modification date"""
        mtime = file_path.stat().st_mtime
        date = datetime.datetime.fromtimestamp(mtime)
        year = date.strftime('%Y')
        month = date.strftime('%m_%B')
        return self.directory / 'ByDate' / year / month
    
    def get_name_based_path(self, file_path):
        """Get path based on first letter of filename"""
        first_char = file_path.name[0].upper()
        if first_char.isalpha():
            return self.directory / 'ByName' / first_char
        return self.directory / 'ByName' / '0-9'
    
    def organize_by_type(self, file_path):
        """Organize files by type/category"""
        category = self.get_category(file_path)
        dest_dir = self.create_category_dir(category)
        dest_path = dest_dir / file_path.name
        
        # Handle duplicate filenames
        if dest_path.exists():
            base = file_path.stem
            ext = file_path.suffix
            counter = 1
            while dest_path.exists():
                dest_path = dest_dir / f"{base}_{counter}{ext}"
                counter += 1
        
        if not self.dry_run:
            shutil.move(str(file_path), str(dest_path))
            print(f"✓ Moved: {file_path.name} → {category}/")
        else:
            print(f"  Would move: {file_path.name} → {category}/")
        
        self.stats['organized'] += 1
    
    def organize_by_date(self, file_path):
        """Organize files by date"""
        dest_dir = self.get_date_based_path(file_path)
        if not dest_dir.exists() and not self.dry_run:
            dest_dir.mkdir(parents=True, exist_ok=True)
        
        dest_path = dest_dir / file_path.name
        
        if dest_path.exists():
            base = file_path.stem
            ext = file_path.suffix
            counter = 1
            while dest_path.exists():
                dest_path = dest_dir / f"{base}_{counter}{ext}"
                counter += 1
        
        if not self.dry_run:
            shutil.move(str(file_path), str(dest_path))
            print(f"✓ Moved: {file_path.name} → ByDate/{dest_dir.name}/")
        else:
            print(f"  Would move: {file_path.name} → ByDate/{dest_dir.name}/")
        
        self.stats['organized'] += 1
    
    def organize_by_name(self, file_path):
        """Organize files by first letter of name"""
        dest_dir = self.get_name_based_path(file_path)
        if not dest_dir.exists() and not self.dry_run:
            dest_dir.mkdir(parents=True, exist_ok=True)
        
        dest_path = dest_dir / file_path.name
        
        if dest_path.exists():
            base = file_path.stem
            ext = file_path.suffix
            counter = 1
            while dest_path.exists():
                dest_path = dest_dir / f"{base}_{counter}{ext}"
                counter += 1
        
        if not self.dry_run:
            shutil.move(str(file_path), str(dest_path))
            print(f"✓ Moved: {file_path.name} → ByName/{dest_dir.name}/")
        else:
            print(f"  Would move: {file_path.name} → ByName/{dest_dir.name}/")
        
        self.stats['organized'] += 1
    
    def organize_files(self, method='type'):
        """Main organization function"""
        print(f"\n📁 Organizing files in: {self.directory}")
        print(f"Method: {method}")
        print(f"Dry Run: {self.dry_run}")
        print("-" * 50)
        
        # Get all files
        if self.recursive:
            files = list(self.directory.rglob('*'))
        else:
            files = list(self.directory.glob('*'))
        
        for file_path in files:
            if self.is_organizable(file_path):
                try:
                    if method == 'type':
                        self.organize_by_type(file_path)
                    elif method == 'date':
                        self.organize_by_date(file_path)
                    elif method == 'name':
                        self.organize_by_name(file_path)
                except Exception as e:
                    print(f"✗ Error organizing {file_path.name}: {e}")
                    self.stats['errors'] += 1
            else:
                self.stats['skipped'] += 1
        
        self.print_summary()
    
    def print_summary(self):
        """Print organization summary"""
        print("\n" + "="*50)
        print("ORGANIZATION SUMMARY")
        print("="*50)
        print(f"  Files Organized: {self.stats['organized']}")
        print(f"  Files Skipped:   {self.stats['skipped']}")
        print(f"  Errors:          {self.stats['errors']}")
        
        if self.dry_run:
            print("\n⚠ This was a dry run. No files were actually moved.")
        else:
            print(f"\n✓ Organization complete!")

def main():
    parser = argparse.ArgumentParser(description='File Organizer Tool')
    parser.add_argument('directory', help='Directory to organize')
    parser.add_argument('-m', '--method', choices=['type', 'date', 'name'], 
                       default='type', help='Organization method (default: type)')
    parser.add_argument('-n', '--dry-run', action='store_true', 
                       help='Show what would be done without actually doing it')
    parser.add_argument('-r', '--recursive', action='store_true',
                       help='Process subdirectories recursively')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.directory):
        print(f"Error: Directory '{args.directory}' does not exist")
        sys.exit(1)
    
    organizer = FileOrganizer(args.directory, args.dry_run, args.recursive)
    organizer.organize_files(args.method)

if __name__ == '__main__':
    main()
    
