//
//  DirectMessage.swift
//  Circle Chat
//
//  Created by Dalton Teague on 8/6/19.
//  Copyright © 2019 Dalton Teague. All rights reserved.
//

import FirebaseFirestore

struct DirectMessage {
    
    let id: String?
    let user1: String
    let user2: String
    
    init(user1: String, user2: String) {
        id = nil
        self.user1 = user1
        self.user2 = user2
    }
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let user1 = data["user1_ID"] as? String else {
            return nil
        }
        guard let user2 = data["user2_ID"] as? String else {
            return nil
        }
        
        self.id = document.documentID
        self.user1 = user1
        self.user2 = user2
    }
    
}

extension DirectMessage: DatabaseRepresentation {
    
    var representation: [String : Any] {
        
        var rep = ["user1_ID": user1, "user2_ID": user2]
       // var rep = ["user2_ID": user2]
        
        if let id = id {
            rep["id"] = id
        }
            
        return rep
        
    }
    
}

extension DirectMessage: Comparable {
    
    static func == (lhs: DirectMessage, rhs: DirectMessage) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func < (lhs: DirectMessage, rhs: DirectMessage) -> Bool {
        return lhs.user1 < rhs.user1
    }
    
}
