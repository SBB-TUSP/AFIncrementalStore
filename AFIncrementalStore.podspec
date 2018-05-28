Pod::Spec.new do |s|
  s.name         = "AFIncrementalStore"
  s.version      = "0.5.2"
  s.summary      = "Core Data Persistence with AFNetworking."
  s.homepage     = "https://github.com/SBB-TUSP/AFIncrementalStore"
  s.author       = { "Mattt Thompson" => "m@mattt.me", "Ignazio Altomare" => "ignazio.altomare@sbb.ch", "Alessandro Ranaldi" => "alessandro.ranandli@sbb.ch" }
  s.license      = 'MIT'

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'

  s.source       = { :git => "https://github.com/SBB-TUSP/AFIncrementalStore.git", :tag => "0.5.2" }
  s.source_files = 'AFIncrementalStore/*.{swift}'

  s.framework  = 'CoreData'

  s.requires_arc = true

  s.dependency 'AFNetworking', '~> 3.2.0'
  s.dependency 'InflectorKit'
  s.dependency 'TransformerKit'
end
