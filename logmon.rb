#!/usr/bin/env ruby

require 'json'
require 'optparse'

class Logmon

  def intialize 
    @conf_file = '/etc/logmon/logmon.json'
    @terminate = false
  end    

  def options 
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
      exit
    end
    opt_c = false
    opt.on('-c') {|v| opt_c = v if v}

    opt.parse!(ARGV)
    
    return opt_c
  end

  def read_conf(check_config)
    config = open(@conf_file) do |io|
      JSON.load(io)
    end

    return config unless check_config

    puts "Config file: #{@conf_file}"
    config.each do |hash|
      puts "Logfile: #{hash["target"]}";
      puts "  Message: #{hash["message"]}"
      puts "  Action: #{hash["action"]}"
    end

    exit
  end

  def watch_for(target, tail_num)
    fork do
      `tail -n#{tail_num} -f #{target["target"]}`.each_line do |line|
        if ( line =~ m/target["message"]/ ) then
          new_action = target["action"]
          new_action = new_action.sub(/<%%%%>/, $1)
          system( new_action )
        end
      end
    end
  end 

  def run
    trap('HUP') { system("pkill -HUP -P $$") }

    trap('TERM') {
      system ( "pkill -TERM -P $$" )
      terminate = true
    }

    config = read_conf(options)

    tail_num = 0
    while ( ! terminate ) do
      config.each do |target|
        watch_for(target, tail_num)
      end
      while ( ! system( "pgrep -P $$" ) ) do
        Process.waitall
      end
      tail_num = 5;
    end
  end
end

Logmon.new.run
