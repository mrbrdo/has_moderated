module HasModerated
  module Associations
    module Base
      
      # Class methods included into ActiveRecord::Base so that you can call them in
      # your ActiveRecord models.
      module ClassMethods
        
        # Will moderate the passed in associations if they are supported.
        # Example: has_moderated_association(:posts, :comments).
        # Also supports passing :all to moderate all associations, but I personally
        # do not recommend using this option.
        # @param [Hash] associations the associations to moderate
        def has_moderated_association(*args)
          # some common initialization (lazy loading)
          HasModerated::Common::init(self)
          
          args = [args] unless args.kind_of? Array

          # handle :all option
          assoc_names = if args.include?(:all)
            self.reflections.keys.reject do |r|
              r == :moderations
            end
          else
            args
          end
          
          # process associations + lazy loading
          assoc_names.map{ |name| self.reflections[name] }.each do |assoc|
            case assoc.macro
              when :has_many then
                self.send :extend, HasModerated::Associations::HasMany::ClassMethods
                has_moderated_has_many_association(assoc)
              when :has_one then
                self.send :extend, HasModerated::Associations::HasOne::ClassMethods
                has_moderated_has_one_association(assoc)
              else raise "don't know how to moderate association macro #{assoc.macro}"
            end
          end
        end
      end # module
      
      module CreateModeration
        # Convert records to an array of record ids or attribute hashes.
        # This is serialized to YAML and saved as moderation data in the database.
        def self.hashize_association_records records
          records.map do |record|
            if record.class == Fixnum   # id
              record
            elsif record.kind_of? Hash  # already a hash (for has_many :through association)
              record
            elsif record.respond_to?(:new_record?) # is ActiveRecord class? TODO: check nicer
              record.get_moderation_attributes
            else
              raise "don't know how to convert #{record.class} to hash"
            end
          end
        end
      
        def self.add_associations_moderation to, assocs_hash
          # convert records to correct format
          assocs_hash.keys.each do |name|
            assocs_hash[name] = hashize_association_records(assocs_hash[name])
          end
          to.create_moderation_with_hooks!({
              :attr_name => "-",
              :attr_value => { :associations => assocs_hash }
            })
        end
      end
      
      module ApplyModeration
        # just a helper
        def self.try_disable_moderation(*args, &block)
          HasModerated::Common::try_disable_moderation(*args, &block)
        end
      
        def self.add_assoc_to_record(to, record, reflection)
          return unless to && record

          if reflection.macro == :has_many
            HasModerated::Associations::HasMany::add_assoc_to_record(to, record, reflection)
            # ok
          end
        end
      
        def self.apply_add_association(to, reflection, attrs)
          klass = reflection.class_name.constantize
          fk = HasModerated::Common::foreign_key(reflection)
        
          attrs = HashWithIndifferentAccess.new(attrs) if attrs.kind_of? Hash
          
          # TODO: perhaps allow to change existing associated object
          if attrs.class != Fixnum && !attrs[:id].blank?
            attrs = attrs[:id].to_i
          end
        
          # parse new associations
          try_disable_moderation(to) do |rec|
            arec = nil
            # PARAM = ID
            if attrs.class == Fixnum
              arec = klass.find_by_id(attrs)
              add_assoc_to_record(rec, arec, reflection)
            # PARAM = Hash (create)
            elsif attrs.kind_of? Hash
              arec = klass.new
              # set foreign key first, may be required sometimes
              add_assoc_to_record(rec, arec, reflection)
              attrs.each_pair do |key, val|
                next if key.to_s == 'associations' || key.to_s == 'id' || key.to_s == fk
                arec.send(key.to_s+"=", val)
              end
              # recursive, used for has_many :through
              apply_moderation(arec, attrs[:associations]) if attrs[:associations].present?
            else
              raise "don't know how to parse #{attrs.class}"
            end
            if arec
              try_disable_moderation(arec) do
                arec.save(:validate => false) # don't run validations
                # TODO: validations? sup?
              end
              if reflection.collection?
                rec.send(reflection.name.to_s) << arec
              else
                rec.send(reflection.name.to_s + "=", arec)
              end
            end
          end
        end
      
        # add/delete associations to a record
        def self.apply(record, associations)
          associations.each_pair do |assoc_name, assoc_records|
            reflection = record.class.reflections[assoc_name.to_sym]
          
            assoc_records.each do |attrs|
              apply_add_association(record, reflection, attrs) if attrs.present?
            end
          end
        end
      end # module
    end
  end
end