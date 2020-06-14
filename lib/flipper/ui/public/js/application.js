(function() {
  $(function() {
    return $(document).on('click', '.js-toggle-trigger', function() {
      var $container;
      $container = $(this).closest('.js-toggle-container');
      return $container.toggleClass('toggle-on');
    });
  });

}).call(this);
