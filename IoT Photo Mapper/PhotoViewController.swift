//
//  PhotoViewController.swift
//  IoT Photo Mapper
//
//  Created by Chih-Yung Liang on 2016/1/2.
//  Copyright © 2016年 Chih-Yung Liang. All rights reserved.
//

import UIKit
import MapKit

class PhotoViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    @IBOutlet weak var photoTableView: UITableView!
    @IBOutlet weak var overlayView: UIView!
    weak var coreData: CoreData?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.photoTableView.dataSource = self
        self.photoTableView.delegate = self
        self.updateData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func beginReloadData() {
        self.overlayView.hidden = false
    }
    
    func updateData() {
        if self.viewIfLoaded == nil || self.coreData?.personalPhotos == nil {
            return
        }
        
        self.photoTableView.reloadData()
        self.overlayView.hidden = true
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("prototype") ?? UITableViewCell(style: .Default, reuseIdentifier: "prototype")
        let imageView = cell.contentView.subviews[0] as! UIImageView
        
        imageView.image = self.coreData!.personalPhotos![indexPath.row].image
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        guard let photoSize = self.coreData?.personalPhotos?[indexPath.row].image?.size else {
            return 0
        }
        
        return photoSize.height / photoSize.width * (tableView.frame.width - 30) + 30
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.coreData?.personalPhotos?.count ?? 0
        }
        
        return 0
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
