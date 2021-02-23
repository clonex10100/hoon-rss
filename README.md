# hoon-rss
An app for urbit. Watches rss feeds and posts the links to a link collection.

# Install
Clone the repo. Make sure your urbit is mounted. You probably should install it on a moon or fake urbit. Copy the files into your urbit's home, then run these commands:

`|commit %home`

`|start %rss`

# Usage
Most interaction with the app is through its generators:

### Add a feed

`:rss|add-feed 'feed url' resource`

### Remove a feed
`:rss|remove-feed 'url'`

### Manually Trigger a fetch
`:rss|fetch`

### Change the fetch interval
`:rss|set-wait ~m15`

It also has a few scry paths

### List feeds
`.^((set cord) %gy /=rss=/feeds)`

### Show current fetch interval
`.^(@dr %gy /=rss=/wait)`
