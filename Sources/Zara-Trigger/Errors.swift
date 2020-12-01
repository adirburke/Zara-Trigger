//
//  Errors.swift
//  Common
//
//  Created by Adir Burke on 17/9/20.
//

import Foundation

extension Error {
    var localizedDescription : String {
        return "\(type(of: self)) \(self)"
    }
}
