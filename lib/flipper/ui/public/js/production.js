$(function() {
  $("[data-warn-on-click]").on("click", function() {
    return confirm("You are in PRODUCTION. Are you sure?");
  });
});