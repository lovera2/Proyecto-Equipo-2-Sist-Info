import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/register_viewmodel.dart';
import 'payment_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controllers: capturan input del usuario
  final TextEditingController _emailDocente = TextEditingController();
  final TextEditingController _passDocente = TextEditingController();

  final TextEditingController _emailEstudiante = TextEditingController();
  final TextEditingController _passEstudiante = TextEditingController();

  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);

  // Validación local. Ideal: mover a RegisterViewModel si se quiere 100% MVVM.
  bool _emailValidoPorRol(String email, String rol) {
    final e = email.trim().toLowerCase();
    final r = rol.trim().toLowerCase();

    if (r == "docente") {
      return e.endsWith("@unimet.edu.ve");
    }
    // estudiante
    return e.endsWith("@correo.unimet.edu.ve");
  }

  // Acción de UI: valida y navega hacia PaymentPage
  // MVVM: usa RegisterViewModel para validación general del formulario
  void _validarYPasarAlPago(
    TextEditingController eCont,
    TextEditingController pCont,
    String rol,
  ) {
    final String emailVal = eCont.text.trim().toLowerCase();
    final String passwordVal = pCont.text.trim();

    if (!_emailValidoPorRol(emailVal, rol)) {
      final msg = rol.toLowerCase() == "docente"
          ? "Docentes: usa solo la dirección '@unimet.edu.ve'"
          : "Estudiantes: usa solo la dirección '@correo.unimet.edu.ve'";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ $msg"), backgroundColor: Colors.red),
      );
      return;
    }

    // ViewModel: reglas generales (password, formato, etc.)
    final vm = context.read<RegisterViewModel>();
    final ok = vm.validarFormulario(email: emailVal, password: passwordVal);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? "❌ Error"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Correo validado. Redirigiendo al pago..."),
        backgroundColor: Colors.green,
      ),
    );

    // Navegación (View): pasa datos a la siguiente pantalla
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          email: emailVal,
          password: passwordVal,
          rol: rol,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailDocente.dispose();
    _passDocente.dispose();
    _emailEstudiante.dispose();
    _passEstudiante.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // View: composición de widgets y layout responsive
    return Scaffold(
      backgroundColor: unimetBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text(
                "¡Crea tu cuenta usando un correo Unimet!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth >= 900;

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildRoleCard(
                            "Docente",
                            Icons.person_outline,
                            _emailDocente,
                            _passDocente,
                            "ejemplo@unimet.edu.ve",
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildRoleCard(
                            "Estudiante",
                            Icons.school_outlined,
                            _emailEstudiante,
                            _passEstudiante,
                            "ejemplo@correo.unimet.edu.ve",
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      _buildRoleCard(
                        "Docente",
                        Icons.person_outline,
                        _emailDocente,
                        _passDocente,
                        "ejemplo@unimet.edu.ve",
                      ),
                      const SizedBox(height: 20),
                      _buildRoleCard(
                        "Estudiante",
                        Icons.school_outlined,
                        _emailEstudiante,
                        _passEstudiante,
                        "ejemplo@correo.unimet.edu.ve",
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  
  Widget _buildRoleCard(
    String title,
    IconData icon,
    TextEditingController eCont,
    TextEditingController pCont,
    String hintCorreo,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono con fondo sutil
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: unimetBlue.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 45, color: unimetBlue),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: unimetBlue,
            ),
          ),
          const SizedBox(height: 25),
          
          // Campo de Correo
          TextField(
            controller: eCont,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
              hintText: hintCorreo,
              labelText: "Correo Institucional",
              labelStyle: const TextStyle(fontSize: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 15),
          
          // Campo de Contraseña
          TextField(
            controller: pCont,
            obscureText: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              hintText: "Mínimo 6 caracteres",
              labelText: "Contraseña",
              labelStyle: const TextStyle(fontSize: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 30),
          
          // Botón de Acción
          ElevatedButton(
            onPressed: () => _validarYPasarAlPago(eCont, pCont, title),
            style: ElevatedButton.styleFrom(
              backgroundColor: unimetOrange,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text(
              "Continuar al pago",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
