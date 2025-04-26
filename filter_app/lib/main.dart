import 'dart:convert';
import 'package:filter_app/models/urunler_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(FilterApp());
}

class FilterApp extends StatefulWidget {
  const FilterApp({super.key});

  @override
  State<FilterApp> createState() => _FilterAppState();
}

class _FilterAppState extends State<FilterApp> {
  UrunlerModel? _veriler;
  List<Urun> _urunler = [];
  int _seciliKategori = 4;
  String _urunArama = "";
  List<Urun> favorites = [];
  final Map<int, bool> _favoriDurumu = {};

  void _loadData() async {
    final dataString = await rootBundle.loadString('assets/files/data.json');
    final dataJson = jsonDecode(dataString);

    _veriler = UrunlerModel.fromJson(dataJson);
    _urunler = _veriler!.urunler;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? favIds = prefs.getStringList('favorites');

    if (favIds != null) {
      favorites = _veriler!.urunler
          .where((urun) => favIds.contains(urun.id.toString()))
          .toList();
    }

    setState(() {});
  }

  Color _kategoriArkaPlanRengi() {
    switch (_seciliKategori) {
      case 1: // Meyveler
        return Colors.red.shade100;
      case 2: // Sebzeler
        return Colors.green.shade100;
      case 3: // Diğer
        return Colors.blue.shade100;
      case 5: // Favoriler
        return Colors.pink.shade100;
      default:
        return Colors.white;
    }
  }

  @override
  void initState() {
    _loadData();
    super.initState();
  }

  void _addFavorites(Urun urun) {
    favorites.add(urun);
    _favoriDurumu[urun.id] = true;
    _saveFavorites();
  }

  void _removeFavorites(Urun urun) {
    favorites.remove(urun);
    _favoriDurumu[urun.id] = false;
    _saveFavorites();
  }

  void _saveFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favIds = favorites.map((e) => e.id.toString()).toList();
    await prefs.setStringList('favorites', favIds);
  }

  void _filterData(int id) {
    _seciliKategori = id;

    List<Urun> filtreli = _veriler!.urunler;

    if (id != 4) {
      filtreli = filtreli.where((e) => e.kategori == id).toList();
    }

    if (id == 5) {
      filtreli = favorites;
    }

    if (_urunArama.isNotEmpty) {
      filtreli = filtreli
          .where(
              (e) => e.isim.toLowerCase().startsWith(_urunArama.toLowerCase()))
          .toList();
    }

    _urunler = filtreli;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Tagesschrift'),
      home: Scaffold(
        backgroundColor: _kategoriArkaPlanRengi(),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF77824),
          title: Text(
            "Menu",
            style: TextStyle(
              fontSize: 40,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: _veriler == null
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Ürün Ara',
                          prefixIcon: Icon(Icons.search),
                          fillColor: Colors.amber,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _urunArama = value;
                            _filterData(_seciliKategori);
                          });
                        },
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      _kategoriView(),
                      SizedBox(
                        height: 30,
                      ),
                      _urunler.isEmpty
                          ? Center(
                              child: Text("Aradığınız ürünü bulamadık.",
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey)),
                            )
                          : _urunlerView()
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  GridView _urunlerView() {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _urunler.length,
      itemBuilder: (context, index) {
        final Urun urun = _urunler[index];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 15,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.network(
                  urun.resim,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.width * 0.38,
                  fit: BoxFit.cover,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    if (favorites.contains(urun)) {
                      _removeFavorites(urun);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Favorilerden çıkarıldı!'),
                          duration: Duration(milliseconds: 800),
                        ),
                      );
                    } else {
                      _addFavorites(urun);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Favorilere eklendi!'),
                          duration: Duration(milliseconds: 800),
                        ),
                      );
                    }
                  });
                },
                icon: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Icon(
                    favorites.contains(urun)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    key: ValueKey<bool>(favorites.contains(urun)),
                    color: favorites.contains(urun) ? Colors.red : Colors.grey,
                    size: 30,
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                left: 4,
                child: Padding(
                    padding: EdgeInsets.all(5),
                    child: Text(
                      urun.isim,
                      style: TextStyle(
                        fontSize: 25,
                      ),
                    )),
              )
            ],
          ),
        );
      },
    );
  }

  Row _kategoriView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _veriler!.kategoriler.length,
        (index) => GestureDetector(
          onTap: () {
            _filterData(index + 1);
            setState(() {
              _seciliKategori = index + 1;
            });
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
            margin: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.01,
            ),
            decoration: BoxDecoration(
                color: _seciliKategori == _veriler!.kategoriler[index].id
                    ? Color(0xFFF77824)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(10)),
            child: Text(_veriler!.kategoriler[index].isim),
          ),
        ),
      ),
    );
  }
}
