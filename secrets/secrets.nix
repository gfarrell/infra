let
  leviathan = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGLOrRJKRHSldOrXEEedw/uDpT1LiKtgULE2Q2uDLykp gideon@leviathan";
  pharos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILZ1YjtQUTwlZ4N6SdDCWPHeKnthoDlBYZCaL2Fv5XJh root@pharos";

  # All keys that can decrypt secrets
  allKeys = [leviathan pharos];
in {
  # Wedding website secrets
  "wedding-website-rsvp-password.age".publicKeys = allKeys;
}
