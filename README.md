# Lisk Node Watcher

AHK script for Windows to watch over the Lisk networks status and your Lisk nodes.

## Description

Lisk Node Watcher is a rewrite and extended version of the previos LiskDelegateMonitor. https://github.com/vegahub/LiskDelegateMonitor

## Installation

You can just run the binary exe and that's it. Alternatively you can run the source file after installing Autohotkey (http://autohotkey.com), or even compile it yourself with a simple drag and drop compiler included in the Autohotkey folder after install.

You'll need the defaultUI.html in the same directory as the tool.
It uses jquery and JqueryUI, it's not needed to download them, but it may be a good idea if you want a faster startup time. Just edit the head of defaultUI.html with the path.

Please make sure that the script has write priviliges to the folder its running in (needed to save settings)

## About Lisk Node Watcher

v0.1 does about the same thing the previous Lisk Delegate Monitor did, but it is a completely new code, with a html based UI that opens up many more possibilities and needed for future improvements.

### Current features
- shows block height consensus of peers on the lisk network (100 peers)
- displays your node(s) height and (if your API is open or your ip whitelisted) the forging status on that node
- Basic information about your Lisk Delegate, like approval, productivity, forged and missed blocks. For both this and for forging status you'll need only to provide a delegate name

The functions should work fine, in future versions their performance will be improved. The UI have some bugs and not yet working functions (for example you can drag the info boxes, but they should snap in place, and stay there), and a few other small quirks.

You can leave a comment in the Lisk forum thread.

*Donation address: 18090376249243533580L*

