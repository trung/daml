// Copyright (c) 2019 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
// SPDX-License-Identifier: Apache-2.0

package com.digitalasset.grpc.sampleservice.implementations

import com.digitalasset.grpc.sampleservice.Responding
import com.digitalasset.platform.hello.HelloServiceGrpc.HelloService
import com.digitalasset.platform.hello.{HelloRequest, HelloResponse, HelloServiceGrpc}
import io.grpc.stub.StreamObserver
import io.grpc.{BindableService, ServerServiceDefinition, Status}

import scala.concurrent.ExecutionContext
class ReferenceImplementation
    extends HelloService
    with Responding
    with BindableService
    with AutoCloseable {

  override def close(): Unit = ()

  override def bindService(): ServerServiceDefinition =
    HelloServiceGrpc.bindService(this, ExecutionContext.global)

  override def serverStreaming(
      request: HelloRequest,
      responseObserver: StreamObserver[HelloResponse]): Unit = {
    validateRequest(request)
    for (i <- 1.to(request.reqInt)) responseObserver.onNext(HelloResponse(i))
    responseObserver.onCompleted()
  }

  private def validateRequest(request: HelloRequest) =
    if (request.reqInt < 0)
      throw Status.INVALID_ARGUMENT
        .withDescription("request cannot be negative")
        .asRuntimeException()

}
