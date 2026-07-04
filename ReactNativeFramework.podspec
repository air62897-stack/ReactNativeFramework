Pod::Spec.new do |s|
  s.name             = 'ReactNativeFramework'
  s.version          = '0.1.0'
  s.summary          = 'React Native 集成框架 - 轻量 API'
  s.homepage         = 'https://github.com/air62897@gmail.com/ReactNativeFramework'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'air62897@gmail.com' => 'air62897@gmail.com' }
  s.source           = { :git => 'https://github.com/air62897@gmail.com/ReactNativeFramework.git', :tag => s.version.to_s }
  s.ios.deployment_target = '16.0'
  s.source_files = 'ReactNativeFramework/Classes/**/*.{swift}'
  s.frameworks = 'UIKit'
end
