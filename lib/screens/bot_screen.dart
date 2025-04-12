import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gigachat_dart/gigachat_dart.dart';  // Импортируем библиотеку Gigachat Dart

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _messages = []; // Список сообщений
  late GigachatClient _gigachatClient;  // Инициализация клиента Gigachat
  late HttpClient _client;  // HttpClient для настройки сертификатов

  @override
  void initState() {
    super.initState();

    // Инициализация GigachatClient с HttpClient
    _gigachatClient = GigachatClient(
      clientId: 'aef71d0f-37fb-4dcd-865c-6da60ddaf112',
      clientSecret: '1cbcb7bc-4c02-4840-bde5-eaf275229cf7',
    );
  }

  // Функция для отправки сообщения
  Future<void> _sendMessage() async {
    String userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.insert(0, {"role": "user", "content": userMessage}); // Добавляем сообщение пользователя
    });

    _controller.clear();

    // Получаем ответ от Gigachat
    String botResponse = await _getBotResponse(userMessage);

    setState(() {
      _messages.insert(0, {"role": "bot", "content": botResponse}); // Добавляем ответ бота
    });
  }

  // Функция для получения ответа от Gigachat с использованием потока
  Future<String> _getBotResponse(String userMessage) async {
    try {
      // Создаем запрос для отправки сообщения с использованием потока
      final request = Chat(
        model: "GigaChat",  // Указываем модель
        messages: [
          Message(role: MessageRole.user, content: userMessage), // Сообщение от пользователя
        ],
      );

      // Отправляем запрос и слушаем поток
      final stream = _gigachatClient.generateChatCompletionStream(request: request);

      String response = '';
      await for (var event in stream) {
        // Каждый chunk потока, содержащий новый кусок сгенерированного текста
        if (event.choices != null && event.choices!.isNotEmpty) {
          final chunk = event.choices![0].delta?.content;
          if (chunk != null) {
            response += chunk;  // Добавляем сгенерированную часть к общему ответу
          }
        }
      }
      return response.isNotEmpty ? response : 'Неизвестная ошибка';
    } catch (e) {
      return 'Ошибка при получении ответа от бота: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Гид", style: TextStyle(
          color: Colors.white,
          shadows: <Shadow>[
            Shadow(
              offset: Offset(1.5, 1.5),
              blurRadius: 3.0,
              color: Colors.black,
            ),
          ],
          fontSize: 30,
        ),
        ),
        backgroundColor: Colors.amberAccent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Область для отображения сообщений
          Expanded(
            child: ListView.builder(
              reverse: true,  // Отображаем последние сообщения сверху
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                var message = _messages[index];
                bool isUserMessage = message["role"] == "user";

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Align(
                    alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUserMessage ? Colors.lightBlueAccent : Colors.greenAccent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        message["content"]!,
                        style: TextStyle(
                          color: isUserMessage ? Colors.white : Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Поле ввода и кнопка отправки
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Введите сообщение...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.amberAccent,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


