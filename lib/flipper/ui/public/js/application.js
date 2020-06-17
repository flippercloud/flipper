$(function() {
  $(document).on('click', '.js-toggle-trigger', function() {
    var $container = $(this).closest('.js-toggle-container');
    return $container.toggleClass('toggle-on');
  });
});
