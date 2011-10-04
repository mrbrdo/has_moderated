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
    
    def update_associations_from_value rec
      # loop association types, e.g. :comments
      interpreted_value[:associations].each_pair do |assoc_name, assoc_records|
        # read reflections attribute to determine proper class name and primary key
        assoc_details = rec.class.reflections[assoc_name.to_sym]
        m = assoc_details.class_name.constantize

        # all instances for this association type
        assoc_records.each do |attrs|
        # PARAM = ID
          if attrs.class == Fixnum
            arec = m.find_by_id(attrs)
            # add the association, if the record still existss
            rec.send(assoc_name.to_s) << arec if arec
        # PARAM = Hash (create)
          else
            arec = m.new
            # set foreign key first, may be required sometimes
            fk = if assoc_details.respond_to?(:foreign_key)
              assoc_details.foreign_key
            else # Rails < v3.1
              assoc_details.primary_key_name
            end
            arec.send(fk.to_s+"=", rec.id) # set association to the newly created record
            attrs.each_pair do |key, val|
              arec.send(key.to_s+"=", val) unless key.to_s == 'id'
            end
            # disable moderation for associated model (if moderated)
            arec.has_moderated_updating = true if arec.respond_to?("has_moderated_updating=")
            arec.save(:validate => false) # don't run validations
            arec.has_moderated_updating = false if arec.respond_to?("has_moderated_updating=")
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