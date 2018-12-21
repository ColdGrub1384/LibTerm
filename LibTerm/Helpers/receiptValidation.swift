// From https://stackoverflow.com/a/47146348/7515957

import Foundation
import StoreKit

/// Validates receipts and stores original purchased version.
func receiptValidation() {
    
    if Thread.current.isMainThread {
        return DispatchQueue.global().async {
            receiptValidation()
        }
    }
    
    let SUBSCRIPTION_SECRET = "2215178a6443418e814339adb05dddfd"
    let receiptPath = Bundle.main.appStoreReceiptURL?.path
    if FileManager.default.fileExists(atPath: receiptPath!){
        var receiptData:NSData?
        do{
            receiptData = try NSData(contentsOf: Bundle.main.appStoreReceiptURL!, options: NSData.ReadingOptions.alwaysMapped)
        }
        catch{
            print("ERROR: " + error.localizedDescription)
        }
        //let receiptString = receiptData?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        let base64encodedReceipt = receiptData?.base64EncodedString(options: NSData.Base64EncodingOptions.endLineWithCarriageReturn)
        
        print(base64encodedReceipt!)
        
        
        let requestDictionary = ["receipt-data":base64encodedReceipt!,"password":SUBSCRIPTION_SECRET]
        
        guard JSONSerialization.isValidJSONObject(requestDictionary) else {  print("requestDictionary is not valid JSON");  return }
        do {
            let requestData = try JSONSerialization.data(withJSONObject: requestDictionary)
            let validationURLString = "https://sandbox.itunes.apple.com/verifyReceipt"  // this works but as noted above it's best to use your own trusted server
            guard let validationURL = URL(string: validationURLString) else { print("the validation url could not be created, unlikely error"); return }
            let session = URLSession(configuration: URLSessionConfiguration.default)
            var request = URLRequest(url: validationURL)
            request.httpMethod = "POST"
            request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringCacheData
            let task = session.uploadTask(with: request, from: requestData) { (data, response, error) in
                if let data = data , error == nil {
                    do {
                        let appReceiptJSON = try JSONSerialization.jsonObject(with: data)
                        
                        if let jsonDict = appReceiptJSON as? [String: Any] {
                            print(jsonDict)
                            if let appVersion = (jsonDict["receipt"] as? [String:Any])?["original_application_version"] as? String {
                                Python3Locker.originalApplicationVersion.stringValue = appVersion
                            }
                        }
                        
                        print("success. here is the json representation of the app receipt: \(appReceiptJSON)")
                        // if you are using your server this will be a json representation of whatever your server provided
                    } catch let error as NSError {
                        print("json serialization failed with error: \(error.localizedDescription)")
                    }
                } else {
                    print("the upload task returned an error: \(error?.localizedDescription ?? "")")
                }
            }
            task.resume()
        } catch let error as NSError {
            print("json serialization failed with error: \(error)")
        }
    } else {
        print("No receipt")
    }
}
