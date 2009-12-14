class SetupWizard
  def self.create
    config=Hash.new unless config
    config['server']=ask("irc server : ") do |q|
      q.default=config['server']||"irc.freenode.net"
    end

    config['password']=ask("irc server password : ")

    config['port']=ask("irc port : ",Integer) do |q|
      q.default=config['port']||6667
    end

    config['nick']=ask("bot name : ") do |q|
      q.default=config['nick']||"botty"
    end

    config['channel']=ask("irc channel : ") do |q|
      q.default=config['channel']||"#bottest"
    end

    config['monitor_dir']=ask("monitor which directory for txt files : ") do |q|
      q.default=config['monitor_dir']||"/tmp/to_irc"
    end
    
    puts "generated your config, going on with main program..."
    File.open(File.expand_path('config.yml'),'w+'){ |f| f.write(YAML::dump(config)) }
    return config
  end
end