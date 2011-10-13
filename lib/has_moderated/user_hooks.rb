module HasModerated
  module UserHooks
    module ClassMethods
      def moderation_creating &block
        cattr_accessor :moderation_creating_hook
        self.moderation_creating_hook = block
      end
    end
  end
end