import Darwin
import UIKit

public class XCNotificationCenter {
    
    public static var shared = XCNotificationCenter()
    
    private var receivers: [String : [Receiver]]
    private var locker: pthread_rwlock_t
    
    public class Receiver {
        var function: ((Any?) -> Void)?
        var notificationName: String
        weak var recordedWeakObject: AnyObject?
        
        public init(receiver function: ((Any?) -> Void)?, recordedWeakObject: AnyObject?, forNotificationNamed name: String) {
            self.function = function
            self.notificationName = name
            self.recordedWeakObject = recordedWeakObject
        }
    }
    
    public init() {
        self.receivers = [String : [Receiver]]()
        self.locker = pthread_rwlock_t()
        pthread_rwlock_init(&self.locker, nil)
    }
    
    public func addObserver(_ weakObj: AnyObject?, forName name: String, executionQueue queue: DispatchQueue = .main, andAction action: ((Any?) -> Void)?) {
        let method = {
            val in
            queue.async {
                action?(val)
            }
        }
        let receiver = Receiver(receiver: method, recordedWeakObject: weakObj, forNotificationNamed: name)
        pthread_rwlock_wrlock(&self.locker)
        if receivers[name] != nil {
            receivers[name]?.append(receiver)
        } else {
            receivers[name] = [receiver]
        }
        pthread_rwlock_unlock(&self.locker)
    }
    
    public func post(notificationNamed name: String, attachedObject object: Any?) {
        var ree = [Receiver]()
        pthread_rwlock_rdlock(&self.locker)
        if var arr = receivers[name] {
            arr.removeAll(where: { $0.recordedWeakObject == nil })
            ree.append(contentsOf: arr)
        }
        for it in ree {
            it.function?(object)
        }
        pthread_rwlock_unlock(&self.locker)
        
    }
    
    deinit {
        pthread_rwlock_destroy(&self.locker)
    }
    
}
