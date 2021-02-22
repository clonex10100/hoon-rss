/-  *post
^?
|%
+$  action
  $%  [%add-feed =url =feed]
      [%remove-feed =url]
      [%set-wait wait=@dr]
      [%fetch ~]
  ==

+$  feed  ::Feed needs to have a list of link-store wires and a date that it was last checked
  $:  =resource
      last-checked=@d
  ==

+$  url  @t


+$  rss-item
  $:  title=tape
      url=tape
      date=@d
  ==
--
