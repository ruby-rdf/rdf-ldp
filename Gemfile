source "https://rubygems.org"

gemspec

gem 'pry'

group :develop do
  gem 'rdf',                git: "git://github.com/ruby-rdf/rdf.git", branch: "develop"
  gem 'ld-patch',           git: "git://github.com/gkellogg/ld-patch.git", branch: "develop"
  gem "rdf-spec",           git: "git://github.com/ruby-rdf/rdf-spec.git", branch: "develop"
  gem 'linkeddata',         git: "git://github.com/ruby-rdf/linkeddata.git", branch: "develop"
end

group :debug do
  gem 'psych', :platforms => [:mri, :rbx]
  gem "wirble"
  gem "redcarpet", :platforms => :ruby
  gem "debugger", :platforms => :mri_19
  gem "byebug", :platforms => :mri
  gem "ruby-debug", :platforms => :jruby
  gem "pry", :platforms => :rbx
  gem 'guard-rspec'
end

group :test do
  gem "rake"
  gem "equivalent-xml"
end

platforms :rbx do
  gem 'rubysl', '~> 2.0'
  gem 'rubinius', '~> 2.0'
end
