import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'transport.dart';
import 'dart:io';
import 'dart:convert' as convert;
import 'package:string_validator/string_validator.dart';

class TransportHTTP implements Transport{

  static final Duration timeout = Duration(seconds: 10);
  late String hostname;
  final Map<String, String> headers = new Map();
  // final client = http.Client();
  // final client = HttpClient();
  // final client = new Dio();
  late IOClient client;

  TransportHTTP(String hostname) {
    if (!isURL(hostname)) {
      throw FormatException("hostname '$hostname' should be an URL.");
    }
    this.hostname = hostname;
    headers["Content-type"] =  "application/x-www-form-urlencoded";
    //header["Content-type"] =  "application/json";
    headers["Accept"] =  "text/plain";

    final context = SecurityContext.defaultContext;
    context.allowLegacyUnsafeRenegotiation = true;
    final httpClient = HttpClient(context: context);
    client = IOClient(httpClient);
  }

  @override
  Future<bool> connect() async {
    return true;
  }

  @override
  Future<void> disconnect() async {
    client.close();
  }
  // void _updateCookie(Response<dynamic> response) {
  //   String? rawCookie = response.headers.map['set-cookie']?.first;
  //   if (rawCookie != null) {
  //     int index = rawCookie.indexOf(';');
  //     headers['cookie'] =
  //     (index == -1) ? rawCookie : rawCookie.substring(0, index);
  //   }
  // }
  void _updateCookie(http.Response response) {
    String? rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      int index = rawCookie.indexOf(';');
      headers['cookie'] =
      (index == -1) ? rawCookie : rawCookie.substring(0, index);
    }
  }

  @override
  Future<Uint8List> sendReceive(String epName, Uint8List data) async {
    try {
      print("Connecting to " + this.hostname + "/" + epName);
      // final response = await client.post(
      //     "http://" + this.hostname + "/" + epName,
      //     data: data,
      //     options: Options(
      //         persistentConnection: true,
      //         // allowLegacyUnsafeRenegotiation: true,
      //         headers: this.headers,
      //         sendTimeout: timeout,
      //         receiveTimeout: timeout,
      //         responseType: ResponseType.bytes
      //     )
      // );
      //     headers: this.headers,
      // body: data).timeout(timeout);
      // final request = await client.postUrl(Uri.http(this.hostname, "/" + epName,));
      // request.headers.add(HttpHeaders.contentTypeHeader, "application/x-www-form-urlencoded");
      // request.headers.add(HttpHeaders.acceptHeader, "text/plain");
      // request.persistentConnection = false;
      // request.write(data);

      http.Response response = await client.post(
          Uri.http(this.hostname, "/" + epName),
          headers: this.headers,
          body: data,
          encoding: Encoding.getByName("utf-8")
      );
        _updateCookie(response);
        print("Connection result: status ${response.statusCode} body ${response.body}");
        if (response.statusCode == 200) {
          //client.close();
          final Uint8List bodyBytes = response.bodyBytes;
          return bodyBytes;
        }
        else {
          print("Connection failed: status ${response.statusCode} body ${response.body}");
          throw Exception("ESP Device doesn't respond");
        }

      // if (response !=null) {
      //   _updateCookie(response);
      //   if (response.statusCode == 200) {
      //     print('Connection successful');
      //     //client.close();
      //     final Uint8List body_bytes = response.data;
      //     return body_bytes;
      //   }
      //   else {
      //     print("Connection failed: status ${response.statusCode} body ${response.data}");
      //     throw Exception("ESP Device doesn't repond");
      //   }
      // }
    }
    catch(e, s){
      print('Connection error:  ' + e.toString());
      print(s);
      throw StateError('Connection error ' + e.toString());
    }
    return Uint8List.fromList([]);
  }
}



