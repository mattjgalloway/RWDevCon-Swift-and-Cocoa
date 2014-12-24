# 203: Swift & Cocoa, Part 2: Demo Instructions

In this demo, you will make the basic RWDevCon Schedule app. The steps here will be explained in the demo, but here are the raw steps in case you miss a step or get stuck.

## Introduction

Open `RWDevConCalendar.xcworkspace` and take a look around the app. Build & run. The app doesn't do anything yet, but we'll add the schedule in this demo.

## Using the Objective-C collection view layout

We want to reuse some code found on GitHub, using Cocoa Pods. It's written in Objective-C and hasn't been ported yet. But never fear - this can be achieved using **brigding**.

Click **File\New\File…**. Select **iOS\Source\Header File** and click **Next**. Call the file **RWDevConCalendar-Bridging-Header.h** and save it with the project.

Open **RWDevConCalendar-Bridging-Header.h** and make it look like this:

```
#import "MSCollectionViewCalendarLayout.h"
#import "NSDate+CupertinoYankee.h"
```

Select the project in the project navigator, then select **Build Settings**. Search for **Bridg** and select **Objective-C Bridging Header**. Double click on the setting under the column **RWDevConCalendar** and enter:

```
${PRODUCT_NAME}/${PRODUCT_NAME}-Bridging-Header.h
```

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
let url = NSData(contentsOfFile: path!)
let json = JSON(data: url!)
```

This obtains the path to the `sessions.json` file. The return type of `pathForResource` is `NSString?` so we need to unwrap it when using it with the `NSData` initialiser. That initialiser returns as `NSData?`, so we unwrap it when creating the `JSON` object.

See `SwiftyJSON.swift` for more about `JSON`. This is a very handy way to handle JSON in Swift due to the strong typing in Swift, which makes it hard to use techniques we used in Objective-C.

Add the following:

```
var data = [NSDate:[Session]]()

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

## Displaying data

Open **ViewController.swift** and add the following at the top of the file, outside the implementation of the class:

```
extension SessionCell {

  func setupWithSession(session: Session) {
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

This is an extension on the `SessionCell` to enable us to set it up with a given `Session` instance.

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
