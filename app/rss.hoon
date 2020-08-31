::  rss.hoon
::  Watch RSS feeds and posts entries to link-store
::
/-  rss
/+  *server, default-agent, dbug
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
    ~&  >  'Onarvo {<sign-arvo>}'
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
        ::
        %fetch
        :_  state
        =/  =url  ?~(feeds.state !! url.i.feeds.state)
        ~&  >>  "FUckUrl {<url>}"
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
    =/  l  (lent (trip ^-(cord data)))
    =/  p  (oust [0 11.345] (trip ^-(cord data)))
    ~&  >>  "{<data>}"
    ~&  >  "{<p>}"
    ~&  >  "{<l>}"
    ::=/  xml  (rss-parse (trip data))
    =/  xml  (rss-parse data)
    ::=/  cdata  (remove-version data)
    ::~&  >>  "File  {<full-file.resp>}"
    ::~&  >  "Decl {<decl:de-xml:html>}"
    ::~&  >>  "Got data from {<data>}"
    ::~&  >>  "{<data>}"
    ~&  >>>  "{<xml>}"
    ?~  feeds.state  !!
    ::=.  file.i.feeds.state  full-file.resp
    `state


  ++  rss-parse
    |=  [xml=cord]
    |^  ^-  (list rss-item:rss)
    (rash xml root)

    ++  root
      ;~  sfix
        ;~  pfix
          (trash '<channel>')
          channel
        ==
        %-  star  cha
      ==

    ++  channel
      %+  ifix  (tagjest "channel")
      ;~  sfix
        %-  star
        ;~  pfix
          (trash '<item>')
          item
        ==
        (trash '</channel>')
      ==

    ++  item
      ^-  rss-item:rss
      |^  %+  ifix  (tagjest "item")
      ;~  sfix
        ;~(plug ;~(pfix (trash '<title>') title) ;~(pfix (trash '<link>') link) ;~(pfix (trash '<pubDate>') pubdate))
        (trash '</item>')
      ==
      ++  title
        %+  ifix  (tagjest "title")
        %-  star
        ;~(less (jest '</title>') cha)

      ++  link
        %+  ifix  (tagjest "link")
        %-  star
        ;~(less (jest '</link>') cha)

      ++  pubdate
        ^-  date
        ::[[& year] month [day hour minute second (list ux)]
        ::Sun, 30 Aug 2020 10:51:10 +0000
        ::X  , day mon  year h m s   x
        %+  ifix  (tagjest "pubDate")
        %-  star
        ;~(less (jest '</pubDate>') cha)
      --

    ++  trash
      |=  [str=cord]
      %-  star
      ;~(less (jest str) cha)

    ++  tagjest
      |=  [tag=tape]
      [(jest (crip (weld ['<' tag] ">"))) (jest (crip (weld ['<' '/' tag] ">")))]

    ++  cha  ::Match printable or whitespace
      ;~(pose prn (mask ~[' ' `@`0x9 `@`0xa `@`0xd `@`'\\' `@`'"']))
    --
  --
