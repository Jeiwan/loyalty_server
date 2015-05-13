$(function() {
  $('#upload_cards').on('submit', function(e) {
    if (typeof this.skipEvent !== 'undefined') {
      return this.skipEvent;
    }

    e.preventDefault();
    if ($('#file_to_upload').val().length === 0) {
      alert('Не выбран файл для загрузки!');
      return false;
    } else {
      this.skipEvent = true;
      return $(this).submit();
    }
  });

  var $cards_table = $('#cards_table');

  if ($cards_table.length > 0) {
    window.cardsTableStatuses = {
      'Не активирована': 'Не активирована',
      'Активирована': 'Активирована',
      'Деактивирована': 'Деактивирована',
      'Заблокирована': 'Заблокирована'
    };

    function operateFormatter (value, row, index) {
      var blockLink = "<a class='block text-danger' href='#' title='Заблокировать'>\
            <i class='glyphicon glyphicon-remove'></i>\
            </a>",
          unblockLink = "<a class='unblock text-success' href='#' title='Разблокировать'>\
            <i class='glyphicon glyphicon-ok'></i>\
            </a>";

      if (typeof row !== 'undefined' && row.status === 'Активирована') {
        return blockLink;
      } else if (typeof row !== 'undefined' && row.status === 'Заблокирована') {
        return unblockLink;
      } else {
        return '';
      }
    }

    var operateEvents = {
      'click .block': function(e, value, row, index) {
        e.preventDefault();

        $.ajax({
          url: '/loyalty/cards/' + row.number + '/block',
          method: 'POST',
          data: { _method: 'PUT' }
        })
        .success(function() {
          $cards_table.bootstrapTable('refresh');
        })
        .fail(function(xhr) {
          var response = JSON.parse(xhr.responseText);
          alert(response);
        });
      },
      'click .unblock': function(e, value, row, index) {
        e.preventDefault();

        $.ajax({
          url: '/loyalty/cards/' + row.number + '/unblock',
          method: 'POST',
          data: { _method: 'PUT' }
        })
        .success(function() {
          $cards_table.bootstrapTable('refresh');
        })
        .fail(function(xhr) {
          var response = JSON.parse(xhr.responseText);
          alert(response);
        });
      }
    };

    $cards_table.bootstrapTable({
      url: '/loyalty/cards',
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
          field: 'number',
          title: 'Номер',
          filterControl: 'input'
        },
        {
          field: 'balance',
          title: 'Баланс'
        },
        {
          field: 'status',
          title: 'Статус',
          filterControl: 'select',
          filterData: 'var_cardsTableStatuses'
        },
        {
          field: 'operate',
          title: 'Управление',
          events: operateEvents,
          formatter: operateFormatter
        }
      ]
    });
  }

  var $cards_table_filter = $('.fixed-table-toolbar');

  if ($cards_table_filter.length > 0) {
    $cards_table_filter.prepend('<div id="cards_table_filter" class="pull-left"></div>');
    $cards_table_filter = $cards_table_filter.find('#cards_table_filter');
    $cards_table_filter.bootstrapTableFilter({
      filters: [
        {
          field: 'balance',
          label: 'Баланс',
          type: 'range'
        }
      ],
      onSubmit: function() {
        var data = $cards_table_filter.bootstrapTableFilter('getData');
        $cards_table.bootstrapTable('refresh',
          {
            query: { filter: JSON.stringify(data) }
          }
        );
      }
    });
  }
});
