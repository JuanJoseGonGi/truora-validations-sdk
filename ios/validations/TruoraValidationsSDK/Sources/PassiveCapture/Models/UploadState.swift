//
//  UploadState.swift
//  TruoraValidationsSDK
//
//  Created by Truora on 23/01/26.
//

import Foundation

enum UploadState: Hashable {
    case none
    case uploading
    /// Upload completed and we navigated to Result (Passive/Document success path).
    case success
    /// We navigated to Result on failure (e.g. validation error). Used so we don't restart camera on appDidBecomeActive; semantically distinct from .success.
    case navigatedToResult
}
