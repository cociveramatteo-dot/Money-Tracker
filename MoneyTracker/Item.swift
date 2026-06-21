//
//  Item.swift
//  MoneyTracker
//
//  Created by Matteo Cocivera on 21/06/26.
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
