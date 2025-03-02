import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:invoiceninja_flutter/constants.dart';
import 'package:invoiceninja_flutter/data/models/entities.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/ui/app/app_webview.dart';
import 'package:invoiceninja_flutter/ui/app/form_card.dart';
import 'package:invoiceninja_flutter/ui/app/forms/app_dropdown_button.dart';
import 'package:invoiceninja_flutter/ui/app/forms/app_form.dart';
import 'package:invoiceninja_flutter/ui/app/forms/bool_dropdown_button.dart';
import 'package:invoiceninja_flutter/ui/app/forms/decorated_form_field.dart';
import 'package:invoiceninja_flutter/ui/app/edit_scaffold.dart';
import 'package:invoiceninja_flutter/ui/app/scrollable_listview.dart';
import 'package:invoiceninja_flutter/ui/app/variables.dart';
import 'package:invoiceninja_flutter/ui/settings/templates_and_reminders_vm.dart';
import 'package:invoiceninja_flutter/utils/completers.dart';
import 'package:invoiceninja_flutter/utils/formatting.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';
import 'package:invoiceninja_flutter/utils/templates.dart';

class TemplatesAndReminders extends StatefulWidget {
  const TemplatesAndReminders({
    Key key,
    @required this.viewModel,
  }) : super(key: key);

  final TemplatesAndRemindersVM viewModel;

  @override
  _TemplatesAndRemindersState createState() => _TemplatesAndRemindersState();
}

class _TemplatesAndRemindersState extends State<TemplatesAndReminders>
    with SingleTickerProviderStateMixin {
  static final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(debugLabel: '_templatesAndReminders');
  final _debouncer = Debouncer(sendFirstAction: true);

  String _lastSubject;
  String _lastBody;
  String _subjectPreview = '';
  String _bodyPreview = '';
  String _defaultSubject = '';
  String _defaultBody = '';

  bool _isLoading = false;
  FocusScopeNode _focusNode;
  TabController _controller;

  static const kTabEdit = 0;

  //static const kTabPreview = 1;

  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();

  List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    _focusNode = FocusScopeNode();
    _controller = TabController(vsync: this, length: 2);
    _controller.addListener(_handleTabSelection);

    _controllers = [
      _subjectController,
      _bodyController,
    ];

    _subjectController.addListener(_onChanged);
    _bodyController.addListener(_onChanged);
  }

  @override
  void didChangeDependencies() {
    _loadTemplate(widget.viewModel.selectedTemplate);

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.removeListener(_handleTabSelection);
    _controller.dispose();
    _controllers.forEach((dynamic controller) {
      controller.removeListener(_onChanged);
      controller.dispose();
    });
    super.dispose();
  }

  void _loadTemplate(EmailTemplate emailTemplate) {
    final viewModel = widget.viewModel;
    final settings = viewModel.settings;
    final templateMap = viewModel.state.staticState.templateMap;

    _bodyController.removeListener(_onChanged);
    _subjectController.removeListener(_onChanged);

    _bodyController.text = settings.getEmailBody(emailTemplate);
    _subjectController.text = settings.getEmailSubject(emailTemplate);

    _bodyController.addListener(_onChanged);
    _subjectController.addListener(_onChanged);

    setState(() {
      final template = templateMap['$emailTemplate'] ?? TemplateEntity();
      _defaultSubject = template.subject;
      _defaultBody = template.body;
    });
  }

  void _onChanged() {
    _debouncer.run(() {
      final template = widget.viewModel.selectedTemplate;
      final String body = _bodyController.text.trim();
      final String subject = _subjectController.text.trim();

      SettingsEntity settings = widget.viewModel.settings;

      if (template == EmailTemplate.invoice) {
        settings = settings.rebuild((b) => b
          ..emailBodyInvoice = body
          ..emailSubjectInvoice = subject);
      } else if (template == EmailTemplate.quote) {
        settings = settings.rebuild((b) => b
          ..emailBodyQuote = body
          ..emailSubjectQuote = subject);
      } else if (template == EmailTemplate.credit) {
        settings = settings.rebuild((b) => b
          ..emailBodyCredit = body
          ..emailSubjectCredit = subject);
      } else if (template == EmailTemplate.payment) {
        settings = settings.rebuild((b) => b
          ..emailBodyPayment = body
          ..emailSubjectPayment = subject);
      } else if (template == EmailTemplate.payment_partial) {
        settings = settings.rebuild((b) => b
          ..emailBodyPaymentPartial = body
          ..emailSubjectPaymentPartial = subject);
      } else if (template == EmailTemplate.reminder1) {
        settings = settings.rebuild((b) => b
          ..emailBodyReminder1 = body
          ..emailSubjectReminder1 = subject);
      } else if (template == EmailTemplate.reminder2) {
        settings = settings.rebuild((b) => b
          ..emailBodyReminder2 = body
          ..emailSubjectReminder2 = subject);
      } else if (template == EmailTemplate.reminder3) {
        settings = settings.rebuild((b) => b
          ..emailBodyReminder3 = body
          ..emailSubjectReminder3 = subject);
      } else if (template == EmailTemplate.reminder_endless) {
        settings = settings.rebuild((b) => b
          ..emailBodyReminderEndless = body
          ..emailSubjectReminderEndless = subject);
      } else if (template == EmailTemplate.custom1) {
        settings = settings.rebuild((b) => b
          ..emailBodyCustom1 = body
          ..emailSubjectCustom1 = subject);
      } else if (template == EmailTemplate.custom2) {
        settings = settings.rebuild((b) => b
          ..emailBodyCustom2 = body
          ..emailSubjectCustom2 = subject);
      } else if (template == EmailTemplate.custom3) {
        settings = settings.rebuild((b) => b
          ..emailBodyCustom3 = body
          ..emailSubjectCustom3 = subject);
      } else if (template == EmailTemplate.statement) {
        settings = settings.rebuild((b) => b
          ..emailBodyStatement = body
          ..emailSubjectStatement = subject);
      }

      if (settings != widget.viewModel.settings) {
        widget.viewModel.onSettingsChanged(settings);
      }
    });
  }

  void _handleTabSelection() {
    if (_isLoading || _controller.index == kTabEdit) {
      return;
    }

    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();

    if (subject == _lastSubject && body == _lastBody) {
      return;
    } else {
      _lastSubject = subject;
      _lastBody = body;
    }

    setState(() {
      _isLoading = true;
    });

    loadEmailTemplate(
        context: context,
        template: '${widget.viewModel.selectedTemplate}',
        body: body,
        subject: subject,
        onComplete: (subject, body, rawSubject, rawBody) {
          if (!mounted) {
            return;
          }

          setState(() {
            _isLoading = false;
            _subjectPreview = subject.trim();
            _bodyPreview = body.trim();
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);
    final viewModel = widget.viewModel;
    final state = viewModel.state;
    final settings = viewModel.settings;
    final template = widget.viewModel.selectedTemplate;
    final company = state.company;

    return EditScaffold(
      title: localization.templatesAndReminders,
      onSavePressed: viewModel.onSavePressed,
      appBarBottom: TabBar(
        key: ValueKey(state.settingsUIState.updatedAt),
        controller: _controller,
        isScrollable: false,
        tabs: [
          Tab(
            text: localization.edit,
          ),
          Tab(
            text: localization.preview,
          ),
        ],
      ),
      body: AppTabForm(
        tabBarKey: ValueKey(
            '__${state.settingsUIState.updatedAt}_${_subjectPreview}_${_bodyPreview}_'),
        tabController: _controller,
        formKey: _formKey,
        focusNode: _focusNode,
        children: <Widget>[
          ScrollableListView(
            children: <Widget>[
              FormCard(children: <Widget>[
                AppDropdownButton<EmailTemplate>(
                  labelText: localization.template,
                  value: template,
                  showBlank: false,
                  onChanged: (dynamic value) => setState(() {
                    viewModel.onTemplateChanged(value);
                    _loadTemplate(value);
                  }),
                  items: EmailTemplate.values.where((value) {
                    if ([
                          EmailTemplate.invoice,
                          EmailTemplate.payment,
                          EmailTemplate.payment_partial,
                        ].contains(value) &&
                        !company.isModuleEnabled(EntityType.invoice)) {
                      return false;
                    } else if (value == EmailTemplate.quote &&
                        !company.isModuleEnabled(EntityType.quote)) {
                      return false;
                    } else if (value == EmailTemplate.credit &&
                        !company.isModuleEnabled(EntityType.credit)) {
                      return false;
                    }
                    // TODO remove this once statements are enabled
                    if (value == EmailTemplate.statement) {
                      return false;
                    }
                    return true;
                  }).map((item) {
                    var name = localization.lookup(item.name);
                    if (item == EmailTemplate.reminder1) {
                      name = localization.firstReminder;
                    } else if (item == EmailTemplate.reminder2) {
                      name = localization.secondReminder;
                    } else if (item == EmailTemplate.reminder3) {
                      name = localization.thirdReminder;
                    } else if (item == EmailTemplate.custom1) {
                      name = localization.firstCustom;
                    } else if (item == EmailTemplate.custom2) {
                      name = localization.secondCustom;
                    } else if (item == EmailTemplate.custom3) {
                      name = localization.thirdCustom;
                    }

                    return DropdownMenuItem<EmailTemplate>(
                      child: Text(name),
                      value: item,
                    );
                  }).toList(),
                ),
                DecoratedFormField(
                  label: localization.subject,
                  controller: _subjectController,
                  hint: _defaultSubject,
                ),
                DecoratedFormField(
                  keyboardType: TextInputType.multiline,
                  label: localization.body,
                  controller: _bodyController,
                  maxLines: 8,
                  hint: _defaultBody,
                ),
              ]),
              if (template == EmailTemplate.reminder1)
                ReminderSettings(
                  key: ValueKey('__reminder1_${template}__'),
                  viewModel: viewModel,
                  enabled: settings.enableReminder1,
                  numDays: settings.numDaysReminder1,
                  schedule: settings.scheduleReminder1,
                  feeAmount: settings.lateFeeAmount1,
                  feePercent: settings.lateFeePercent1,
                  onChanged: (enabled, days, schedule, feeAmount, feePercent) =>
                      viewModel.onSettingsChanged(settings.rebuild((b) => b
                        ..enableReminder1 = enabled
                        ..numDaysReminder1 = days
                        ..scheduleReminder1 = schedule
                        ..lateFeeAmount1 = feeAmount
                        ..lateFeePercent1 = feePercent)),
                ),
              if (template == EmailTemplate.reminder2)
                ReminderSettings(
                  key: ValueKey('__reminder2_${template}__'),
                  viewModel: viewModel,
                  enabled: settings.enableReminder2,
                  numDays: settings.numDaysReminder2,
                  schedule: settings.scheduleReminder2,
                  feeAmount: settings.lateFeeAmount2,
                  feePercent: settings.lateFeePercent2,
                  onChanged: (enabled, days, schedule, feeAmount, feePercent) =>
                      viewModel.onSettingsChanged(settings.rebuild((b) => b
                        ..enableReminder2 = enabled
                        ..numDaysReminder2 = days
                        ..scheduleReminder2 = schedule
                        ..lateFeeAmount2 = feeAmount
                        ..lateFeePercent2 = feePercent)),
                ),
              if (template == EmailTemplate.reminder3)
                ReminderSettings(
                  key: ValueKey('__reminder3_${template}__'),
                  viewModel: viewModel,
                  enabled: settings.enableReminder3,
                  numDays: settings.numDaysReminder3,
                  schedule: settings.scheduleReminder3,
                  feeAmount: settings.lateFeeAmount3,
                  feePercent: settings.lateFeePercent3,
                  onChanged: (enabled, days, schedule, feeAmount, feePercent) =>
                      viewModel.onSettingsChanged(settings.rebuild((b) => b
                        ..enableReminder3 = enabled
                        ..numDaysReminder3 = days
                        ..scheduleReminder3 = schedule
                        ..lateFeeAmount3 = feeAmount
                        ..lateFeePercent3 = feePercent)),
                ),
              if (template == EmailTemplate.reminder_endless)
                FormCard(
                  children: <Widget>[
                    BoolDropdownButton(
                      label: localization.sendEmail,
                      value: settings.enableReminderEndless,
                      onChanged: (value) => viewModel.onSettingsChanged(settings
                          .rebuild((b) => b..enableReminderEndless = value)),
                      iconData: Icons.email,
                    ),
                    AppDropdownButton(
                        labelText: localization.frequency,
                        value: settings.endlessReminderFrequencyId == '0'
                            ? null
                            : settings.endlessReminderFrequencyId,
                        onChanged: (dynamic value) =>
                            viewModel.onSettingsChanged(settings.rebuild(
                                (b) => b..endlessReminderFrequencyId = value)),
                        items: kFrequencies
                            .map((id, frequency) =>
                                MapEntry<String, DropdownMenuItem<String>>(
                                    id,
                                    DropdownMenuItem<String>(
                                      child:
                                          Text(localization.lookup(frequency)),
                                      value: id,
                                    )))
                            .values
                            .toList()),
                  ],
                ),
              VariablesHelp(
                //showEmailVariables: true,
                showInvoiceAsQuote: template == EmailTemplate.quote,
              ),
            ],
          ),
          EmailPreview(
            isLoading: _isLoading,
            subject: _subjectPreview,
            body: _bodyPreview,
          ),
        ],
      ),
    );
  }
}

class ReminderSettings extends StatefulWidget {
  const ReminderSettings({
    Key key,
    @required this.viewModel,
    @required this.enabled,
    @required this.schedule,
    @required this.onChanged,
    @required this.numDays,
    @required this.feeAmount,
    @required this.feePercent,
  }) : super(key: key);

  final TemplatesAndRemindersVM viewModel;
  final bool enabled;
  final int numDays;
  final double feeAmount;
  final double feePercent;
  final String schedule;
  final Function(bool, int, String, double, double) onChanged;

  @override
  _ReminderSettingsState createState() => _ReminderSettingsState();
}

class _ReminderSettingsState extends State<ReminderSettings> {
  final _daysController = TextEditingController();
  final _feeAmountController = TextEditingController();
  final _feePercentController = TextEditingController();

  bool _enabled;
  String _schedule;

  List<TextEditingController> _controllers = [];
  final _debouncer = Debouncer(sendFirstAction: true);

  @override
  void dispose() {
    _controllers.forEach((dynamic controller) {
      controller.removeListener(_onTextChanged);
      controller.dispose();
    });
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _enabled = widget.enabled;
    _schedule = widget.schedule;

    _controllers = [
      _daysController,
      _feeAmountController,
      _feePercentController,
    ];

    _controllers.forEach(
        (dynamic controller) => controller.removeListener(_onTextChanged));

    _daysController.text = '${widget.numDays ?? ''}';
    _feeAmountController.text = formatNumber(widget.feeAmount, context,
        formatNumberType: FormatNumberType.inputMoney);
    _feePercentController.text = formatNumber(widget.feePercent, context,
        formatNumberType: FormatNumberType.inputMoney);

    _controllers.forEach(
        (dynamic controller) => controller.addListener(_onTextChanged));

    super.didChangeDependencies();
  }

  void _onTextChanged() {
    _debouncer.run(() {
      _onChanged();
    });
  }

  void _onChanged() {
    final int days = parseInt(_daysController.text.trim(), zeroIsNull: true);
    final feeAmount =
        parseDouble(_feeAmountController.text.trim(), zeroIsNull: true);
    final feePercent =
        parseDouble(_feePercentController.text.trim(), zeroIsNull: true);

    widget.onChanged(_enabled, days, _schedule, feeAmount, feePercent);
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);

    return Column(
      children: <Widget>[
        FormCard(
          children: <Widget>[
            DecoratedFormField(
              label: localization.days,
              controller: _daysController,
              keyboardType: TextInputType.number,
            ),
            AppDropdownButton(
              value: widget.schedule,
              labelText: localization.schedule,
              onChanged: (dynamic value) {
                _schedule = value;
                _onChanged();
              },
              items: [
                DropdownMenuItem(
                  child: Text(localization.afterInvoiceDate),
                  value: kReminderScheduleAfterInvoiceDate,
                ),
                DropdownMenuItem(
                  child: Text(localization.beforeDueDate),
                  value: kReminderScheduleBeforeDueDate,
                ),
                DropdownMenuItem(
                  child: Text(localization.afterDueDate),
                  value: kReminderScheduleAfterDueDate,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: BoolDropdownButton(
                label: localization.sendEmail,
                value: widget.enabled,
                onChanged: (value) {
                  _enabled = value;
                  _onChanged();
                },
                iconData: Icons.email,
              ),
            ),
            DecoratedFormField(
              label: localization.lateFeeAmount,
              controller: _feeAmountController,
              isMoney: true,
            ),
            DecoratedFormField(
              label: localization.lateFeePercent,
              controller: _feePercentController,
              isPercent: true,
            ),
          ],
        ),
      ],
    );
  }
}

class EmailPreview extends StatelessWidget {
  const EmailPreview({
    @required this.subject,
    @required this.body,
    @required this.isLoading,
  });

  final String subject;
  final String body;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  subject,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      .copyWith(color: Colors.black),
                ),
              ),
              Expanded(
                child: AppWebView(html: body),
              ),
            ],
          ),
          if (isLoading)
            SizedBox(
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
