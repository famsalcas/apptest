sub init()
    m.itemBg = m.top.findNode("itemBg")
    m.channelLogo = m.top.findNode("channelLogo")
    m.channelTitle = m.top.findNode("channelTitle")
    m.channelCategory = m.top.findNode("channelCategory")
    m.qualityBadge = m.top.findNode("qualityBadge")
    m.qualityText = m.top.findNode("qualityText")
    m.focusBorder = m.top.findNode("focusBorder")
end sub

sub setContent()
    itemData = m.top.itemContent
    if itemData <> invalid
        ' Título del canal
        if itemData.title <> invalid
            m.channelTitle.text = itemData.title
        end if
        
        ' Logo del canal
        if itemData.HDPosterUrl <> invalid and itemData.HDPosterUrl <> ""
            m.channelLogo.uri = itemData.HDPosterUrl
        else if itemData.PosterUrl <> invalid and itemData.PosterUrl <> ""
            m.channelLogo.uri = itemData.PosterUrl
        end if
        
        ' Categoría (desde el parent node)
        if itemData.getParent() <> invalid and itemData.getParent().title <> invalid
            m.channelCategory.text = itemData.getParent().title
        end if
        
        ' Indicador de calidad basado en el título
        title = itemData.title
        if title <> invalid
            titleUpper = UCase(title)
            if Instr(1, titleUpper, "HD") > 0 or Instr(1, titleUpper, "1080") > 0
                m.qualityBadge.visible = true
                m.qualityText.text = "HD"
                m.qualityBadge.color = "0x00AA00FF"
            else if Instr(1, titleUpper, "4K") > 0 or Instr(1, titleUpper, "UHD") > 0
                m.qualityBadge.visible = true
                m.qualityText.text = "4K"
                m.qualityBadge.color = "0x0066FFFF"
            else if Instr(1, titleUpper, "SD") > 0 or Instr(1, titleUpper, "480") > 0
                m.qualityBadge.visible = true
                m.qualityText.text = "SD"
                m.qualityBadge.color = "0xFFAA00FF"
            end if
        end if
    end if
end sub

sub focusChanged()
    focusPercent = m.top.focusPercent
    
    if focusPercent > 0
        ' Aplicar efecto de foco
        m.focusBorder.color = "0x00A0FFFF"
        m.focusBorder.width = 4
        m.itemBg.color = "0x404040FF"
        
        ' Animación de escalado sutil
        m.top.scale = 1.05
    else
        ' Quitar efecto de foco
        m.focusBorder.color = "0x00000000"
        m.focusBorder.width = 0
        m.itemBg.color = "0x2E2E2EFF"
        m.top.scale = 1.0
    end if
end sub