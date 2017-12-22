//
//  TodoItem.swift
//  Todo
//
//  Created by Brian Advent on 08.12.17.
//  Copyright © 2017 Brian Advent. All rights reserved.
//

import CloudKit



struct TodoItem : Codable {

    var title:String
    var completed:Bool
    var createdAt:Date
    var itemIdentifier:UUID
    
    func saveItem() {
        DataManager.save(self, with: "\(itemIdentifier.uuidString)")
    }
    
    func deleteItem() {
        DataManager.delete(itemIdentifier.uuidString)
    }
    
    mutating func markAsCompleted(){
        self.completed = true
        DataManager.save(self, with: "\(itemIdentifier.uuidString)")
    }

}




