#!/usr/bin/perl
#
#   logmon.pl / LogMonitor
#
#   2009/06/26  ver1.0
#   2009/06/30  ver1.1 Add meta-string: <%%%%>
#   2010/04/11  ver1.2 resolve meta-string substitution bug
#

require 'json'
require 'optparse'
use strict;
use Getopt::Std;

@conf_file = '/etc/logmon/logmon.conf'
@config = ''
@terminate = false

def options {
  option_hash = {}
  opt = OptionParser.new
  opt.on('-f VAL') {|v| @conf_file = v}
  opt.on('-h') do |v| 
    puts <<EOF;
Usage: logmon [-hc] [-f config_file]
Options:
  -h: show help
  -c: check config
  -f: config file (Default: /etc/logmon/logmon.conf)
EOF
  end
  opt_c = false
  opt.on('-c') {|v| opt_c = v if v}

  opt.parse!(ARGV)
  
  return opt_c
}

def read_conf(check_config)
  open(@conf_file) do |file|
    target  = nil
    message = nil
    action  = nil
    while line = file.gets
      line = line.sub(/^\s+/, '').sub(/\s+$/, '').sub(/#.*$/, '')
      next if line.empty?
      if ( line =~ /^:(.+)/ )     { target  = $1; next }
      if ( line =~ /^(\(.+\))$/ ) { message = $1; next }
      action  = line;
      next unless ( target && message );
      @config[target] = {message => action}
      
    end
  end

  return unless check_config

  puts "Config file: #{@conf_file}"
  @config.keys.each do |target|
    puts "Logfile: #{target}";
    @config[target].keys.each do |message|
      puts "  Message: #{message}"
      @config[target][message].each do |action|
        puts "    Action: #{action}"
      end
    end
  end
end


def watch_for(target, tail_num)
  fork do
    `tail -n#{tail_num} -f #{target}`.each_line do |line|
      @config[target].keys.each do |message| 
        if ( line =~ m/message/ ) then
          @config[target][message].each do |action|
            new_action = action
            new_action = new_action.sub(/<%%%%>/, $1)
            system( new_action )
        end
      end
    end
  end
end

trap('HUP') { system("pkill -HUP -P $$") }

trap('TERM') {
  system ( "pkill -TERM -P $$" )
  terminate = true
}

read_conf(options)

tail_num = 0
while ( ! terminate ) do
  config.keys.each do |target|
    watch_for(target, tail_num)
  end
  while ( ! system( "pgrep -P $$" ) ) do
    Process.waitall
  end
    tail_num = 5;
end
