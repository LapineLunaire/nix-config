{...}: {
  # "!" disables root login
  users.users.root.hashedPassword = "!";
  users.mutableUsers = false;
}
