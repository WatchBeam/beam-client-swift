//
//  BeamRequest.swift
//  Beam API
//
//  Created by Jack Cook on 3/15/15.
//  Copyright (c) 2015 Jack Cook. All rights reserved.
//

import Foundation
import SwiftyJSON

public class BeamRequest {
    
    public static var imageCache = [String: UIImage]()
    
    public class func request(endpoint: String, requestType: String) {
        BeamRequest.request("https://beam.pro/api/v1\(endpoint)", requestType: requestType) { (data, error) -> Void in }
    }
    
    public class func request(endpoint: String, requestType: String, completion: (json: JSON?, error: BeamRequestError?) -> Void) {
        BeamRequest.request("https://beam.pro/api/v1\(endpoint)", requestType: requestType, headers: [String: String](), params: [String: String](), body: "", completion: completion)
    }
    
    public class func request(endpoint: String, requestType: String, body: String, completion: (json: JSON?, error: BeamRequestError?) -> Void) {
        BeamRequest.request("https://beam.pro/api/v1\(endpoint)", requestType: requestType, headers: [String: String](), params: [String: String](), body: body, completion: completion)
    }
    
    public class func request(endpoint: String, requestType: String, headers: [String: String], completion: (json: JSON?, error: BeamRequestError?) -> Void) {
        BeamRequest.request("https://beam.pro/api/v1\(endpoint)", requestType: requestType, headers: headers, params: [String: String](), body: "", completion: completion)
    }
    
    public class func request(endpoint: String, requestType: String, params: [String: String], completion: (json: JSON?, error: BeamRequestError?) -> Void) {
        BeamRequest.request("https://beam.pro/api/v1\(endpoint)", requestType: requestType, headers: [String: String](), params: params, body: "", completion: completion)
    }
    
    public class func request(endpoint: String, requestType: String, headers: [String: String], params: [String: String], body: String, completion: (json: JSON?, error: BeamRequestError?) -> Void) {
        BeamRequest.dataRequest(endpoint, requestType: requestType, headers: headers, params: params, body: body) { (data, error) -> Void in
            guard let data = data else {
                completion(json: nil, error: error)
                return
            }
            
            let json = JSON(data: data)
            completion(json: json, error: error)
        }
    }
    
    public class func imageRequest(url: String, completion: (image: UIImage?, error: BeamRequestError?) -> Void) {
        imageRequest(url, fromCache: true, completion: completion)
    }
    
    public class func imageRequest(url: String, fromCache: Bool, completion: (image: UIImage?, error: BeamRequestError?) -> Void) {
        if fromCache {
            if let img = imageCache[url] {
                completion(image: img, error: nil)
                return
            }
        }
        
        BeamRequest.dataRequest(url, requestType: "GET") { (data, error) -> Void in
            guard let data = data,
                image = UIImage(data: data) else {
                    completion(image: nil, error: error)
                    return
            }
            
            imageCache[url] = image
            completion(image: image, error: error)
        }
    }
    
    public class func dataRequest(url: String, requestType: String, completion: (data: NSData?, error: BeamRequestError?) -> Void) {
        BeamRequest.dataRequest(url, requestType: requestType, headers: [String: String](), params: [String: String](), body: "", completion: completion)
    }
    
    public class func dataRequest(url: String, requestType: String, headers: [String: String], params: [String: String], body: String, completion: (data: NSData?, error: BeamRequestError?) -> Void) {
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        var url = NSURL(string: url)!
        url = self.NSURLByAppendingQueryParameters(url, queryParameters: params)
        
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = requestType
        request.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding)
        
        for (header, val) in headers {
            request.addValue(val, forHTTPHeaderField: header)
        }
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            guard let response = response as? NSHTTPURLResponse else {
                completion(data: nil, error: .Unknown)
                return
            }
            
            var requestError: BeamRequestError? = nil
            
            if let error = error {
                switch error.code {
                case -1009:
                    requestError = BeamRequestError.Offline
                default:
                    requestError = BeamRequestError.Unknown
                }
                
                completion(data: nil, error: requestError)
            } else if response.statusCode != 200 {
                switch response.statusCode {
                case 400:
                    print(NSString(data: data!, encoding: NSUTF8StringEncoding))
                    requestError = BeamRequestError.BadRequest
                case 401:
                    requestError = BeamRequestError.InvalidCredentials
                case 403:
                    requestError = BeamRequestError.AccessDenied
                case 404:
                    requestError = BeamRequestError.NotFound
                case 499:
                    requestError = BeamRequestError.Requires2FA
                default:
                    print("Unknown status code: \(response.statusCode)")
                    requestError = BeamRequestError.Unknown
                }
                
                completion(data: data, error: requestError)
            } else {
                if let data = data {
                    completion(data: data, error: nil)
                } else {
                    completion(data: nil, error: nil)
                }
            }
        })
        
        task.resume()
    }
    
    private class func stringFromQueryParameters(queryParameters: [String: String]) -> String {
        var parts: [String] = []
        for (name, value) in queryParameters {
            let part = NSString(format: "%@=%@",
                name.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!,
                value.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!)
            parts.append(part as String)
        }
        return parts.joinWithSeparator("&")
    }
    
    private class func NSURLByAppendingQueryParameters(url: NSURL!, queryParameters: [String: String]) -> NSURL {
        let URLString = NSString(format: "%@?%@", url.absoluteString, self.stringFromQueryParameters(queryParameters))
        return NSURL(string: URLString as String)!
    }
}