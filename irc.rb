#!/usr/bin/ruby
require "rubygems"
require 'fileutils'
require "socket"
require './lib/setup_wizard.rb'

begin
  require 'highline/import'
rescue LoadError => e
  $stderr.puts "You need to install the the highline gem to require 'highline/import'"
  exit 1
end

Signal.trap("SIGINT") do
  begin
    puts "Stopping..."
    irc.disconnect
  rescue
    puts "could not disconnect"
  end
  exit(0)
end

class IRC
  def initialize(options=Hash.new)
    if File.exists?(File.expand_path('config.yml'))
      config = YAML.load_file(File.expand_path('config.yml'))
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
    # s.gsub!("Wes Oldenbeuving","Narnach")
    case s
    when /^(PASS|USER|NICK|JOIN|PING|QUIT)/
      @irc.send "#{s}\n", 0 
    else
      puts "seding #{s} "
      @irc.send "PRIVMSG #{@channel} : #{s}\n", 0
    end
  end

  def connect()
    # Connect to the IRC server
    @irc = TCPSocket.open(@server, @port)
    send "PASS #{@password}"
    send "USER #{@nick} 8 * :#{@nick}"
    send "NICK #{@nick}"
    send "JOIN #{@channel}"
  end
  def disconnect()
    @irc.send "QUIT", 0 
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

irc=IRC.new
puts "connecting..."
irc.connect
puts "connected !"

irc.monitor_input while true
puts "disconnecting..."
irc.disconnect
puts "done"
