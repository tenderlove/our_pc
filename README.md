# OurPC

OurPC is an experimental implementation of a gRPC client and server.

OurPC uses nghttp2 for H2 support, Ruby sockets for networking and IO access, and Google Protobuf for protobuf encoding.

## Features

* Core implementation is pure Ruby

* Uses plain old Ruby IO objects, so server/client side timeouts can be provided to varios IO calls

* MIT licensed

## Limitations

* Doesn't support streaming yet.

## Fun times!

Try this!  In one terminal:

```
$ rake server
```

In a different terminal:

```
$ rake client
```

Neat!
