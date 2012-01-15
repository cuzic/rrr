require 'net/http'
require 'net/smtp'
require 'yaml'
require 'nkf'
require 'sdbm'

at_exit do
  $sdbm.close if $sdbm
end

def main
  dir = current_dir

  yamlfilename = File.join(dir, "rrr.yaml")
  $yaml = YAML::load(open(yamlfilename).read)
  if ARGV.empty? then
    iepg = parse_iepg $stdin.read
  else
    filename = ARGV.join(" ")
    iepg = read_file filename
  end
  $sdbm = SDBM.open("rrr.sdbm",0644)
  $sdbm.delete_if do |k, value|
    value < (Time.now - 60*60*24*7).strftime("%Y%m%d")
  end
  title = iepg["program-title"]
  if $sdbm[title] then
    raise "already reserved #{title}"
  end
  $sdbm[title] = %w(year month date).map{|k| iepg[k]}.join("")
  title, order = compose_message iepg

  case $yaml["submit_type"]
  when "appspot"
    submit_by_appspot title, order
  when "mail"
    if RUBY_PLATFORM.include?("mswin32") and $yaml["enable_tls"]
      require 'rubygems'
      require 'tlsmail'
    end
    submit_by_mail title, order
  end
end

def submit_by_mail title, order
  mailconfigs = $yaml["mail"]

  mailconfigs.each do |conf|
    begin
      send_mail conf, title, order
      return
    rescue Exception => e
      $stderr.puts e.inspect
      $stderr.puts "failed"
      next
    end
  end
end

def send_mail conf, title, message
  smtp = Net::SMTP.new(conf["host"], conf["port"])
  if conf["enable_tls"]
    smtp.enable_tls OpenSSL::SSL::VERIFY_NONE
  end
  sender = conf["sender"]
  username = conf["username"] || conf["sender"]
  recipients = conf["recipients"]
  if conf["notauth"]
    auth = []
  else
    auth = [username, conf["password"], :login]
  end

  smtp.start(conf["host"], *auth) do |smtp|
    smtp.send_mail <<EOD , sender, *recipients
From: <#{sender}>
To: #{recipients.map{|addr| "<#{addr}>"}.join(", ")}
Subject: #{title}

#{message}
EOD
  end
end

def current_dir
  dir = nil
  if defined? ExerbRuntime
    dir = File.dirname(ExerbRuntime.filepath)
  else
    dir = File.dirname(File.expand_path($0))
  end
  return dir
end

def read_file filename
  text = IO.read filename
  File.unlink filename
  parse_iepg text
end

def parse_iepg iepg_text
  h = {}
  iepg_text.scan(/(.+?): (.+)/) do |field, value|
    h[field] = value.chomp
  end
  h
end

def compose_message h
  rd = $yaml["rrr"]
  pre_word = "open #{rd["password"]} prog add"
  day = "#{h["year"]}#{h["month"]}#{h["date"]}"
  duration = "#{h["start"]} #{h["end"]}".gsub(":","")
  stations = $yaml["stations"]
  station = h["station"]
  channel = stations[station]
  if channel.nil?
    raise "cannot find CH #{station}"
  end
  arg = rd["argument"]
  title = h["program-title"]

  return "rrr #{day} #{duration} #{channel}", <<EOD
#{pre_word} #{day} #{duration} #{channel} #{arg}
#{title}
EOD
end

def submit_by_appspot title, command
  escaped = URI.escape command
  param = "command=#{escaped}&title=#{$yaml["rrr"]["title"]}"
  body = Net::HTTP.get($yaml["appspot"]["host"],
                       "/regist?#{param}")
end

if $0 == __FILE__ then
  main
end
