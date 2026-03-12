class DigestItem {
  DigestItem({
    required this.id,
    required this.date,
    required this.lang,
    required this.title,
    required this.url,
    this.markdown,
  });

  final String id;
  final String date;
  final String lang;
  final String title;
  final String url;
  final String? markdown;

  DigestItem copyWith({String? markdown, String? url}) {
    return DigestItem(
      id: id,
      date: date,
      lang: lang,
      title: title,
      url: url ?? this.url,
      markdown: markdown ?? this.markdown,
    );
  }

  factory DigestItem.fromJson(Map<String, dynamic> json) {
    return DigestItem(
      id: json['id'] as String,
      date: json['date'] as String,
      lang: json['lang'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      markdown: json['markdown'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'lang': lang,
      'title': title,
      'url': url,
      'markdown': markdown,
    };
  }
}
