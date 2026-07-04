#!/bin/bash
set -e

# ============================================================
# build_vendor.sh
# 将 React Native 0.85 prebuilt xcframeworks 打包到 Vendor/ 目录
#
# 并通过符号链接使 React umbrella header 的旧路径导入可用。
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PODS_DIR="$SCRIPT_DIR/Example/Pods"
VENDOR_DIR="$SCRIPT_DIR/Vendor"

echo "📦 Building vendored frameworks for ReactNativeFramework..."

if [ ! -d "$PODS_DIR/React-Core-prebuilt" ]; then
    echo "❌ Error: Example/Pods not found. Run 'cd Example && pod install' first."
    exit 1
fi

rm -rf "$VENDOR_DIR"
mkdir -p "$VENDOR_DIR"

# 1. 复制 xcframeworks
echo "  → Copying React.xcframework..."
cp -R "$PODS_DIR/React-Core-prebuilt/React.xcframework" "$VENDOR_DIR/React.xcframework"

echo "  → Copying ReactNativeDependencies.xcframework..."
cp -R "$PODS_DIR/ReactNativeDependencies/framework/packages/react-native/ReactNativeDependencies.xcframework" \
      "$VENDOR_DIR/ReactNativeDependencies.xcframework"

echo "  → Copying hermesvm.xcframework..."
cp -R "$PODS_DIR/hermes-engine/destroot/Library/Frameworks/universal/hermesvm.xcframework" \
      "$VENDOR_DIR/hermesvm.xcframework"

# 2. 创建头文件符号链接，兼容旧版导入路径
#    问题背景：
#      React umbrella header 使用 <React/XXX.h> 格式导入，但 xcframework 新布局
#      将文件放在子目录中（如 React_Core/React/RCTBridge.h）。
#      某些头文件内部使用子目录导入（如 <yoga/Yoga.h>、<cxxreact/JSExecutor.h>、
#      <react/runtime/JSRuntimeFactory.h>），这些子目录在 Headers 根目录下不存在。
#      react/ 命名空间横跨多个 React_* 目录，单个目录符号链接无法处理。
#    解决方案：
#      (a) 为每个唯一的 .h 文件名在 Headers/ 根目录创建扁平符号链接
#          （处理 <React/XXX.h> 形式导入）
#      (b) 扫描所有头文件的 #import 语句，为每个子目录导入（如 <DIR/SUBDIR/File.h>）
#          在 Headers/ 下创建精确路径的符号链接
echo "  → Creating backward-compatible header symlinks..."
create_symlinks() {
    local headers_dir="$1"
    python3 - "$headers_dir" << 'PYEOF'
import os, sys, re

headers_dir = sys.argv[1]
flat_count = 0
path_count = 0

# --- Step 1: Build file index (filename -> real path) ---
file_index = {}  # filename -> real_path
for root, dirs, files in os.walk(headers_dir):
    rel_root = os.path.relpath(root, headers_dir)
    if rel_root == '.':
        continue
    for f in files:
        if f.endswith('.h'):
            real = os.path.realpath(os.path.join(root, f))
            file_index[f] = real

# --- Step 2: Flat symlinks for <React/XXX.h> imports ---
for filename, real_path in file_index.items():
    link_path = os.path.join(headers_dir, filename)
    if not os.path.exists(link_path):
        rel = os.path.relpath(real_path, headers_dir)
        os.symlink(rel, link_path)
        flat_count += 1

print(f"  Flat symlinks: {flat_count}", file=sys.stderr)

# --- Step 3: Per-path symlinks for subdirectory imports ---
# Scan original header files (not symlinks) for #import <DIR/.../FILE.h>
SYSTEM_FRAMEWORKS = {
    'UIKit', 'Foundation', 'CoreGraphics', 'QuartzCore', 'CoreText',
    'ImageIO', 'MobileCoreServices', 'AVFoundation', 'CoreLocation',
    'CoreMedia', 'Metal', 'MetalKit', 'Accelerate', 'os', 'sys',
    'TargetConditionals', 'CommonCrypto', 'objc', 'dispatch', 'malloc',
    'JavaScriptCore', 'Security', 'SystemConfiguration', 'CFNetwork',
    'CoreFoundation', 'Darwin', 'GLKit', 'OpenGLES', 'SceneKit',
    'SpriteKit', 'WatchKit', 'WebKit', 'XCTest', 'MapKit', 'CoreData',
    'CoreImage', 'CoreAudio', 'CoreVideo', 'VideoToolbox',
}

CXX_HEADERS = {'atomic', 'mutex', 'functional', 'optional', 'memory',
               'string', 'vector', 'type_traits', 'algorithm', 'utility',
               'cstdint', 'cstdlib', 'cstring', 'cmath', 'cstdio',
               'condition_variable', 'thread', 'chrono', 'exception',
               'initializer_list', 'limits', 'new', 'stdexcept', 'tuple',
               'unordered_map', 'unordered_set', 'map', 'set', 'list',
               'deque', 'queue', 'array', 'forward_list', 'iterator',
               'sstream', 'iosfwd', 'fstream', 'iomanip', 'numeric',
               'random', 'ratio', 'regex', 'shared_mutex', 'system_error',
               'bitset', 'complex', 'csetjmp', 'csignal', 'cstdarg',
               'ctime', 'cwchar', 'cwctype', 'strstream',
}

FOLLY_HEADERS = {'folly'}
BOOST_HEADERS = {'boost'}
HERMESVM_HEADERS = {'hermesvm'}

# Pattern: #import/#include <anything/anything.h> with optional nested paths
import_pattern = re.compile(r'(?:#import|#include)\s+<(([^/>\s]+)/[^>]+)>')

processed_files = set()
created_paths = set()

# Only scan real files (not symlinks) to avoid duplicates
for root, dirs, files in os.walk(headers_dir):
    rel_root = os.path.relpath(root, headers_dir)
    for f in files:
        if not f.endswith('.h'):
            continue
        fpath = os.path.join(root, f)
        real = os.path.realpath(fpath)
        if real in processed_files:
            continue
        processed_files.add(real)
        try:
            with open(fpath, 'r', encoding='utf-8', errors='ignore') as fh:
                content = fh.read()
        except:
            continue
        for m in import_pattern.finditer(content):
            full_path = m.group(1)    # e.g., "yoga/Yoga.h"
            first_dir = m.group(2)    # e.g., "yoga"

            if first_dir in SYSTEM_FRAMEWORKS or first_dir in CXX_HEADERS:
                continue
            if first_dir in FOLLY_HEADERS or first_dir in BOOST_HEADERS or first_dir in HERMESVM_HEADERS:
                continue
            if first_dir == 'React':
                continue

            # Check if this path already exists at Headers root
            target_path = os.path.join(headers_dir, full_path)
            if os.path.exists(target_path):
                continue

            # Extract the filename from the full path
            filename = os.path.basename(full_path)

            # Find the real file
            if filename in file_index:
                real_file = file_index[filename]
                # Create parent directories if needed
                parent_dir = os.path.dirname(target_path)
                os.makedirs(parent_dir, exist_ok=True)
                # Create symlink
                rel = os.path.relpath(real_file, parent_dir)
                if target_path not in created_paths:
                    try:
                        os.symlink(rel, target_path)
                        created_paths.add(target_path)
                        path_count += 1
                    except OSError:
                        pass

print(f"  Path symlinks: {path_count}", file=sys.stderr)
print(f"{flat_count + path_count}")
PYEOF
}

total_symlinks=0
for slice_dir in "$VENDOR_DIR/React.xcframework"/ios-*/React.framework/Headers/; do
    if [ -d "$slice_dir" ]; then
        count=$(create_symlinks "$slice_dir")
        total_symlinks=$((total_symlinks + count))
    fi
done
echo "  → Created $total_symlinks symlinks across all slices"

# 2.5 消除瑜伽双层嵌套：将真实文件从 Headers/Yoga/yoga/ 提升到 Headers/Yoga/
#    原始 xcframework 结构: Headers/Yoga/ (symlinks) → Headers/Yoga/yoga/ (real files)
#    XCFrameworkIntermediates 会将目录名小写化，导致 <yoga/...> 查找失败
#    解决：直接扁平化 Yoga 目录结构
echo "  → Flattening Yoga directory structure..."
for slice_dir in "$VENDOR_DIR/React.xcframework"/ios-*/React.framework/Headers/; do
    if [ -d "$slice_dir" ]; then
        yoga_real_dir="$slice_dir/Yoga/yoga"
        yoga_parent_dir="$slice_dir/Yoga"
        if [ -d "$yoga_real_dir" ]; then
            # Move all real files and directories from Yoga/yoga/ up to Yoga/
            for item in "$yoga_real_dir"/*; do
                item_name="$(basename "$item")"
                target="$yoga_parent_dir/$item_name"
                # Remove the existing symlink at Yoga/ if present
                rm -f "$target"
                # Move the real item up
                mv "$item" "$target"
            done
            # Remove now-empty yoga/ subdirectory
            rmdir "$yoga_real_dir" 2>/dev/null || true
            echo "    Flattened Yoga in $(basename "$(dirname "$slice_dir")")"
        fi
    fi
done

# 3. 修复 CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER 问题
#    React 头文件内部使用了 #import <yoga/Yoga.h> 等尖括号导入同框架内的头文件，
#    新版本 clang 会将此视为 error。解决方案：将同框架内的尖括号导入改为引号导入。
echo "  → Patching quoted includes in React headers..."
patch_headers() {
    local headers_dir="$1"
    python3 - "$headers_dir" << 'PYEOF'
import os, sys, re

headers_dir = sys.argv[1]

# Build a set of valid framework-internal include prefixes
# i.e., directories under Headers that might be used in #import <DIR/...>
# Use lowercase keys for case-insensitive matching (macOS filesystem is case-insensitive)
internal_dirs = set()
for entry in os.listdir(headers_dir):
    entry_path = os.path.join(headers_dir, entry)
    if os.path.isdir(entry_path):
        internal_dirs.add(entry.lower())
    # Also check if 'entry' is a symlink to a directory
    if os.path.islink(entry_path) and os.path.isdir(entry_path):
        internal_dirs.add(entry.lower())

# Don't patch React itself (React/ imports are already correct framework-scoped)
internal_dirs.discard('react')

patch_count = 0
file_count = 0

# Pattern for both #import and #include with angled brackets
angle_import = re.compile(r'(#(?:import|include)\s+)<(([^/>\s]+)/[^>]+)>')

# Process only real files (not symlinks) to avoid double-patching
processed = set()

for root, dirs, files in os.walk(headers_dir):
    rel_root = os.path.relpath(root, headers_dir)
    for fname in files:
        if not fname.endswith('.h'):
            continue
        fpath = os.path.join(root, fname)
        real = os.path.realpath(fpath)
        if real in processed:
            continue
        processed.add(real)
        
        try:
            with open(fpath, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
        except:
            continue
        
        original = content
        # Find all angled bracket imports and check if first dir is internal
        # Case-insensitive comparison (macOS APFS is case-insensitive by default)
        def replacer(m):
            prefix = m.group(1)
            dirname = m.group(3)
            if dirname.lower() in internal_dirs:
                return prefix + '"' + m.group(2) + '"'
            return m.group(0)
        
        content = angle_import.sub(replacer, content)
        
        if content != original:
            try:
                with open(fpath, 'w', encoding='utf-8') as f:
                    f.write(content)
                file_count += 1
                patch_count += (len(angle_import.findall(original)) - len(angle_import.findall(content)))
            except:
                pass

print(f"  Patched {patch_count} imports in {file_count} files", file=sys.stderr)
PYEOF
}

total_patched=0
for slice_dir in "$VENDOR_DIR/React.xcframework"/ios-*/React.framework/Headers/; do
    if [ -d "$slice_dir" ]; then
        patch_headers "$slice_dir"
    fi
done
echo "  → Quote patching complete"

# 4. 输出大小信息
echo ""
echo "✅ Vendored frameworks built successfully!"
echo ""
du -sh "$VENDOR_DIR"/React.xcframework 2>/dev/null
du -sh "$VENDOR_DIR"/ReactNativeDependencies.xcframework 2>/dev/null
du -sh "$VENDOR_DIR"/hermesvm.xcframework 2>/dev/null
echo "Total: $(du -sh "$VENDOR_DIR" | awk '{print $1}')"
