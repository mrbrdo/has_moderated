require 'fileutils'

def dirEmpty? dirname
  return true unless File.directory?(dirname)
  Dir.entries(dirname).size == 2
end

def tmpEmpty?
  dirEmpty?(TEMPDIR)
end

def uploadEmpty?
  photoModel = crazy_models.get_klass(:Photo)
  dir = File.expand_path("../../../public/uploads/#{photoModel.to_s.underscore}/avatar", __FILE__)
  dirEmpty?(dir)
end

TEMPDIR = File.expand_path("../../../public/uploads/tmp", __FILE__)

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
  assert(filename =~ /avatar\/1\/test.jpg\Z/)
end