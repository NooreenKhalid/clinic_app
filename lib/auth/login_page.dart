import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const LoginPage({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  bool _hidePassword = true;
  String _selectedRole = 'admin';

  late AnimationController _logoAnimationController;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animation (scale)
    _logoAnimationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _logoAnimation =
        Tween<double>(begin: 0.9, end: 1.1).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _logoAnimationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Please enter email & password", Colors.redAccent);
      return;
    }

    setState(() => _loading = true);

    await AuthService.login(
      context,
      email,
      password,
      _selectedRole,
      isDarkMode: widget.isDarkMode,
      onThemeToggle: widget.onThemeToggle,
    );

    if (mounted) setState(() => _loading = false);
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _launchWebsite() async {
    const url = "https://australiasoftwarehub.com/";
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar("Could not open website", Colors.redAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        widget.isDarkMode ? Colors.grey[900] : const Color(0xFFF4F6FA);
    final containerColor = widget.isDarkMode ? Colors.grey[850] : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final labelColor = widget.isDarkMode ? Colors.white70 : Colors.grey;
    final inputFillColor =
        widget.isDarkMode ? Colors.grey[800] : const Color(0xFFF9FAFB);

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Container(
            width: size.width < 500 ? size.width : 450,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 35,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo with scale animation
                ScaleTransition(
                  scale: _logoAnimation,
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image:
                            AssetImage('assets/images/smart_clinic_logo.png'),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // App Name
                Text(
                  "Smart Clinic",
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Admin & Staff Login",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 28),

                // Role Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  items: const [
                    DropdownMenuItem(
                        value: 'admin', child: Text("Login as Admin")),
                    DropdownMenuItem(
                        value: 'staff', child: Text("Login as Staff")),
                  ],
                  onChanged: (value) => setState(() => _selectedRole = value!),
                  decoration: _inputDecoration(
                      "Select Role", Icons.person_outline,
                      fillColor: inputFillColor),
                  style: GoogleFonts.poppins(color: textColor),
                ),
                const SizedBox(height: 18),

                // Email Field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.poppins(color: textColor),
                  decoration: _inputDecoration(
                      "Email Address", Icons.email_outlined,
                      fillColor: inputFillColor),
                ),
                const SizedBox(height: 16),

                // Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: _hidePassword,
                  style: GoogleFonts.poppins(color: textColor),
                  decoration: _inputDecoration(
                    "Password",
                    Icons.lock_outline,
                    fillColor: inputFillColor,
                    suffix: IconButton(
                      icon: Icon(
                        _hidePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.teal[700],
                      ),
                      onPressed: () =>
                          setState(() => _hidePassword = !_hidePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Login Button with subtle animation
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[700],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                      shadowColor: Colors.tealAccent.withOpacity(0.4),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Text(
                            "Login",
                            style: GoogleFonts.poppins(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Developer Credit
                Column(
                  children: [
                    Text(
                      "App Developed by",
                      style:
                          GoogleFonts.poppins(fontSize: 12, color: labelColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Nooreen Khalid",
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _launchWebsite,
                      child: Text(
                        "www.australiasoftwarehub.com",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.redAccent,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Dark/Light Mode Toggle
                IconButton(
                  icon: Icon(
                      widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      color: Colors.teal[700],
                      size: 28),
                  onPressed: widget.onThemeToggle,
                  tooltip: widget.isDarkMode
                      ? "Switch to Light Mode"
                      : "Switch to Dark Mode",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon,
      {Widget? suffix, Color? fillColor}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(
        color: Colors.teal[700]?.withOpacity(0.7),
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: Colors.teal[700]),
      suffixIcon: suffix,
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.teal.shade700, width: 2),
      ),
    );
  }
}
