module HasModerated
  module ModerationModel
    
    def interpreted_value
      @interpreted_value ||= if attr_name == '-'
        YAML::load(attr_value)
      else
        attr_value
      end
    end
    
    def create_from_value
      if moderatable_id.blank?
        # create the main record
        rec = moderatable_type.constantize.new
        attrs = interpreted_value[:main_model]
        # bypass attr_accessible protection
        attrs && attrs.each_pair do |key, val|
          rec.send(key.to_s+"=", val) unless key.to_s == 'id'
        end
        rec
      else
        nil
      end
    end
    
    def delete_assoc_from_record arec, rec, assoc_name
      return unless rec && arec
      
      assoc = rec.class.reflections[assoc_name.to_sym]
      
      if assoc.macro == :has_and_belongs_to_many || !assoc.options[:through].blank? || assoc.macro == :has_many
        rec.send(assoc_name).delete(arec)
      else
        raise "Cannot delete association for this type of associations!"
      end
    end
    
    def delete_associations_from_value rec, interpreted_assocs = nil
      interpreted_assocs ||= interpreted_value[:delete_associations]
      # in case it's empty
      interpreted_assocs ||= {}
      
      interpreted_assocs.each_pair do |assoc_name, assoc_records|
        # read reflections attribute to determine proper class name and primary key
        assoc_details = rec.class.reflections[assoc_name.to_sym]
        m = assoc_details.class_name.constantize
        
        fk = if assoc_details.respond_to?(:foreign_key)
          assoc_details.foreign_key
        else # Rails < v3.1
          assoc_details.primary_key_name
        end

        # all instances for this association type
        assoc_records.each do |attrs|
          next if attrs.blank?
          next if attrs.class != Fixnum
          try_moderatable_updating(rec) do
            arec = nil
          # PARAM = ID
            arec = m.find_by_id(attrs)
            delete_assoc_from_record(arec, rec, assoc_name)
          end
        end
      end
    end
    
    def add_assoc_to_record arec, rec, assoc_name
      return unless rec && arec
      
      assoc = rec.class.reflections[assoc_name.to_sym]
      
      if assoc.macro == :has_and_belongs_to_many || !assoc.options[:through].blank?
        field = if !assoc.options[:join_table].blank?
          jointable = assoc.options[:join_table].to_s
          results = arec.class.reflections.reject do |assoc_name, assoc|
            !(assoc.options[:join_table] && assoc.options[:join_table].to_s == jointable)
          end
          if results.blank?
            raise "has_moderated: Cannot determine join table for a Habtm association!"
          end
          results.first[1].name.to_s
        else
          rec.class.to_s.underscore.pluralize
        end
        arec.send(field) << rec
      elsif assoc.macro == :has_many || assoc.macro == :has_one
        field = if !assoc.options[:as].blank?
          assoc.options[:as].to_s
        elsif !assoc.options[:foreign_key].blank?
          fk = assoc.options[:foreign_key].to_s
          results = arec.class.reflections.reject do |assoc_name, assoc|
            !(assoc.options[:foreign_key] && assoc.options[:foreign_key].to_s == fk)
          end
          if results.blank?
            raise "Please set foreign_key for both belongs_to and has_one/has_many!"
          end
          results.first[1].name.to_s
        else
          rec.class.to_s.underscore
        end
        arec.send(field + "=", rec)
      end
    end
    
    def try_moderatable_updating rec
      rec.has_moderated_updating = true if rec.respond_to?("has_moderated_updating=")
      yield(rec)
      rec.has_moderated_updating = false if rec.respond_to?("has_moderated_updating=")
    end
    
    def update_associations_from_value rec, interpreted_assocs = nil
      interpreted_assocs ||= interpreted_value[:associations]
      # in case it's empty
      interpreted_assocs ||= {}
      # loop association types, e.g. :comments
      interpreted_assocs.each_pair do |assoc_name, assoc_records|
        # read reflections attribute to determine proper class name and primary key
        assoc_details = rec.class.reflections[assoc_name.to_sym]
        m = assoc_details.class_name.constantize
        
        fk = if assoc_details.respond_to?(:foreign_key)
          assoc_details.foreign_key
        else # Rails < v3.1
          assoc_details.primary_key_name
        end

        # all instances for this association type
        assoc_records.each do |attrs|
          next if attrs.blank?
          if attrs.class != Fixnum && !attrs[:id].blank?
            attrs = attrs[:id].to_i
          end
          try_moderatable_updating(rec) do
            arec = nil
          # PARAM = ID
            if attrs.class == Fixnum
              arec = m.find_by_id(attrs)
              add_assoc_to_record(arec, rec, assoc_name)
          # PARAM = Hash (create)
            else
              arec = m.new
              # set foreign key first, may be required sometimes
              add_assoc_to_record(arec, rec, assoc_name)
              attrs && attrs.each_pair do |key, val|
                next if key.to_s == "associations" || key.to_s == 'id' || key.to_s == fk
                arec.send(key.to_s+"=", val)
              end
              if attrs[:associations]
                update_associations_from_value arec, attrs[:associations]
              end
            end
            if arec
              try_moderatable_updating(arec) do
                arec.save(:validate => false) # don't run validations
              end
              if assoc_details.collection?
                rec.send(assoc_name.to_s) << arec if arec
              else
                rec.send(assoc_name.to_s + "=", arec) if arec
              end
            end
          end
        end
      end
    end
    
    def accept
      # DESTROY
      if attr_name == '-' && attr_value.class == String && attr_value == "destroy"
        moderatable.moderatable_updating { moderatable.destroy }
        self.destroy
      
      # CREATE or ASSOCIATIONS
      elsif attr_name == '-'
        loaded_val = YAML::load(attr_value)
        # case: moderated existance (new record)
        if moderatable_id.blank?
          rec = create_from_value
          # save, don't run validations
          rec.moderatable_updating { rec.save(:validate => false) }
        # case: moderated associations (existing record)
        else
          rec = moderatable
        end

        # check for saved associated records
        update_associations_from_value rec
        delete_associations_from_value rec
        
        self.destroy # destroy this moderation since it has been applied
        rec
        
      # CHANGE ATTRIBUTE
      else
        moderatable.moderatable_updating do
          # bypass attr_accessible protection
          moderatable.send(attr_name.to_s+"=", YAML::load(attr_value))
          moderatable.save(:validate => false) # don't run validations
        end
        self.destroy # destroy this moderation since it has been applied
      end
    end

    def discard
      if moderatable_type
        klass = moderatable_type.constantize
        klass.moderatable_discard(self) if klass.respond_to?(:moderatable_discard)
      end
      self.destroy
    end
  end
end