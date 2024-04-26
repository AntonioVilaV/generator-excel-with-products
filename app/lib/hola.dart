 import 'package:flutter/material.dart';
 import 'package:flutter/cupertino.dart';

 void main() {
   runApp(MyApp());
 }

 class Product {
   String description;
   double amount;
   String currency;

   Product({required this.description, required this.amount, required this.currency});
 }

 class MyApp extends StatelessWidget {
   @override
   Widget build(BuildContext context) {
     return MaterialApp(
       title: 'Lista de Productos',
       theme: ThemeData(
         primarySwatch: Colors.blue,
       ),
       home: MyHomePage(),
     );
   }
 }

 class MyHomePage extends StatefulWidget {
   @override
   _MyHomePageState createState() => _MyHomePageState();
 }

 class _MyHomePageState extends State<MyHomePage> {
   List<Product> products = [];
   double totalUSD = 0.0;
   double bcvPrice = 0.0;

   void _addProduct(String description, double amount, String currency) {
     setState(() {
       products.add(Product(description: description, amount: amount, currency: currency));
       if (currency == 'USD') {
         totalUSD += amount;
       }
     });
   }

   void _editProduct(int index) {
     final product = products[index];
     String editedDescription = product.description;
     double editedAmount = product.amount;
     String editedCurrency = product.currency;

     showDialog(
       context: context,
       builder: (BuildContext context) {
         return AlertDialog(
           title: Text('Editar Producto'),
           content: StatefulBuilder(
             builder: (BuildContext context, StateSetter setState) {
               return Column(
                 mainAxisSize: MainAxisSize.min,
                 children: <Widget>[
                   TextField(
                     controller: TextEditingController(text: editedDescription),
                     onChanged: (value) {
                       editedDescription = value;
                     },
                     decoration: InputDecoration(labelText: 'Descripción'),
                   ),
                   TextField(
                     controller: TextEditingController(text: editedAmount.toString()),
                     onChanged: (value) {
                       editedAmount = double.tryParse(value) ?? 0.0;
                     },
                     decoration: InputDecoration(labelText: 'Monto'),
                   ),
                   DropdownButton<String>(
                     value: editedCurrency,
                     onChanged: (String? newValue) {
                       setState(() {
                         editedCurrency = newValue!;
                       });
                     },
                     items: <String>['BS', 'USD'].map((String value) {
                       return DropdownMenuItem<String>(
                         value: value,
                         child: Text(value),
                       );
                     }).toList(),
                   ),
                 ],
               );
             },
           ),
           actions: <Widget>[
             TextButton(
               child: Text('Cancelar'),
               onPressed: () {
                 Navigator.of(context).pop();
               },
             ),
             TextButton(
               child: Text('Guardar'),
               onPressed: () {
                 setState(() {
                   products[index] = Product(description: editedDescription, amount: editedAmount, currency: editedCurrency);
                 });
                 Navigator.of(context).pop();
               },
             ),
           ],
         );
       },
     );
   }

   @override
   Widget build(BuildContext context) {
     double subtotalBS = 0.0;
     products.forEach((product) {
       if (product.currency == 'BS') {
         subtotalBS += product.amount;
       }
     });

     double totalTasaBCV = bcvPrice != 0.0 ? subtotalBS / bcvPrice : 0.0;
     double totalGeneral = totalUSD + totalTasaBCV;

     return Scaffold(
       appBar: AppBar(
         title: Text('Lista de Productos'),
       ),
       body: Column(
         children: [
           Expanded(
             child: ListView.builder(
               itemCount: products.length,
               itemBuilder: (context, index) {
                 final product = products[index];
                 return ListTile(
                   title: Text(product.description),
                   subtitle: Text('${product.amount.toString()} ${product.currency}'),
                   trailing: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       IconButton(
                         icon: Icon(Icons.edit),
                         onPressed: () {
                           _editProduct(index);
                         },
                       ),
                       IconButton(
                         icon: Icon(Icons.delete),
                         onPressed: () {
                           setState(() {
                             products.removeAt(index);
                           });
                         },
                       ),
                     ],
                   ),
                 );
               },
             ),
           ),
           Container(
             color: Colors.grey[200],
             padding: EdgeInsets.all(16),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: [
                 TextField(
                   onChanged: (value) {
                     bcvPrice = double.tryParse(value) ?? 0.0;
                   },
                   keyboardType: TextInputType.number,
                   decoration: InputDecoration(labelText: 'Precio del BCV'),
                 ),
                 Text('Subtotal en BsS: $subtotalBS'),
                 Text('Total a Tasa BCV: $totalTasaBCV'),
                 Text('Total General: $totalGeneral'),
               ],
             ),
           ),
         ],
       ),
       floatingActionButton: FloatingActionButton(
         onPressed: () {
           _addProduct('Nuevo Producto', 0.0, 'BS');
         },
         tooltip: 'Agregar Producto',
         child: Icon(Icons.add),
       ),
     );
   }
 }