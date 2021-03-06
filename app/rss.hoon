::  rss.hoon
::  Watches RSS feeds and posts entries to a link collection
::
::  Usage
::  Generators:
::  :rss|add-feed feed-url resource
::      Watch the feed at url and add links to the link collection at resource
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
/-  graph=graph-store, post
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
::
++  on-init
  :: Start fetch timer
  ^-  (quip card _this)
  ~&  >  '%rss initialized successfully'
  =.  wait.state  ~m15
  :-  ~[(timer-card:hc wait.state)]
  this
::
++  on-save
  ~&  >  '%rss saved'
  ^-  vase
  !>(state)
::
++  on-load
  |=  old-state=vase
  ^-  (quip card _this)
  ~&  >  '%rss recompiled successfully'
  `this(state !<(state-zero old-state))
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?>  (team:title [our src]:bowl)
  =^  cards  state
    :: Switch on the mark, if not handled pass the card to default agent
    ?+  mark  (on-poke:def mark vase) 
        %rss-action  (handle-action:hc !<(action:rss vase))
    ==
  [cards this]
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ?+  -.sign-arvo  (on-arvo:def wire sign-arvo)
    %iris
    ?>  ?=(%http-response +<.sign-arvo)
    =^  cards  state
      (handle-response:hc -.wire client-response.sign-arvo)
    [cards this]
    %behn
    ?>  ?=(%wake +<.sign-arvo)
    :_  this
    :: Reset time and poke self to fetch
    ~[(timer-card:hc wait.state) [%pass /fetch %agent [our.bowl %rss] %poke %rss-action !>([%fetch ~])]]  
  ==
::
++  on-watch  on-watch:def
++  on-leave  on-leave:def
::
++  on-peek
  |=  pax=path
  ^-  (unit (unit cage))
  ?+    pax  (on-peek:def pax)
      [%y %feeds ~]
  ``noun+!>(~(key by feeds.state))
      [%y %wait ~]
  ``noun+!>(wait.state)
  ==
::
++  on-agent  on-agent:def
++  on-fail   on-fail:def
--
::
|_  =bowl:gall
++  handle-action
    |=  =action:rss
    ^-  (quip card _state)
    ?-  -.action  ::TODO More feed CRUD
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
::
++  get-url
  |=  =url
  ^-  request:http
  [%'GET' url ~ ~]
:: +iris-card make a request card for iris
::
++  iris-card
  |=  [=url]  ^-  card
  ~&  >  "Getting Url: {<url>}"
  [%pass /[url] %arvo %i %request (get-url url) *outbound-config:iris]
:: +timer-card marke a time card for behn
::
++  timer-card
  |=  [wait=@dr]  ^-  card
  [%pass /rss-timer %arvo %b %wait (add now.bowl wait)]
:: +link-card make a card to add a link to a collection
::
++  link-card
  |=  [resource=resource:graph index=@ title=@t url=@t]
  :-  %pass
  :-  /rss
  :-  %agent
  :-  [our.bowl %graph-push-hook]
  :-  %poke
  :-  %graph-update
  !>  ^-  update:graph
  :+  %0  index
  :-  %add-nodes
  :-  resource
  %-  ~(put by *(map index:post node:graph))
  :-  ~[index]
  :_  *internal-graph:graph
  ^-  post:post
  [our.bowl ~[index] now.bowl `(list content:post)`~[[%text title] [%url url]] ~ ~]
::
++  handle-fetch
  ^-  (quip card _state)
  :_  state
  %+  turn  ~(tap in ~(key by feeds.state))  iris-card
:: +find-p return a unit of the first index where p evaluates to true
::
++  find-p
  |*  [l=(list) p=$-(* ?)]
  ^-  (unit @ud)
  =>  .(l (homo l))
  =|  i=@ud
  |-
  ?~  l  ~
  ?:  (p i.l)
    `i
  $(i +(i), l t.l)
::
++  handle-response
  |=  [=url resp=client-response:iris]
  ^-  (quip card _state)
  ?.  ?=(%finished -.resp)
    ~&  >>>  "Invalid response {<-.resp>}"
    `state
  ?~  full-file.resp
    ~&  >>>  "{<url>} responded with a blank page"
    `state
  =/  data  q.data.u.full-file.resp
  =/  xml=(list rss-item:rss)  (rss-parse:rss data)
  =/  feed  (~(got by feeds.state) url)
  =/  last-fetch  last-checked.feed
  :: Sort xml by decending date
  =.  xml
    %+  sort  xml
    |=  [a=rss-item:rss b=rss-item:rss]
    (gth date.a date.b)
  :: unit index of the first rss item that has a date
  :: older than our last fetch
  =/  first-seen-index
  %+  find-p  xml
  |=  [x=rss-item:rss]
  (lte date.x last-fetch)
  :: Cut off old items
  =?  xml  ?=([~ u=@ud] first-seen-index)
  (scag u.first-seen-index xml)
  :: Update the last fetch time for the feed
  =/  this-fetch
    ?~(xml last-fetch date.i.xml)
  :_  state(feeds (~(put by feeds.state) url [resource:feed this-fetch]))
  =<  p
  %^  spin  (flop xml)
    now.bowl
  |=  [i=rss-item:rss index=@]
  :_  +(index)
  %:  link-card
      resource.feed
      index
      (crip title.i)
      (crip url.i)
  ==
--
