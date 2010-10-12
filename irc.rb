#!/usr/bin/ruby
$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), "lib"))
require "rubygems"
require 'fileutils'
require "socket"
require 'yaml'
require 'rirc_bot/setup_wizard'

class IRC
  def initialize(options=Hash.new)
    config_file = options.delete(:config_file) || File.expand_path('config.yml')
    if File.exists?(config_file)
      config = YAML.load_file(config_file)
    else
      config=SetupWizard.create
    end
    puts config.inspect
    @server = config['server']
    @port = config['port']
    @nick = config['nick']
    @channel = config['channel']
    @password = config['password']
    @monitor_dir=config['monitor_dir']
    FileUtils.mkdir_p(@monitor_dir)
  end

  def send(s)
    case s
    when /^(PASS|USER|NICK|JOIN|PING|QUIT)/
      @irc.send "#{s}\n", 0
    else
      puts "seding #{s} "
      @irc.send "PRIVMSG #{@channel} : #{s}\n", 0
    end
  end

  def connect
    # Connect to the IRC server
    @irc = TCPSocket.open(@server, @port)
    send "PASS #{@password}"
    send "USER #{@nick} 8 * :#{@nick}"
    send "NICK #{@nick}"
    send "JOIN #{@channel}"
  end

  def disconnect
    @irc.send "QUIT", 0
    @irc=nil
  end

  def monitor_input
    files=Dir.glob("#{@monitor_dir}/*.txt")
    files.each do |file|
      File.read(file).each do |line|
        puts "sending #{line}"
        send line
      end
      File.delete(file)
    end
    send "PING"
    sleep(5)
  end
end

@irc=IRC.new :config_file=>File.expand_path(File.join(File.dirname(__FILE__), "config.yml"))
puts "connecting..."
@irc.connect
puts "connected !"

Signal.trap("SIGINT") do
  begin
    puts "Stopping..."
    @irc.disconnect
  rescue => e
    puts e.inspect
    puts "could not disconnect"
  end
  exit
end
Signal.trap("SIGTERM") do
  begin
    puts "Stopping..."
    @irc.disconnect
  rescue => e
    puts e.inspect
    puts "could not disconnect"
  end
  exit
end

loop do
  begin
    @irc.connect unless @irc
    @irc.monitor_input
  rescue SystemCallError => e
    puts "#{e.class.name}: #{e.message}. Re-connection"
    @irc.disconnect rescue nil
    sleep 5
  end
end
