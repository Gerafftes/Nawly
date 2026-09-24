#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
android_gradle="$repo_root/android/app/build.gradle.kts"
ios_project_file="$repo_root/ios/Runner.xcodeproj/project.pbxproj"
ios_signing_config="$repo_root/ios/Flutter/ReleaseSigning.xcconfig"
ios_podfile="$repo_root/ios/Podfile"
windows_utils="$repo_root/windows/runner/utils.cpp"
app_environment="$repo_root/lib/config/app_environment.dart"

fail() {
  printf 'release-signing verification failed: %s\n' "$1" >&2
  exit 1
}

usage() {
  cat >&2 <<'EOF'
Usage:
  bash tool/verify_release_signing.sh --static
  bash tool/verify_release_signing.sh --config
  bash tool/verify_release_signing.sh --config \
    --android-artifact path/to/app-release.apk \
    --ios-artifact path/to/app.ipa

Artifact verification requires:
  ANDROID_EXPECTED_CERT_SHA256
  IOS_EXPECTED_SIGNING_IDENTITY
  IOS_EXPECTED_PROFILE_UUID
  IOS_EXPECTED_TEAM_ID
EOF
  exit 2
}

static_check_android() {
  [[ -f "$android_gradle" ]] || fail "missing Android Gradle configuration"
  [[ -f "$repo_root/android/key.properties.example" ]] \
    || fail "missing Android protected-signing configuration example"

  rg -q 'create\("release"\)' "$android_gradle" \
    || fail "missing dedicated Android release signing configuration"
  rg -q 'signingConfig = signingConfigs\.getByName\("release"\)' "$android_gradle" \
    || fail "Android release does not select the dedicated release signing configuration"
  if rg -q 'signingConfigs\.getByName\("debug"\)' "$android_gradle"; then
    fail "Android release configuration still references the debug signing configuration"
  fi
  rg -q 'ANDROID_KEYSTORE_PATH|key\.properties' "$android_gradle" \
    || fail "Android release signing is not backed by protected configuration"
  rg -q 'defaultDebugKeystore|debug\.keystore' "$android_gradle" \
    || fail "Android release signing does not reject the default debug keystore"
}

ios_target_block() {
  local configuration="$1"
  awk -v configuration="$configuration" '
    /isa = XCBuildConfiguration;/ {
      block = $0 ORS
      collecting = 1
      next
    }
    collecting {
      block = block $0 ORS
      if ($0 ~ ("name = " configuration ";")) {
        if (block ~ /PRODUCT_BUNDLE_IDENTIFIER = com\.nawly\.nawly;/) {
          printf "%s", block
          found = 1
        }
        collecting = 0
      }
    }
    END {
      if (!found) exit 1
    }
  ' "$ios_project_file"
}

static_check_ios() {
  [[ -f "$ios_project_file" ]] || fail "missing iOS Xcode project"
  [[ -f "$repo_root/ios/Flutter/ReleaseSigning.xcconfig.example" ]] \
    || fail "missing iOS protected-signing configuration example"

  for wrapper in Profile Release; do
    local wrapper_path="$repo_root/ios/Flutter/${wrapper}.xcconfig"
    [[ -f "$wrapper_path" ]] \
      || fail "missing iOS Flutter ${wrapper}.xcconfig"
    rg -q '#include "ReleaseSigning\.xcconfig"' "$wrapper_path" \
      || fail "iOS Flutter ${wrapper}.xcconfig does not include protected release signing settings"
  done
  [[ -f "$ios_podfile" ]] || fail "missing iOS Podfile"
  rg -q 'ReleaseSigning\.xcconfig' "$ios_podfile" \
    || fail "iOS Podfile does not preserve protected release signing settings after pod install"
  local release_wrapper_count
  release_wrapper_count="$(rg -F -c 'baseConfigurationReference = 7AFA3C8E1D35360C0083082E /* Release.xcconfig */;' "$ios_project_file" || true)"
  [[ "$release_wrapper_count" -ge 2 ]] \
    || fail "iOS Runner Profile/Release do not use the protected Flutter wrapper configuration"

  for configuration in Profile Release; do
    local block
    if ! block="$(ios_target_block "$configuration")"; then
      fail "could not locate the iOS Runner $configuration configuration"
    fi
    if printf '%s' "$block" | rg -qi 'iPhone Developer|Apple Development|iOS Development'; then
      fail "iOS Runner $configuration still resolves to a development signing identity"
    fi
    for setting in \
      'IOS_DISTRIBUTION_SIGNING_IDENTITY' \
      'IOS_DISTRIBUTION_TEAM_ID' \
      'IOS_DISTRIBUTION_PROVISIONING_PROFILE'; do
      printf '%s' "$block" | rg -q "$setting" \
        || fail "iOS Runner $configuration is missing $setting"
    done
    printf '%s' "$block" | rg -q 'CODE_SIGN_STYLE(\[sdk=iphoneos\*\])?"? = Manual;' \
      || fail "iOS Runner $configuration is not configured for manual distribution signing"
  done
}

static_check_tracked_signing_material() {
  command -v git >/dev/null 2>&1 \
    || fail "git is required to check tracked signing material"
  while IFS= read -r tracked_file; do
    case "$tracked_file" in
      android/key.properties|ios/Flutter/ReleaseSigning.xcconfig|*.jks|*.keystore|*.p12|*.mobileprovision)
        fail "signing material is tracked in source control: $tracked_file"
        ;;
    esac
  done < <(git -C "$repo_root" ls-files)
}

static_check_windows() {
  [[ -f "$windows_utils" ]] || fail "missing Windows command-line conversion implementation"
  rg -q 'BoundedWideStringLength' "$windows_utils" \
    || fail "Windows command-line conversion does not bound the input length"
  rg -q 'input_length > kMaxCommandLineArgumentLength \|\| input_length > INT_MAX' "$windows_utils" \
    || fail "Windows command-line conversion does not validate the input length"
  if rg -q 'wcslen\(' "$windows_utils"; then
    fail "Windows command-line conversion still uses unbounded wcslen"
  fi

  awk '
    /const int target_length_with_null = ::WideCharToMultiByte/ { query = NR }
    /target_length_with_null <= 0/ { guard = NR }
    /const int target_length = target_length_with_null - 1/ { subtract = NR }
    END { exit !(query > 0 && guard > query && subtract > guard) }
  ' "$windows_utils" \
    || fail "Windows conversion subtracts the terminator before checking the signed result"
  awk '
    /static_cast<size_t>\(target_length\) > kMaxCommandLineArgumentLength/ { guard = NR }
    /utf8_string\.resize\(static_cast<size_t>\(target_length\)\)/ { resize = NR }
    END { exit !(guard > 0 && resize > guard) }
  ' "$windows_utils" \
    || fail "Windows conversion resizes before enforcing the output limit"
  rg -q 'converted_length != target_length' "$windows_utils" \
    || fail "Windows conversion does not reject a partial or failed conversion"
}

static_check_supabase() {
  [[ -f "$app_environment" ]] || fail "missing Supabase endpoint validation boundary"
  rg -q "import 'package:flutter/foundation.dart' show kDebugMode;" "$app_environment" \
    || fail "Supabase endpoint validation is not tied to the build mode"
  rg -q "scheme == 'https'" "$app_environment" \
    || fail "Supabase endpoint validation does not require HTTPS"
  rg -q 'allowLocalHttp: kDebugMode' "$app_environment" \
    || fail "Supabase cleartext HTTP is not development-only"
  rg -q "scheme == 'http' && _isNumericLoopbackHost" "$app_environment" \
    || fail "Supabase cleartext HTTP is not restricted to numeric loopback"
  rg -q 'AppEnvironment\.fromEnvironment\(\)' "$repo_root/lib/main.dart" \
    || fail "Supabase initialization bypasses the validated app environment"
}

static_check() {
  static_check_tracked_signing_material
  static_check_android
  static_check_ios
  static_check_windows
  static_check_supabase
  printf 'Static release-security checks passed.\n'
}

setting_from_xcodebuild() {
  local settings="$1"
  local name="$2"
  printf '%s\n' "$settings" | awk -F ' = ' -v name="$name" \
    '$1 ~ "^[[:space:]]*" name "[[:space:]]*$" { print $2; exit }'
}

config_check_ios() {
  command -v xcodebuild >/dev/null 2>&1 \
    || fail "xcodebuild is required for iOS configuration verification"
  [[ -f "$ios_signing_config" ]] \
    || fail "missing protected ios/Flutter/ReleaseSigning.xcconfig"

  for configuration in Profile Release; do
    local settings identity style team profile
    local unresolved_marker='$('
    if ! settings="$(xcodebuild \
      -project "$repo_root/ios/Runner.xcodeproj" \
      -target Runner \
      -configuration "$configuration" \
      -sdk iphoneos \
      -showBuildSettings 2>&1)"; then
      printf '%s\n' "$settings" >&2
      fail "xcodebuild could not resolve iOS Runner $configuration settings"
    fi

    identity="$(setting_from_xcodebuild "$settings" CODE_SIGN_IDENTITY)"
    style="$(setting_from_xcodebuild "$settings" CODE_SIGN_STYLE)"
    team="$(setting_from_xcodebuild "$settings" DEVELOPMENT_TEAM)"
    profile="$(setting_from_xcodebuild "$settings" PROVISIONING_PROFILE_SPECIFIER)"

    [[ "$identity" == *"Apple Distribution"* ]] \
      || fail "iOS Runner $configuration does not resolve to Apple Distribution"
    [[ "$identity" != *"$unresolved_marker"* ]] \
      || fail "iOS Runner $configuration has an unresolved signing identity"
    [[ "$identity" != *"Apple Development"* && "$identity" != *"iPhone Developer"* ]] \
      || fail "iOS Runner $configuration resolves to a development identity"
    [[ "$identity" != *"YOUR_"* && "$team" != *"YOUR_"* && "$profile" != *"YOUR_"* ]] \
      || fail "iOS Runner $configuration still uses placeholder signing settings"
    [[ "$style" == "Manual" ]] \
      || fail "iOS Runner $configuration is not manually signed"
    [[ -n "$team" && "$team" != *"$unresolved_marker"* ]] \
      || fail "iOS Runner $configuration has no resolved distribution team"
    [[ -n "$profile" && "$profile" != *"$unresolved_marker"* ]] \
      || fail "iOS Runner $configuration has no resolved provisioning profile"
  done
  printf 'Resolved iOS Profile/Release settings use protected distribution signing.\n'
}

normalize_fingerprint() {
  tr -d '[:space:]:' | tr '[:lower:]' '[:upper:]'
}

find_apksigner() {
  if command -v apksigner >/dev/null 2>&1; then
    command -v apksigner
    return
  fi

  local sdk_root="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
  if [[ -n "$sdk_root" && -d "$sdk_root/build-tools" ]]; then
    local sdk_apksigner
    sdk_apksigner="$(find "$sdk_root/build-tools" -type f -name apksigner -print \
      | sort \
      | tail -n 1)"
    if [[ -n "$sdk_apksigner" ]]; then
      printf '%s\n' "$sdk_apksigner"
      return
    fi
  fi
  fail "apksigner is required to verify APK certificates"
}

verify_android_artifact() {
  local artifact="$1"
  local expected="${ANDROID_EXPECTED_CERT_SHA256:-}"
  [[ -f "$artifact" ]] || fail "Android artifact does not exist: $artifact"
  [[ -n "$expected" ]] || fail "ANDROID_EXPECTED_CERT_SHA256 is required for Android artifact verification"

  local certificate_output fingerprint
  case "$artifact" in
    *.apk)
      certificate_output="$("$(find_apksigner)" verify --print-certs "$artifact" 2>&1)" \
        || fail "apksigner rejected Android artifact: $artifact"
      fingerprint="$(printf '%s\n' "$certificate_output" \
        | awk -F': ' '/SHA-256 digest/ { print $2; exit }')"
      ;;
    *.aab)
      command -v keytool >/dev/null 2>&1 \
        || fail "keytool is required to verify AAB certificates"
      certificate_output="$(keytool -printcert -jarfile "$artifact" 2>&1)" \
        || fail "keytool rejected Android bundle: $artifact"
      fingerprint="$(printf '%s\n' "$certificate_output" \
        | awk -F': ' '/SHA256:/ { print $2; exit }')"
      ;;
    *)
      fail "unsupported Android artifact type: $artifact"
      ;;
  esac

  [[ -n "$fingerprint" ]] || fail "could not extract Android certificate from $artifact"
  [[ "$(printf '%s' "$fingerprint" | normalize_fingerprint)" == \
     "$(printf '%s' "$expected" | normalize_fingerprint)" ]] \
    || fail "Android artifact certificate does not match ANDROID_EXPECTED_CERT_SHA256: $artifact"
  printf 'Verified Android artifact certificate: %s\n' "$artifact"
}

decimal_exceeds_limit() {
  local value="$1"
  local limit="$2"
  [[ "$value" =~ ^[0-9]+$ ]] || return 0
  awk -v value="$value" -v limit="$limit" \
    'BEGIN { exit !(value > limit) }'
}

validate_ipa_archive() {
  local artifact="$1"
  local max_archive_bytes=536870912
  local max_expanded_bytes=2147483648
  local max_entry_count=100000
  local max_path_length=1024
  local max_path_depth=64
  local archive_size archive_totals archive_total_values
  local entry_count expanded_bytes compressed_bytes listed_entry_count

  [[ -f "$artifact" && ! -L "$artifact" ]] \
    || fail "iOS artifact must be a regular, non-symlink file: $artifact"
  if ! archive_size="$(wc -c < "$artifact" | tr -d '[:space:]')"; then
    fail "could not read iOS artifact size: $artifact"
  fi
  if decimal_exceeds_limit "$archive_size" "$max_archive_bytes"; then
    fail "iOS artifact exceeds the 512 MiB compressed-size limit: $artifact"
  fi

  if ! archive_totals="$(LC_ALL=C unzip -Z -t -- "$artifact" 2>&1)"; then
    printf '%s\n' "$archive_totals" >&2
    fail "could not inspect iOS artifact archive: $artifact"
  fi
  archive_total_values="$(printf '%s\n' "$archive_totals" | awk '
    $2 == "file," || $2 == "files," {
      print $1, $3, $6
      exit
    }
  ')"
  if ! read -r entry_count expanded_bytes compressed_bytes <<<"$archive_total_values"; then
    fail "could not read iOS artifact archive totals: $artifact"
  fi
  [[ "$entry_count" =~ ^[0-9]+$ &&
     "$expanded_bytes" =~ ^[0-9]+$ &&
     "$compressed_bytes" =~ ^[0-9]+$ ]] \
    || fail "iOS artifact archive totals are invalid: $artifact"
  if decimal_exceeds_limit "$entry_count" "$max_entry_count"; then
    fail "iOS artifact contains more than 100000 archive entries: $artifact"
  fi
  if decimal_exceeds_limit "$expanded_bytes" "$max_expanded_bytes"; then
    fail "iOS artifact exceeds the 2 GiB expanded-size limit: $artifact"
  fi
  if decimal_exceeds_limit "$compressed_bytes" "$max_archive_bytes"; then
    fail "iOS artifact exceeds the 512 MiB compressed-content limit: $artifact"
  fi

  if ! listed_entry_count="$(
    LC_ALL=C unzip -Z1 -- "$artifact" 2>/dev/null |
      LC_ALL=C awk \
        -v max_entries="$max_entry_count" \
        -v max_length="$max_path_length" \
        -v max_depth="$max_path_depth" '
        {
          entry = $0
          count++
          if (count > max_entries) {
            invalid = 1
            exit
          }
          if (length(entry) > max_length) {
            invalid = 1
            exit
          }
          depth = gsub(/\//, "/", entry)
          if (depth > max_depth) {
            invalid = 1
            exit
          }
          if (entry ~ /^\// ||
              entry ~ /^[[:alpha:]][[:alnum:]]*:/ ||
              entry ~ /(^|\/)\.\.(\/|$)/ ||
              entry ~ /\\/) {
            invalid = 1
            exit
          }
          if (seen[$0]++) {
            invalid = 1
            exit
          }
        }
        END {
          if (invalid || count == 0) {
            exit 1
          }
          print count
        }'
  )"; then
    fail "iOS artifact contains invalid, duplicated, or unsafe archive paths: $artifact"
  fi
  [[ "$listed_entry_count" == "$entry_count" ]] \
    || fail "iOS artifact archive entry count is inconsistent: $artifact"

  if ! LC_ALL=C unzip -Z -v -- "$artifact" 2>/dev/null |
    LC_ALL=C awk '
      /file security status:/ {
        security_statuses++
        if ($0 !~ /not encrypted/) {
          invalid = 1
        }
      }
      /Unix file attributes .*:[[:space:]]+[lbcps]/ {
        invalid = 1
      }
      END {
        if (security_statuses == 0 || invalid) {
          exit 1
        }
      }'
  then
    fail "iOS artifact is encrypted or contains special-file archive entries: $artifact"
  fi
}

extract_ipa_archive() {
  local artifact="$1"
  local temp_dir="$2"
  local timeout_seconds="$3"
  local unzip_pid watchdog_pid unzip_status

  unzip -q -o -- "$artifact" -d "$temp_dir" &
  unzip_pid=$!
  (
    sleep "$timeout_seconds"
    if kill -0 "$unzip_pid" >/dev/null 2>&1; then
      kill -TERM "$unzip_pid" >/dev/null 2>&1 || true
      sleep 1
      kill -KILL "$unzip_pid" >/dev/null 2>&1 || true
    fi
  ) &
  watchdog_pid=$!

  if wait "$unzip_pid"; then
    unzip_status=0
  else
    unzip_status=$?
  fi
  kill "$watchdog_pid" >/dev/null 2>&1 || true
  wait "$watchdog_pid" >/dev/null 2>&1 || true
  return "$unzip_status"
}

verify_ios_artifact() {
  local artifact="$1"
  local expected_identity="${IOS_EXPECTED_SIGNING_IDENTITY:-}"
  local expected_profile_uuid="${IOS_EXPECTED_PROFILE_UUID:-}"
  local expected_team_id="${IOS_EXPECTED_TEAM_ID:-}"
  [[ -f "$artifact" ]] || fail "iOS artifact does not exist: $artifact"
  [[ -n "$expected_identity" ]] || fail "IOS_EXPECTED_SIGNING_IDENTITY is required for iOS artifact verification"
  [[ -n "$expected_profile_uuid" ]] || fail "IOS_EXPECTED_PROFILE_UUID is required for iOS artifact verification"
  [[ -n "$expected_team_id" ]] || fail "IOS_EXPECTED_TEAM_ID is required for iOS artifact verification"
  command -v codesign >/dev/null 2>&1 || fail "codesign is required for iOS artifact verification"
  command -v security >/dev/null 2>&1 || fail "security is required for iOS artifact verification"
  [[ -x /usr/libexec/PlistBuddy ]] || fail "PlistBuddy is required for iOS artifact verification"

  local temp_dir app_path profile profile_plist details identity team profile_uuid
  local profile_team profile_app_identifier bundle_identifier
  validate_ipa_archive "$artifact"
  if ! temp_dir="$(mktemp -d -t nawly-ipa-XXXXXX)"; then
    fail "could not create temporary directory for iOS artifact: $artifact"
  fi
  trap 'rm -rf "$temp_dir"' EXIT
  extract_ipa_archive "$artifact" "$temp_dir" 120 \
    || fail "could not unpack iOS artifact within the resource and time limits: $artifact"
  app_path="$(find "$temp_dir/Payload" -maxdepth 1 -type d -name '*.app' -print -quit)"
  [[ -n "$app_path" ]] || fail "iOS artifact contains no app bundle: $artifact"
  profile="$app_path/embedded.mobileprovision"
  [[ -f "$profile" ]] || fail "iOS app bundle has no embedded provisioning profile: $artifact"
  bundle_identifier="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_path/Info.plist" 2>/dev/null || true)"
  [[ "$bundle_identifier" == "com.nawly.nawly" ]] \
    || fail "iOS artifact bundle identifier is not com.nawly.nawly"

  details="$(codesign -dvv "$app_path" 2>&1)" \
    || fail "codesign could not inspect iOS app bundle: $artifact"
  codesign --verify --deep --strict "$app_path" >/dev/null 2>&1 \
    || fail "iOS app bundle has an invalid or incomplete code signature: $artifact"
  identity="$(printf '%s\n' "$details" \
    | awk -F= '$1 == "Authority" && $2 ~ /^Apple Distribution/ { print $2; exit }')"
  team="$(printf '%s\n' "$details" | sed -n 's/^TeamIdentifier=//p' | head -n 1)"
  [[ "$identity" == "$expected_identity" ]] \
    || fail "iOS artifact identity does not match IOS_EXPECTED_SIGNING_IDENTITY"
  [[ "$identity" == *"Apple Distribution"* ]] \
    || fail "iOS artifact is not signed with an Apple Distribution identity"
  [[ "$team" == "$expected_team_id" ]] \
    || fail "iOS artifact team does not match IOS_EXPECTED_TEAM_ID"

  profile_plist="$temp_dir/embedded-profile.plist"
  security cms -D -i "$profile" -o "$profile_plist" \
    || fail "could not decode iOS provisioning profile: $artifact"
  profile_uuid="$(/usr/libexec/PlistBuddy -c 'Print :UUID' "$profile_plist" 2>/dev/null || true)"
  profile_team="$(/usr/libexec/PlistBuddy -c 'Print :TeamIdentifier:0' "$profile_plist" 2>/dev/null || true)"
  profile_app_identifier="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:application-identifier' "$profile_plist" 2>/dev/null || true)"
  profile_get_task_allow="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:get-task-allow' "$profile_plist" 2>/dev/null || true)"
  [[ "$profile_uuid" == "$expected_profile_uuid" ]] \
    || fail "iOS provisioning profile UUID does not match IOS_EXPECTED_PROFILE_UUID"
  [[ "$profile_team" == "$expected_team_id" ]] \
    || fail "iOS provisioning profile team does not match IOS_EXPECTED_TEAM_ID"
  [[ "$profile_app_identifier" == "$expected_team_id.com.nawly.nawly" ]] \
    || fail "iOS provisioning profile is not scoped to com.nawly.nawly"
  [[ "$profile_get_task_allow" == "false" ]] \
    || fail "iOS provisioning profile permits development debugging"
  if /usr/libexec/PlistBuddy -c 'Print :ProvisionedDevices' "$profile_plist" >/dev/null 2>&1; then
    fail "iOS provisioning profile is not an App Store profile"
  fi
  printf 'Verified iOS certificate and provisioning profile: %s\n' "$artifact"
}

run_static=false
run_config=false
android_artifacts=()
android_artifact_count=0
ios_artifact=""

while (($# > 0)); do
  case "$1" in
    --static)
      run_static=true
      ;;
    --config)
      run_config=true
      ;;
    --android-artifact)
      (($# >= 2)) || usage
      android_artifacts+=("$2")
      android_artifact_count=$((android_artifact_count + 1))
      shift
      ;;
    --ios-artifact)
      (($# >= 2)) || usage
      ios_artifact="$2"
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      usage
      ;;
  esac
  shift
done

[[ "$run_static" == true || "$run_config" == true || "$android_artifact_count" -gt 0 || -n "$ios_artifact" ]] \
  || usage

if [[ "$run_static" == true ]]; then
  static_check
fi
if [[ "$run_config" == true ]]; then
  config_check_ios
fi
if [[ "$android_artifact_count" -gt 0 ]]; then
  for artifact in "${android_artifacts[@]}"; do
    verify_android_artifact "$artifact"
  done
fi
if [[ -n "$ios_artifact" ]]; then
  verify_ios_artifact "$ios_artifact"
fi
