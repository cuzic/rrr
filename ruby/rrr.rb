require 'net/http'
require 'net/smtp'
require 'yaml'
require 'nkf'

def main
  dir = current_dir

  yamlfilename = File.join(dir, "rrr.yaml")
  $yaml = YAML::load(open(yamlfilename).read)

  filename = ARGV.shift
  iepg = read_file filename
  title, order = compose_message iepg

  case $yaml["submit_type"]
  when "appspot"
    submit_by_appspot title, order
  when "mail"
    if $yaml["enable_tls"]
      require 'rubygems'
      require 'tlsmail'
    end
    submit_by_mail title, order
  end
end

def submit_by_mail title, order
  mailconfigs = $yaml["mail"]

  sended = false
  loop do
    mailconfigs.each do |conf|
      begin
        send_mail conf, title, order
        sended = true
#        $stderr.puts "success"
#        $stderr.puts conf.inspect
        break
      rescue Exception => e
#        $stderr.puts e.inspect
#        $stderr.puts "failed"
        next
      end
    end
    break if sended
    $stderr.puts "cannot send mail"
    exit
  end
end

def send_mail conf, title, message
  smtp = nil
  if conf["enable_tls"]
    if RUBY_PLATFORM.include?("mswin32")
      smtp = Net::SMTP.new(conf["host"], conf["port"])
      smtp.enable_tls OpenSSL::SSL::VERIFY_NONE
    else
      smtp = Net::SMTP.new(conf["host"], conf["port"])
      smtp.enable_tls OpenSSL::SSL::VERIFY_NONE
    end
  else
    smtp = Net::SMTP.new(conf["host"], conf["port"])
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
  h = {}
  text.scan(/(.+?): (.+)/) do |field, value|
    h[field] = value.chomp
  end
  h
end

def compose_message h
  rd = $yaml["rrr"]
  pre_word = "open #{rd["password"]} prog add"
  day = "#{h["year"]}#{h["month"]}#{h["date"]}"
  duration = "#{h["start"]} #{h["end"]}".gsub(":","")
  station = $yaml["stations"]
  channel = station[h["station"]]
  arg = rd["argument"]

  order = [pre_word, day, duration, channel, arg].join(" ")
  return nil, order
end

def submit_by_appspot title, command
  escaped = URI.escape command
  param = "command=#{escaped}&title=#{$yaml["rrr"]["title"]}"
  body = Net::HTTP.get($yaml["appspot"]["host"],
                       "/regist?#{param}")
end

main
