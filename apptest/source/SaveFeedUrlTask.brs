sub init()
    m.top.functionName = "SaveFeedUrl"
end sub

sub SaveFeedUrl()
    reg = CreateObject("roRegistrySection", "profile")
    reg.Write("primaryfeed", m.global.feedurl)
    reg.Flush()
end sub