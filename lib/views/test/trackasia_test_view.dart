import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/trackasia_place.dart';
import '../../services/trackasia_service.dart';

class TrackAsiaTestView extends StatefulWidget {
  const TrackAsiaTestView({super.key});

  @override
  State<TrackAsiaTestView> createState() => _TrackAsiaTestViewState();
}

class _TrackAsiaTestViewState extends State<TrackAsiaTestView> {
  final TrackAsiaService _trackAsiaService = TrackAsiaService();
  final TextEditingController _searchController = TextEditingController();

  List<TrackAsiaPlace> _suggestions = [];
  TrackAsiaPlace? _selectedPlace;
  TrackAsiaPlace? _currentLocationAddress;

  bool _isSearching = false;
  bool _isGeocoding = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() => _suggestions = []);
        return;
      }

      setState(() => _isSearching = true);
      final results = await _trackAsiaService.autocomplete(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _handleSelectSuggestion(TrackAsiaPlace suggestion) async {
    setState(() {
      _selectedPlace = suggestion;
      _searchController.text = suggestion.label;
      _suggestions = [];
    });

    // Demonstrate searchAddress for more precision if needed
    // (though autocomplete already provides coords)
    final topResult = await _trackAsiaService.searchAddress(suggestion.label);
    if (mounted && topResult != null) {
      setState(() => _selectedPlace = topResult);
    }
  }

  Future<void> _handleReverseGeocode() async {
    // Current Sample Coordinates (e.g., Da Nang center)
    const double lat = 16.0544;
    const double lon = 108.2022;

    setState(() => _isGeocoding = true);
    final result = await _trackAsiaService.reverseGeocode(lat: lat, lng: lon);
    if (mounted) {
      setState(() {
        _currentLocationAddress = result;
        _isGeocoding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TrackAsia Demo Test'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. Autocomplete & Search',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Nhập địa chỉ cần tìm...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(10.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: _onSearchChanged,
            ),

            // Autocomplete Results
            if (_suggestions.isNotEmpty)
              Container(
                height: 250,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final p = _suggestions[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                      ),
                      title: Text(p.label),
                      onTap: () => _handleSelectSuggestion(p),
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),
            if (_selectedPlace != null)
              Card(
                color: Colors.blueGrey[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kết quả tìm kiếm:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text('Địa chỉ: ${_selectedPlace!.label}'),
                      Text(
                        'Tọa độ: ${_selectedPlace!.latitude}, ${_selectedPlace!.longitude}',
                      ),
                      if (_selectedPlace!.district != null)
                        Text('Quận/Huyện: ${_selectedPlace!.district}'),
                      if (_selectedPlace!.city != null)
                        Text('Thành phố: ${_selectedPlace!.city}'),
                    ],
                  ),
                ),
              ),

            const Divider(height: 40),
            const Text(
              '2. Reverse Geocoding',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Tọa độ mẫu: 16.0544, 108.2022 (Đà Nẵng)'),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGeocoding ? null : _handleReverseGeocode,
                icon: const Icon(Icons.gps_fixed),
                label: Text(
                  _isGeocoding ? 'Đang lấy địa chỉ...' : 'Lấy địa chỉ hiện tại',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            if (_currentLocationAddress != null)
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Text(
                  'Địa chỉ hiện tại: ${_currentLocationAddress!.label}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
