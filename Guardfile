guard 'spork', :rspec => true, :rspec_env => { 'RAILS_ENV' => 'test' } do
  watch('has_moderated.gemspec')
  watch('Gemfile')
  watch('Gemfile.lock')
  watch('spec/spec_helper.rb') { :rspec }
  watch(%r{^spec/support/.+\.rb$}) { :rspec }
  watch(%r{^lib/has_moderated/.+\.rb$})
end

guard 'rspec', :version => 2, :cli => '--color --fail-fast --drb', :spec_paths => ["spec"], :all_after_pass => false do
  watch(%r{^spec/.+_spec\.rb$})
  watch('spec/spec_helper.rb')  { "spec" }

  # Rails example
  watch(%r{^spec/support/(.+)\.rb$})                  { "spec" }
  watch(%r{^lib/has_moderated/.+\.rb$}) { "test/dummy/spec" }
end
