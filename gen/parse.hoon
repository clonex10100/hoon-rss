/-  *rss
!:
|=  [xml=tape]
=<  ^-((list rss-item) (scan xml channel))
|%
++  channel
  %+  ifix  (tagjest "channel")
  ;~  sfix
    %-  star
    ;~  pfix
      (trash '<item>')
      item
    ==
    %-  star  cha
  ==
++  item
  |^  %+  ifix  (tagjest "item")
  ;~  sfix
    ;~(plug ;~(pfix (trash '<title>') title) ;~(pfix (trash '<link>') link))
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
  --
++  trash
  |=  [str=cord]
  %-  star
  ;~(less (jest str) cha)
++  tagjest
  |=  [tag=tape]
  [(jest (crip (weld ['<' tag] ">"))) (jest (crip (weld ['<' '/' tag] ">")))]
++  cha  ::Match printable or whitespace
  ;~(pose prn (mask ~[' ' `@`0x9 `@`0xa `@`0xd]))
--

::'<channel> fucking shit </channel>'
