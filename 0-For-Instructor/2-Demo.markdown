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
```

Select the project in the project navigator, then select **Build Settings**. Search for **Bridg** and select **Objective-C Bridging Header**. Double click on the setting under the column **RWDevConCalendar** and enter:

```
${PRODUCT_NAME}/${PRODUCT_NAME}-Bridging-Header.h
```

The other bridging setting in here is **Install Objective-C Compatibility Header**. When this is turned on, the Swift compiler creates a file called **${PRODUCT_NAME}-Swift.h**.

Build the app by pressing **Cmd-B**. Then go to the **Report navigator** (final tab in the left pane) and select the last **Build** log. Search down for **Copy RWDevConCalendar-Swift.h** and open that log entry. Copy the location shown after `Ditto` and on the first line. Then press **Cmd-O** and paste the location, then press **Enter**.

Take a look at this file. Notice all the Swift classes which have Objective-C interfaces for them. This is the way we can use Swift classes from Objective-C. We won't do it in this project, but all you would need to do is import this header in your Objective-C class and then you have access to every compatible Swift class. Not everything from Swift is compatible, for example Swift structs and enums are not.

Back to out app, now we can use in Swift, the Objective-C classes which we imported in the bridging header.

Open **ViewController.swift** and find the section of commented lines at the bottom of `viewDidLoad()`:

Add the following above it:

```
let layout = MSCollectionViewCalendarLayout()
self.collectionView?.collectionViewLayout = layout
layout.delegate = self
layout.sectionLayoutType = .HorizontalTile
layout.headerLayoutType = .TimeRowAboveDayColumn
layout.timeRowHeaderWidth = 46
layout.sectionWidth = 402
```

You're using the `MSCollectionViewCalendarLayout` class, which is written in Objective-C, but from Swift! We set up various properties of the class and set ourselves as the delegate of it.

Now uncomment the lines you find just below the lines you added. These register the various classes for decoration and supplementary views in the collection view.

Also, at the bottom of the class, find the commented method called `collectionView(viewForSupplementaryElementOfKind:atIndexPath:)` and uncomment it. This method returns the supplementary views as requested by the collection view.

## Building the collection view

We've declared ourselves as the delegate of the layout, but haven't actually implemented the delegate yet.

Add the following to the bottom of the file, outside the class:

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

The collection view is ready to go, except for the fact that there is no cell to display the data yet. Now we're going to build that class from scratch.

Click **File\New\File…**. Select **iOS\Source\Cocoa Touch Class** and click **Next**. Call the class **SessionCell** and make it a subclass of **UICollectionViewCell**. Make sure the language is set to **Swift**. Click **Next** and save it with the project.

We're now going to build this class. It needs to display the session title and the speaker's name. To do that, we'll use a couple of `UILabel`s. Add the following properties to the class:

```
let titleLabel: UILabel
let speakerLabel: UILabel
```

Notice that now we've added these properties, the compiler is complaining that there are no initialisers for our class. This is because the properties are declared as non-optionals but we have not specified a value for them. The class needs an initialiser so that the values for the properties can be set, because they must not be nil.

Add the following method:

```
override init(frame: CGRect) {
}
```

This is the designated initialiser for a `UIView`, and none of `SessionCell`'s ancestors declare another designated initialiser, so this is the one we need to override at the very least.

Add the following to the initialiser:

```
let titleLabel = UILabel(frame: CGRectZero)
titleLabel.font = UIFont.boldSystemFontOfSize(12)
titleLabel.numberOfLines = 0
self.titleLabel = titleLabel
```

This sets up a `UILabel`. It looks very similar to how you would have done it in Objective-C. Remember - the core competency of iOS programming really is Cocoa Touch - Swift is just a new syntax!

Next, add the following code:

```
let speakerLabel = UILabel(frame: CGRectZero)
speakerLabel.font = UIFont.systemFontOfSize(12)
speakerLabel.numberOfLines = 0
self.speakerLabel = speakerLabel
```

This sets up our second and final label. So we now have both labels set up. You may notice though that we haven't called `super`'s initialiser yet. In Objective-C we called `super`'s initialiser first and then set ourselves up. In Swift, we must set ourselves up and *then* call `super`.

Add the following:

```
super.init(frame: frame)
```

There, we've now fully initialised the class. It's not until we've done this, that we can call anything that is defined in the superclass or any other ancestors. That's why we haven't added the labels as subviews yet, because the cell itself is not initialised, so the `contentView` (where we need to add the labels) is not ready yet.

Add the following code:

```
self.layer.borderColor = UIColor.blackColor().CGColor
self.layer.borderWidth = 1.0

self.contentView.addSubview(titleLabel)
self.contentView.addSubview(speakerLabel)
```

This finalises the initialiser. We give the cell a border, and add the labels to the content view.

Notice there is still an error. It tells us that `init(coder:)` is a required initialiser. The reason for this is that `init(coder:)` is another designated initialiser which comes from the `NSCoding` protocol which all `UIView`s must adhere to, hence the required. Since we overrode one initialiser, Swift forces us to override all of them. It assumes that if you have extra work to do in one, you must in the other.

Add the following code:

```
required init(coder aDecoder: NSCoder) {
  fatalError("init(coder:) has not been implemented")
}
```

In our case, we're going to somewhat ignore `NSCoding`. We don't actually need it in our app, since our cells will be created programatically, so there won't be a need to use `NSCoding`. That's for when views are created in Interface Builder. This implementation silences the compiler, because we've overridden the initialiser, but we just crash if this is ever called (which it won't).

That's the cell initialised. But now we need to add the code which will lay it out. This should be familiar to you. It's exactly the same as in Objective-C - just override `layoutSubviews`.

Add the following method to the class:

```
override func layoutSubviews() {
  super.layoutSubviews()
}
```

Just like in Objective-C, we need to call `super` first, so that it gets a chance to layout anything it needs to.

Add the following to the end of the method:

```
let bounds = self.contentView.bounds
let padding: CGFloat = 5.0
let paddedWidth = CGRectGetWidth(bounds) - (2.0 * padding)

let titleLabelSize = self.titleLabel.sizeThatFits(CGSizeMake(paddedWidth, CGFloat.max))
```

This sets up some constants that we will need during the layout.

Now add the following code:

```
if self.speakerLabel.text != nil && countElements(self.speakerLabel.text!) > 0 {
  self.titleLabel.frame = CGRect(origin: CGPoint(x: padding, y: padding), size: titleLabelSize)

  let speakerLabelSize = self.speakerLabel.sizeThatFits(CGSizeMake(paddedWidth, CGFloat.max))
  self.speakerLabel.frame = CGRect(origin: CGPoint(x: padding, y: CGRectGetMaxY(bounds) - padding - speakerLabelSize.height), size: speakerLabelSize)
} else {
  self.titleLabel.bounds = CGRect(origin: CGPointZero, size: titleLabelSize)
  self.titleLabel.center = CGPoint(x: CGRectGetMidX(bounds), y: CGRectGetMidY(bounds))
}
```

Here we lay out the cell depending on whether or not the speaker has any text or not. For those that don't have a speaker, we centre the text in the cell. These are the generic sessions like registration and the party.

That's the cell all done!

Now we need to register the cell class in the collection view. Open **ViewController.swift** and add the following in `viewDidLoad()`, above the other registering of classes.

```
self.collectionView?.registerClass(SessionCell.self, forCellWithReuseIdentifier: CELL_IDENTIFIER)
```

That's the cell registered, but now we need to set the cells up as we're returning them.

Open **ViewController.swift** and add the following methods after `loadData()`:

```
override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
  return self.days.count;
}

override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
  return self.sessions[section].count
}

override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
  let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CELL_IDENTIFIER, forIndexPath: indexPath) as SessionCell
  let session = self.sessions[indexPath.section][indexPath.item]
  cell.setupWithSession(session)
  return cell
}
```

Here we return the number of sections and items in the collection view. In the cell method, we then grab the session for the relevant index path and call a method to set up the cell with that session. But we haven't yet implemented that setup method. Let's do that now.

an often talked about topic in Objective-C was should cells have a dependency on their model. I take the view that they shouldn't. Some people would add a category on the cell to set it up with the model object. This worked well, but it still technically leaks a dependency of the cell to the model.

In Swift, we can make use of access modifiers and extensions to achieve the same split but while not leaking the dependency. We can create an extension on the cell, but inside the view controller class, and use a private method in the extension. This method will only be accessible to the view controller. But we've still split concerns into logic sections of code with the extension.

Add the following at the top of the file, outside the implementation of the class:

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

Finally, lets make something happen when you tap on the cells. Add the following method at the end of the class:

```
override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
  let session = self.sessions[indexPath.section][indexPath.item]
  let alert = UIAlertController(title: "Session tapped", message: "You tapped session:\n\(session.title)", preferredStyle: .Alert)
  alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
  self.presentViewController(alert, animated: true, completion: nil)
}
```

This creates an alert controller and presents it. Notice how creating an alert is very similar to what you're used to from Objective-C. It looks almost the same - because it is!

## Turning on the data

There's one last bit of work to do before the view controller will display anything. Currently the data isn't being loaded. Open **ViewController.swift** and find `viewDidLoad()`. Uncomment the line which reads:

```
self.loadData()
```

This will now pull in the data from the sessions JSON file that I added to the project for you.

And that's it!

## Build & Run

Build & run and you'll see something like this:

![](./2-DemoImages/01-RWDevConCalendar.png)
