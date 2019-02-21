source 'https://rubygems.org'

gemspec

unless ENV['CI']
  gem 'guard'
  gem 'pry'
end

group :debug do
  gem 'byebug', platforms: :mri
  gem 'guard-rspec'
  gem 'psych', platforms: [:mri, :rbx]
  gem 'redcarpet', platforms: :ruby
  gem 'wirble'
end

group :test do
  gem 'equivalent-xml'
  gem 'rake'
end
