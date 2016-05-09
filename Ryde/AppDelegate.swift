//
//  AppDelegate.swift
//  Ryde
//
//  Created by Cameron Gibson on 3/29/16.
//  Copyright © 2016 Jared Deiner. All rights reserved.
//

import UIKit

import CoreLocation

import FBSDKCoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // Global Variables So they can be access throughout the entire application//
    
    // From FB, used for authentication
    var FBid = ""
    
    // Probile counters
    var rydesTakenCount = 0
    var rydesGivenCount = 0
    
    // Dictionary containing information about the current logged in suer
    var currentUser: NSDictionary?
    
    // Used for API calls.
    var baseURL = "jupiter.cs.vt.edu"
    
    var window: UIWindow?
    var locationManager: CLLocationManager?


    /**
     CoreLocation authentization of usage as well as Facebook SDK implementation
    **/
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        
        locationManager = CLLocationManager()
        locationManager?.requestWhenInUseAuthorization()

        
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

