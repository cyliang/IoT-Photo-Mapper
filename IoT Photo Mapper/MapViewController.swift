//
//  PublicViewController.swift
//  IoT Photo Mapper
//
//  Created by Chih-Yung Liang on 2015/12/30.
//  Copyright © 2015年 Chih-Yung Liang. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var globalSwitch: UISwitch!
    @IBOutlet weak var overlayView: UIView!
    
    weak var coreData: CoreData?
    
    class ImageAnnotation: MKPointAnnotation {
        var photoInfo: CoreData.PhotoInfo?
    }
    var globalAnnotations: [MKPointAnnotation]?
    var personalAnnotations: [ImageAnnotation]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.mapView.showsUserLocation = true
        self.mapView.userTrackingMode = .Follow
        self.mapView.delegate = self
        
        if self.personalAnnotations == nil {
            self.beginReloadPersonalData()
        } else {
            self.updatePersonalData()
        }
        if self.globalAnnotations != nil {
            self.overlayView.hidden = true
        } else {
            self.updateGlobalData()
        }
    }
    
    func beginReloadGlobalData() {
        if self.viewIfLoaded != nil {
            self.overlayView.hidden = false
        }
    }
    
    func beginReloadPersonalData() {
        if self.viewIfLoaded != nil {
            self.globalSwitch.on = true
            self.globalSwitch.enabled = false
            self.globalSwitch.userInteractionEnabled = false
        }
    }
    
    func updateGlobalData() {
        if self.viewIfLoaded == nil || self.coreData?.globalPositions == nil {
            return
        }
        
        self.globalAnnotations = coreData!.globalPositions!.map { position -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.coordinate = position.coordinate
            annotation.title = position.title
            
            return annotation
        }
        
        self.overlayView.hidden = true
        
        if self.globalSwitch.on {
            self.reloadData()
        }
    }
    
    func updatePersonalData() {
        if self.viewIfLoaded == nil || self.coreData?.personalPhotos == nil {
            return
        }
        
        self.personalAnnotations = self.coreData!.personalPhotos!.map { photo -> ImageAnnotation in
            let annotation = ImageAnnotation()
            annotation.coordinate = photo.coordinate
            annotation.photoInfo = photo
            annotation.title = " "
            
            return annotation
        }
        
        self.globalSwitch.enabled = true
        self.globalSwitch.userInteractionEnabled = true
        
        if !self.globalSwitch.on {
            self.reloadData()
        }
    }
    
    @IBAction
    func reloadData() {
        guard let nowData = self.globalSwitch.on ? globalAnnotations : personalAnnotations else {
            return
        }
        
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.mapView.addAnnotations(nowData)
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        guard let image = (annotation as? ImageAnnotation)?.photoInfo?.image else {
            return nil
        }
        
        var annotationView = self.mapView.dequeueReusableAnnotationViewWithIdentifier("PersonalPhotoAnnotation")
        
        if annotationView != nil {
            annotationView!.annotation = annotation
        } else {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "PersonalPhotoAnnotation")
            annotationView!.canShowCallout = true
            annotationView!.detailCalloutAccessoryView = UIImageView()
            annotationView!.detailCalloutAccessoryView!.contentMode = .ScaleAspectFit
        }
        
        (annotationView!.detailCalloutAccessoryView as! UIImageView).image = image
        
        return annotationView
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
