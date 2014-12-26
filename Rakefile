# encoding: utf-8
File.expand_path('../lib', __FILE__).tap{|lib|$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)}
require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
require 'spree/testing_support/common_rake'

RSpec::Core::RakeTask.new

task :default => [:spec]

desc "Generates a dummy app for testing"
task :test_app do
  ENV['LIB_NAME'] = 'spree_social'
  Rake::Task['common:test_app'].invoke("Spree::User")
end
