$(function() {
  var $certificatesTable = $('#certificates_table');

  if ($certificatesTable.length > 0) {
    window.certificatesTableStatuses = {
      'Не активирован': 'Не активирован',
      'Инициирован': 'Инициирован',
      'Активирован': 'Активирован',
      'Использован': 'Использован'
    };

    $certificatesTable.bootstrapTable({
      url: '/loyalty/certificates',
      pagination: true,
      pageSize: 40,
      pageList: [30, 40, 50, 100],
      sidePagination: 'server',
      showColumns: true,
      showRefresh: true,
      queryParamsType: '',
      filterControl: true,
      sortOrder: 'desc',
      columns: [
        {
          field: 'number',
          title: 'Номер',
          filterControl: 'input'
        },
        {
          field: 'status',
          title: 'Статус',
          filterControl: 'select',
          filterData: 'var_certificatesTableStatuses'
        },
        {
          field: 'purchase_sum',
          title: 'Сумма чека',
        },
        {
          field: 'card_number',
          title: 'Номер карты',
          filterControl: 'input'
        }
      ]
    });
  }
});
