require 'net/http'
require 'yaml'

def main
  dir = current_dir
  yamlfilename = File.join(dir, "rrr.yaml")
  $yaml = YAML::load(open(yamlfilename).read)

  filename = ARGV.shift
  iepg = read_file filename
  title, order = compose_message iepg
  submit_appspot title, order
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

  title = h["program-title"]
  order = [pre_word, day, duration, channel, arg].join(" ")
  return title, order
end

def submit_appspot title, command
  escaped = URI.escape command
  param = "command=#{escaped}&title=#{$yaml["rrr"]["title"]}"
  body = Net::HTTP.get($yaml["appspot"]["host"],
                       "/regist?#{param}")
end

main
