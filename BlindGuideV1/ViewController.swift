//
//  ViewController.swift
//  BlindGuideV1
//
//  Created by Ding Xu on 11/24/14.
//  Copyright (c) 2014 Ding Xu. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    @IBOutlet var stopButton: UIButton!
    @IBOutlet var leftButton: UIButton!
    @IBOutlet var rightButton: UIButton!
    
    
    // bluetooth
    let serviceUUID = CBUUID(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e")
    let txCharUUID  = CBUUID(string: "6e400002-b5a3-f393-e0a9-e50e24dcca9e")
    let rxCharUUID  = CBUUID(string: "6e400003-b5a3-f393-e0a9-e50e24dcca9e")
    let deviceInfoServiceUUID   = CBUUID(string: "180A")
    let hardwareRevisionStrUUID = CBUUID(string: "2A27")
    
    //var peripheralManager: CBPeripheralManager!
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral?
    var txCharacteristic: CBCharacteristic?
    var rxCharacteristic: CBCharacteristic?
    var uartService: CBService?
    
    // book page message
    var BLEName:NSString! = ""
    let BLEMsgStart:NSString! = ":"
    let BLEMsgEnd:NSString! = "#"

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // set button image
        //stopButton.setImage(UIImage(named: "navigation-icon.png"), forState: UIControlState.Normal)
        //leftButton.setImage(UIImage(named: "navigation-icon.png"), forState: UIControlState.Normal)
        //rightButton.setImage(UIImage(named: "navigation-icon.png"), forState: UIControlState.Normal)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //////////////////////////////////////////////////
    ///////////// Bluetooth connection ///////////////
    // Invoked when the central manager’s state is updated (required)
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        if central.state == .PoweredOn {
            NSLog("central on")
            // scanning
            centralManager.scanForPeripheralsWithServices([self.serviceUUID!], options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        }
    }
    
    // Invoked when the central manager discovers a peripheral while scanning
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        var periName:NSString! = peripheral!.valueForKey("name") as NSString
        if (periName == self.BLEName) {
            // Clear off any pending connections
            centralManager.stopScan()
            centralManager.cancelPeripheralConnection(peripheral)
            
            // find peripheral
            NSLog("Did discover peripheral: \(peripheral.name)")
            self.peripheral = peripheral
            
            //connectPeripheral
            let numberWithBool = NSNumber(bool: true)
            central.connectPeripheral(peripheral, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey:false])
        }
    }
    
    // Invoked when a call to connectPeripheral:options: is successful.
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID, deviceInfoServiceUUID])
    }
    
    // Invoked when a call to discoverServices: method
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        if (error == nil) {
            for s:CBService in peripheral.services as [CBService] {
                if (s.UUID.UUIDString == serviceUUID.UUIDString) {
                    // service
                    NSLog("Found correct service")
                    uartService = s
                    // Discovers the specified characteristics of a service
                    peripheral.discoverCharacteristics([txCharUUID, rxCharUUID], forService: uartService)
                } else if (s.UUID.UUIDString == deviceInfoServiceUUID.UUIDString) {
                    peripheral.discoverCharacteristics([hardwareRevisionStrUUID], forService: s)
                }
            }
        } else {
            NSLog("Discover services error: \(error)")
            return
        }
    }
    
    // Invoked when the peripheral discovers one or more characteristics of the specified service
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        if (error == nil) {
            NSLog("Discover Characteristics For Service: \(service.description)")
            let services:[CBService] = peripheral.services as [CBService]
            let s = services[services.count - 1]
            if service.UUID.UUIDString == s.UUID.UUIDString {
                for s:CBService in peripheral.services as [CBService] {
                    for c:CBCharacteristic in s.characteristics as [CBCharacteristic] {
                        if (c.UUID.UUIDString == rxCharUUID.UUIDString) {
                            NSLog("Found RX Characteristics")
                            rxCharacteristic = c
                            peripheral.setNotifyValue(true, forCharacteristic: rxCharacteristic)
                            /*// send first message only after both rx and tx characters have been set
                            if (txCharacteristic != nil) {
                                self.sendBLEMsg("hello, world")
                            }*/
                        } else if (c.UUID.UUIDString == txCharUUID.UUIDString) {
                            NSLog("Found TX Characteristics")
                            txCharacteristic = c
                            peripheral.setNotifyValue(false, forCharacteristic: txCharacteristic)
                            // send first message only after both rx and tx characters have been set
                            /*if (rxCharacteristic != nil) {
                                self.sendBLEMsg("hello, world")
                            }*/
                        } else if (c.UUID.UUIDString == hardwareRevisionStrUUID.UUIDString) {
                            NSLog("Found Hardware Revision String characteristic")
                            peripheral.readValueForCharacteristic(c)
                        }
                    }
                }
            }
        }
    }
    
    // Invoked after write a characteristic with property .WriteWithResponse
    func peripheral(peripheral: CBPeripheral!, didWriteValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        NSLog("didWriteValueForCharacteristic")
    }
    
    // Invoked if there is a update with all the characteristics that setNotifyValue to be True
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        //NSLog("Did Update Value For Characteristic")
        if error == nil {
            if (characteristic == rxCharacteristic) {
                //NSLog("Recieved: \(characteristic.value)")
                let rxStr:NSString! = NSString(data: characteristic.value, encoding:NSUTF8StringEncoding)
                //println(rxStr)
                NSLog("Received value is \(rxStr)")
            }
            else if characteristic.UUID.UUIDString == hardwareRevisionStrUUID.UUIDString {
                NSLog("Did read hardware revision string")
                var hwRevision:NSString = ""
                var bytes:UnsafePointer<UInt8> = UnsafePointer<UInt8>(characteristic.value.bytes)
                var i:Int
                for (i = 0; i < characteristic.value.length; i++){
                    hwRevision = hwRevision.stringByAppendingFormat("0x%x, ", bytes[i])
                }
                //Once hardware revision string is read, connection to Bluefruit is complete
                let hwStr = hwRevision.substringToIndex(hwRevision.length-2)
                NSLog("HW Revision: \(hwStr)")
            }
        }
        else {
            NSLog("Error receiving notification for characteristic: \(error)")
            return
        }
    }
    
    func sendBLEMsg(sendStr: NSString!) {
        // write char
        let newString: NSString = sendStr
        let txData: NSData = NSData(bytes: newString.UTF8String, length: newString.length)
        NSLog("Sending: \(txData)");
        NSLog(String(self.txCharacteristic!.properties.rawValue))
        if (self.txCharacteristic != nil) {
            //if (self.txCharacteristic!.properties & CBCharacteristicProperties.WriteWithoutResponse)
            if (self.txCharacteristic!.properties == CBCharacteristicProperties.WriteWithoutResponse) {
                self.peripheral!.writeValue(txData, forCharacteristic: self.txCharacteristic, type: .WithoutResponse)
            }
            else if (self.txCharacteristic!.properties == CBCharacteristicProperties.Write) {
                self.peripheral!.writeValue(txData, forCharacteristic: self.txCharacteristic, type: .WithResponse)
            }
            else {
                NSLog("No write property on TX characteristic, %d.", self.txCharacteristic!.properties.rawValue)
            }
        }
    }

    @IBAction func tappingLeftBtn(sender: AnyObject) {
        self.sendBLEMsg("#1$")
    }
    @IBAction func tappingRightBtn(sender: AnyObject) {
        self.sendBLEMsg("#2$")
    }
    
    
    @IBAction func holdingBtn(sender: AnyObject) {
        self.sendBLEMsg("#3$")
    }
    
    
    @IBAction func tracingLeftBtn(sender: AnyObject) {
        self.sendBLEMsg("#4$")
    }
    @IBAction func tracingRightBtn(sender: AnyObject) {
        self.sendBLEMsg("#5$")
    }
    
    
    @IBAction func releaseBtn(sender: AnyObject) {
        self.sendBLEMsg("#0$")
    }
}

