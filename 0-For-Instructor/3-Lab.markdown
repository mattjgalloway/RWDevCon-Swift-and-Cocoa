# 203: Swift & Cocoa, Part 3: Lab Instructions

The RWDevConCalendar app works as it stands, but there's more that we can do with it. Currently nothing happens when you tap on sessions. In this lab, you're going to add that functionality.

You'll add your own view controller to the app as well, to show you how to create one from scratch. This is something you probably did a lot of in Objective-C, so you can learn how to do it in Swift now.

## Adding the View Controller

Click **File\New\File…**. Select **iOS\Source\Cocoa Touch Class** and click **Next**. Call the class **SessionViewController**, make it a subclass of **UIViewController** and select **Swift** as the language. Then click **Next** and finally save it with the project.

Open **SessionViewController.swift** and add the following properties at the top:

```
@IBOutlet private var titleLabel: UILabel!
@IBOutlet private var speakerLabel: UILabel!
@IBOutlet private var descriptionLabel: UILabel!
@IBOutlet private var timeLabel: UILabel!
```

These are how we specify Interface Builder outlets in Swift. They must be optionals, because we don't know what they're going to contain at initialisation time. Remember that view controllers only set up their outlets when the view is loaded. They can either be implicitly unwrapped optionals, or normal optionals. Here we're using implicitly unwrapped optionals to make some code easier as you will see shortly.

Open **Main.storyboard** and add a view controller to the scene. Add four labels and make it look like this:

![](./3-LabImages/01-SessionView.png)

Then set the class of the view controller to `SessionViewController` in the Identity Inspector and finally wire up the four labels you just added to the four outlets you added to the code earlier.

Next, Control-drag from the original view controller to the new one to add a **Show** segue. Then in the Attributes Inspector, make the identifier of the segue `PresentSession`.

## Fleshing Out the View Controller

The view controller to display session information now exists, but it's time to make that view controller actually do something.

Open **SessionViewController.swift** and add the following property to the top of the class:

```
var session: Session?
```

This will hold the session that the view controller is currently displaying. It's an optional because once again, it doesn't know the session until after the view controller has been instantiated. It will be set during the segue from the main view controller.

Next, add the following method to the class:

```
private func updateWithCurrentSession() {
  if !self.isViewLoaded() {
    return
  }

  if let session = self.session {
    self.titleLabel.text = session.title
    self.speakerLabel.text = session.speaker
    self.descriptionLabel.text = session.description

    let startDateFormatter = NSDateFormatter()
    startDateFormatter.dateFormat = "EEEE HH:mm"
    let endDateFormatter = NSDateFormatter()
    endDateFormatter.dateFormat = "HH:mm"
    self.timeLabel.text = "\(startDateFormatter.stringFromDate(session.start)) - \(endDateFormatter.stringFromDate(session.end))"
  }
}
```

This will update the view with the relevant information for the current session. It first checks to see if the view is loaded because if not then the `titleLabel`, `descriptionLabel`, `speakerLabel` and `timeLabel` outlets will not be populated yet. It also uses optional binding to gain access to the `session` property optional.

This method needs to be called in two places. Once when the view loads and whenever the session changes.

To achieve the latter we can hook into the `session` property. Change its definition to the following:

```
var session: Session? = nil {
  didSet {
    self.updateWithCurrentSession()
  }
}
```

This adds code that runs after the property is set. We simply call the `updateWithCurrentSession` method to update the view as necessary.

Now find `viewDidLoad()` and make it look like this:

```
super.viewDidLoad()

self.title = "Session"

self.updateWithCurrentSession()
```

This sets the title before calling the `updateWithCurrentSession` method to populate the labels as necessary.

## Wiring Up the Segue

The view controller is almost finished, but first you need to wire it up to the main view controller.

Open **ViewController.swift** and add the following method to the class:

```
override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
  self.performSegueWithIdentifier(PRESENT_SESSION_SEGUE_IDENTIFIER, sender: indexPath)
}
```

This will cause the `PresentSession` segue to happen when a cell in the collection view is selected. The sender is the index path that was selected. The reason for this choice will become clear shortly.

Add the following method to the class:

```
override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
  if segue.identifier == PRESENT_SESSION_SEGUE_IDENTIFIER {
    let indexPath = sender as NSIndexPath
    let viewController = segue.destinationViewController as SessionViewController
    viewController.session = self.sessions[indexPath.section][indexPath.item]
  }
}
```

This handles preparation of the view controller when the segue happens. Here the sender of the segue is retrieved, which in this case is the index path of the selected collection view item.

The session view controller is set up by giving it the correct session.

Build & run the app. Wahoo! You can now tap on sessions and see details about them!

![](./3-LabImages/02-SessionViewComplete.png)

## Adding Session Sharing

It would be nice if you could share which sessions you're attending with the world, wouldn't it? Well, let's add that functionality!

Open **SessionViewController.swift** and add the following method to the class:

```
private func shareTapped(sender: AnyObject) {
  if let session = self.session {
    let activityViewController = UIActivityViewController(activityItems: ["I'm attending \(session.title) at RWDevCon!"], applicationActivities: nil)
    activityViewController.completionHandler = { (activityType: String!, completed: Bool) in
      self.dismissViewControllerAnimated(true, completion: nil)
    }
    self.presentViewController(activityViewController, animated: true, completion: nil)
  }
}
```

This adds a method which will display a `UIActivityViewController` to allow native sharing of the fact that you're attending a certain session. That part is fairly simple and self explanatory.

Now you need to wire this up to the view controller. The usual way to do this is to use a `UIBarButtonItem` and add it as the right bar button item on the view controller's navigation item.

Find `viewDidLoad()` and add the following line:

```
self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "shareTapped:")
```

You'll recall this method from Objective-C Cocoa Touch development. It gives a target and an action. The action is executed on the target when the button is tapped. The action is a "selector", which is an Objective-C method to call on the target. But this is a Swift class!

This is where Swift has had to merge with Objective-C somewhat and introduces us to a new keyword in Swift - `@objc`. The `@objc` keyword when added to a method allows it to be used from Objective-C. What that means under the hood is it becomes a method which must be treated like an Objective-C method is. The Objective-C runtime must be able to see it in the way that it expects to. This means the Swift compiler cannot do as many optimisations on it that it can with normal Swift methods. But that's just the way it is if we want to use it as a target for a `UIBarButtonItem`.

Find the `shareTapped()` method that you just added, and make it look like this:

```
@objc private func shareTapped(sender: AnyObject)
```

This means that it can now be used as the target for the `UIBarButtonItem`.

Build & run the app. And then share away!

![](./3-LabImages/03-SessionShare.png)

Congratulations, you've finished the app!
