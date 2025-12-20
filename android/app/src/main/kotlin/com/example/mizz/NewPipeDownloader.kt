package com.example.mizz

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import org.schabi.newpipe.extractor.NewPipe
import org.schabi.newpipe.extractor.ServiceList
import org.schabi.newpipe.extractor.stream.StreamInfoItem
import org.schabi.newpipe.extractor.downloader.Downloader
import org.schabi.newpipe.extractor.downloader.Request
import org.schabi.newpipe.extractor.downloader.Response
import org.schabi.newpipe.extractor.exceptions.ReCaptchaException
import okhttp3.OkHttpClient
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.TimeUnit

// Custom Downloader implementation using OkHttp
class OkHttpDownloader : Downloader() {
    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .followRedirects(true)
        .build()
    
    override fun execute(request: Request): Response {
        val url = request.url()
        val headers = request.headers()
        val dataToSend = request.dataToSend()
        
        val requestBuilder = okhttp3.Request.Builder()
            .url(url)
        
        // Add headers
        headers.forEach { (key, values) ->
            values.forEach { value ->
                requestBuilder.addHeader(key, value)
            }
        }
        
        // Set method and body
        if (dataToSend != null && dataToSend.isNotEmpty()) {
            requestBuilder.post(dataToSend.toRequestBody())
        } else {
            requestBuilder.get()
        }
        
        val response = client.newCall(requestBuilder.build()).execute()
        
        val responseHeaders = mutableMapOf<String, List<String>>()
        response.headers.names().forEach { name ->
            responseHeaders[name] = response.headers.values(name)
        }
        
        return Response(
            response.code,
            response.message,
            responseHeaders,
            response.body?.string(),
            response.request.url.toString()
        )
    }
}

class NewPipeDownloader {
    
    companion object {
        private var isInitialized = false
        
        fun initialize() {
            if (!isInitialized) {
                NewPipe.init(OkHttpDownloader())
                isInitialized = true
            }
        }
        
        fun downloadAudio(
            videoUrl: String,
            outputPath: String,
            onProgress: (Int) -> Unit,
            onComplete: (String) -> Unit,
            onError: (String) -> Unit
        ) {
            CoroutineScope(Dispatchers.IO).launch {
                try {
                    // Initialize if needed
                    initialize()
                    
                    // Extract video info
                    val service = ServiceList.YouTube
                    val extractor = service.getStreamExtractor(videoUrl)
                    extractor.fetchPage()
                    
                    val title = extractor.name
                    val audioStreams = extractor.audioStreams
                    
                    if (audioStreams.isEmpty()) {
                        withContext(Dispatchers.Main) {
                            onError("No audio streams found")
                        }
                        return@launch
                    }
                    
                    // Get best audio stream (prefer webm/opus)
                    val bestAudio = audioStreams
                        .filter { it.format?.mimeType?.contains("webm") == true }
                        .maxByOrNull { it.averageBitrate } 
                        ?: audioStreams.maxByOrNull { it.averageBitrate }
                    
                    if (bestAudio == null) {
                        withContext(Dispatchers.Main) {
                            onError("No suitable audio stream")
                        }
                        return@launch
                    }
                    
                    val audioUrl = bestAudio.url ?: bestAudio.content
                    
                    // Download the file
                    val outputFile = File(outputPath)
                    outputFile.parentFile?.mkdirs()
                    
                    val connection = URL(audioUrl).openConnection() as HttpURLConnection
                    connection.requestMethod = "GET"
                    connection.setRequestProperty("User-Agent", "Mozilla/5.0")
                    connection.connect()
                    
                    val totalSize = connection.contentLength
                    val inputStream = connection.inputStream
                    val outputStream = FileOutputStream(outputFile)
                    
                    val buffer = ByteArray(8192)
                    var downloaded = 0
                    var lastProgress = 0
                    
                    var bytesRead: Int
                    while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                        outputStream.write(buffer, 0, bytesRead)
                        downloaded += bytesRead
                        
                        if (totalSize > 0) {
                            val progress = (downloaded * 100 / totalSize)
                            if (progress != lastProgress && progress % 5 == 0) {
                                lastProgress = progress
                                withContext(Dispatchers.Main) {
                                    onProgress(progress)
                                }
                            }
                        }
                    }
                    
                    outputStream.flush()
                    outputStream.close()
                    inputStream.close()
                    
                    withContext(Dispatchers.Main) {
                        onProgress(100)
                        onComplete(outputFile.absolutePath)
                    }
                    
                } catch (e: Exception) {
                    withContext(Dispatchers.Main) {
                        onError("Download failed: ${e.message}")
                    }
                }
            }
        }
        
        fun getVideoInfo(
            videoUrl: String,
            onSuccess: (Map<String, Any>) -> Unit,
            onError: (String) -> Unit
        ) {
            CoroutineScope(Dispatchers.IO).launch {
                try {
                    initialize()
                    
                    val service = ServiceList.YouTube
                    val extractor = service.getStreamExtractor(videoUrl)
                    extractor.fetchPage()
                    
                    val info = mapOf(
                        "title" to extractor.name,
                        "duration" to extractor.length,
                        "uploader" to extractor.uploaderName,
                        "thumbnail" to extractor.thumbnails.lastOrNull()?.url.orEmpty(),
                        "description" to (extractor.description?.content ?: "")
                    )
                    
                    withContext(Dispatchers.Main) {
                        onSuccess(info)
                    }
                    
                } catch (e: Exception) {
                    withContext(Dispatchers.Main) {
                        onError("Failed to get info: ${e.message}")
                    }
                }
            }
        }
    }
}
