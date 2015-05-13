$(function() {
  var $purchasesTable = $('#purchases_table');

  if ($purchasesTable.length > 0) {
    window.purchasesTableKinds = {
      'Продажа': 'Продажа',
      'Возврат': 'Возврат'
    };

    $purchasesTable.bootstrapTable({
      url: '/loyalty/purchases',
      pagination: true,
      pageSize: 40,
      pageList: [30, 40, 50, 100],
      sidePagination: 'server',
      //search: true,
      showColumns: true,
      showRefresh: true,
      queryParamsType: '',
      filterControl: true,
      sortOrder: 'desc',
      columns: [
        {
          field: 'kind',
          title: 'Тип',
          filterControl: 'select',
          filterData: 'var_purchasesTableKinds'
        },
        {
          field: 'created_at',
          title: 'Дата',
          sortable: true
        },
        {
          field: 'pharmacy_name',
          title: 'Аптека',
          filterControl: 'input'
        },
        {
          field: 'sum',
          title: 'Сумма чека'
        },
        {
          field: 'card_number',
          title: 'Карта',
          sortable: true
        },
        {
          field: 'card_balance',
          title: 'Остаток баллов'
        }
      ]
    });
  }
});
