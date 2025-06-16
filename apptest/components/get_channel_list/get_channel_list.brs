sub init()
    m.top.functionName = "getContent"
end sub

sub getContent()
    feedurl = m.global.feedurl
    if feedurl = invalid or feedurl = ""
        return
    end if

    m.port = CreateObject("roMessagePort")
    searchRequest = CreateObject("roUrlTransfer")
    searchRequest.setURL(feedurl)
    searchRequest.EnableEncodings(true)
    searchRequest.SetRequest("GET")
    
    ' Configuración HTTPS mejorada
    httpsReg = CreateObject("roRegex", "^https:", "")
    if httpsReg.isMatch(feedurl)
        searchRequest.SetCertificatesFile("common:/certs/ca-bundle.crt")
        searchRequest.AddHeader("X-Roku-Reserved-Dev-Id", "")
        searchRequest.InitClientCertificates()
    end if
    
    ' Headers adicionales para mejor compatibilidad
    searchRequest.AddHeader("User-Agent", "Roku/DVP-9.40 (829.40E04111A)")
    searchRequest.AddHeader("Accept", "*/*")

    text = searchRequest.getToString()
    
    if text = invalid or text = ""
        print "Error: No se pudo obtener contenido de la URL"
        return
    end if

    ' Regex mejorados para parsing M3U
    reHasGroups = CreateObject("roRegex", "group-title\s*=\s*" + chr(34) + "?([^" + chr(34) + ",]*)" + chr(34) + "?", "i")
    reLineSplit = CreateObject("roRegex", "(?>\r\n|[\r\n])", "")
    reExtinf = CreateObject("roRegex", "(?i)^#EXTINF:\s*([^,]*),\s*(.*)$", "")
    rePath = CreateObject("roRegex", "^([^#].*)$", "")
    
    ' Regex para extraer logos
    reLogoTvg = CreateObject("roRegex", "tvg-logo\s*=\s*" + chr(34) + "([^" + chr(34) + "]*)" + chr(34), "i")
    reLogoGeneric = CreateObject("roRegex", "logo\s*=\s*" + chr(34) + "([^" + chr(34) + "]*)" + chr(34), "i")

    hasGroups = reHasGroups.isMatch(text)
    inExtinf = false
    con = CreateObject("roSGNode", "ContentNode")
    
    if not hasGroups
        ' Si no hay grupos, crear uno por defecto
        defaultGroup = con.CreateChild("ContentNode")
        defaultGroup.contenttype = "SECTION"
        defaultGroup.title = "Todos los Canales"
        group = defaultGroup
    else
        groups = {}
    end if

    currentTitle = ""
    currentLogo = ""
    currentGroup = ""

    for each line in reLineSplit.Split(text)
        line = line.Trim()
        
        if inExtinf
            ' Procesamos la URL del stream
            maPath = rePath.Match(line)
            if maPath.Count() = 2 and maPath[1] <> ""
                item = group.CreateChild("ContentNode")
                item.url = maPath[1]
                item.title = currentTitle
                
                ' Asignar logo si existe
                if currentLogo <> ""
                    item.HDPosterUrl = currentLogo
                    item.PosterUrl = currentLogo
                end if
                
                ' Asignar tipo de contenido
                item.contenttype = "MOVIE"
                item.streamformat = "hls"
                
                inExtinf = false
            end if
        end if
        
        ' Procesamos líneas EXTINF
        maExtinf = reExtinf.Match(line)
        if maExtinf.Count() = 3
            currentTitle = maExtinf[2].Trim()
            
            ' Extraer información del grupo si existe
            if hasGroups
                maGroup = reHasGroups.Match(line)
                if maGroup.Count() > 1
                    currentGroup = maGroup[1].Trim()
                    if currentGroup = "" then currentGroup = "Sin Categoría"
                else
                    currentGroup = "Sin Categoría"
                end if
                
                ' Buscar o crear grupo
                group = invalid
                for x = 0 to con.getChildCount() - 1
                    node = con.getChild(x)
                    if node.title = currentGroup
                        group = node
                        exit for
                    end if
                end for
                
                if group = invalid
                    group = con.CreateChild("ContentNode")
                    group.contenttype = "SECTION"
                    group.title = currentGroup
                end if
            end if
            
            ' Extraer logo
            currentLogo = ""
            maLogo = reLogoTvg.Match(line)
            if maLogo.Count() > 1
                currentLogo = maLogo[1]
            else
                maLogo = reLogoGeneric.Match(line)
                if maLogo.Count() > 1
                    currentLogo = maLogo[1]
                end if
            end if
            
            inExtinf = true
        end if
    end for
    
    ' Ordenar grupos alfabéticamente
    if hasGroups and con.getChildCount() > 1
        sortedGroups = []
        for i = 0 to con.getChildCount() - 1
            sortedGroups.Push(con.getChild(i))
        end for
        
        ' Ordenamiento simple por título
        for i = 0 to sortedGroups.Count() - 2
            for j = i + 1 to sortedGroups.Count() - 1
                if UCase(sortedGroups[i].title) > UCase(sortedGroups[j].title)
                    temp = sortedGroups[i]
                    sortedGroups[i] = sortedGroups[j]
                    sortedGroups[j] = temp
                end if
            end for
        end for
        
        ' Recrear contenido ordenado
        newCon = CreateObject("roSGNode", "ContentNode")
        for each sortedGroup in sortedGroups
            newChild = newCon.CreateChild("ContentNode")
            newChild.contenttype = sortedGroup.contenttype
            newChild.title = sortedGroup.title
            
            ' Copiar canales del grupo
            for i = 0 to sortedGroup.getChildCount() - 1
                channel = sortedGroup.getChild(i)
                newChannel = newChild.CreateChild("ContentNode")
                newChannel.url = channel.url
                newChannel.title = channel.title
                newChannel.HDPosterUrl = channel.HDPosterUrl
                newChannel.PosterUrl = channel.PosterUrl
                newChannel.contenttype = channel.contenttype
                newChannel.streamformat = channel.streamformat
            end for
        end for
        
        con = newCon
    end if

    m.top.content = con
end sub