//
//  MessagesViewController.swift
//  Messenger
//
//  Created by Alexandra Lifa on 8/15/16.
//  Copyright © 2016 Alexandra Lifa. All rights reserved.
//
import UIKit
import JSQMessagesViewController
import Firebase



class MessagesViewController:  JSQMessagesViewController {
    
    var user: FIRAuth?
    var messages = [JSQMessage]()
    var messageRef: FIRDatabaseReference!
    var incomingBubbleImageView: JSQMessagesBubbleImage!
    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var usersTypingQuery: FIRDatabaseQuery!
    let defaults = UserDefaults.standard
    
    @IBOutlet var MessageView: UIView!

    var userIsTypingRef: FIRDatabaseReference! // 1
    fileprivate var localTyping = false
    var isTyping: Bool {
        get {
            return localTyping
        }
        set {
            localTyping = newValue
            userIsTypingRef.setValue(newValue)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.senderId = UIDevice.current.identifierForVendor?.uuidString
        self.senderDisplayName = UIDevice.current.identifierForVendor?.uuidString
        self.inputToolbar.contentView.leftBarButtonItem = nil
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero;
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero;
        
        messageRef = FIRDatabase.database().reference()
        observeMessages()
        setupBubbles()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        collectionView.collectionViewLayout.springinessEnabled = true
        observeTyping()
    }
    
    fileprivate func setupBubbles() {
        let factory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImageView = factory?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleRed())
        incomingBubbleImageView = factory?.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }
    
    
    func addMessage(_ id: String, text: String) {
        let message = JSQMessage(senderId: id, displayName: "", text: text)
        messages.append(message!)
    }
    
    fileprivate func observeMessages() {
        let messagesQuery = messageRef.queryLimited(toLast: 25)
        messagesQuery.observe(.childAdded) { (snapshot: FIRDataSnapshot!) in
            if let value = snapshot.value as? [String:AnyObject], let id = value["senderId"] as? String, let text = value["text"] as? String {
            self.addMessage(id, text: text)
            self.finishReceivingMessage()
        }
    }
        
}
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        // If the text is not empty, the user is typing
        print(textView.text != "")
        isTyping = textView.text != ""
    }
    
    fileprivate func observeTyping() {
        let typingIndicatorRef = FIRDatabase.database().reference().child("typingIndicator")
        userIsTypingRef = typingIndicatorRef.child(senderId)
        userIsTypingRef.onDisconnectRemoveValue()
        
        usersTypingQuery = typingIndicatorRef.queryOrderedByValue().queryEqual(toValue: true)
        
        usersTypingQuery.observe(.value) { (data: FIRDataSnapshot!) in
            
            if data.childrenCount == 1 && self.isTyping {
                return
            }
            
            self.showTypingIndicator = data.childrenCount > 0
            self.scrollToBottom(animated: true)
        }
    }
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        let itemRef = messageRef.childByAutoId()
        let messageItem = [
            "text": text,
            "senderId": senderId
        ]
        itemRef.setValue(messageItem)
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        finishSendingMessage()
        isTyping = false
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        // Leave blank
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        
        let data = self.messages[indexPath.row]
        return data
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didDeleteMessageAt indexPath: IndexPath!) {
        self.messages.remove(at: indexPath.row)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        let data = messages[indexPath.row]
        switch(data.senderId) {
        case self.senderId:
            return self.outgoingBubbleImageView
        default:
            return self.incomingBubbleImageView
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            cell.textView!.textColor = UIColor.white
        } else {
            cell.textView!.textColor = UIColor.white
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath) -> JSQMessageAvatarImageDataSource! {
        
        return nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
