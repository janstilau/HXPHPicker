//
//  AppDelegate.swift
//  HXPHPicker
//
//  Created by Slience on 2020/12/30.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application( _ application: UIApplication,
                      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? ) -> Bool {
        
        let windows = UIWindow(frame: UIScreen.main.bounds)
        let homeController: HomeViewController
        homeController = .init(style: .grouped)
        let navigationController = UINavigationController(rootViewController: homeController)
        windows.rootViewController = navigationController
        windows.makeKeyAndVisible()
        self.window = windows
        return true
    }
}
