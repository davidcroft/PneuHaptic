//
//  mainUITableViewController.swift
//  BlindGuideV1
//
//  Created by Ding Xu on 11/24/14.
//  Copyright (c) 2014 Ding Xu. All rights reserved.
//

import UIKit
import CoreBluetooth

class mainUITableViewController: UITableViewController, UITableViewDataSource, CBCentralManagerDelegate{

    var centralManager: CBCentralManager!
    var peripehralNameList:[NSString] = []
    let serviceUUID = CBUUID(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e")
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // bluetooth init
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // turn on network activity
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        // table view init
        tableView.rowHeight = 60

    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("deviceItem") as? mainUITableViewCell ?? mainUITableViewCell()
        let deviceName = self.peripehralNameList[indexPath.row]
        cell.cellTitle.text = deviceName
        cell.cellCoverImage.image = UIImage(named: "navigation-icon.png")
        //cell.cellCoverImage.image = UIImage(named:"bookThumbDefault.jpg")
        // turn the image to round
        cell.cellCoverImage.layer.cornerRadius = cell.cellCoverImage.bounds.size.height / 2.0
        cell.cellCoverImage.clipsToBounds = true // very important, not mask the image otherwise
        return cell
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return self.albums.count
        return self.peripehralNameList.count
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        case "deviceToConnect":
            if var secondViewController = segue.destinationViewController as? ViewController {
                if var cell = sender as? mainUITableViewCell {
                    var index = tableView!.indexPathForSelectedRow()!.row
                    var selectedDevice = self.peripehralNameList[index]
                    secondViewController.BLEName = selectedDevice
                }
            }
        default:
            break
        }
    }
    
    ///////////// bluetooth /////////////
    // Invoked when the central manager’s state is updated (required)
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        if central.state == .PoweredOn {
            NSLog("TableView: Central ON")
            // scanning available bluetooth devices
            centralManager.stopScan()
            centralManager.scanForPeripheralsWithServices([self.serviceUUID!], options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        }
    }
    
    // Invoked when the central manager discovers a peripheral while scanning
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        
        //////////// list available peripheral /////////
        if (peripheral != nil) {
            var BLEName:NSString! = peripheral!.valueForKey("name") as NSString
            if (!contains(peripehralNameList, BLEName)) {
                peripehralNameList.append(BLEName)
                println(BLEName)
                self.tableView!.reloadData()
            }
        }
    }

}
