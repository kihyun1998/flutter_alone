#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flutter_alone'
  s.version          = '3.1.3' # pubspec.yaml의 버전과 일치
  s.summary          = 'A Flutter plugin for preventing duplicate execution of desktop applications.'
  s.description      = <<-DESC
A Flutter plugin for preventing duplicate execution of desktop applications with customizable message support and cross-user detection.
                       DESC
  s.homepage         = 'https://github.com/kihyun1998/flutter_alone'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Name' => 'your@email.com' } # 실제 정보로 변경
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*.{h,m,swift}'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11' # macOS 지원 버전
  s.swift_version = '5.0' # Swift 버전
end
