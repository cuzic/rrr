#!/usr/bin/env ruby
# -*- encoding: cp932 -*-

def wget url
  arguments = {
    "--user-agent" => %{Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.3) Gecko/2008092416 Firefox/3.0.3},
    "-x" => "",
    "--load-cookies" => "cookies.txt",
    "-O" => "-",
    "-q" => "",
  }

  arg = arguments.map do |k, v|
    v.empty? ? k : %(#{k} "#{v}")
  end.join(" ")
  cmdline = "wget #{arg} #{url}"
  `#{cmdline}`
end

def index
  url = "http://tv.so-net.ne.jp/m/schedulesByFilter.action"
  body = wget url
  body.scan(%r(href="/iepg.tvpid\?id=(\d+)")) do |id,|
    yield id
  end
end

def get_iepg id
  url = "http://tv.so-net.ne.jp/iepg.tvpid?id=#{id}"
  body = wget url
end

def rrr iepg
  IO.popen("ruby rrr.rb", "w") do |io|
    io.write iepg
  end
end

def main
  index do |id|
    iepg = get_iepg id
    rrr iepg
  end
end

if $0 == __FILE__ then
  main
end
