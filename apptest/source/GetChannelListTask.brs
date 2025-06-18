sub init()
    m.top.functionName = "GetChannelList"
end sub

sub GetChannelList()
    ' Obtener URL de la lista M3U
    reg = CreateObject("roRegistrySection", "profile")
    url = reg.Read("primaryfeed")
    
    if url = invalid or url = "" then
        m.top.content = invalid
        return
    end if
    
    ' Descargar contenido M3U
    http = CreateObject("roUrlTransfer")
    http.SetUrl(url)
    http.SetCertificatesFile("common:/certs/ca-bundle.crt")
    http.InitClientCertificates()
    http.SetRequest("GET")
    
    response = http.GetToString()
    
    if response <> invalid and response <> ""
        content = ParseM3U(response)
        m.top.content = content
    else
        m.top.content = invalid
    end if
end sub

function ParseM3U(m3uContent as String) as Object
    lines = m3uContent.Split(chr(10))
    rootContent = CreateObject("roSGNode", "ContentNode")
    
    ' Crear categorías
    categories = {}
    currentCategory = "General"
    
    i = 0
    while i < lines.Count()
        line = lines[i].Trim()
        
        if line.StartsWith("#EXTINF:")
            ' Extraer información del canal
            channelInfo = ParseChannelInfo(line)
            
            ' Obtener URL del siguiente line
            if i + 1 < lines.Count()
                channelUrl = lines[i + 1].Trim()
                if not channelUrl.StartsWith("#")
                    
                    ' Determinar categoría
                    if channelInfo.group <> invalid and channelInfo.group <> ""
                        currentCategory = channelInfo.group
                    end if
                    
                    ' Crear nodo de contenido para el canal
                    channelNode = CreateObject("roSGNode", "ContentNode")
                    channelNode.title = channelInfo.title
                    channelNode.url = channelUrl
                    channelNode.streamFormat = "hls"
                    
                    ' Configurar imagen del canal
                    if channelInfo.logo <> invalid and channelInfo.logo <> ""
                        channelNode.HDPosterUrl = channelInfo.logo
                        channelNode.SDPosterUrl = channelInfo.logo
                    else
                        ' Usar imagen por defecto si no hay logo
                        channelNode.HDPosterUrl = "pkg:/images/channel-default.jpg"
                        channelNode.SDPosterUrl = "pkg:/images/channel-default.jpg"
                    end if
                    
                    ' Agregar a categoría
                    if not categories.DoesExist(currentCategory)
                        categoryNode = CreateObject("roSGNode", "ContentNode")
                        categoryNode.title = currentCategory
                        categories[currentCategory] = categoryNode
                        rootContent.appendChild(categoryNode)
                    end if
                    
                    categories[currentCategory].appendChild(channelNode)
                    i = i + 1 ' Saltar línea de URL
                end if
            end if
        end if
        
        i = i + 1
    end while
    
    return rootContent
end function

function ParseChannelInfo(extinf as String) as Object
    info = {
        title: "Canal Sin Nombre",
        logo: "",
        group: "General"
    }
    
    ' Extraer título (después de la última coma)
    parts = extinf.Split(",")
    if parts.Count() > 1
        info.title = parts[parts.Count() - 1].Trim()
    end if
    
    ' Extraer logo (tvg-logo="...")
    logoMatch = CreateObject("roRegex", "tvg-logo=""([^""]*)", "i")
    logoResult = logoMatch.Match(extinf)
    if logoResult.Count() > 1
        info.logo = logoResult[1]
    end if
    
    ' Extraer grupo (group-title="...")
    groupMatch = CreateObject("roRegex", "group-title=""([^""]*)", "i")
    groupResult = groupMatch.Match(extinf)
    if groupResult.Count() > 1
        info.group = groupResult[1]
    end if
    
    return info
end function