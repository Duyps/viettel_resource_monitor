import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/network_metric.dart';

class ViettelNetworkTracker extends HttpOverrides {
  final HttpOverrides? _previousOverrides = HttpOverrides.current;
  void Function(NetworkMetric metric)? onNetworkReport;

  void start() {
    HttpOverrides.global = this;
  }

  void stop() {
    HttpOverrides.global = _previousOverrides;
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final HttpClient client = _previousOverrides?.createHttpClient(context) ?? super.createHttpClient(context);
    return _ViettelHttpClient(client, onNetworkReport);
  }
}

class _ViettelHttpClient implements HttpClient {
  final HttpClient _inner;
  final void Function(NetworkMetric metric)? _onNetworkReport;

  _ViettelHttpClient(this._inner, this._onNetworkReport);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    final startTime = DateTime.now();
    try {
      final request = await _inner.openUrl(method, url);
      return _ViettelHttpClientRequest(request, startTime, method, url.toString(), _onNetworkReport);
    } catch (e) {
      _reportMetric(url.toString(), method, startTime, 0, 0, 0);
      rethrow;
    }
  }

  void _reportMetric(String url, String method, DateTime startTime, int statusCode, int reqSize, int resSize) {
    final duration = DateTime.now().difference(startTime).inMilliseconds;
    final metric = NetworkMetric(
      url: url,
      method: method,
      statusCode: statusCode,
      durationMilliseconds: duration,
      requestSizeBytes: reqSize,
      responseSizeBytes: resSize,
      timestamp: startTime,
    );
    if (kDebugMode) {
      debugPrint('ViettelResourceMonitor: Network [${metric.method}] ${metric.statusCode} - ${metric.url} in ${metric.durationMilliseconds}ms (size: ${metric.responseSizeBytes}B)');
    }
    _onNetworkReport?.call(metric);
  }

  @override
  Future<HttpClientRequest> open(String method, String host, int port, String path) {
    final uri = Uri(scheme: 'http', host: host, port: port, path: path);
    return openUrl(method, uri);
  }
  
  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);
  @override
  Future<HttpClientRequest> get(String host, int port, String path) => open('GET', host, port, path);
  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('POST', url);
  @override
  Future<HttpClientRequest> post(String host, int port, String path) => open('POST', host, port, path);
  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl('PUT', url);
  @override
  Future<HttpClientRequest> put(String host, int port, String path) => open('PUT', host, port, path);
  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl('DELETE', url);
  @override
  Future<HttpClientRequest> delete(String host, int port, String path) => open('DELETE', host, port, path);
  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl('PATCH', url);
  @override
  Future<HttpClientRequest> patch(String host, int port, String path) => open('PATCH', host, port, path);
  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl('HEAD', url);
  @override
  Future<HttpClientRequest> head(String host, int port, String path) => open('HEAD', host, port, path);

  // --- Boilerplate Delegations ---
  @override
  set autoUncompress(bool value) => _inner.autoUncompress = value;
  @override
  bool get autoUncompress => _inner.autoUncompress;
  @override
  set connectionTimeout(Duration? value) => _inner.connectionTimeout = value;
  @override
  Duration? get connectionTimeout => _inner.connectionTimeout;
  @override
  set idleTimeout(Duration value) => _inner.idleTimeout = value;
  @override
  Duration get idleTimeout => _inner.idleTimeout;
  @override
  set maxConnectionsPerHost(int? value) => _inner.maxConnectionsPerHost = value;
  @override
  int? get maxConnectionsPerHost => _inner.maxConnectionsPerHost;
  @override
  set userAgent(String? value) => _inner.userAgent = value;
  @override
  String? get userAgent => _inner.userAgent;
  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) => _inner.addCredentials(url, realm, credentials);
  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) => _inner.addProxyCredentials(host, port, realm, credentials);
  @override
  set authenticate(Future<bool> Function(Uri url, String scheme, String? realm)? f) => _inner.authenticate = f;
  @override
  set authenticateProxy(Future<bool> Function(String host, int port, String scheme, String? realm)? f) => _inner.authenticateProxy = f;
  @override
  set badCertificateCallback(bool Function(X509Certificate cert, String host, int port)? callback) => _inner.badCertificateCallback = callback;
  @override
  void close({bool force = false}) => _inner.close(force: force);
  @override
  set findProxy(String Function(Uri url)? f) => _inner.findProxy = f;
  @override
  set keyLog(Function(String line)? callback) => _inner.keyLog = callback;
  @override
  set connectionFactory(Future<ConnectionTask<Socket>> Function(Uri url, String? proxyHost, int? proxyPort)? f) => _inner.connectionFactory = f;
}

class _ViettelHttpClientRequest implements HttpClientRequest {
  final HttpClientRequest _inner;
  final DateTime _startTime;
  final String _method;
  final String _url;
  final void Function(NetworkMetric metric)? _onNetworkReport;

  _ViettelHttpClientRequest(this._inner, this._startTime, this._method, this._url, this._onNetworkReport);

  @override
  Future<HttpClientResponse> close() async {
    final response = await _inner.close();
    return _ViettelHttpClientResponse(response, _startTime, _method, _url, contentLength, _onNetworkReport);
  }

  @override
  bool get bufferOutput => _inner.bufferOutput;
  @override
  set bufferOutput(bool value) => _inner.bufferOutput = value;
  @override
  int get contentLength => _inner.contentLength;
  @override
  set contentLength(int value) => _inner.contentLength = value;
  @override
  Encoding get encoding => _inner.encoding;
  @override
  set encoding(Encoding value) => _inner.encoding = value;
  @override
  bool get followRedirects => _inner.followRedirects;
  @override
  set followRedirects(bool value) => _inner.followRedirects = value;
  @override
  int get maxRedirects => _inner.maxRedirects;
  @override
  set maxRedirects(int value) => _inner.maxRedirects = value;
  @override
  bool get persistentConnection => _inner.persistentConnection;
  @override
  set persistentConnection(bool value) => _inner.persistentConnection = value;
  @override
  HttpHeaders get headers => _inner.headers;
  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;
  @override
  List<Cookie> get cookies => _inner.cookies;
  @override
  Future<HttpClientResponse> get done => _inner.done;
  @override
  String get method => _inner.method;
  @override
  Uri get uri => _inner.uri;
  @override
  void abort([Object? exception, StackTrace? stackTrace]) => _inner.abort(exception, stackTrace);
  @override
  void add(List<int> data) => _inner.add(data);
  @override
  void addError(Object error, [StackTrace? stackTrace]) => _inner.addError(error, stackTrace);
  @override
  Future addStream(Stream<List<int>> stream) => _inner.addStream(stream);
  @override
  Future flush() => _inner.flush();
  @override
  void write(Object? object) => _inner.write(object);
  @override
  void writeAll(Iterable objects, [String separator = ""]) => _inner.writeAll(objects, separator);
  @override
  void writeCharCode(int charCode) => _inner.writeCharCode(charCode);
  @override
  void writeln([Object? object = ""]) => _inner.writeln(object);
}

class _ViettelHttpClientResponse implements HttpClientResponse {
  final HttpClientResponse _inner;
  final DateTime _startTime;
  final String _method;
  final String _url;
  final int _reqSize;
  final void Function(NetworkMetric metric)? _onNetworkReport;
  int _resSize = 0;

  _ViettelHttpClientResponse(this._inner, this._startTime, this._method, this._url, this._reqSize, this._onNetworkReport);

  @override
  HttpClientResponseCompressionState get compressionState => _inner.compressionState;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return _inner.listen((data) {
      _resSize += data.length;
      if (onData != null) onData(data);
    }, onError: onError, onDone: () {
      _reportMetric();
      if (onDone != null) onDone();
    }, cancelOnError: cancelOnError);
  }

  void _reportMetric() {
    final duration = DateTime.now().difference(_startTime).inMilliseconds;
    final metric = NetworkMetric(
      url: _url,
      method: _method,
      statusCode: statusCode,
      durationMilliseconds: duration,
      requestSizeBytes: _reqSize,
      responseSizeBytes: _resSize,
      timestamp: _startTime,
    );
    if (kDebugMode) {
      debugPrint('ViettelResourceMonitor: Network [${metric.method}] ${metric.statusCode} - ${metric.url} in ${metric.durationMilliseconds}ms (size: ${metric.responseSizeBytes}B)');
    }
    _onNetworkReport?.call(metric);
  }

  @override
  X509Certificate? get certificate => _inner.certificate;
  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;
  @override
  int get contentLength => _inner.contentLength;
  @override
  List<Cookie> get cookies => _inner.cookies;
  @override
  HttpHeaders get headers => _inner.headers;
  @override
  bool get isRedirect => _inner.isRedirect;
  @override
  bool get persistentConnection => _inner.persistentConnection;
  @override
  String get reasonPhrase => _inner.reasonPhrase;
  @override
  List<RedirectInfo> get redirects => _inner.redirects;
  @override
  int get statusCode => _inner.statusCode;
  @override
  Future<HttpClientResponse> redirect([String? method, Uri? url, bool? followLoops]) => _inner.redirect(method, url, followLoops);
  @override
  Future<Socket> detachSocket() => _inner.detachSocket();
  @override
  Future<bool> any(bool Function(List<int>) test) => _inner.any(test);
  @override
  Stream<List<int>> asBroadcastStream({void Function(StreamSubscription<List<int>> subscription)? onListen, void Function(StreamSubscription<List<int>> subscription)? onCancel}) => _inner.asBroadcastStream(onListen: onListen, onCancel: onCancel);
  @override
  Stream<E> asyncExpand<E>(Stream<E>? Function(List<int> event) mapper) => _inner.asyncExpand(mapper);
  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(List<int> event) mapper) => _inner.asyncMap(mapper);
  @override
  Stream<R> cast<R>() => _inner.cast<R>();
  @override
  Future<bool> contains(Object? needle) => _inner.contains(needle);
  @override
  Stream<List<int>> distinct([bool Function(List<int> previous, List<int> next)? equals]) => _inner.distinct(equals);
  @override
  Future<E> drain<E>([E? futureValue]) => _inner.drain(futureValue);
  @override
  Future<List<int>> elementAt(int index) => _inner.elementAt(index);
  @override
  Future<bool> every(bool Function(List<int> element) test) => _inner.every(test);
  @override
  Stream<S> expand<S>(Iterable<S> Function(List<int> element) mapper) => _inner.expand(mapper);
  @override
  Future<List<int>> get first => _inner.first;
  @override
  Future<List<int>> firstWhere(bool Function(List<int> element) test, {List<int> Function()? orElse}) => _inner.firstWhere(test, orElse: orElse);
  @override
  Future<S> fold<S>(S initialValue, S Function(S previous, List<int> element) combine) => _inner.fold(initialValue, combine);
  @override
  Future forEach(void Function(List<int> element) action) => _inner.forEach(action);
  @override
  Stream<List<int>> handleError(Function onError, {bool Function(dynamic error)? test}) => _inner.handleError(onError, test: test);
  @override
  bool get isBroadcast => _inner.isBroadcast;
  @override
  Future<bool> get isEmpty => _inner.isEmpty;
  @override
  Future<String> join([String separator = ""]) => _inner.join(separator);
  @override
  Future<List<int>> get last => _inner.last;
  @override
  Future<List<int>> lastWhere(bool Function(List<int> element) test, {List<int> Function()? orElse}) => _inner.lastWhere(test, orElse: orElse);
  @override
  Future<int> get length => _inner.length;
  @override
  Stream<S> map<S>(S Function(List<int> event) convert) => _inner.map(convert);
  @override
  Future pipe(StreamConsumer<List<int>> streamConsumer) => _inner.pipe(streamConsumer);
  @override
  Future<List<int>> reduce(List<int> Function(List<int> previous, List<int> element) combine) => _inner.reduce(combine);
  @override
  Future<List<int>> get single => _inner.single;
  @override
  Future<List<int>> singleWhere(bool Function(List<int> element) test, {List<int> Function()? orElse}) => _inner.singleWhere(test, orElse: orElse);
  @override
  Stream<List<int>> skip(int count) => _inner.skip(count);
  @override
  Stream<List<int>> skipWhile(bool Function(List<int> element) test) => _inner.skipWhile(test);
  @override
  Stream<List<int>> take(int count) => _inner.take(count);
  @override
  Stream<List<int>> takeWhile(bool Function(List<int> element) test) => _inner.takeWhile(test);
  @override
  Stream<List<int>> timeout(Duration timeLimit, {void Function(EventSink<List<int>> sink)? onTimeout}) => _inner.timeout(timeLimit, onTimeout: onTimeout);
  @override
  Future<List<List<int>>> toList() => _inner.toList();
  @override
  Future<Set<List<int>>> toSet() => _inner.toSet();
  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) => _inner.transform(streamTransformer);
  @override
  Stream<List<int>> where(bool Function(List<int> event) test) => _inner.where(test);
}
