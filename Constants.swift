//
//  Constants.swift
//  Circle Chat
//
//  Created by Dalton Teague on 6/14/18.
//  Copyright © 2018 Dalton Teague. All rights reserved.
//

import Foundation
import Firebase

struct Constants
{
    struct refs
    {
        static let databaseRoot = Database.database().reference()
        static let databaseChats = databaseRoot.child("chats")
    }
}


