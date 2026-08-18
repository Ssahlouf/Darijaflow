import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const String apiBase = 'https://unarrogantly-bifilar-chase.ngrok-free.dev';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const DarijaApp());
}

class DarijaApp extends StatelessWidget {
  const DarijaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DarijaFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE94560),
          surface: Color(0xFF16213E),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Color(0xFFE94560))),
            );
          }
          if (snapshot.hasData) return const MainPage();
          return const AuthPage();
        },
      ),
    );
  }
}

// ── Auth Page ─────────────────────────────────────────────────
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  String _error = '';

  Future<void> _emailAuth() async {
    setState(() { _isLoading = true; _error = ''; });
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Authentication failed');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() { _isLoading = true; _error = ''; });
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Logo & title
              const Center(
                child: Column(
                  children: [
                    Text('🇲🇦', style: TextStyle(fontSize: 60)),
                    SizedBox(height: 12),
                    Text('DarijaFlow',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 6),
                    Text('Translate Darija with AI',
                      style: TextStyle(color: Colors.white38, fontSize: 14)),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Tab toggle
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLogin = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isLogin ? const Color(0xFFE94560) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('Sign In', textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isLogin ? Colors.white : Colors.white54,
                              fontWeight: FontWeight.bold,
                            )),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLogin = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isLogin ? const Color(0xFFE94560) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('Sign Up', textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !_isLogin ? Colors.white : Colors.white54,
                              fontWeight: FontWeight.bold,
                            )),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Email field
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF16213E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Password field
              TextField(
                controller: _passCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.lock_outlined, color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF16213E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_error, style: const TextStyle(color: Color(0xFFE94560), fontSize: 13)),
              ],

              const SizedBox(height: 20),

              // Sign in/up button
              ElevatedButton(
                onPressed: _isLoading ? null : _emailAuth,
               style: ElevatedButton.styleFrom(
                 backgroundColor: const Color(0xFFE94560),
                 foregroundColor: Colors.white,
                 padding: const EdgeInsets.symmetric(vertical: 16),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                 elevation: 0,),
                 child: _isLoading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isLogin ? 'Sign In' : 'Create Account',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
               ),

              const SizedBox(height: 16),

              // Divider
              const Row(children: [
                Expanded(child: Divider(color: Colors.white12)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ),
                Expanded(child: Divider(color: Colors.white12)),
              ]),

              const SizedBox(height: 16),

              // Google sign in
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _googleSignIn,
                icon: const Text('G', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4285F4))),
                label: const Text('Continue with Google', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.white12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Languages ─────────────────────────────────────────────────
const List<Map<String, String>> kInputLangs = [
  {'label': '🇲🇦 Darija', 'locale': 'ar', 'name': 'Darija'},
  {'label': '🇬🇧 English', 'locale': 'en-US', 'name': 'English'},
  {'label': '🇫🇷 French', 'locale': 'fr-FR', 'name': 'French'},
  {'label': '🇪🇸 Spanish', 'locale': 'es-ES', 'name': 'Spanish'},
  {'label': '🇸🇦 Arabic', 'locale': 'ar-SA', 'name': 'Arabic'},
  {'label': '🇩🇪 German', 'locale': 'de-DE', 'name': 'German'},
  {'label': '🇮🇹 Italian', 'locale': 'it-IT', 'name': 'Italian'},
];

const List<Map<String, String>> kOutputLangs = [
  {'label': '🇲🇦 Darija', 'value': 'Moroccan Darija (Arabic script)', 'name': 'Darija'},
  {'label': '🇬🇧 English', 'value': 'English', 'name': 'English'},
  {'label': '🇫🇷 French', 'value': 'French', 'name': 'French'},
  {'label': '🇪🇸 Spanish', 'value': 'Spanish', 'name': 'Spanish'},
  {'label': '🇸🇦 Arabic', 'value': 'Modern Standard Arabic', 'name': 'Arabic'},
  {'label': '🇩🇪 German', 'value': 'German', 'name': 'German'},
  {'label': '🇮🇹 Italian', 'value': 'Italian', 'name': 'Italian'},
  {'label': '🇵🇹 Portuguese', 'value': 'Portuguese', 'name': 'Portuguese'},
  {'label': '🇷🇺 Russian', 'value': 'Russian', 'name': 'Russian'},
  {'label': '🇨🇳 Chinese', 'value': 'Chinese', 'name': 'Chinese'},
  {'label': '🇯🇵 Japanese', 'value': 'Japanese', 'name': 'Japanese'},
];

// ── Main scaffold ─────────────────────────────────────────────
class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _tab = 0;
  List<Map<String, String>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['history'] != null) {
          setState(() {
            _history = List<Map<String, String>>.from(
              (data['history'] as List).map((e) => Map<String, String>.from(e))
            );
          });
        }
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('history') ?? [];
      setState(() {
        _history = raw.map((e) => Map<String, String>.from(jsonDecode(e))).toList();
      });
    }
  }

  Future<void> _saveToHistory(Map<String, String> entry) async {
    _history.insert(0, entry);
    if (_history.length > 100) _history = _history.take(100).toList();
    setState(() {});
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'history': _history,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('history', _history.map((e) => jsonEncode(e)).toList());
      }
    }
  }

  Future<void> _clearHistory() async {
    setState(() => _history = []);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'history': []});
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('history');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          HomePage(onTranslated: _saveToHistory),
          HistoryPage(history: _history, onClear: _clearHistory),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF16213E),
        indicatorColor: const Color(0xFFE94560).withOpacity(0.2),
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.translate), label: 'Translate'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// ── Home page ─────────────────────────────────────────────────
class HomePage extends StatefulWidget {
  final Future<void> Function(Map<String, String>) onTranslated;
  const HomePage({super.key, required this.onTranslated});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _ctrl = TextEditingController();
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  int _inputIdx = 0;
  int _outputIdx = 0;
  String _outputText = '';
  String _outputLangKey = '';
  bool _isLoading = false;
  bool _isListening = false;

  Future<void> _translate() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() { _isLoading = true; _outputText = ''; });
    try {
      final res = await http.post(
        Uri.parse('$apiBase/translate/text'),
        headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
        body: jsonEncode({'text': text, 'target_lang': kOutputLangs[_outputIdx]['value']}),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timed out'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _outputText = data['output'];
          _outputLangKey = data['output_lang'];
        });
        unawaited(widget.onTranslated({
          'input': text,
          'output': data['output'],
          'input_lang': kInputLangs[_inputIdx]['name']!,
          'output_lang': kOutputLangs[_outputIdx]['name']!,
        }));
        _speak(data['output'], data['output_lang']);
      } else {
        setState(() => _outputText = 'Error ${res.statusCode}');
      }
    } catch (_) {
      setState(() => _outputText = 'Cannot reach server.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleMic() async {
  if (_isListening) {
    await _speech.stop();
    setState(() => _isListening = false);
    return; // 🔥 STOP ONLY — no translate
  }

  final ok = await _speech.initialize();
  if (ok) {
    setState(() => _isListening = true);

    _speech.listen(
      onResult: (r) => setState(() => _ctrl.text = r.recognizedWords),
      localeId: kInputLangs[_inputIdx]['locale'],
    );
  }
}

  Future<void> _speak(String text, String lang) async {
    final code = {
      'english': 'en-US', 'darija': 'ar-SA', 'french': 'fr-FR',
      'spanish': 'es-ES', 'german': 'de-DE', 'italian': 'it-IT',
      'portuguese': 'pt-PT', 'russian': 'ru-RU', 'chinese': 'zh-CN',
      'japanese': 'ja-JP', 'modern standard arabic': 'ar-SA',
    }[lang.toLowerCase()] ?? 'en-US';
    await _tts.setLanguage(code);
    await _tts.speak(text);
  }

  void _swap() {
    final newOut = kOutputLangs.indexWhere((l) => l['name'] == kInputLangs[_inputIdx]['name']);
    final newIn = kInputLangs.indexWhere((l) => l['name'] == kOutputLangs[_outputIdx]['name']);
    setState(() {
      if (newOut != -1) _outputIdx = newOut;
      if (newIn != -1) _inputIdx = newIn;
      final tmp = _ctrl.text;
      _ctrl.text = _outputText;
      _outputText = tmp;
    });
  }

  Future<void> _showLangPicker(bool isInput) async {
    final langs = isInput ? kInputLangs : kOutputLangs;
    final current = isInput ? _inputIdx : _outputIdx;
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ListView.builder(
        itemCount: langs.length,
        itemBuilder: (_, i) => ListTile(
          leading: Text(langs[i]['label']!.split(' ')[0], style: const TextStyle(fontSize: 24)),
          title: Text(langs[i]['name']!, style: const TextStyle(color: Colors.white)),
          trailing: i == current ? const Icon(Icons.check, color: Color(0xFFE94560)) : null,
          onTap: () => Navigator.pop(context, i),
        ),
      ),
    );
    if (picked != null) setState(() => isInput ? _inputIdx = picked : _outputIdx = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDarija = _outputLangKey == 'darija';
    final user = FirebaseAuth.instance.currentUser;
    return SafeArea(
      child: Column(
        children: [
          Container(
            color: const Color(0xFF16213E),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                const Text('DarijaFlow',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                if (user?.photoURL != null)
                  CircleAvatar(backgroundImage: NetworkImage(user!.photoURL!), radius: 16)
                else
                  CircleAvatar(
                    backgroundColor: const Color(0xFFE94560),
                    radius: 16,
                    child: Text(
                      (user?.email ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            color: const Color(0xFF16213E),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showLangPicker(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(kInputLangs[_inputIdx]['label']!,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _swap,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE94560),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.swap_horiz, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showLangPicker(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(kOutputLangs[_outputIdx]['label']!,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(kInputLangs[_inputIdx]['name']!,
                          style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _ctrl,
                          maxLines: 5,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Write or paste your text here...',
                            hintStyle: TextStyle(color: Colors.white24),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_ctrl.text.length}/1000',
                              style: const TextStyle(color: Colors.white38, fontSize: 12)),
                            Row(
                              children: [
                                if (_ctrl.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.copy, color: Colors.white54, size: 20),
                                    onPressed: () => Clipboard.setData(ClipboardData(text: _ctrl.text)),
                                  ),
                                IconButton(
                                  icon: Icon(
                                    _isListening ? Icons.stop_circle : Icons.mic,
                                    color: _isListening ? const Color(0xFFE94560) : Colors.white54,
                                    size: 24,
                                  ),
                                  onPressed: _toggleMic,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _translate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE94560),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.translate, size: 18),
                                SizedBox(width: 8),
                                Text('Translate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('AI may make small mistakes.',
                    style: TextStyle(color: Colors.white38, fontSize: 11)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _outputText.isNotEmpty
                          ? const Color(0xFFE94560).withOpacity(0.4) : Colors.white12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: _outputText.isEmpty
                        ? const Column(
                            children: [
                              SizedBox(height: 20),
                              Icon(Icons.translate, color: Colors.white12, size: 40),
                              SizedBox(height: 12),
                              Text('Start translating, your translation will appear here',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white24, fontSize: 14)),
                              SizedBox(height: 20),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(kOutputLangs[_outputIdx]['name']!,
                                style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              const SizedBox(height: 8),
                              Text(_outputText,
                                textDirection: isDarija ? TextDirection.rtl : TextDirection.ltr,
                                style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.6)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.copy, color: Colors.white54, size: 20),
                                    onPressed: () => Clipboard.setData(ClipboardData(text: _outputText)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.volume_up, color: Colors.white54, size: 20),
                                    onPressed: () => _speak(_outputText, _outputLangKey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── History page ──────────────────────────────────────────────
class HistoryPage extends StatelessWidget {
  final List<Map<String, String>> history;
  final VoidCallback onClear;
  const HistoryPage({super.key, required this.history, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('History (${history.length})',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                if (history.isNotEmpty)
                  TextButton(onPressed: onClear,
                    child: const Text('Clear all', style: TextStyle(color: Color(0xFFE94560)))),
              ],
            ),
          ),
          Expanded(
            child: history.isEmpty
                ? const Center(child: Text('No history yet', style: TextStyle(color: Colors.white38)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final item = history[i];
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF16213E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['input'] ?? '',
                              style: const TextStyle(color: Colors.white54, fontSize: 14)),
                            const Divider(color: Colors.white12, height: 20),
                            Text(item['output'] ?? '',
                              textDirection: item['output_lang'] == 'Darija'
                                ? TextDirection.rtl : TextDirection.ltr,
                              style: const TextStyle(color: Colors.white, fontSize: 16,
                                fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text('${item['input_lang']} → ${item['output_lang']}',
                              style: const TextStyle(color: Color(0xFFE94560), fontSize: 11)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Settings page ─────────────────────────────────────────────
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _signOut(BuildContext context) async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),

            // User info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE94560).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFE94560),
                    radius: 24,
                    backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!) : null,
                    child: user?.photoURL == null
                      ? Text((user?.email ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 20,
                            fontWeight: FontWeight.bold))
                      : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.displayName ?? 'User',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(user?.email ?? '',
                          style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            _tile(Icons.translate, 'Translation Engine', 'GPT-4o-mini'),
            _tile(Icons.mic, 'Voice Input', 'Enabled'),
            _tile(Icons.volume_up, 'Auto Speak', 'Enabled'),
            _tile(Icons.history, 'History Limit', '100 translations'),
            _tile(Icons.language, 'App Version', '1.0.0'),

            const SizedBox(height: 16),

            // Sign out button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _signOut(context),
                icon: const Icon(Icons.logout, color: Color(0xFFE94560)),
                label: const Text('Sign Out', style: TextStyle(color: Color(0xFFE94560))),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFFE94560)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE94560), size: 22),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15))),
          Text(value, style: const TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }
}