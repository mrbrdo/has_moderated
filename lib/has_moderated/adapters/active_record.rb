# everything that does with activerecord should be here.
# use a wrapper that calls stuff from here, so that impl. can be switched eg with mongomapper
# also write test that if one attr is moderated and one is not, the unmoderated one must still save immediately!

module HasModerated
  module Adapters
    module ActiveRecord
      