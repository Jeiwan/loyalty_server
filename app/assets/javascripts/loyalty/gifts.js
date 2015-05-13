$(function() {
  $(document).on('cocoon:after-insert', '.gift_positions', function(e, gift) {
    $(gift).find('.gift_position_search').select2({
      minimumInputLength: 3,
      multiple: false,
      ajax: {
        url: function () {
          return '/autocompletes/products?fields=name,replacement_code,assortment_code,code&categories='
        },
        dataType: 'json',
        quietMillis: 200,
        data: function (term, page) {
          return { q: term, page: page };
        },
        results: function (data, page) {
          var more = data.length == 50
          return { results: data, more: more };
        }
      },
      formatResult: function (assoc) {
        var addCode = null;
        if (assoc.replacement_code === null) {
          addCode = assoc.replacement_code;
        } else {
          addCode = assoc.assortment_code;
        }
        name = '<strong>' + assoc.assortment_category + ' ' + assoc.code + '</strong>' + ' ' + assoc.name;
        name = assoc.manufacturer === null ? name : name + ' ' + assoc.manufacturer;
        return addCode === null ? name : '(' + addCode + ') ' + name;
      },
      formatSelection: function (assoc) {
        return assoc.name;
      },
      initSelection: function (element, callback) {
        var value = $(element).data('initialValue');
        console.log(element, value);
        callback(value);
      }
    });
  })
});
