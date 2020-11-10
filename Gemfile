source 'https://rubygems.org'

gemspec

gem 'rack-linkeddata',    git: "https://github.com/ruby-rdf/rack-linkeddata",       branch: "develop"
gem "linkeddata",         git: "https://github.com/ruby-rdf/linkeddata",            branch: "develop"

group :develop do
  gem "json-ld",            git: "https://github.com/ruby-rdf/json-ld",             branch: "develop"
  gem 'json-ld-preloaded',  git: "https://github.com/ruby-rdf/json-ld-preloaded",   branch: "develop"
  gem "ld-patch",           git: "https://github.com/ruby-rdf/ld-patch",            branch: "develop"
  gem 'rdf',                git: "https://github.com/ruby-rdf/rdf",                 branch: "develop"
  gem "rdf-aggregate-repo", git: "https://github.com/ruby-rdf/rdf-aggregate-repo",  branch: "develop"
  gem 'rdf-isomorphic',     git: "https://github.com/ruby-rdf/rdf-isomorphic",      branch: "develop"
  gem 'rdf-json',           git: "https://github.com/ruby-rdf/rdf-json",            branch: "develop"
  gem 'rdf-microdata',      git: "https://github.com/ruby-rdf/rdf-microdata",       branch: "develop"
  gem 'rdf-n3',             git: "https://github.com/ruby-rdf/rdf-n3",              branch: "develop"
  gem 'rdf-normalize',      git: "https://github.com/ruby-rdf/rdf-normalize",       branch: "develop"
  gem 'rdf-rdfa',           git: "https://github.com/ruby-rdf/rdf-rdfa",            branch: "develop"
  gem 'rdf-rdfxml',         git: "https://github.com/ruby-rdf/rdf-rdfxml",          branch: "develop"
  gem 'rdf-reasoner',       git: "https://github.com/ruby-rdf/rdf-reasoner",        branch: "develop"
  gem "rdf-spec",           git: "https://github.com/ruby-rdf/rdf-spec",            branch: "develop"
  gem 'rdf-tabular',        git: "https://github.com/ruby-rdf/rdf-tabular",         branch: "develop"
  gem 'rdf-trig',           git: "https://github.com/ruby-rdf/rdf-trig",            branch: "develop"
  gem 'rdf-trix',           git: "https://github.com/ruby-rdf/rdf-trix",            branch: "develop"
  gem 'rdf-turtle',         git: "https://github.com/ruby-rdf/rdf-turtle",          branch: "develop"
  gem 'rdf-vocab',          git: "https://github.com/ruby-rdf/rdf-vocab",           branch: "develop"
  gem 'rdf-xsd',            git: "https://github.com/ruby-rdf/rdf-xsd",             branch: "develop"
  gem 'sparql',             git: "https://github.com/ruby-rdf/sparql",              branch: "develop"
  gem 'sparql-client',      git: "https://github.com/ruby-rdf/sparql-client",       branch: "develop"
end                       

group :development do
  gem "ebnf",             git: "https://github.com/dryruby/ebnf",                   branch: "develop"
  gem 'shex',             git: "https://github.com/ruby-rdf/shex",                  branch: "develop"
  gem 'sxp',              git: "https://github.com/dryruby/sxp.rb",                 branch: "develop"
end

group :debug do
  gem 'byebug', platforms: :mri
  gem 'guard-rspec'
  gem 'psych', platforms: [:mri, :rbx]
  gem 'redcarpet', platforms: :ruby
  gem 'wirble'
end

unless ENV['CI']
  gem 'guard'
  gem 'pry'
end

group :test do
  gem 'equivalent-xml'
  gem 'rake'
  gem 'simplecov',      '~> 0.16', platforms: :mri
  gem 'coveralls',      '~> 0.8', '>= 0.8.23',  platforms: :mri
end
