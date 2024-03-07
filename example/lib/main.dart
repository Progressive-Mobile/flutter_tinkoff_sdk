/*

  Copyright © 2020 ProgressiveMobile

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

import 'package:flutter/material.dart';
import 'package:tinkoff_sdk/tinkoff_sdk.dart';

void main() {
  runApp(Application());
}

class Application extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tinkoff SDK',
      home: MyApp(),
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TinkoffSdk acquiring = TinkoffSdk();

  static const _TERMINAL_KEY = '';
  static const _PASSWORD = '';
  static const _PUBLIC_KEY =
      '';

  final _terminalKeyController = TextEditingController(text: _TERMINAL_KEY);
  final _passwordController = TextEditingController(text: _PASSWORD);
  final _publicKeyController = TextEditingController(text: _PUBLIC_KEY);

  OrderOptions? _orderOptions;
  CustomerOptions? _customerOptions;
  FeaturesOptions _featuresOptions = FeaturesOptions();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _getAppBar(),
      body: _getLayout(),
    );
  }

  AppBar _getAppBar() => AppBar(
      title: Text('Tinkoff SDK'),
      centerTitle: true,
      actions: acquiring.activated
          ? [_getCardAttachAction(), _getSBPShowQRAction()]
          : []);

  Widget _getLayout() {
    if (!TinkoffSdk().activated) {
      return _getActivatePanel();
    } else {
      return _getPaymentLayout();
    }
  }

  Widget _getActivatePanel() {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _getTextForm('Terminal Key', _terminalKeyController),
          _getTextForm('Password', _passwordController),
          _getTextForm('Public Key', _publicKeyController),
          SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {
              acquiring
                  .activate(
                terminalKey: _terminalKeyController.text,
                password: _passwordController.text,
                publicKey: _publicKeyController.text,
                logging: true,
                isDeveloperMode: false,
              )
                  .then((_) {
                if (mounted) setState(() {});
              }).catchError(_showErrorDialog);
            },
            child: Text('Активировать'),
          )
        ],
      ),
    );
  }

  Widget _getPaymentLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          'Нажмите на карточку, чтобы внести в неё изменения',
          style: TextStyle(
            fontSize: 12.0,
            color: Colors.black54,
          ),
        ),
        SizedBox(height: 8.0),
        _getOrderCard(),
        _getCustomerCard(),
        _getFeatureCard(),
        SizedBox(height: 8.0),
        _getPaymentAction(),
        _getCardsAction(),
      ],
    );
  }

  Widget _getOrderCard() {
    return _getCardLayout(
      title: 'Данные заказа',
      body: _orderOptions != null
          ? Column(
              children: [
                _getEntryText('ID заказа', _orderOptions!.orderId,
                    required: true),
                _getEntryText('Заголовок', _orderOptions!.title,
                    required: true),
                _getEntryText('Описание', _orderOptions!.description,
                    required: true),
                _getEntryText('Сумма (в копейках)', _orderOptions!.amount),
                _getEntryText(
                    'Рекуррентный платеж', _orderOptions!.recurrentPayment)
              ],
            )
          : Text('Нажмите чтобы заполнить'),
      onTap: _showOrderOptionsDialog,
    );
  }

  Widget _getCustomerCard() {
    return _getCardLayout(
        title: 'Данные покупателя',
        body: _customerOptions != null
            ? Column(
                children: [
                  _getEntryText('ID', _customerOptions!.customerKey,
                      required: true),
                  _getEntryText('E-mail', _customerOptions!.email),
                  _getEntryText(
                      'Тип проверки карты', _customerOptions!.checkType)
                ],
              )
            : Text('Нажмите чтобы заполнить'),
        onTap: _showCustomerOptionsDialog);
  }

  Widget _getFeatureCard() {
    return _getCardLayout(
        title: 'Настройки экрана',
        body: Column(
          children: [
            _getEntryText('СБП включено', _featuresOptions.fpsEnabled),
            _getEntryText(
                'Безопасная клавиатура', _featuresOptions.useSecureKeyboard),
            _getEntryText('Сканер карт включён',
                _featuresOptions.enableCameraCardScanner),
            _getEntryText(
                'Обработка ошибок', _featuresOptions.handleCardListErrorInSdk),
            _getEntryText('Темная тема', _featuresOptions.darkThemeMode),
          ],
        ),
        onTap: _showFeatureOptionsDialog);
  }

  Widget _getPaymentAction() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24.0,
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _orderOptions != null && _customerOptions != null
                  ? () {
                      acquiring
                          .openPaymentScreen(
                            orderOptions: _orderOptions!,
                            customerOptions: _customerOptions!,
                            featuresOptions: _featuresOptions,
                            terminalKey: _TERMINAL_KEY,
                            publicKey: _PUBLIC_KEY,
                            androidReceipt: AndroidReceiptFfd105(
                              taxation: Taxation.osn,
                              email: '',
                              items: [
                                AndroidItem105(
                                  name: 'Кружка 350 мл',
                                  amount: 1000,
                                  tax: Tax.vat10,
                                  price: 1000,
                                  quantity: 1,
                                ),
                              ],
                            ),
                            iosReceipt: IosReceipt(
                              email: '',
                            ),
                          )
                          .then(_showResultDialog)
                          .catchError(_showErrorDialog);
                    }
                  : null,
              child: Text('Тестовая оплата'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getCardsAction() {
    return ElevatedButton(
      onPressed: _customerOptions != null
          ? () {
              acquiring.getCardList(_customerOptions!.customerKey);
            }
          : null,
      child: Text('Список карт'),
    );
  }

  Widget _getTextForm(
    String hint,
    TextEditingController controller, {
    TextInputType? keyboardType,
    bool isDialog = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
          vertical: 2.0, horizontal: isDialog ? 0.0 : 24.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType ?? TextInputType.text,
        decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: hint,
            alignLabelWithHint: true),
      ),
    );
  }

  Widget _getEntryText(String key, dynamic value, {bool required = false}) {
    final canShow = (value != null && value is! String) ||
        (value is String && value.isNotEmpty);
    return Row(
      children: [
        Text(key),
        Spacer(),
        Text(
          canShow ? value.toString() : 'не указано',
          style: TextStyle(
              fontSize: 12.0, color: canShow ? Colors.black : Colors.grey),
        ),
        if (!canShow && required)
          Icon(Icons.warning, color: Colors.red, size: 14.0)
      ],
    );
  }

  Widget _getCardLayout(
      {required String title, required Widget body, VoidCallback? onTap}) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 24.0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.start,
                style: TextStyle(fontSize: 12.0, color: Colors.grey),
              ),
              SizedBox(height: 4.0),
              body
            ],
          ),
        ),
      ),
    );
  }

  Future<Null> _showResultDialog(TinkoffResult result) async {
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Результат'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('Success: ' + result.success.toString()),
                  Text('isError: ' + result.isError.toString()),
                  Text('Message: ' + result.message.toString()),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Ok'),
                )
              ],
            ));
  }

  Future<Null> _showErrorDialog(error) async {
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Ошибка'),
              content: Text(error.toString()),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Ok'),
                )
              ],
            ));
  }

  void _showOrderOptionsDialog() async {
    final orderIdController =
        TextEditingController(text: _orderOptions?.orderId.toString() ?? '12397987');
    final titleController =
        TextEditingController(text: _orderOptions?.title ?? 'test');
    final descriptionController =
        TextEditingController(text: _orderOptions?.description ?? 'test');
    final amountController =
        TextEditingController(text: _orderOptions?.amount.toString() ?? '1000');
    final ValueNotifier<bool> reccurent =
        ValueNotifier(_orderOptions?.recurrentPayment ?? false);

    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              contentPadding: EdgeInsets.zero,
              content: SingleChildScrollView(
                padding: EdgeInsets.all(14.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _getTextForm('ID заказа', orderIdController,
                        keyboardType: TextInputType.number, isDialog: true),
                    _getTextForm(
                      'Заголовок',
                      titleController,
                      isDialog: true,
                    ),
                    _getTextForm(
                      'Описание',
                      descriptionController,
                      isDialog: true,
                    ),
                    _getTextForm('Сумма (в копейках)', amountController,
                        keyboardType: TextInputType.number, isDialog: true),
                    _getCheckboxRow('Рекуррентный платеж', reccurent),
                  ],
                ),
              ),
            ));
    final orderId = orderIdController.text;
    setState(() {
      _orderOptions = OrderOptions(
        orderId: orderId,
        amount: int.tryParse(amountController.text)!,
        title: titleController.text,
        description: descriptionController.text,
        recurrentPayment: reccurent.value,
      );
    });
  }

  void _showCustomerOptionsDialog() async {
    final idController =
        TextEditingController(text: _customerOptions?.customerKey ?? '1');
    final emailController = TextEditingController(
        text: _customerOptions?.email ?? 'fsog1920@gmail.com');
    final checkType =
        ValueNotifier<CheckType>(_customerOptions?.checkType ?? CheckType.no);

    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              contentPadding: EdgeInsets.zero,
              content: SingleChildScrollView(
                padding: EdgeInsets.all(14.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _getTextForm('ID', idController, isDialog: true),
                    _getTextForm('E-mail', emailController,
                        keyboardType: TextInputType.emailAddress,
                        isDialog: true),
                    Row(
                      children: <Widget>[
                        Text('Тип проверки'),
                        Spacer(),
                        ValueListenableBuilder<CheckType>(
                          valueListenable: checkType,
                          builder: (context, value, _) =>
                              DropdownButton<CheckType>(
                                  value: value,
                                  items: [
                                    DropdownMenuItem(
                                      value: CheckType.no,
                                      child: Text('NO'),
                                    ),
                                    DropdownMenuItem(
                                        value: CheckType.hold,
                                        child: Text('HOLD')),
                                    DropdownMenuItem(
                                        value: CheckType.threeDS,
                                        child: Text('3DS')),
                                    DropdownMenuItem(
                                        value: CheckType.threeDS_hold,
                                        child: Text('3DS_HOLD'))
                                  ],
                                  onChanged: (value) {
                                    checkType.value = value!;
                                  }),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ));
    setState(() {
      _customerOptions = CustomerOptions(
        customerKey: idController.text,
        email: emailController.text,
        checkType: checkType.value,
      );
    });
  }

  void _showFeatureOptionsDialog() async {
    final sbp = ValueNotifier<bool>(_featuresOptions.fpsEnabled);
    final secureKeyboard =
        ValueNotifier<bool>(_featuresOptions.useSecureKeyboard);
    final scanner =
        ValueNotifier<bool>(_featuresOptions.enableCameraCardScanner);
    final errorHandle =
        ValueNotifier<bool>(_featuresOptions.handleCardListErrorInSdk);
    final darkTheme =
        ValueNotifier<DarkThemeMode>(_featuresOptions.darkThemeMode);

    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              contentPadding: EdgeInsets.zero,
              content: SingleChildScrollView(
                padding: EdgeInsets.all(14.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _getCheckboxRow('СБП', sbp),
                    _getCheckboxRow('Безопасная клавиатура', secureKeyboard),
                    _getCheckboxRow('Сканнер карт', scanner),
                    _getCheckboxRow('Обработка ошибок', errorHandle),
                    Row(
                      children: <Widget>[
                        Text('Темная тема'),
                        Spacer(),
                        ValueListenableBuilder<DarkThemeMode>(
                          valueListenable: darkTheme,
                          builder: (context, value, _) =>
                              DropdownButton<DarkThemeMode>(
                                  value: value,
                                  items: [
                                    DropdownMenuItem(
                                      value: DarkThemeMode.auto,
                                      child: Text('AUTO'),
                                    ),
                                    DropdownMenuItem(
                                        value: DarkThemeMode.enabled,
                                        child: Text('ENABLED')),
                                    DropdownMenuItem(
                                        value: DarkThemeMode.disabled,
                                        child: Text('DISABLED'))
                                  ],
                                  onChanged: (value) {
                                    darkTheme.value = value!;
                                  }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ));
    setState(() {
      _featuresOptions = FeaturesOptions(
        fpsEnabled: sbp.value,
        useSecureKeyboard: secureKeyboard.value,
        enableCameraCardScanner: scanner.value,
        handleCardListErrorInSdk: errorHandle.value,
        darkThemeMode: darkTheme.value,
      );
    });
  }

  Widget _getCheckboxRow(String title, ValueNotifier<bool> valueListenable) {
    return Row(
      children: <Widget>[
        Text(title),
        Spacer(),
        ValueListenableBuilder<bool>(
          valueListenable: valueListenable,
          builder: (context, value, _) => Checkbox(
            value: value,
            onChanged: (value) => valueListenable.value = value!,
          ),
        ),
      ],
    );
  }

  Widget _getCardAttachAction() {
    return IconButton(
      icon: Icon(Icons.add_card_rounded),
      onPressed: _customerOptions != null
          ? () async {
              await acquiring.openAttachCardScreen(
                customerOptions: _customerOptions!,
                featuresOptions: _featuresOptions,
              );
            }
          : null,
    );
  }

  Widget _getSBPShowQRAction() {
    return IconButton(
      icon: Icon(Icons.qr_code_rounded),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isDismissible: true,
          constraints: BoxConstraints.expand(),
          builder: (context) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () async => await acquiring.showStaticQRCode(
                    featuresOptions: _featuresOptions,
                  ),
                  child: Text('Статический QR-код'),
                ),
                TextButton(
                  onPressed: () async => await acquiring.showDynamicQRCode(
                    iOSDynamicQrCode: IosDynamicQrCodeFullPaymentFlow(
                      orderOptions: _orderOptions!,
                    ),
                    androidDynamicQrCode: AndroidDynamicQrCode(
                      orderOptions: _orderOptions!,
                      customerOptions: _customerOptions!,
                      terminalKey: _TERMINAL_KEY,
                      publicKey: _PUBLIC_KEY,
                    ),
                  ),
                  child: Text('Динамический QR-код'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
