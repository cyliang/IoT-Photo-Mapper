//
//  TabBarController.swift
//  IoT Photo Mapper
//
//  Created by Chih-Yung Liang on 2015/12/30.
//  Copyright © 2015年 Chih-Yung Liang. All rights reserved.
//

import UIKit
import CoreLocation

class TabBarController: UITabBarController {

    weak var mapView: MapViewController!
    weak var photoView: PhotoViewController!
    weak var moreView: TableViewController!
    let coreData = CoreData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView = self.viewControllers![0] as! MapViewController
        self.photoView = self.viewControllers![1] as! PhotoViewController
        self.moreView = self.viewControllers![2] as! TableViewController
        
        self.coreData.mapViewController = self.mapView
        self.coreData.photoViewController = self.photoView
        self.mapView.coreData = self.coreData
        self.photoView.coreData = self.coreData
        self.mapView.updateGlobalData()
        self.mapView.updatePersonalData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "uploadSegue") {
            (segue.destinationViewController as! UploadViewController).coreData = self.coreData
        }
    }
    
}

