import 'package:flutter/material.dart';
import 'FG_deliverylist.dart';

class GridItem {
  final String title;
  final String image;
  final String Url;

  GridItem({required this.title, required this.image, required this.Url});
}

class FGType extends StatefulWidget {
  final type;

  const FGType({
    super.key,
    required this.type
  });

  @override
  State<FGType> createState() => _FGTypeState();
}

class _FGTypeState extends State<FGType> {
  List<GridItem> items = [];

  void _initializeItems() {
    setState(() {
      items.addAll([
        /*GridItem(
          title: 'PINDO 1',
          image: 'assets/images/pindo.png',
          Url: 'PDK1',
        ),
        GridItem(
          title: 'PINDO 2',
          image: 'assets/images/pindo.png',
          Url: 'PDK2',
        ),
        GridItem(
          title: 'PINDO 3',
          image: 'assets/images/pindo.png',
          Url: 'PDK3',
        ),
        GridItem(
          title: 'IK Karawang',
          image: 'assets/images/indahkiat.png',
          Url: 'IKK',
        ),*/
        GridItem(
          title: 'Export',
          image: 'assets/images/export.png',
          Url: 'E',
        ),
         GridItem(
          title: 'Local',
          image: 'assets/images/pickup.png',
          Url: 'L',
        ),
      ]);
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeItems();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Delivery Menu',
            style: TextStyle(
              color: Colors.white, // Set the text color to white
              fontWeight: FontWeight.bold, // Set the text to bold
            ),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.only(left: 10, right: 10, top: 15,),
          child: Column(
            children: [
              const SizedBox(height: 15,),
              GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2.0,
                    mainAxisSpacing: 2.0,
                  ),
                  itemCount: items.length,
                  // Center the grid horizontally
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  itemBuilder: (context, index){
                    return Padding(
                      padding: const EdgeInsets.only(left: 3,right: 3,top: 5),
                      child: Card(
                          elevation: 3.0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: InkWell(
                              splashColor: Colors.red,
                              borderRadius: BorderRadius.circular(20.0),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 15,),
                                    Image.asset(
                                      items[index].image,
                                      height: 30.0,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(height: 5,),
                                    Text(
                                      items[index].title,
                                      style: const TextStyle(
                                        fontSize: 10.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () async {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DeliveryList(
                                      type: widget.type,
                                      deliv_type: items[index].Url,
                                    ),
                                  ),
                                );
                              }
                          )
                      ),
                    );
                  }
              )
            ],
          ),
        )
    );
  }
}
