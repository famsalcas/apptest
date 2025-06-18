sub init()
    m.top.backgroundURI = "pkg:/images/background-controls.jpg"

    ' Cambio menor: nombres de tareas actualizados
    m.save_feed_url = m.top.FindNode("SaveFeedUrlTask")
    m.get_channel_list = m.top.FindNode("GetChannelListTask")
    m.get_channel_list.ObserveField("content", "SetContent")

    ' Usar RowList en lugar de LabelList para mejor presentación
    m.rowList = m.top.FindNode("rowList")
    m.rowList.ObserveField("itemSelected", "setChannel")
    m.rowList.ObserveField("rowItemSelected", "setChannel")

    m.video = m.top.FindNode("Video")
    m.video.ObserveField("state", "checkState")

    ' Agregar indicadores visuales
    m.loadingSpinner = m.top.FindNode("loadingSpinner")
    m.channelInfo = m.top.FindNode("channelInfo")

    ' Verificar si ya tenemos URL guardada
    reg = CreateObject("roRegistrySection", "profile")
    if reg.Exists("primaryfeed") and reg.Exists("url_confirmed") then
        ' Si ya confirmamos la URL antes, cargar directamente
        m.loadingSpinner.visible = true
        m.get_channel_list.control = "RUN"
    else
        ' Solo mostrar diálogo si es primera vez o no confirmado
        showdialog()
    end if
End sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    result = false
    
    if press
        if key = "right"
            ' Cambiar a vista completa del video
            m.rowList.SetFocus(false)
            m.video.translation = [0, 0]
            m.video.width = 1920
            m.video.height = 1080
            m.channelInfo.visible = false
            result = true
        else if key = "left" or key = "back"
            ' Volver a vista con lista
            m.rowList.SetFocus(true)
            m.video.translation = [960, 100]
            m.video.width = 960
            m.video.height = 540
            m.channelInfo.visible = true
            result = true
        else if key = "options"
            ' Solo mostrar diálogo de configuración con options
            showConfigDialog()
            result = true
        else if key = "play"
            ' Reproducir/pausar
            if m.video.state = "playing"
                m.video.control = "pause"
            else
                m.video.control = "play"
            end if
            result = true
        end if
    end if
    
    return result 
end function

sub checkState()
    state = m.video.state
    if state = "error"
        m.top.dialog = CreateObject("roSGNode", "Dialog")
        m.top.dialog.title = "Error de Reproducción"
        m.top.dialog.message = "No se pudo reproducir este canal. Código: " + str(m.video.errorCode)
        m.top.dialog.buttons = ["OK"]
    else if state = "playing"
        ' Actualizar información del canal
        updateChannelInfo()
    end if
end sub

sub SetContent()    
    m.loadingSpinner.visible = false
    content = m.get_channel_list.content
    
    if content <> invalid and content.getChildCount() > 0
        m.rowList.content = content
        m.rowList.SetFocus(true)
        m.rowList.visible = true
        
        ' Seleccionar primer canal automáticamente
        if content.getChild(0).getChildCount() > 0
            m.rowList.jumpToRowItem = [0, 0]
            setChannel()
        end if
    else
        ' Mostrar error si no hay contenido
        m.top.dialog = CreateObject("roSGNode", "Dialog")
        m.top.dialog.title = "Sin Canales"
        m.top.dialog.message = "No se encontraron canales en la URL proporcionada"
        m.top.dialog.buttons = ["OK"]
    end if
end sub

sub setChannel()
    selectedItem = m.rowList.content.getChild(m.rowList.rowItemSelected[0]).getChild(m.rowList.rowItemSelected[1])
    
    if selectedItem = invalid then return
    
    ' Clonar contenido para evitar modificaciones
    content = selectedItem.clone(true)
    content.streamFormat = "hls,dash,smooth,mp4"
    
    ' Configuración mejorada para streaming
    content.HttpSendClientCertificates = true
    content.HttpCertificatesFile = "common:/certs/ca-bundle.crt"
    
    ' Evitar reproducir el mismo canal
    if m.video.content <> invalid and m.video.content.url = content.url then return
    
    m.video.EnableCookies()
    m.video.SetCertificatesFile("common:/certs/ca-bundle.crt")
    m.video.InitClientCertificates()
    m.video.content = content
    m.video.control = "play"
    
    ' Actualizar información visual
    updateChannelInfo()
end sub

sub updateChannelInfo()
    if m.video.content <> invalid
        ' Actualizar título del canal
        titleLabel = m.channelInfo.FindNode("channelTitle")
        if titleLabel <> invalid
            titleLabel.text = m.video.content.title
        end if
        
        ' Actualizar logo del canal
        logoNode = m.channelInfo.FindNode("channelLogo")
        if logoNode <> invalid
            if m.video.content.HDPosterUrl <> invalid and m.video.content.HDPosterUrl <> ""
                logoNode.uri = m.video.content.HDPosterUrl
            else
                logoNode.uri = "pkg:/images/channel-default.jpg"
            end if
        end if
    end if
end sub

sub showConfigDialog()
    keyboarddialog = createObject("roSGNode", "KeyboardDialog")
    keyboarddialog.backgroundUri = "pkg:/images/rsgde_bg_hd.jpg"
    keyboarddialog.title = "Configurar Lista M3U"
    keyboarddialog.text = m.global.feedurl
    keyboarddialog.buttons = ["Cancelar", "Guardar y Cargar"]
    keyboarddialog.optionsDialog = true
    
    m.top.dialog = keyboarddialog
    m.top.dialog.keyboard.textEditBox.cursorPosition = len(m.global.feedurl)
    m.top.dialog.keyboard.textEditBox.maxTextLength = 500
    
    keyboarddialog.observeFieldScoped("buttonSelected", "onConfigKeyPress")
end sub

sub showdialog()
    keyboarddialog = createObject("roSGNode", "KeyboardDialog")
    keyboarddialog.backgroundUri = "pkg:/images/rsgde_bg_hd.jpg"
    keyboarddialog.title = "Bienvenido - Ingresa tu Lista M3U"
    keyboarddialog.text = m.global.feedurl
    keyboarddialog.buttons = ["Cargar Canales"]
    keyboarddialog.optionsDialog = false
    
    m.top.dialog = keyboarddialog
    m.top.dialog.keyboard.textEditBox.cursorPosition = len(m.global.feedurl)
    m.top.dialog.keyboard.textEditBox.maxTextLength = 500
    
    keyboarddialog.observeFieldScoped("buttonSelected", "onKeyPress")
end sub

sub onConfigKeyPress()
    if m.top.dialog.buttonSelected = 1 ' Guardar y Cargar
        url = m.top.dialog.text
        if url <> "" and url <> invalid
            m.global.feedurl = url
            ' Marcar como confirmado para evitar diálogo futuro
            reg = CreateObject("roRegistrySection", "profile")
            reg.Write("url_confirmed", "true")
            reg.Flush()
            
            m.save_feed_url.control = "RUN"
            m.top.dialog.close = true
            m.loadingSpinner.visible = true
            m.get_channel_list.control = "RUN"
        end if
    end if
    ' Si cancela, simplemente cierra el diálogo
    m.top.dialog.close = true
end sub

sub onKeyPress()
    if m.top.dialog.buttonSelected = 0 ' Cargar Canales
        url = m.top.dialog.text
        if url <> "" and url <> invalid
            m.global.feedurl = url
            ' Marcar como confirmado
            reg = CreateObject("roRegistrySection", "profile")
            reg.Write("url_confirmed", "true")
            reg.Flush()
            
            m.save_feed_url.control = "RUN"
            m.top.dialog.close = true
            m.loadingSpinner.visible = true
            m.get_channel_list.control = "RUN"
        end if
    end if
end sub