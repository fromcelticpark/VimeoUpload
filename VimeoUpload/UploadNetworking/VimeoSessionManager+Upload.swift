//
//  VimeoSessionManager+Upload.swift
//  VimeoUpload
//
//  Created by Alfred Hanssen on 10/21/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

enum TaskDescription: String
{
    case CreateVideo = "CreateVideo"
    case UploadVideo = "UploadVideo"
    case ActivateVideo = "ActivateVideo"
    case VideoSettings = "VideoSettings"
}

typealias DestinationHandler = () -> NSURL
typealias CreateVideoCompletionHandler = (response: CreateVideoResponse?, error: NSError?) -> Void

extension VimeoSessionManager
{
    func createVideoDownloadTask(url url: NSURL, destination: DestinationHandler?, completionHandler: CreateVideoCompletionHandler?) throws -> NSURLSessionDownloadTask
    {
        let request = try (self.requestSerializer as! VimeoRequestSerializer).createVideoRequestWithUrl(url)

        let task = self.downloadTaskWithRequest(request, progress: nil, destination: { (url, response) -> NSURL in
            
            if let destination = destination
            {
                return destination()
            }
            
            return try! VimeoSessionManager.DocumentsURL.vimeoDownloadDataURL()
            
        }, completionHandler: { [weak self] (response, url, error) -> Void in
            
            guard let strongSelf = self, let completionHandler = completionHandler else
            {
                return
            }
            
            do
            {
                let response = try (strongSelf.responseSerializer as! VimeoResponseSerializer).processCreateVideoResponse(response, url: url, error: error)
                completionHandler(response: response, error: nil)
            }
            catch let error as NSError
            {
                completionHandler(response: nil, error: error)
            }
        })
        
        task.taskDescription = TaskDescription.CreateVideo.rawValue
        
        return task
    }
    
    func uploadVideoTask(source: NSURL, destination: String, progress: AutoreleasingUnsafeMutablePointer<NSProgress?>, completionHandler: ErrorBlock?) throws -> NSURLSessionUploadTask
    {
        let request = try (self.requestSerializer as! VimeoRequestSerializer).uploadVideoRequestWithSource(source, destination: destination)
        
        let task = self.uploadTaskWithRequest(request, fromFile: source, progress: progress, completionHandler: { [weak self] (response, responseObject, error) -> Void in
            
            guard let strongSelf = self, let completionHandler = completionHandler else
            {
                return
            }
            
            do
            {
                try (strongSelf.responseSerializer as! VimeoResponseSerializer).processUploadVideoResponse(response, responseObject: responseObject, error: error)
                completionHandler(error: nil)
            }
            catch let error as NSError
            {
                completionHandler(error: error)
            }
        })

        task.taskDescription = TaskDescription.UploadVideo.rawValue
        
        return task
    }
    
    func activateVideoTask(activationUri: String, destination: DestinationHandler?, completionHandler: StringErrorBlock?) throws -> NSURLSessionDownloadTask
    {
        let request = try (self.requestSerializer as! VimeoRequestSerializer).activateVideoRequestWithUri(activationUri)
        
        let task = self.downloadTaskWithRequest(request, progress: nil, destination: { (url, response) -> NSURL in
            
            if let destination = destination
            {
                return destination()
            }
            
            return try! VimeoSessionManager.DocumentsURL.vimeoDownloadDataURL()
            
        }, completionHandler: { [weak self] (response, url, error) -> Void in
            
            guard let strongSelf = self, let completionHandler = completionHandler else
            {
                return
            }
            
            do
            {
                let response = try (strongSelf.responseSerializer as! VimeoResponseSerializer).processActivateVideoResponse(response, url: url, error: error)
                completionHandler(value: response, error: nil)
            }
            catch let error as NSError
            {
                completionHandler(value: nil, error: error)
            }
        })
        
        task.taskDescription = TaskDescription.ActivateVideo.rawValue
        
        return task
    }    

    func videoSettingsTask(videoUri: String, videoSettings: VideoSettings, destination: DestinationHandler?, completionHandler: ErrorBlock?) throws -> NSURLSessionDownloadTask
    {
        let request = try (self.requestSerializer as! VimeoRequestSerializer).videoSettingsRequestWithUri(videoUri, videoSettings: videoSettings)
        
        let task = self.downloadTaskWithRequest(request, progress: nil, destination: { (url, response) -> NSURL in
            
            if let destination = destination
            {
                return destination()
            }
            
            return try! VimeoSessionManager.DocumentsURL.vimeoDownloadDataURL()
            
        }, completionHandler: { [weak self] (response, url, error) -> Void in
            
            guard let strongSelf = self, let completionHandler = completionHandler else
            {
                return
            }
            
            do
            {
                try (strongSelf.responseSerializer as! VimeoResponseSerializer).processVideoSettingsResponse(response, url: url, error: error)
                completionHandler(error: nil)
            }
            catch let error as NSError
            {
                completionHandler(error: error)
            }
        })
        
        task.taskDescription = TaskDescription.VideoSettings.rawValue
        
        return task
    }
}