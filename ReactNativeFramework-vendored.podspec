Pod::Spec.new do |s|
  s.name             = 'ReactNativeFramework-vendored'
  s.version          = '0.1.0'
  s.summary          = 'React Native 原生集成框架（Vendored 版本）'
  s.description      = <<-DESC
ReactNativeFramework-vendored 是 ReactNativeFramework 的预编译分发版本。
内置 React Native 0.85 全部二进制，宿主 App 的 Podfile 无需 use_react_native!。
宿主代码只需 import ReactNativeFramework，调用 RNEmbedder.shared.show(in:) 即可嵌入 RN 页面。
                       DESC
  s.homepage         = 'https://github.com/air62897@gmail.com/ReactNativeFramework'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'air62897@gmail.com' => 'air62897@gmail.com' }
  s.source           = { :git => 'https://github.com/air62897@gmail.com/ReactNativeFramework.git', :tag => s.version.to_s }

  s.ios.deployment_target = '16.0'
  s.module_name = 'ReactNativeFramework'

  s.source_files = 'ReactNativeFramework/Classes/**/*.{swift,mm,h}'
  s.frameworks = 'UIKit'

  s.vendored_frameworks = [
    'Vendor/React.xcframework',
    'Vendor/ReactNativeDependencies.xcframework',
    'Vendor/hermesvm.xcframework'
  ]

  s.pod_target_xcconfig = {
    'FRAMEWORK_SEARCH_PATHS' => '$(inherited) ${PODS_TARGET_SRCROOT}/Vendor',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++20',
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) RCT_NEW_ARCH_ENABLED=1',
    'DEFINES_MODULE' => 'YES',
    'CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER' => 'NO',
    'OTHER_SWIFT_FLAGS' => '$(inherited) -Xcc -Wno-quoted-include-in-framework-header',
  }

  s.user_target_xcconfig = {
    'FRAMEWORK_SEARCH_PATHS' => '$(inherited) ${PODS_TARGET_SRCROOT}/Vendor',
  }
end
