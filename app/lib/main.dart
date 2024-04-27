import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class Product {
  String description;
  double amount;
  String currency;

  Product({
    required this.description,
    required this.amount,
    required this.currency,
  });
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
  double totalGeneral = 0.0;

  late String description;
  late double amount;
  late String currency = 'USD';
  bool cargaMasiva = false;

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  void _exportToExcel() async {
    if (products.isEmpty) {
      _showAlertMessage(1, 'No hay productos para exportar');
    } else {
      var now = DateTime.now();
      var formatter = DateFormat('dd-MM-yyyy H-m-s');
      String formattedDate = formatter.format(now);

      var name_file = "cotizacion ${formattedDate}.xlsx";

      var excel = Excel.createExcel();
      var sheet = excel.sheets[excel.getDefaultSheet() as String]!;
      CellStyle cellStyle = CellStyle(bold: true);
      var headDescription = sheet.cell(CellIndex.indexByString("A1"));
      headDescription.value = TextCellValue("Description");
      headDescription.cellStyle = cellStyle;
      var headAmount = sheet.cell(CellIndex.indexByString("B1"));
      headAmount.value = TextCellValue("monto");
      headAmount.cellStyle = cellStyle;
      for (var product in products) {
        double total = product.amount;
        if (product.currency == 'BS') {
          total = product.amount / bcvPrice;
          total = double.parse(total.toStringAsFixed(2));
        }
        sheet.appendRow([
          TextCellValue(product.description),
          TextCellValue('${total.toString()}\$')
        ]);
      }
      sheet.appendRow([
        TextCellValue("Total"),
        TextCellValue('${totalGeneral.toString()}\$')
      ]);
      var fileBytes = excel.save();
      try {
        var fileBytes = excel.save();
        String path = '/storage/emulated/0/Documents/';
        if (Platform.isIOS) {
          Directory dir = await getApplicationDocumentsDirectory();
          path = dir.path;
        }
        String absoulte_path_file = '${path}/${name_file}';
        if (fileBytes != null) {
          File(absoulte_path_file)
            ..createSync(recursive: true)
            ..writeAsBytesSync(fileBytes);
          _showExportConfirmation(true, path);
        } else {
          throw Exception('Error al generar el archivo');
        }
      } catch (e) {
        print(e);
        _showExportConfirmation(false, e.toString());
      }
    }
  }

  void _showExportConfirmation(bool success, String message) {
    if (success) {
      Fluttertoast.showToast(
        msg: 'El archivo se ha exportado correctamente',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } else {
      Fluttertoast.showToast(
        msg: 'Hubo un error al exportar el archivo: $message',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  void _showAlertMessage(int type, String message) {
    int WARNING = 1;
    if (type == WARNING) {
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.yellow,
        textColor: Colors.black,
        fontSize: 16.0,
      );
    }
  }

  void _addProduct(String description, double amount, String currency) {
    setState(() {
      products.add(Product(
        description: description,
        amount: amount,
        currency: currency,
      ));
      if (currency == 'USD') {
        totalUSD += amount;
      }
      _recalculateTotals();
      _descriptionController.clear();
      _amountController.clear();
    });

    setState(() {
      this.description = '';
      this.amount = 0.0;
      this.currency = currency;
    });
  }

  void _editProduct(int index) {
    final product = products[index];
    String description = product.description;
    double amount = product.amount;
    String currency = product.currency;

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
                    controller: TextEditingController(text: description),
                    onChanged: (value) {
                      description = value;
                    },
                    decoration: InputDecoration(labelText: 'Descripción'),
                  ),
                  TextField(
                    controller: TextEditingController(text: amount.toString()),
                    onChanged: (value) {
                      amount = double.tryParse(value) ?? 0.0;
                    },
                    decoration: InputDecoration(labelText: 'Monto'),
                  ),
                  Row(
                    children: <Widget>[
                      Text('Carga Masiva'),
                      Switch(
                        value: cargaMasiva,
                        onChanged: (value) {
                          setState(() {
                            cargaMasiva = value;
                          });
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Radio<String>(
                        value: 'BS',
                        groupValue: currency,
                        onChanged: (String? value) {
                          setState(() {
                            currency = value!;
                          });
                        },
                      ),
                      Text('BS'),
                      Radio<String>(
                        value: 'USD',
                        groupValue: currency,
                        onChanged: (String? value) {
                          setState(() {
                            currency = value!;
                          });
                        },
                      ),
                      Text('USD'),
                    ],
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
                  var oldCurrency = products[index].currency;
                  products[index] = Product(
                    description: description,
                    amount: amount,
                    currency: currency,
                  );
                  if (oldCurrency == 'USD') {
                    totalUSD -= products[index].amount;
                  }
                  if (currency == 'USD') {
                    totalUSD += amount;
                  }
                  _recalculateTotals();
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((_) {
      setState(() {});
    });
  }

  void _clearProducts() {
    setState(() {
      products.clear();
      totalUSD = 0.0;
      totalGeneral = 0.0;
    });
    
  }

  void _recalculateTotals() {
    double subtotalBS = 0.0;
    double subtotalUSD = 0.0;
    products.forEach((product) {
      if (product.currency == 'BS') {
        subtotalBS += product.amount;
      } else {
        subtotalUSD += product.amount;
      }
    });

    double totalTasaBCV = bcvPrice != 0.0 ? subtotalBS / bcvPrice : 0.0;
    totalGeneral = totalUSD + totalTasaBCV;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double subtotalBS = 0.0;
    double subtotalUSD = 0.0;
    products.forEach((product) {
      if (product.currency == 'BS') {
        subtotalBS += product.amount;
      } else {
        subtotalUSD += product.amount;
      }
    });

    double totalTasaBCV = bcvPrice != 0.0 ? subtotalBS / bcvPrice : 0.0;
    double totalGeneral = totalUSD + totalTasaBCV;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1a1c64),
        title: Text(
          'Venimeca Gastos',
          style: TextStyle(
            color: Colors.white, // Adjust text color as needed
            fontFamily: 'Arial',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lista de productos',
                  style: TextStyle(
                    fontSize: 18.0,
                  ),
                ),
                TextButton(
                  child: Text('Limpiar lista'),
                  onPressed: () {
                    _clearProducts();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 221, 88, 0),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ListTile(
                  title: Text(product.description),
                  subtitle:
                      Text('${product.amount.toString()} ${product.currency}'),
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
                            if (products[index].currency == 'USD') {
                              totalUSD -= products[index].amount;
                            }
                            products.removeAt(index);
                          });
                          _recalculateTotals();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            color: Color(0xFF1a1c64),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  onChanged: (value) {
                    setState(() {
                      bcvPrice = double.tryParse(value) ?? 0.0;
                    });
                    _recalculateTotals();
                  },
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Precio del BCV',
                    labelStyle: TextStyle(color: Colors.white),
                    hintText: 'Ingrese el precio',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
                Text('Subtotal en BsS: ${subtotalBS.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.white)),
                Text(
                    'Subtotal de productos en \$: ${subtotalUSD.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.white)),
                Text(
                  'Total a Tasa BCV: ${totalTasaBCV.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.white),
                ),
                Text(
                  'Total General: ${totalGeneral.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Agregar Producto'),
                content: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text('Carga Masiva'),
                            Switch(
                              value: cargaMasiva,
                              onChanged: (value) {
                                setState(() {
                                  cargaMasiva = value;
                                });
                              },
                            ),
                          ],
                        ),
                        TextField(
                          decoration: InputDecoration(labelText: 'Descripción'),
                          onChanged: (value) => description = value,
                          controller: _descriptionController,
                        ),
                        TextField(
                          decoration: InputDecoration(labelText: 'Monto'),
                          keyboardType: TextInputType.number,
                          controller: _amountController,
                          onChanged: (value) =>
                              amount = double.tryParse(value) ?? 0.0,
                        ),
                        Row(
                          children: <Widget>[
                            Radio<String>(
                              value: 'BS',
                              groupValue: currency,
                              onChanged: (String? value) {
                                setState(() {
                                  currency = value!;
                                });
                              },
                            ),
                            Text('BS'),
                            Radio<String>(
                              value: 'USD',
                              groupValue: currency,
                              onChanged: (String? value) {
                                setState(() {
                                  currency = value!;
                                });
                              },
                            ),
                            Text('USD'),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () {
                      _addProduct(description, amount, currency);
                      if (!cargaMasiva) {
                        // Cerrar diálogo solo si no está en modo carga masiva
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text('Agregar'),
                  ),
                ],
              );
            },
          );
        },
        tooltip: 'Agregar Producto',
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.zero,
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  backgroundColor: Color.fromARGB(255, 221, 88, 0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: 20.0, horizontal: 16.0),
                ),
                onPressed: _exportToExcel,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.file_download),
                    const SizedBox(width: 8.0),
                    const Text('Exportar'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
