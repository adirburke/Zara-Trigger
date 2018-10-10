import Foundation
import projectConstants


public class TriggerService {
    public var console : Bool = true
    public private(set) var triggers = [Trigger]()
    
    public func add(_ trigger : Trigger) {
        if console {
            triggers.append(trigger)
        } else {
            let timer = Timer(fireAt: trigger.date, interval: 0, target: self, selector: #selector(nonConsoleRun(timer:)), userInfo: ["trigger" : trigger], repeats: false)
            
            RunLoop.main.add(timer, forMode: .commonModes)
        }
    }
    public func delete(_ i : Int) {
        triggers.remove(at: i)
    }
    
    @objc public func nonConsoleRun(timer : Timer) {
        guard let uI = timer.userInfo! as? [String:Any], let trigger = uI["trigger"] as? Trigger else {
            print("Unknown \'type\' in testLoop")
            return
        }
        add(trigger.makeNextTrigger()!)
        trigger.complete?()
    }
    
    public func run(_ trigger : Trigger) -> Trigger? {
        return trigger.makeNextTrigger()
    }
    public func check(_ trigger : Trigger) -> Bool {
        return Date() > trigger.date
    }
    
    
    init() {
        
    }
}

public class Trigger {
    
    static var finishDate : Date? {
        let userCalender = NSCalendar.current
        
        var dateComp2 = userCalender.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        
        var dateComp = DateComponents()
        
        dateComp.calendar = userCalender
        
        dateComp2.hour = 21
        dateComp2.minute = 0
        
        guard let nextRun = userCalender.date(from: dateComp2) else {
            return nil
        }
        print("Finish Timer : \(nextRun.timeStamp())")
        return nextRun
    }
    
    var lastrun : Date
    let date : Date
    let type : timerType
    let complete : (()->())?
    
    init(date : Date, last: Date, type : timerType, complete : (()->())? = nil) {
        self.date = date
        self.type = type
        self.lastrun = last
        self.complete = complete
    }
    
    /// MAKE A NEW TIMER
    ///
    /// - Parameters:
    ///     - hour: Hour to start timer in 24 hour
    ///     - min: Minute to start Timer
    ///     - type: Type of Timer
    ///     - last: Last Time the timer was ran (use for Every 30 seconds only)
    /// - Returns: The Trigger for the next avaiable time for hour/min for that timer type
    
    convenience init?(hour: Int, min: Int, type: timerType, lastrun: Date? = nil, complete: (()->())? = nil) {
        
        
        let userCalender = NSCalendar.current
        var date = Date()
        
        var dateComp = DateComponents()
        dateComp.calendar = userCalender
        
        let currentHour = userCalender.component(.hour, from: Date())
        let currentSecond = userCalender.component(.second, from: Date())
        
        switch type {
        case .SundayWeekly:
            
            dateComp.weekday = 1
            dateComp.hour = hour
            dateComp.minute = min
            guard let nextSunday = userCalender.nextDate(after: date, matching: dateComp, matchingPolicy: .nextTime) else {
                print("THERE IS NO SUNDAY AFTER TODAY, BE WORRIED")
                return nil
            }
            
            date = nextSunday
            
            
        case .everyHalfMinute:
            
            if currentHour < hour { // Checks to see if StartTime has passed, if not makes the Timer for the startTime 5 am
                dateComp.hour = hour
                dateComp.minute = min
                guard let nextRun = userCalender.nextDate(after: date, matching: dateComp, matchingPolicy: .nextTime) else {
                    print("THERE IS NO SUNDAY AFTER TODAY, BE WORRIED")
                    return nil
                }
                
                date = nextRun
            } else if date >= Trigger.finishDate! { //Checks to see if FinishTime has passed, if so creates new start
                dateComp.hour = hour
                dateComp.minute = min
                guard let nextStart = userCalender.nextDate(after: date, matching: dateComp, matchingPolicy: .nextTime) else {
                    print("THERE IS NO SUNDAY AFTER TODAY, BE WORRIED")
                    return nil
                }
                date = nextStart
            } else { // Just starts at the next XX:XX:30
                if currentSecond > 30 {
                    dateComp.second = 0
                } else {
                    dateComp.second = 30
                }
                
                guard let nextStart = userCalender.nextDate(after: date, matching: dateComp, matchingPolicy: .nextTime) else {
                    print("THERE IS NO SUNDAY AFTER TODAY, BE WORRIED")
                    return nil
                }
                
                date = nextStart
            }
            
        default:
            dateComp.hour = hour
            dateComp.minute = min
            guard let nextRun = userCalender.nextDate(after: date, matching: dateComp, matchingPolicy: .nextTime) else {
                print("THERE IS NO SUNDAY AFTER TODAY, BE WORRIED")
                return nil
            }
            
            date = nextRun
            
        }
        
        let dateFormatter = Globals.Date.TimeStamp
        let dateString = dateFormatter.string(from: date)
        
        print("Started Timer :  \(dateString)")
        self.init(date: date, last: lastrun ?? Date(), type: type, complete: complete)
        
    }
    
    func makeNextTrigger(complete: (()->())? = nil) -> Trigger? {
        
        let dateFormatter = Globals.Date.TimeStamp
        let userCalender = NSCalendar.current
        
        var date = Date()
        var lastRun = self.date
        
        var dateComp = userCalender.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self.date)
        
        switch self.type {
        case .SundayWeekly:
            
            dateComp.weekday = 1
            guard let nextSunday = userCalender.nextDate(after: date, matching: dateComp, matchingPolicy: .nextTime) else {
                print("THERE IS NO SUNDAY AFTER TODAY, BE WORRIED")
                return nil
            }
            date = nextSunday
            
        case .everyHalfMinute:
            if date >= Trigger.finishDate! {
                var dateComp2 = DateComponents()
                dateComp2.hour = 5
                dateComp2.minute = 30
                guard let nextStart = userCalender.nextDate(after: date, matching: dateComp2, matchingPolicy: .nextTime) else {
                    print("testEveryHalfMinute> nextStart")
                    return nil
                }
                date = nextStart
                lastRun = nextStart
            } else {
                dateComp.second = dateComp.second! + 30
                date = userCalender.date(from: dateComp)!
            }
            UserDefaults.standard.set(self.lastrun.timeStamp(), forKey: "lastrun")
        default:
            dateComp.day = dateComp.day! + 1
            date = userCalender.date(from: dateComp)!
        }
        
        
        
        let dateString = dateFormatter.string(from: self.date)
        let dateString2 = dateFormatter.string(from: date)
        print("Triggered \(dateString) - Next Trigger \(dateString2)")
        return Trigger(date: date, last: lastRun, type: self.type, complete: self.complete)
    }
    
}
