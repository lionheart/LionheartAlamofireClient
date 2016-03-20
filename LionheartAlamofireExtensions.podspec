Pod::Spec.new do |s|
  s.name             = "LionheartAlamofireExtensions"
  s.version          = "0.1.0"
  s.summary          = "A short description of LionheartAlamofireExtensions."

  s.description      = <<-DESC
                       DESC

  s.homepage         = "https://github.com/lionheart/LionheartAlamofireExtensions"
  s.license          = 'Apache 2.0'
  s.author           = { "Dan Loewenherz" => "dan@lionheartsw.com" }
  s.source           = { :git => "https://github.com/lionheart/LionheartAlamofireExtensions.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/dwlz'
  s.platform     = :ios, '8.0'
  s.requires_arc = true
  s.source_files = 'Pod/Classes/**/*'
  s.dependency 'Alamofire'
end
