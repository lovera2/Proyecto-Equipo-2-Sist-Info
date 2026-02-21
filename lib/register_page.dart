import 'package:flutter/material.dart';
import 'payment_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controladores para capturar los datos
  final TextEditingController _emailDocente = TextEditingController();
  final TextEditingController _passDocente = TextEditingController();
  
  final TextEditingController _emailEstudiante = TextEditingController();
  final TextEditingController _passEstudiante = TextEditingController();

  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);

  // Se validan los pagos
  void _validarYPasarAlPago(TextEditingController eCont, TextEditingController pCont, String rol) {
    // Usamos trim() para evitar errores de espacios accidentales
    final String emailVal = eCont.text.trim();
    final String passwordVal = pCont.text.trim();

    // Validar campos vacíos
    if (emailVal.isEmpty || passwordVal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Por favor, llena todos los campos"), 
          backgroundColor: Colors.red
        ),
      );
      return;
    }

    // Validar correo Unimet
    if (emailVal.endsWith('@unimet.edu.ve') || emailVal.endsWith('@correo.unimet.edu.ve')) {
      
      if (passwordVal.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ La clave debe tener al menos 6 caracteres"), 
            backgroundColor: Colors.red
          ),
        );
        return;
      }

      // Feedback positivo antes de saltar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Correo validado. Redirigiendo al pago..."), 
          backgroundColor: Colors.green
        ),
      );

      // Se navega con parametros
      Navigator.push(
        context, 
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            email: emailVal, 
            password: passwordVal,
            rol: rol,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Error: Usa tu correo institucional UNIMET"), 
          backgroundColor: Colors.red
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: unimetBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        iconTheme: const IconThemeData(color: Colors.white)
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
                  fontWeight: FontWeight.bold
                )
              ),
              const SizedBox(height: 40),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRoleCard("Docente", Icons.person_outline, _emailDocente, _passDocente),
                  const SizedBox(width: 20),
                  _buildRoleCard("Estudiante", Icons.school_outlined, _emailEstudiante, _passEstudiante),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String title, IconData icon, TextEditingController eCont, TextEditingController pCont) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]
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
                color: unimetBlue
              )
            ),
            const SizedBox(height: 20),
            TextField(
              controller: eCont, 
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: "ejemplo@unimet.edu.ve", 
                labelText: "Correo Institucional"
              )
            ),
            const SizedBox(height: 10),
            TextField(
              controller: pCont, 
              obscureText: true, 
              decoration: const InputDecoration(
                hintText: "Mínimo 6 caracteres", 
                labelText: "Contraseña"
              )
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () => _validarYPasarAlPago(eCont, pCont, title),
              style: ElevatedButton.styleFrom(
                backgroundColor: unimetOrange,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
              child: const Text(
                "Crear cuenta", 
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)
              ),
            ),
          ],
        ),
      ),
    );
  }
}