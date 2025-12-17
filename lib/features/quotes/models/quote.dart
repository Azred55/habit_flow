class Quote {
  const Quote({
    required this.text,
    required this.author,
  });

  final String text;
  final String author;

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      text: (json['quote'] as String?)?.trim().isNotEmpty == true
          ? (json['quote'] as String).trim()
          : 'Bleib dran – jeder Tag zählt!',
      author: (json['author'] as String?)?.trim().isNotEmpty == true
          ? (json['author'] as String).trim()
          : 'Unbekannt',
    );
  }
}
