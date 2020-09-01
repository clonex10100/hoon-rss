::  rss.hoon
::  Watches RSS feeds and posts entries to link-store
::
::  Usage
::  Generators:
::  :rss|add-feed feed-url link-store-wire
::      Rss will check the feed at the url on an interval (15 minutes by
::      default) and post
::      new links to the link store wire
::
::  :rss|remove-feed feed-url
::      Remove the feed at url from rss
::
::  :rss|set-wait @dr
::      Set the interval in between feed updates
::
::  :rss|fetch
::      manually start an update
::
::  Scry Paths:
::  %gy /=rss=/feeds
::  returns a set of cords where each cord is a feed url
::
::  %gy /=rss=/wait
::  @rd of the interval between updates
::
/-  link-store
/+  rss, *server, default-agent, dbug
|%
+$  versioned-state
    $%  state-zero
    ==
::
+$  state-zero  [%0 feeds=(map url feed:rss) wait=@dr]
::
+$  url  @t
::
+$  card  card:agent:gall
::
--
::
%-  agent:dbug
=|  state=versioned-state
^-  agent:gall
=<
  |_  =bowl:gall
  +*  this      .
      def   ~(. (default-agent this %|) bowl)
      hc  ~(. +> bowl)

  ++  on-init
    ::Start fetch timer
    ^-  (quip card _this)
    ~&  >  '%rss initialized successfully'
    =.  wait.state  ~m15
    :-  ~[(timer-card:hc wait.state)]
    this

  ++  on-save
    ~&  >  '%rss saved'
    ^-  vase
    !>(state)

  ++  on-load
    |=  old-state=vase
    ^-  (quip card _this)
    ~&  >  '%rss recompiled successfully'
    `this(state !<(state-zero old-state))

  ++  on-poke
    |=  [=mark =vase]
    ^-  (quip card _this)
    =^  cards  state
      ?+  mark  (on-poke:def mark vase)  ::Switch on the mark, if not handled pass the card to default agent
          %rss-action  (handle-action:hc !<(action:rss vase))
      ==
    [cards this]

  ++  on-arvo
    |=  [=wire =sign-arvo]
    ^-  (quip card _this)
    ?+  -.sign-arvo  (on-arvo:def wire sign-arvo)
        %i
      ?>  ?=(%http-response +<.sign-arvo)
      =^  cards  state
        (handle-response:hc -.wire client-response.sign-arvo)
      [cards this]
        %b
      ?>  ?=(%wake +<.sign-arvo)
      :_  this
      ~[(timer-card:hc wait.state) [%pass /fetch %agent [our.bowl %rss] %poke %rss-action !>([%fetch ~])]]  ::Reset time and poke self to fetch
    ==

  ++  on-watch  on-watch:def
  ++  on-leave  on-leave:def

  ++  on-peek
    |=  pax=path
    ^-  (unit (unit cage))
    ?+    pax  (on-peek:def pax)
        [%y %feeds ~]
    ``noun+!>(~(key by feeds.state))
        [%y %wait ~]
    ``noun+!>(wait.state)
    ==

  ++  on-agent  on-agent:def
  ++  on-fail   on-fail:def
  --
  ::
  |_  =bowl:gall
  ++  handle-action
      |=  =action:rss
      ^-  (quip card _state)
      |^  ?-  -.action  ::TODO More feed CRUD
          %add-feed
            :-  ~
            state(feeds (~(put by feeds.state) url.+.action feed.+.action))
          %remove-feed
            :-  ~
            state(feeds (~(del by feeds.state) url.+.action))
          %set-wait
            :-  ~
            state(wait wait.+.action)
          %fetch  handle-fetch
      ==
      ++  handle-fetch
        ^-  (quip card _state)
        :_  state
        %+  turn  ~(tap in ~(key by feeds.state))  iris-card
      --
  ++  get-url
    |=  =url
    ^-  request:http
    [%'GET' url ~ ~]

  ++  iris-card
    |=  =url  ^-  card
        ~&  >  "Getting Url: {<url>}"
    [%pass /[url] %arvo %i %request (get-url url) *outbound-config:iris]

  ++  timer-card
    |=  [wait=@dr]  ^-  card
    [%pass /rss-timer %arvo %b %wait (add now.bowl wait)]

  ++  handle-response
    |=  [=url resp=client-response:iris]
    ^-  (quip card _state)
    ?.  ?=(%finished -.resp) ::If response type not finished simply print it and leave state unchanged
      ~&  >>>  -.resp
      `state
    ?~  full-file.resp  !!
    =/  data  q.data.u.full-file.resp
    =/  xml=(list rss-item:rss)  (rss-parse:rss data)
    ::~&  >>  "{<xml>}"
    =/  feed  (~(got by feeds.state) url)
    =/  last-fetch  last-checked.feed
    =/  this-fetch  ?~  xml  last-fetch  ::Keep track of the date of the newest item to avoid dupes. If there are no items then use prev date
    ^-  @d  (roll (turn xml |=(i=rss-item:rss ^-(@d date.i))) max)  ::Get the latest date out of all items
    =.  xml  (skim xml |=(i=rss-item:rss (gth date.i last-fetch)))::Remove dupes
    ::~&  >>>  "{<xml>}"
    :_  state(feeds (~(put by feeds.state) url [path:feed this-fetch]))::Update the last checked time for the feed
    %+  turn  xml
    |=  [i=rss-item:rss]  ^-  card
      [%pass /rss %agent [our.bowl %link-store] %poke [%link-action !>([%save `wire`path:feed (crip title.i) (crip url.i)])]]

  --
