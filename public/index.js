$(function() {
  'use strict';

  function setMessage(klass, opt) {
    $(".help-block > span").hide();
    $(".help-block ." + klass).show();
    $(".help-block ." + klass + " .opt").text(opt || '');
    console.log(opt);
  }

  $('form').on('submit', function (e) {
    e.stopPropagation();
    e.preventDefault();

    setMessage('progress');
    $('#email').prop('disabled', true);

    $.ajax('/invite', {
      method: 'POST',
      data: JSON.stringify({ email: $('#email').val() }),
      contentType: 'application/json',
      dataType: 'json',
    })

    .done(function (data) {
      if (data.res) {
        data = JSON.parse(data.res);
      }
      console.log(data);
      
      if (data && data.ok) {
        setMessage('succeeded');
        $('#email').val('');
      }

      else {
        setMessage('failed', '(' + data.error + ')');
      }
    })

    .fail(function () {
      setMessage('failed');
    })

    .always(function () {
      $('#email').prop('disabled', false);
    });
  });
});
