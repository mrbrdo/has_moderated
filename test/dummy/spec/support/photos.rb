require 'fileutils'

def dirEmpty? dirname
  return true unless File.directory?(dirname)
  Dir.entries(dirname).size == 2
end

def tmpEmpty?
  dirEmpty?(TEMPDIR)
end

TEMPDIR = File.expand_path("../../../public/uploads/tmp", __FILE__)
UPLOADDIR = "/Users/apple/rails/has_moderated/test/dummy/public/uploads/photo/photo/1"

def carrierwave_test_photo
  test_photo_path = File.expand_path("../../../public/test.jpg", __FILE__)
  File.open(test_photo_path, "r")
end

def assert_photo_uploaded photo
  photo.should_not be_nil
  photo.file.should_not be_nil
  photo.file.file.should_not be_nil
  
  filename = photo.file.file
  File.exist?(filename)
  assert(filename =~ /photo\/1\/test.jpg\Z/)
end