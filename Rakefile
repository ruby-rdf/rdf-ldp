#!/usr/bin/env ruby
$:.unshift(File.expand_path('../lib', __FILE__))
require 'rubygems'

namespace :gem do
  desc "Build the rdf-ldp-#{File.read('VERSION').chomp}.gem file"
  task :build do
    sh "gem build rdf-ldp.gemspec && mv rdf-ldp-#{File.read('VERSION').chomp}.gem pkg/"
  end

  desc "Release the rdf-ldp-#{File.read('VERSION').chomp}.gem file"
  task :release do
    sh "gem push pkg/rdf-ldp-#{File.read('VERSION').chomp}.gem"
  end
end
