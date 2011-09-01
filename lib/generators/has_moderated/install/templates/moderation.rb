class Moderation < ActiveRecord::Base
  belongs_to :moderatable, :polymorphic => true

  def accept
    # case: moderated existance (new record)
    if attr_name == '-'
      # create the main record
      rec = moderatable_type.constantize.new
      loaded_val = YAML::load(attr_value)
      attrs = loaded_val[:main_model]
      # bypass attr_accessible protection
      attrs.each_pair do |key, val|
        rec.send(key.to_s+"=", val) unless key.to_s == 'id'
      end
      # temporarily disable moderation check on save, and save updated record
      rec.has_moderated_updating = true
      rec.save
      rec.has_moderated_updating = false

      # check for saved associated records
      loaded_val[:associations].each_pair do |assoc_name, assoc_records|
        # read reflections attribute to determine proper class name and primary key
        assoc_details = rec.class.reflections[assoc_name.to_sym]
        m = assoc_details.class_name.constantize

        # all records for this associated model
        assoc_records.each do |attrs|
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
          arec.save
          arec.has_moderated_updating = false if arec.respond_to?("has_moderated_updating=")
        end
      end
      self.destroy # destroy this moderation since it has been applied
      rec
    # case: moderated attribute (existing record)
    else
      moderatable.has_moderated_updating = true
      # bypass attr_accessible protection
      moderatable.send(attr_name.to_s+"=", YAML::load(attr_value))
      moderatable.save
      moderatable.has_moderated_updating = false
      self.destroy # destroy this moderation since it has been applied
    end
  end

  def discard
    self.destroy
  end
end
