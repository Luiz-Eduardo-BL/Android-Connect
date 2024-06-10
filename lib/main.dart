import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectToDeviceScreen extends StatefulWidget {
  const ConnectToDeviceScreen({super.key});

  @override
  _ConnectToDeviceScreenState createState() => _ConnectToDeviceScreenState();
}

class _ConnectToDeviceScreenState extends State<ConnectToDeviceScreen> {
  final TextEditingController _ipAddressController = TextEditingController();
  String _connectionStatus = '';
  List<String> _savedIPs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedIPs();
  }

  Future<void> _loadSavedIPs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedIPs = prefs.getStringList('savedIPs') ?? [];
    });
  }

  Future<void> _saveIP(String ip) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!_savedIPs.contains(ip)) {
      setState(() {
        _savedIPs.add(ip);
      });
      await prefs.setStringList('savedIPs', _savedIPs);
    }
  }

  void _clearConnectionStatus() {
    setState(() {
      _connectionStatus = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Conecte seu dispositivo'),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _ipAddressController,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Adicione o endereço IP do dispositivo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Visibility(
                  visible: !_isLoading,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: ElevatedButton(
                      onPressed: _connectToDevice,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        backgroundColor: Colors.blue[100],
                      ),
                      child: const Text(
                        'Conectar',
                        style: TextStyle(fontSize: 15, color: Colors.black),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_isLoading) const CircularProgressIndicator(),
                Text(_connectionStatus),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: DropdownButton<String>(
                          hint: const Text("Selecionar endereço IP salvo"),
                          underline: Container(),
                          isExpanded: true,
                          items: _savedIPs.map((String ip) {
                            return DropdownMenuItem<String>(
                              value: ip,
                              child: Text(ip),
                            );
                          }).toList(),
                          onChanged: (String? newIP) {
                            if (newIP != null) {
                              setState(() {
                                _ipAddressController.text = newIP;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _clearConnectionStatus,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        backgroundColor: Colors.red[700],
                      ),
                      child: const Text(
                        'Limpar\n Saida',
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _connectToDevice() async {
    setState(() {
      _isLoading = true;
    });

    String ipAddress = _ipAddressController.text.trim();
    if (ipAddress.isNotEmpty) {
      try {
        // Iniciar o ADB em modo WiFi
        await _executeADBCommand('adb', ['tcpip', '5555']);

        // Conectar-se ao dispositivo via WiFi
        String output =
        await _executeADBCommand('adb', ['connect', '$ipAddress:5555']);

        setState(() {
          if (output.contains('connected to')) {
            _connectionStatus = '✅ Conectado com sucesso!';
          } else if (output.contains('unable to connect')) {
            _connectionStatus =
            'Não foi possível conectar. Verifique o endereço IP e tente novamente.';
          } else {
            _connectionStatus = 'Status de conexão desconhecido: $output';
          }
          _isLoading = false;
        });

        // Save the IP address
        await _saveIP(ipAddress);
      } catch (e) {
        setState(() {
          _connectionStatus = 'Erro: $e';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _connectionStatus = 'Por favor, adicione um endereço IP válido.';
        _isLoading = false;
      });
    }
  }

  Future<String> _executeADBCommand(String command, List<String> args) async {
    final result = await Process.run(command, args);
    return result.stdout.toString();
  }
}

void main() {
  runApp(const ConnectToDeviceScreen());
}
