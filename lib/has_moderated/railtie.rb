module HasModerated
  class Railtie < Rails::Railtie
    initializer "has_moderated.include_in_activerecord" do
      ActiveRecord::Base.send :include, HasModerated
    end
  end
end