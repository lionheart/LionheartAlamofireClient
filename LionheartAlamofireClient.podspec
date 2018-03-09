# vim: ft=ruby

Pod::Spec.new do |s|
  s.name             = "LionheartAlamofireClient"
  s.version          =  "2.2.2"
  s.summary          = "A simple class that helps manage interaction with remote APIs using Alamofire."
  s.description      = "This is a simple class that helps manage interaction with remote APIs using Alamofire."
  s.homepage         = "https://github.com/lionheart/LionheartAlamofireClient"
  s.license          = 'Apache 2.0'
  s.author           = { "Dan Loewenherz" => "dan@lionheartsw.com" }
  s.source           = { :git => "https://github.com/lionheart/LionheartAlamofireClient.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/lionheartsw'
  s.platform         = :ios, '10.3'
  s.requires_arc     = true
  s.source_files     = 'Pod/Classes/**/*'
  s.swift_version    = "4.0"

  s.dependency 'Alamofire'
end
