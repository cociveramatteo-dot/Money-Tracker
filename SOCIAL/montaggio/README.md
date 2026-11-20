# Master social Bucktrail

> Per il formato editoriale leggere le [direttive social](../direttive-social.md). Qui si documenta l’uso dello script di montaggio.

Serve FFmpeg con libass, libx264 e ffprobe. La conversione HDR richiede anche zscale. Su macOS, `brew install ffmpeg-full`. Lo script rileva la formula Homebrew oppure usa i binari nel PATH. Per percorsi diversi, imposta `FFMPEG_BIN` e `FFPROBE_BIN`.

Dalla radice del repository, con la clip nella cartella `SOCIAL/clip-social/`:

```bash
SOCIAL/montaggio/master.sh ripresa.mov SOCIAL/montaggio/modello.ass SOCIAL/clip-social/master.mp4 0:3 3:7:2 7:12
SOCIAL/montaggio/test-fumo.sh
```

Gli intervalli sono secondi della sorgente. Lo script concatena i tratti nell’ordine indicato con tagli netti. Il suffisso `:2` accelera solo quel tratto a 2×. Senza intervalli usa tutta la clip. I tempi dei sottotitoli seguono il master dopo i tagli. Per conservare voce ed effetti, aggiungi `--keep-audio` prima degli intervalli e usa una clip con audio privo di musica. Di base il master è muto.

Un SRT usa lo stile Inter per tutti i sottotitoli. Per titoli in Space Grotesk Bold, colori sulle singole parole e firma della curva, copia [modello.ass](modello.ass) e modifica le righe `Dialogue`. I tag ASS verde e ambra sono nel modello. Tieni 3–5 parole per riga, fino a due righe, e lascia almeno 1,5 s per riga. Controlla in anteprima che tutte le scritte rientrino in x 120–900 e y 280–1250. Il filtro ritaglia eventuali elementi ASS che sconfinano.

Per F1 registra la curva e passa da campo largo a dettaglio con un taglio. Per F4 filma su iPhone il tocco posteriore, accelera l’inserimento e lascia a 1× l’aggiornamento della curva. Usa clip sorgenti prive di watermark. Il master è MP4 H.264 a 1080×1920, 30 fps, SDR Rec.709, con bitrate target di 16 Mbps. Il test genera clip e master temporanei e li elimina al termine.
