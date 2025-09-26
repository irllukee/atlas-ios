# Weather Widget Setup

To enable the weather widget functionality, you need to:

## 1. Get OpenWeather API Key

1. Go to [OpenWeatherMap](https://openweathermap.org/api)
2. Sign up for a free account
3. Get your API key from the dashboard

## 2. Configure the API Key

Replace the placeholder in `Atlas/Core/Services/WeatherService.swift`:

```swift
private let apiKey = "YOUR_OPENWEATHER_API_KEY" // Replace with actual API key
```

With your actual API key:

```swift
private let apiKey = "your_actual_api_key_here"
```

## 3. Add Location Permission

Add this to your `Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to show local weather information.</string>
```

## 4. Features

- Real-time weather data
- Location-based weather
- Expandable weather details
- Beautiful weather icons
- Temperature, humidity, and pressure information

The weather widget will automatically request location permission and fetch weather data when the dashboard loads.
