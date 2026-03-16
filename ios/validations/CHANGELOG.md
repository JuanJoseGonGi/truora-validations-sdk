# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.0.0 - 2026-03-05

* Stable release of the Truora Validations SDK for production use

### Added
* Face validations including autocapture, live feedback for face detection and liveness using Truora backend services
* Document validations including autocapture, live feedback for document detection on both sides and fraud verification using Truora backend services
* Localization for english, spanish and portuguese
* Color customization following Material3 themes with colors
  * primary
  * onPrimary
  * secondary
  * onSecondary
  * surface
  * onSurface
  * surfaceVariant 
  * onSurfaceVariant
  * error

## 1.0.0-rc.2 - 2026-03-03

* Strip logs from Release builds through a shared `debugLog`function
* Test stable release before publishing

## 1.0.0-rc.1 - 2026-02-28

* Added `surfaceVariantColor` and `onSurfaceVariantColor` parameters to `UIConfig`

## 1.0.0-beta.4 - 2026-02-17

* Added `onSecondaryColor` parameter to `UIConfig`
* Added support for passport document in capture views

## 1.0.0-beta.1 - 2026-02-08

* First stable release of Truora Validations SDK
* Added support for document with face validation flows

## 0.1.0-alpha.2 - 2026-02-08

* Stable release with fixes from internal massive tests

## 0.1.0-alpha.1 - 2026-02-08

* Stable release with fixes from internal UI tests
* Release in both publishing platforms SPM and CP

# 0.0.9 [SPM] - 2026-01-30

* Stable release of doc and face SDKs with SwiftUI

# 0.0.8 [SPM] - 2026-01-30

* Test release of doc and face SDKs with SwiftUI
* Added document capture, feedback and results polling

## 0.0.4-alpha.3 [CP] - 2026-01-30

* Stable release of doc and face SDKs with SwiftUI

## 0.0.4-alpha.1 [CP] - 2026-01-27

* Test release of doc and face SDKs with SwiftUI

## 0.0.3-alpha.8 [CP] - 2026-01-23

* Test release of doc and face SDKs with KMP installation
* Added document capture, feedback and results polling

## 0.0.1 [SPM] - 2026-01-20

* Test release of face SDK in SPM
* Added basic features for capture of face biometry and comparing against a prev backend account enrollment

## 0.0.2alpha [CP] - 2026-01-06

* Test release of face SDK in CocoaPods
* Added basic features for capture of face biometry and comparing against a prev backend account enrollment