import '../domain/audio_file.dart';
import '../domain/folder.dart';

/// Puerto de acceso al sistema de archivos.
///
/// Existen dos implementaciones:
/// - [DesktopFilesystem] para Windows/Linux (rutas nativas).
/// - [AndroidSafFilesystem] para Android (Storage Access Framework, USB-OTG).
abstract class FilesystemGateway {
  /// Pide al usuario elegir el directorio origen (memoria USB, carpeta...).
  /// Devuelve `null` si el usuario cancela.
  Future<Folder?> pickSourceDirectory();

  /// Pide al usuario elegir el directorio destino de los convertidos.
  Future<Folder?> pickDestinationDirectory();

  /// Escanea [folder] recursivamente y devuelve los archivos de audio.
  Future<List<AudioFile>> scanAudioFiles(Folder folder);

  /// Argumento de entrada que FFmpeg debe usar para [file] (path o content://).
  String inputArgument(AudioFile file);

  /// Devuelve la ruta donde FFmpeg escribirá el resultado para
  /// [relativePath] (ruta relativa al destino). En desktop es el destino real;
  /// en Android un archivo temporal en caché.
  Future<String> outputPathFor(Folder destination, String relativePath);

  /// Confirma el resultado: mueve [scratchPath] a su ubicación final
  /// (desktop) o lo copia al árbol SAF (Android).
  Future<void> commitOutput(
    Folder destination,
    String relativePath,
    String scratchPath,
  );

  /// Comprueba si [relativePath] ya existe en [destination].
  Future<bool> outputExists(Folder destination, String relativePath);

  /// Elimina un archivo temporal o parcial.
  Future<void> deleteFile(String path);
}