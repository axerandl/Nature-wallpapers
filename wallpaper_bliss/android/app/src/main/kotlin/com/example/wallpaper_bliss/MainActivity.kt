package com.kuzalex.nature_wallpapers


import android.app.WallpaperManager
import android.content.Context
import android.content.Intent
import android.graphics.*
import android.graphics.Bitmap.CompressFormat
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.util.DisplayMetrics
import android.util.Log
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugins.GeneratedPluginRegistrant
import kotlinx.coroutines.*
import java.io.ByteArrayOutputStream
import java.io.File
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine
import kotlin.math.abs


class MainActivity: FlutterActivity() {
  private val coroutineScope = MainScope()

  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    GeneratedPluginRegistrant.registerWith(flutterEngine)

    MethodChannel(flutterEngine.getDartExecutor(), CHANNEL)
            .setMethodCallHandler { methodCall, result ->
              when (methodCall.method) {
                SET_WALLPAPER -> {
                  setWallpaper(
                          (methodCall.arguments as? List<*>)?.filterIsInstance<Any>(),
                          result
                  )
                }
                SET_LOCKSCREEN -> {
                  setLockScreen(
                          (methodCall.arguments as? List<*>)?.filterIsInstance<Any>(),
                          result
                  )
                }
                SCAN_FILE -> {
                  scanImageFile(
                          (methodCall.arguments as? List<*>)?.filterIsInstance<Any>(),
                          result
                  )
                }
                RESIZE_IMAGE -> {
                  resizeImage(
                          result,
                          methodCall.argument("bytes") as? ByteArray
                  )
                }
                else -> result.notImplemented()
              }
            }
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    super.onActivityResult(requestCode, resultCode, data)
  }

  override fun onDestroy() {
    super.onDestroy()
    coroutineScope.cancel()
  }

  private fun resizeImage(
          result: Result,
          bytes: ByteArray?
  ) {
    if (bytes == null) {
      return result.error("error", "bytes cannot be null", null)
    }

    val newHeight = WallpaperManager.getInstance(this@MainActivity).desiredMinimumWidth.coerceAtMost(WallpaperManager.getInstance(this@MainActivity).desiredMinimumHeight)
    Log.i(TAG, "New height: $newHeight")

    coroutineScope.launch {
      val byteArray = withContext(Dispatchers.IO) {
        ByteArrayOutputStream()
                .also {
                  getResizedBitmap(
                          BitmapFactory.decodeByteArray(bytes, 0, bytes.size),
                          newHeight
                  ).compress(CompressFormat.JPEG, 100, it)
                }
                .toByteArray()
      }
      result.success(byteArray)
    }
  }

  private fun getResizedBitmap(
          bm: Bitmap,
          newHeight: Int
  ): Bitmap {
    val metrics = DisplayMetrics()
    windowManager.defaultDisplay.getMetrics(metrics);

    val deviceWidth = metrics.widthPixels.coerceAtMost(metrics.heightPixels)
    val scale: Float = newHeight.toFloat() / bm.height
    val scaledWidth: Int = (scale * bm.width).toInt()
    val imageCenterWidth: Int = scaledWidth / 2
    val widthToCut = abs(imageCenterWidth - deviceWidth / 2)
    val leftWidth = scaledWidth - widthToCut

    Log.d(TAG, "deviceWidth: $deviceWidth scale: $scale scaleWidth: $scaledWidth imageCenterWidth: $imageCenterWidth widthToCut: $widthToCut leftWidth: $leftWidth")

    try {
      val scaledWallpaper:Bitmap = Bitmap.createScaledBitmap(bm, scaledWidth, newHeight, false)
      return Bitmap.createBitmap(scaledWallpaper, widthToCut,0, leftWidth, newHeight)
    } catch (e: Exception) {
      Log.i(TAG, "Resizing image error: ${e.message}")
    }

    return bm
  }

  private fun scanImageFile(imagePath: List<Any>?, result: Result) {
    if (imagePath == null) {
      return result.error("error", "Arguments must be a list and not null", null)
    }

    if (!isExternalStorageReadable) {
      return result.error("error", "External storage is unavailable", null)
    }

    val absolutePath = getExternalFilesDir(null)!!.absolutePath
    val imageFilePath = absolutePath + File.separator + joinPath(imagePath)
    Log.i(TAG, "Start scan: $imageFilePath")

    coroutineScope.launch {
      try {
        val (path, uri) = withContext(Dispatchers.IO) { scanFile(imageFilePath) }

        Log.i(TAG, "Scan result Path: $path")
        Log.i(TAG, "Scan result Uri: $uri")

        result.success("Scan completed")
      } catch (e: Exception) {
        Log.i(TAG, "Scan file error: $e")
        result.error("error", e.message, null)
      }
    }
  }

  private fun setWallpaper(path: List<Any>?, result: Result) {
    Log.i(TAG, "Setting wallpaper")
    try {
      if (path == null) {
        return result.error("error", "Arguments must be a list and not null", null)
      }

      if (!isExternalStorageReadable) {
        return result.error("error", "External storage is unavailable", null)
      }

      val absolutePath = getExternalFilesDir(null)!!.absolutePath
      val imageFilePath = absolutePath + File.separator + joinPath(path)

      coroutineScope.launch {
        withContext(Dispatchers.IO) {
          val bitmap = BitmapFactory.decodeFile(imageFilePath)
          val wallpaperManager = WallpaperManager.getInstance(this@MainActivity)
          wallpaperManager.setWallpaperOffsetSteps(1F, 1F)

          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_SYSTEM)
          } else {
            wallpaperManager.setBitmap(bitmap);
          }
        }
        result.success("Success!")
      }

    } catch (e: Exception) {
      result.error("error", e.message, null)
    }
  }

  @RequiresApi(Build.VERSION_CODES.N)
  private fun setLockScreen(path: List<Any>?, result: Result) {
    try {
      if (path == null) {
        return result.error("error", "Arguments must be a list and not null", null)
      }

      if (!isExternalStorageReadable) {
        return result.error("error", "External storage is unavailable", null)
      }

      val absolutePath = getExternalFilesDir(null)!!.absolutePath
      val imageFilePath = absolutePath + File.separator + joinPath(path)

      coroutineScope.launch {
        withContext(Dispatchers.IO) {
          val bitmap = BitmapFactory.decodeFile(imageFilePath)
          val wallpaperManager = WallpaperManager.getInstance(this@MainActivity)
          wallpaperManager.setWallpaperOffsetSteps(1F, 1F)

          val resInt = async { wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_LOCK) }
          val resStr: String?
          if (resInt.await() > 0) {
            resStr = "Success!"
          } else {
            resStr = null
          }
          Log.i(TAG, "Setting lockscreen image, res: $resStr")
          withContext(Dispatchers.Main) {
            result.success(resStr)
          }
        }
      }
    } catch (e: Exception) {
      result.error("error", e.message, null)
    }
  }

  companion object {
    const val CHANNEL = "wallpaper_bliss"
    const val SET_WALLPAPER = "setWallpaper"
    const val SET_LOCKSCREEN = "setLockScreen"
    const val SCAN_FILE = "scanFile"
    const val RESIZE_IMAGE = "resizeImage"
    const val TAG = "flutter"
  }
}

private fun joinPath(path: List<Any>) = path.joinToString(separator = File.separator)

/**
 * Checks if external storage is available to at least read
 */
private val isExternalStorageReadable
  get() = Environment.getExternalStorageState().let { state ->
    Environment.MEDIA_MOUNTED == state || Environment.MEDIA_MOUNTED_READ_ONLY == state
  }


private suspend fun Context.scanFile(imageFilePath: String): Pair<String?, Uri?> {
  return suspendCoroutine { continuation ->
    MediaScannerConnection.scanFile(
      this,
      arrayOf(imageFilePath),
      null
    ) { path, uri ->
      continuation.resume(path to uri)
    }
  }
}
