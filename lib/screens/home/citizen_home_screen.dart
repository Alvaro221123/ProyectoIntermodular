// ============================================================================
// CitizenHomeScreen
// ----------------------------------------------------------------------------
// Pantalla principal del usuario ciudadano.
//
// Responsabilidades:
// - Cargar el perfil del usuario autenticado.
// - Permitir crear, consultar, editar estado y eliminar alertas propias.
// - Consultar alertas comunitarias por código postal.
// - Gestionar ayudantes, chat y mensajes pendientes.
// - Mostrar y editar el perfil del usuario.
// - Mantener una interfaz visual coherente con los colores de VecinoApp.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/user_service.dart';
import '../../services/alert_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/spain_locations.dart';

class CitizenHomeScreen extends StatefulWidget {
  const CitizenHomeScreen({super.key});

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {

  // ===============================================================
  // 1. VARIABLES, SERVICIOS Y COLORES
  // En este bloque se declaran los servicios de Firebase, el estado de carga,
  // la opción seleccionada del menú lateral y la paleta visual de VecinoApp.
  // ===============================================================

  // 1- Servicio para leer datos del usuario desde Firestore
  final _userService = UserService();

  // 2- Servicio para gestionar alertas en Firestore
  final _alertService = AlertService();

  // 3- Aquí guardaremos los datos del usuario logueado
  Map<String, dynamic>? userData;

  // 4- Controla si todavía estamos cargando datos
  bool loading = true;

  // 5- Controla qué opción del menú lateral está seleccionada
  int selectedIndex = 0;

  // COLORES BASE DE VECINOAPP
// Usamos estos colores para unificar visualmente todo el panel ciudadano.
final Color primaryBlue = const Color(0xFF2F80ED);
final Color darkBlue = const Color(0xFF1E3A8A);
final Color lightBlue = const Color(0xFFEAF3FF);
final Color accentOrange = const Color(0xFFF2994A);
final Color backgroundColor = const Color(0xFFF5F7FB);



  // ===============================================================
  // 2. CICLO DE VIDA Y CARGA DE USUARIO
  // Métodos que se ejecutan al abrir la pantalla y cargan el perfil del usuario conectado.
  // ===============================================================

  @override
  void initState() {
    super.initState();

    // 6- Al entrar al panel, cargamos los datos del usuario
    _loadUser();
  }

  Future<void> _loadUser() async {
    // 7- Obtenemos el uid del usuario logueado
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // 8- Buscamos su perfil en Firestore
    final data = await _userService.getUserProfile(uid);

    // 9- Guardamos los datos y quitamos el loading
    setState(() {
      userData = data;
      loading = false;
    });
  }



  // ===============================================================
  // 3. ESTRUCTURA PRINCIPAL DE LA PANTALLA
  // Construye el Scaffold principal: AppBar, botón flotante, menú lateral y zona de contenido.
  // ===============================================================

  @override
  Widget build(BuildContext context) {
    // 16- Mientras cargan los datos del usuario mostramos spinner
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
  backgroundColor: backgroundColor,

  appBar: AppBar(
    automaticallyImplyLeading: false,
    backgroundColor: primaryBlue,
    foregroundColor: Colors.white,
    elevation: 3,

    title: Row(
      children: [
        const Text(
          'VecinoApp',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        const Spacer(),

        Text(
          'Hola, ${userData?['name'] ?? 'vecino'}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(width: 10),

        CircleAvatar(
          backgroundColor: accentOrange,
          child: Text(
            (userData?['name'] ?? 'V')
                .toString()
                .substring(0, 1)
                .toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  ),
        // 1- Botón flotante para emitir alertas desde cualquier apartado
  floatingActionButton: FloatingActionButton.extended(
  backgroundColor: accentOrange,
  foregroundColor: Colors.white,
  onPressed: _showCreateAlertDialog,
  icon: const Icon(Icons.add_alert),
  label: const Text(''),
),
      // 17- Row nos permite tener menú lateral + contenido principal
      body: Row(
        children: [
          // 18- Menú lateral izquierdo
          NavigationRail(

  // COLOR DE FONDO DEL MENÚ LATERAL
  backgroundColor: darkBlue,

  // OPCIÓN SELECCIONADA
  selectedIndex: selectedIndex,

  // COLOR ICONOS SELECCIONADOS
  selectedIconTheme: IconThemeData(
    color: accentOrange,
  ),

  // COLOR ICONOS NO SELECCIONADOS
  unselectedIconTheme: const IconThemeData(
    color: Colors.white70,
  ),

  // COLOR TEXTO SELECCIONADO
  selectedLabelTextStyle: TextStyle(
    color: accentOrange,
    fontWeight: FontWeight.bold,
  ),

  // COLOR TEXTO NORMAL
  unselectedLabelTextStyle: const TextStyle(
    color: Colors.white70,
  ),

  // CUANDO CAMBIAMOS DE APARTADO
  onDestinationSelected: (index) {
    setState(() {
      selectedIndex = index;
    });
  },

  // MOSTRAR TEXTO DEBAJO DE LOS ICONOS
  labelType: NavigationRailLabelType.all,

  // OPCIONES DEL MENÚ
  destinations: const [

    NavigationRailDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: Text('Inicio'),
    ),

    NavigationRailDestination(
      icon: Icon(Icons.warning_amber_outlined),
      selectedIcon: Icon(Icons.warning),
      label: Text('Activas'),
    ),

    NavigationRailDestination(
      icon: Icon(Icons.check_circle_outline),
      selectedIcon: Icon(Icons.check_circle),
      label: Text('Completadas'),
    ),

    NavigationRailDestination(
      icon: Icon(Icons.groups_outlined),
      selectedIcon: Icon(Icons.groups),
      label: Text('Comunidad'),
    ),

    NavigationRailDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: Text('Perfil'),
    ),
  ],
),

          // 20- Línea vertical separadora
          const VerticalDivider(width: 1),

          // 21- Zona principal de contenido
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildSelectedPage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPage() {
  // 1- Inicio
  if (selectedIndex == 0) {
    return _buildHomePage();
  }

  // 2- Alertas activas
  if (selectedIndex == 1) {
    return _buildActiveAlertsPage();
  }

  // 3- Alertas completadas
  if (selectedIndex == 2) {
    return _buildCompletedAlertsPage();
  }

  // 4- Alertas de la comunidad
  if (selectedIndex == 3) {
    return _buildCommunityAlertsPage();
  }

  // 5- Perfil
  return _buildProfilePage();
}



  // ===============================================================
  // 4. DIÁLOGOS Y ACCIONES PRINCIPALES
  // Formularios y ventanas emergentes para crear alertas, editar perfil, chat,
  // ayudantes, eliminar alertas y cerrar sesión.
  // ===============================================================

Future<void> _showCreateAlertDialog() async {

  // ---------------------------------------------------
  // CONTROLLERS DE LOS CAMPOS
  // ---------------------------------------------------
  final descriptionController =
      TextEditingController();

  final titleController =
      TextEditingController();

  // ---------------------------------------------------
  // VALORES INICIALES
  // ---------------------------------------------------
  String selectedType = 'seguridad';
  String selectedPriority = 'media';

  // ---------------------------------------------------
  // USUARIO ACTUAL
  // ---------------------------------------------------
  final user =
      FirebaseAuth.instance.currentUser;

  if (user == null) return;

  // ---------------------------------------------------
  // ABRIMOS EL DIÁLOGO
  // ---------------------------------------------------
  await showDialog(
    context: context,

    builder: (context) {

      return StatefulBuilder(
        builder: (
          context,
          setDialogState,
        ) {

          return AlertDialog(

            // ---------------------------------------------------
            // ESTILO GENERAL DEL DIALOG
            // ---------------------------------------------------
            backgroundColor: Colors.white,

            elevation: 8,

            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(24),
            ),

            // ---------------------------------------------------
            // TÍTULO MODERNO
            // ---------------------------------------------------
            title: Row(
              children: [

                CircleAvatar(
                  backgroundColor:
                      lightBlue,

                  child: Icon(
                    Icons.add_alert,
                    color: primaryBlue,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    'Emitir nueva alerta',

                    style: TextStyle(
                      color: darkBlue,
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
              ],
            ),

            // ---------------------------------------------------
            // CONTENIDO DEL FORMULARIO
            // ---------------------------------------------------
            content: SizedBox(
              width: 450,

              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [

                    // ---------------------------------------------------
                    // TIPO ALERTA
                    // ---------------------------------------------------
                    DropdownButtonFormField<String>(
                      value: selectedType,

                      decoration:
                          _modernInputDecoration(
                        label:
                            'Tipo de alerta',

                        icon:
                            Icons.category_outlined,
                      ),

                      dropdownColor:
                          Colors.white,

                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),

                      items: const [

                        DropdownMenuItem(
                          value:
                              'seguridad',

                          child: Text(
                            'Seguridad',
                          ),
                        ),

                        DropdownMenuItem(
                          value:
                              'incidencia',

                          child: Text(
                            'Incidencia',
                          ),
                        ),

                        DropdownMenuItem(
                          value:
                              'otros',

                          child: Text(
                            'Otros',
                          ),
                        ),
                      ],

                      onChanged: (value) {

                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedType =
                              value;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // ---------------------------------------------------
                    // TÍTULO ALERTA
                    // ---------------------------------------------------
                    TextField(
                      controller:
                          titleController,

                      decoration:
                          _modernInputDecoration(
                        label:
                            'Título alerta',

                        icon:
                            Icons.title,
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // ---------------------------------------------------
                    // PRIORIDAD
                    // ---------------------------------------------------
                    DropdownButtonFormField<String>(
                      value:
                          selectedPriority,

                      decoration:
                          _modernInputDecoration(
                        label:
                            'Prioridad',

                        icon:
                            Icons.priority_high,
                      ),

                      dropdownColor:
                          Colors.white,

                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),

                      items: const [

                        DropdownMenuItem(
                          value: 'baja',
                          child: Text(
                            'Baja',
                          ),
                        ),

                        DropdownMenuItem(
                          value: 'media',
                          child: Text(
                            'Media',
                          ),
                        ),

                        DropdownMenuItem(
                          value: 'alta',
                          child: Text(
                            'Alta',
                          ),
                        ),

                        DropdownMenuItem(
                          value:
                              'escalar_autoridades',

                          child: Text(
                            'Escalar con autoridades',
                          ),
                        ),
                      ],

                      onChanged: (value) {

                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedPriority =
                              value;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // ---------------------------------------------------
                    // DESCRIPCIÓN
                    // ---------------------------------------------------
                    TextField(
                      controller:
                          descriptionController,

                      maxLines: 4,

                      decoration:
                          _modernInputDecoration(
                        label:
                            'Descripción',

                        icon:
                            Icons.description_outlined,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---------------------------------------------------
            // BOTONES INFERIORES
            // ---------------------------------------------------
            actionsPadding:
                const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              16,
            ),

            actions: [

              // ---------------------------------------------------
              // CANCELAR
              // ---------------------------------------------------
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },

                child: Text(
                  'Cancelar',

                  style: TextStyle(
                    color: darkBlue,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

              // ---------------------------------------------------
              // GUARDAR ALERTA
              // ---------------------------------------------------
              _modernButton(
                onPressed: () async {

                  // VALIDAMOS DESCRIPCIÓN
                  if (descriptionController
                      .text
                      .trim()
                      .isEmpty) {

                    _showAppMessage(
                      title:
                          'Descripción obligatoria',

                      message:
                          'Debes introducir una descripción para continuar.',

                      icon:
                          Icons.warning_amber,

                      color:
                          Colors.orange,
                    );

                    return;
                  }

                  // VALIDAMOS TÍTULO
                  if (titleController
                      .text
                      .trim()
                      .isEmpty) {

                    _showAppMessage(
                      title:
                          'Título obligatorio',

                      message:
                          'Debes introducir un título para la alerta.',

                      icon:
                          Icons.warning_amber,

                      color:
                          Colors.orange,
                    );

                    return;
                  }

                  // ---------------------------------------------------
                  // CREAMOS ALERTA EN FIRESTORE
                  // ---------------------------------------------------
                  await _alertService
                      .createAlert(

                    title:
                        titleController
                            .text
                            .trim(),

                    type:
                        selectedType,

                    description:
                        descriptionController
                            .text
                            .trim(),

                    priority:
                        selectedPriority,

                    createdBy:
                        user.uid,

                    createdByEmail:
                        user.email ?? '',

                    city:
                        userData?['city']
                            ?? '',

                    postalCode:
                        userData?[
                                'postalCode']
                            ?? '',
                  );

                  if (!mounted) return;

                  // ---------------------------------------------------
                  // CERRAMOS DIALOG
                  // ---------------------------------------------------
                  Navigator.pop(context);

                  // ---------------------------------------------------
                  // MENSAJE ÉXITO
                  // ---------------------------------------------------
                  _showAppMessage(
                    title:
                        'Alerta creada',

                    message:
                        'La alerta se ha publicado correctamente.',

                    icon:
                        Icons.check_circle,

                    color:
                        Colors.green,
                  );

                  // ---------------------------------------------------
                  // CAMBIAMOS A ALERTAS ACTIVAS
                  // ---------------------------------------------------
                  setState(() {
                    selectedIndex = 1;
                  });
                },

                icon: Icons.save,
                text: 'Guardar',
                backgroundColor:
                    accentOrange,
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _showEditProfileDialog() async {

  // ---------------------------------------------------
  // CONTROLLERS PARA CAMPOS DE TEXTO
  // ---------------------------------------------------
  final nameController = TextEditingController(
    text: userData?['name'] ?? '',
  );

  final lastNameController = TextEditingController(
    text: userData?['lastName'] ?? '',
  );

  final addressController = TextEditingController(
    text: userData?['address'] ?? '',
  );

  final dniController = TextEditingController(
    text: userData?['dniNif'] ?? '',
  );

  // ---------------------------------------------------
  // VALORES ACTUALES DE UBICACIÓN
  // ---------------------------------------------------
  String? selectedProvince =
      userData?['city'];

  String? selectedPopulation =
      userData?['population'];

  String? selectedPostalCode =
      userData?['postalCode'];

  // ---------------------------------------------------
  // LISTA DE PROVINCIAS
  // ---------------------------------------------------
  final List<String> provinces =
      spainLocations.keys.toList();

  // ---------------------------------------------------
  // ABRIMOS EL DIALOG
  // ---------------------------------------------------
  await showDialog(
    context: context,

    builder: (context) {

      return StatefulBuilder(
        builder: (
          context,
          setDialogState,
        ) {

          // ---------------------------------------------------
          // POBLACIONES SEGÚN PROVINCIA
          // ---------------------------------------------------
          final populations =
              selectedProvince == null
                  ? <String>[]
                  : spainLocations[
                          selectedProvince!]!
                      .keys
                      .toList();

          // ---------------------------------------------------
          // CÓDIGOS POSTALES SEGÚN POBLACIÓN
          // ---------------------------------------------------
          final postalCodes =
              selectedProvince == null ||
                      selectedPopulation == null
                  ? <String>[]
                  : spainLocations[
                          selectedProvince!]![
                      selectedPopulation!]!;

          return AlertDialog(

            // ---------------------------------------------------
            // ESTILO GENERAL DEL DIALOG
            // ---------------------------------------------------
            backgroundColor:
                Colors.white,

            elevation: 8,

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                24,
              ),
            ),

            // ---------------------------------------------------
            // TÍTULO MODERNO
            // ---------------------------------------------------
            title: Row(
              children: [

                CircleAvatar(
                  backgroundColor:
                      lightBlue,

                  child: Icon(
                    Icons.edit,
                    color:
                        primaryBlue,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Text(
                  'Editar perfil',

                  style: TextStyle(
                    color:
                        darkBlue,
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ],
            ),

            // ---------------------------------------------------
            // CONTENIDO
            // ---------------------------------------------------
            content: SizedBox(
              width: 450,

              child:
                  SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [

                    // ---------------------------------------------------
                    // NOMBRE
                    // ---------------------------------------------------
                    TextField(
                      controller:
                          nameController,

                      decoration:
                          _modernInputDecoration(
                        label:
                            'Nombre',

                        icon:
                            Icons.person_outline,
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // ---------------------------------------------------
                    // APELLIDOS
                    // ---------------------------------------------------
                    TextField(
                      controller:
                          lastNameController,

                      decoration:
                          _modernInputDecoration(
                        label:
                            'Apellidos',

                        icon:
                            Icons.badge_outlined,
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // ---------------------------------------------------
                    // DIRECCIÓN
                    // ---------------------------------------------------
                    TextField(
                      controller:
                          addressController,

                      decoration:
                          _modernInputDecoration(
                        label:
                            'Dirección',

                        icon:
                            Icons.home_outlined,
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // ---------------------------------------------------
                    // PROVINCIA
                    // ---------------------------------------------------
                    DropdownButtonFormField<
                        String>(
                      value:
                          selectedProvince,

                      decoration:
                          _modernInputDecoration(
                        label:
                            'Provincia',

                        icon:
                            Icons.map_outlined,
                      ),

                      dropdownColor:
                          Colors.white,

                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),

                      items:
                          provinces.map(
                        (province) {

                          return DropdownMenuItem(
                            value:
                                province,

                            child: Text(
                              province,
                            ),
                          );
                        },
                      ).toList(),

                      onChanged:
                          (value) {

                        setDialogState(() {

                          selectedProvince =
                              value;

                          selectedPopulation =
                              null;

                          selectedPostalCode =
                              null;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // ---------------------------------------------------
                    // POBLACIÓN
                    // ---------------------------------------------------
                    DropdownButtonFormField<
                        String>(
                      value:
                          selectedPopulation,

                      decoration:
                          _modernInputDecoration(
                        label:
                            'Población',

                        icon:
                            Icons.location_city_outlined,
                      ),

                      dropdownColor:
                          Colors.white,

                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),

                      items:
                          populations.map(
                        (population) {

                          return DropdownMenuItem(
                            value:
                                population,

                            child: Text(
                              population,
                            ),
                          );
                        },
                      ).toList(),

                      onChanged:
                          selectedProvince ==
                                  null
                              ? null
                              : (value) {

                                  setDialogState(
                                    () {

                                      selectedPopulation =
                                          value;

                                      selectedPostalCode =
                                          null;
                                    },
                                  );
                                },
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // ---------------------------------------------------
                    // CÓDIGO POSTAL
                    // ---------------------------------------------------
                    DropdownButtonFormField<
                        String>(
                      value:
                          selectedPostalCode,

                      decoration:
                          _modernInputDecoration(
                        label:
                            'Código postal',

                        icon:
                            Icons.local_post_office_outlined,
                      ),

                      dropdownColor:
                          Colors.white,

                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),

                      items:
                          postalCodes.map(
                        (cp) {

                          return DropdownMenuItem(
                            value: cp,

                            child: Text(
                              cp,
                            ),
                          );
                        },
                      ).toList(),

                      onChanged:
                          selectedPopulation ==
                                  null
                              ? null
                              : (value) {

                                  setDialogState(
                                    () {

                                      selectedPostalCode =
                                          value;
                                    },
                                  );
                                },
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // ---------------------------------------------------
                    // DNI / NIF
                    // ---------------------------------------------------
                    TextField(
                      controller:
                          dniController,

                      decoration:
                          _modernInputDecoration(
                        label:
                            'DNI/NIF',

                        icon:
                            Icons.credit_card_outlined,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---------------------------------------------------
            // BOTONES INFERIORES
            // ---------------------------------------------------
            actionsPadding:
                const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              16,
            ),

            actions: [

              // ---------------------------------------------------
              // CANCELAR
              // ---------------------------------------------------
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                  );
                },

                child: Text(
                  'Cancelar',

                  style: TextStyle(
                    color:
                        darkBlue,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

              // ---------------------------------------------------
              // GUARDAR CAMBIOS
              // ---------------------------------------------------
              _modernButton(
                onPressed: () async {

  // =====================================================
  // VALIDACIÓN CAMPOS VACÍOS
  // =====================================================

  if (
      nameController.text.trim().isEmpty ||
      lastNameController.text.trim().isEmpty ||
      addressController.text.trim().isEmpty ||
      selectedProvince == null ||
      selectedPopulation == null ||
      selectedPostalCode == null ||
      dniController.text.trim().isEmpty
  ) {

    _showAppMessage(
      title: 'Campos incompletos',

      message:
          'Debes completar todos los campos del perfil.',

      icon: Icons.warning_amber_rounded,

      color: Colors.orange,
    );

    return;
  }

  // =====================================================
  // UID USUARIO ACTUAL
  // =====================================================

  final uid =
      FirebaseAuth.instance.currentUser!.uid;

  // =====================================================
  // ACTUALIZAR PERFIL FIRESTORE
  // =====================================================

  await _userService.updateUserProfile(
    uid: uid,

    name: nameController.text.trim(),

    lastName:
        lastNameController.text.trim(),

    address:
        addressController.text.trim(),

    city: selectedProvince!,

    population:
        selectedPopulation!,

    postalCode:
        selectedPostalCode!,

    dniNif:
        dniController.text.trim(),
  );

  // =====================================================
  // RECARGAR DATOS
  // =====================================================

  await _loadUser();

  if (!mounted) return;

  Navigator.pop(context);

  // =====================================================
  // MENSAJE ÉXITO
  // =====================================================

  _showAppMessage(
    title: 'Perfil actualizado',

    message:
        'Los datos del perfil se actualizaron correctamente.',

    icon: Icons.check_circle,

    color: Colors.green,
  );
},

                icon: Icons.save,

                text: 'Guardar',

                backgroundColor:
                    accentOrange,
              ),
            ],
          );
        },
      );
    },
  );
}

void _showChatDialog(String alertId) {

  // 1- Controlador para escribir mensajes
  final messageController = TextEditingController();

  // 2- Usuario actual
  final currentUser = FirebaseAuth.instance.currentUser;

  // 3- Si no hay usuario, salimos
  if (currentUser == null) return;
  // 4- Marcamos el chat como leído
_alertService.markChatAsRead(
  alertId: alertId,
  userId: currentUser.uid,
);

  // 4- Abrimos diálogo
  showDialog(
    context: context,
    builder: (context) {

      return AlertDialog(

        // 5- Título del chat
        title: const Text('Chat de la alerta'),

        // 6- Contenido principal
        content: SizedBox(
          width: 500,
          height: 500,

          child: Column(
            children: [

              // 7- Lista de mensajes
              Expanded(
                child: StreamBuilder(
                  stream: _alertService.getMessages(alertId),

                  builder: (context, snapshot) {

                    // 8- Mientras cargan mensajes
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    // 9- Si ocurre error
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Error al cargar mensajes',
                        ),
                      );
                    }

                    // 10- Obtenemos mensajes
                    final messages = snapshot.data!.docs;

                    // 11- Si no hay mensajes todavía
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'Todavía no hay mensajes',
                        ),
                      );
                    }

                    // 12- Lista de mensajes
                    return ListView.builder(
                      itemCount: messages.length,

                      itemBuilder: (context, index) {

                        final message =
                            messages[index].data()
                                as Map<String, dynamic>;

                        // 13- Comprobamos si el mensaje es mío
                        final isMine =
                            message['senderId'] ==
                                currentUser.uid;

                        return Align(
                          alignment: isMine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,

                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4,
                            ),

                            padding: const EdgeInsets.all(12),

                            decoration: BoxDecoration(
                              color: isMine
                                  ? Colors.blue.shade100
                                  : Colors.grey.shade300,

                              borderRadius:
                                  BorderRadius.circular(12),
                            ),

                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [

                                // 14- Nombre usuario
                                Text(
                                  message['senderName'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                // 15- Texto mensaje
                                Text(
                                  message['text'] ?? '',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // 16- Caja escribir mensaje
              Row(
                children: [

                  // 17- Input mensaje
                  Expanded(
                    child: TextField(
                      controller: messageController,

                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 18- Botón enviar
                  IconButton(
                    onPressed: () async {

                      // 19- Evitamos mensajes vacíos
                      if (messageController.text
                          .trim()
                          .isEmpty) {
                        return;
                      }

                      // 20- Enviamos mensaje a Firestore
                      await _alertService.sendMessage(
                        alertId: alertId,

                        senderId: currentUser.uid,

                        senderName:
                            userData?['name'] ?? '',

                        text: messageController.text.trim(),
                      );

                      // 21- Limpiamos input
                      messageController.clear();
                    },

                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 22- Botón cerrar
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cerrar'),
          ),
        ],
      );
    },
  );
}

void _showHelpersDialog(String alertId) {
  _showModernDialog(
    title: 'Personas ayudando',
    icon: Icons.groups_outlined,
    content: SizedBox(
      width: 420,
      height: 320,
      child: StreamBuilder(
        stream: _alertService.getAlertHelpers(alertId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: primaryBlue,
              ),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Error al cargar ayudantes'),
            );
          }

          final helpers = snapshot.data!.docs;

          if (helpers.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group_off_outlined,
                  size: 48,
                  color: primaryBlue,
                ),
                const SizedBox(height: 12),
                Text(
                  'Todavía no hay personas ayudando',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: darkBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            itemCount: helpers.length,
            itemBuilder: (context, index) {
              final helper =
                  helpers[index].data() as Map<String, dynamic>;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: accentOrange,
                      child: Text(
                        (helper['name'] ?? 'A')
                            .toString()
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            helper['name'] ?? 'Sin nombre',
                            style: TextStyle(
                              color: darkBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            helper['email'] ?? 'Sin email',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    ),
    actions: [
      _modernButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: Icons.close,
        text: 'Cerrar',
        backgroundColor: primaryBlue,
      ),
    ],
  );
}

void _showDeleteAlertDialog(String alertId) {
  _showModernDialog(
    title: 'Eliminar alerta',
    icon: Icons.delete_outline,
    content: const Text(
      '¿Seguro que quieres eliminar esta alerta? Esta acción no se puede deshacer.',
      style: TextStyle(
        fontSize: 15,
        height: 1.4,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Text(
          'Cancelar',
          style: TextStyle(
            color: darkBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      _modernButton(
        onPressed: () async {
          await _alertService.deleteAlert(alertId);

          if (!mounted) return;

          Navigator.pop(context);

          _showAppMessage(
            title: 'Alerta eliminada',
            message: 'La alerta se ha eliminado correctamente.',
            icon: Icons.check_circle,
            color: Colors.green,
          );
        },
        icon: Icons.delete,
        text: 'Eliminar',
        backgroundColor: Colors.red,
      ),
    ],
  );
}

void _showLogoutDialog() {
  _showModernDialog(
    title: 'Cerrar sesión',
    icon: Icons.logout,
    content: const Text(
      '¿Seguro que quieres cerrar sesión?',
      style: TextStyle(
        fontSize: 15,
        height: 1.4,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Text(
          'Cancelar',
          style: TextStyle(
            color: darkBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      _modernButton(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();

          if (!mounted) return;

          Navigator.pushReplacementNamed(context, '/');
        },
        icon: Icons.check,
        text: 'Sí, cerrar',
        backgroundColor: accentOrange,
      ),
    ],
  );
}



  // ===============================================================
  // 5. PÁGINAS DEL PANEL CIUDADANO
  // Cada método representa una sección del menú lateral: Inicio, Activas,
  // Completadas, Comunidad y Perfil.
  // ===============================================================

Widget _buildHomePage() {
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    return const Center(
      child: Text('No hay usuario conectado'),
    );
  }

  return Column(
    
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle(
  'Inicio',
  Icons.home,
),

      const SizedBox(height: 12),

      const Text(
        'Mensajes pendientes en tus alertas:',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),

      const SizedBox(height: 12),

      Expanded(
        child: StreamBuilder(
          stream: _alertService.getAlertsCreatedByUser(
            currentUser.uid,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text('Error al cargar mensajes pendientes'),
              );
            }

            final alerts = snapshot.data!.docs;

            if (alerts.isEmpty) {
              return const Text(
                'No tienes alertas creadas todavía.',
              );
            }

            return ListView.builder(
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert =
                    alerts[index].data() as Map<String, dynamic>;

                final alertId = alerts[index].id;

                return _modernCard(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      // ICONO IZQUIERDO
      Container(
        padding: const EdgeInsets.all(12),

        decoration: BoxDecoration(
          color: lightBlue,
          borderRadius: BorderRadius.circular(14),
        ),

        child: Icon(
          Icons.warning_amber_rounded,
          color: primaryBlue,
          size: 30,
        ),
      ),

      const SizedBox(width: 16),

      // CONTENIDO CENTRAL
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // TÍTULO ALERTA
            Text(
              alert['title'] ?? 'Sin título',

              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: darkBlue,
              ),
            ),

            const SizedBox(height: 10),

            // CHIPS VISUALES
            Wrap(
              spacing: 8,
              runSpacing: 8,

              children: [

                _chipLabel(
                  alert['type'],
                  primaryBlue,
                ),

                _chipLabel(
                  'Chat activo',
                  accentOrange,
                ),
              ],
            ),
          ],
        ),
      ),

      const SizedBox(width: 12),

      // ZONA DERECHA
      Column(
        children: [

          // CONTADOR MENSAJES
          _buildUnreadMessagesCounter(alertId),

          const SizedBox(height: 10),

          // BOTÓN CHAT
          Container(
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.circular(12),
            ),

            child: IconButton(
              onPressed: () {
                _showChatDialog(alertId);
              },

              icon: const Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ],
  ),
);
              },
            );
          },
        ),
      ),
      const SizedBox(height: 24),

const Text(
  'Alertas donde colaboras:',
  style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  ),
),

const SizedBox(height: 12),

Expanded(
  child: StreamBuilder(
    stream: _alertService.getAlertsWhereUserHelps(
      currentUser.uid,
    ),

    builder: (context, snapshot) {

      if (snapshot.connectionState ==
          ConnectionState.waiting) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (snapshot.hasError) {
        return const Center(
          child: Text(
            'Error al cargar colaboraciones',
          ),
        );
      }

      final alerts = snapshot.data!.docs;

      if (alerts.isEmpty) {
        return const Text(
          'No colaboras en ninguna alerta.',
        );
      }

      return ListView.builder(
        itemCount: alerts.length,

        itemBuilder: (context, index) {

          final alert =
              alerts[index].data()
                  as Map<String, dynamic>;

          final alertId = alerts[index].id;

          return _modernCard(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      // ICONO IZQUIERDO
      Container(
        padding: const EdgeInsets.all(12),

        decoration: BoxDecoration(
          color: lightBlue,
          borderRadius: BorderRadius.circular(14),
        ),

        child: Icon(
          Icons.groups_rounded,
          color: accentOrange,
          size: 30,
        ),
      ),

      const SizedBox(width: 16),

      // CONTENIDO PRINCIPAL
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // TÍTULO ALERTA
            Text(
              alert['title'] ?? 'Sin título',

              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: darkBlue,
              ),
            ),

            const SizedBox(height: 10),

            // ETIQUETAS VISUALES
            Wrap(
              spacing: 8,
              runSpacing: 8,

              children: [

                _chipLabel(
                  alert['type'],
                  primaryBlue,
                ),

                _chipLabel(
                  'Colaborando',
                  accentOrange,
                ),
              ],
            ),
          ],
        ),
      ),

      const SizedBox(width: 12),

      // ZONA DERECHA
      Column(
        children: [

          // MENSAJES PENDIENTES
          _buildUnreadMessagesCounter(alertId),

          const SizedBox(height: 10),

          // BOTÓN CHAT
          Container(
            decoration: BoxDecoration(
              color: accentOrange,
              borderRadius: BorderRadius.circular(12),
            ),

            child: IconButton(
              onPressed: () {
                _showChatDialog(alertId);
              },

              icon: const Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ],
  ),
);
        },
      );
    },
  ),
),
    ],
  );
}

  // 24- Página de alertas activas

  Widget _buildActiveAlertsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
  'Alertas activas',
  Icons.warning_amber,
),

        const SizedBox(height: 12),

        Expanded(
          child: StreamBuilder(
            // 25- Escuchamos alertas con estado activo
            stream: _alertService.getActiveAlertsByUser(
  FirebaseAuth.instance.currentUser!.uid,
),

            builder: (context, snapshot) {
              // 26- Estado de carga
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              // 27- Estado de error
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Error al cargar alertas'),
                );
              }

              // 28- Documentos obtenidos desde Firestore
              final alerts = snapshot.data!.docs;

              // 29- Si no hay alertas activas
              if (alerts.isEmpty) {
                return const Center(
                  child: Text('No hay alertas activas'),
                );
              }

              // 30- Lista dinámica de alertas
              return ListView.builder(
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alert =
                      alerts[index].data() as Map<String, dynamic>;
                      final alertId = alerts[index].id;

                  return _modernCard(
                    
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 1- Título principal
      Text(
        alert['title'] ?? 'Sin título',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: darkBlue,
        ),
      ),

      const SizedBox(height: 12),

      // 2- Etiquetas visuales
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _chipLabel(alert['type'], primaryBlue),
          _chipLabel(alert['priority'], accentOrange),
          _chipLabel(alert['status'], Colors.green),
        ],
      ),

      const SizedBox(height: 16),

      // 3- Descripción
      Text(
        alert['description'],
        style: const TextStyle(
          fontSize: 15,
          height: 1.5,
          color: Colors.black87,
        ),
      ),

      const SizedBox(height: 18),

      // 4- Selector de estado
      DropdownButtonFormField<String>(
        value: alert['status'],
        decoration: InputDecoration(
          labelText: 'Estado',
          filled: true,
          fillColor: lightBlue,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        items: const [
          DropdownMenuItem(value: 'activo', child: Text('Activo')),
          DropdownMenuItem(value: 'en_proceso', child: Text('En proceso')),
          DropdownMenuItem(value: 'completado', child: Text('Completado')),
          DropdownMenuItem(value: 'cancelado', child: Text('Cancelado')),
        ],
        onChanged: (value) async {
          if (value == null) return;

          await _alertService.updateAlertStatus(
            alertId: alertId,
            status: value,
          );

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Estado actualizado')),
          );
        },
      ),

      const SizedBox(height: 18),

      // 5- Botones de acción
      Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,

  children: [

    SizedBox(
      width: double.infinity,

      child: _modernButton(
        onPressed: () {
          _showHelpersDialog(alertId);
        },

        icon: Icons.group,

        text: 'Ver ayudantes',

        backgroundColor: accentOrange,
      ),
    ),

    const SizedBox(height: 12),

    SizedBox(
      width: double.infinity,

      child: _modernButton(
        onPressed: () {
          _showChatDialog(alertId);
        },

        icon: Icons.chat_bubble_outline,

        text: 'Chat',

        backgroundColor: primaryBlue,
      ),
    ),

    const SizedBox(height: 10),

    _buildUnreadMessagesCounter(alertId),

    const SizedBox(height: 12),

    SizedBox(
      width: double.infinity,

      child: _modernButton(
        onPressed: () {
          _showDeleteAlertDialog(alertId);
        },

        icon: Icons.delete,

        text: 'Eliminar',

        backgroundColor: Colors.red,
      ),
    ),
  ],
),
    ],
  ),
);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedAlertsPage() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 1- Título del apartado
      _sectionTitle(
  'Alertas completadas',
  Icons.check_circle,
),

      const SizedBox(height: 12),

      // 2- Expanded permite que la lista ocupe el espacio disponible
      Expanded(
        child: StreamBuilder(
          // 3- Escuchamos solo alertas completadas
          stream: _alertService.getCompletedAlertsByUser(
  FirebaseAuth.instance.currentUser!.uid,
),

          builder: (context, snapshot) {
            // 4- Mientras Firestore carga datos
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // 5- Si ocurre algún error
            if (snapshot.hasError) {
              return const Center(
                child: Text('Error al cargar alertas completadas'),
              );
            }

            // 6- Obtenemos los documentos de Firestore
            final alerts = snapshot.data!.docs;

            // 7- Si no hay alertas completadas
            if (alerts.isEmpty) {
              return const Center(
                child: Text('No hay alertas completadas'),
              );
            }

            // 8- Mostramos las alertas completadas en tarjetas
            return ListView.builder(
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert =
                    alerts[index].data() as Map<String, dynamic>;
                     // 2- ID del documento Firestore
  

                return _modernCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      // TÍTULO DE LA ALERTA
      Text(
        alert['title'] ?? 'Sin título',

        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: darkBlue,
        ),
      ),

      const SizedBox(height: 14),

      // CHIPS VISUALES
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [

          _chipLabel(
            alert['type'],
            primaryBlue,
          ),

          _chipLabel(
            alert['priority'],
            accentOrange,
          ),

          _chipLabel(
            alert['status'],
            Colors.green,
          ),
        ],
      ),

      const SizedBox(height: 18),

      // DESCRIPCIÓN
      Text(
        alert['description'],

        style: const TextStyle(
          fontSize: 15,
          height: 1.5,
          color: Colors.black87,
        ),
      ),

      const SizedBox(height: 18),

      // MENSAJE VISUAL DE ALERTA FINALIZADA
      Container(
        width: double.infinity,

        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.10),

          borderRadius: BorderRadius.circular(14),

          border: Border.all(
            color: Colors.green.withOpacity(0.3),
          ),
        ),

        child: const Row(
          children: [

            Icon(
              Icons.check_circle,
              color: Colors.green,
            ),

            SizedBox(width: 10),

            Text(
              'Alerta completada',

              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
);
              },
            );
          },
        ),
      ),
    ],
  );
}

Widget _buildCommunityAlertsPage() {

  // 1- Obtenemos el uid del usuario actual
  final currentUserId =
      FirebaseAuth.instance.currentUser!.uid;

  // 2- Obtenemos la ciudad del usuario actual
  final currentCity = userData?['city'] ?? '';

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      // 3- Título del apartado
      _sectionTitle(
  'Alertas de la comunidad',
  Icons.groups,
),

      const SizedBox(height: 12),

      // 4- Lista de alertas de la comunidad
      Expanded(
        child: StreamBuilder(

          // 5- Escuchamos alertas de la misma ciudad
          stream: _alertService.getCommunityAlerts(
            postalCode: userData?['postalCode'] ?? '',
            currentUserId: currentUserId,
          ),

          builder: (context, snapshot) {

            // 6- Mientras cargan datos
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // 7- Si ocurre error
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Error al cargar alertas comunidad',
                ),
              );
            }

            // 8- Obtenemos documentos Firestore
            final alerts = snapshot.data!.docs;

            // 9- Filtramos alertas propias
            final filteredAlerts = alerts.where((doc) {

              final data =
                  doc.data() as Map<String, dynamic>;

              return data['createdBy'] != currentUserId;

            }).toList();

            // 10- Si no hay alertas cercanas
            if (filteredAlerts.isEmpty) {
              return const Center(
                child: Text(
                  'No hay alertas de la comunidad cercanas',
                ),
              );
            }

            // 11- Mostramos lista de alertas
            return ListView.builder(
              itemCount: filteredAlerts.length,

              itemBuilder: (context, index) {

                // 12- Datos alerta
                final alert =
                    filteredAlerts[index].data()
                        as Map<String, dynamic>;

                      final alertId = filteredAlerts[index].id;

                return _modernCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      // TÍTULO DE LA ALERTA
      Text(
        alert['title'] ?? 'Sin título',

        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: darkBlue,
        ),
      ),

      const SizedBox(height: 14),

      // ETIQUETAS VISUALES
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [

          _chipLabel(
            alert['type'],
            primaryBlue,
          ),

          _chipLabel(
            alert['priority'],
            accentOrange,
          ),

          _chipLabel(
            'Comunidad',
            Colors.green,
          ),
        ],
      ),

      const SizedBox(height: 18),

      // DESCRIPCIÓN
      Text(
        alert['description'],

        style: const TextStyle(
          fontSize: 15,
          height: 1.5,
          color: Colors.black87,
        ),
      ),

      const SizedBox(height: 14),

      // UBICACIÓN
      Row(
        children: [

          Icon(
            Icons.location_on,
            color: primaryBlue,
            size: 20,
          ),

          const SizedBox(width: 6),

          Text(
            alert['city'] ?? '',

            style: TextStyle(
              color: darkBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),

      const SizedBox(height: 18),

// ---------------------------------------------------
// BOTÓN AYUDAR / YA INSCRITO
// ---------------------------------------------------
StreamBuilder(
  stream: _alertService.getAlertHelpers(alertId),

  builder: (context, helperSnapshot) {

    final currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    bool alreadyHelping = false;

    if (helperSnapshot.hasData) {

      alreadyHelping =
          helperSnapshot.data!.docs.any(
        (doc) {

          return doc.id ==
              currentUser.uid;
        },
      );
    }

    // ---------------------------------------------------
    // SI YA ESTÁ AYUDANDO
    // ---------------------------------------------------
    if (alreadyHelping) {

      return SizedBox(
        width: double.infinity,

        child: _modernButton(
          onPressed: () {},

          icon: Icons.check_circle,

          text: 'Ya estás ayudando',

          backgroundColor: Colors.grey.shade500,
        ),
      );
    }

    // ---------------------------------------------------
    // BOTÓN UNIRSE
    // ---------------------------------------------------
    return SizedBox(
      width: double.infinity,

      child: _modernButton(
        onPressed: () async {

          final user =
              FirebaseAuth.instance.currentUser;

          if (user == null) return;

          await _alertService.joinAlert(
            alertId: alertId,

            userId: user.uid,

            name: userData?['name'] ?? '',

            email: user.email ?? '',
          );

          if (!mounted) return;

          _showAppMessage(
            title: 'Te has unido',
            message:
                'Ahora estás colaborando en esta alerta.',
            icon: Icons.volunteer_activism,
            color: Colors.green,
          );
        },

        icon: Icons.volunteer_activism,

        text: 'Ayudar',

        backgroundColor: Colors.green,
      ),
    );
  },
),

      const SizedBox(height: 18),

      // BOTONES DE ACCIÓN
      Wrap(
        spacing: 10,
        runSpacing: 10,

        children: [

          

          // BOTÓN CHAT
          SizedBox(
  width: double.infinity,

  child: _modernButton(
    onPressed: () {
      _showChatDialog(alertId);
    },

    icon: Icons.chat_bubble_outline,

    text: 'Chat',

    backgroundColor: primaryBlue,
  ),
),

          // CONTADOR MENSAJES
          _buildUnreadMessagesCounter(alertId),
        ],
      ),
    ],
  ),
);
              },
            );
          },
        ),
      ),
    ],
  );
}
// BLOQUE VISUAL: título grande de cada sección

  Widget _buildProfilePage() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 1- Título del apartado
      _sectionTitle(
        'Perfil',
        Icons.person,
      ),

      const SizedBox(height: 24),

      // 2- Card moderna del perfil
      _modernCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 3- Cabecera con avatar, nombre y email
            Row(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: accentOrange,
                  child: Text(
                    (userData?['name'] ?? 'V')
                        .toString()
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 18),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${userData?['name'] ?? ''} ${userData?['lastName'] ?? ''}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkBlue,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        userData?['email'] ?? '',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // 4- Datos personales
            _profileRow(
              Icons.home_outlined,
              'Dirección',
              userData?['address'] ?? '',
            ),

            _profileRow(
              Icons.location_city,
              'Provincia',
              userData?['city'] ?? '',
            ),

            _profileRow(
              Icons.map_outlined,
              'Población',
              userData?['population'] ?? '',
            ),

            _profileRow(
              Icons.local_post_office_outlined,
              'Código postal',
              userData?['postalCode'] ?? '',
            ),

            _profileRow(
              Icons.credit_card_outlined,
              'DNI/NIF',
              userData?['dniNif'] ?? '',
            ),

            const SizedBox(height: 26),

            // 5- Botones de acción
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
  width: double.infinity,

  child: _modernButton(
    onPressed: () {
      _showEditProfileDialog();
    },

    icon: Icons.edit,

    text: 'Editar perfil',

    backgroundColor: primaryBlue,
  ),
),

                SizedBox(
  width: double.infinity,

  child: _modernButton(
    onPressed: () {
      _showLogoutDialog();
    },

    icon: Icons.logout,

    text: 'Cerrar sesión',

    backgroundColor: accentOrange,
  ),
),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}
  // 22- Esta función decide qué apartado mostrar según el menú



  // ===============================================================
  // 6. COMPONENTES VISUALES REUTILIZABLES
  // Helpers para evitar repetir código visual: cards, botones, títulos, chips,
  // fila de perfil, inputs y diálogos modernos.
  // ===============================================================

Widget _sectionTitle(String title, IconData icon) {
  return Row(
    children: [
      Icon(icon, color: primaryBlue, size: 28),
      const SizedBox(width: 10),
      Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: darkBlue,
        ),
      ),
    ],
  );
}

// BLOQUE VISUAL: tarjeta moderna reutilizable

Widget _modernCard({
  required Widget child,
  Color backgroundColor = Colors.white,
}) {
  return Card(
    elevation: 4,
    shadowColor: Colors.black12,
    color: backgroundColor,
    shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(18),

  side: BorderSide(
    color: const Color.fromARGB(255, 28, 110, 177),
    width: 1.5,
  ),
),
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: child,
    ),
  );
}

Widget _modernButton({
  required VoidCallback onPressed,
  required IconData icon,
  required String text,

  Color? backgroundColor,
  Color? foregroundColor,
}) {

  return ElevatedButton.icon(

    onPressed: onPressed,

    icon: Icon(icon),

    label: Text(text),

    style: ElevatedButton.styleFrom(

      backgroundColor:
          backgroundColor ?? primaryBlue,

      foregroundColor:
          foregroundColor ?? Colors.white,

      elevation: 0,

      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),

      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    ),
  );
}

Widget _chipLabel(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    ),
  );
}

Widget _profileRow(
  IconData icon,
  String label,
  String value,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: primaryBlue,
          size: 22,
        ),

        const SizedBox(width: 12),

        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: darkBlue,
          ),
        ),

        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );
}
// BOTÓN MODERNO REUTILIZABLE

InputDecoration _modernInputDecoration({
  required String label,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: label,
    floatingLabelBehavior:
    FloatingLabelBehavior.always,
    isDense: false,
    prefixIcon: Icon(icon, color: primaryBlue),
    filled: true,
    fillColor: lightBlue,
    contentPadding: const EdgeInsets.only(
  left: 14,
  right: 14,
  top: 24,
  bottom: 16,
),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: primaryBlue,
        width: 1.5,
      ),
    ),
  );
}

Future<void> _showModernDialog({
  required String title,
  required Widget content,
  required List<Widget> actions,
  IconData icon = Icons.info_outline,
}) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: lightBlue,
              child: Icon(
                icon,
                color: primaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: darkBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: content,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: actions,
      );
    },
  );
}

void _showAppMessage({
  required String title,
  required String message,
  required IconData icon,
  required Color color,
}) {
  _showModernDialog(
    title: title,
    icon: icon,
    content: Text(
      message,
      style: const TextStyle(
        fontSize: 15,
        height: 1.4,
      ),
    ),
    actions: [
      _modernButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: Icons.check,
        text: 'Aceptar',
        backgroundColor: color,
      ),
    ],
  );
}
// BLOQUE VISUAL: etiqueta tipo chip

Widget _buildUnreadMessagesCounter(String alertId) {
  // 1- Obtenemos el usuario actual
  final currentUser = FirebaseAuth.instance.currentUser;

  // 2- Si no hay usuario, no mostramos nada
  if (currentUser == null) {
    return const SizedBox.shrink();
  }

  // 3- Leemos cuándo fue la última vez que este usuario abrió el chat
  return StreamBuilder(
    stream: _alertService.getReadStatus(
      alertId: alertId,
      userId: currentUser.uid,
    ),

    builder: (context, readSnapshot) {
      // 4- Si todavía no hay estado de lectura, usamos una fecha antigua
      Timestamp lastReadAt = Timestamp.fromDate(
        DateTime(2000),
      );

      // 5- Si existe lectura previa, usamos esa fecha
      if (readSnapshot.hasData && readSnapshot.data!.exists) {
        final data =
            readSnapshot.data!.data() as Map<String, dynamic>;

        lastReadAt = data['lastReadAt'];
      }

      // 6- Buscamos mensajes posteriores a la última lectura
      return StreamBuilder(
        stream: _alertService.getUnreadMessages(
          alertId: alertId,
          userId: currentUser.uid,
          lastReadAt: lastReadAt,
        ),

        builder: (context, messageSnapshot) {
          // 7- Si todavía no hay datos, no mostramos contador
          if (!messageSnapshot.hasData) {
            return const SizedBox.shrink();
          }

          // 8- Filtramos mensajes que NO sean míos
          final unreadMessages =
              messageSnapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return data['senderId'] != currentUser.uid;
          }).toList();

          // 9- Si no hay mensajes pendientes, no mostramos nada
          if (unreadMessages.isEmpty) {
            return const SizedBox.shrink();
          }

          // 10- Mostramos el contador
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${unreadMessages.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      );
    },
  );
}

}
