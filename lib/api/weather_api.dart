import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:geocoding/geocoding.dart';
import '../models/weather_forecast_hourly.dart';
import '../utils/constants.dart';
import '../utils/location.dart';

class WeatherApi {
  final _client = HttpClient();

  static const _host =
      Constants.WEATHER_BASE_SCHEME + Constants.WEATHER_BASE_URL_DOMAIN;

  Uri _makeUri(String path, [Map<String, dynamic>? parameters]) {
    final uri = Uri.parse('$_host$path');
    if (parameters != null) {
      return uri.replace(queryParameters: parameters);
    } else {
      return uri;
    }
  }

  Future<WeatherForecastModel> fetchWeatherForecast({String? cityName}) async {
    Map<String, String> parameters;

    if (cityName != null && cityName.isNotEmpty) {
      parameters = {
        'key': Constants.WEATHER_APP_ID,
        'q': cityName,
        'days': '1',
      };
    } else {
      UserLocation location = UserLocation();
      await location.determinePosition();

      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude!,
        location.longitude!,
      );
      String? city =
          placemarks.first.locality ?? placemarks.first.subAdministrativeArea;

      parameters = {
        'key': Constants.WEATHER_APP_ID,
        'q': city ?? '${location.latitude},${location.longitude}',
        'days': '1',
      };
    }

    final url = _makeUri(Constants.WEATHER_FORECAST_PATH, parameters);

    log('request: ${url.toString()}');
    final request = await _client.getUrl(url);
    final response = await request.close();
    final json =
        await response
                .transform(utf8.decoder)
                .toList()
                .then((value) => value.join())
                .then<dynamic>((val) => jsonDecode(val))
            as Map<String, dynamic>;

    return WeatherForecastModel.fromJson(json);
  }
}
