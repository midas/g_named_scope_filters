require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "g_named_scope_filters"
    gem.summary = %Q{A UI component that generates an unordered list of filters that use named scopes within an ActiveRecord model to filter a list.}
    gem.description = %Q{A UI component that generates an unordered list of filters that use named scopes within an ActiveRecord model to filter a list.  It is not tied to a table or list specifically as it simply manipulates the url, resulting  in a manipulation of any collection (list, table, etc.) it may be coupled with.}
    gem.email = "jason@lookforwardenterprises.com"
    gem.homepage = "http://github.com/midas/g_named_scope_filters"
    gem.authors = ["C. Jason Harrelson (midas)"]
    gem.add_development_dependency "rspec", ">=1.2.8"
    gem.add_dependency 'rails', ">= 2.2.0"
    gem.add_dependency 'guilded', ">=1.0.0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "test #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
