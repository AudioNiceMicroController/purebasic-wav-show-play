;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; sndfile ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; --- Constantes libsndfile ---
#SFM_READ = $10 ; Mode lecture pour sf_open (0x10)
#SFM_WRITE = $20
#SFM_RDWR = $30

#SEEK_SET = 0
#SEEK_CUR = 1
#SEEK_END = 2

; --- Importation des fonctions libsndfile ---
ImportC "libsndfile.1.0.37.dylib"
  sf_open(filename.p-utf8, mode.l, *sfinfo)
  ;   sf_open(filename.s, mode.l, *sfinfo)  ; filename.s = PureBasic String
  sf_strerror(*sndfile)
  sf_close(*sndfile)
  sf_read_float(*sndfile, *ptr_float, frames.q)
  sf_readf_float(*sndfile, *ptr_float, frames.q)
  sf_seek(*sndfile, pos.i, style.i);sf_count_t  sf_seek  (SNDFILE *sndfile, sf_count_t frames, int whence) ;
EndImport

; --- Structure SF_INFO de libsndfile ---
Structure SF_INFO Align #PB_Structure_AlignC
  frames.i       ; sf_count_t (nombre de frames) 8
  samplerate.l   ; int (fréquence d'échantillonnage) 4
  channels.l     ; int (nombre de canaux) 4
  format.l       ; int (format du fichier, ex: WAV, FLAC, etc.) 4
  sections.l     ; int (nombre de sections) 4
  seekable.l     ; int (indique si le fichier est seekable) 4
EndStructure

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; portaudio ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ==== Constantes ====
#paContinue = 0
#SampleRate = 44100
#FramesPerBuffer = 64
#TwoPi = 2 * #PI
#paFloat32 = $1
#paInt16   = $8
#paComplete = 1


Enumeration
  #paNoError = 0
  
  #paNotInitialized = -10000
  #paUnanticipatedHostError
  #paInvalidChannelCount
  #paInvalidSampleRate
  #paInvalidDevice
  #paInvalidFlag
  #paSampleFormatNotSupported
  #paBadIODeviceCombination
  #paInsufficientMemory
  #paBufferTooBig
  #paBufferTooSmall
  #paNullCallback
  #paBadStreamPtr
  #paTimedOut
  #paInternalError
  #paDeviceUnavailable
  #paIncompatibleHostApiSpecificStreamInfo
  #paStreamIsStopped
  #paStreamIsNotStopped
  #paInputOverflowed
  #paOutputUnderflowed
  #paHostApiNotFound
  #paInvalidHostApi
  #paCanNotReadFromACallbackStream
  #paCanNotWriteToACallbackStream
  #paCanNotReadFromAnOutputOnlyStream
  #paCanNotWriteToAnInputOnlyStream
  #paIncompatibleStreamHostApi
  #paBadBufferPtr
EndEnumeration

ImportC "libportaudio.2.dylib"
  Pa_Initialize()
  Pa_Terminate()
  Pa_GetDeviceCount()
  Pa_GetDeviceInfo(i) ;const PaDeviceInfo * Pa_GetDeviceInfo (PaDeviceIndex device)
  Pa_GetHostApiInfo(q);const PaHostApiInfo * Pa_GetHostApiInfo (PaHostApiIndex hostApi)
  Pa_GetErrorText(i)  ;const char * Pa_GetErrorText (PaError errorCode)
  Pa_StartStream(*stream)
  Pa_StopStream(*stream)
  Pa_CloseStream(*stream)
  Pa_IsStreamActive(*stream)
  
  ;   typedef unsigned long PaSampleFormat;
  ;   PaError Pa_OpenDefaultStream (PaStream **stream, int numInputChannels, int numOutputChannels, PaSampleFormat sampleFormat, double sampleRate, unsigned long framesPerBuffer, PaStreamCallback *streamCallback, void *userData)
  Pa_OpenDefaultStream(*stream, inputChannels, outputChannels.l, sampleFormat.q, sampleRate.d, framesPerBuffer.q, *callback, *userData)
  
  Pa_Sleep(ms)
EndImport

Structure PaDeviceInfo Align #PB_Structure_AlignC
  structVersion.l               ;4 bytes
  *name                         ; 8 bytes
  hostApi.l                     ;4 bytes. int
  maxInputChannels.l            ;4 bytes
  maxOutputChannels.l           ;4 bytes
  defaultLowInputLatency.d      ; 8 bytes
  defaultLowOutputLatency.d     ; 8 bytes
  defaultHighInputLatency.d     ; 8 bytes
  defaultHighOutputLatency.d    ; 8 bytes
  defaultSampleRate.d           ; 8 bytes
EndStructure

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#FRAMES_PER_BUFFER = 512

Structure PaData
  file.i         ; SNDFILE* (pointeur vers la structure SF_SNDFILE, un handle de fichier)
  info.SF_INFO   ; Informations sur le fichier audio
EndStructure

; === Callback audio ===
ProcedureC.l audio_callback(*inputBuffer, *outputBuffer, framesPerBuffer.q, *timeInfo, statusFlags.q, *userData)
  Protected *audioData.PaData = *userData
  Protected *audioOut.FLOAT = *outputBuffer
  Protected num_read.q
  Protected i.l, totalSamples.l, filtre.f, input.f
  
  totalSamples = framesPerBuffer * *audioData\info\channels
  
  num_read = sf_read_float(*audioData\file, *audioOut, totalSamples)
  
  ProcedureReturn #paContinue
EndProcedure
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; --- Déclaration des variables ---
Define audioData.PaData

Define filename.s = "/Users/uio/Music/test.wav" ; Chemin du fichier WAV

; --- Ouverture du fichier WAV ---
audioData\info\format = 0 ; Initialise le format à 0 comme requis par sf_open
audioData\file = sf_open(filename, #SFM_READ, @audioData\info) ; Passe l'adresse de la structure SF_INFO

; OpenConsole()

If audioData\file = 0
  ; Récupère le message d'erreur de libsndfile
  ; #Null est la constante PureBasic pour un pointeur nul, équivalent à NULL en C.
  Define *error_str.Ascii = sf_strerror(#Null)
  ;   PrintN("Erreur lors de l'ouverture du fichier WAV : " + PeekS(*error_str, -1, #PB_Ascii))
  Debug("Erreur lors de l'ouverture du fichier WAV : " + PeekS(*error_str, -1, #PB_Ascii))
  End
EndIf

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

nbreEchantillonCanalGauche = audioData\info\frames
#w = 1000
#h = 200
nbFrameParPixel = nbreEchantillonCanalGauche / #w
; Debug("nbFrameParPixel : " + Str(nbFrameParPixel))
nAlire.i = nbFrameParPixel*2; stéréo
Dim tamp.f(nAlire)
Dim moyennes.d(#w)
uneMoyenne.d
*p = @tamp(0)
i.i=0
k.i
k = sf_read_float(audioData\file, *p, nAlire); on a lu les 2 canaux gauches et droits
While k=nAlire
  ;     Debug Str(i)+"   "+Str(nAlire)+"   "+Str(k)
  uneMoyenne=0
  For m = 0 To nAlire - 1
    uneMoyenne + Abs(PeekF(*p + (m) * SizeOf(Float)))
  Next m
  uneMoyenne/nAlire
  moyennes(i)=uneMoyenne
  k = sf_read_float(audioData\file, *p, nAlire)
  i+1
Wend

; trouver le max
max.d=moyennes(0)
For i = 0 To #w-1
  If max < moyennes(i)
    max = moyennes(i)
  EndIf
Next i
;normaliser
For i = 0 To #w-1
  moyennes(i) / max
  moyennes(i) * #h
Next i



OpenWindow(0, 100, 100, #w, #h, "2D Drawing Test")

Global monCanva
monCanva = CanvasGadget(#PB_Any, 0, 0, DesktopScaledX(#w), DesktopScaledY(#h))

Debug "monCanva  : "+Str(monCanva) 

Procedure dessine(canva.i, x.l, Array moyennes.d(1)); 1 pOUR VECTEUR !!!
  StartDrawing(CanvasOutput(canva))
  Box(0, 0, OutputWidth(), OutputHeight(), $FFFFFF) ; efface en blanc
  For i = 0 To #w-1
    LineXY(i, #h, i, #h-moyennes(i), RGB(0, 152, 0))
  Next i
  
  ; tracer la barre de position
  For i = 0 To 5
    LineXY(x+i, #h, x+i, 0, RGB(0, 0, 0))
  Next i
  StopDrawing()
  ProcedureReturn 0
EndProcedure

dessine(monCanva, 10, moyennes())

sf_seek(audioData\file, 0, #SEEK_SET);


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


If Pa_Initialize() <> 0
  MessageRequester("Erreur", "Erreur initialisation PortAudio")
  sf_close(audioData\file)
  End
EndIf

Define *stream

If Pa_OpenDefaultStream(@*stream, 0, audioData\info\channels, #paFloat32, audioData\info\samplerate, #FRAMES_PER_BUFFER, @audio_callback(), @audioData) <> 0
  MessageRequester("Erreur", "Erreur ouverture flux audio")
  Pa_Terminate()
  sf_close(audioData\file)
  End
EndIf

If Pa_StartStream(*stream) <> 0
  MessageRequester("Erreur", "Erreur démarrage flux")
  Pa_CloseStream(*stream)
  Pa_Terminate()
  sf_close(audioData\file)
  End
EndIf
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Debug("Fichier WAV '" + GetFilePart(filename) + "' ouvert avec succès.")
; Debug("Fréquence d'échantillonnage : " + Str(audioData\info\samplerate) + " Hz")
; Debug("Canaux : " + Str(audioData\info\channels))
; Debug("Nombre total de frames : " + Str(audioData\info\frames))

; AddWindowTimer(0, 0, 10) ; Timeout = 10 ms

Global lastTime = ElapsedMilliseconds()
Repeat
  Event = WaitWindowEvent(10)
  
  Select Event
    Case #PB_Event_Gadget
      Select EventGadget()
        Case monCanva ; Canvas gauche
          If EventType() = #PB_EventType_LeftClick
            x = GetGadgetAttribute(monCanva, #PB_Canvas_MouseX)
            y = GetGadgetAttribute(monCanva, #PB_Canvas_MouseY)
            pourc.f = x / #w
            pourc.f * audioData\info\frames
            pos.i = Int(pourc)
            sf_seek(audioData\file, pos, #SEEK_SET)
;             Debug pourc
;             Debug "Clic sur gauche: X=" + Str(x) + " Y=" + Str(y)
            
          EndIf
      EndSelect
  EndSelect
  
  pos.i = sf_seek(audioData\file, 0, #SEEK_CUR);
  pourc.f = pos / audioData\info\frames * 1.0
  pos=Int(pourc*#w)
  
  res.i=dessine(monCanva, pos, moyennes()); bug avec 10 donc en bas
  
;   ; refaire le graphique
;   StartDrawing(CanvasOutput(monCanva))
;   Box(0, 0, OutputWidth(), OutputHeight(), $FFFFFF) ; efface en blanc
;   For i = 0 To #w-1
;     LineXY(i, #h, i, #h-moyennes(i), RGB(0, 152, 0))
;   Next i
;   
;   ; tracer la barre de position
;   For i = 0 To 5
;     LineXY(pos+i, #h, pos+i, 0, RGB(0, 0, 0))
;   Next i
;   StopDrawing()
  
  If ElapsedMilliseconds() - lastTime >= 1000
    lastTime = ElapsedMilliseconds()
    ;     Debug "Événement déclenché à " + FormatDate("%hh:%ii:%ss", Date())
    ;     Debug even
    ;     Debug #PB_Event_CloseWindow
  EndIf
Until Event = #PB_Event_CloseWindow  ; If the user has pressed on the window close button



; === Boucle lecture audio ===
; Repeat
;   Pa_Sleep(10)
; ForEver

; === Nettoyage ===
Pa_StopStream(*stream)
Pa_CloseStream(*stream)
Pa_Terminate()
sf_close(audioData\file)

; Debug("Fichier WAV fermé.")


; Else
;   MessageRequester("Erreur", "Impossible d'ouvrir la console.")

; CloseConsole()

End
; IDE Options = PureBasic 6.21 - C Backend (MacOS X - arm64)
; CursorPosition = 326
; FirstLine = 289
; Folding = -
; Optimizer
; EnableXP
; DPIAware