module HasModerated
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      desc "This generator installs files for has_moderated."
      include Rails::Generators::Migration

      def self.source_root
        @_has_moderated_source_root ||= File.expand_path("../templates", __FILE__)
      end
      
      def files
        # class_collisions 'Moderation'
        template 'moderation.rb', File.join('app/models', 'moderation.rb')
      end

      def create_migrations
        Dir["#{self.class.source_root}/migrations/*.rb"].sort.each do |filepath|
          name = File.basename(filepath)
          migration_template "migrations/#{name}", "db/migrate/#{name.gsub(/^\d+_/,'')}"
          sleep 1
        end
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
