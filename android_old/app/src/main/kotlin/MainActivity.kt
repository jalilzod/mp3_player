// Put this in android/app/src/main/kotlin/<your/package/path>/MainActivity.kt
// (replace the existing file there — do NOT keep two MainActivity files).
// KEEP your own `package ...` line from the original file.

package com.example.music_player // <-- keep YOUR package name

import android.content.ContentUris
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.util.Size
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

/**
 * AudioServiceActivity = FlutterActivity + background audio support.
 * Also exposes a small MediaStore channel so we don't need an outdated plugin
 * to list songs and load their artwork.
 */
class MainActivity : AudioServiceActivity() {

    private val executor = Executors.newFixedThreadPool(2)
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "music_player/media_store")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "querySongs" -> executor.execute {
                        try {
                            val songs = querySongs()
                            mainHandler.post { result.success(songs) }
                        } catch (e: Exception) {
                            mainHandler.post { result.error("QUERY_FAILED", e.message, null) }
                        }
                    }

                    "getArtwork" -> {
                        val id = call.argument<Number>("id")?.toLong()
                        val albumId = call.argument<Number>("albumId")?.toLong()
                        val size = call.argument<Number>("size")?.toInt() ?: 300
                        if (id == null) {
                            result.success(null)
                        } else {
                            executor.execute {
                                val bytes = try {
                                    loadArtwork(id, albumId, size)
                                } catch (e: Exception) {
                                    null
                                }
                                mainHandler.post { result.success(bytes) }
                            }
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun querySongs(): List<Map<String, Any?>> {
        val collection: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
        } else {
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        }

        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.AudioColumns.DURATION,
            MediaStore.Audio.Media.DATE_ADDED,
            MediaStore.Audio.Media.DISPLAY_NAME,
        )
        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"
        val sortOrder = "${MediaStore.Audio.Media.TITLE} COLLATE NOCASE ASC"

        val songs = mutableListOf<Map<String, Any?>>()
        contentResolver.query(collection, projection, selection, null, sortOrder)?.use { c ->
            val idCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val albumCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val albumIdCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)
            val durationCol = c.getColumnIndexOrThrow(MediaStore.Audio.AudioColumns.DURATION)
            val dateCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_ADDED)
            val nameCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DISPLAY_NAME)

            while (c.moveToNext()) {
                val id = c.getLong(idCol)
                val uri = ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id)
                songs.add(
                    mapOf(
                        "id" to id,
                        "title" to (c.getString(titleCol) ?: c.getString(nameCol)),
                        "artist" to c.getString(artistCol),
                        "album" to c.getString(albumCol),
                        "albumId" to c.getLong(albumIdCol),
                        "duration" to c.getLong(durationCol),
                        "dateAdded" to c.getLong(dateCol),
                        "uri" to uri.toString(),
                    )
                )
            }
        }
        return songs
    }

    private fun loadArtwork(id: Long, albumId: Long?, size: Int): ByteArray? {
        val bitmap: Bitmap? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val uri = ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id)
            try {
                contentResolver.loadThumbnail(uri, Size(size, size), null)
            } catch (e: Exception) {
                null
            }
        } else if (albumId != null) {
            val uri = ContentUris.withAppendedId(
                Uri.parse("content://media/external/audio/albumart"), albumId
            )
            try {
                contentResolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it) }
            } catch (e: Exception) {
                null
            }
        } else {
            null
        }

        bitmap ?: return null
        val out = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 90, out)
        return out.toByteArray()
    }
}