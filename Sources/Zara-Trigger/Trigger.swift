import Foundation
import Common
import NIO
import Zara_Logger

//public typealias TriggerCompletion = ((Trigger) throws -> () )
public typealias TriggerCompletion = ((Trigger) throws -> EventLoopFuture<Void>)?

public class TriggerService {
    var operationQueue = DispatchQueue(label: "service.trigger")
    public let mainLogger : LogService
    
    @discardableResult
    public func add(_ trigger : Trigger) -> DispatchWorkItem {
        
        let timeFromNow = trigger.date.timeIntervalSince(Date())
        //        print(timeFromNow); #warning("Need to work out what to do with DayLight Saving")
        
        let workItem = DispatchWorkItem {
            self.run(trigger)
        }
        operationQueue.asyncAfter(deadline: .now() + timeFromNow, execute: workItem)
        return workItem
    }
    
    func run(_ trigger : Trigger)  {
        do {
            try trigger.complete?(trigger).whenComplete { r in
                if trigger.type != .none {
                    switch r {
                    case .success(_):
                        self.add( (try? trigger.makeNextTrigger()) ?? Trigger())
                    case .failure(let error):
                        self.mainLogger.logMessage("\(#function), \(error.localizedDescription)")
                        let returnTrigger = (try? trigger.makeNextTrigger(lastrun: trigger.lastrun)) ?? Trigger()
                        self.add( returnTrigger)
                    }
                    
                }
            }
        } catch {
            self.mainLogger.logMessage("\(#function), \(error.localizedDescription)")
            if trigger.type != .none {
                let returnTrigger = (try? trigger.makeNextTrigger(lastrun: trigger.lastrun)) ?? Trigger()
                self.add( returnTrigger)
            }
        }
    }
    
    public init(name: String = "TriggerServiceTest") {
        mainLogger = LogService(name: name)
    }
}

public enum TriggerError : Error {
    case cantCreateDate
    
    public var localizedDescription : String {
        return "TriggerError - cantCreateDate"
    }
}

public class Trigger {
    
    static var finishDate : Date? {
        let userCalender = NSCalendar.current
        
        var dateComp2 = userCalender.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        
        var dateComp = DateComponents()
        
        dateComp.calendar = userCalender
        
        dateComp2.hour = 23
        dateComp2.minute = 30
        
        guard let nextRun = userCalender.date(from: dateComp2) else {
            return nil
        }
//        print("Finish Timer : \(nextRun.timeStamp())")
        return nextRun
    }
    
    public var lastrun : Date
    let date : Date
    public let type : timerType
    let complete : TriggerCompletion
    
    let logger : LogService
    
    public init(date : Date, last: Date, type : timerType, complete : TriggerCompletion, logger : LogService = .init(name: "TriggerService3", withStart: false)) {
        self.date = date
        self.type = type
        self.lastrun = last
        self.complete = complete
        self.logger = logger
    }
    

    
    /// MAKE A NEW TIMER
    ///
    /// - Parameters:
    ///     - hour: Hour to start timer in 24 hour
    ///     - min: Minute to start Timer
    ///     - type: Type of Timer
    ///     - last: Last Time the timer was ran (use for Every 30 seconds only)
    /// - Returns: The Trigger for the next avaiable time for hour/min for that timer type
    
    public convenience init(hour: Int, min: Int, type: timerType, lastrun: Date? = nil, complete: TriggerCompletion, logger : LogService) throws {
        
        
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
//                print("THERE IS NO SUNDAY AFTER TODAY, BE WORRIED")
                logger.logMessage("THERE IS NO SUNDAY AFTER TODAY, BE WORRIED")

                throw TriggerError.cantCreateDate
            }
            
            date = nextSunday
            
        case .TodayWeekly:
            
            dateComp.weekday = 4
            dateComp.hour = hour
            dateComp.minute = min
            guard let nextSunday = userCalender.nextDate(after: date, matching: dateComp, matchingPolicy: .nextTime) else {
                logger.logMessage("THERE IS NO SUNDAY AFTER TODAY, BE WORRIED")
                throw TriggerError.cantCreateDate
            }
            
            date = nextSunday
            
        case .everyHalfMinute:
            
            if currentHour < hour { // Checks to see if StartTime has passed, if not makes the Timer for the startTime 5 am
                dateComp.hour = hour
                dateComp.minute = min
                guard let nextRun = userCalender.nextDate(after: date, matching: dateComp, matchingPolicy: .nextTime) else {
                    logger.logMessage("THERE IS NO SUNDAY AFTER TODAY, BE WORRIED")
                    throw TriggerError.cantCreateDate
                }

                date = nextRun
            } else if date >= Trigger.finishDate! { //Checks to see if FinishTime has passed, if so creates new start
                dateComp.hour = hour
                dateComp.minute = min
                guard let nextStart = userCalender.nextDate(after: date, matching: dateComp, matchingPolicy: .nextTime) else {
                    logger.logMessage("THERE IS NO SUNDAY AFTER TODAY, BE WORRIED")
                    throw TriggerError.cantCreateDate
                }
                date = nextStart
            } else { // Just starts at the next XX:XX:30
                if currentSecond > 30 {
                    dateComp.second = 0
                } else {
                    dateComp.second = 30
                }
                
                guard let nextStart = userCalender.nextDate(after: date, matching: dateComp, matchingPolicy: .nextTime) else {
                    logger.logMessage("THERE IS NO SUNDAY AFTER TODAY, BE WORRIED")
                    throw TriggerError.cantCreateDate
                }
                
                date = nextStart
            }
            
        case .EveryMinute:
                
                if currentHour < hour { // Checks to see if StartTime has passed, if not makes the Timer for the startTime 5 am
                    dateComp.hour = hour
                    dateComp.minute = min
                    guard let nextRun = userCalender.nextDate(after: date, matching: dateComp, matchingPolicy: .nextTime) else {
                        logger.logMessage("THERE IS NO SUNDAY AFTER TODAY, BE WORRIED")
                        throw TriggerError.cantCreateDate
                    }

                    date = nextRun
                } else if date >= Trigger.finishDate! { //Checks to see if FinishTime has passed, if so creates new start
                    dateComp.hour = hour
                    dateComp.minute = min
                    guard let nextStart = userCalender.nextDate(after: date, matching: dateComp, matchingPolicy: .nextTime) else {
                        logger.logMessage("THERE IS NO SUNDAY AFTER TODAY, BE WORRIED")
                        throw TriggerError.cantCreateDate
                    }
                    date = nextStart
                } else { // Just starts at the next XX:XX:30
                    dateComp.second = 0
                    
                    guard let nextStart = userCalender.nextDate(after: date, matching: dateComp, matchingPolicy: .nextTime) else {
                        logger.logMessage("THERE IS NO SUNDAY AFTER TODAY, BE WORRIED")
                        throw TriggerError.cantCreateDate
                    }
                    
                    date = nextStart
                }
            
        default:
            dateComp.hour = hour
            dateComp.minute = min
            guard let nextRun = userCalender.nextDate(after: date, matching: dateComp, matchingPolicy: .nextTime) else {
                logger.logMessage("THERE IS NO SUNDAY AFTER TODAY, BE WORRIED")
                throw TriggerError.cantCreateDate
            }
            
            date = nextRun
            
        }
        
        let dateFormatter = Globals.Date.TimeStamp
        let dateString = dateFormatter.string(from: date)
        
        logger.logMessage("\(type) Started Timer :  \(dateString)")
        self.init(date: date, last: lastrun ?? Date(), type: type, complete: complete, logger: logger)
        
    }
    
    func makeNextTrigger(lastrun : Date? = nil) throws -> Trigger {
        
        let dateFormatter = Globals.Date.TimeStamp
        let userCalender = NSCalendar.current
        
        var date = Date()
        var lastRun = lastrun ?? self.date
        
        var dateComp = userCalender.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self.date)
        
        switch self.type {
        case .SundayWeekly:
             var dateComp2 = DateComponents()
            dateComp2.weekday = 1
            dateComp2.hour = dateComp.hour
            dateComp2.minute = dateComp.minute
            guard let nextSunday = userCalender.nextDate(after: date, matching: dateComp2, matchingPolicy: .nextTime) else {
                logger.logMessage("THERE IS NO SUNDAY AFTER TODAY, BE WORRIED")
                 throw TriggerError.cantCreateDate
            }
            date = nextSunday
        case .EveryMinute:
            if date >= Trigger.finishDate! {
                var dateComp2 = DateComponents()
                dateComp2.hour = 0
                dateComp2.minute = 0
                guard let nextStart = userCalender.nextDate(after: date, matching: dateComp2, matchingPolicy: .nextTime) else {
                    logger.logMessage("EveryMinute> nextStart")
                     throw TriggerError.cantCreateDate
                }
                var dateComp3 = DateComponents()
                dateComp3.hour = 5
                dateComp3.minute = 30
                guard let nextStart2 = userCalender.nextDate(after: date, matching: dateComp3, matchingPolicy: .nextTime) else {
                    logger.logMessage("EveryMinute> nextStart")
                     throw TriggerError.cantCreateDate
                }
                date = nextStart2
                lastRun = nextStart
                UserDefaultsAlt.default.set(lastRun.timeStamp(), forKey: "lastrun")
            } else {
                dateComp.second = dateComp.second! + 60
                date = userCalender.date(from: dateComp)!
                UserDefaultsAlt.default.set(lastRun.timeStamp(), forKey: "lastrun")
            }
        case .everyHalfMinute:
            if date >= Trigger.finishDate! {
                var dateComp2 = DateComponents()
                dateComp2.hour = 0
                dateComp2.minute = 0
                guard let nextStart = userCalender.nextDate(after: date, matching: dateComp2, matchingPolicy: .nextTime) else {
                    logger.logMessage("testEveryHalfMinute> nextStart")
                     throw TriggerError.cantCreateDate
                }
                var dateComp3 = DateComponents()
                dateComp3.hour = 5
                dateComp3.minute = 30
                guard let nextStart2 = userCalender.nextDate(after: date, matching: dateComp2, matchingPolicy: .nextTime) else {
                    logger.logMessage("testEveryHalfMinute> nextStart")
                     throw TriggerError.cantCreateDate
                }
                date = nextStart2
                lastRun = nextStart
                UserDefaultsAlt.default.set(lastRun.timeStamp(), forKey: "lastrun")
            } else {
                dateComp.second = dateComp.second! + 30
                date = userCalender.date(from: dateComp)!
                UserDefaultsAlt.default.set(self.lastrun.timeStamp(), forKey: "lastrun")
            }
//            UserDefaultsAlt.default.set(self.lastrun.timeStamp(), forKey: "lastrun")
            
        case .CleaningSchedule, .Daily:
            dateComp.day = dateComp.day! + 1
            date = userCalender.date(from: dateComp)!
        case .none:
            return Trigger();
        case .TodayWeekly:
            var dateComp2 = DateComponents()
            
            dateComp2.weekday = 4
            dateComp2.hour = dateComp.hour
            dateComp2.minute = dateComp.minute
            print(dateComp, dateComp2)
            guard let nextSunday = userCalender.nextDate(after: date, matching: dateComp2, matchingPolicy: .nextTime) else {
                logger.logMessage("THERE IS NO SUNDAY AFTER TODAY, BE WORRIED")
                 throw TriggerError.cantCreateDate
            }
            date = nextSunday
        }
        
        
        
        let dateString = dateFormatter.string(from: self.date)
        let dateString2 = dateFormatter.string(from: date)
        switch self.type {
        case .EveryMinute, .everyHalfMinute:
            logger.logMessage("--\(self.type) Triggered \(dateString) - Next Trigger \(dateString2) - withLastRun: \(lastRun.timeStamp())")
        default:
            logger.logMessage("--\(self.type) Triggered \(dateString) - Next Trigger \(dateString2)")
        }
        
        
        return Trigger(date: date, last: lastRun, type: self.type, complete: self.complete, logger: self.logger)
    }
 
    
    init(logger : LogService = .init(name: "TriggerService4")) {
        lastrun = Date()
        date = Date()
        type = .none
        complete = nil
        self.logger = logger
    }
}
