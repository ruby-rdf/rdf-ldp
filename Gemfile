source 'https://rubygems.org'

gemspec

unless ENV['CI']
  gem 'guard'
  gem 'pry'
end

group :debug do
  gem 'byebug', platforms: :mri
  gem 'debugger', platforms: :mri_19
  gem 'guard-rspec'
  gem 'pry', platforms: :rbx
  gem 'psych', platforms: [:mri, :rbx]
  gem 'redcarpet', platforms: :ruby
  gem 'ruby-debug', platforms: :jruby
  gem 'wirble'
end

group :test do
  gem 'equivalent-xml'
  gem 'rake'
end

platforms :rbx do
  gem 'rubinius', '~> 2.0'
  gem 'rubysl', '~> 2.0'
end
