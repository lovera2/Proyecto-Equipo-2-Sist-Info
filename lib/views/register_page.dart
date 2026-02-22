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
  final TextEditingController _emailDocente = TextEditingController();
  final TextEditingController _passDocente = TextEditingController();

  final TextEditingController _emailEstudiante = TextEditingController();
  final TextEditingController _passEstudiante = TextEditingController();

  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);

  bool _emailValidoPorRol(String email, String rol) {
    final e = email.trim().toLowerCase();
    final r = rol.trim().toLowerCase();

    if (r == "docente") {
      return e.endsWith("@unimet.edu.ve");
    }
    // estudiante
    return e.endsWith("@correo.unimet.edu.ve");
  }

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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(icon, size: 60, color: unimetBlue),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: unimetBlue,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: eCont,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: hintCorreo,
              labelText: "Correo Institucional",
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: pCont,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: "Mínimo 6 caracteres",
              labelText: "Contraseña",
            ),
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: () => _validarYPasarAlPago(eCont, pCont, title),
            style: ElevatedButton.styleFrom(
              backgroundColor: unimetOrange,
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              "Crear cuenta",
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}