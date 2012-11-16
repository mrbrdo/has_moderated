$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "has_moderated/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "has_moderated"
  s.version     = HasModerated::VERSION
  s.authors     = ["Jan Berdajs"]
  s.email       = ["mrbrdo@gmail.com"]
  s.homepage    = "https://github.com/mrbrdo/has_moderated"
  s.summary     = "Moderate fields or entire model instances."
  s.description = "Moderated fields or whole model instances are serialized and saved into a separate moderations table. The moderation can then be accepted and the changes will be applied to the model. This way, lookups for existing, accepted fields or entries will be much faster than if using something like Papertrail, since the changes that have not yet been accepted are stored outside of the model table - in the moderations table."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/has_moderated/*_spec.rb"]

  s.add_dependency "rails", ">=3.0.0"

  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'rspec', ">=2.11"
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rmagick'
  s.add_development_dependency 'growl'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'carrierwave'

  s.add_development_dependency 'spork'
  s.add_development_dependency 'guard-spork'
  s.add_development_dependency 'guard-rspec'
end
