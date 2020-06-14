(function() {
  $(function() {
    return $(document).on('click', '.js-toggle-trigger', function() {
      var $container;
      console.log(this);
      $container = $(this).closest('.js-toggle-container');
      $container.toggleClass('toggle-on');
      if ($container.hasClass('toggle-on')) {
        return $container.find('.js-toggle-focus-when-on').focus();
      }
    });
  });

}).call(this);
