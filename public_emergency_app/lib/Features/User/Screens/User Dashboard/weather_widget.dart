import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherWidget extends StatefulWidget {
  final bool compact;

  const WeatherWidget({this.compact = false, Key? key}) : super(key: key);

  @override
  _WeatherWidgetState createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  WeatherData? _weatherData;
  bool _isLoading = true;
  String _error = '';

  static const String WEATHER_API_KEY = 'f0dbe5113db2db758394e7351f6254d0';

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Location permission denied';
            _isLoading = false;
          });
          return;
        }
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);

      // Fetch weather data
      final response = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$WEATHER_API_KEY&units=metric'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          _weatherData = WeatherData.fromJson(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load weather data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching weather: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildWeatherIcon(String mainCondition) {
    switch (mainCondition.toLowerCase()) {
      case 'clear':
        return Icon(Icons.wb_sunny,
            color: Colors.orange, size: widget.compact ? 30 : 50);
      case 'clouds':
        return Icon(Icons.cloud,
            color: Colors.grey, size: widget.compact ? 30 : 50);
      case 'rain':
        return Icon(Icons.beach_access,
            color: Colors.blue, size: widget.compact ? 30 : 50);
      case 'snow':
        return Icon(Icons.ac_unit,
            color: Colors.blue, size: widget.compact ? 30 : 50);
      case 'thunderstorm':
        return Icon(Icons.flash_on,
            color: Colors.yellow, size: widget.compact ? 30 : 50);
      default:
        return Icon(Icons.cloud,
            color: Colors.grey, size: widget.compact ? 30 : 50);
    }
  }

  String _getWeatherAlert(double temp, String condition) {
    if (temp > 35) return "⚠️ Extreme Heat Warning";
    if (temp < 0) return "⚠️ Freezing Temperature";
    if (condition.toLowerCase().contains('thunderstorm')) return "⚠️ Storm Warning";
    if (condition.toLowerCase().contains('heavy rain')) return "⚠️ Heavy Rain Alert";
    return "✅ Weather conditions are safe";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
              width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 8),
          Text("Loading weather..."),
        ],
      );
    }

    if (_error.isNotEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error, color: Colors.red),
          SizedBox(width: 8),
          Text(_error, style: TextStyle(color: Colors.red)),
          if (!widget.compact)
            TextButton(
              onPressed: _fetchWeather,
              child: Text('Retry'),
            ),
        ],
      );
    }

    if (_weatherData == null) return Text("Weather data not available");

    final weather = _weatherData!;

    if (widget.compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildWeatherIcon(weather.mainCondition),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("${weather.temperature.round()}°C",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(weather.description),
            ],
          ),
        ],
      );
    }

    // Full detailed view
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildWeatherIcon(weather.mainCondition),
        SizedBox(height: 16),
        Text("${weather.temperature.round()}°C",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text(weather.description,
            style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        SizedBox(height: 8),
        Text(weather.location, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getWeatherAlert(weather.temperature, weather.mainCondition)
                    .contains('⚠️')
                ? Colors.orange[100]
                : Colors.green[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: _getWeatherAlert(weather.temperature, weather.mainCondition)
                          .contains('⚠️')
                      ? Colors.orange
                      : Colors.green),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  _getWeatherAlert(weather.temperature, weather.mainCondition),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: _getWeatherAlert(weather.temperature, weather.mainCondition)
                            .contains('⚠️')
                        ? Colors.orange[800]
                        : Colors.green[800],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildWeatherDetail('Feels like', "${weather.feelsLike.round()}°C"),
            _buildWeatherDetail('Humidity', "${weather.humidity}%"),
            _buildWeatherDetail('Wind', "${weather.windSpeed} m/s"),
          ],
        ),
      ],
    );
  }

  Widget _buildWeatherDetail(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class WeatherData {
  final String location;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String description;
  final String mainCondition;

  WeatherData({
    required this.location,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.mainCondition,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      location: json['name'],
      temperature: json['main']['temp'].toDouble(),
      feelsLike: json['main']['feels_like'].toDouble(),
      humidity: json['main']['humidity'],
      windSpeed: json['wind']['speed'].toDouble(),
      description: json['weather'][0]['description'],
      mainCondition: json['weather'][0]['main'],
    );
  }
}
