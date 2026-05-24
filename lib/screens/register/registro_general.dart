import 'package:flutter/material.dart';
import 'package:vecinoapp/screens/register/widgets/register_asociation_form.dart';
import 'widgets/auth_tabs.dart';
import 'widgets/account_type_selector.dart';
import 'widgets/login_form.dart';
import 'widgets/register_citizen_form.dart';





class RegistroGeneral extends StatefulWidget {
  const RegistroGeneral({super.key});

  @override
  State<RegistroGeneral> createState() => _RegistroGeneralState();
}

class _RegistroGeneralState extends State<RegistroGeneral> {
  int selectedTab = 0;// 0 = Iniciar sesión, 1 = Registrarse
  int accountType = 0; // 0 ciudadano, 1 asociación
 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              const _HeaderRegistro(),
              const SizedBox(height: 20),

              // Aquí irá el widget de tabs
              
              AuthTabs( // botones de inicio de sesion o registro
              selectedIndex: selectedTab,
              onChanged: (i) => setState(() => selectedTab = i),
              ),


              const SizedBox(height: 20),

              if (selectedTab == 0) ...[
              // 👉 TAB: Iniciar sesión
              const LoginForm(),
              ] else ...[
              // 👉 TAB: Registrarse
              AccountTypeSelector(
              selected: accountType,
              onChanged: (v) => setState(() => accountType = v),
              ),
              if (accountType == 0) ...[
              const RegisterCitizenForm(),
              ] else ...[
              RegistroAsociacion(), // luego register asociación
              ],
        ],


            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderRegistro extends StatelessWidget {
  const _HeaderRegistro();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/logo_vecinoapp.png',
            width: 160,
            height: 160,
            
          ),
        ),
        const SizedBox(height: 10),
        
      ],
    );
  }
}
