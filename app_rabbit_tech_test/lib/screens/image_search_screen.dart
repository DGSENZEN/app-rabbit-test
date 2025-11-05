import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/image_service.dart';

class ImageSearchScreen extends StatefulWidget {
  const ImageSearchScreen({Key? key}) : super(key: key);

  @override
  State<ImageSearchScreen> createState() => _ImageSearchScreenState();

}

class _ImageSearchScreenState extends State<ImageSearchScreen> {
  final ImageService _imageService = ImageService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ImageModel> _images = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String _currentQuery = 'dogs';

  Timer? _searchDebounce;
  Timer? _scrollDebounce;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadImages();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadImages() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newImages = await _imageService.searchImages(_currentQuery, _currentPage);

      setState(() {
        _images.addAll(newImages);
        _currentPage++;
        _isLoading = false;
        _hasMore = newImages.isNotEmpty;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      _showError(e.toString());
      }
    }

    void _onScroll() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {

            _scrollDebounce?.cancel();
            _scrollDebounce = Timer(const Duration(milliseconds: 300), () {
              _loadMoreImages();
            });
          }
    }

    void _loadMoreImages(){
      if (_isLoadingMore || !_hasMore || _isLoading) return;

      setState(() {
        _isLoadingMore = true;
      });

      _loadImages();
    }

    void _onSearchChanged(String value) {
      _searchDebounce?.cancel();

      _searchDebounce = Timer(const Duration(milliseconds: 500), () {
        if (value.isNotEmpty && value != _currentQuery) 
        {
          _performSearch(value);
        }
      });
    }

    void _performSearch(String query) {
      setState(() {
        _currentQuery = query;
        _images.clear();
        _currentPage = 1;
        _hasMore = true;
        _isLoading = false;
        _isLoadingMore = false;
      });

      _loadImages();
    }

    void _onSearchSubmitted(String query) {
      _searchDebounce?.cancel();
      if (query.isNotEmpty) {
        _performSearch(query);
      }
    }

    Future<void> _onRefresh() async {
      setState(() {
        _images.clear();
        _currentPage = 1;
        _hasMore = true;
      });
      await _loadImages();
    }

    void _showError(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $message')),
      );
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: 
            _buildImageGrid()),
          ],
        ),
      );
    }

    Widget _buildSearchBar() {
      return Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow( 
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2)
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search images!',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: _searchController.text.isNotEmpty 
            ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
            ) : null,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onSubmitted: _onSearchSubmitted,
          onChanged: _onSearchChanged,
        ),
      );
    }

  Widget _buildImageGrid() {
    if (_images.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_images.isEmpty) {
      return const Center(child: Text('No images found'));
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.75,
        ),
        itemCount: _images.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _images.length) {
            return const Center(child: CircularProgressIndicator());
          }

          return _buildImageCard(_images[index]);
        },
      ),
    );
  }

  Widget _buildImageCard(ImageModel image) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: image.regularUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.error, color: Colors.red,),
        ),
      )
    );
  }
    
  }