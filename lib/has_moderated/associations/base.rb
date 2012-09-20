module ActiveRecord
  class Base
    attr_accessor :moderation_view
  end
end

module HasModerated
  module Associations
    module Base
      
      # Class methods included into ActiveRecord::Base so that they can be called in
      # ActiveRecord models.
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
                self.send :extend, HasModerated::Associations::Collection::ClassMethods
                has_moderated_collection_association(assoc)
              when :has_one then
                self.send :extend, HasModerated::Associations::HasOne::ClassMethods
                has_moderated_has_one_association(assoc)
              when :has_and_belongs_to_many then
                self.send :extend, HasModerated::Associations::Collection::ClassMethods
                has_moderated_collection_association(assoc)
              else raise "don't know how to moderate association macro #{assoc.macro}"
            end
          end
        end

        def viewable(moderation)
          mod_obj = moderation.moderatable
          unless mod_obj.nil?
            attrs = moderation.parsed_data[:attributes]
            set_mod_associations(mod_obj, moderation.parsed_data)
          else
            attrs = moderation.parsed_data[:create][:attributes]
            mod_obj = self.new
            mod_obj.moderation_view = true
            set_mod_associations(mod_obj, moderation.parsed_data[:create])
          end
          set_mod_attrs(mod_obj, attrs)
          mod_obj.moderation_view = true
          return mod_obj
        end

        private
        def set_mod_attrs(mod_obj, attrs)
          attrs && attrs.each_pair do |key, val|
            mod_obj.send(key.to_s+"=", val) unless key.to_s == 'id'
          end
        end
 
        def set_mod_associations(mod_obj, mod_hash)
          associations = mod_hash[:associations]
          associations_array = []
          img_associations_array = []
          unless associations.blank?
            associations.each do |association_name, association_values|
              reflection = self.reflect_on_association(association_name)
              klass = eval("#{reflection.class_name}")
              if reflection.collection?
                assoc = eval('mod_obj.' + association_name.to_s)
                for association_value in association_values
                  assoc << klass.find(association_value)
                end
              else
                eval('mod_obj.' + association_name.to_s + ' = ' + "klass.find(association_values.first)")
              end
            end
          end
        end

      end # module
      
      module ApplyModeration
        # just a helper
        def self.try_without_moderation(*args, &block)
          HasModerated::Common::try_without_moderation(*args, &block)
        end
      
        def self.add_assoc_to_record(to, assoc_id, reflection)
          return unless to && assoc_id
          
          # TODO has_one weirdness?
          if reflection.macro == :has_many || reflection.macro == :has_and_belongs_to_many
            HasModerated::Associations::Collection::AssociationHelpers::add_assoc_to_record(to, assoc_id, reflection)
          end
        end
        
        def self.delete_assoc_from_record(from, assoc_id, reflection)
          return unless from && assoc_id

          if reflection.macro == :has_one
            HasModerated::Associations::HasOne::AssociationHelpers::delete_assoc_from_record(from, assoc_id, reflection)
          else
            HasModerated::Associations::Collection::AssociationHelpers::delete_assoc_from_record(from, assoc_id, reflection)
          end
        end
      
        def self.apply_add_association(to, reflection, attrs)
          klass = reflection.class_name.constantize
          fk = HasModerated::ActiveRecordHelpers::foreign_key(reflection)
        
          attrs = HashWithIndifferentAccess.new(attrs) if attrs.kind_of? Hash
          
          # TODO: perhaps allow to change existing associated object
          if attrs.class != Fixnum && !attrs[:id].blank?
            attrs = attrs[:id].to_i
          end
        
          # parse new associations
          try_without_moderation(to) do |rec|
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
              apply(arec, attrs) if attrs[:associations].present?
            else
              raise "don't know how to parse #{attrs.class}"
            end
            if arec
              try_without_moderation(arec) do
                arec.save(:validate => false) # don't run validations
                # TODO: validations? sup?
              end
              if reflection.collection?
                rec = rec.reload
                #rec.send(reflection.name.to_s) << arec unless rec.send(reflection.name.to_s).include?(arec)
              else
                rec.send(reflection.name.to_s + "=", arec)
              end
            end
          end
        end
        
        def self.apply_delete_association(to, reflection, attrs)
          m = reflection.class_name.constantize

          fk = HasModerated::ActiveRecordHelpers::foreign_key(reflection)

          return if attrs.blank?
          return if attrs.class != Fixnum
          
          try_without_moderation(to) do
            delete_assoc_from_record(to, attrs, reflection)
          end
        end
      
        # add/delete associations to a record
        def self.apply(record, data)
          associations = data[:associations]
          delete_associations = data[:delete_associations]
          
          associations && associations.each_pair do |assoc_name, assoc_records|
            reflection = record.class.reflections[assoc_name.to_sym]
          
            assoc_records.each do |attrs|
              apply_add_association(record, reflection, attrs) if attrs.present?
            end
          end
          
          delete_associations && delete_associations.each_pair do |assoc_name, assoc_records|
            reflection = record.class.reflections[assoc_name.to_sym]
            
            assoc_records.each do |attrs|
              apply_delete_association(record, reflection, attrs) if attrs.present?
            end
          end
          
          record
        end
      end # module
    end
  end
end
