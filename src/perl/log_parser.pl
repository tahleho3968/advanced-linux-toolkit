#!/usr/bin/perl
# ============================================================
# Log Parser v2.0 - Advanced Perl log parsing and analysis tool
# ============================================================

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use POSIX qw(strftime);
use Data::Dumper;

# Color codes for output
my $RED = "\033[0;31m";
my $GREEN = "\033[0;32m";
my $YELLOW = "\033[1;33m";
my $BLUE = "\033[0;34m";
my $MAGENTA = "\033[0;35m";
my $CYAN = "\033[0;36m";
my $NC = "\033[0m";

# Configuration
my $log_file = "";
my $pattern = "";
my $output_file = "";
my $verbose = 0;
my $summary = 0;
my $errors_only = 0;
my $warnings_only = 0;
my $stats = 0;
my $follow = 0;
my $tail_lines = 0;
my $date_from = "";
my $date_to = "";
my $format = "text";
my $case_sensitive = 0;

# Statistics
my %stats_data = (
    total_lines => 0,
    error_lines => 0,
    warning_lines => 0,
    info_lines => 0,
    debug_lines => 0,
    ip_addresses => {},
    hours => {},
    dates => {},
    status_codes => {},
    users => {},
    log_levels => {}
);

# Patterns
my %patterns = (
    ip => qr/(?:\d{1,3}\.){3}\d{1,3}/,
    email => qr/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/,
    url => qr/https?:\/\/[^\s]+/,
    status_code => qr/\b[1-5]\d{2}\b/,
    timestamp => qr/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/,
    error => qr/ERROR|FATAL|CRITICAL|EMERGENCY/i,
    warning => qr/WARNING|WARN|ALERT/i,
    info => qr/INFO|NOTICE/i,
    debug => qr/DEBUG|TRACE/i,
    user => qr/user[=:]\s*\w+/i
);

# Function to show usage
sub show_usage {
    print << "EOF";
${CYAN}========================================${NC}
${CYAN}        LOG PARSER v2.0${NC}
${CYAN}========================================${NC}

Usage: $0 [options] <logfile>

Options:
  -p, --pattern <regex>   Search for specific pattern
  -o, --output <file>     Write output to file
  -v, --verbose           Verbose output
  -s, --summary           Show summary only
  -e, --errors-only       Show only error lines
  -w, --warnings-only     Show only warning lines
  -t, --stats             Display statistics
  -f, --follow            Follow log file (like tail -f)
  --tail <lines>          Show last N lines
  --from <date>           Filter from date (YYYY-MM-DD)
  --to <date>             Filter to date (YYYY-MM-DD)
  --format <format>       Output format: text, json, csv (default: text)
  -i, --ignore-case       Case-insensitive search
  -h, --help              Show this help message

Examples:
  $0 /var/log/syslog
  $0 -p "ERROR" /var/log/apache2/error.log
  $0 --errors-only --stats /var/log/syslog
  $0 --tail 100 /var/log/auth.log
  $0 --from 2024-01-01 --to 2024-01-31 /var/log/syslog
  $0 --format json /var/log/nginx/access.log

EOF
    exit 0;
}

# Parse command line arguments
GetOptions(
    "p|pattern=s" => \$pattern,
    "o|output=s" => \$output_file,
    "v|verbose" => \$verbose,
    "s|summary" => \$summary,
    "e|errors-only" => \$errors_only,
    "w|warnings-only" => \$warnings_only,
    "t|stats" => \$stats,
    "f|follow" => \$follow,
    "tail=i" => \$tail_lines,
    "from=s" => \$date_from,
    "to=s" => \$date_to,
    "format=s" => \$format,
    "i|ignore-case" => \$case_sensitive,
    "h|help" => \&show_usage
) or show_usage();

# Get log file from arguments
$log_file = shift @ARGV;
if (!$log_file) {
    print "${RED}Error: No log file specified${NC}\n";
    show_usage();
}

# Check if log file exists
if (!-f $log_file && !$follow) {
    print "${RED}Error: Log file '$log_file' does not exist${NC}\n";
    exit 1;
}

# Function to colorize output
sub colorize {
    my ($level, $text) = @_;
    
    if ($level eq 'ERROR') {
        return "${RED}$text${NC}";
    } elsif ($level eq 'WARNING') {
        return "${YELLOW}$text${NC}";
    } elsif ($level eq 'INFO') {
        return "${GREEN}$text${NC}";
    } elsif ($level eq 'DEBUG') {
        return "${BLUE}$text${NC}";
    }
    return $text;
}

# Function to format output
sub format_output {
    my ($line, $format) = @_;
    
    if ($format eq 'json') {
        # JSON output not implemented for line-by-line
        return $line;
    } elsif ($format eq 'csv') {
        # CSV output not implemented for line-by-line
        return $line;
    }
    return $line;
}

# Function to detect log level
sub detect_level {
    my ($line) = @_;
    
    if ($line =~ $patterns{error}) {
        return 'ERROR';
    } elsif ($line =~ $patterns{warning}) {
        return 'WARNING';
    } elsif ($line =~ $patterns{info}) {
        return 'INFO';
    } elsif ($line =~ $patterns{debug}) {
        return 'DEBUG';
    }
    return 'UNKNOWN';
}

# Function to extract information from line
sub extract_info {
    my ($line) = @_;
    
    my $info = {};
    
    # Extract IP addresses
    my @ips = ($line =~ /$patterns{ip}/g);
    $info->{ips} = \@ips if @ips;
    
    # Extract emails
    my @emails = ($line =~ /$patterns{email}/g);
    $info->{emails} = \@emails if @emails;
    
    # Extract URLs
    my @urls = ($line =~ /$patterns{url}/g);
    $info->{urls} = \@urls if @urls;
    
    # Extract status codes
    my @status = ($line =~ /$patterns{status_code}/g);
    $info->{status} = \@status if @status;
    
    # Extract timestamp
    if ($line =~ /($patterns{timestamp})/) {
        $info->{timestamp} = $1;
    }
    
    # Extract username
    if ($line =~ /($patterns{user})/) {
        $info->{user} = $1;
    }
    
    return $info;
}

# Function to update statistics
sub update_stats {
    my ($line) = @_;
    
    $stats_data{total_lines}++;
    
    # Update log level stats
    my $level = detect_level($line);
    $stats_data{log_levels}{$level}++;
    
    if ($level eq 'ERROR') {
        $stats_data{error_lines}++;
    } elsif ($level eq 'WARNING') {
        $stats_data{warning_lines}++;
    } elsif ($level eq 'INFO') {
        $stats_data{info_lines}++;
    } elsif ($level eq 'DEBUG') {
        $stats_data{debug_lines}++;
    }
    
    # Extract and update IP addresses
    my @ips = ($line =~ /$patterns{ip}/g);
    foreach my $ip (@ips) {
        $stats_data{ip_addresses}{$ip}++;
    }
    
    # Extract and update status codes
    my @status = ($line =~ /$patterns{status_code}/g);
    foreach my $code (@status) {
        $stats_data{status_codes}{$code}++;
    }
    
    # Extract timestamp for hourly stats
    if ($line =~ /($patterns{timestamp})/) {
        my $timestamp = $1;
        if ($timestamp =~ /(\d{4}-\d{2}-\d{2}) (\d{2}):/) {
            $stats_data{dates}{$1}++;
            $stats_data{hours}{$2}++;
        }
    }
}

# Function to display statistics
sub display_stats {
    print "\n${CYAN}========================================${NC}\n";
    print "${CYAN}        LOG STATISTICS${NC}\n";
    print "${CYAN}========================================${NC}\n\n";
    
    print "${GREEN}Total lines processed:${NC} $stats_data{total_lines}\n\n";
    
    print "${GREEN}Log Level Breakdown:${NC}\n";
    foreach my $level (sort keys %{$stats_data{log_levels}}) {
        my $count = $stats_data{log_levels}{$level};
        my $percentage = ($count / $stats_data{total_lines}) * 100;
        my $colored_level = colorize($level, $level);
        printf "  %-10s %6d (%5.1f%%)\n", $colored_level, $count, $percentage;
    }
    
    print "\n${GREEN}Top IP Addresses:${NC}\n";
    my @sorted_ips = sort { $stats_data{ip_addresses}{$b} <=> $stats_data{ip_addresses}{$a} } 
                      keys %{$stats_data{ip_addresses}};
    my $ip_count = 0;
    foreach my $ip (@sorted_ips) {
        last if $ip_count++ >= 10;
        printf "  %-20s %d\n", $ip, $stats_data{ip_addresses}{$ip};
    }
    
    print "\n${GREEN}Top Status Codes:${NC}\n";
    my @sorted_status = sort { $stats_data{status_codes}{$b} <=> $stats_data{status_codes}{$a} } 
                         keys %{$stats_data{status_codes}};
    foreach my $code (@sorted_status) {
        printf "  %-10s %d\n", $code, $stats_data{status_codes}{$code};
    }
    
    print "\n${GREEN}Activity by Hour:${NC}\n";
    foreach my $hour (sort { $a <=> $b } keys %{$stats_data{hours}}) {
        my $bar_length = int($stats_data{hours}{$hour} / 10) + 1;
        my $bar = "█" x ($bar_length > 50 ? 50 : $bar_length);
        printf "  %02d:00 %-50s %d\n", $hour, $bar, $stats_data{hours}{$hour};
    }
    
    print "\n${GREEN}Activity by Date:${NC}\n";
    my @sorted_dates = sort keys %{$stats_data{dates}};
    foreach my $date (@sorted_dates[-10..-1]) {
        printf "  %s %d\n", $date, $stats_data{dates}{$date};
    }
}

# Function to filter by date
sub date_filter {
    my ($line) = @_;
    
    return 1 if (!$date_from && !$date_to);
    
    if ($line =~ /($patterns{timestamp})/) {
        my $timestamp = $1;
        my $date = substr($timestamp, 0, 10);
        
        if ($date_from && $date lt $date_from) {
            return 0;
        }
        if ($date_to && $date gt $date_to) {
            return 0;
        }
        return 1;
    }
    return 1;
}

# Function to process line
sub process_line {
    my ($line) = @_;
    
    chomp $line;
    
    # Apply date filter
    return unless date_filter($line);
    
    # Apply pattern filter
    if ($pattern) {
        my $pattern_regex = $case_sensitive ? qr/$pattern/ : qr/$pattern/i;
        return unless $line =~ $pattern_regex;
    }
    
    # Apply level filters
    my $level = detect_level($line);
    if ($errors_only && $level ne 'ERROR') {
        return;
    }
    if ($warnings_only && $level ne 'WARNING') {
        return;
    }
    
    # Update statistics
    if ($stats) {
        update_stats($line);
    }
    
    # Extract information if verbose
    my $info = {};
    if ($verbose) {
        $info = extract_info($line);
    }
    
    # Output line
    if (!$summary && !$stats) {
        my $output = $line;
        if ($format eq 'text') {
            $output = colorize($level, $line);
        }
        
        if ($output_file) {
            open(my $fh, '>>', $output_file) or die "Cannot open $output_file: $!";
            print $fh "$output\n";
            close $fh;
        } else {
            print "$output\n";
        }
        
        # Print extracted info if verbose
        if ($verbose && %$info) {
            print "${CYAN}  └─ Extracted:${NC} ";
            my @extracted;
            push @extracted, "IPs: " . join(',', @{$info->{ips}}) if $info->{ips};
            push @extracted, "Emails: " . join(',', @{$info->{emails}}) if $info->{emails};
            push @extracted, "URLs: " . join(',', @{$info->{urls}}) if $info->{urls};
            push @extracted, "Status: " . join(',', @{$info->{status}}) if $info->{status};
            push @extracted, "User: $info->{user}" if $info->{user};
            print join(', ', @extracted) . "\n" if @extracted;
        }
    }
}

# Function to process log file
sub process_log_file {
    my ($file) = @_;
    
    if ($follow) {
        # Follow mode (like tail -f)
        open(my $fh, '<', $file) or die "Cannot open $file: $!";
        
        # Seek to end if tail_lines is not set
        if (!$tail_lines) {
            seek($fh, 0, 2);
        } elsif ($tail_lines > 0) {
            # Show last N lines
            my @lines;
            while (<$fh>) {
                push @lines, $_;
                shift @lines if @lines > $tail_lines;
            }
            foreach my $line (@lines) {
                process_line($line);
            }
        }
        
        # Follow new lines
        while (1) {
            while (defined(my $line = <$fh>)) {
                process_line($line);
            }
            sleep 1;
            seek($fh, 0, 1);
        }
        close $fh;
    } else {
        # Normal mode
        open(my $fh, '<', $file) or die "Cannot open $file: $!";
        
        if ($tail_lines) {
            # Show last N lines
            my @lines;
            while (<$fh>) {
                push @lines, $_;
                shift @lines if @lines > $tail_lines;
            }
            foreach my $line (@lines) {
                process_line($line);
            }
        } else {
            # Process all lines
            while (my $line = <$fh>) {
                process_line($line);
            }
        }
        
        close $fh;
    }
    
    # Display statistics if requested
    if ($stats) {
        display_stats();
    }
}

# Function to export to JSON
sub export_json {
    my ($file) = @_;
    
    require JSON;
    my $json = JSON->new->pretty;
    
    open(my $fh, '>', $file) or die "Cannot open $file: $!";
    print $fh $json->encode(\%stats_data);
    close $fh;
    
    print "${GREEN}✓ Statistics exported to $file${NC}\n";
}

# Function to export to CSV
sub export_csv {
    my ($file) = @_;
    
    open(my $fh, '>', $file) or die "Cannot open $file: $!";
    
    # Write IP addresses
    print $fh "IP Address,Count\n";
    foreach my $ip (sort { $stats_data{ip_addresses}{$b} <=> $stats_data{ip_addresses}{$a} } 
                    keys %{$stats_data{ip_addresses}}) {
        print $fh "$ip,$stats_data{ip_addresses}{$ip}\n";
    }
    
    close $fh;
    print "${GREEN}✓ CSV exported to $file${NC}\n";
}

# Main execution
print "${CYAN}========================================${NC}\n";
print "${CYAN}        LOG PARSER v2.0${NC}\n";
print "${CYAN}========================================${NC}\n";
print "Log file: $log_file\n";
print "Started at: " . strftime("%Y-%m-%d %H:%M:%S", localtime) . "\n";
print "========================================\n\n";

# Process the log file
process_log_file($log_file);

# Export data if output format is JSON or CSV
if ($format eq 'json' && $stats) {
    my $json_file = $output_file ? $output_file : "log_stats.json";
    export_json($json_file);
} elsif ($format eq 'csv' && $stats) {
    my $csv_file = $output_file ? $output_file : "log_stats.csv";
    export_csv($csv_file);
}

print "\n${GREEN}✓ Completed at: " . strftime("%Y-%m-%d %H:%M:%S", localtime) . "${NC}\n";
