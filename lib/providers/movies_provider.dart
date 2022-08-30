import 'dart:async';
import 'dart:convert';

import 'package:film_project/helpers/debouncer.dart';
import 'package:film_project/models/models.dart';
import 'package:film_project/models/search_movies_response.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
class MoviesProvider extends ChangeNotifier {

  String _baseurl = 'api.themoviedb.org';
  String _apiKey = '2c35811a9698b2b73a8861d49657f2b0';
  String _language = 'es-ES';

  List<Movie> onDisplayMovies = [];
  List<Movie> popularMovies = [];

  Map<int, List<Cast>> moviesCast = {};
  int _popularPage = 0;
  final debouncer = Debouncer(duration: Duration(milliseconds: 500),);
  final StreamController<List<Movie>> _suggestionStreamController = new StreamController.broadcast();
  Stream<List<Movie>> get suggestionStream => this._suggestionStreamController.stream;


  MoviesProvider() {
    print('Movies provider inicializado');
    this.getOnDisplayMovies();
    this.getPopularMovies();
  }

  Future<String> _getJsonData(String Segment, [int page = 1]) async {
    final url = Uri.https(_baseurl, Segment,
        {
          'api_key': _apiKey,
          'language': _language,
          'page': '$page'
        });
    final response = await http.get(url);
    return response.body;
  }

  getOnDisplayMovies() async {
    final jsonData = await this._getJsonData('3/movie/now_playing');
    final nowPlayingReponse = NowPlayingResponse.fromJson(jsonData);

    onDisplayMovies = nowPlayingReponse.results;

    notifyListeners();

  }

  getPopularMovies() async {

    _popularPage++;

    final jsonData = await this._getJsonData('3/movie/popular', _popularPage);
    final popularResponse = PopularResponse.fromJson(jsonData);

    popularMovies = [...popularMovies,...popularResponse.results];
    print(popularMovies[0]);
    notifyListeners();
  }

  Future <List<Cast>> getMovieCast(int movieId) async {
    if(moviesCast.containsKey(movieId)) return moviesCast[movieId]!;
    final jsonData = await this._getJsonData('3/movie/$movieId/credits');
    final creditsResponse = CreditsResponse.fromJson(jsonData);

    moviesCast[movieId] = creditsResponse.cast;
    return creditsResponse.cast;
  }


  Future <List<Movie>> searchMovie(String query) async {
    final url = Uri.https(_baseurl, '3/search/movie',
        {
          'api_key': _apiKey,
          'language': _language,
          'query': query
        });

    final response = await http.get(url);
    final searchResponse = SearchResponse.fromJson(response.body);
    return searchResponse.results;
  }

  void getSuggestionByQuery(String query) {
    debouncer.value = '';
    debouncer.onValue = (value) async {
      final results = await this.searchMovie(value);
      this._suggestionStreamController.add(results);
    };

    final timer = Timer.periodic(Duration(milliseconds: 300), (_) {
      debouncer.value = query;
    });

    Future.delayed(Duration(milliseconds: 301)).then((_) => timer.cancel());
  }

}