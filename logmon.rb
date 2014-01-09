#!/usr/bin/env ruby

require 'json'
require 'optparse'
require 'net/ssh'
require 'pry'

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
      puts "Logfile: #{hash["file"]}";
      puts "  Message: #{hash["message"]}"
      puts "  Action: #{hash["action"]}"
    end

    exit
  end

  def watch_for(target)
    fork do
      ssh_config = Net::SSH::Config.for(target['host'], Net::SSH::Config.default_files)
      Net::SSH.start(target['host'], ssh_config[:user], ssh_config) do |session|
        session.open_channel do |channel|
          channel.on_data do |ch, data|
            if data =~ /#{target['message']}/ then
              new_action = target['action']
              new_action = new_action.sub(/<%%%%>/, data)
              system( new_action )
            end
          end
          channel.exec "tail -n0 -f #{target['file']}"
        end
        session.loop
      end
    end
  end 

  def run
    trap('HUP') { system("pkill -HUP -P $$") }

    trap('TERM') {
      system ( "pkill -KILL -P #{$$}" )
      @terminate = true
    }

    config = read_conf(options)

    while ( ! @terminate ) do
      config.each do |target|
        watch_for(target, tail_num)
      end
      Process.waitall
    end
  end
end

Logmon.new.run
