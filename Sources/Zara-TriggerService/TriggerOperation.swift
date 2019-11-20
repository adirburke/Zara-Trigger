//
//  TriggerOperation.swift
//  Zara-Trigger
//
//  Created by WorkDesk on 20/11/19.
//

import Foundation


protocol Canceller {
    var _shouldCancel : Bool { get set}
    func setShouldCancel(shouldCancel : Bool)
    func shouldCancel() -> Bool
}

extension Canceller {
    mutating func setShouldCancel(shouldCancel : Bool) {
        _shouldCancel = shouldCancel
    }
    func shouldCancel() -> Bool {
        return _shouldCancel
    }
}


func test(a : Int) {
    var canceller : Canceller? = nil
    
    var q = OS_dispatch_queue_global(label: "service.trigger")
    
    
    
}

public class TriggerServiceOperation {
    
lazy var triggerList: [Int: Operation] = [:]
lazy var triggerQueue: OperationQueue = {
  var queue = OperationQueue()
  queue.name = "trigger Queue"
  queue.maxConcurrentOperationCount = 4
  return queue
}()
 
    
    
    
}
