class Folder {
  const Folder({required this.id, required this.name});

  final String id;
  final String name;

  @override
  String toString() => name;
}