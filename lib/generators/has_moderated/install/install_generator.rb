module HasModerated
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      desc "This generator installs files for has_moderated."
      source_root File.expand_path('../templates', __FILE__)
      include Rails::Generators::Migration

      def files
        class_collisions 'Moderation'
        template 'moderation.rb', File.join('app/models', 'moderation.rb')
        migration_template 'migration.rb', 'db/migrate/create_moderations.rb'
      end

      private
        def self.next_migration_number(dirname) #:nodoc:
          if ActiveRecord::Base.timestamped_migrations
            Time.now.utc.strftime("%Y%m%d%H%M%S")
          else
            "%.3d" % (current_migration_number(dirname) + 1)
          end
        end
    end
  end
end
