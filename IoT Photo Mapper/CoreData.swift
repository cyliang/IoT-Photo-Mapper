//
//  DataLoader.swift
//  IoT Photo Mapper
//
//  Created by Chih-Yung Liang on 2016/1/8.
//  Copyright © 2016年 Chih-Yung Liang. All rights reserved.
//

import UIKit
import CoreLocation

class CoreData {
    
    let locationManager = CLLocationManager()
    var location: CLLocation {
        get {
            return locationManager.location!
        }
    }
    
    class PhotoInfo {
        var url: String!
        var coordinate: CLLocationCoordinate2D!
        var image: UIImage?
    }
    var personalPhotos: [PhotoInfo]?
    let personalURL = NSURL(string: "http://140.113.195.27/Account/MyAlbum")!
    var personalPhotosToLoad: Int = 0
    weak var photoViewController: PhotoViewController?
    
    class GlobalInfo {
        var title: String!
        var coordinate: CLLocationCoordinate2D!
    }
    var globalPositions: [GlobalInfo]?
    let globalURL = NSURL(string: "http://140.113.195.27")!
    weak var mapViewController: MapViewController?
    
    init() {
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        
        NSHTTPCookieStorage.sharedHTTPCookieStorage().setCookie(NSHTTPCookie(properties: [
            NSHTTPCookiePath: "/",
            NSHTTPCookieName: ".AspNet.ApplicationCookie",
            NSHTTPCookieValue: "48h7HNzzKTr7z9mAtUY3lcmhG8xF5hc-ucR4c4-s-ecc-loiG9VWRK4W6onmJnfcyJ6HOlMzyOiXOl1GIfO5_IC9HxjfDFQbhUZ9zJ-jrLEZntZ3EYPpz84XcooS-6jF6JB2wdi8-_uVSYs9Ui9n7Oa5oypdTQj7eOD-m6ZTPG4WE0X2mMU4lYiItJ9tOmneeYkB_h2DNqgjTvPt-qnosIZW7KSW0HFGicnDUlmkVpY",
            NSHTTPCookieDomain: "140.113.195.27"
        ])!)
        NSHTTPCookieStorage.sharedHTTPCookieStorage().setCookie(NSHTTPCookie(properties: [
            NSHTTPCookiePath: "/",
            NSHTTPCookieName: "__RequestVerificationToken",
            NSHTTPCookieValue: "0EatsqctYV26OvgdgxzkDalyPU33GH3b9sRgJeQb8yO4rJhdNkkVv0MKHzIkkGHC6Ad2bfLI058S_DRn2XQ18sEARN44v33cME5Gnn8AWMk1",
            NSHTTPCookieDomain: "140.113.195.27"
        ])!)
        
        self.reloadPersonalData()
        self.reloadGlobalData()
    }
    
    func reloadPersonalData() {
        self.mapViewController?.beginReloadPersonalData()
        self.photoViewController?.beginReloadData()
        
        NSURLSession.sharedSession().dataTaskWithURL(self.personalURL) { data, response, error in
            let html = NSString(data: data!, encoding: NSUTF8StringEncoding)
            let parser = NDHpple(HTMLData: html! as String)
            let xpath = "//div[@class='container body-content']/div/div"
            
            guard let nodes = parser.searchWithXPathQuery(xpath) else {
                print("Failed to parse")
                return
            }
            
            self.personalPhotos = nodes.flatMap({ element -> PhotoInfo? in
                guard let children = element.childrenWithTagName("div"),
                    let url = children[0].firstChildWithTagName("img")?.attributes["src"] as? String,
                    let coorStr = children[1].children?[3].content else {
                        
                        print("Failed")
                        return nil
                }
                
                let photo = PhotoInfo()
                photo.url = "http://140.113.195.27" + url
                photo.image = nil
                
                let coor = coorStr.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "()")).characters.split(",").map(String.init)
                photo.coordinate = CLLocationCoordinate2D(latitude: Double(coor[1])!, longitude: Double(coor[0])!)
                
                return photo
            }).reverse()
            
            self.personalPhotosToLoad = self.personalPhotos!.count
            for photo in self.personalPhotos! {
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: photo.url)!) { data, response, error in
                    photo.image = UIImage(data: data!)
                    
                    self.personalPhotosToLoad--
                    if self.personalPhotosToLoad == 0 {
                        self.mapViewController?.updatePersonalData()
                        self.photoViewController?.updateData()
                    }
                }.resume()
            }
        }.resume()
    }
    
    func reloadGlobalData() {
        self.mapViewController?.beginReloadGlobalData()
        
        NSURLSession.sharedSession().dataTaskWithURL(self.globalURL) { data, response, error in
            let html = NSString(data: data!, encoding: NSUTF8StringEncoding)
            let parser = NDHpple(HTMLData: html! as String)
            let xpath = "//div[@class='styHiddenPos']"
            
            guard let nodes = parser.searchWithXPathQuery(xpath) else {
                print("Failed to parse")
                return
            }
            
            self.globalPositions = nodes.flatMap { element -> GlobalInfo? in
                let attr = element.attributes
                
                guard let latStr = attr["data-lat"] as? String, let lat = Double(latStr),
                    let longStr = attr["data-lng"] as? String, let long = Double(longStr),
                    let account = attr["data-account"] as? String else {
                        return nil
                }
                
                let position = GlobalInfo()
                position.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                position.title = account
                return position
            }
            
            self.mapViewController?.updateGlobalData()
        }.resume()
    }
}