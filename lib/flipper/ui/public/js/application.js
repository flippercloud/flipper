$(function() {
  $(document).on('click', '.js-toggle-trigger', function() {
    var $container = $(this).closest('.js-toggle-container');
    return $container.toggleClass('toggle-on');
  });

  $("#delete_feature").click(function() {
    confirm(
      "Are you sure you want to remove this feature from the list of features and disable it for everyone?"
    );
  });
});
