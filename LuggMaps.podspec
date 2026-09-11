require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "LuggMaps"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => min_ios_version_supported }
  s.source       = { :git => "https://github.com/lugg/maps.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,swift,cpp}"
  s.private_header_files = "ios/**/*.h"

  # `$LuggMapsGoogleEnabled = false` in the Podfile drops the Google Maps SDK (Apple Maps only)
  google_enabled = defined?($LuggMapsGoogleEnabled) ? $LuggMapsGoogleEnabled : true
  s.pod_target_xcconfig = {
    "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) LUGG_GOOGLE_MAPS_ENABLED=#{google_enabled ? 1 : 0}"
  }
  if google_enabled
    s.dependency "GoogleMaps"
  else
    s.exclude_files = "ios/core/Google*", "ios/core/GMS*"
  end
  s.frameworks = "MapKit"

  install_modules_dependencies(s)
end
