//
//  SceneDelegate.swift
//  CleanApp
//
//  Minimal app without TruoraSDK dependencies.
//  Used to measure SDK size impact by comparing archive sizes.
//

import SwiftUI
import UIKit

@objc(SceneDelegate)
public class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    public var window: UIWindow?

    public func scene(
        _ scene: UIScene,
        willConnectTo _: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        let rootView = Text("Clean App — No SDK")
            .font(.title)
        let hostingController = UIHostingController(rootView: rootView)

        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        self.window = window
    }

    public func sceneDidDisconnect(_: UIScene) {}

    public func sceneDidBecomeActive(_: UIScene) {}

    public func sceneWillResignActive(_: UIScene) {}

    public func sceneWillEnterForeground(_: UIScene) {}

    public func sceneDidEnterBackground(_: UIScene) {}
}
