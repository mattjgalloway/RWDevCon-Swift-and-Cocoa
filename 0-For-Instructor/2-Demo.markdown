# 203: Swift & Cocoa, Part 2: Demo Instructions

In this demo, you will make the basic RWDevCon Schedule app. The steps here will be explained in the demo, but here are the raw steps in case you miss a step or get stuck.

## Introduction

Open `RWDevConCalendar.xcworkspace` and take a look around the app. Build & run. The app doesn't do anything yet, but we'll add the schedule in this demo.

## Using the Objective-C collection view layout

We want to reuse some code found on GitHub, using Cocoa Pods. It's written in Objective-C and hasn't been ported yet. But never fear - this can be achieved using **brigding**.

Click **File\New\File…**. Select **iOS\Source\Header File** and click **Next**. Call the file **RWDevConCalendar-Bridging-Header.h** and save it with the project.

The name of this file doesn't matter. Here we're using the same name as Xcode uses when it creates it itself when using a template, but we could use any name we like.

This file is where we pull in Objective-C classes that we want to expose in Swift. Anything we import in this header, will be accessible from Swift. This is the Objective-C to Swift bridging header.

Open **RWDevConCalendar-Bridging-Header.h** and make it look like this:

```
#import "MSCollectionViewCalendarLayout.h"
#import "NSDate+CupertinoYankee.h"
```

Select the project in the project navigator, then select **Build Settings**. Search for **Bridg** and select **Objective-C Bridging Header**. Double click on the setting under the column **RWDevConCalendar** and enter:

```
${PRODUCT_NAME}/${PRODUCT_NAME}-Bridging-Header.h
```

The other bridging setting in here is **Install Objective-C Compatibility Header**. When this is turned on, the Swift compiler creates a file called **${PRODUCT_NAME}-Swift.h**.

Build the app by pressing **Cmd-B**. Then go to the **Report navigator** (final tab in the left pane) and select the last **Build** log. Search down for **Copy RWDevConCalendar-Swift.h** and open that log entry. Copy the location shown after `Ditto` and on the first line. Then press **Cmd-O** and paste the location, then press **Enter**.

Take a look at this file. Notice all the Swift classes which have Objective-C interfaces for them. This is the way we can use Swift classes from Objective-C. We won't do it in this project, but all you would need to do is import this header in your Objective-C class and then you have access to every compatible Swift class. Not everything from Swift is compatible, for example Swift structs and enums are not.

Back to out app, now we can use in Swift, the Objective-C classes which we imported in the bridging header.

Open **ViewController.swift** and enter the following at the end of `viewDidLoad()`:

```
let layout = self.collectionView?.collectionViewLayout as MSCollectionViewCalendarLayout
layout.sectionLayoutType = .HorizontalTile
layout.headerLayoutType = .TimeRowAboveDayColumn
layout.timeRowHeaderWidth = 46
layout.sectionWidth = 402
```

Now you can use the `MSCollectionViewCalendarLayout` class, which is written in Objective-C, but from Swift!

## Parsing the data

Take a look at `ssessions.json`. This contains the data for the sessions that we'll use to populate the calendar.

Open **ViewController.swift** and find `loadData()`. Add the following:

```
let path = NSBundle.mainBundle().pathForResource("sessions", ofType: "json")
let jsonData = NSData(contentsOfFile: path!)
```

This obtains the path to the `sessions.json` file. The return type of `pathForResource` is `NSString?` so we need to unwrap it when using it with the `NSData` initialiser.

Open **sessions.json** and take a look at the structure.

When you parse JSON you as the developer are the only person who knows what the structure of the JSON looks like. This means which keys the objects will have and what the types are.

In Objective-C, parsing JSON was quite simple. You don't have to check types because fetching values from arrays and dictionaries gives you `id` types, which can be cast appropriately. But that was actually quite dangerous. What if the value was considered as a number but actually it was a string? This could mean you end up calling methods on it which are not valid. You would get a runtime crash.

In Swift, the type safety of the compiler makes parsing JSON relatively long-winded. JSON objects are represented as `[String:AnyObject]` dictionaries. Since accessing dictionaries returns optionals, because the value may not exist for that key, you end up with very nested code, especially if the values you are accessing are a few levels deep in the JSON.

SwiftyJSON is a library which allows you to access JSON much more easily and cleanly in Swift. The heart of the library is a struct called `JSON`. It parses the structure as you access it, and provides methods to access elements of the JSON.

Every object in the JSON is represented with a value of type `JSON`. Accessing JSON arrays and JSON objects with SwiftyJSON gives you values of type `JSON` as well.

When you access values of an object, if you think that a certain value is a string, you can call `stringValue` on it. This will return a non-optional `String` object. If the value is not actually a string, then empty string is returned. So it is safe.

Let's use that in our code then. Open **ViewController.swift** and add the following underneath the code you just added in `viewDidLoad()`:

```
let json = JSON(data: jsonData!)
```

This parses the sessions JSON data into the SwiftyJSON structure. Now we need to parse it.

Add the following:

```
var data = [NSDate:[Session]]()
```

This is going to hold the sessions, keyed by the day they're on. So there'll be one array for each day of the conference, holding the sessions for that day.

Now add the following:

```
for (key, value) in json {
  let session = createSessionFromJSON(value)
  let day = session.start.beginningOfDay()

  var dayArray = data[day]
  if dayArray == nil {
    dayArray = []
  }
  dayArray!.append(session)
  data[day] = dayArray
}

var days = data.keys.array
days.sort {
  lhs, rhs in
  return lhs.compare(rhs) == NSComparisonResult.OrderedAscending
}

var sessions = [[Session]]()
for day in days {
  sessions.append(data[day]!)
}

self.days = days
self.sessions = sessions
```

This parses all the sessions into the relevant data structures.

**Cmd-click** on `createSessionFromJSON`. This function is where the JSON parsing happens. We use `stringValue` and `doubleValue` of SwiftyJSON to access the values. I will leave it as an exercise to write the same code without SwiftyJSON.

## Building the collection view

Open **ViewController.swift** and add the following to the bottom of `viewDidLoad()`:

```
layout.delegate = self

self.collectionView?.registerClass(SessionCell.self, forCellWithReuseIdentifier: "Cell")
self.collectionView?.registerClass(DayColumnHeader.self, forSupplementaryViewOfKind: MSCollectionElementKindDayColumnHeader, withReuseIdentifier: DAY_COLUMN_IDENTIFIER)
self.collectionView?.registerClass(TimeRowHeader.self, forSupplementaryViewOfKind: MSCollectionElementKindTimeRowHeader, withReuseIdentifier: TIME_ROW_IDENTIFIER)

// These are optional. If you don't want any of the decoration views, just don't register a class for them.
layout.registerClass(CurrentTimeGridline.self, forDecorationViewOfKind: MSCollectionElementKindCurrentTimeHorizontalGridline)
layout.registerClass(Gridline.self, forDecorationViewOfKind: MSCollectionElementKindHorizontalGridline)
layout.registerClass(Gridline.self, forDecorationViewOfKind: MSCollectionElementKindVerticalGridline)
layout.registerClass(TimeRowHeaderBackground.self, forDecorationViewOfKind: MSCollectionElementKindTimeRowHeaderBackground)
layout.registerClass(DayColumnHeaderBackground.self, forDecorationViewOfKind: MSCollectionElementKindDayColumnHeaderBackground)
```

This sets up the view controller to be the delegate of the collection view layout and also registers the various collection view cells with the collection view.

Add the following to the bottom of the file:

```
extension ViewController: MSCollectionViewDelegateCalendarLayout {

  func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: MSCollectionViewCalendarLayout!, dayForSection section: Int) -> NSDate! {
    return self.days[section]
  }

  func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: MSCollectionViewCalendarLayout!, startTimeForItemAtIndexPath indexPath: NSIndexPath!) -> NSDate! {
    let session = self.sessions[indexPath.section][indexPath.item]
    return session.start
  }

  func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: MSCollectionViewCalendarLayout!, endTimeForItemAtIndexPath indexPath: NSIndexPath!) -> NSDate! {
    let session = self.sessions[indexPath.section][indexPath.item]
    return session.end
  }

  func currentTimeComponentsForCollectionView(collectionView: UICollectionView!, layout collectionViewLayout: MSCollectionViewCalendarLayout!) -> NSDate! {
    return NSDate()
  }
  
}
```

This is the recommended way to organise implementing protocols in Swift. Add them as an extension on the class, one for each protocol. Here we give the collection view layout the various things it needs.

These methods are required by the collection view layout to allow it to know where to put each session cell.

Notice that the return value of these methods is implicitly unwrapped optional. Also notice that each parameter is an implicitly unwrapped optional. This is an important thing to notice when it comes to bridging Objective-C to Swift. There is no concept of optionals in Objective-C, but an object variably can always be nil. So the type in Swift must be an optional. It's an implicitly unwrapped optional to make life easier by default, but it's important to realise this. If one of these values was nil when coming from Objective-C, and you tried to use it without checking for nil, then it would crash at runtime.

## Displaying data

Open **ViewController.swift** and add the following at the top of the file, outside the implementation of the class:

```
extension SessionCell {

  private func setupWithSession(session: Session) {
    switch session.track {
    case .Generic:
      self.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
    case .Beginner:
      self.backgroundColor = UIColor(red: 0.8, green: 1.0, blue: 0.8, alpha: 1.0)
    case .Intermediate:
      self.backgroundColor = UIColor(red: 1.0, green: 0.9, blue: 0.8, alpha: 1.0)
    case .Advanced:
      self.backgroundColor = UIColor(red: 1.0, green: 0.8, blue: 0.8, alpha: 1.0)
    }

    self.titleLabel.text = session.title
    self.speakerLabel.text = session.speaker

    self.setNeedsLayout()
  }

}
```

This is an extension on the `SessionCell` to enable us to set it up with a given `Session` instance. This is quite a neat way of using Swift extensions to ensure that the cell class doesn't have a dependency on the model. This is a pattern which is quite well talked about in the iOS community. Here we make a dependency on the model for the cell, but only usable within the view controller class. We get to split up the code into logical units, but don't end up with the cell having an exposed dependency on the model.

Find `collectionView(cellForItemAtIndexPath:)` and add the following in the middle of the existing two lines:

```
let session = self.sessions[indexPath.section][indexPath.item]
cell.setupWithSession(session)
```

This sets up the cell with the session for the relevant index path.

Add the following method to the `ViewController` class:

```
override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
  switch kind {
  case MSCollectionElementKindDayColumnHeader:
    let dayColumnHeader = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: DAY_COLUMN_IDENTIFIER, forIndexPath: indexPath) as DayColumnHeader
    let day = (self.collectionView?.collectionViewLayout as MSCollectionViewCalendarLayout).dateForDayColumnHeaderAtIndexPath(indexPath)
    dayColumnHeader.titleLabel.text = self.dayColumnDateFormatter.stringFromDate(day)
    dayColumnHeader.setNeedsLayout()
    return dayColumnHeader
  case MSCollectionElementKindTimeRowHeader:
    let timeRowHeader = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: TIME_ROW_IDENTIFIER, forIndexPath: indexPath) as TimeRowHeader
    let time = (self.collectionView?.collectionViewLayout as MSCollectionViewCalendarLayout).dateForTimeRowHeaderAtIndexPath(indexPath)
    timeRowHeader.titleLabel.text = self.timeRowDateFormatter.stringFromDate(time)
    timeRowHeader.setNeedsLayout()
    return timeRowHeader
  default:
    fatalError("Unhandled supplementary kind")
  }
}
```

This returns the relevant views for the supplementary items in the collection view.

## Build & Run

Build & run and you'll see something like this:

![](./2-DemoImages/01-RWDevConCalendar.png)
