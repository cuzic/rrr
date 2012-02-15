require 'pathname'

GAE_DIR = '/cygdrive/d/Google/google_appengine'
EXERB = '/cygdrive/c/Program Files/ruby-1.8/bin/exerb.bat'

APPSERVER = File.join(GAE_DIR, 'dev_appserver.py')
APPCFG = File.join(GAE_DIR, 'appcfg.py')

RUBY_DIR = "./ruby"
EXECUTABLES = ["#{RUBY_DIR}/rrr.exe"]

desc "compile ruby scripts to rrr.exe"
task :rrr => EXECUTABLES

task :server do
  sh "python #{APPSERVER} gae"
end

task :clear do
  sh "python #{APPSERVER} --clear_datagstore gae"
end

task :update do
  sh "python #{APPCFG} update gae"
end

rule '.exy' => ['.rb'] do |t|
  pathname = Pathname.new(t.to_s)
  dirname = pathname.dirname
  basename = pathname.basename(".exy")
  Dir.chdir(dirname) do
    sh "mkexy -Ks #{basename}.rb"
  end
end

rule '.exe' => ['.exy', '.rb'] do |t|
  pathname = Pathname.new(t.source)
  dirname = pathname.dirname
  basename = pathname.basename(".exe")
  Dir.chdir(dirname) do
    sh "exerb #{t.source}"
  end
end

#rule ".exe" => ".bat" do |t|
#  pathname = Pathname.new(t.to_s)
#  dirname = pathname.dirname
#  basename = pathname.basename("exe")
#  Dir.chdir(dirname) do
#    sh "bat_to_exe_converter -bat #{pathname} -overwrite -save #{t.source}"
#  end
#end
