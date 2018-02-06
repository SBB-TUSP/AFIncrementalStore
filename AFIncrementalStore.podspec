Pod::Spec.new do |s|
  s.name         = "AFIncrementalStore"
  s.version      = "0.6.0"
  s.summary      = "Core Data Persistence with AFNetworking, Done Right."
  s.homepage     = "https://github.com/SBB-TUSP/AFIncrementalStore"
  s.author       = { "Mattt Thompson" => "m@mattt.me" }
  s.license      = 'MIT'

  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.9'

  s.source       = { :git => "https://github.com/SBB-TUSP/AFIncrementalStore.git", :tag => "0.5.1" }
  s.source_files = 'AFIncrementalStore/*.{h,m}'

  s.framework  = 'CoreData'

  s.requires_arc = true

  s.dependency 'AFNetworking', '~> 3.2.0'
  s.dependency 'InflectorKit'
  s.dependency 'TransformerKit'
end
