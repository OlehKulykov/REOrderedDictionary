Pod::Spec.new do |s|

# Common settings
  s.name         = "REOrderedDictionary"
  s.version      = "0.0.2"
  s.summary      = "REOrderedDictionary - ordered NSDictionary implementation"
  s.description  = <<-DESC
REOrderedDictionary - ordered NSDictionary implementation.
                      DESC
  s.homepage     = "https://github.com/OlehKulykov/REOrderedDictionary"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Oleh Kulykov" => "info@resident.name" }
  s.source       = { :git => 'https://github.com/OlehKulykov/REOrderedDictionary.git', :tag => s.version.to_s }

# Platforms
  s.ios.deployment_target = "7.0"
  s.osx.deployment_target = "10.7"
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target = '9.0'

# Build  
  s.source_files = 'REOrderedDictionary/*.{h,mm}'
  s.public_header_files = 'REOrderedDictionary/*.h'
  s.requires_arc = true
  s.libraries = 'stdc++'
end
