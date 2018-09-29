# OurPC

OurPC is an experimental implementation of a gRPC client and server.

OurPC uses nghttp2, Ruby IO objects, and Protobuf as the building blocks for implementing a gRPC server and client.  The core of OurPC simply sets the right headers (including the Protobuf buffer prefix), and delegates to either the server code or the client code depending on the context.

## Features

* Core implementation is pure Ruby

* Uses plain old Ruby IO objects, so server/client side timeouts can be provided to varios IO calls

* MIT licensed

## Limitations

* Doesn't support streaming yet.

* OurPC doesn't have many tests (it's an experiment!)

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
