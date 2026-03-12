//
//  Item.swift
//  Fleet-Tracker
//
//  Created by Maher Yousif on 3/10/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
