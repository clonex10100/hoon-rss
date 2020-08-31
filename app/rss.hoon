::  rss.hoon
::  Watch RSS feeds and posts entries to link-store
::
/+  rss, *server, default-agent, dbug
!:
|%
+$  versioned-state
    $%  state-zero
    ==
::
+$  state-zero  [%0 feeds=(list feed:rss)]
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

  ++  on-init
    ^-  (quip card _this)
    ~&  >  '%rss initialized successfully'
    :-  ~
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
      ?+  mark  (on-poke:def mark vase)  ::Switch on the mark, if not handledpass the card to default agent
          %rss-action  (handle-action !<(action:rss vase))
      ==
    [cards this]

  ++  on-arvo
    |=  [=wire =sign-arvo]
    ^-  (quip card _this)
    ::If sign is an http-response from iris handle it with handle-response
    ::If it's any other sign from iris crash
    ::If it's not from iris handle with default agent
    ?+  -.sign-arvo  (on-arvo:def wire sign-arvo)
        %i
      ?>  ?=(%http-response +<.sign-arvo)
      =^  cards  state
        (handle-response -.wire client-response.sign-arvo)
      [cards this]
    ==

  ++  on-watch  on-watch:def
  ++  on-leave  on-leave:def
  ++  on-peek   on-peek:def
  ++  on-agent  on-agent:def
  ++  on-fail   on-fail:def
  --
  ::
  |_  =bowl:gall
  ++  handle-action
      |=  =action:rss
      ^-  (quip card _state)
      ?-  -.action
          %add-feed
        :-  ~
        state(feeds [+.action feeds:state])

          %fetch
        :_  state
        =/  =url  ?~(feeds.state !! url.i.feeds.state)
        ~&  >  "Getting Url: {<url>}"
        ~[[%pass /[url] %arvo %i %request (get-url url) *outbound-config:iris]]
      ==

  ++  get-url
    |=  =url
    ^-  request:http
    [%'GET' url ~ ~]

  ++  handle-response
    |=  [=url resp=client-response:iris]
    ^-  (quip card _state)
    ?.  ?=(%finished -.resp) ::If response type not finished simply print it and leave state unchanged
      ~&  >>>  -.resp
      `state
    ?~  full-file.resp  !!
    =/  data  q.data.u.full-file.resp
    ~&  >>  "{<data>}"
    =/  xml  (rss-parse:rss data)
    ~&  >>>  "{<xml>}"
    ?~  feeds.state  !!
    ::This is where I need to send link-store cards
    `state
  --
