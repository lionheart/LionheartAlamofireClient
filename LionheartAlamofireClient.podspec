Pod::Spec.new do |s|
  s.name             = "LionheartAlamofireClient"
  s.version          = "2.2.0"
  s.summary          = "A simple class that helps manage interaction with remote APIs using Alamofire."
  s.description      = "A simple class that helps manage interaction with remote APIs using Alamofire."
  s.homepage         = "https://github.com/lionheart/LionheartAlamofireClient"
  s.license          = 'Apache 2.0'
  s.author           = { "Dan Loewenherz" => "dan@lionheartsw.com" }
  s.source           = { :git => "https://github.com/lionheart/LionheartAlamofireClient.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/dwlz'
  s.platform     = :ios, '9.0'
  s.requires_arc = true
  s.source_files = 'Pod/Classes/**/*'

  s.dependency 'Alamofire'
end
