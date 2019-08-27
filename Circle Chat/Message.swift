import Foundation
import Firebase
import FirebaseFirestore
import CoreLocation
import MessageKit
import AVFoundation

private struct CoordinateItem: LocationItem {
    
    var location: CLLocation
    var size: CGSize
    
    init(location: CLLocation) {
        self.location = location
        self.size = CGSize(width: 240, height: 240)
    }
    
}

private struct ImageMediaItem: MediaItem {
    
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
    init(image: UIImage) {
        self.image = image
        self.size = CGSize(width: 240, height: 240)
        self.placeholderImage = UIImage()
    }
    
}

private struct Audiotem: AudioItem {
    
    var url: URL
    var size: CGSize
    var duration: Float
    
    init(url: URL) {
        self.url = url
        self.size = CGSize(width: 160, height: 35)
        // compute duration
        let audioAsset = AVURLAsset(url: url)
        self.duration = Float(CMTimeGetSeconds(audioAsset.duration))
    }
    
}

internal struct Message: MessageType {
    
    let id: String?
    
    var messageId: String {
        return id ?? UUID().uuidString
    }
    var sender: SenderType
    var sentDate: Date
    var kind: MessageKind
    var content: String
    
    var user: User
    
    var image: UIImage? = nil
    
    var downloadURL: URL? = nil
    
    private init(kind: MessageKind, content: String, user: User, sender: Sender, messageId: String, date: Date) {
        //sender = Sender(id: user.uid, displayName: user.email!)
        self.kind = kind
        self.user = user
        self.id = messageId
        self.sentDate = date
        self.content = content
        self.sender = sender
    }
    
    init(custom: Any?, user: User, sender: Sender, messageId: String, date: Date) {
        self.init(kind: .custom(custom), content: "", user: user, sender: sender, messageId: messageId, date: date)
        self.sender = sender
    }
    
    init(text: String, user: User, sender: Sender, messageId: String, date: Date) {
        self.init(kind: .text(text), content: text, user: user, sender: sender, messageId: messageId, date: date)
        self.sender = sender
    }
    
    init(image: UIImage, user: User, sender: Sender, messageId: String, date: Date) {
        let mediaItem = ImageMediaItem(image: image)
        self.init(kind: .photo(mediaItem), content: "", user: user, sender: sender, messageId: messageId, date: date)
        self.sender = sender
    }
    
    init?(document: QueryDocumentSnapshot, user: User) {
        let data = document.data()
        
        
        guard let sentDate = data["created"] as? Date else {
            return nil
        }
        guard let senderID = data["senderID"] as? String else {
            return nil
        }
        guard let senderName = data["senderName"] as? String else {
            return nil
        }
        
        id = document.documentID
        self.user = user
        
        self.sentDate = sentDate
        sender = Sender(id: senderID, displayName: senderName)
        
        if let content = data["content"] as? String {
            self.content = content
            self.kind = .text(content)
            downloadURL = nil
        } else if let urlString = data["url"] as? String, let url = URL(string: urlString) {
            downloadURL = url
            content = ""
            self.kind = .text(content)
        } else {
            return nil
        }
    }
    
//    init(emoji: String, user: User, messageId: String, date: Date) {
//        self.init(kind: .emoji(emoji), user: user, messageId: messageId, date: date)
//        sender = Sender(id: user.uid, displayName: user.email!)
//    }
    
}

extension Message: DatabaseRepresentation {
    
    var representation: [String : Any] {
        var rep: [String : Any] = [
            "created": sentDate,
            "senderID": sender.senderId,
            "senderName": sender.displayName
        ]
        
        if let url = downloadURL {
            rep["url"] = url.absoluteString
        } else {
            rep["content"] = content
        }
        
        return rep
    }
    
}

extension Message: Comparable {
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.messageId == rhs.messageId
    }
    
    static func < (lhs: Message, rhs: Message) -> Bool {
        return lhs.sentDate < rhs.sentDate
    }
    
}
