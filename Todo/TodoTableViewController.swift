//
//  TodoTableViewController.swift
//  Todo
//
//  Created by Brian Advent on 08.12.17.
//  Copyright © 2017 Brian Advent. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class TodoTableViewController: UITableViewController, TodoCellDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate {


    var todoItems:[TodoItem]!
    
    
    var peerID:MCPeerID!
    var mcSession:MCSession!
    var mcAdvertiserAssistant:MCAdvertiserAssistant!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        loadData()
        
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        
    }
    
    func loadData(){
        todoItems = [TodoItem]()
        todoItems = DataManager.loadAll(TodoItem.self).sorted(by: {$0.createdAt < $1.createdAt})
        self.tableView.reloadData()
    }
    
    
    
    @IBAction func addTodo(_ sender: Any) {
        let addAlert = UIAlertController(title: "New Todo", message: "Enter a title", preferredStyle: .alert)
        addAlert.addTextField { (textfield:UITextField) in
            textfield.placeholder = "ToDo Item Title"
        }
        
        addAlert.addAction(UIAlertAction(title: "Create", style: .default, handler: { (action:UIAlertAction) in
            guard let title = addAlert.textFields?.first?.text else {return}
            let newTodo = TodoItem(title: title, completed: false, createdAt: Date(), itemIdentifier: UUID())
            newTodo.saveItem()
            self.todoItems.append(newTodo)
            
            let indexPath = IndexPath(row: self.tableView.numberOfRows(inSection: 0), section: 0)
            
            self.tableView.insertRows(at: [indexPath], with: .automatic)
        }))
        
        addAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(addAlert, animated: true, completion: nil)
        
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
       
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       
        return todoItems.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TodoTableViewCell

        let todoItem = todoItems[indexPath.row]
        cell.todoLabel.text = todoItem.title
        cell.delegte = self
        
        if todoItem.completed {
            cell.todoLabel.attributedText = strikeThroughText(todoItem.title)
        }

        return cell
    }
    
    func didRequestDelete(_ cell: TodoTableViewCell) {
        
        if let indexPath = tableView.indexPath(for: cell) {
            todoItems[indexPath.row].deleteItem()
            todoItems.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
        }
    }
    
    func didRequestComplete(_ cell: TodoTableViewCell) {
        
        if let indexPath = tableView.indexPath(for: cell) {
            var todoItem = todoItems[indexPath.row]
            todoItem.markAsCompleted()
            cell.todoLabel.attributedText = strikeThroughText(todoItem.title)
        }
    }
    
    func didRequestShare(_ cell: TodoTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let todoItem = todoItems[indexPath.row]
            sendTodo(todoItem)
        }
    }
    
    func sendTodo (_ todoItem:TodoItem) {
        if mcSession.connectedPeers.count > 0 {
            if let todoData = DataManager.loadData(todoItem.itemIdentifier.uuidString) {
                do {
                    try mcSession.send(todoData, toPeers: mcSession.connectedPeers, with: .reliable)
                }catch{
                    fatalError("Could not send todo item")
                }
            }
        }else{
            print("you are not connected to another device")
        }
    }
    

    func strikeThroughText (_ text:String) -> NSAttributedString {
        let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: text)
        attributeString.addAttribute(NSAttributedStringKey.strikethroughStyle, value: 1, range: NSMakeRange(0, attributeString.length))
        
        return attributeString
    }
    
   
    // MARK: - Multipeer Connectivity
    
    
    @IBAction func showConnectivityActions(_ sender: Any) {
        let actionSheet = UIAlertController(title: "ToDo Exchange", message: "Do you want to Host or Join a session?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Host Session", style: .default, handler: { (action:UIAlertAction) in
            
            self.mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "ba-td", discoveryInfo: nil, session: self.mcSession)
            self.mcAdvertiserAssistant.start()
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Join Session", style: .default, handler: { (action:UIAlertAction) in
            let mcBrowser = MCBrowserViewController(serviceType: "ba-td", session: self.mcSession)
            mcBrowser.delegate = self
            self.present(mcBrowser, animated: true, completion: nil)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        /// just to make it work for iPads too
        actionSheet.popoverPresentationController?.sourceView = view

        self.present(actionSheet, animated: true, completion: nil)
        
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
            
        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")
            
        case MCSessionState.notConnected:
            print("Not Connected: \(peerID.displayName)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        do {
            let todoItem = try JSONDecoder().decode(TodoItem.self, from: data)
            
            DataManager.save(todoItem, with: todoItem.itemIdentifier.uuidString)
            
            DispatchQueue.main.async {
                self.todoItems.append(todoItem)
                
                let indexPath = IndexPath(row: self.tableView.numberOfRows(inSection: 0), section: 0)
                
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            }
            
        }catch{
            fatalError("Unable to process recieved data")
        }
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
    
   
}
