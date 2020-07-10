// Copyright 2020 The TensorFlow Runtime Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// This test is auto generated by: //utils/eigen:gen_batch_norm_grad_tests

// RUN: tfrt_translate --mlir-to-bef %s | bef_executor | FileCheck %s --dump-input=always
// RUN: tfrt_translate --mlir-to-bef %s | bef_executor --work_queue_type=mstd:1 | FileCheck %s --dump-input=always
// RUN: tfrt_translate --mlir-to-bef %s | bef_executor --work_queue_type=mstd:2 | FileCheck %s --dump-input=always
// RUN: tfrt_translate --mlir-to-bef %s | bef_executor --work_queue_type=mstd:4 | FileCheck %s --dump-input=always
// RUN: tfrt_translate --mlir-to-bef %s | bef_executor --work_queue_type=mstd:8 | FileCheck %s --dump-input=always

// CHECK-LABEL: --- Running 'test_batch_norm_grad_in_2x1x1x8_epsilon_0.0001'
func @test_batch_norm_grad_in_2x1x1x8_epsilon_0.0001() {
  %ch0 = hex.new.chain

  %path = "tfrt_test.get_string"() {
      value = "backends/common/mlir_tests/compat/eigen/test_data/batch_norm_grad_f32.btf"
  } : () -> !hex.string

  %input_index       = hex.constant.i32 0
  %gamma_index       = hex.constant.i32 1
  %beta_index        = hex.constant.i32 2
  %mean_index        = hex.constant.i32 3
  %var_index         = hex.constant.i32 4

  %output_grad_index = hex.constant.i32 5
  %input_grad_index  = hex.constant.i32 6
  %gamma_grad_index  = hex.constant.i32 7
  %beta_grad_index   = hex.constant.i32 8

  %input = "btf.read_dense_tensor.f32.4"(%path, %input_index)
    : (!hex.string, i32) -> (!t.tensor)

  %gamma = "btf.read_dense_tensor.f32.1"(%path, %gamma_index)
    : (!hex.string, i32) -> (!t.tensor)

  %beta = "btf.read_dense_tensor.f32.1"(%path, %beta_index)
    : (!hex.string, i32) -> (!t.tensor)

  %mean = "btf.read_dense_tensor.f32.1"(%path, %mean_index)
    : (!hex.string, i32) -> (!t.tensor)

  %var = "btf.read_dense_tensor.f32.1"(%path, %var_index)
    : (!hex.string, i32) -> (!t.tensor)

  %output_grad = "btf.read_dense_tensor.f32.4"(%path, %output_grad_index)
    : (!hex.string, i32) -> (!t.tensor)

  %expected_input_grad = "btf.read_dense_tensor.f32.4"(%path, %input_grad_index)
    : (!hex.string, i32) -> (!t.tensor)

  %expected_gamma_grad = "btf.read_dense_tensor.f32.1"(%path, %gamma_grad_index)
    : (!hex.string, i32) -> (!t.tensor)

  %expected_beta_grad = "btf.read_dense_tensor.f32.1"(%path, %beta_grad_index)
    : (!hex.string, i32) -> (!t.tensor)

  %input_grad = "tfrt_dht.create_uninitialized_tensor.f32.4"()
    { shape = [2 : i64, 1 : i64, 1 : i64, 8 : i64] }
    : () -> !t.tensor

  %gamma_grad = "tfrt_dht.create_uninitialized_tensor.f32.1"()
    { shape = [8 : i64] }
    : () -> !t.tensor

  %beta_grad = "tfrt_dht.create_uninitialized_tensor.f32.1"()
    { shape = [8 : i64] }
    : () -> !t.tensor

  %ch_in, %ch_gamma, %ch_beta = "eigen.batch_norm.grad.f32"(
      %output_grad, %input, %gamma, %mean, %var, %ch0, %input_grad,
      %gamma_grad, %beta_grad
    )
    { epsilon = [0.0001 : f32] }
    :  (!t.tensor, !t.tensor, !t.tensor, !t.tensor,
        !t.tensor, !hex.chain, !t.tensor, !t.tensor, !t.tensor)
       -> (!hex.chain, !hex.chain, !hex.chain)

  %ch2 = hex.merge.chains %ch_in, %ch_gamma, %ch_beta

  %cmp0, %ch3 = "tfrt_dht.tensor_allclose.100000ulp.f32"(%expected_input_grad, %input_grad, %ch2)
    : (!t.tensor, !t.tensor, !hex.chain) -> (i1, !hex.chain)

  %cmp1, %ch4 = "tfrt_dht.tensor_allclose.100000ulp.f32"(%expected_gamma_grad, %gamma_grad, %ch2)
    : (!t.tensor, !t.tensor, !hex.chain) -> (i1, !hex.chain)

  %cmp2, %ch5 = "tfrt_dht.tensor_allclose.100000ulp.f32"(%expected_beta_grad, %beta_grad, %ch2)
    : (!t.tensor, !t.tensor, !hex.chain) -> (i1, !hex.chain)

  // CHECK: int1 = 1
  %ch6 = hex.print.i1 %cmp0, %ch5

  // CHECK: int1 = 1
  %ch7 = hex.print.i1 %cmp1, %ch6

  // CHECK: int1 = 1
  %ch8 = hex.print.i1 %cmp2, %ch7

  hex.return
}

// CHECK-LABEL: --- Running 'test_batch_norm_grad_in_2x2x2x4_epsilon_0.001'
func @test_batch_norm_grad_in_2x2x2x4_epsilon_0.001() {
  %ch0 = hex.new.chain

  %path = "tfrt_test.get_string"() {
      value = "backends/common/mlir_tests/compat/eigen/test_data/batch_norm_grad_f32.btf"
  } : () -> !hex.string

  %input_index       = hex.constant.i32 9
  %gamma_index       = hex.constant.i32 10
  %beta_index        = hex.constant.i32 11
  %mean_index        = hex.constant.i32 12
  %var_index         = hex.constant.i32 13

  %output_grad_index = hex.constant.i32 14
  %input_grad_index  = hex.constant.i32 15
  %gamma_grad_index  = hex.constant.i32 16
  %beta_grad_index   = hex.constant.i32 17

  %input = "btf.read_dense_tensor.f32.4"(%path, %input_index)
    : (!hex.string, i32) -> (!t.tensor)

  %gamma = "btf.read_dense_tensor.f32.1"(%path, %gamma_index)
    : (!hex.string, i32) -> (!t.tensor)

  %beta = "btf.read_dense_tensor.f32.1"(%path, %beta_index)
    : (!hex.string, i32) -> (!t.tensor)

  %mean = "btf.read_dense_tensor.f32.1"(%path, %mean_index)
    : (!hex.string, i32) -> (!t.tensor)

  %var = "btf.read_dense_tensor.f32.1"(%path, %var_index)
    : (!hex.string, i32) -> (!t.tensor)

  %output_grad = "btf.read_dense_tensor.f32.4"(%path, %output_grad_index)
    : (!hex.string, i32) -> (!t.tensor)

  %expected_input_grad = "btf.read_dense_tensor.f32.4"(%path, %input_grad_index)
    : (!hex.string, i32) -> (!t.tensor)

  %expected_gamma_grad = "btf.read_dense_tensor.f32.1"(%path, %gamma_grad_index)
    : (!hex.string, i32) -> (!t.tensor)

  %expected_beta_grad = "btf.read_dense_tensor.f32.1"(%path, %beta_grad_index)
    : (!hex.string, i32) -> (!t.tensor)

  %input_grad = "tfrt_dht.create_uninitialized_tensor.f32.4"()
    { shape = [2 : i64, 2 : i64, 2 : i64, 4 : i64] }
    : () -> !t.tensor

  %gamma_grad = "tfrt_dht.create_uninitialized_tensor.f32.1"()
    { shape = [4 : i64] }
    : () -> !t.tensor

  %beta_grad = "tfrt_dht.create_uninitialized_tensor.f32.1"()
    { shape = [4 : i64] }
    : () -> !t.tensor

  %ch_in, %ch_gamma, %ch_beta = "eigen.batch_norm.grad.f32"(
      %output_grad, %input, %gamma, %mean, %var, %ch0, %input_grad,
      %gamma_grad, %beta_grad
    )
    { epsilon = [0.001 : f32] }
    :  (!t.tensor, !t.tensor, !t.tensor, !t.tensor,
        !t.tensor, !hex.chain, !t.tensor, !t.tensor, !t.tensor)
       -> (!hex.chain, !hex.chain, !hex.chain)

  %ch2 = hex.merge.chains %ch_in, %ch_gamma, %ch_beta

  %cmp0, %ch3 = "tfrt_dht.tensor_allclose.100000ulp.f32"(%expected_input_grad, %input_grad, %ch2)
    : (!t.tensor, !t.tensor, !hex.chain) -> (i1, !hex.chain)

  %cmp1, %ch4 = "tfrt_dht.tensor_allclose.100000ulp.f32"(%expected_gamma_grad, %gamma_grad, %ch2)
    : (!t.tensor, !t.tensor, !hex.chain) -> (i1, !hex.chain)

  %cmp2, %ch5 = "tfrt_dht.tensor_allclose.100000ulp.f32"(%expected_beta_grad, %beta_grad, %ch2)
    : (!t.tensor, !t.tensor, !hex.chain) -> (i1, !hex.chain)

  // CHECK: int1 = 1
  %ch6 = hex.print.i1 %cmp0, %ch5

  // CHECK: int1 = 1
  %ch7 = hex.print.i1 %cmp1, %ch6

  // CHECK: int1 = 1
  %ch8 = hex.print.i1 %cmp2, %ch7

  hex.return
}

// CHECK-LABEL: --- Running 'test_batch_norm_grad_in_4x4x4x32_epsilon_0.01'
func @test_batch_norm_grad_in_4x4x4x32_epsilon_0.01() {
  %ch0 = hex.new.chain

  %path = "tfrt_test.get_string"() {
      value = "backends/common/mlir_tests/compat/eigen/test_data/batch_norm_grad_f32.btf"
  } : () -> !hex.string

  %input_index       = hex.constant.i32 18
  %gamma_index       = hex.constant.i32 19
  %beta_index        = hex.constant.i32 20
  %mean_index        = hex.constant.i32 21
  %var_index         = hex.constant.i32 22

  %output_grad_index = hex.constant.i32 23
  %input_grad_index  = hex.constant.i32 24
  %gamma_grad_index  = hex.constant.i32 25
  %beta_grad_index   = hex.constant.i32 26

  %input = "btf.read_dense_tensor.f32.4"(%path, %input_index)
    : (!hex.string, i32) -> (!t.tensor)

  %gamma = "btf.read_dense_tensor.f32.1"(%path, %gamma_index)
    : (!hex.string, i32) -> (!t.tensor)

  %beta = "btf.read_dense_tensor.f32.1"(%path, %beta_index)
    : (!hex.string, i32) -> (!t.tensor)

  %mean = "btf.read_dense_tensor.f32.1"(%path, %mean_index)
    : (!hex.string, i32) -> (!t.tensor)

  %var = "btf.read_dense_tensor.f32.1"(%path, %var_index)
    : (!hex.string, i32) -> (!t.tensor)

  %output_grad = "btf.read_dense_tensor.f32.4"(%path, %output_grad_index)
    : (!hex.string, i32) -> (!t.tensor)

  %expected_input_grad = "btf.read_dense_tensor.f32.4"(%path, %input_grad_index)
    : (!hex.string, i32) -> (!t.tensor)

  %expected_gamma_grad = "btf.read_dense_tensor.f32.1"(%path, %gamma_grad_index)
    : (!hex.string, i32) -> (!t.tensor)

  %expected_beta_grad = "btf.read_dense_tensor.f32.1"(%path, %beta_grad_index)
    : (!hex.string, i32) -> (!t.tensor)

  %input_grad = "tfrt_dht.create_uninitialized_tensor.f32.4"()
    { shape = [4 : i64, 4 : i64, 4 : i64, 32 : i64] }
    : () -> !t.tensor

  %gamma_grad = "tfrt_dht.create_uninitialized_tensor.f32.1"()
    { shape = [32 : i64] }
    : () -> !t.tensor

  %beta_grad = "tfrt_dht.create_uninitialized_tensor.f32.1"()
    { shape = [32 : i64] }
    : () -> !t.tensor

  %ch_in, %ch_gamma, %ch_beta = "eigen.batch_norm.grad.f32"(
      %output_grad, %input, %gamma, %mean, %var, %ch0, %input_grad,
      %gamma_grad, %beta_grad
    )
    { epsilon = [0.01 : f32] }
    :  (!t.tensor, !t.tensor, !t.tensor, !t.tensor,
        !t.tensor, !hex.chain, !t.tensor, !t.tensor, !t.tensor)
       -> (!hex.chain, !hex.chain, !hex.chain)

  %ch2 = hex.merge.chains %ch_in, %ch_gamma, %ch_beta

  %cmp0, %ch3 = "tfrt_dht.tensor_allclose.100000ulp.f32"(%expected_input_grad, %input_grad, %ch2)
    : (!t.tensor, !t.tensor, !hex.chain) -> (i1, !hex.chain)

  %cmp1, %ch4 = "tfrt_dht.tensor_allclose.100000ulp.f32"(%expected_gamma_grad, %gamma_grad, %ch2)
    : (!t.tensor, !t.tensor, !hex.chain) -> (i1, !hex.chain)

  %cmp2, %ch5 = "tfrt_dht.tensor_allclose.100000ulp.f32"(%expected_beta_grad, %beta_grad, %ch2)
    : (!t.tensor, !t.tensor, !hex.chain) -> (i1, !hex.chain)

  // CHECK: int1 = 1
  %ch6 = hex.print.i1 %cmp0, %ch5

  // CHECK: int1 = 1
  %ch7 = hex.print.i1 %cmp1, %ch6

  // CHECK: int1 = 1
  %ch8 = hex.print.i1 %cmp2, %ch7

  hex.return
}

// CHECK-LABEL: --- Running 'test_batch_norm_grad_in_8x4x4x64_epsilon_0.0001'
func @test_batch_norm_grad_in_8x4x4x64_epsilon_0.0001() {
  %ch0 = hex.new.chain

  %path = "tfrt_test.get_string"() {
      value = "backends/common/mlir_tests/compat/eigen/test_data/batch_norm_grad_f32.btf"
  } : () -> !hex.string

  %input_index       = hex.constant.i32 27
  %gamma_index       = hex.constant.i32 28
  %beta_index        = hex.constant.i32 29
  %mean_index        = hex.constant.i32 30
  %var_index         = hex.constant.i32 31

  %output_grad_index = hex.constant.i32 32
  %input_grad_index  = hex.constant.i32 33
  %gamma_grad_index  = hex.constant.i32 34
  %beta_grad_index   = hex.constant.i32 35

  %input = "btf.read_dense_tensor.f32.4"(%path, %input_index)
    : (!hex.string, i32) -> (!t.tensor)

  %gamma = "btf.read_dense_tensor.f32.1"(%path, %gamma_index)
    : (!hex.string, i32) -> (!t.tensor)

  %beta = "btf.read_dense_tensor.f32.1"(%path, %beta_index)
    : (!hex.string, i32) -> (!t.tensor)

  %mean = "btf.read_dense_tensor.f32.1"(%path, %mean_index)
    : (!hex.string, i32) -> (!t.tensor)

  %var = "btf.read_dense_tensor.f32.1"(%path, %var_index)
    : (!hex.string, i32) -> (!t.tensor)

  %output_grad = "btf.read_dense_tensor.f32.4"(%path, %output_grad_index)
    : (!hex.string, i32) -> (!t.tensor)

  %expected_input_grad = "btf.read_dense_tensor.f32.4"(%path, %input_grad_index)
    : (!hex.string, i32) -> (!t.tensor)

  %expected_gamma_grad = "btf.read_dense_tensor.f32.1"(%path, %gamma_grad_index)
    : (!hex.string, i32) -> (!t.tensor)

  %expected_beta_grad = "btf.read_dense_tensor.f32.1"(%path, %beta_grad_index)
    : (!hex.string, i32) -> (!t.tensor)

  %input_grad = "tfrt_dht.create_uninitialized_tensor.f32.4"()
    { shape = [8 : i64, 4 : i64, 4 : i64, 64 : i64] }
    : () -> !t.tensor

  %gamma_grad = "tfrt_dht.create_uninitialized_tensor.f32.1"()
    { shape = [64 : i64] }
    : () -> !t.tensor

  %beta_grad = "tfrt_dht.create_uninitialized_tensor.f32.1"()
    { shape = [64 : i64] }
    : () -> !t.tensor

  %ch_in, %ch_gamma, %ch_beta = "eigen.batch_norm.grad.f32"(
      %output_grad, %input, %gamma, %mean, %var, %ch0, %input_grad,
      %gamma_grad, %beta_grad
    )
    { epsilon = [0.0001 : f32] }
    :  (!t.tensor, !t.tensor, !t.tensor, !t.tensor,
        !t.tensor, !hex.chain, !t.tensor, !t.tensor, !t.tensor)
       -> (!hex.chain, !hex.chain, !hex.chain)

  %ch2 = hex.merge.chains %ch_in, %ch_gamma, %ch_beta

  %cmp0, %ch3 = "tfrt_dht.tensor_allclose.100000ulp.f32"(%expected_input_grad, %input_grad, %ch2)
    : (!t.tensor, !t.tensor, !hex.chain) -> (i1, !hex.chain)

  %cmp1, %ch4 = "tfrt_dht.tensor_allclose.100000ulp.f32"(%expected_gamma_grad, %gamma_grad, %ch2)
    : (!t.tensor, !t.tensor, !hex.chain) -> (i1, !hex.chain)

  %cmp2, %ch5 = "tfrt_dht.tensor_allclose.100000ulp.f32"(%expected_beta_grad, %beta_grad, %ch2)
    : (!t.tensor, !t.tensor, !hex.chain) -> (i1, !hex.chain)

  // CHECK: int1 = 1
  %ch6 = hex.print.i1 %cmp0, %ch5

  // CHECK: int1 = 1
  %ch7 = hex.print.i1 %cmp1, %ch6

  // CHECK: int1 = 1
  %ch8 = hex.print.i1 %cmp2, %ch7

  hex.return
}
