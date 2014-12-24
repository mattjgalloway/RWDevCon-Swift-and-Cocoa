# 203: Swift & Cocoa, Part 4: Challenge Instructions

The app so far looks great and works well. But it would be nice if people could see a list of speakers as well. The data for this is already bundled with the app in a file called **speakers.json**. Take a look at it.

In this challenge, you're going to add a new view controller to show the list of speakers alongside their Twitter handles.

First of all you're going to need to change the layout of the storyboard to use a tab bar controller with two tabs. Use the **Editor\Embed In\Tab Bar Controller** method to achieve this. The following illustration may help with laying out the storyboard:

![](./4-ChallengeImages/01-StoryboardLayout.png)

Then add a view controller called `SpeakersViewController` which is a subclass of `UITableViewController`. In here, load the list of speakers as an array of name & Twitter handle tuples, from the `speakers.json` file. Use the `loadData()` method in `ViewController` as a template if necessary.

You'll need to wire up the table view data source methods to return the correct number of rows and set up the cell appropriately. I suggest using a **Right Detail** type cell, setting the name as the title label's text and the Twitter handle as the detail label's text.

Finally, wire up selection of the table view cell to open a `SLComposeViewController` view controller to compose a new tweet mentioning the speaker that was selected.

Once you're done you should have an app which looks like the following:

![](./4-ChallengeImages/02-App1.png)

![](./4-ChallengeImages/03-App2.png)

![](./4-ChallengeImages/04-App3.png)
