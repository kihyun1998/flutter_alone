#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_alone.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_alone'
  s.version          = '3.2.4'
  s.summary          = 'Flutter desktop plugin to ensure only a single instance of an application runs.'
  s.description      = <<-DESC
A Flutter desktop plugin that prevents multiple instances of an application from running simultaneously.
Supports Windows, macOS, and Linux with customizable messages and cross-user detection.
                       DESC
  s.homepage         = 'https://github.com/kihyun-park/flutter_alone'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Ki Hyun Park' => 'kihyun.park@example.com' }

  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'

  # If your plugin requires a privacy manifest, for example if it collects user
  # data, update the PrivacyInfo.xcprivacy file to describe your plugin's
  # privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'flutter_alone_privacy' => ['Resources/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
