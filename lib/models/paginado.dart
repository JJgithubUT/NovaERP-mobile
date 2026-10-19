/// Sobre de paginacion que devuelven todos los listados del backend:
/// `{count, page, page_size, num_pages, results}`.
class Paginado<T> {
  final int total;
  final int pagina;
  final int tamanoPagina;
  final int numeroPaginas;
  final List<T> elementos;

  const Paginado({
    required this.total,
    required this.pagina,
    required this.tamanoPagina,
    required this.numeroPaginas,
    required this.elementos,
  });

  factory Paginado.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) desdeJson,
  ) {
    return Paginado(
      total: (json['count'] as num?)?.toInt() ?? 0,
      pagina: (json['page'] as num?)?.toInt() ?? 1,
      tamanoPagina: (json['page_size'] as num?)?.toInt() ?? 20,
      numeroPaginas: (json['num_pages'] as num?)?.toInt() ?? 1,
      elementos: (json['results'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => desdeJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  bool get hayMasPaginas => pagina < numeroPaginas;
}
