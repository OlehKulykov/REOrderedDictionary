Pod::Spec.new do |s|

# Common settings
  s.name         = "NSOrderedDictionary"
  s.version      = "0.0.1"
  s.summary      = "NSOrderedDictionary - ordered NSDictionary implementation"
  s.description  = <<-DESC
NSOrderedDictionary - ordered NSDictionary implementation.
                      DESC
  s.homepage     = "https://github.com/OlehKulykov/NSOrderedDictionary"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Oleh Kulykov" => "info@resident.name" }
  s.source       = { :git => 'https://github.com/OlehKulykov/NSOrderedDictionary.git', :tag => s.version.to_s }

# Platforms
  s.ios.deployment_target = "7.0"
  s.osx.deployment_target = "10.7"
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target = '9.0'

# Build  
  s.source_files = 'NSOrderedDictionary/*.{h,mm}'
  s.public_header_files = 'NSOrderedDictionary/*.h'
  s.requires_arc = true
  s.libraries = 'stdc++'
end
