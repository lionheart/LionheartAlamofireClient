Pod::Spec.new do |s|
  s.name             = "LionheartAlamofireClient"
  s.version          = "1.0.0"
  s.summary          = "A helpful class and process to manage hitting a remote API with Alamofire"

  s.homepage         = "https://github.com/lionheart/LionheartAlamofireClient"
  s.license          = 'Apache 2.0'
  s.author           = { "Dan Loewenherz" => "dan@lionheartsw.com" }
  s.source           = { :git => "https://github.com/lionheart/LionheartAlamofireClient.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/dwlz'
  s.platform     = :ios, '8.0'
  s.requires_arc = true
  s.source_files = 'Pod/Classes/**/*'
  s.dependency 'Alamofire'
end
