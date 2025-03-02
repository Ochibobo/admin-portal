import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:invoiceninja_flutter/data/models/entities.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/ui/invoice/edit/invoice_edit_contacts_vm.dart';
import 'package:invoiceninja_flutter/ui/invoice/edit/invoice_edit_details_vm.dart';
import 'package:invoiceninja_flutter/ui/invoice/edit/invoice_edit_footer.dart';
import 'package:invoiceninja_flutter/ui/invoice/edit/invoice_edit_items_vm.dart';
import 'package:invoiceninja_flutter/ui/invoice/edit/invoice_edit_notes_vm.dart';
import 'package:invoiceninja_flutter/ui/invoice/edit/invoice_edit_pdf_vm.dart';
import 'package:invoiceninja_flutter/ui/invoice/edit/invoice_edit_vm.dart';
import 'package:invoiceninja_flutter/ui/invoice/edit/invoice_item_selector.dart';
import 'package:invoiceninja_flutter/ui/app/edit_scaffold.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';

class InvoiceEdit extends StatefulWidget {
  const InvoiceEdit({
    Key key,
    @required this.viewModel,
  }) : super(key: key);

  final AbstractInvoiceEditVM viewModel;

  @override
  _InvoiceEditState createState() => _InvoiceEditState();
}

class _InvoiceEditState extends State<InvoiceEdit>
    with SingleTickerProviderStateMixin {
  TabController _controller;

  static final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(debugLabel: '_invoiceEdit');

  static const kDetailsScreen = 0;

  //static const kContactScreen = 1;
  static const kItemScreen = 2;

  //static const kNotesScreen = 3;

  @override
  void initState() {
    super.initState();

    final viewModel = widget.viewModel;

    final index =
        viewModel.invoiceItemIndex != null ? kItemScreen : kDetailsScreen;
    _controller = TabController(vsync: this, length: 5, initialIndex: index);
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.viewModel.invoiceItemIndex != null) {
      _controller.animateTo(kItemScreen);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSavePressed(BuildContext context, [EntityAction action]) {
    final bool isValid = _formKey.currentState.validate();

    /*
        setState(() {
          autoValidate = !isValid ?? false;
        });
         */

    if (!isValid) {
      return;
    }

    widget.viewModel.onSavePressed(context, action);
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);
    final viewModel = widget.viewModel;
    final invoice = viewModel.invoice;
    final state = viewModel.state;
    final prefState = state.prefState;
    final isFullscreen = prefState.isEditorFullScreen(EntityType.invoice);

    return EditScaffold(
      isFullscreen: isFullscreen,
      entity: invoice,
      title: invoice.isNew ? localization.newInvoice : localization.editInvoice,
      onCancelPressed: (context) => viewModel.onCancelPressed(context),
      onSavePressed: (context) => _onSavePressed(context),
      actions: [
        EntityAction.viewPdf,
        EntityAction.emailInvoice,
        if (!invoice.isPaid) EntityAction.newPayment,
        if (!invoice.isSent) EntityAction.markSent,
        if (!invoice.isPaid) EntityAction.markPaid,
      ],
      onActionPressed: (context, action) => _onSavePressed(context, action),
      appBarBottom: TabBar(
        controller: _controller,
        isScrollable: true,
        tabs: [
          Tab(
            text: localization.details,
          ),
          Tab(
            text: localization.contacts,
          ),
          Tab(
            text: localization.items,
          ),
          Tab(
            text: localization.notes,
          ),
          Tab(
            text: localization.pdf,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: isFullscreen
            ? InvoiceEditDetailsScreen(
                viewModel: widget.viewModel,
              )
            : TabBarView(
                key: ValueKey('__invoice_${invoice.id}_${invoice.updatedAt}__'),
                controller: _controller,
                children: <Widget>[
                  InvoiceEditDetailsScreen(
                    viewModel: widget.viewModel,
                  ),
                  InvoiceEditContactsScreen(
                    entityType: invoice.entityType,
                  ),
                  InvoiceEditItemsScreen(
                    viewModel: widget.viewModel,
                  ),
                  InvoiceEditNotesScreen(),
                  InvoiceEditPDFScreen(),
                ],
              ),
      ),
      bottomNavigationBar: InvoiceEditFooter(invoice: invoice),
      floatingActionButton: FloatingActionButton(
        heroTag: 'invoice_edit_fab',
        backgroundColor: Theme.of(context).primaryColorDark,
        onPressed: () {
          showDialog<InvoiceItemSelector>(
              context: context,
              builder: (BuildContext context) {
                return InvoiceItemSelector(
                  showTasksAndExpenses: true,
                  excluded: invoice.lineItems
                      .where((item) => item.isTask || item.isExpense)
                      .map((item) => item.isTask
                          ? viewModel.state.taskState.map[item.taskId]
                          : viewModel.state.expenseState.map[item.expenseId])
                      .toList(),
                  clientId: invoice.clientId,
                  onItemsSelected: (items, [clientId]) {
                    viewModel.onItemsAdded(items, clientId);
                    if (!isFullscreen) {
                      _controller.animateTo(kItemScreen);
                    }
                  },
                );
              });
        },
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: localization.addItem,
      ),
    );
  }
}
