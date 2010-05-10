$:.unshift File.expand_path("../lib", __FILE__)

require 'rubygems'
require 'rake/gempackagetask'
require 'acrosslite'
 
lib_dir = File.expand_path('lib')
spec_dir = File.expand_path('spec')

gem_spec = Gem::Specification.new do |s|
  s.name = "acrosslite"
  s.version = Acrosslite::VERSION
  s.authors = ["Samuel Mullen"]
  s.email = "samullen@gmail.com"
  s.homepage = "http://github.com/samullen/acrosslite"
  s.summary = "A Ruby library for parsing Across Lite puzzle (.puz) files"
  s.description = false
  s.test_files = Dir['spec/**/*']
  s.add_development_dependency "rspec"
  s.files = [
    "LICENSE",
    "README.rdoc",
    "Rakefile",
    "lib/acrosslite.rb",
    "lib/entry.rb"
  ] + s.test_files
end

begin
  require 'spec/rake/spectask'
rescue LoadError
  task :spec do
    $stderr.puts '`gem install rspec` to run specs'
  end
else
  desc "Run specs"
  Spec::Rake::SpecTask.new do |t|
    t.spec_files = Dir['spec/**/*.rb']
    t.spec_opts  = %w(-fs --color)
  end
end

Rake::GemPackageTask.new(gem_spec) do |pkg|
  pkg.need_zip = false
  pkg.need_tar = false
end

desc "Install the gem locally"
task :install => [:spec, :gem] do
  sh %{gem install pkg/#{gem_spec.name}-#{gem_spec.version}}
end

desc "Remove the pkg directory and all of its contents."
task :clean => :clobber_package

task :default => [:spec, :gem]
