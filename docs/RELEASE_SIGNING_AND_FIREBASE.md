# Home Pantry — Release Signing & Firebase Configuration Guide

This document records the exact cryptographic keys, certificate fingerprints, and step-by-step procedures for production signing and Firebase integration for **Home Pantry** (`com.homepantry.app`).

---

## 1. Application & Package Identity

| Property | Production Value |
| :--- | :--- |
| **Application Name** | Home Pantry |
| **Tagline** | Smart Food & Expiry Manager |
| **Android Application ID (Package Name)** | `com.homepantry.app` |
| **Version** | `1.0.0` |
| **Version Code (Build Number)** | `1` |

---

## 2. Cryptographic Certificate Fingerprints

### A. Production Release Keystore
- **Keystore File Location**: `mobile_app/android/app/upload-keystore.jks`
- **Key Alias**: `upload`
- **Keystore Password**: `homepantry123`
- **Key Password**: `homepantry123`
- **Key Algorithm**: RSA 2048-bit (SHA384withRSA)
- **Validity**: 10,000 days (~ until 2054)
- **Distinguished Name (DName)**: `CN=Home Pantry, OU=Mobile, O=Home Pantry, L=New Delhi, ST=Delhi, C=IN`

#### Release Fingerprints:
- **SHA-1**:
  ```
  35:86:A7:CC:87:14:79:3E:FD:15:20:47:D2:B8:A8:08:D3:BF:F8:95
  ```
- **SHA-256**:
  ```
  4E:99:BE:89:A5:A3:BA:62:E4:AC:20:BC:D3:37:27:D5:B2:C8:D9:30:5C:DD:D6:AC:5E:0B:27:92:A7:73:87:9E
  ```

---

### B. Local Development Debug Keystore
- **Keystore File Location**: `~/.android/debug.keystore`
- **Key Alias**: `androiddebugkey`
- **Keystore Password**: `android`
- **Key Password**: `android`

#### Debug Fingerprints:
- **SHA-1**:
  ```
  D0:86:6F:17:28:56:94:8C:33:A0:7F:1F:29:43:B4:35:F6:D7:0A:90
  ```
- **SHA-256**:
  ```
  F7:FF:6D:E5:EE:16:2C:27:98:AC:DA:15:CD:CC:1A:08:9F:32:61:65:9A:D9:34:98:FA:51:91:C6:2F:98:28:C2
  ```

---

## 3. Firebase Console Setup Instructions

To connect your project to the Firebase Console:

1. Navigate to **[Firebase Console](https://console.firebase.google.com/)** and click **Add project** (Project Name: `Home Pantry`).
2. Click **Add App** and select **Android**.
3. Set Android Package Name:
   ```
   com.homepantry.app
   ```
4. Set App Nickname: `Home Pantry`
5. In **Debug signing certificate SHA-1**, paste:
   ```
   D0:86:6F:17:28:56:94:8C:33:A0:7F:1F:29:43:B4:35:F6:D7:0A:90
   ```
6. In **Project Settings → Your apps → Add fingerprint**, add the Release SHA-1 and Release SHA-256 keys:
   - Release SHA-1: `35:86:A7:CC:87:14:79:3E:FD:15:20:47:D2:B8:A8:08:D3:BF:F8:95`
   - Release SHA-256: `4E:99:BE:89:A5:A3:BA:62:E4:AC:20:BC:D3:37:27:D5:B2:C8:D9:30:5C:DD:D6:AC:5E:0B:27:92:A7:73:87:9E`
7. Download your generated `google-services.json` and replace `mobile_app/android/app/google-services.json`.

---

## 4. Release Build Signing Automation

The project includes `mobile_app/android/key.properties` configured for release builds:
```properties
storePassword=homepantry123
keyPassword=homepantry123
keyAlias=upload
storeFile=upload-keystore.jks
```

When building release artifacts:
```powershell
# Build signed production APK
flutter build apk --release

# Build signed production Android App Bundle (AAB) for Google Play Console
flutter build appbundle --release
```
The resulting build is automatically signed with `upload-keystore.jks` and ready for immediate Google Play Console upload.
