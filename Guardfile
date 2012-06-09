guard 'spork', :rspec => true, :rspec_env => { 'RAILS_ENV' => 'test' } do
  watch('test/dummy/config/application.rb')
  watch('test/dummy/config/environment.rb')
  watch(%r{^test/dummy/config/environments/.+\.rb$})
  watch(%r{^test/dummy/config/initializers/.+\.rb$})
  watch('has_moderated.gemspec')
  watch('Gemfile')
  watch('Gemfile.lock')
  watch('test/dummy/spec/spec_helper.rb') { :rspec }
  watch(%r{^test/dummy/spec/support/.+\.rb$}) { :rspec }
  watch(%r{^lib/has_moderated/.+\.rb$})
end

guard 'rspec', :version => 2, :cli => '--color --fail-fast --drb', :spec_paths => ["test/dummy/spec"], :all_after_pass => false do
  watch(%r{^test/dummy/spec/.+_spec\.rb$})
  watch(%r{^test/dummy/lib/(.+)\.rb$})     { |m| "test/dummy/spec/lib/#{m[1]}_spec.rb" }
  watch('test/dummy/spec/spec_helper.rb')  { "test/dummy/spec" }

  # Rails example
  watch(%r{^test/dummy/app/(.+)\.rb$})                           { |m| "test/dummy/spec/#{m[1]}_spec.rb" }
  watch(%r{^test/dummy/spec/support/(.+)\.rb$})                  { "test/dummy/spec" }
  watch(%r{^lib/has_moderated/.+\.rb$}) { "test/dummy/spec" }
end
