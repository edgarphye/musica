package com.musica.musica

import android.app.Activity
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

class SafHelper(private val activity: Activity) {
    private var pendingResult: MethodChannel.Result? = null

    private val getTreeLauncher = (activity as MainActivity)
        .treeLauncher

    fun onTreePicked(uri: Uri?) {
        val result = pendingResult ?: return
        pendingResult = null
        if (uri == null) {
            result.success(null)
            return
        }
        val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
        try {
            activity.contentResolver.takePersistableUriPermission(uri, flags)
        } catch (_: SecurityException) {
            // sin permiso persistente: seguimos mientras la sesión dure
        }
        val name = queryDisplayName(uri) ?: "Memoria USB"
        result.success(mapOf("uri" to uri.toString(), "name" to name))
    }

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickDirectory" -> {
                pendingResult = result
                getTreeLauncher.launch(Intent(Intent.ACTION_OPEN_DOCUMENT_TREE))
            }
            "listChildren" -> {
                val treeUri = Uri.parse(call.argument<String>("uri"))
                val parentRel = call.argument<String>("parentRelative") ?: ""
                result.success(listChildren(treeUri, parentRel))
            }
            "writeFromPath" -> {
                val treeUri = Uri.parse(call.argument<String>("treeUri"))
                val relPath = call.argument<String>("relativePath") ?: ""
                val sourcePath = call.argument<String>("sourcePath") ?: ""
                result.success(writeFromPath(treeUri, relPath, sourcePath))
            }
            "exists" -> {
                val treeUri = Uri.parse(call.argument<String>("treeUri"))
                val relPath = call.argument<String>("relativePath") ?: ""
                result.success(exists(treeUri, relPath))
            }
            "copyToCache" -> {
                val uri = Uri.parse(call.argument<String>("uri"))
                result.success(copyToCache(uri))
            }
            "deleteCached" -> {
                val path = call.argument<String>("path") ?: ""
                val ok = File(path).delete()
                result.success(ok)
            }
            else -> result.notImplemented()
        }
    }

    // ---- tree / children helpers ----

    private fun treeRootDocId(treeUri: Uri): String =
        DocumentsContract.getTreeDocumentId(treeUri)

    private fun childrenQuery(treeUri: Uri): Uri =
        DocumentsContract.buildChildDocumentsUriUsingTree(
            treeUri,
            treeRootDocId(treeUri)
        )

    private fun docUri(treeUri: Uri, docId: String): Uri =
        DocumentsContract.buildDocumentUriUsingTree(treeUri, docId)

    private fun queryDisplayName(uri: Uri): String? {
        val cursor: Cursor? = activity.contentResolver.query(
            uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null
        )
        cursor?.use {
            if (it.moveToFirst()) return it.getString(0)
        }
        return null
    }

    private fun listChildren(treeUri: Uri, parentRelative: String): List<Map<String, Any?>> {
        val out = mutableListOf<Map<String, Any?>>()
        val rootId = treeRootDocId(treeUri)
        val queryUri = buildChildDocumentsUriUsingTree(treeUri, rootId)

        // Recorremos la ruta relativa para llegar al directorio padre.
        var currentChildQuery = queryUri
        var currentDirUri = treeUri
        if (parentRelative.isNotEmpty()) {
            val parts = parentRelative.split("/").filter { it.isNotEmpty() }
            var found = true
            for (part in parts) {
                val child = findChild(treeUri, currentDirUri, part)
                if (child == null) {
                    found = false
                    break
                }
                currentDirUri = child
                val docId = DocumentsContract.getDocumentId(currentDirUri)
                currentChildQuery = DocumentsContract.buildChildDocumentsUriUsingTree(
                    treeUri, docId
                )
            }
            if (!found) return out
        }

        val cursor: Cursor? = activity.contentResolver.query(
            currentChildQuery, null, null, null, null
        )
        cursor?.use {
            while (it.moveToNext()) {
                val docId = it.getString(it.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID))
                val name = it.getString(it.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME))
                val mime = it.getString(it.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_MIME_TYPE))
                val isDir = it.getInt(it.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_FLAGS)) and
                    DocumentsContract.Document.FLAG_DIRECTORY != 0
                val childUri = buildDocumentUriUsingTree(treeUri, docId)
                out.add(
                    mapOf(
                        "name" to name,
                        "uri" to childUri.toString(),
                        "isDirectory" to isDir,
                        "size" to if (isDir) 0L else querySize(childUri),
                        "mime" to (mime ?: ""),
                        "relativePath" to if (parentRelative.isEmpty()) name else "$parentRelative/$name"
                    )
                )
            }
        }
        return out
    }

    private fun findChild(treeUri: Uri, parentDirUri: Uri, name: String): Uri? {
        val parentDocId = DocumentsContract.getDocumentId(parentDirUri)
        val queryUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, parentDocId)
        val cursor: Cursor? = activity.contentResolver.query(
            queryUri, null, null, null, null
        )
        cursor?.use {
            while (it.moveToNext()) {
                val display = it.getString(it.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME))
                if (display == name) {
                    val docId = it.getString(it.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID))
                    return buildDocumentUriUsingTree(treeUri, docId)
                }
            }
        }
        return null
    }

    private fun querySize(uri: Uri): Long {
        val cursor: Cursor? = activity.contentResolver.query(
            uri, arrayOf(OpenableColumns.SIZE), null, null, null
        )
        cursor?.use {
            if (it.moveToFirst()) {
                val idx = it.getColumnIndex(OpenableColumns.SIZE)
                if (idx >= 0 && !it.isNull(idx)) return it.getLong(idx)
            }
        }
        return 0L
    }

    private fun exists(treeUri: Uri, relativePath: String): Boolean {
        val parts = relativePath.split("/").filter { it.isNotEmpty() }
        if (parts.isEmpty()) return true
        var currentDir = treeUri
        for ((i, part) in parts.withIndex()) {
            val child = findChild(treeUri, currentDir, part)
            if (child == null) return false
            currentDir = child
        }
        return true
    }

    private fun writeFromPath(treeUri: Uri, relativePath: String, sourcePath: String): Boolean {
        val parts = relativePath.split("/").filter { it.isNotEmpty() }
        if (parts.isEmpty()) return false
        var currentParent = treeUri
        // crea/encuentra directorios
        for (i in 0 until parts.size - 1) {
            val dirName = parts[i]
            val existing = findChild(treeUri, currentParent, dirName)
            currentParent = if (existing != null) {
                existing
            } else {
                DocumentsContract.createDocument(
                    activity.contentResolver,
                    currentParent,
                    DocumentsContract.Document.MIME_TYPE_DIR,
                    dirName
                ) ?: return false
            }
        }
        val fileName = parts.last()
        val existingFile = findChild(treeUri, currentParent, fileName)
        val fileUri = if (existingFile != null) {
            existingFile
        } else {
            DocumentsContract.createDocument(
                activity.contentResolver,
                currentParent,
                "application/octet-stream",
                fileName
            ) ?: return false
        }
        return copyBytes(sourcePath, fileUri)
    }

    private fun copyBytes(sourcePath: String, destUri: Uri): Boolean {
        return try {
            activity.contentResolver.openOutputStream(destUri)?.use { out ->
                FileInputStream(File(sourcePath)).use { inp ->
                    val buffer = ByteArray(8192)
                    var read = inp.read(buffer)
                    while (read != -1) {
                        out.write(buffer, 0, read)
                        read = inp.read(buffer)
                    }
                }
            } ?: return false
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun copyToCache(uri: Uri): String? {
        return try {
            val name = queryDisplayName(uri) ?: "archivo.bin"
            val cacheDir = File(activity.cacheDir, "saf_read")
            if (!cacheDir.exists()) cacheDir.mkdirs()
            val target = File(cacheDir, name)
            activity.contentResolver.openInputStream(uri)?.use { inp ->
                FileOutputStream(target).use { out ->
                    val buffer = ByteArray(8192)
                    var read = inp.read(buffer)
                    while (read != -1) {
                        out.write(buffer, 0, read)
                        read = inp.read(buffer)
                    }
                }
            } ?: return null
            target.absolutePath
        } catch (_: Exception) {
            null
        }
    }
}