# Setup SSH Public Key Authentication #

When you use scp and ssh on the command-line, you might be used to being prompted for your username and password and typing them in.  Because the Upload with scp Automator action works in batch mode, it doesn't allow you to type in your password.  You'll need to use an automatic form of authentication – SSH public key authentication — for the Upload with scp Automator action to work correctly.

This document describes how to setup SSH public key authentication.  It assumes basic familiarity with the command-line.



## Goal ##

By following the steps in this document, you will learn how to create an SSH public key / private key pair on your computer, install the public key on the server you want to login to, and install the private key in your Mac OS X keychain.

## System requirements ##

  * Your computer: Mac OS X 10.5.1 or higher
  * The server: An account on the server that you can login to with SSH and that you can copy files to using scp (on the command-line).

## Terminal ##

You will need to execute commands on the command-line.  You can use Terminal.app, which can be found in the /Applications/Utilities folder.

In this tutorial, you will see code samples of the form:
```
$ whoami
jsmith
```
The line starting with `$` denotes the prompt.  You should type what appears after the `$` and hit the return key.  The output appears on the following line(s).  In this case, the user typed the command `whoami`, hit return, and the `whoami` program printed their username.

## Phase 1: Generate an SSH key pair ##

In this phase, we will generate your SSH public key / private key pair and store them on your computer.

  1. Create a folder on your computer that will store your SSH keys.
```
$ mkdir ~/.ssh
$ chmod 700 ~/.ssh
```
  1. Generate your SSH public key pair.  You will be prompted to pick a new password to protect your private key.  You should pick a secure password that is at least 8-10 characters long and hard for someone to guess; you will not need to remember this password on a day-to-day basis, so you should pick a strong password.
```
$ ssh-keygen -q -t rsa -b 2048 -f ~/.ssh/id_rsa
Enter passphrase (empty for no passphrase): …
Enter same passphrase again: …
$ chmod 600 ~/.ssh/*
```

## Phase 2: Copy your SSH public key to the server ##

In this phase, we will copy your SSH public key to the remote server.  In the following, replace **`jsmith`** with your username on the remote server and **`example.com`** with the domain name (or IP address) of the remote server.

  1. Copy your SSH public key to the remote server.  When prompted, enter your password for your account on the remote server.
```
$ scp ~/.ssh/id_rsa.pub jsmith@example.com:
jsmith@example.com's password: …
id_rsa.pub
```
  1. Login to the remote server. When prompted, enter your password for your account on the remote server.
```
$ ssh jsmith@example.com
jsmith@example.com's password: …
```
  1. Create a folder on the remote server for your SSH public key.
```
$ mkdir ~/.ssh
$ chmod 700 ~/.ssh
```
  1. Add your SSH public key to the list of accepted public keys for your account.
```
$ cat id_rsa.pub >> ~/.ssh/authorized_keys
$ chmod 600 ~/.ssh/authorized_keys
$ rm ~/id_rsa.pub
```
  1. Log out of the remote server.
```
$ logout
Connection to example.com closed.
```

## Phase 3: Testing SSH public key authentication ##

  1. Finally, we'll test logging in to the remote server using our new SSH public key.
```
$ ssh jsmith@example.com
```
  1. This time, instead of being prompted for your remote server password in the Terminal, a dialog box like the one below should pop up. ![http://automator-scp.googlecode.com/files/SetupSSHPublicKeyAuthentication-Keychain.png](http://automator-scp.googlecode.com/files/SetupSSHPublicKeyAuthentication-Keychain.png)
  1. Enter the password that you chose back in Phase 1 for your SSH private key.  Then click "Remember password in my keychain" to save that password: you won't need to enter that password every time you try to login to the remote server.  Since the keychain encrypts all of its contents under your Mac OS X password, its contents are safe.
  1. Log out of the remote server and close Terminal.app.
```
$ logout
Connection to example.com closed.
$ logout
```

## Congratulations! ##

If you successfully logged in to the server in Phase 3, entered your password in the dialog box that popped up, and saved the password in your keychain, you are ready to use the Upload with scp Automator action.

## Credits ##

This document is based on information in the following sources:
  * Anton Altaparmakov. Using SSH Agent With Mac OS X Leopard. http://www-uxsup.csx.cam.ac.uk/~aia21/osx/leopard-ssh.html
  * Jeremy Mates. OpenSSH Public Key Authentication. http://sial.org/howto/openssh/publickey-auth/