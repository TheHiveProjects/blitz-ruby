$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development, :test)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rake'
require 'jeweler'
require 'blitz'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "blitz"
  gem.homepage = "http://blitz.io"
  gem.license = "MIT"
  gem.summary = %Q{Make load and performance testing a fun sport}
  gem.description = %Q{Make load and performance testing a fun sport}
  gem.email = "support@blitz.io"
  gem.authors = ["pcapr"]
  gem.version = Blitz::Version
  gem.executables = ['blitz']

  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  #  gem.add_runtime_dependency 'jabber4r', '> 0.1'
  #  gem.add_development_dependency 'rspec', '> 1.2.3'
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core/rake_task'
desc "Run all the specs"
RSpec::Core::RakeTask.new do |t|
    t.pattern = ENV['file'] || 'spec/**/*_spec.rb'
    t.rspec_opts = ["--color"]
end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "blitz #{Blitz::Version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

