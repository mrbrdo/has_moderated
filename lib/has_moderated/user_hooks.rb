module HasModerated
  module UserHooks
    module ClassMethods
      def moderation_creating &block
        cattr_accessor :moderation_hooks
        self.moderation_hooks ||= { :creating => [] }
        self.moderation_hooks[:creating].push(block)
      end
    end
  end
end