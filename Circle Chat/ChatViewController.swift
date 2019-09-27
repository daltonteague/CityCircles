import UIKit
import Photos
import Firebase
import MessageKit
import FirebaseFirestore
import InputBarAccessoryView

final class ChatViewController: MessagesViewController {
    
    let outgoingAvatarOverlap: CGFloat = 17.5
    
    private var isSendingPhoto = false {
        didSet {
            DispatchQueue.main.async {
                self.messageInputBar.leftStackViewItems.forEach { item in
                    //item.isEnabled = !self.isSendingPhoto
                }
            }
        }
    }
    
    private let db = Firestore.firestore()
    private var reference: CollectionReference?
    private let storage = Storage.storage().reference()
    
    private var messages: [Message] = []
    private var messageListener: ListenerRegistration?
    
    private var user: User
    public var channel: Channel?
    public var direct: DirectMessage?
    
    private var indexCount: Int
    private var isDirect: Bool
    
    public var mapVC: MapViewController?
    
    let refreshControl = UIRefreshControl()
    
    var databaseRef = Database.database().reference(fromURL: "https://circle-chat-3cee4.firebaseio.com/")
    
    deinit {
        messageListener?.remove()
    }
    
    init(user: User, channel: Channel) {
        self.user = user
        self.indexCount = 0
        self.channel = channel
        self.isDirect = false
        
        print("init user name is: ", self.user.displayName)
        print("init channel is: ", self.channel?.name)
        print("init channel id is: ", self.channel?.id)
        
        super.init(nibName: nil, bundle: nil)
        
        title = channel.name
        
    }
    
    init(user: User, message: DirectMessage) {
        self.user = user
        self.indexCount = 0
        self.direct = message
        self.isDirect = true
        
        super.init(nibName: nil, bundle: nil)
        
        title = direct?.user2
    }
    
    required init?(coder aDecoder: NSCoder) {
//        //self.user = User()
//        self.indexCount = 0
//        self.user = Auth.auth().currentUser!
        //super.init(coder: aDecoder)
        fatalError("Cannot be instantiated from storyboard")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("chat preview vc is ", mapVC ?? "nil")
        
        Auth.auth().addStateDidChangeListener { auth, userParam in
            print("balss")
            if let theUser = userParam {
                // User is signed in.
                
                self.user = theUser
                print("LOGGED IN!!!!")
                
                
            } else {
                // No user is signed in.
                self.performSegue(withIdentifier: "preview", sender: self)
            }
        }
        
        if (isDirect) {
            if (direct != nil) {
                print("message made it as: ", direct?.user2 as! String)
            }
            
            guard let id = direct?.id else {
                print("here there be dragons")
                navigationController?.popViewController(animated: true)
                return
            }
            
            print("bby id is ", id, " for ", direct?.user1 as Any)
            
            reference = db.collection(["messages", id, "thread"].joined(separator: "/"))
            messageListener = reference?.order(by: "created", descending: false).addSnapshotListener { querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
                    return
                }
                print("Listening to channel updates for ", self.reference?.collectionID as Any)
                snapshot.documentChanges.forEach { change in
                    self.handleDocumentChange(change)
                }
            }
        } else {
            if (channel != nil) {
                print("channel made it as: ", channel?.name as! String, " ", channel?.id as! String)
            }
            
            
            guard let id = channel?.id else {
                print("here there be dragons")
                navigationController?.popViewController(animated: true)
                return
            }
            
            print("bby id is ", id, " for ", channel?.name as Any)
            
            reference = db.collection(["channels", id, "thread"].joined(separator: "/"))
            messageListener = reference?.order(by: "created", descending: false).addSnapshotListener { querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
                    return
                }
                print("Listening to channel updates for ", self.reference?.collectionID as Any)
                snapshot.documentChanges.forEach { change in
                    self.handleDocumentChange(change)
                }
            }
        }
        
        //messages.removeAll()
        //self.messagesCollectionView.numberOfItems(inSection: 0)
        
        navigationItem.largeTitleDisplayMode = .never
        
        maintainPositionOnKeyboardFrameChanged = true
        
        configureMessageInputBar()
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        self.messagesCollectionView.reloadData()
        self.messagesCollectionView.scrollToBottom()
        
        let cameraItem = [
            makeButton().onSelected { b in
                self.cameraButtonPressed()
            }
        ]
        
        //cameraItem.setSize(CGSize(width: 60, height: 30), animated: false)
        
        //messageInputBar.leftStackView.alignment = .center
        //messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)
        //messageInputBar.setStackViewItems(cameraItem, forStack: .left, animated: false) // 3

    }
    
    func configureMessageInputBar() {
        messageInputBar.delegate = self
        messageInputBar.inputTextView.tintColor = .black
        messageInputBar.sendButton.setTitleColor(.black, for: .normal)
        messageInputBar.sendButton.setTitleColor(
            UIColor.black,
            for: .highlighted
        )
    }
    
    func configureMessageCollectionView() {
        
        messagesCollectionView.messagesDataSource = self
        scrollsToBottomOnKeyboardBeginsEditing = true // default false
        maintainPositionOnKeyboardFrameChanged = true // default false
        
        messagesCollectionView.addSubview(refreshControl)
        //refreshControl.addTarget(self, action: #selector(loadMoreMessages), for: .valueChanged)
    }
    
    // MARK: - Actions
    
    @objc private func cameraButtonPressed() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        
        self.present(picker, animated: true, completion: nil)
    }
    
    // MARK: - Helpers
    
    private func save(_ message: Message) {
        
        reference?.addDocument(data: message.representation as [String:Any]) { error in
            if let e = error {
                print("Error sending message: \(e.localizedDescription)")
                return
            }
            
            self.messagesCollectionView.scrollToBottom()
        }
    }
    
    private func insertNewMessage(_ message: Message) {
        messages.append(message)
        //messages.sort()
         //Reload last section to update header/footer labels and insert a new one
        messagesCollectionView.performBatchUpdates({

            messagesCollectionView.insertSections([messages.count - 1])
            print("inserted section")
            if messages.count >= 2 {
                messagesCollectionView.reloadSections([messages.count - 2])
                indexCount += 1

            }
        }, completion: { [weak self] _ in
            if self?.isLastSectionVisible() == true {
                self?.messagesCollectionView.scrollToBottom(animated: true)
            }
        })
//        messages.sort()
//
//        let isLatestMessage = messages.firstIndex(of: message) == (messages.count - 1)
//        let shouldScrollToBottom = isLatestMessage
//
//        messagesCollectionView.reloadData()
//
//        if shouldScrollToBottom {
//            DispatchQueue.main.async {
//                self.messagesCollectionView.scrollToBottom(animated: true)
//            }
//        }
    }
    
    func isLastSectionVisible() -> Bool {
        
        guard !messages.isEmpty else { return false }
        
        let lastIndexPath = IndexPath(item: 0, section: messages.count - 1)
        
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }
    
    private func handleDocumentChange(_ change: DocumentChange) {
        
        let senderName = change.document.get("senderName") as! String
        let uuid = change.document.get("senderID") as! String
        let text = change.document.get("content") as! String
        let timestamp = change.document.get("created") as! Timestamp
        let sender = Sender(id: uuid, displayName: senderName)
        
        let date = timestamp.dateValue()
        
        var message = Message(text: text, user: self.user, sender: sender,  messageId: uuid, date: date)
        print("handling doc change")

        switch change.type {
        case .added:
            if let url = message.downloadURL {
                downloadImage(at: url) { [weak self] image in
                    guard let `self` = self else {
                        return
                    }
                    guard let image = image else {
                        return
                    }
                    
                    message.image = image
                    self.insertNewMessage(message)
                }
            } else {
                insertNewMessage(message)
            }

        default:
            break
        }
    }
    
    
    private func uploadImage(_ image: UIImage, to channel: Channel, completion: @escaping (URL?) -> Void) {
//        guard let channelID = channel.id else {
//            completion(nil)
//            return
//        }
        
//        guard let scaledImage = image., let data = scaledImage.jpegData(compressionQuality: 0.4) else {
//            completion(nil)
//            return
//        }
        
       // let metadata = StorageMetadata()
        //metadata.contentType = "image/jpeg"
        
        //let imageName = [UUID().uuidString, String(Date().timeIntervalSince1970)].joined()
//        storage.child(channelID).child(imageName).putData(data, metadata: metadata) { meta, error in
//            completion(meta?.downloadURL())
//        }
    }
    
    private func sendPhoto(_ image: UIImage) {
        isSendingPhoto = true
        
        uploadImage(image, to: channel!) { [weak self] url in
            guard let `self` = self else {
                return
            }
            self.isSendingPhoto = false
            
            guard let url = url else {
                return
            }
            
//            let message = Message(image: image, user: self.user, messageId: UUID().uuidString, date: Date())
//            //message.downloadURL = url
//
//            self.save(message)
            self.messagesCollectionView.scrollToBottom()
        }
    }
    
    private func downloadImage(at url: URL, completion: @escaping (UIImage?) -> Void) {
        let ref = Storage.storage().reference(forURL: url.absoluteString)
        let megaByte = Int64(1 * 1024 * 1024)
        
        ref.getData(maxSize: megaByte) { data, error in
            guard let imageData = data else {
                completion(nil)
                return
            }
            
            completion(UIImage(data: imageData))
        }
    }
    
    func isTimeLabelVisible(at indexPath: IndexPath) -> Bool {
        return indexPath.section % 3 == 0 && !isPreviousMessageSameSender(at: indexPath)
    }
    
    private func makeButton() -> InputBarButtonItem {
        return InputBarButtonItem()
            .configure {
                $0.spacing = .fixed(10)
                //$0.image = UIImage(named: named)?.withRenderingMode(.alwaysTemplate)
                $0.setSize(CGSize(width: 25, height: 25), animated: false)
                $0.tintColor = UIColor(white: 0.8, alpha: 1)
            }.onSelected {
                $0.tintColor = .gray
            }.onDeselected {
                $0.tintColor = UIColor(white: 0.8, alpha: 1)
            }.onTouchUpInside {
                print("Item Tapped")
                let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                let action = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                actionSheet.addAction(action)
                if let popoverPresentationController = actionSheet.popoverPresentationController {
                    popoverPresentationController.sourceView = $0
                    popoverPresentationController.sourceRect = $0.frame
                }
                self.navigationController?.present(actionSheet, animated: true, completion: nil)
        }
    }
    
    //func setTypingIndicatorViewHidden(_ isHidden: Bool, performUpdates updates: (() -> Void)? = nil) {
    //    updateTitleView(title: "MessageKit", subtitle: isHidden ? "2 Online" : "Typing...")
    //    setTypingIndicatorViewHidden(isHidden, animated: true, whilePerforming: updates) { [weak self] success in
    //        if success, self?.isLastSectionVisible() == true {
    //            self?.messagesCollectionView.scrollToBottom(animated: true)
    //        }
    //    }
    //}

    
    override func viewWillDisappear(_ animated: Bool) {
//        if let parentvc = self.parent {
//            print("parent is: ", p)
            //if let parentvc = parentvc as? PreviewCircleViewController {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let mapvc = storyBoard.instantiateViewController(withIdentifier: "mapIdentifier") as! MapViewController
        
        mapvc.prevSelected = mapVC?.selectedAnnotation
        mapvc.reinstantiate = true
        
                UIApplication.shared.keyWindow?.rootViewController = mapvc
                UIApplication.shared.keyWindow?.makeKeyAndVisible()
                self.navigationController?.popViewController(animated: false)
                self.dismiss(animated: true, completion: nil)
//            } else if let parentvc = parentvc as? UserViewController {
//                let storyBoard = UIStoryboard(name: "Main", bundle: nil)
//                let uvc = storyBoard.instantiateViewController(withIdentifier: "userIdentifier") as! UserViewController
//                UIApplication.shared.keyWindow?.rootViewController = uvc
//                UIApplication.shared.keyWindow?.makeKeyAndVisible()
//                self.navigationController?.popViewController(animated: false)
//                self.dismiss(animated: false, completion: nil)
//            }
        

        
       
    }
    
    
}

// MARK: - MessagesDisplayDelegate

extension ChatViewController: MessagesDisplayDelegate {
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .darkGray : .lightGray
    }
    
    func shouldDisplayHeader(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> Bool {
        return false
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        //let user = databaseRef.child("users").child(message.sender.displayName)
        //print("configuring avatar for ", message.sender.displayName, " ", user)
        
        databaseRef.child("users").child(message.messageId).observeSingleEvent(of: .value, with: { (snapshot)
            in
            if let dict = snapshot.value as? [String: AnyObject] {
                let profileImageURL = dict["pic"] as? String
                if profileImageURL != nil && profileImageURL != "" {
                    
                    let url = URL(string: profileImageURL!)
                    URLSession.shared.dataTask(with: url!, completionHandler: { (data,
                        response, error) in
                        if error != nil {
                            print(error!)
                            return
                        }
                        DispatchQueue.main.async {
                            let image = UIImage(data: data!)
                            avatarView.set(avatar: Avatar(image: image, initials: "?"))
                        }
                    }).resume()
                }
            }
        })
    }
    
}

// MARK: - MessagesLayoutDelegate

extension ChatViewController: MessagesLayoutDelegate {
    
    
    func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section - 1 >= 0 else { return false }
        return messages[indexPath.section].sender.senderId == messages[indexPath.section - 1].sender.senderId
    }
    
    func isNextMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section + 1 < messages.count else { return false }
        return messages[indexPath.section].sender.senderId == messages[indexPath.section + 1].sender.senderId
    }
    
    func avatarSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return .zero
    }
    
    func footerViewSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return CGSize(width: 0, height: 8)
    }
    
    func heightForLocation(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        
        return 0
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if isFromCurrentSender(message: message) {
            return !isPreviousMessageSameSender(at: indexPath) ? 20 : 0
        } else {
            return !isPreviousMessageSameSender(at: indexPath) ? (20) : 0
        }
    }
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if isTimeLabelVisible(at: indexPath) {
            return 18
        }
        return 0
    }
    
}

// MARK: - MessagesDataSource

extension ChatViewController: MessagesDataSource {
    func currentSender() -> SenderType {
        return Sender(id: user.uid, displayName: user.uid)
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        //print("message count is ", messages.count)
        return messages.count
    }
    
    
    func currentSender() -> Sender {
        return Sender(id: user.uid, displayName: user.displayName! )
    }
    
    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if isTimeLabelVisible(at: indexPath) {
            return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        }
        return nil
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if !isPreviousMessageSameSender(at: indexPath) {
            let name = message.sender.displayName
            return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
        }
        return nil
    }
}

// MARK: - MessageInputBarDelegate

extension ChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        
        var displayName: String = "Username unavailable"
        if let uid = Auth.auth().currentUser?.uid {
            self.databaseRef.child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot)
                in
                if let dict = snapshot.value as? [String: AnyObject] {
                    displayName = dict["username"] as? String ?? "Username unavailable"
                    print("bby pressed send! user is ", displayName)
                    let sender = Sender(id: self.user.uid, displayName: displayName)
                    let message = Message(text: text, user: self.user, sender: sender, messageId: UUID().uuidString, date: Date())
                    
                    self.save(message)
                }
            })
           
        }
        //insertNewMessage(message)
        //let components = inputBar.inputTextView.components
        messageInputBar.inputTextView.text = String()
        messageInputBar.invalidatePlugins()

        // Send button activity animation
        messageInputBar.sendButton.startAnimating()
        messageInputBar.inputTextView.placeholder = "Sending..."
        DispatchQueue.global(qos: .default).async {
            // fake send request task
            sleep(1)
            DispatchQueue.main.async { [weak self] in
                self?.messageInputBar.sendButton.stopAnimating()
                self?.messageInputBar.inputTextView.placeholder = "Aa"
                //self?.insertMessages(components)
                self?.messagesCollectionView.scrollToBottom(animated: true)
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print("dismisses here")
        picker.dismiss(animated: false, completion: nil)
        
        if let asset = info[.phAsset] as? PHAsset { // 1
            let size = CGSize(width: 500, height: 500)
            PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: nil) { result, info in
                guard let image = result else {
                    return
                }
                
                self.sendPhoto(image)
            }
        } else if let image = info[.originalImage] as? UIImage { // 2
            sendPhoto(image)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}

extension UserDefaults {
    static let messagesKey = "Messages"
    
    // MARK: -  Messages
    
    func setMessages(count: Int) {
        set(count, forKey: "Messages")
        synchronize()
    }
    
    func MessagesCount() -> Int {
        if let value = object(forKey: "Messages") as? Int {
            return value
        }
        return 20
    }
    
    static func isFirstLaunch() -> Bool {
        let hasBeenLaunchedBeforeFlag = "hasBeenLaunchedBeforeFlag"
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: hasBeenLaunchedBeforeFlag)
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: hasBeenLaunchedBeforeFlag)
            UserDefaults.standard.synchronize()
        }
        return isFirstLaunch
    }
}

