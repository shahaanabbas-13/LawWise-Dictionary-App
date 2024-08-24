import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LawWise',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ArticleListScreen(),
    );
  }
}

class ArticleListScreen extends StatefulWidget {
  @override
  _ArticleListScreenState createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends State<ArticleListScreen> {
  List<dynamic> articles = [];
  List<dynamic> filteredArticles = [];
  Set<String> savedArticleNumbers = Set<String>();

  @override
  void initState() {
    super.initState();
    loadJsonData();
    loadSavedArticles();
  }

  Future<void> loadJsonData() async {
    final data = await json.decode(constitution);
    setState(() {
      articles = data;
      filteredArticles = articles;
    });
  }

  Future<void> loadSavedArticles() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedArticleNumbersList =
        prefs.getStringList('savedArticles');
    setState(() {
      savedArticleNumbers = savedArticleNumbersList != null
          ? savedArticleNumbersList.toSet()
          : Set<String>();
    });
  }

  void filterSearchResults(String query) {
    if (query.isNotEmpty) {
      List<dynamic> dummyListData = [];
      for (var item in articles) {
        if (item['title']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            item['article'].toString().contains(query) ||
            item['description']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase())) {
          dummyListData.add(item);
        }
      }
      setState(() {
        filteredArticles = dummyListData;
      });
    } else {
      setState(() {
        filteredArticles = articles;
      });
    }
  }

  void toggleBookmark(String articleNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedArticleNumbersList =
        prefs.getStringList('savedArticles');
    List<String> updatedList = savedArticleNumbersList != null
        ? List.from(savedArticleNumbersList)
        : [];

    if (savedArticleNumbers.contains(articleNumber)) {
      updatedList.remove(articleNumber);
      savedArticleNumbers.remove(articleNumber);
    } else {
      updatedList.add(articleNumber);
      savedArticleNumbers.add(articleNumber);
    }

    await prefs.setStringList('savedArticles', updatedList);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LawWise'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: const Text(
                'Navigation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('Saved'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SavedArticlesScreen(
                      articles: articles,
                      onToggleBookmark: toggleBookmark,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                filterSearchResults(value);
              },
              decoration: const InputDecoration(
                labelText: "Search",
                hintText: "Search by Article Number, Title, or Description",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredArticles.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "Article ${filteredArticles[index]['article']}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          filteredArticles[index]['title'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArticleDetailScreen(
                            article: filteredArticles[index],
                            articles: articles,
                            savedArticleNumbers: savedArticleNumbers,
                            onToggleBookmark: toggleBookmark,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ArticleDetailScreen extends StatefulWidget {
  final dynamic article;
  final List<dynamic> articles;
  final Set<String> savedArticleNumbers;
  final Function(String) onToggleBookmark;

  const ArticleDetailScreen({
    required this.article,
    required this.articles,
    required this.savedArticleNumbers,
    required this.onToggleBookmark,
  });

  @override
  _ArticleDetailScreenState createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late bool isBookmarked;
  late List<dynamic> randomArticles;

  @override
  void initState() {
    super.initState();
    isBookmarked = widget.savedArticleNumbers
        .contains(widget.article['article'].toString());
    randomArticles = getRandomArticles();
  }

  List<dynamic> getRandomArticles() {
    List<dynamic> allArticles = List.from(widget.articles);
    allArticles.removeWhere((art) =>
        art['article'].toString() == widget.article['article'].toString());
    allArticles.shuffle();
    return allArticles.take(5).toList();
  }

  void _toggleBookmark() {
    widget.onToggleBookmark(widget.article['article'].toString());
    setState(() {
      isBookmarked = !isBookmarked;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> relatedArticles = widget.articles
        .where((art) {
          String currentArticleNumber = widget.article['article'].toString();
          String artArticleNumber = art['article'].toString();
          return artArticleNumber.startsWith(currentArticleNumber) &&
              artArticleNumber != currentArticleNumber;
        })
        .take(5)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Article ${widget.article['article']}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "Article ${widget.article['article']}, ${widget.article['title']}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              widget.article['description'],
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (relatedArticles.isNotEmpty) ...[
              const Text(
                "Related Articles",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: relatedArticles.map((relatedArticle) {
                  return ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArticleDetailScreen(
                            article: relatedArticle,
                            articles: widget.articles,
                            savedArticleNumbers: widget.savedArticleNumbers,
                            onToggleBookmark: widget.onToggleBookmark,
                          ),
                        ),
                      );
                    },
                    child: Text("${relatedArticle['article']}"),
                  );
                }).toList(),
              ),
            ],
            if (relatedArticles.isEmpty) ...[
              const Text(
                "Other Articles:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: randomArticles.map((randomArticle) {
                  return ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArticleDetailScreen(
                            article: randomArticle,
                            articles: widget.articles,
                            savedArticleNumbers: widget.savedArticleNumbers,
                            onToggleBookmark: widget.onToggleBookmark,
                          ),
                        ),
                      );
                    },
                    child: Text("${randomArticle['article']}"),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleBookmark,
        backgroundColor: isBookmarked ? Colors.red : Colors.blue,
        child: Icon(
          isBookmarked ? Icons.delete : Icons.favorite,
          color: Colors.white,
        ),
      ),
    );
  }
}

class SavedArticlesScreen extends StatefulWidget {
  final List<dynamic> articles;
  final Function(String) onToggleBookmark;

  const SavedArticlesScreen({
    required this.articles,
    required this.onToggleBookmark,
  });

  @override
  _SavedArticlesScreenState createState() => _SavedArticlesScreenState();
}

class _SavedArticlesScreenState extends State<SavedArticlesScreen> {
  List<dynamic> savedArticles = [];
  Set<String> savedArticleNumbers = Set<String>();

  @override
  void initState() {
    super.initState();
    loadSavedArticles();
  }

  Future<void> loadSavedArticles() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedArticleNumbersList =
        prefs.getStringList('savedArticles');
    setState(() {
      savedArticleNumbers = savedArticleNumbersList != null
          ? savedArticleNumbersList.toSet()
          : Set<String>();
      savedArticles = widget.articles.where((article) {
        return savedArticleNumbers.contains(article['article'].toString());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Articles'),
      ),
      body: ListView.builder(
        itemCount: savedArticles.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16.0),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "Article ${savedArticles[index]['article']}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    savedArticles[index]['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArticleDetailScreen(
                      article: savedArticles[index],
                      articles: widget.articles,
                      savedArticleNumbers: savedArticleNumbers,
                      onToggleBookmark: widget.onToggleBookmark,
                    ),
                  ),
                ).then((_) => loadSavedArticles());
              },
            ),
          );
        },
      ),
    );
  }
}
