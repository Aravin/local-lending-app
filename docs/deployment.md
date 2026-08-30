# Deployment Guide

## Building for Android

Each white-label client maps to an Android product flavor.

### Debug APK
```bash
make build-apk FLAVOR=localLendingHub
```

### Release APK
```bash
make build-apk-release FLAVOR=localLendingHub
```
The APK output is generated at:
`build/app/outputs/flutter-apk/app-localLendingHub-release.apk`

### Production App Bundle (AAB for Google Play)
```bash
make build-aab FLAVOR=localLendingHub
```
The AAB output is generated at:
`build/app/outputs/bundle/localLendingHubRelease/app-localLendingHub-release.aab`

## Signing Configuration

1. Generate a keystore:
   ```bash
   keytool -genkey -v -keystore local_lending.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
   ```
2. Create `android/key.properties`:
   ```properties
   storePassword=your_store_password
   keyPassword=your_key_password
   keyAlias=key
   storeFile=../local_lending.jks
   ```
3. `android/key.properties` is already excluded in `.gitignore`.
