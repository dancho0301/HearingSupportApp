//
//  Item.swift
//  HearingSupportApp
//
//  Created by dancho on 2025/05/27.
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
