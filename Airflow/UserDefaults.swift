//
//  UserDefaults.swift
//  Airflow
//
//  Created by Sanchitha Dinesh on 8/29/20.
//  Copyright © 2020 Sanchitha Dinesh. All rights reserved.
//

import Foundation

extension UserDefaults {
    var zipcode: String? {
        get {
            return UserDefaults.standard.string(forKey: #function)
        }
        set {
            guard let string = newValue else { return }
            UserDefaults.standard.set(string, forKey: #function)
        }
    }
}
