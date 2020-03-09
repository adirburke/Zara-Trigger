import Foundation
import projectConstants

import Zara_Logger

public typealias TriggerCompletion = ((Trigger) throws ->())


public class TriggerService {
    var operationQueue = DispatchQueue(label: "service.trigger")
    let mainLogger : Zara_Logger.LogService

    @discardableResult
    public func add(_ trigger : Trigger) -> DispatchWorkItem {
        
        let timeFromNow = trigger.date.timeIntervalSince(Date())
//        print(timeFromNow); #warning("Need to work out what to do with DayLight Saving")
        
        let workItem = DispatchWorkItem {
            let newTrigger = try! self.run(trigger)
            if trigger.type != .none {
                self.add(newTrigger)
            }
        }
        operationQueue.asyncAfter(deadline: .now() + timeFromNow, execute: workItem)
        return workItem
    }
    
    func run(_ trigger : Trigger) throws -> Trigger {
        try trigger.complete(trigger)
        
        return try trigger.makeNextTrigger()
    }
    public init(name: String = "TriggerService") {
        mainLogger = LogService(name: name)
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
//        print("Finish Timer : \(nextRun.timeStamp())")
        return nextRun
    }
    
    public var lastrun : Date
    let date : Date
    public let type : timerType
    let complete : TriggerCompletion
    
    let logger : LogService
    
    public init(date : Date, last: Date, type : timerType, complete : @escaping TriggerCompletion, logger : LogService = .init(name: "TriggerService")) {
        self.date = date
        self.type = type
        self.lastrun = last
        self.complete = complete
        self.logger = logger
    }
    
    enum TriggerError : Error {
        case cantCreateDate
    }
    
    /// MAKE A NEW TIMER
    ///
    /// - Parameters:
    ///     - hour: Hour to start timer in 24 hour
    ///     - min: Minute to start Timer
    ///     - type: Type of Timer
    ///     - last: Last Time the timer was ran (use for Every 30 seconds only)
    /// - Returns: The Trigger for the next avaiable time for hour/min for that timer type
    
    public convenience init(hour: Int, min: Int, type: timerType, lastrun: Date? = nil, complete: @escaping TriggerCompletion, logger : LogService = .init(name: "TriggerService")) throws {
        
        
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
        
        logger.logMessage("Started Timer :  \(dateString)")
        self.init(date: date, last: lastrun ?? Date(), type: type, complete: complete, logger: logger)
        
    }
    
    func makeNextTrigger() throws -> Trigger {
        
        let dateFormatter = Globals.Date.TimeStamp
        let userCalender = NSCalendar.current
        
        var date = Date()
        var lastRun = self.date
        
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
            
        case .everyHalfMinute:
            if date >= Trigger.finishDate! {
                var dateComp2 = DateComponents()
                dateComp2.hour = 0
                dateComp2.minute = 0
                guard let nextStart = userCalender.nextDate(after: date, matching: dateComp2, matchingPolicy: .nextTime) else {
                    logger.logMessage("testEveryHalfMinute> nextStart")
                     throw TriggerError.cantCreateDate
                }
                date = nextStart
                lastRun = nextStart
                UserDefaultsAlt.default.set(date.timeStamp(), forKey: "lastrun")
            } else {
                dateComp.second = dateComp.second! + 30
                date = userCalender.date(from: dateComp)!
                UserDefaultsAlt.default.set(self.lastrun.timeStamp(), forKey: "lastrun")
            }
//            UserDefaultsAlt.default.set(self.lastrun.timeStamp(), forKey: "lastrun")
            
        case .CleaningSchedule, .Daily:
            dateComp.day = dateComp.day! + 1
            date = userCalender.date(from: dateComp)!
        case .none: return Trigger();
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
        logger.logMessage("Triggered \(dateString) - Next Trigger \(dateString2)")
        return Trigger(date: date, last: lastRun, type: self.type, complete: self.complete)
    }
 
    
    init(logger : LogService = .init(name: "TriggerService")) {
        lastrun = Date()
        date = Date()
        type = .none
        complete = { _ in return}
        self.logger = logger
    }
}
