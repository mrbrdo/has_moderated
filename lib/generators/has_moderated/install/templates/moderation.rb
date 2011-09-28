class Moderation < ActiveRecord::Base
  belongs_to :moderatable, :polymorphic => true

  def accept
    # case: moderated destruction
    if attr_name == '-' && attr_value.class == String && attr_value == "destroy"
      moderatable.has_moderated_updating = true
      moderatable.destroy
      moderatable.has_moderated_updating = false
      self.destroy
    elsif attr_name == '-'
      loaded_val = YAML::load(attr_value)
      # case: moderated existance (new record)
      if moderatable_id.blank?
        # create the main record
        rec = moderatable_type.constantize.new
        attrs = loaded_val[:main_model]
        # bypass attr_accessible protection
        attrs.each_pair do |key, val|
          rec.send(key.to_s+"=", val) unless key.to_s == 'id'
        end
        # temporarily disable moderation check on save, and save updated record
        rec.has_moderated_updating = true
        rec.save(:validate => false) # don't run validations
        rec.has_moderated_updating = false
      # case: moderated associations (existing record)
      else
        rec = moderatable
      end

      # check for saved associated records
      loaded_val[:associations].each_pair do |assoc_name, assoc_records|
        # read reflections attribute to determine proper class name and primary key
        assoc_details = rec.class.reflections[assoc_name.to_sym]
        m = assoc_details.class_name.constantize

        # all records for this associated model
        assoc_records.each do |attrs|
          if attrs.class == Fixnum # associate to existing record
            arec = m.find_by_id(attrs)
            rec.send(assoc_name.to_s) << arec if arec # add the association, if the record still exists
          else # create a new record
            arec = m.new # new associated model
            attrs.each_pair do |key, val|
              arec.send(key.to_s+"=", val) unless key.to_s == 'id'
            end
            fk = if assoc_details.respond_to?(:foreign_key)
              assoc_details.foreign_key
            else # version < 3.1
              assoc_details.primary_key_name
            end
            arec.send(fk.to_s+"=", rec.id) # set association to the newly created record
            # disable moderation for associated model (if enabled)
            arec.has_moderated_updating = true if arec.respond_to?("has_moderated_updating=")
            arec.save(:validate => false) # don't run validations
            arec.has_moderated_updating = false if arec.respond_to?("has_moderated_updating=")
          end
        end
      end
      self.destroy # destroy this moderation since it has been applied
      rec
    # case: moderated attribute (existing record)
    else
      moderatable.has_moderated_updating = true
      # bypass attr_accessible protection
      moderatable.send(attr_name.to_s+"=", YAML::load(attr_value))
      moderatable.save(:validate => false) # don't run validations
      moderatable.has_moderated_updating = false
      self.destroy # destroy this moderation since it has been applied
    end
  end

  def discard
    self.destroy
  end
end
