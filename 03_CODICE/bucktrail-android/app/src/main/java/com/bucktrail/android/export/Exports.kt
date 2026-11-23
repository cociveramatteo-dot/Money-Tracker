package com.bucktrail.android.export

import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.pdf.PdfDocument
import android.os.Build
import androidx.core.content.FileProvider
import com.bucktrail.android.domain.PdfReport
import java.io.File

/** File temporanei di esportazione (cache privata) e condivisione col foglio di sistema (`FileProvider` + `ACTION_SEND`). */
object ShareFiles {
    private fun dir(context: Context) = File(context.cacheDir, "exports").apply { mkdirs() }

    fun target(context: Context, name: String): File = File(dir(context), name)

    fun write(context: Context, name: String, bytes: ByteArray): File = target(context, name).also { it.writeBytes(bytes) }

    fun clear(context: Context) { File(context.cacheDir, "exports").deleteRecursively() }

    fun share(context: Context, file: File, mime: String) {
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
        val send = Intent(Intent.ACTION_SEND).setType(mime).putExtra(Intent.EXTRA_STREAM, uri).putExtra(Intent.EXTRA_TITLE, file.name)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        send.clipData = ClipData.newRawUri(file.name, uri)
        val chooser = Intent.createChooser(send, file.name).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        if (context !is android.app.Activity) chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(chooser)
    }
}

/** Stampa l'impaginazione di `PdfReport` su un `PdfDocument` (A4, font di sistema, colori neutri come iOS). */
object PdfRenderer {
    private const val INK = 0xFF121212.toInt()
    private const val SMOKE = 0xFF878787.toInt()
    private const val FOG = 0xFFE0E0E0.toInt()

    private fun tone(t: PdfReport.Tone) = when (t) { PdfReport.Tone.Ink -> INK; PdfReport.Tone.Smoke -> SMOKE; PdfReport.Tone.Fog -> FOG }

    private fun typeface(w: PdfReport.Weight): Typeface {
        val weight = when (w) { PdfReport.Weight.Regular -> 400; PdfReport.Weight.Medium -> 500; PdfReport.Weight.Semibold -> 600; PdfReport.Weight.Black -> 900 }
        return if (Build.VERSION.SDK_INT >= 28) Typeface.create(Typeface.DEFAULT, weight, false)
        else Typeface.create(Typeface.DEFAULT, if (weight >= 600) Typeface.BOLD else Typeface.NORMAL)
    }

    private fun fit(paint: Paint, text: String, maxWidth: Float?): String {
        if (maxWidth == null || paint.measureText(text) <= maxWidth) return text
        var end = text.length
        while (end > 0 && paint.measureText(text.substring(0, end) + "…") > maxWidth) end--
        return text.substring(0, end) + "…"
    }

    fun write(pages: List<List<PdfReport.Op>>, target: File) {
        val doc = PdfDocument()
        try {
            pages.forEachIndexed { index, ops ->
                val page = doc.startPage(PdfDocument.PageInfo.Builder(Math.round(PdfReport.PAGE_W), Math.round(PdfReport.PAGE_H), index + 1).create())
                val canvas = page.canvas
                val paint = Paint(Paint.ANTI_ALIAS_FLAG)
                for (op in ops) when (op) {
                    is PdfReport.Text -> {
                        paint.reset(); paint.isAntiAlias = true
                        paint.typeface = typeface(op.weight); paint.textSize = op.size; paint.color = tone(op.tone)
                        paint.letterSpacing = if (op.kern != 0f) op.kern / op.size else 0f
                        paint.textAlign = if (op.alignRight) Paint.Align.RIGHT else Paint.Align.LEFT
                        canvas.drawText(fit(paint, op.text, op.maxWidth), op.x, op.y - paint.ascent(), paint)
                    }
                    is PdfReport.Line -> { paint.reset(); paint.color = FOG; paint.strokeWidth = 0.5f; canvas.drawLine(PdfReport.MARGIN, op.y, PdfReport.PAGE_W - PdfReport.MARGIN, op.y, paint) }
                    is PdfReport.Bar -> { paint.reset(); paint.color = tone(op.tone); canvas.drawRect(op.x, op.y, op.x + op.w, op.y + op.h, paint) }
                }
                doc.finishPage(page)
            }
            target.outputStream().use { doc.writeTo(it) }
        } finally { doc.close() }
    }
}
