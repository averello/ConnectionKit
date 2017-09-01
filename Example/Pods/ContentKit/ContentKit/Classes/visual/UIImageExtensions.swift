//
//  UIImageExtensions.swift
//  ContentKit
//
//  Created by Georges Boumis on 16/05/2017.
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the
//  "License"); you may not use this file except in compliance
//  with the License.  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.
//

import Foundation

extension UIImage: Image {
    public var image: UIImage {
        return self
    }
    
    public func scaled(_ scale: Float) -> Image {
        let newWidth = self.size.width.multiplied(by: CGFloat(scale))
        let newHeight = self.size.height.multiplied(by: CGFloat(scale))
        let newSize = CGSize(width: newWidth, height: newHeight).ceiled
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        self.draw(in: CGRect(origin: CGPoint.zero, size: newSize))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return AnyImage(image: image!)
    }
}