# Copyright (c) 2019 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

load("@bazel_skylib//lib:shell.bzl", "shell")

def _client_server_test_impl(ctx):

  # Construct wrapper to execute the runner, which in turn
  # will start the client and server.
  wrapper = ctx.actions.declare_file(ctx.label.name + "_wrapper.sh")
  ctx.actions.write(
    output = wrapper,
    content = """#!/usr/bin/env bash
{runner} '{client}' '{client_args}' '{server}' '{server_args}'
""".format(
      runner = ctx.executable._runner.short_path,
      client = ctx.executable.client.short_path,
      client_args = " ".join([ a.replace("'", "'\\''") for a in ctx.attr.client_args]),
      server = ctx.executable.server.short_path,
      server_args = " ".join([ a.replace("'", "'\\''") for a in ctx.attr.server_args]),
    ),
    is_executable = True
  )

  runfiles = ctx.runfiles(files = [wrapper])
  runfiles = runfiles.merge(ctx.attr._runner[DefaultInfo].default_runfiles)
  runfiles = runfiles.merge(ctx.attr.client[DefaultInfo].default_runfiles)
  runfiles = runfiles.merge(ctx.attr.server[DefaultInfo].default_runfiles)

  return struct(
    executable = wrapper,
    files = depset([wrapper]),
    runfiles = runfiles,
  )

client_server_test = rule(
  implementation = _client_server_test_impl,
  test = True,
  executable = True,
  attrs = {
    "_runner": attr.label(
      cfg = "host",
      allow_single_file = True,
      executable = True,
      default = Label("@//bazel_tools/client_server_test/runner:runner"),
    ),
    "client": attr.label(
      cfg = "target",
      executable = True,
    ),
    "client_args": attr.string_list(),
    "server": attr.label(
      cfg = "target",
      executable = True,
    ),
    "server_args": attr.string_list(),
  },
)
"""Create a client-server test.

The rule takes a client and server executables and their
arguments as parameters. The server port is passed via a
temporary file, which is passed to the server executable via the
"--port-file" parameter. The client application receives the port
via the "--target-port" argument.

The server process is killed after the client process exits.

The client and server executables can be any Bazel target that
is executable, e.g. scala_binary, sh_binary, etc.

Example:
  ```bzl
  client_server_test(
    name = "my_test",
    client = ":my_client",
    client_args = ["--extra-argument"],
    server = ":my_server",
    server_args = ["--fast"],
  )
  ```
"""
